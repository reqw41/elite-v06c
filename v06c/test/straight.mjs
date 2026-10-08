// Короткие пути «полёт прямо» обычного образа (нет ни крена, ни тангажа): пыль STARS1 и движение MVEIT/MV40
// должны давать то же, что полный расчёт образа стенда с нулевыми ALPHA и BETA. Пыль — точно (массивы и экран);
// у кораблей BBC при нулевом тангаже уводит y на единицу младшего разряда за проход (вычитание с переносом 0) —
// короткий путь этого не делает: допускается разница на единицу в y (INWK+3, +4) и, через него, в x (INWK+0, +1).
// sh v06c/build.sh && sh v06c/build.sh -DSCHED && node v06c/test/straight.mjs
import { createVector } from '../tools/v06c.mjs';
let bad = 0; const fail = (s) => { if (++bad <= 10) console.log('FAIL ' + s); };
const a = createVector('elite'), b = createVector('elite_t'); a.frame(60); b.frame(60);
// режимы: прямо, только крен, только тангаж; ALPHA/BETA — знак и модуль, ALP2/BET2 — знак и обратный знак
const axes = (mode, rnd) => { const sa = rnd(2) << 7, sb = rnd(2) << 7, am = mode === 1 ? 1 + rnd(31) : 0, bm = mode === 2 ? 1 + rnd(8) : 0;
  return { ALPHA: am ? sa | am : 0, ALP1: am, ALP2: [sa, sa ^ 0x80], BETA: bm ? sb | bm : 0, BET1: bm, BET2: [sb, sb ^ 0x80] }; };
const MODES = ['прямо', 'только крен', 'только тангаж'];
let rs = 4242; const rnd = (n) => { rs = (rs * 1103515245 + 12345) >>> 0; return (rs >>> 8) % n; };
const skipNoise = (m) => () => { for (;;) { const pc = m.cpu.pc & 0xffff; if (pc === m.L.NOISE) { const sp = m.cpu.sp & 0xffff; m.cpu.pc = m.rd(sp) | (m.rd(sp + 1) << 8); m.cpu.sp = (sp + 2) & 0xffff; } else return; } };
// пыль
for (let mode = 0; mode < 3; mode++) { const N = 12, view = (m) => { let s = ''; for (let x = 0xC000; x < 0xE000; x++) if ((x & 255) >= 64 && m.rd(x)) s += x.toString(16) + ':' + m.rd(x) + ' '; return s; };
  let cyA = 0, cyB = 0, n = 0;
  for (let i = 0; i < 400; i++) {
    const st = { NOSTM: N, VIEW: 0, QQ11: 0, ...axes(mode, rnd), DELTA: 1 + rnd(40), RAND: [rnd(256), rnd(256), rnd(256), rnd(256)] };
    st.DELT4 = [(st.DELTA << 2) & 255, st.DELTA >> 6];
    const arr = (f) => Array.from({ length: N + 1 }, f);
    const dust = { SX: arr(() => rnd(256) | 1), SY: arr(() => rnd(256) | 1), /* без нулевого модуля: у BBC ноль меняет знак */ SZ: arr(() => 16 + rnd(240)), SXL: arr(() => rnd(256)), SYL: arr(() => rnd(256)), SZL: arr(() => rnd(256)) };
    const run = (m) => { for (let x = 0xC000; x < 0xE000; x++) if ((x & 255) >= 64) m.wr(x, [0]); const r = m.call('STARS1', { mem: { ...st, ...dust } }, 2e6);
      return [r.cycles, Object.keys(dust).map((k) => Array.from({ length: N + 1 }, (_, j) => m.rd(m.L[k] + j)).join()).join(' | ') + ' # ' + view(m) + ' # ' + [0, 1, 2, 3].map((j) => m.rd(m.L.RAND + j))]; };
    const [ca, ra] = run(a), [cb, rb] = run(b); cyA += ca; cyB += cb; n++;
    if (ra !== rb) { const x = ra.split(' '), y = rb.split(' '); fail(`пыль (${MODES[mode]}), случай ${i}: итог разный: ${x.filter((v, j) => v !== y[j]).slice(0, 6)} против ${y.filter((v, j) => v !== x[j]).slice(0, 6)}; SY ${dust.SY}; SX ${dust.SX}`); }
  }
  console.log(`пыль, ${MODES[mode]}: случаев ${n}, тактов на вызов — короткий путь ${(cyA / n).toFixed(0)}, полный ${(cyB / n).toFixed(0)}`);
}
// корабль
for (let mode = 0; mode < 3; mode++) { let cyA = 0, cyB = 0, n = 0, drift = 0;
  for (let i = 0; i < 400; i++) {
    const inwk = Array.from({ length: 36 }, () => rnd(256)); inwk[31] = 0xA0 & 0; inwk[32] = 0; inwk[35] = 100; inwk[27] = rnd(20); inwk[28] = 0; inwk[29] = rnd(2) ? 0 : 0x80 | rnd(8); inwk[30] = 0;
    for (const k of [2, 5, 8]) inwk[k] &= 0x80; inwk[31] = 0;   // у корабля в байте знака — только знак
    const st = { INWK: inwk, TYPE: 1, MCNT: 3, XSAV: 0, ...axes(mode, rnd), DELTA: rnd(40), QQ11: 1 };
    const run = (m) => { const r = m.call('MVEIT', { mem: st, tick: skipNoise(m) }, 2e6); return [r.cycles, Array.from({ length: 31 }, (_, j) => m.rd(m.L.INWK + j))]; };
    const [ca, ra] = run(a), [cb, rb] = run(b); cyA += ca; cyB += cb; n++;
    const diff = ra.map((v, j) => (v !== rb[j] ? j : -1)).filter((j) => j >= 0);
    const w = (r, o) => r[o] | (r[o + 1] << 8);
    if (diff.some((j) => j > 4 || j === 2) || Math.abs(w(ra, 3) - w(rb, 3)) > 1 || Math.abs(w(ra, 0) - w(rb, 0)) > 1) fail(`корабль (${MODES[mode]}), случай ${i}: расходятся байты INWK ${diff}: ${diff.map((j) => ra[j] + '/' + rb[j])}`);
    else if (diff.length) drift++;
  }
  console.log(`корабль, ${MODES[mode]}: случаев ${n}, тактов на вызов — короткий путь ${(cyA / n).toFixed(0)}, полный ${(cyB / n).toFixed(0)}; увод y на 1 у BBC — в ${drift} случаях`);
}
console.log(bad ? `ПРОВАЛ: ${bad}` : 'STRAIGHT: всё как задумано');
process.exit(bad ? 1 : 0);
