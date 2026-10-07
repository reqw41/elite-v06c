// Какие процедуры эталон исполняет на отрезке сценария. node tools/oracle/coverage.js <сценарий> <от прохода> <до прохода>
// Печатает процедуры (блоки исходника с «Name:») с разделом, размером блока в байтах и числом тактов.
'use strict';
const fs = require('fs');
const path = require('path');
const { BBC } = require('./bbc.js');
const { SCN } = require('./scenario.js');
const name = process.argv[2] || 'launch', from = +(process.argv[3] || 0), to = +(process.argv[4] || 1);
const m = new BBC({ sched: true }), L = m.lab;
const ORIG = process.env.ELITE_ORIG || path.resolve(__dirname, '../../orig');
const src = fs.readFileSync(path.join(ORIG, 'bbc/cassette/1-source-files/main-sources/elite-source.asm'), 'latin1');
const cat = {}, starts = [];
let cur = null;
for (const l of src.split('\n')) {
  let k = l.match(/^\\\s+Name:\s+(\S+)/); if (k) { cur = k[1]; continue; }
  k = l.match(/^\\\s+Category:\s+(.*\S)/); if (k && cur) { cat[cur] ??= k[1]; continue; }
  k = l.match(/^\.(\S+)/); if (k && cur && L[k[1]] >= L['S%'] && !starts.some((s) => s.n === cur)) starts.push({ a: L[k[1]], n: cur });
}
starts.sort((a, b) => a.a - b.a);
const owner = new Array(0x10000).fill(null), size = {};
for (let i = 0; i < starts.length; i++) { const end = starts[i + 1] ? starts[i + 1].a : m.codeEnd; size[starts[i].n] = end - starts[i].a; for (let a = starts[i].a; a < end; a++) owner[a] = starts[i].n; }
const cyc = {}; let on = false;
const step0 = m.step.bind(m);
m.step = () => { const o = owner[m.cpu.pc], c0 = m.cpu.cycles; step0(); if (on && o) cyc[o] = (cyc[o] || 0) + m.cpu.cycles - c0; };
let idx = 0;
outer: for (const [label, n, down = [], up = [], k = 2] of SCN[name]) {
  down.forEach((c) => m.keys.add(c)); up.forEach((c) => m.keys.delete(c));
  for (let i = 0; i < n; i++, idx++) { if (idx >= to) break outer; on = idx >= from; m.pass(label, k); }
}
const byCat = {};
for (const n of Object.keys(cyc)) (byCat[cat[n] || '?'] ??= []).push(n);
let total = 0;
console.log(`сценарий ${name}, проходы ${from}–${to - 1}: процедур ${Object.keys(cyc).length}`);
for (const [c, list] of Object.entries(byCat).sort((a, b) => b[1].length - a[1].length)) {
  const bytes = list.reduce((s, n) => s + size[n], 0); total += bytes;
  console.log(`${c} (${list.length}, ${bytes} Б): ${list.sort().map((n) => `${n}`).join(' ')}`);
}
console.log(`всего байт BBC в этих блоках: ${total}`);
