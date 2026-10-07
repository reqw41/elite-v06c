// Сколько перенесено: процедуры BBC (блоки исходника с «Name:») против меток образа Вектора.
// node tools/analysis/progress.js   (перед этим sh v06c/build.sh)
'use strict';
const fs = require('fs');
const path = require('path');
const { BBC } = require('../oracle/bbc.js');
const ROOT = path.resolve(__dirname, '../..');
const m = new BBC({ sched: true }), L = m.lab;
const src = fs.readFileSync(path.join(ROOT, 'orig/bbc/cassette/1-source-files/main-sources/elite-source.asm'), 'latin1');
const cat = {}, type = {}, starts = [];
let cur = null;
for (const l of src.split('\n')) {
  let k = l.match(/^\\\s+Name:\s+(\S+)/); if (k) { cur = k[1]; continue; }
  k = l.match(/^\\\s+Type:\s+(\S+)/); if (k && cur) { type[cur] ??= k[1]; continue; }
  k = l.match(/^\\\s+Category:\s+(.*\S)/); if (k && cur) { cat[cur] ??= k[1]; continue; }
  k = l.match(/^\.(\S+)/); if (k && cur && L[k[1]] >= L['S%'] && L[k[1]] < L.XX21 && !starts.some((s) => s.n === cur)) starts.push({ a: L[k[1]], n: cur });
}
starts.sort((a, b) => a.a - b.a);
const sym = fs.readFileSync(path.join(ROOT, 'v06c/build/elite.sym'), 'latin1');
const have = new Set([...sym.matchAll(/^([A-Za-z_][\w.]*):/gm)].map((x) => x[1]));
const stubs = new Set([...fs.readFileSync(path.join(ROOT, 'v06c/src/stubs.asm'), 'latin1').matchAll(/^([A-Za-z_]\w*):/gm)].map((x) => x[1]));
const vname = (n) => { const s = n.replace(/%/g, '_'); return ['cpl'].includes(s) ? s + '_' : s; };
const by = {}; let tb = 0, db = 0, tn = 0, dn = 0;
for (let i = 0; i < starts.length; i++) {
  const s = starts[i], size = (starts[i + 1] ? starts[i + 1].a : L.XX21) - s.a;
  if (type[s.n] !== 'Subroutine') continue;
  const done = have.has(vname(s.n)) && !stubs.has(vname(s.n));
  const c = (by[cat[s.n] || '?'] ??= { n: 0, d: 0, b: 0, db: 0, left: [] });
  c.n++; c.b += size; tn++; tb += size;
  if (done) { c.d++; c.db += size; dn++; db += size; } else c.left.push(s.n);
}
console.log('раздел | процедур: сделано из всего | байт BBC: сделано из всего | не сделано');
for (const [c, v] of Object.entries(by).sort((a, b) => b[1].b - a[1].b)) console.log(`${c} | ${v.d} из ${v.n} | ${v.db} из ${v.b} | ${v.left.join(' ')}`);
console.log(`ВСЕГО | ${dn} из ${tn} | ${db} из ${tb} (${(100 * db / tb).toFixed(0)} %)`);
