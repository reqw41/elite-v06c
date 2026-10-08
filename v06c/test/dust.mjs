// Пыль обычного образа (свой STARS1, stars.asm): массивы пылинок и вызовы рисования точки против расчёта тем же
// способом на JS — множитель расхождения из таблицы sn_tab, тангаж, крен, замена ушедших. Случайные числа новой
// пылинки подставляются тестом. Плюс свойства: без крена и тангажа пылинка уходит от центра по своему лучу.
// sh v06c/build.sh && node v06c/test/dust.mjs
import { createVector } from '../tools/v06c.mjs';
let bad = 0; const fail = (s) => { if (++bad <= 10) console.log('FAIL ' + s); };
const m = createVector('elite'), L = m.L, cpu = m.cpu; m.frame(60);
const TAB = Array.from({ length: 64 }, (_, i) => m.rd(L.sn_tab + i));
const ret = () => { const sp = cpu.sp & 0xffff; cpu.pc = m.rd(sp) | (m.rd(sp + 1) << 8); cpu.sp = (sp + 2) & 0xffff; };
let rs = 99; const rnd = (n) => { rs = (rs * 1103515245 + 12345) >>> 0; return (rs >>> 8) % n; };
const s16 = (v) => (v << 16) >> 16;
function model(st, d, N, rands) {
  const o = JSON.parse(JSON.stringify(d)), px = []; let ri = 0;
  for (let c = N; c >= 1; c--) {
    let x1 = o.SX[c], y1 = o.SY[c], zz = o.SZ[c]; px.push([x1, y1, zz]);
    const q = (((st.DELTA * TAB[(zz >> 2) & 63]) << 4) >> 8 & 255) | 1;
    const zl = o.SZL[c] - st.DELT4[0], zh = o.SZ[c] - st.DELT4[1] - (zl < 0 ? 1 : 0); o.SZL[c] = zl & 255; o.SZ[c] = zh & 255;
    const fresh = () => { o.SY[c] = y1 = rands[ri++] | 4; o.SX[c] = x1 = rands[ri++] | 8; o.SZ[c] = zz = rands[ri++] | 144; px.push([x1, y1, zz]); };
    if (zh < 0 || zh < 16) { fresh(); continue; }
    zz = zh;
    const zoom = (hi, lo) => { const mg = ((hi & 127) << 8 | lo) + (hi & 127) * q; return (mg >> 8) >= 120 ? null : (hi & 128 ? -mg : mg); };
    let X = zoom(x1, o.SXL[c]); if (X === null) { fresh(); continue; }
    let Y = zoom(y1, o.SYL[c]); if (Y === null) { fresh(); continue; }
    if (st.BET1) Y = s16(((((Y >> 8) & 255) + (st.BETA & 128 ? st.BET1 : -st.BET1)) & 255) << 8 | (Y & 255));
    if (st.ALP1) {
      const term = (V) => { const h = (V >> 8) & 255; return [(h & 128 ? (~h & 255) : h) * st.ALP1, h]; };
      const adds = (V, T, sign) => { const r = sign & 128 ? V - T : V + T; return r > 32767 || r < -32768 ? null : r; };
      let [t, h] = term(X); Y = adds(Y, t, h ^ st.ALP2[1]); if (Y === null) { fresh(); continue; }
      [t, h] = term(Y); X = adds(X, t, h ^ st.ALP2[0]); if (X === null) { fresh(); continue; }
    }
    const sm = (V) => { const mg = Math.abs(V); return (mg >> 8) >= 120 ? null : [(mg >> 8) | (V < 0 ? 128 : 0), mg & 255]; };
    const ys = sm(Y); if (!ys) { fresh(); continue; } o.SY[c] = y1 = ys[0]; o.SYL[c] = ys[1];
    const xs = sm(X); if (!xs) { fresh(); continue; } o.SX[c] = x1 = xs[0]; o.SXL[c] = xs[1];
    px.push([x1, y1, zz]);
  }
  return [o, px];
}
const N = 16, KEYS = ['SX', 'SXL', 'SY', 'SYL', 'SZ', 'SZL'];
let cases = 0, cyc = [0, 0, 0, 0], cnt = [0, 0, 0, 0], fresh = 0;
for (let i = 0; i < 1200; i++) {
  const mode = i % 4, sa = rnd(2) << 7, sb = rnd(2) << 7, am = mode & 1 ? 1 + rnd(31) : 0, bm = mode & 2 ? 1 + rnd(8) : 0, delta = 1 + rnd(40);
  const st = { NOSTM: N, VIEW: 0, QQ11: 0, ALPHA: am ? sa | am : 0, ALP1: am, ALP2: [sa, sa ^ 128], BETA: bm ? sb | bm : 0, BET1: bm, BET2: [sb, sb ^ 128], DELTA: delta, DELT4: [(delta << 2) & 255, delta >> 6] };
  const arr = (f) => Array.from({ length: N + 1 }, f);
  const d = { SX: arr(() => rnd(256)), SXL: arr(() => rnd(256)), SY: arr(() => rnd(256)), SYL: arr(() => rnd(256)), SZ: arr(() => (rnd(6) ? 16 + rnd(240) : rnd(24))), SZL: arr(() => rnd(256)) };
  const rands = Array.from({ length: 3 * N }, () => rnd(256)); let ri = 0; const px = [];
  const tick = () => { for (;;) { const pc = cpu.pc & 0xffff;
    if (pc === L.PIXEL2) { px.push([m.rd(L.X1), m.rd(L.Y1), m.rd(L.ZZ)]); ret(); } else if (pc === L.DORND) { cpu.regs[7] = rands[ri++]; ret(); } else return; } };
  const r = m.call('STARS1', { mem: { ...st, ...d }, tick }, 2e6);
  const [want, wpx] = model(st, d, N, rands);
  const got = Object.fromEntries(KEYS.map((k) => [k, Array.from({ length: N + 1 }, (_, j) => m.rd(L[k] + j))]));
  cases++; cyc[mode] += r.cycles; cnt[mode]++; fresh += ri / 3;
  for (const k of KEYS) for (let c = 1; c <= N; c++) if (got[k][c] !== want[k][c]) { fail(`случай ${i} (крен ${am}, тангаж ${bm}, скорость ${delta}): ${k}[${c}] = ${got[k][c]}, по расчёту ${want[k][c]} (было x ${d.SX[c]}.${d.SXL[c]} y ${d.SY[c]}.${d.SYL[c]} z ${d.SZ[c]})`); break; }
  if (JSON.stringify(px) !== JSON.stringify(wpx)) fail(`случай ${i}: вызовы рисования точки не те (${px.length} против ${wpx.length})`);
}
console.log(`случаев ${cases} по ${N} пылинок; заменено новых в среднем ${(fresh / cases).toFixed(1)} за вызов; тактов на пылинку без рисования точки: прямо ${(cyc[0] / cnt[0] / N).toFixed(0)}, крен ${(cyc[1] / cnt[1] / N).toFixed(0)}, тангаж ${(cyc[2] / cnt[2] / N).toFixed(0)}, оба ${(cyc[3] / cnt[3] / N).toFixed(0)}`);
// свойство: полёт прямо — пылинка остаётся на своём луче (отношение x к y почти не меняется) и удаляется от центра
{ let worst = 0, shrink = 0;
  for (let i = 0; i < 300; i++) { const x = 8 + rnd(60), y = 8 + rnd(60), z = 40 + rnd(200), delta = 5 + rnd(35);
    const st = { NOSTM: 1, VIEW: 0, QQ11: 0, ALPHA: 0, ALP1: 0, ALP2: [0, 128], BETA: 0, BET1: 0, BET2: [0, 128], DELTA: delta, DELT4: [(delta << 2) & 255, delta >> 6] };
    m.call('STARS1', { mem: { ...st, SX: [0, x], SXL: [0, 0], SY: [0, y], SYL: [0, 0], SZ: [0, z], SZL: [0, 0] }, tick: () => { for (;;) { const pc = cpu.pc & 0xffff; if (pc === L.PIXEL2) ret(); else return; } } }, 2e6);
    const nx = m.rd(L.SX + 1) * 256 + m.rd(L.SXL + 1), ny = m.rd(L.SY + 1) * 256 + m.rd(L.SYL + 1);
    if (nx < x * 256 || ny < y * 256) shrink++; worst = Math.max(worst, Math.abs(nx / ny - x / y) / (x / y)); }
  if (shrink || worst > 0.01) fail(`полёт прямо: пылинка приблизилась к центру ${shrink} раз, луч сместился до ${(worst * 100).toFixed(2)} %`);
  console.log(`полёт прямо, 300 пылинок: к центру не приблизилась ни одна, отношение x/y меняется не больше чем на ${(worst * 100).toFixed(2)} %`); }
console.log(bad ? `ПРОВАЛ: ${bad}` : 'DUST: всё совпало');
process.exit(bad ? 1 : 0);
