import { test, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { randomBytes } from 'node:crypto';
import { createApp } from '../src/app.js';
import { FintocClient, parseNextLink } from '../src/fintoc.js';
import { JsonStore } from '../src/store.js';
import { decrypt, encrypt } from '../src/crypto.js';
import { readConfig } from '../src/config.js';

const config = {
  fintocPublicKey: 'pk_test_123',
  fintocSecretKey: 'sk_test_secret',
  fintocApiUrl: 'https://api.fintoc.test/v1',
  encryptionKey: randomBytes(32).toString('base64'),
  appSecret: 'una-clave-compartida-larga',
  publicUrl: 'https://cuadra.example.com',
};

/** Simula la API de Fintoc. */
function fakeFintoc() {
  const calls = [];
  const state = { failWith: null };
  const fetchImpl = async (url, init) => {
    calls.push({ url: url.toString(), init });
    assert.equal(init.headers.Authorization, config.fintocSecretKey);
    if (state.failWith) {
      return new Response(JSON.stringify({ error: state.failWith.body }), { status: state.failWith.status });
    }
    const { pathname, searchParams } = url;
    if (pathname === '/v1/links/exchange') {
      return Response.json({ id: 'link_abc', link_token: 'link_abc_token_SECRETO', holder_name: 'Ana Pérez',
        institution: { id: 'cl_banco_santander', name: 'Banco Santander', country: 'cl' } });
    }
    if (pathname === '/v1/accounts') {
      assert.equal(searchParams.get('link_token'), 'link_abc_token_SECRETO');
      return Response.json([{ id: 'acc_1', name: 'Cuenta Corriente', type: 'checking_account', currency: 'CLP',
        balance: { available: 1000, current: 1000, limit: 0 } }]);
    }
    if (pathname === '/v1/accounts/acc_1/movements') {
      assert.equal(searchParams.get('link_token'), 'link_abc_token_SECRETO');
      if (searchParams.get('page') === '2') {
        return Response.json([{ id: 'mov_3', amount: 500 }]);
      }
      assert.equal(searchParams.get('since'), '2026-01-01');
      return new Response(JSON.stringify([{ id: 'mov_1', amount: -100 }, { id: 'mov_2', amount: -200 }]), {
        status: 200,
        headers: { Link: '<https://api.fintoc.test/v1/accounts/acc_1/movements?page=2&per_page=300>; rel="next"' },
      });
    }
    if (pathname === '/v1/links/link_abc_token_SECRETO' && init.method === 'DELETE') {
      return new Response('', { status: 204 });
    }
    return new Response('{}', { status: 404 });
  };
  return { calls, state, client: new FintocClient({ secretKey: config.fintocSecretKey, baseUrl: config.fintocApiUrl, fetchImpl }) };
}

let server, baseUrl, dataDir, fintoc;

beforeEach(async () => {
  dataDir = mkdtempSync(join(tmpdir(), 'cuadra-'));
  fintoc = fakeFintoc();
  const silent = { info() {}, warn() {}, error() {} };
  server = createServer(createApp({ config, store: new JsonStore(dataDir), fintoc: fintoc.client, logger: silent }));
  await new Promise((resolve) => server.listen(0, resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

afterEach(async () => {
  await new Promise((resolve) => server.close(resolve));
  rmSync(dataDir, { recursive: true, force: true });
});

async function call(method, path, { token, body } = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    method,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await response.text();
  return { status: response.status, body: text.startsWith('{') ? JSON.parse(text) : text, headers: response.headers };
}

async function register() {
  const { status, body } = await call('POST', '/v1/devices', { body: { appSecret: config.appSecret } });
  assert.equal(status, 201);
  return body.token;
}

test('registro de dispositivo exige la clave compartida', async () => {
  assert.equal((await call('POST', '/v1/devices', { body: { appSecret: 'incorrecta' } })).status, 401);
  assert.equal((await call('POST', '/v1/devices', { body: {} })).status, 401);
  const token = await register();
  assert.ok(token.length >= 40);
});

test('las rutas de datos exigen token válido', async () => {
  assert.equal((await call('GET', '/v1/links')).status, 401);
  assert.equal((await call('GET', '/v1/links', { token: 'falso' })).status, 401);
});

test('flujo completo: conectar, listar cuentas, movimientos paginados y borrar', async () => {
  const token = await register();
  const created = await call('POST', '/v1/links', { token, body: { exchangeToken: 'exch_123456' } });
  assert.equal(created.status, 201);
  const link = created.body.link;
  assert.equal(link.institution.name, 'Banco Santander');
  assert.equal(link.holderName, 'Ana Pérez');
  assert.equal(link.linkToken, undefined, 'el link_token nunca sale del servidor');

  const raw = readFileSync(join(dataDir, 'store.json'), 'utf8');
  assert.ok(!raw.includes('link_abc_token_SECRETO'), 'el link_token se guarda cifrado');
  assert.ok(!raw.includes(token), 'el token del dispositivo se guarda como hash');

  const listed = await call('GET', '/v1/links', { token });
  assert.deepEqual(listed.body.links.map((l) => l.id), [link.id]);

  const accounts = await call('GET', `/v1/links/${link.id}/accounts`, { token });
  assert.equal(accounts.body.accounts[0].id, 'acc_1');

  const movements = await call('GET', `/v1/links/${link.id}/accounts/acc_1/movements?since=2026-01-01`, { token });
  assert.equal(movements.status, 200);
  assert.deepEqual(movements.body.movements.map((m) => m.id), ['mov_1', 'mov_2', 'mov_3']);
  const secondPage = fintoc.calls.find((c) => c.url.includes('page=2'));
  assert.ok(secondPage.url.includes('link_token=link_abc_token_SECRETO'));

  assert.equal((await call('GET', `/v1/links/${link.id}/accounts/acc_1/movements?since=ayer`, { token })).status, 400);

  const deleted = await call('DELETE', `/v1/links/${link.id}`, { token });
  assert.equal(deleted.status, 200);
  assert.deepEqual((await call('GET', '/v1/links', { token })).body.links, []);
});

test('un dispositivo no puede ver conexiones de otro', async () => {
  const tokenA = await register();
  const tokenB = await register();
  const { body } = await call('POST', '/v1/links', { token: tokenA, body: { exchangeToken: 'exch_123456' } });
  assert.equal((await call('GET', `/v1/links/${body.link.id}/accounts`, { token: tokenB })).status, 404);
  assert.deepEqual((await call('GET', '/v1/links', { token: tokenB })).body.links, []);
});

test('credenciales vencidas se informan como reconexión', async () => {
  const token = await register();
  const { body } = await call('POST', '/v1/links', { token, body: { exchangeToken: 'exch_123456' } });
  fintoc.state.failWith = { status: 403, body: { type: 'link_error', code: 'invalid_credentials', message: 'x' } };
  const result = await call('GET', `/v1/links/${body.link.id}/accounts`, { token });
  assert.equal(result.status, 409);
  assert.equal(result.body.code, 'link_needs_reconnect');

  fintoc.state.failWith = { status: 500, body: { type: 'api_error', message: 'x' } };
  const providerDown = await call('GET', `/v1/links/${body.link.id}/accounts`, { token });
  assert.equal(providerDown.status, 502);
});

test('validaciones y rutas desconocidas', async () => {
  const token = await register();
  assert.equal((await call('POST', '/v1/links', { token, body: {} })).status, 400);
  assert.equal((await call('GET', '/nada')).status, 404);
  assert.equal((await call('PUT', '/v1/links', { token })).status, 405);
  const bad = await fetch(`${baseUrl}/v1/devices`, { method: 'POST', body: '{no-json' });
  assert.equal(bad.status, 400);
});

test('página de conexión inyecta la llave pública de forma segura', async () => {
  const page = await call('GET', '/connect');
  assert.equal(page.status, 200);
  assert.ok(page.body.includes('publicKey: "pk_test_123"'));
  assert.ok(page.body.includes('"https://cuadra.example.com/webhooks/fintoc"'));
  assert.ok(!page.body.includes('sk_test_secret'), 'la llave secreta jamás llega al cliente');
  assert.ok(page.headers.get('content-security-policy').includes('https://js.fintoc.com'));
});

test('cifrado, paginación y configuración', () => {
  const key = randomBytes(32).toString('base64');
  const sealed = encrypt('hola', key);
  assert.equal(decrypt(sealed, key), 'hola');
  assert.throws(() => decrypt(sealed, randomBytes(32).toString('base64')));
  assert.equal(parseNextLink('<https://a/x?page=2>; rel="next", <https://a/x?page=9>; rel="last"'), 'https://a/x?page=2');
  assert.equal(parseNextLink(null), null);
  assert.equal(readConfig({}).problems.length, 4);
  assert.equal(readConfig({ FINTOC_PUBLIC_KEY: 'pk', FINTOC_SECRET_KEY: 'sk', ENCRYPTION_KEY: key, APP_SECRET: 'x'.repeat(16) }).problems.length, 0);
});
