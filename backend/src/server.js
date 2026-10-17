import { createServer } from 'node:http';
import { loadDotEnv, readConfig } from './config.js';
import { createApp } from './app.js';
import { FintocClient } from './fintoc.js';
import { JsonStore } from './store.js';

loadDotEnv();
const { config, problems } = readConfig();
if (problems.length > 0) {
  console.error(`Faltan o son inválidas estas variables: ${problems.join(', ')}. Revisa .env.example.`);
  process.exit(1);
}

const app = createApp({
  config,
  store: new JsonStore(config.dataDir),
  fintoc: new FintocClient({ secretKey: config.fintocSecretKey, baseUrl: config.fintocApiUrl }),
});

createServer(app).listen(config.port, () => {
  console.log(`Cuadra backend escuchando en el puerto ${config.port}`);
});
