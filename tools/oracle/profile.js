// Профиль эталона: какие процедуры исполняются в сценарии и сколько тактов 6502 на проход цикла.
// node tools/oracle/profile.js [сценарий=title] [с какого прохода=0]
// Процедура — блок исходника с заголовком «Name:»; такты относятся к блоку, в котором стоит команда.
'use strict';
const fs = require('fs');
const path = require('path');
const { BBC } = require('./bbc.js');
const { SCN } = require('./scenario.js');
const name = process.argv[2] || 'title', from = +(process.argv[3] || 0);
const m = new BBC({ sched: true }), L = m.lab;
const ORIG = process.env.ELITE_ORIG || path.resolve(__dirname, '../../orig');
const src = fs.readFileSync(path.join(ORIG, 'bbc/cassette/1-source-files/main-sources/elite-source.asm'), 'latin1');
const cat = {}, starts = [];
let cur = null;
for (const l of src.split('\n')) {
  let k = l.match(/^\\\s+Name:\s+(\S+)/); if (k) { cur = k[1]; continue; }
  k = l.match(/^\\\s+Category:\s+(.*\S)/); if (k && cur) { cat[cur] ??= k[1]; continue; }
  k = l.match(/^\.(\S+)/); if (k && cur && L[k[1]] >= L['S%'] && !starts.some((s) => s.a === L[k[1]])) { if (!starts.some((s) => s.n === cur)) starts.push({ a: L[k[1]], n: cur }); }
}
starts.sort((a, b) => a.a - b.a);
const owner = new Array(0x10000).fill(null);
for (let i = 0; i < starts.length; i++) for (let a = starts[i].a; a < (starts[i + 1] ? starts[i + 1].a : m.codeEnd); a++) owner[a] = starts[i].n;
const cyc = {}, calls = {};
let passes = 0, total = 0, on = false;
const step0 = m.step.bind(m);
m.step = function () {
  const pc = m.cpu.pc, c0 = m.cpu.cycles, o = owner[pc] || '(вне игры)';
  step0();
  if (on) { cyc[o] = (cyc[o] || 0) + m.cpu.cycles - c0; total += m.cpu.cycles - c0; }
};
for (const a of Object.keys(L)) { /* вызовы считаются по приходу в первую команду блока */ }
const first = new Map(starts.map((s) => [s.a, s.n]));
const stepC = m.step;
m.step = function () { if (on) { const n = first.get(m.cpu.pc); if (n) calls[n] = (calls[n] || 0) + 1; } stepC(); };
let idx = 0;
for (const [label, n, down = [], up = [], k = 2] of SCN[name]) {
  down.forEach((c) => m.keys.add(c)); up.forEach((c) => m.keys.delete(c));
  for (let i = 0; i < n; i++, idx++) { on = idx >= from; m.pass(label, k); if (on) passes++; }
}
const rows = Object.entries(cyc).sort((a, b) => b[1] - a[1]);
console.log(`сценарий ${name}, проходов ${passes}: ${Math.round(total / passes)} тактов 6502 на проход (${(total / passes / 2e3).toFixed(1)} мс при 2 МГц), процедур ${rows.length}`);
console.log('доля  | тактов на проход | приходов на проход | процедура (раздел)');
for (const [n, c] of rows) console.log(`${(100 * c / total).toFixed(1).padStart(5)} | ${String(Math.round(c / passes)).padStart(16)} | ${((calls[n] || 0) / passes).toFixed(1).padStart(18)} | ${n} (${cat[n] || ''})`);
