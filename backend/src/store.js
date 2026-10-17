import { mkdirSync, readFileSync, renameSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

/**
 * Almacenamiento mínimo en un archivo JSON con escritura atómica.
 * Suficiente para uso personal o familiar; para muchos usuarios conviene una base de datos.
 */
export class JsonStore {
  constructor(dataDir) {
    this.dir = dataDir;
    this.file = join(dataDir, 'store.json');
    mkdirSync(dataDir, { recursive: true, mode: 0o700 });
    this.data = existsSync(this.file)
      ? JSON.parse(readFileSync(this.file, 'utf8'))
      : { devices: {}, links: {} };
    this.data.devices ??= {};
    this.data.links ??= {};
  }

  save() {
    const tmp = `${this.file}.tmp`;
    writeFileSync(tmp, JSON.stringify(this.data, null, 2), { mode: 0o600 });
    renameSync(tmp, this.file);
  }

  addDevice(tokenHash, device) {
    this.data.devices[tokenHash] = device;
    this.save();
  }

  deviceByTokenHash(tokenHash) {
    return this.data.devices[tokenHash] ?? null;
  }

  addLink(link) {
    this.data.links[link.id] = link;
    this.save();
  }

  link(id, deviceId) {
    const link = this.data.links[id];
    return link && link.deviceId === deviceId ? link : null;
  }

  links(deviceId) {
    return Object.values(this.data.links).filter((link) => link.deviceId === deviceId);
  }

  removeLink(id) {
    delete this.data.links[id];
    this.save();
  }
}
