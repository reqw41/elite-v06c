// Кто читает побочные записи: трассировка эталона. node tools/oracle/liveness.js [сценарий=launch] [процедура ...]
// Для каждой записи в нулевую страницу запоминается процедура-писатель (блок исходника с «Name:»). Чтение той же
// ячейки другой процедурой до следующей записи — «чужое чтение». Вывод: писатель, ячейка → читатели и число
// чтений. Без списка процедур печатаются все писатели. Запись, у которой чужих читателей нет ни в одном
// сценарии, на i8080 можно не делать (это наблюдение по сценарию, а не доказательство для всего кода).
'use strict';
const fs = require('fs');
const path = require('path');
const { BBC } = require('./bbc.js');
const { SCN, prep } = require('./scenario.js');
const name = process.argv[2] || 'launch', only = new Set(process.argv.slice(3));
const m = new BBC({ sched: true }), L = m.lab;
const ORIG = process.env.ELITE_ORIG || path.resolve(__dirname, '../../orig');
const src = fs.readFileSync(path.join(ORIG, 'bbc/cassette/1-source-files/main-sources/elite-source.asm'), 'latin1');
const starts = [];
let cur = null;
for (const l of src.split('\n')) {
  let k = l.match(/^\\\s+Name:\s+(\S+)/); if (k) { cur = k[1]; continue; }
  k = l.match(/^\.(\S+)/); if (k && cur && L[k[1]] >= L['S%'] && !starts.some((s) => s.n === cur)) starts.push({ a: L[k[1]], n: cur });
}
starts.sort((a, b) => a.a - b.a);
const owner = new Array(0x10000).fill('(вне игры)');
for (let i = 0; i < starts.length; i++) for (let a = starts[i].a; a < (starts[i + 1] ? starts[i + 1].a : m.codeEnd); a++) owner[a] = starts[i].n;
const cellName = {}; for (const [n, a] of Object.entries(L)) if (a < 0x100 && !(a in cellName)) cellName[a] = n;
const cell = (a) => { for (let k = 0; k < 40; k++) if ((a - k) in cellName) return cellName[a - k] + (k ? '+' + k : ''); return '&' + a.toString(16); };

const writer = new Array(0x100).fill(null);      // ячейка → кто писал последним
const writes = {}, foreign = {};                  // «писатель ячейка» → число записей; → {читатель: число}
let pcNow = 0;
const rd0 = m.rd.bind(m), wr0 = m.wr.bind(m);
m.rd = (a) => {
  if (a < 0x100 && a !== pcNow) { const w = writer[a], r = owner[pcNow]; if (w && w !== r) { const k = w + ' ' + cell(a); (foreign[k] ??= {})[r] = (foreign[k][r] || 0) + 1; } }
  return rd0(a);
};
m.wr = (a, v) => { if (a < 0x100) { const w = owner[pcNow]; writer[a] = w; const k = w + ' ' + cell(a); writes[k] = (writes[k] || 0) + 1; } return wr0(a, v); };
const step0 = m.step.bind(m);
m.step = () => { pcNow = m.cpu.pc; step0(); };
let passes = 0;
for (const step of SCN[name]) {
  const [label, n, down = [], up = [], k = 2] = step; prep(m, step);
  down.forEach((c) => m.keys.add(c)); up.forEach((c) => m.keys.delete(c));
  for (let i = 0; i < n; i++) { m.pass(label, k); passes++; }
}
console.log(`сценарий ${name}, проходов ${passes}. Писатель, ячейка: записей → чужие читатели (число чтений)`);
const rows = Object.keys(writes).sort();
for (const k of rows) {
  const w = k.split(' ')[0];
  if (only.size && !only.has(w)) continue;
  const f = foreign[k];
  console.log(`${k.padEnd(18)} ${String(writes[k]).padStart(7)} → ${f ? Object.entries(f).sort((a, b) => b[1] - a[1]).map(([r, n]) => `${r} ${n}`).join(', ') : '—'}`);
}
