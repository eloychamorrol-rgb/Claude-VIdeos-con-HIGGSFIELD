/**
 * Cliente mínimo de la API de Fintoc (https://docs.fintoc.com).
 * Toda la comunicación con Fintoc ocurre aquí: si se cambia de proveedor, solo se reemplaza este archivo.
 */
export class FintocError extends Error {
  constructor(status, body) {
    const detail = body?.error ?? {};
    super(detail.message || `Fintoc respondió ${status}`);
    this.status = status;
    this.type = detail.type || '';
    this.code = detail.code || '';
  }

  /** El banco pide volver a ingresar credenciales (clave cambiada, link inválido, etc.). */
  get needsReconnect() {
    const text = `${this.type} ${this.code}`.toLowerCase();
    return this.status === 401 || this.status === 403 || this.status === 404
      || /link|credential|password|mfa|blocked/.test(text);
  }
}

export class FintocClient {
  constructor({ secretKey, baseUrl = 'https://api.fintoc.com/v1', fetchImpl = globalThis.fetch }) {
    this.secretKey = secretKey;
    this.baseUrl = baseUrl;
    this.fetch = fetchImpl;
  }

  async request(pathOrUrl, { method = 'GET', query = {} } = {}) {
    const url = new URL(pathOrUrl.startsWith('http') ? pathOrUrl : `${this.baseUrl}${pathOrUrl}`);
    for (const [key, value] of Object.entries(query)) {
      if (value !== undefined && value !== null && value !== '') url.searchParams.set(key, String(value));
    }
    const response = await this.fetch(url, {
      method,
      headers: { Authorization: this.secretKey, Accept: 'application/json' },
      signal: AbortSignal.timeout(60_000),
    });
    const text = await response.text();
    let body = null;
    try { body = text ? JSON.parse(text) : null; } catch { body = null; }
    if (!response.ok) throw new FintocError(response.status, body);
    return { body, next: parseNextLink(response.headers.get('link')) };
  }

  /** Canjea el exchange_token que entrega el widget por el Link (incluye link_token). */
  async exchange(exchangeToken) {
    const { body } = await this.request('/links/exchange', { query: { exchange_token: exchangeToken } });
    return body;
  }

  async accounts(linkToken) {
    const { body } = await this.request('/accounts', { query: { link_token: linkToken } });
    return Array.isArray(body) ? body : [];
  }

  /** Descarga todos los movimientos desde `since` (YYYY-MM-DD) siguiendo la paginación. */
  async movements(linkToken, accountId, since) {
    const all = [];
    let page = await this.request(`/accounts/${encodeURIComponent(accountId)}/movements`, {
      query: { link_token: linkToken, since, per_page: 300 },
    });
    for (let guard = 0; guard < 100; guard += 1) {
      if (Array.isArray(page.body)) all.push(...page.body);
      if (!page.next) break;
      const next = new URL(page.next);
      if (!next.searchParams.has('link_token')) next.searchParams.set('link_token', linkToken);
      page = await this.request(next.toString());
    }
    return all;
  }

  async deleteLink(linkToken) {
    await this.request(`/links/${encodeURIComponent(linkToken)}`, { method: 'DELETE' });
  }
}

/** Extrae la URL rel="next" del header Link (RFC 8288). */
export function parseNextLink(header) {
  if (!header) return null;
  for (const part of header.split(',')) {
    const match = part.match(/<([^>]+)>\s*;\s*rel="?next"?/);
    if (match) return match[1];
  }
  return null;
}
