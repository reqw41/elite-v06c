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
  // here: система — текущая (QQ8 = 0), тогда проверяются особые описания RUPLA; tp — байт миссий TP.
  describe(galaxy, system, rand = [0, 0, 0, 0], { here = false, tp = 0 } = {}) {
    const m = this.mem, L = this.lab, cpu = this.cpu, RET = 0xffa0;
    m.fill(0); m.set(this.image, LOAD);
    m.set(seeds(galaxy, system), L.QQ15);
    m.set(rand, L.RAND);
    m[L.QQ8] = here ? 0 : 1;    // расстояние не ноль: особые описания (RUPLA) не проверяются
    m[L.TP] = tp;
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

// Текст миссии: слово номер token таблицы TKN1 через DETOK. Перехвачены печать знака (в журнал идут знак и
// текстовая позиция XC, YC на этот момент), очистка экрана TT66 («{cls}»), задержка DELAY, ожидание клавиши с
// кораблём PAUSE («{ship}») и опрос клавиш RDKEY (клавиша то отпущена, то нажата: PAUSE2 проходит, «{key}»).
Disc.prototype.detok = function (token, { gcnt = 0, name = 'JAMESON' } = {}) {
  const m = this.mem, L = this.lab, cpu = this.cpu, RET = 0xffa0;
  m.fill(0); m.set(this.image, LOAD);
  m.set(fs.readFileSync(path.join(OUT, 'WORDS.bin')), 0x0400);          // основной словарь QQ18
  m[L.GCNT] = gcnt; m[L.QQ17] = 0x80; m[L.XC] = 1; m[L.YC] = 1;
  const NA = 0x1181;                                                    // NA%: имя командира (метка полётной части листинга)
  [...name].forEach((c, i) => { m[NA + i] = c.charCodeAt(0); }); m[NA + name.length] = 13;
  cpu.a = token; cpu.x = cpu.y = 0; cpu.p = FLAGS.U | FLAGS.I; cpu.s = 0xfd;
  m[0x1fe] = (RET - 1) & 0xff; m[0x1ff] = (RET - 1) >> 8;
  cpu.pc = L.DETOK;
  const out = []; let key = 0; const start = cpu.cycles;
  while (cpu.pc !== RET) {
    if (cpu.pc === L.CHPR) { out.push([String.fromCharCode(cpu.a), m[L.XC], m[L.YC]]); cpu.p &= ~FLAGS.C; cpu.rts(); continue; }
    // TT66 дисковой версии, кроме очистки, возвращает печать к «как в предложении» (MT2) и ставит «не внутри слова»
    if (cpu.pc === L.TT66) { out.push(['{cls}', m[L.XC], m[L.YC]]); m[L.DTW1] = 0x20; m[L.DTW6] = 0; m[L.DTW2] = 0x80; m[L.QQ17] = 0x80; cpu.rts(); continue; }
    if (cpu.pc === L.DELAY) { cpu.rts(); continue; }
    if (cpu.pc === L.PAUSE) { out.push(['{ship}', m[L.XC], m[L.YC]]); cpu.rts(); continue; }
    if (cpu.pc === L.RDKEY) { key ^= 1; if (key === 0) out.push(['{key}', m[L.XC], m[L.YC]]); cpu.a = cpu.x = key ? 0 : 0x62; cpu.p = (cpu.p & ~0x82) | (key ? 2 : 0); cpu.rts(); continue; }
    cpu.step();
    if (cpu.cycles - start > 6e7) throw new Error(`DETOK ${token}: не вернулась`);
  }
  return out;
};

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
