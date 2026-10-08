// Эталон расширенных описаний планет: настоящий код дисковой версии BBC (стоянка, T.CODE) в голом ядре 6502.
// Вызывается одна процедура PDESC; печать знака (CHPR) перехвачена — знаки собираются в строку вместе с
// переводами строк, которые расставляет выравнивание DASC. Кассетная версия описаний не знает, поэтому эталон
// отдельный: node tools/oracle/pdesc.js [галактика [система]] — напечатать описания.
'use strict';
const fs = require('fs');
const path = require('path');
const { CPU6502, FLAGS } = require('./cpu6502.js');

const ROOT = path.resolve(__dirname, '../..');
const ORIG = process.env.ELITE_ORIG || (fs.existsSync(path.join(ROOT, 'orig')) ? path.join(ROOT, 'orig') : '/Users/boris/projects/elite-v06c/orig');
const OUT = path.join(ORIG, 'bbc/disc/3-assembled-output');
const LOAD = 0x11e3;            // S.T.CODE &11E3 &6000

// Метки стоянки: в листинге сначала идёт полётная часть, поэтому берётся кусок между записями D.CODE и T.CODE.
function loadLabels() {
  const t = fs.readFileSync(path.join(OUT, 'compile.txt'), 'latin1');
  const from = t.indexOf("Saving file '3-assembled-output/D.CODE.unprot.bin'"), to = t.indexOf("Saving file '3-assembled-output/T.CODE.unprot.bin'");
  if (from < 0 || to < from) throw new Error('листинг дисковой версии: нет границ D.CODE / T.CODE');
  const lab = {};
  for (const m of t.slice(from, to).matchAll(/^\.(\S+) *\r?\n\s+([0-9A-F]{4})\b/gm)) if (!(m[1] in lab)) lab[m[1]] = parseInt(m[2], 16);
  return lab;
}

// Семена системы: галактика 0 — 5A4A 0248 B753; следующая галактика — каждый байт циклически влево;
// следующая система — четыре шага ряда Фибоначчи.
function seeds(galaxy, system) {
  let s = [0x5a4a, 0x0248, 0xb753];
  const rol = (b) => ((b << 1) | (b >> 7)) & 0xff;
  for (let g = 0; g < galaxy; g++) s = s.map((w) => rol(w & 0xff) | (rol(w >> 8) << 8));
  for (let i = 0; i < system * 4; i++) s = [s[1], s[2], (s[0] + s[1] + s[2]) & 0xffff];
  return [s[0] & 0xff, s[0] >> 8, s[1] & 0xff, s[1] >> 8, s[2] & 0xff, s[2] >> 8];
}

class Disc {
  constructor() {
    this.lab = loadLabels();
    this.image = fs.readFileSync(path.join(OUT, 'T.CODE.unprot.bin'));
    this.mem = new Uint8Array(0x10000);
    this.cpu = new CPU6502((a) => this.mem[a], (a, v) => { this.mem[a] = v; });
  }
  // Описание системы: строка знаков, как их получает CHPR (12 — перевод строки).
  describe(galaxy, system, rand = [0, 0, 0, 0]) {
    const m = this.mem, L = this.lab, cpu = this.cpu, RET = 0xffa0;
    m.fill(0); m.set(this.image, LOAD);
    m.set(seeds(galaxy, system), L.QQ15);
    m.set(rand, L.RAND);
    m[L.QQ8] = 1;               // расстояние не ноль: особые описания (RUPLA) не проверяются
    m[L.GCNT] = galaxy; m[L.ZZ] = system; m[L.QQ17] = 0x80;
    cpu.a = cpu.x = cpu.y = 0; cpu.p = FLAGS.U | FLAGS.I; cpu.s = 0xfd;
    m[0x1fe] = (RET - 1) & 0xff; m[0x1ff] = (RET - 1) >> 8;
    cpu.pc = L.PDESC;
    let out = '', dornd = 0, peak = 0; const start = cpu.cycles;
    while (cpu.pc !== RET) {
      if (cpu.pc === L.CHPR) { out += String.fromCharCode(cpu.a); cpu.p &= ~FLAGS.C; cpu.rts(); continue; }   // CHPR кончается CLC : RTS
      if (cpu.pc === L.DORND) dornd++;
      if (m[L.DTW5] > peak) peak = m[L.DTW5];          // сколько знаков лежало в буфере выравнивания
      cpu.step();
      if (cpu.cycles - start > 2e7) throw new Error(`PDESC ${galaxy}/${system}: не вернулась`);
    }
    return { text: out, dornd, rand: Array.from(m.subarray(L.RAND, L.RAND + 4)), peak, cycles: cpu.cycles - start };
  }
}

module.exports = { Disc, seeds };

if (require.main === module) {
  const d = new Disc();
  const g = Number(process.argv[2] || 0), one = process.argv[3];
  let maxLen = 0, maxLines = 0, peak = 0;
  for (let s = one === undefined ? 0 : Number(one); s < (one === undefined ? 256 : Number(one) + 1); s++) {
    const r = d.describe(g, s);
    const lines = r.text.split('\f').slice(0, -1);
    peak = Math.max(peak, r.peak); maxLen = Math.max(maxLen, r.text.length); maxLines = Math.max(maxLines, lines.length);
    console.log(String(s).padStart(3) + ' ' + lines.join(' | '));
  }
  console.log(`галактика ${g}: самое длинное описание ${maxLen} знаков, строк не больше ${maxLines}, в буфере не больше ${peak}`);
}
