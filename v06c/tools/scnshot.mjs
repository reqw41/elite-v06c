// Снимок экрана Вектора после N проходов сценария (без сверки): node v06c/tools/scnshot.mjs <сценарий> <N> [файл.png]
// Образ стенда elite_t.rom идёт по шагам сценария; в конце — кадр с палитрой и PNG. Печатает, сколько точек
// зажжено в плоскости обзора и во второй плоскости (второй цвет).
import path from 'node:path';
import { createRequire } from 'node:module';
import { createVector, savePng, ROOT } from './v06c.mjs';
const require = createRequire(import.meta.url);
const { BBC } = require(path.join(ROOT, 'tools/oracle/bbc.js'));
const { SCN, addr } = require(path.join(ROOT, 'tools/oracle/scenario.js'));
const [name = 'fight', N = '190', out = path.join(ROOT, 'work/v06c', `scn-${name}-${N}.png`)] = process.argv.slice(2);
const m = createVector(process.env.ROM || 'elite_t'), L = m.L, WS = L.WS, B = new BBC({ sched: true }).lab;
const rows = new Array(8).fill(0); let mod = 0;
const setKey = (code, down) => { let i = m.rd(L.kb_rev + code); if (i === 255) return;
  if (i & 0x80) { const bit = 1 << (i & 7); mod = down ? mod | bit : mod & ~bit; m.wr(L.kb_mod, [mod]); return; }
  if (i & 0x40) { i &= 63; mod = down ? mod | 0x20 : mod & ~0x20; m.wr(L.kb_mod, [mod]); }
  if (down) rows[i >> 3] |= 1 << (i & 7); else rows[i >> 3] &= ~(1 << (i & 7)); m.wr(L.kb_rows, rows); };
const VL = { t: 'tt217_t', t2: 'tt217_t2', D2: 'death_d2' };
let idx = 0;
outer: for (const step of SCN[name]) {
  const [label, n, down = [], up = [], k = 2, poke, calls] = step;
  const vput = (map) => { for (const [a, v] of Object.entries(map || {})) m.wr(WS + addr(B, a), v); };
  vput(poke);
  for (const [lab, { a = 0, x = 0, y = 0, c = 0 } = {}, mem] of calls || []) { vput(mem); m.call(lab, { a, b: x, c: y, cf: c }); }
  down.forEach((c) => setKey(c, true)); up.forEach((c) => setKey(c, false));
  for (let i = 0; i < n; i++, idx++) { if (idx >= +N) break outer; m.runTo(VL[label] || label, 3e7);
    for (let f = 0; f < k; f++) { m.wr('DL', [30]); const la = m.rd('LASCT'); if (la) m.wr('LASCT', [la - 1]); } }
}
const mem = m.mem(); let w = 0, r = 0;
const bits = (v) => { let c = 0; while (v) { c += v & 1; v >>= 1; } return c; };
for (let c = 0; c < 32; c++) for (let y = 0; y < 192; y++) { w += bits(mem[0xC000 + c * 256 + 255 - y]); r += bits(mem[0xE000 + c * 256 + 255 - y]); }
m.frame(+(process.env.FRAMES || 6)); savePng(m.bmp(), out);
console.log(`${name}, проход ${idx}: в обзоре белых точек ${w}, второго цвета ${r}; снимок ${out}`);
