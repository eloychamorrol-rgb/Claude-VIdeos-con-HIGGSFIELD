import { existsSync, readFileSync } from 'node:fs';

/** Carga variables desde .env si existe (sin dependencias externas). */
export function loadDotEnv(path = '.env') {
  if (!existsSync(path)) return;
  for (const line of readFileSync(path, 'utf8').split(/\r?\n/)) {
    const match = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
    if (!match || line.trim().startsWith('#')) continue;
    const [, key, raw] = match;
    if (process.env[key] !== undefined) continue;
    process.env[key] = raw.replace(/^["']|["']$/g, '');
  }
}

export function readConfig(env = process.env) {
  const config = {
    port: Number(env.PORT || 8080),
    publicUrl: (env.PUBLIC_URL || '').replace(/\/$/, ''),
    fintocPublicKey: env.FINTOC_PUBLIC_KEY || '',
    fintocSecretKey: env.FINTOC_SECRET_KEY || '',
    fintocApiUrl: (env.FINTOC_API_URL || 'https://api.fintoc.com/v1').replace(/\/$/, ''),
    encryptionKey: env.ENCRYPTION_KEY || '',
    appSecret: env.APP_SECRET || '',
    dataDir: env.DATA_DIR || './data',
  };
  const problems = [];
  if (!config.fintocPublicKey) problems.push('FINTOC_PUBLIC_KEY');
  if (!config.fintocSecretKey) problems.push('FINTOC_SECRET_KEY');
  if (Buffer.from(config.encryptionKey, 'base64').length !== 32) problems.push('ENCRYPTION_KEY (32 bytes en base64)');
  if (config.appSecret.length < 16) problems.push('APP_SECRET (mínimo 16 caracteres)');
  return { config, problems };
}
