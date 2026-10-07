// Эталон быстрой арифметики: процедуры версии BBC Elite для второго процессора (логарифмы) в ядре 6502.
// Загружается код сопроцессора P.CODE (с &1000) вместе с таблицами log, logL, antilog, antilogODD.
// Нужен только вызов отдельной процедуры: FMLTU, LL28.
'use strict';
const fs = require('fs');
const path = require('path');
const { CPU6502, FLAGS } = require('./cpu6502.js');
const ROOT = path.resolve(__dirname, '../..');
const ORIG = process.env.ELITE_ORIG || (fs.existsSync(path.join(ROOT, 'orig')) ? path.join(ROOT, 'orig') : '/Users/boris/projects/elite-v06c/orig');
const SP = path.join(ORIG, 'bbc/6502-second-processor/3-assembled-output');

class SPCode {
  constructor() {
    this.mem = new Uint8Array(0x10000);
    this.mem.set(fs.readFileSync(path.join(SP, 'P.CODE.unprot.bin')), 0x1000);
    this.lab = {};
    const t = fs.readFileSync(path.join(SP, 'compile.txt'), 'latin1');
    for (const m of t.matchAll(/^\.(\S+)\r?\n\s+([0-9A-F]{4})\b/gm)) if (!(m[1] in this.lab)) this.lab[m[1]] = parseInt(m[2], 16);
    this.cpu = new CPU6502((a) => this.mem[a], (a, v) => { this.mem[a] = v; });
  }
  call(label, { a = 0, x = 0, y = 0, c = 0, mem = {} } = {}, maxCycles = 1e5) {
    const cpu = this.cpu, RET = 0xffa0;
    for (const [k, v] of Object.entries(mem)) this.mem[k in this.lab ? this.lab[k] : Number(k)] = v & 0xff;
    cpu.a = a; cpu.x = x; cpu.y = y; cpu.p = FLAGS.U | FLAGS.I | (c ? FLAGS.C : 0);
    cpu.s = 0xfd; this.mem[0x1fe] = (RET - 1) & 0xff; this.mem[0x1ff] = (RET - 1) >> 8;
    cpu.pc = this.lab[label];
    const start = cpu.cycles;
    while (cpu.pc !== RET) { cpu.step(); if (cpu.cycles - start > maxCycles) throw new Error(`call ${label}: не вернулась`); }
    return { a: cpu.a, x: cpu.x, y: cpu.y, c: cpu.p & 1, cycles: cpu.cycles - start };
  }
}
module.exports = { SPCode };
