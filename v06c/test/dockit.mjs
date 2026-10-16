// Автопилот стыковки дисковой версии: DOCKIT на Векторе против DOCKIT полётного кода дисковой BBC
// (tools/oracle/disc.js) на случайных положениях корабля и станции; сверяются решения (INWK+27…30), RAT2,
// XX15 и K3. Затем — сама игра: взлёт, включение автопилота, проходы цикла до стыковки.
// sh v06c/build.sh && node v06c/test/dockit.mjs [случаев = 4000]
import path from 'node:path';
import { createRequire } from 'node:module';
import { createVector, savePng, ROOT } from '../tools/v06c.mjs';
const require = createRequire(import.meta.url);
const { DiscCode } = require(path.join(ROOT, 'tools/oracle/disc.js'));
const N = +(process.argv[2] || 4000);
const d = new DiscCode('flight'), m = createVector('elite'), L = m.L;
m.frame(40);
let bad = 0; const fail = (s) => { if (++bad <= 8) console.log('FAIL ' + s); };
let rs = 777; const rnd = (n = 256) => { rs = (rs * 1103515245 + 12345) >>> 0; return ((rs >>> 16) % n); };
// ортонормированная тройка длины 96 в формате игры: младший байт 0, старший — знак и величина
const vec = () => { let v; do { v = [rnd() - 128, rnd() - 128, rnd() - 128]; } while (Math.hypot(...v) < 20); const k = 96 / Math.hypot(...v); return v.map((c) => c * k); };
const cross = (a, b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
const sm = (c) => { const q = Math.min(96, Math.round(Math.abs(c))); return [rnd(), q | (c < 0 ? 0x80 : 0)]; };
const frame = () => { const n = vec(); let r = cross(n, vec()); const kr = 96 / (Math.hypot(...r) || 1); r = r.map((c) => c * kr); const s = cross(n, r).map((c) => c / 96);
  return [...n.flatMap(sm), ...r.flatMap(sm), ...s.flatMap(sm)]; };
const pos = (far) => [0, 1, 2].flatMap(() => { const big = far ? rnd(4) === 0 : false; return [rnd(), rnd(far ? 256 : 48), (big ? rnd(3) : 0) | (rnd(2) << 7)]; });
const ph = {};
for (let i = 0; i < N; i++) {
  const player = rnd(4) !== 0, stn = new Array(36).fill(0), plan = new Array(36).fill(0), inwk = new Array(36).fill(0);
  pos(i % 5 === 0).forEach((b, k) => { stn[k] = b; }); frame().forEach((b, k) => { stn[9 + k] = b; });
  pos(true).forEach((b, k) => { plan[k] = b; });
  if (player) { inwk[10 + 4] = 96; inwk[10 + 12] = 0xE0; inwk[18 + 2] = 96; inwk[9 + 1] = 96; inwk[14] = 96; inwk[22] = 0xE0; }
  else { pos(false).forEach((b, k) => { inwk[k] = b; }); frame().forEach((b, k) => { inwk[9 + k] = b; }); }
  if (player) { inwk.fill(0); inwk[10] = 96; inwk[14] = 96; inwk[22] = 0xE0; inwk[18] = 96; }   // ZINF: sidev x, nosev z (обращён), roofv y
  inwk[27] = rnd(40); inwk[28] = rnd(3) - 1 & 255; inwk[29] = rnd(4) ? 0 : rnd(); inwk[30] = rnd(4) ? 0 : rnd();
  const type = player ? 0xE0 : 2 + rnd(6), sspr = rnd(8) ? 1 : 0;   // тип 1 на диске — ракета: её ветвь не переносилась
  d.reset();
  d.poke('K%', plan); d.poke(d.lab['K%'] + 37, stn); d.poke('INWK', inwk); d.poke('TYPE', type); d.poke('SSPR', sspr);
  d.call('DOCKIT');
  m.wr('K_', plan); m.wr(L.K_ + 36, stn); m.wr('INWK', inwk); m.wr('TYPE', [type]); m.wr('SSPR', [sspr]);
  m.call('DOCKIT');
  const want = [...d.peek(d.lab.INWK + 27, 4), d.peek('RAT2'), ...d.peek('XX15', 3), ...d.peek('K3', 9)];
  const got = [27, 28, 29, 30].map((k) => m.rd(L.INWK + k)).concat([m.rd('RAT2')], [0, 1, 2].map((k) => m.rd(L.XX15 + k)), Array.from({ length: 9 }, (_, k) => m.rd(L.K3 + k)));
  const key = `${player ? 'мы' : 'чужой'}: скорость ${want[0] === 1 ? '1' : '—'}, разгон ${want[1]}, крен ${want[2] ? 1 : 0}, тангаж ${want[3] ? 1 : 0}`;
  ph[key] = (ph[key] || 0) + 1;
  if (want.join() !== got.join()) fail(`случай ${i} (${player ? 'мы' : 'тип ' + type}, SSPR ${sspr}):\n  BBC    ${want}\n  Вектор ${got}\n  станция ${stn}\n  INWK ${inwk}`);
}
console.log(`DOCKIT: случаев ${N}, разных исходов ${Object.keys(ph).length}`);
// В игре (обычный образ, настоящие кадры): новый командир, взлёт, стыковочный компьютер, клавиша C — и ждём стыковки.
for (const wait of [150, 600]) {
  const g = createVector('elite'), W = g.L.WS, K = { SPACE: [7, 0x80], N: [5, 0x40], F1: [1, 0x08], C: [4, 0x02] };   // автопилот в полёте — А (русская раскладка, docs/CONTROLS.md)
  const press = (k) => { g.key(K[k][0], K[k][1], true); g.frame(20); g.key(K[k][0], K[k][1], false); };
  g.frame(300); press('N'); g.frame(200); press('SPACE'); g.frame(200); press('F1'); g.frame(wait);
  if (g.rd(g.L.QQ12) !== 0) { fail('взлёт не состоялся'); continue; }
  g.wr(g.L.DKCMP, [0xFF]); press('C');
  if (!g.rd(g.L.auto)) fail('автопилот не включился');
  let f = 0, minE = 255; const speeds = new Set();
  while (g.rd(g.L.QQ12) === 0 && f < 30000) { g.frame(25); f += 25; minE = Math.min(minE, g.rd(g.L.ENERGY)); speeds.add(g.rd(g.L.DELTA));
    if (f === 500) savePng(g.bmp(), path.join(ROOT, `work/v06c/dockit-${wait}.png`)); }
  const ok = g.rd(g.L.QQ12) === 0xFF;
  console.log(`в игре: автопилот через ${wait} кадров после взлёта — ${ok ? 'стыковка' : 'НЕ пристыковался'} за ${f} кадров (${(f / 50).toFixed(0)} с), энергия не ниже ${minE}, скорость до ${Math.max(...speeds)}, автопилот после стыковки ${g.rd(g.L.auto) ? 'включён' : 'выключен'}`);
  if (!ok) fail('стыковки нет'); if (minE < 255) fail('по дороге был урон'); if (g.rd(g.L.auto)) fail('автопилот не выключился');
}
// Отмена автопилота клавишей P (как в дисковой версии): автопилот выключается, корабль остаётся в полёте.
{
  const g = createVector('elite'), K = { SPACE: [7, 0x80], N: [5, 0x40], F1: [1, 0x08], C: [4, 0x02], P: [5, 0x80] };   // автопилот в полёте — А, отключить — О (docs/CONTROLS.md)
  const press = (k) => { g.key(K[k][0], K[k][1], true); g.frame(20); g.key(K[k][0], K[k][1], false); };
  g.frame(300); press('N'); g.frame(200); press('SPACE'); g.frame(200); press('F1'); g.frame(600);
  g.wr(g.L.DKCMP, [0xFF]); press('C'); const on = g.rd(g.L.auto); g.frame(200);
  press('P'); const off = g.rd(g.L.auto); g.frame(1500);
  console.log(`отмена: после C автопилот ${on ? 'включён' : 'выключен'}, после P — ${off ? 'включён' : 'выключен'}; через 30 с ${g.rd(g.L.QQ12) === 0 ? 'всё ещё в полёте' : 'пристыкованы'}`);
  if (!on || off) fail('клавиша P автопилот не выключила'); if (g.rd(g.L.QQ12) !== 0) fail('после отмены корабль пристыковался');
  press('C'); if (!g.rd(g.L.auto)) fail('после отмены автопилот снова не включается');
}
console.log(bad ? `ПРОВАЛ: ${bad}` : 'DOCKIT: всё совпало');
process.exit(bad ? 1 : 0);
