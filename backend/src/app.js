import { readFileSync } from 'node:fs';
import { decrypt, encrypt, randomToken, safeEqual, sha256 } from './crypto.js';
import { FintocError } from './fintoc.js';

const connectTemplate = readFileSync(new URL('../public/connect.html', import.meta.url), 'utf8');
const MAX_BODY = 64 * 1024;

class HttpError extends Error {
  constructor(status, message, code = undefined) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

/** Limita intentos por IP (p. ej. registro de dispositivos). */
class RateLimiter {
  constructor(limit, windowMs) {
    this.limit = limit;
    this.windowMs = windowMs;
    this.hits = new Map();
  }

  allow(key, now = Date.now()) {
    const recent = (this.hits.get(key) ?? []).filter((time) => now - time < this.windowMs);
    recent.push(now);
    this.hits.set(key, recent);
    return recent.length <= this.limit;
  }
}

function send(res, status, payload, headers = {}) {
  const isHtml = typeof payload === 'string';
  const body = isHtml ? payload : JSON.stringify(payload);
  res.writeHead(status, {
    'Content-Type': isHtml ? 'text/html; charset=utf-8' : 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff',
    'Referrer-Policy': 'no-referrer',
    ...headers,
  });
  res.end(body);
}

async function readJson(req) {
  let size = 0;
  const chunks = [];
  for await (const chunk of req) {
    size += chunk.length;
    if (size > MAX_BODY) throw new HttpError(413, 'Solicitud demasiado grande.');
    chunks.push(chunk);
  }
  if (chunks.length === 0) return {};
  try {
    const parsed = JSON.parse(Buffer.concat(chunks).toString('utf8'));
    return parsed && typeof parsed === 'object' ? parsed : {};
  } catch {
    throw new HttpError(400, 'JSON inválido.');
  }
}

function escapeForScript(value) {
  return JSON.stringify(String(value)).replace(/</g, '\\u003c');
}

function publicLink(link) {
  return { id: link.id, institution: link.institution, holderName: link.holderName ?? null, createdAt: link.createdAt };
}

function mapFintocError(error) {
  if (error instanceof FintocError) {
    if (error.needsReconnect) {
      return new HttpError(409, 'El banco pidió volver a ingresar tus credenciales. Reconecta la cuenta.', 'link_needs_reconnect');
    }
    return new HttpError(502, 'El banco no respondió correctamente. Intenta más tarde.', 'provider_error');
  }
  if (error?.name === 'TimeoutError' || error?.name === 'AbortError') {
    return new HttpError(504, 'El banco tardó demasiado en responder. Intenta más tarde.', 'provider_timeout');
  }
  return error;
}

export function createApp({ config, store, fintoc, logger = console }) {
  const registerLimiter = new RateLimiter(10, 60 * 60 * 1000);

  function authenticate(req) {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7).trim() : '';
    const device = token ? store.deviceByTokenHash(sha256(token)) : null;
    if (!device) throw new HttpError(401, 'No autorizado.');
    return device;
  }

  function linkFor(device, id) {
    const link = store.link(id, device.id);
    if (!link) throw new HttpError(404, 'Conexión no encontrada.');
    return { link, linkToken: decrypt(link.linkToken, config.encryptionKey) };
  }

  const routes = [
    ['GET', /^\/health$/, async (_req, res) => send(res, 200, { ok: true })],

    ['GET', /^\/connect$/, async (_req, res) => {
      const html = connectTemplate
        .replace('__FINTOC_PUBLIC_KEY__', () => escapeForScript(config.fintocPublicKey))
        .replace('__WEBHOOK_URL__', () => escapeForScript(config.publicUrl ? `${config.publicUrl}/webhooks/fintoc` : ''));
      send(res, 200, html, {
        'Content-Security-Policy': "default-src 'self'; script-src 'self' 'unsafe-inline' https://js.fintoc.com; "
          + "frame-src https://*.fintoc.com; connect-src https://*.fintoc.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:",
      });
    }],

    ['POST', /^\/v1\/devices$/, async (req, res) => {
      const ip = req.socket.remoteAddress || 'unknown';
      if (!registerLimiter.allow(ip)) throw new HttpError(429, 'Demasiados intentos. Espera una hora.');
      const { appSecret } = await readJson(req);
      if (typeof appSecret !== 'string' || !safeEqual(appSecret, config.appSecret)) {
        throw new HttpError(401, 'Clave de la app incorrecta.');
      }
      const token = randomToken();
      store.addDevice(sha256(token), { id: randomToken(12), createdAt: new Date().toISOString() });
      send(res, 201, { token });
    }],

    ['POST', /^\/v1\/links$/, async (req, res) => {
      const device = authenticate(req);
      const { exchangeToken } = await readJson(req);
      if (typeof exchangeToken !== 'string' || exchangeToken.length < 8 || exchangeToken.length > 512) {
        throw new HttpError(400, 'Falta el exchangeToken.');
      }
      const remote = await fintoc.exchange(exchangeToken);
      const linkToken = remote?.link_token;
      if (!linkToken) throw new HttpError(502, 'El proveedor no entregó la conexión.', 'provider_error');
      const link = {
        id: randomToken(12),
        deviceId: device.id,
        linkToken: encrypt(linkToken, config.encryptionKey),
        fintocLinkId: remote.id ?? null,
        institution: { id: remote.institution?.id ?? 'unknown', name: remote.institution?.name ?? 'Banco' },
        holderName: remote.holder_name ?? null,
        createdAt: new Date().toISOString(),
      };
      store.addLink(link);
      send(res, 201, { link: publicLink(link) });
    }],

    ['GET', /^\/v1\/links$/, async (req, res) => {
      const device = authenticate(req);
      send(res, 200, { links: store.links(device.id).map(publicLink) });
    }],

    ['DELETE', /^\/v1\/links\/([\w-]+)$/, async (req, res, [id]) => {
      const device = authenticate(req);
      const { link, linkToken } = linkFor(device, id);
      try {
        await fintoc.deleteLink(linkToken);
      } catch (error) {
        // Se elimina localmente aunque el proveedor falle: el token deja de existir en este servidor.
        logger.warn?.(`No se pudo eliminar el link en Fintoc: ${error.message}`);
      }
      store.removeLink(link.id);
      send(res, 200, { deleted: true });
    }],

    ['GET', /^\/v1\/links\/([\w-]+)\/accounts$/, async (req, res, [id]) => {
      const device = authenticate(req);
      const { linkToken } = linkFor(device, id);
      send(res, 200, { accounts: await fintoc.accounts(linkToken) });
    }],

    ['GET', /^\/v1\/links\/([\w-]+)\/accounts\/([\w-]+)\/movements$/, async (req, res, [id, accountId], url) => {
      const device = authenticate(req);
      const { linkToken } = linkFor(device, id);
      let since = url.searchParams.get('since');
      if (since && !/^\d{4}-\d{2}-\d{2}$/.test(since)) throw new HttpError(400, 'El parámetro since debe ser AAAA-MM-DD.');
      if (!since) {
        const date = new Date();
        date.setUTCFullYear(date.getUTCFullYear() - 1);
        since = date.toISOString().slice(0, 10);
      }
      send(res, 200, { movements: await fintoc.movements(linkToken, accountId, since) });
    }],

    ['POST', /^\/webhooks\/fintoc$/, async (req, res) => {
      // Fintoc avisa eventos (p. ej. credenciales cambiadas). La app consulta el estado al sincronizar,
      // así que aquí solo se registra el tipo de evento.
      const event = await readJson(req).catch(() => ({}));
      logger.info?.(`Webhook Fintoc: ${event?.type ?? 'desconocido'}`);
      send(res, 200, { received: true });
    }],
  ];

  return async function handler(req, res) {
    try {
      const url = new URL(req.url, 'http://localhost');
      for (const [method, pattern, action] of routes) {
        const match = url.pathname.match(pattern);
        if (!match) continue;
        if (req.method !== method) continue;
        await action(req, res, match.slice(1), url);
        return;
      }
      const pathExists = routes.some(([, pattern]) => pattern.test(url.pathname));
      throw new HttpError(pathExists ? 405 : 404, pathExists ? 'Método no permitido.' : 'Ruta no encontrada.');
    } catch (raw) {
      const error = mapFintocError(raw);
      if (error instanceof HttpError) {
        send(res, error.status, { error: error.message, ...(error.code ? { code: error.code } : {}) });
      } else {
        logger.error?.(error);
        send(res, 500, { error: 'Error interno del servidor.' });
      }
    }
  };
}
