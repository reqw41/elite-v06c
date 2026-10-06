// Сверка стенда с настоящим BBC (jsbeeb): оба идут от входа в игру (TT170) и останавливаются на N-м приходе
// в метку; сравнивается память 0–&7FFF. Стенд стартует с памяти и регистров, снятых с jsbeeb в TT170.
// Запуск: node tools/oracle/xcheck.mjs [метка=TLL2] [приходов=40]
import path from 'path';
import fs from 'fs';
import { createRequire } from 'module';
import { fileURLToPath } from 'url';
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const require = createRequire(import.meta.url);
const { BBC } = require('./bbc.js');
const { MachineSession } = await import(path.join(ROOT, 'orig/tools/jsbeeb/src/machine-session.js'));
// Сценарий: [метка, число приходов, клавиши нажать, клавиши отпустить] — клавиши меняются перед шагом.
// Номера клавиш — внутренние BBC: N=&55, пробел=&62, f0 (взлёт)=&20, A (огонь)=&41, S/X (тангаж)=&51/&42.
const SCN = {
  title: [['TLL2', 40]],
  launch: [['TLL2', 60], ['TLL2', 1, [0x55]], ['TLL2', 60, [], [0x55]], ['MLOOP', 1, [0x62]], ['MLOOP', 40, [], [0x62]],
    ['MLOOP', 3, [0x20]], ['MLOOP', 120, [], [0x20]], ['MLOOP', 40, [0x62]], ['MLOOP', 40, [0x41, 0x51], [0x62]],
    ['MLOOP', 60, [], [0x41, 0x51]]],
};
const scn = SCN[process.argv[2] || 'launch'];

const log = console.log; console.log = () => {};          // jsbeeb пишет о загрузке ПЗУ
const s = new MachineSession('B-DFS1.2', { discImage: path.join(ROOT, 'orig/bbc/cassette/5-compiled-game-discs/elite-cassette-sth.ssd') });
await s.initialise(); await s.boot(); await s.type('*EXEC !BOOT\n');
const m = new BBC();
await s.runUntilAddress(m.lab.TT170, 120);
console.log = log;
const r = s.registers();
m.mem.set(s.readMemory(0, 0x8000), 0);
m.mem[m.lab.VEC] = 0x80; m.mem[m.lab.VEC + 1] = 0xff;     // у стенда своя заглушка системного прерывания
Object.assign(m.cpu, { pc: r.pc, a: r.a, x: r.x, y: r.y, s: r.s, p: r.p._byte ?? r.p });

const inv = Object.entries(m.lab).map(([k, v]) => [v, k]).sort((a, b) => a[0] - b[0]);
const near = (a) => { let n = '?'; for (const [v, k] of inv) { if (v > a) break; n = `${k}+${a - v}`; } return n; };
let bad = 0, total = 0, armed = false, target = 0;
const cpu = s._machine.processor;
cpu.debugInstruction.add((pc) => { if (armed && pc === target) { armed = false; return true; } return false; });
const skip = (a) => (a >= 0x100 && a < 0x300) || (a >= 0x380 && a < 0x400) || (a >= 0x800 && a < 0x900) ||
  a === m.lab.VEC || a === m.lab.VEC + 1 || (a >= 0xb0 && a < 0xd1) || (a >= 0xe2 && a <= 0xff);   // стек и области системы
for (const [label, hits, down = [], up = []] of scn) {
  target = m.lab[label];
  for (const k of down) { m.keys.add(k); s.keyDownRaw([k & 15, k >> 4]); }
  for (const k of up) { m.keys.delete(k); s.keyUpRaw([k & 15, k >> 4]); }
  for (let i = 1; i <= hits; i++) {
    armed = false; await s.runFor(4); armed = true;
    for (let k = 0; k < 400 && armed; k++) await s.runFor(40000);
    if (armed) throw new Error(`jsbeeb не дошёл до ${label}`);
    m.step(); if (!m.runTo(target, 3000)) throw new Error(`стенд не дошёл до ${label}`);
    const j = s.readMemory(0, 0x8000), diff = [];
    for (let a = 0; a < 0x8000; a++) if (j[a] !== m.mem[a] && !skip(a)) diff.push(a);
    total++;
    if (diff.length && ++bad <= 4) {
      console.log(`шаг ${total} (${label} №${i}): различий ${diff.length}:`, diff.slice(0, 10).map((a) => `${a.toString(16)}(${near(a)}) bbc=${j[a].toString(16)} стенд=${m.mem[a].toString(16)}`).join(', '));
    }
  }
}
m.png(path.join(ROOT, 'work/oracle/xcheck-end.png'));
console.log(`сценарий ${process.argv[2] || 'launch'}: шагов ${total}, с различиями ${bad}; звуков в стенде ${m.sounds.length}, RAND ${[...m.mem.subarray(m.lab.RAND, m.lab.RAND + 4)].map((v) => v.toString(16)).join(' ')}`);
process.exit(bad ? 1 : 0);
