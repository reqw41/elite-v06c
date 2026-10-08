// Эталон для добавок из дисковой версии BBC: код дисковой версии (полётная часть D.CODE или стоянка T.CODE)
// в голом ядре 6502, вызов одной процедуры — как m.call кассетного эталона (bbc.js). Системы BBC здесь нет:
// годится для процедур, которые работают только с памятью. Адреса меток — из листинга дисковой версии; имена
// рабочих ячеек те же, что в кассетной, адреса другие — память задаётся и читается по именам.
'use strict';
const fs = require('fs');
const path = require('path');
const { CPU6502, FLAGS } = require('./cpu6502.js');

const ROOT = path.resolve(__dirname, '../..');
const ORIG = process.env.ELITE_ORIG || (fs.existsSync(path.join(ROOT, 'orig')) ? path.join(ROOT, 'orig') : '/Users/boris/projects/elite-v06c/orig');
const OUT = path.join(ORIG, 'bbc/disc/3-assembled-output');
const LOAD = 0x11e3;            // S.D.CODE и S.T.CODE: &11E3
const MARK = (f) => `Saving file '3-assembled-output/${f}.unprot.bin'`;

function loadLabels(part) {
  const t = fs.readFileSync(path.join(OUT, 'compile.txt'), 'latin1');
  const d = t.indexOf(MARK('D.CODE')), e = t.indexOf(MARK('T.CODE'));
  if (d < 0 || e < d) throw new Error('листинг дисковой версии: нет границ D.CODE / T.CODE');
  const lab = {};
  for (const m of (part === 'flight' ? t.slice(0, d) : t.slice(d, e)).matchAll(/^\.(\S+) *\r?\n\s+([0-9A-F]{4})\b/gm)) if (!(m[1] in lab)) lab[m[1]] = parseInt(m[2], 16);
  return lab;
}

class DiscCode {
  // part: 'flight' (D.CODE) или 'docked' (T.CODE)
  constructor(part = 'flight') {
    this.lab = loadLabels(part);
    this.image = fs.readFileSync(path.join(OUT, (part === 'flight' ? 'D.CODE' : 'T.CODE') + '.unprot.bin'));
    this.mem = new Uint8Array(0x10000);
    this.cpu = new CPU6502((a) => this.mem[a], (a, v) => { this.mem[a] = v; });
    this.hooks = new Map();     // адрес → функция; вернуть true — «выполнить RTS»
    this.reset();
  }
  reset() { this.mem.fill(0); this.mem.set(this.image, LOAD); }
  at(k) { return typeof k === 'number' ? k : (k in this.lab ? this.lab[k] : (() => { throw new Error('нет метки ' + k); })()); }
  poke(k, v) { const a = this.at(k); (Array.isArray(v) ? v : [v]).forEach((b, i) => { this.mem[a + i] = b & 0xff; }); }
  peek(k, n = 1) { const a = this.at(k); return n === 1 ? this.mem[a] : Array.from(this.mem.subarray(a, a + n)); }
  call(label, { a = 0, x = 0, y = 0, c = 0, mem = {} } = {}, maxCycles = 4e6) {
    const cpu = this.cpu, RET = 0xffa0;
    for (const [k, v] of Object.entries(mem)) this.poke(k in this.lab ? k : Number(k), v);
    cpu.a = a & 0xff; cpu.x = x & 0xff; cpu.y = y & 0xff; cpu.p = FLAGS.U | FLAGS.I | (c ? FLAGS.C : 0);
    cpu.s = 0xfd; this.mem[0x1fe] = (RET - 1) & 0xff; this.mem[0x1ff] = (RET - 1) >> 8;
    cpu.pc = this.at(label);
    const start = cpu.cycles;
    while (cpu.pc !== RET) {
      const h = this.hooks.get(cpu.pc);
      if (h) { if (h(this)) cpu.rts(); } else cpu.step();
      if (cpu.cycles - start > maxCycles) throw new Error(`call ${label}: не вернулась за ${maxCycles} тактов`);
    }
    return { a: cpu.a, x: cpu.x, y: cpu.y, c: cpu.p & 1, z: (cpu.p >> 1) & 1, n: cpu.p >> 7, cycles: cpu.cycles - start };
  }
}

module.exports = { DiscCode };
