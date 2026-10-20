// Кэш солнца (sun_red, обычный образ): солнце с прежними x, y и радиусом не перерисовывается, пока не прошло
// SUN_FR кадров (бахрома); при любой перемене, после стирания (WPLS) и очистки (FLFLLS) — рисуется сразу. После
// каждого вызова экран второй плоскости равен строкам LSO вокруг SUNX, строки солнца — в пределах y ± радиус.
// sh v06c/build.sh && node v06c/test/suncache.mjs [шагов = 1500]
import { createVector } from '../tools/v06c.mjs';
const N = +(process.argv[2] || 1500);
let bad = 0; const fail = (s) => { if (++bad <= 10) console.log('FAIL ' + s); };
const m = createVector('elite'), L = m.L; m.frame(60);
const RED = 0xE000, ROWS = 192, FR = 16;
const clear = () => { for (let a = 0xC000; a < 0x10000; a++) if ((a & 255) >= 64) m.wr(a, [0]); };
clear(); m.call('FLFLLS');
const pix = (x, y) => (m.rd(RED + (x >> 3) * 256 + 255 - y) >> (7 - (x & 7))) & 1;
const s16 = (v) => (v << 16) >> 16;
const edges = (cx, h) => { const r = cx + h, l = cx - h; if (r < 0 || l > 255) return null; const a = l < 0 ? 2 : l, b = r > 255 ? 254 : r; return [Math.min(a, b), Math.max(a, b)]; };
let rs = 777; const rnd = (n) => { rs = (rs * 1103515245 + 12345) >>> 0; return (rs >>> 8) % n; };
let X = 100, Y = 80, K = 30, fr = 0, last = null, drawn = 0, skipped = 0, wiped = 0;
const st = { hold: 0, move: 0, jump: 0, wipe: 0, cls: 0 };
for (let i = 0; i < N; i++) {
  const r = rnd(20); let act;
  if (r < 9) act = 'hold'; else if (r < 14) act = 'move'; else if (r < 16) act = 'jump'; else if (r < 18) act = 'wipe'; else act = 'cls';
  st[act]++;
  if (act === 'move') { const k = rnd(3); if (k === 0) X += rnd(3) - 1 || 1; else if (k === 1) Y += rnd(3) - 1 || 1; else K = Math.max(1, Math.min(200, K + (rnd(2) ? 1 : -1))); }
  if (act === 'jump') { K = 1 + rnd(120); X = -100 + rnd(450); Y = -80 + rnd(350); }
  if (act === 'wipe') { m.call('wpls_red'); wiped++; for (let y = 0; y < ROWS; y++) for (let x = 0; x < 256; x++) if (pix(x, y)) { fail(`#${i} WPLS: осталась точка (${x}, ${y})`); y = ROWS; break; } }
  if (act === 'cls') { clear(); m.call('FLFLLS'); }
  fr = (fr + rnd(act === 'hold' ? 12 : 4)) & 255;
  const lsxBefore = m.rd(L.LSX);
  const c = m.call('sun_red', { mem: { K: [K], K3: [X & 255, (X >> 8) & 255], K4: [Y & 255, (Y >> 8) & 255], v_frames: [fr, 0] } }, 5e6);
  const same = last && last.X === X && last.Y === Y && last.K === K && lsxBefore !== 0xFF;
  const want = !same || ((fr - last.t) & 255) >= FR;
  const did = c.cycles > 2000;
  if (did !== want) fail(`#${i} ${act}: солнце ${did ? 'перерисовано' : 'пропущено'}, ожидалось ${want ? 'рисовать' : 'пропустить'} (кадров ${last ? (fr - last.t) & 255 : '-'}, LSX ${lsxBefore})`);
  if (did) { drawn++; last = { X, Y, K, t: fr }; } else skipped++;
  const lsx = m.rd(L.LSX), cx = s16(m.rd16(L.SUNX));
  if (lsx !== 0xFF && cx !== X) fail(`#${i}: SUNX ${cx}, а x ${X}`);
  for (let y = 1; y < ROWS; y++) {
    const h = m.rd(L.LSO + y), e = h ? edges(cx, h) : null;
    if (h && Math.abs(y - Y) > K + 1) { fail(`#${i}: строка ${y} солнца (полуширина ${h}) дальше радиуса ${K} от y ${Y}`); break; }
    let ok = true; for (let x = 0; x < 256; x++) { const w = e && x >= e[0] && x < e[1] ? 1 : 0; if (pix(x, y) !== w) { fail(`#${i} ${act}: точка (${x}, ${y}) ${pix(x, y)}, по LSO ${w}`); ok = false; break; } }
    if (!ok) break;
  }
  if (bad > 10) break;
}
console.log(`шагов ${N}: ${Object.entries(st).map(([k, v]) => k + ' ' + v).join(', ')}; нарисовано ${drawn}, пропущено ${skipped}`);
console.log(bad ? `ПРОВАЛ: ${bad}` : 'SUNCACHE: всё совпало');
process.exit(bad ? 1 : 0);
