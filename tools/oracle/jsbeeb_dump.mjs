// Настоящий BBC (jsbeeb) без окна: загрузить кассетную версию с образа диска, дойти до входа в игру (TT170)
// и сохранить память 0–&7FFF. Это образ «как после загрузчика» для сверки со стендом tools/oracle/bbc.js.
// Запуск: node tools/oracle/jsbeeb_dump.mjs [метка-или-адрес] [файл]
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const { MachineSession } = await import(path.join(ROOT, 'orig/tools/jsbeeb/src/machine-session.js'));
const t = fs.readFileSync(path.join(ROOT, 'orig/bbc/cassette/3-assembled-output/compile.txt'), 'latin1');
const lab = {};
for (const m of t.matchAll(/^\.(\S+)\r?\n\s+([0-9A-F]{4})\b/gm)) if (!(m[1] in lab)) lab[m[1]] = parseInt(m[2], 16);
const target = process.argv[2] || 'TT170';
const addr = target in lab ? lab[target] : parseInt(target, 16);
const out = process.argv[3] || path.join(ROOT, 'work/oracle/jsbeeb_' + target + '.bin');
const s = new MachineSession('B-DFS1.2', { discImage: path.join(ROOT, 'orig/bbc/cassette/5-compiled-game-discs/elite-cassette-sth.ssd') });
await s.initialise();
await s.boot();
await s.type('*EXEC !BOOT\n');
const hit = await s.runUntilAddress(addr, 120);
const reg = s.registers();
const mem = s.readMemory(0, 0x8000);
fs.writeFileSync(out, Buffer.from(mem));
console.log('дошли:', JSON.stringify(hit), 'регистры:', JSON.stringify(reg), '→', out);
s.destroy?.();
process.exit(0);
