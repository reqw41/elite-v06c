// Солнце обычного образа (SUN без умножений и корней, planet.asm): после каждого вызова экран обзора равен строкам
// из списка LSO вокруг SUNX (края как в EDGES), полуширина строки — целый корень из K² - V² плюс бахрома не больше
// маски CNT, невидимые строки — 0; WPLS стирает всё. Солнце ходит мелкими шагами (рисуется только разница) и прыгает,
// в том числе за края экрана. Код игры не меняется. sh v06c/build.sh && node v06c/test/sun.mjs [вызовов = 3000]
import { createVector } from '../tools/v06c.mjs';
const N = +(process.argv[2] || 3000);
let bad = 0; const fail = (s) => { if (++bad <= 10) console.log('FAIL ' + s); };
const m = createVector('elite'), L = m.L; m.frame(60);
const VIEW = 0xC000, ROWS = 192;
for (let a = VIEW; a < VIEW + 0x2000; a++) if ((a & 255) >= 64) m.wr(a, [0]);
m.wr(L.LSO, new Array(191).fill(0)); m.wr(L.LSX, [0xFF]);
const pix = (x, y) => (m.rd(VIEW + (x >> 3) * 256 + 255 - y) >> (7 - (x & 7))) & 1;
const s16 = (v) => (v << 16) >> 16;
const code = []; for (let a = 0x100; a < L.rom_end; a++) code.push(m.rd(a));
let rs = 4242; const rnd = (n) => { rs = (rs * 1103515245 + 12345) >>> 0; return (rs >>> 8) % n; };
// края строки полуширины h вокруг cx, как EDGES (за экраном — 2 и 254): null — строки нет на экране
const edges = (cx, h) => { const r = cx + h, l = cx - h; if (r < 0 || l > 255) return null; const a = l < 0 ? 2 : l, b = r > 255 ? 254 : r; return [Math.min(a, b), Math.max(a, b)]; };   // HLOIN — от меньшего до большего
// строки и V по порядку SUN (как на BBC): снизу от TGT; V — от строки 191 или от низа солнца, через центр — вверх
const plan = (Y, K) => { const bot = Y + K, tgt = bot < 0 || bot > 191 ? 191 : bot === 0 ? 1 : bot, d = 191 - Y, out = new Map();
  let V, up; if (d < 0) { V = -d; up = true; } else if (d === 0) { V = 0; up = true; } else if (d < K) { V = d; up = false; } else { V = K; up = false; }
  if (up && V > K) return out;
  for (let c = tgt; c >= 1; c--) { out.set(c, V); if (!up) { V--; if (V === 0) up = true; } else { V++; if (V > K) break; } }
  return out; };
let X = 128, Y = 96, K = 40, calls = 0, drawn = 0, cyc = 0, maxc = 0, rows = 0;
for (let i = 0; i < N; i++) {
  if (rnd(8) === 0) { K = 1 + rnd(rnd(2) ? 64 : 254); X = -200 + rnd(660); Y = -150 + rnd(500); }
  else { X += rnd(7) - 3; Y += rnd(7) - 3; if (rnd(4) === 0) K = Math.max(1, Math.min(254, K + rnd(5) - 2)); }
  const c = m.call('SUN', { mem: { K: [K], K3: [X & 255, (X >> 8) & 255], K4: [Y & 255, (Y >> 8) & 255] } }, 5e6);
  calls++; cyc += c.cycles; maxc = Math.max(maxc, c.cycles);
  const lsx = m.rd(L.LSX), cnt = m.rd(L.CNT), cx = s16(m.rd16(L.SUNX));
  let on = 0, rowsHere = 0; const pl = plan(Y, K);
  for (let y = 1; y < ROWS; y++) {
    const h = m.rd(L.LSO + y), e = h ? edges(cx, h) : null;
    if (h && !e) fail(`#${i} K ${K} (${X}, ${Y}): строка ${y} с полушириной ${h} не на экране, а LSO не 0`);
    if (lsx !== 0xFF && cx === X) {                          // солнце нарисовано: полуширина по расчёту
      const v = pl.has(y) ? pl.get(y) : -1, q = v >= 0 ? Math.floor(Math.sqrt(K * K - v * v)) : -1;
      const ok = q < 0 || !edges(X, Math.min(255, q + cnt)) && !edges(X, q) ? h === 0 : h === 0 ? q === 0 || !edges(X, q) : h >= q && h <= Math.min(255, q + cnt);
      if (!ok && rowsHere++ < 1) fail(`#${i} K ${K} (${X}, ${Y}): строка ${y}, V ${v}: полуширина ${h}, корень ${q}, бахрома до ${cnt}`);
    }
    for (let x = 0; x < 256; x++) { const want = e && x >= e[0] && x < e[1] ? 1 : 0; if (pix(x, y) !== want) { fail(`#${i} K ${K} (${X}, ${Y}): точка (${x}, ${y}) ${pix(x, y)}, по LSO ${want} (h ${h}, SUNX ${cx})`); break; } on += want; }
    if (h) rows++;
  }
  for (let x = 0; x < 256; x++) if (pix(x, 0)) { fail(`#${i}: точка в строке 0`); break; }
  if (lsx === 0xFF && on) fail(`#${i}: солнца нет (LSX FFh), а на экране ${on} точек`);
  if (on) drawn++;
  if (bad > 10) break;
}
m.call('WPLS');
for (let y = 0; y < ROWS && bad < 11; y++) for (let x = 0; x < 256; x++) if (pix(x, y)) { fail(`WPLS: осталась точка (${x}, ${y})`); break; }
for (let a = 0x100, k = 0; a < L.rom_end; a++, k++) if (m.rd(a) !== code[k]) { fail(`код изменён в ${a.toString(16)}`); break; }
console.log(`вызовов ${calls}, с солнцем на экране ${drawn}, строк ${rows}; тактов в среднем ${(cyc / calls).toFixed(0)}, самый долгий ${maxc}`);
console.log(bad ? `ПРОВАЛ: ${bad}` : 'SUN: всё совпало');
process.exit(bad ? 1 : 0);
