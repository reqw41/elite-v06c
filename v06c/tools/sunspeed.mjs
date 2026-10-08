// Сколько стоит залитое солнце: такты процедуры PLANET для солнца на разных расстояниях — первая отрисовка и
// перерисовка со сдвигом (так идёт каждый проход цикла, пока солнце в кадре). Для сравнения — средний проход цикла
// полёта в сценарии launch: 352 677 тактов (v06c/tools/speed.mjs). node v06c/tools/sunspeed.mjs
import { createVector } from './v06c.mjs';
const g = createVector('elite'), L = g.L; g.frame(40);
const PASS = 352677;
console.log('расстояние z | строк на экране | первая отрисовка, тактов | перерисовка со сдвигом, тактов (мс) | доля среднего прохода');
for (const zhi of [0x60, 0x30, 0x18, 0x0C, 0x06, 0x03]) {
  g.call('TT66', { a: 0 });
  const mk = (dx) => { const w = new Array(36).fill(0); w[0] = dx; w[1] = 0x04; w[4] = 0x02; w[5] = 0x80; w[7] = 0; w[8] = zhi >> 4; w[7] = (zhi << 4) & 255; [9, 15, 21].forEach((o, k) => { w[o + 2 * k + 1] = 0x60; }); return w; };
  g.wr(L.LSO, [0xFF, ...new Array(191).fill(0)]); g.wr(L.SUNX, [128, 0]); g.wr(L.LSX2, [0xFF]); g.wr(L.LSY2, [0xFF]);
  const a = g.call('PLANET', { mem: { INWK: mk(0), TYPE: 129 } }, 4e7).cycles;
  let rows = 0; for (let y = 0; y < 192; y++) { let on = 0; for (let c = 0; c < 32; c++) on |= g.rd(0xE000 + c * 256 + 255 - y); if (on) rows++; }
  let b = 0; for (let i = 1; i <= 4; i++) b += g.call('PLANET', { mem: { INWK: mk(i * 0x40), TYPE: 129 } }, 4e7).cycles; b /= 4;
  console.log(`${(zhi << 12).toString(16).padStart(6)}h | ${String(rows).padStart(3)} | ${String(a).padStart(8)} | ${b.toFixed(0).padStart(8)} (${(b / 3000).toFixed(0)}) | ${(b / PASS * 100).toFixed(0)} %`);
}
