// Баланс: сколько объектов появляется за час полёта обычного образа, по типам, для данного строя системы.
// Игрок разворачивается от планеты и летит прямо, неуязвим, не стреляет; раз в 60 с все корабли убираются (как бомбой), чтобы
// не копились. Считается прирост числа объектов каждого типа между опросами (раз в 10 кадров), и число проходов
// главного цикла (по MCNT). node v06c/tools/balance.mjs <gov 0..7> [кадров = 90000] [беглец 0|1]
import { createVector } from './v06c.mjs';
const GOV = +(process.argv[2] ?? 0), FRAMES = +(process.argv[3] || 90000), FUG = +(process.argv[4] || 0), STEP = 10;
const g = createVector('elite'), L = g.L;
const K = { SPACE: [7, 0x80], N: [5, 0x40], F1: [1, 0x08], S: [6, 0x08] };
const key = (k, d) => g.key(K[k][0], K[k][1], d);
const press = (k) => { key(k, true); g.frame(20); key(k, false); };
const launch = () => { g.frame(300); press('N'); g.frame(200); press('SPACE'); g.frame(200); press('F1'); g.frame(300);
  key('S', true); for (let i = 0; i < 400 && !(g.rd(L.K_ + 8) & 0x80); i++) g.frame(5); key('S', false);   // планета за спиной
  key('SPACE', true); g.frame(2500); key('SPACE', false); };
launch();
const spawn = {}, cnt = () => { const c = {}; for (let i = 2; i < 13; i++) { const t = g.rd(L.FRIN + i); if (t && t < 128) c[t] = (c[t] || 0) + 1; } return c; };
let prev = cnt(), loops = 0, mc = g.rd(L.MCNT), deaths = 0, sst = 0, polls = 0;
for (let f = 0; f < FRAMES; f += STEP) {
  g.frame(STEP);
  if (g.rd(L.QQ12) !== 0) { deaths++; launch(); prev = cnt(); continue; }
  g.wr(L.gov, [GOV]); g.wr(L.FIST, [FUG ? 0xFF : 0]);
  g.wr(L.ENERGY, [255]); g.wr(L.FSH, [255]); g.wr(L.ASH, [255]); g.wr(L.GNTMP, [0]); g.wr(L.CABTMP, [0]); g.wr(L.ALTIT, [255]);
  const m = g.rd(L.MCNT); loops += (mc - m) & 255; mc = m;
  polls++; if (g.rd(L.SSPR)) sst++;
  const c = cnt(); for (const t in c) if (c[t] > (prev[t] || 0)) spawn[t] = (spawn[t] || 0) + c[t] - (prev[t] || 0); prev = c;
  if (f % 3000 === 2990) { for (let i = 2; i < 13; i++) { const t = g.rd(L.FRIN + i); if (t && t < 128) { const a = L.K_ + 36 * i + 31; g.wr(a, [g.rd(a) | 0x80]); } } }
}
const h = FRAMES / 180000;
console.log(JSON.stringify({ gov: GOV, fug: FUG, hours: h, loopsPerSec: +(loops / (FRAMES / 50)).toFixed(2), deaths, stationShare: +(sst / polls).toFixed(2),
  perHour: Object.fromEntries(Object.entries(spawn).map(([t, n]) => [t, +(n / h).toFixed(1)])) }));
