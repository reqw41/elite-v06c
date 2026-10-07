// T27, рубеж М2: сценарий эталона целиком. Образ стенда elite_t.rom идёт с первой команды по тем же шагам, что
// tools/oracle/scenario.js: заставки, станция, взлёт, полёт, разгон, огонь, поворот. Состояние сравнивается на
// каждом проходе цикла. node v06c/test/t27.mjs [сценарий = launch] [сколько проходов, по умолчанию все]
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { createVector, savePng, ROOT } from '../tools/v06c.mjs';
import { bbcView, vecView, bbcDash, vecDash, firstDiff } from '../tools/screen.mjs';
const require = createRequire(import.meta.url);
const { BBC } = require(path.join(ROOT, 'tools/oracle/bbc.js'));
const { SCN } = require(path.join(ROOT, 'tools/oracle/scenario.js'));
const name = process.argv[2] || 'launch', LIMIT = +(process.argv[3] || 1e9);
const ROM = process.env.ROM || 'elite_t', FREE = !!process.env.FREE;      // FREE=1 — без сверки (быстрая сборка)
const m = createVector(ROM), L = m.L, WS = L.WS, bbc = new BBC({ sched: true }), B = bbc.lab;
bbc.mem.set(fs.readFileSync(path.join(ROOT, 'v06c/data/font.bin')), 0xC000);     // эталон печатает нашим шрифтом
const AREAS = [[0x0000, 0x0100], [0x0100, 0x01C0], [0x0300, 0x0372], [0x0900, 0x0F34], [0x0F48, 0x0F51]];
// вне сравнения: рабочие ячейки рисования и печати на BBC и указатели (в них адреса своей машины)
const SKIP = new Set();
const skip = (n, len = 1) => { for (let k = 0; k < len; k++) SKIP.add((typeof n === 'number' ? n : B[n]) + k); };
for (const [n, len] of [['P', 3], ['Q', 1], ['R', 1], ['S', 1], ['SWAP', 1], ['YSAV', 1], ['SC', 2], ['X1', 1], ['V', 2], ['XX0', 2], ['INF', 2], ['SLSP', 2],
  ['YSAV2', 1], ['XSAV2', 1], ['T', 1], ['T1', 1]]) skip(n, len);
skip(B.INWK + 33, 2); for (let i = 0; i < 13; i++) skip(0x900 + 36 * i + 33, 2);
const names = {}; for (const [n, a] of Object.entries(B)) if (a < 0x0F51 && n !== 'S%' && !(a in names)) names[a] = n;
const cell = (a) => { for (let k = 0; k < 40; k++) if ((a - k) in names) return names[a - k] + (k ? '+' + k : ''); return '&' + a.toString(16); };
function compare() {
  const diff = [], vm = m.mem();
  for (const [lo, hi] of AREAS) for (let a = lo; a < hi && diff.length < 10; a++) if (vm[WS + a] !== bbc.mem[a] && !SKIP.has(a)) diff.push(`${cell(a)}: BBC ${bbc.mem[a]}, Вектор ${vm[WS + a]}`);
  let d = firstDiff(vecView(vm), bbcView(bbc.mem)); if (d) diff.push(`обзор: столбец ${d.i % 32}, строка ${Math.floor(d.i / 32)}: Вектор ${d.a}, BBC ${d.b}`);
  d = firstDiff(vecDash(vm), bbcDash(bbc.mem)); if (d) diff.push(`панель: x=${d.i & 255}, строка ${192 + (d.i >> 8)}: Вектор ${d.a}, BBC ${d.b}`);
  return diff.length ? diff.join('; ') : null;
}
// клавиша BBC → матрица Вектора по таблице образа
const rows = new Array(8).fill(0);
const setKey = (code, down) => { const i = m.rd(L.kb_rev + code); if (i >= 64) throw new Error('клавиша BBC &' + code.toString(16) + ' не назначена'); if (down) rows[i >> 3] |= 1 << (i & 7); else rows[i >> 3] &= ~(1 << (i & 7)); m.wr(L.kb_rows, rows); };
const prof = new Float64Array(0x10000), profAll = new Float64Array(0x10000);   // prof — только проходы полёта
let idx = 0, fail = null, tv = 0, tb = 0, flightV = 0, flightB = 0, flightN = 0;
const t0 = Date.now();
outer: for (const [label, n, down = [], up = [], k = 2] of SCN[name]) {
  down.forEach((c) => { bbc.keys.add(c); setKey(c, true); }); up.forEach((c) => { bbc.keys.delete(c); setKey(c, false); });
  for (let i = 0; i < n; i++, idx++) {
    if (idx >= LIMIT) break outer;
    const c0 = bbc.cpu.cycles;
    bbc.pass(label, k);
    let cyc;
    const inFlight = label === 'MLOOP' && bbc.mem[B.QQ12] === 0 && idx > 170;
    try { cyc = m.runTo(label, 3e7, inFlight ? prof : profAll); } catch (e) { fail = `проход ${idx} (${label}): ${e.message}; метка рядом: ${Object.entries(L).filter(([, a]) => a <= (m.cpu.pc & 0xffff)).sort((a, b) => b[1] - a[1])[0][0]}`; break outer; }
    for (let f = 0; f < k; f++) { m.wr('DL', [30]); const la = m.rd('LASCT'); if (la) m.wr('LASCT', [la - 1]); }   // кадры по расписанию, как tick() эталона
    tv += cyc; tb += bbc.cpu.cycles - c0;
    if (inFlight) { flightV += cyc; flightB += bbc.cpu.cycles - c0; flightN++; }
    const d = FREE ? null : compare();
    if (d) { fail = `проход ${idx} (${label}): ${d}`; break outer; }
  }
}
console.log(`${fail ? 'FAIL' : 'OK  '} сценарий ${name}: ${idx} проходов от включения — обзор, панель и рабочие области = эталон${fail ? ' — ' + fail : ''}`);
m.frame(0);
if (flightN) {
  const b = flightB / flightN / 2e3, v = flightV / flightN / 3e3;
  console.log(`полёт, ${flightN} проходов: 6502 ${(flightB / flightN).toFixed(0)} тактов (${b.toFixed(1)} мс), i8080 ${(flightV / flightN).toFixed(0)} тактов (${v.toFixed(1)} мс); Вектор/BBC ${(v / b).toFixed(2)}; проходов в секунду: ${(1000 / b).toFixed(1)} → ${(1000 / v).toFixed(1)}`);
}
// профиль Вектора по процедурам (метка с прописной буквы или общий помощник), весь сценарий
const HELP = new Set(['mul8', 'mulhi', 'divlog', 'dash_xor', 'dash_put', 'dash_eor', 'li_div', 'li_addr', 'lo_swhook', 'entry', 'isr', 'cls_all', 'sq_init']);
const own = Object.entries(L).filter(([n, a]) => a >= 0x100 && a < L.XX21 && (process.env.FINE || /^[A-Z]/.test(n) || HELP.has(n))).sort((a, b) => a[1] - b[1]);
const cost = {}; let total = 0, kk = 0;
for (let a = 0x100; a < 0x10000; a++) { while (kk + 1 < own.length && own[kk + 1][1] <= a) kk++; if (prof[a]) { cost[own[kk][0]] = (cost[own[kk][0]] || 0) + prof[a]; total += prof[a]; } }
console.log(`профиль Вектора в полёте (${flightN} проходов, ${(total / 3e6).toFixed(1)} с машинного времени), доля тактов по процедуре, где стоит команда:`);
for (const [n, c] of Object.entries(cost).sort((a, b) => b[1] - a[1]).slice(0, process.env.FINE ? 44 : 22)) console.log(`${(100 * c / total).toFixed(1).padStart(5)} %  ${n}`);
console.log(fail ? 'ПРОВАЛ' : FREE ? `T27: прогон ${ROM} без сверки` : 'T27: всё совпало');
process.exit(fail ? 1 : 0);
