// Цена планеты при тангаже: PLANET обычного образа на разных радиусах, центр смещается по вертикали на STEP точек
// за вызов (как при зажатом тангаже). Печатает путь (точками / отрезками) и такты на вызов (рисование новой и
// стирание прежней). node tools/analysis/planet_bench.mjs [STEP = 2]
import { createVector } from '../../v06c/tools/v06c.mjs';
const STEP = +(process.argv[2] || 2);
const m = createVector(process.env.IMG || 'elite'), L = m.L; m.frame(60);
const VIEW = 0xC000;
for (let a = VIEW; a < VIEW + 0x2000; a++) if ((a & 255) >= 64) m.wr(a, [0]);
m.wr(L.LSX2, [0xFF]); m.wr(L.LSP, [1]);
if (process.env.SEG) {                                       // SEG=n — радиус от n рисовать отрезками (cp 3 / jp c в pc_try -> cp n / jp nc)
  let a = L.pc_try; while (!(m.rd(a) === 0xFE && m.rd(a + 1) === 3)) a++;
  m.wr(a + 1, [+process.env.SEG]); m.wr(a + 2, [0xD2]); }
// y в INWK+3..5: сдвиг центра на экране ≈ y / z; z = (zs, zh): радиус = 24576 / (zs·256 + zh)
const PR = process.env.PROF ? new Float64Array(0x10000) : null;
for (const R of (process.env.R ? process.env.R.split(',').map(Number) : [40, 80, 110, 127, 140, 180, 250, 400])) {
  if (PR) PR.fill(0);
  const z = Math.round(24576 / R), zs = z >> 8, zh = z & 255;
  let cyc = 0, n = 0, pts = 0;
  for (let i = 0; i < 40; i++) {
    const dy = ((i % 20) - 10) * STEP, y = Math.round(dy * z), ya = Math.abs(y);
    const c = m.call('PLANET', { mem: { TYPE: 128, INWK: [0, 0, 0, ya & 255, (ya >> 8) & 255, (y < 0 ? 0x80 : 0) | (ya >> 16), 0, zh, zs] }, prof: i >= 2 ? PR : null }, 5e6);
    if (i >= 2) { cyc += c.cycles; n++; }
  }
  if (PR) { const labs = Object.entries(L).filter(([k, a]) => typeof a === 'number' && a >= 0x100 && a < 0xB000 && /^[A-Za-z]/.test(k)).sort((x, y) => x[1] - y[1]);
    const cost = {}; let k = 0; for (let a = 0; a < 0x10000; a++) { if (!PR[a]) continue; while (k + 1 < labs.length && labs[k + 1][1] <= a) k++; const nm = a < 0x100 ? 'low' : labs[k][0]; cost[nm] = (cost[nm] || 0) + PR[a]; }
    console.log(Object.entries(cost).sort((x, y) => y[1] - x[1]).slice(0, +process.env.PROF).map(([nm, c]) => `${nm} ${(c / n).toFixed(0)}`).join(', ')); }
  console.log(`радиус ${String(R).padStart(3)}: ${m.rd(L.LSX2) === 1 ? 'точками ' : 'отрезками'} ${(cyc / n).toFixed(0).padStart(7)} тактов на вызов`);
}
