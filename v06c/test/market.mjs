// Удобства рынка и карты из дисковой версии BBC (только обычный образ; эталона нет — проверка по смыслу):
// 1. ввод количества gnum: первым знаком Y — всё доступное (QQ25), N — ничего, иначе число, как раньше;
// 2. продажа (TT210 на экране продажи): «Sell(Y/N)?» принимает Y, N или число; деньги растут на цену × количество;
//    число больше, чем есть в трюме, — отказ и повтор строки;
// 3. курсор карты (TT17): с нажатой СС шаг вчетверо больше.
// sh v06c/build.sh && node v06c/test/market.mjs
import { createVector } from '../tools/v06c.mjs';
const m = createVector('elite'), L = m.L, cpu = m.cpu;
m.frame(300);                                           // заставка: рабочие области и рынок готовы
let bad = 0; const ok = (c, s) => { if (!c) bad++; console.log(`${c ? 'OK  ' : 'FAIL'} ${s}`); };
const ret = () => { const sp = cpu.sp & 0xffff; cpu.pc = m.rd(sp) | (m.rd(sp + 1) << 8); cpu.sp = (sp + 2) & 0xffff; };
const run = (label, regs, keys) => { let k = 0, asked = 0, errs = 0;
  const tick = () => { for (;;) { const pc = cpu.pc & 0xffff;         // после перехвата новый адрес проверяется снова
    if (pc === L.TT217) { asked++; cpu.regs[7] = (keys[k++] || 'n').charCodeAt(0); ret(); }
    else if (pc === L.TT26 || pc === L.DELAY) { if (pc === L.TT26) cpu.cf = 0; ret(); }
    else if (pc === L.BAY2) ret();
    else { if (pc === L.tt210_e && last !== pc) errs++; last = pc; return; } } };
  let last = 0;
  const r = m.call(label, { ...regs, tick }, 2e7); return { ...r, asked, errs, used: k }; };
const cash = () => [0, 1, 2, 3].reduce((q, i) => q * 256 + m.rd(L.CASH + i), 0);

// 1. gnum
for (const [keys, max, want, what] of [['y', 17, 17, 'Y — всё доступное'], ['n', 17, 0, 'N — ничего'], ['12\r', 17, 12, 'число 12'], ['7\r', 17, 7, 'число 7'], ['y', 0, 0, 'Y при нуле доступного']]) {
  m.wr(L.QQ25, [max]); const r = run('gnum', {}, [...keys]);
  ok(m.rd(L.R_) === want && r.a === want && r.cf === 0, `gnum, ${what}: R = ${m.rd(L.R_)}, перенос ${r.cf}`); }
{ m.wr(L.QQ25, [17]); const r = run('gnum', {}, [...'25\r']); ok(r.cf === 1, `gnum, число больше доступного (25 при 17): перенос ${r.cf}`); }

// 2. продажа: в трюме 10 т еды (товар 0) и 5 т компьютеров (товар 7)
const hold = (food, comp) => { const q = new Array(17).fill(0); q[0] = food; q[7] = comp; m.wr(L.QQ20, q); m.wr(L.QQ11, [4]); m.wr(L.CASH, [0, 0, 0x10, 0]); m.wr(L.YC, [2]); };
hold(1, 0); let c0 = cash(); run('TT210', {}, ['y']); const priceFood = cash() - c0;
hold(0, 1); c0 = cash(); run('TT210', {}, ['y']); const priceComp = cash() - c0;
ok(priceFood > 0 && priceComp > priceFood, `цена единицы: еда ${priceFood / 10} Cr, компьютеры ${priceComp / 10} Cr`);
for (const [keys, wantFood, wantComp, what] of [[['3', '\r', 'n'], 7, 5, 'еды продать 3, компьютеры — N'], [['y', '2', '\r'], 0, 3, 'еду — всю (Y), компьютеров 2'], [['n', 'n'], 10, 5, 'ничего'], [['y', 'y'], 0, 0, 'всё']]) {
  hold(10, 5); c0 = cash(); const r = run('TT210', {}, keys);
  const f = m.rd(L.QQ20), c = m.rd(L.QQ20 + 7), got = cash() - c0, want = (10 - wantFood) * priceFood + (5 - wantComp) * priceComp;
  ok(f === wantFood && c === wantComp && got === want && r.errs === 0, `продажа, ${what}: еды ${f}, компьютеров ${c}, выручка ${got / 10} Cr (ждали ${want / 10})`); }
{ hold(10, 5); c0 = cash(); const r = run('TT210', {}, ['2', '5', '4', '\r', 'n']);   // 25 > 10: отказ, строка заново, затем 4
  ok(m.rd(L.QQ20) === 6 && r.errs === 1 && cash() - c0 === 4 * priceFood, `продажа, 25 т при 10 в трюме: отказов ${r.errs}, после повтора продано 4, еды ${m.rd(L.QQ20)}`); }

// 3. курсор карты
const arrow = (code, ss) => { const rows = new Array(8).fill(0), i = m.rd(L.kb_rev + code); rows[i >> 3] |= 1 << (i & 7); m.wr(L.kb_rows, rows); m.wr(L.kb_mod, [ss ? 0x20 : 0]);
  const r = m.call('TT17', {}, 2e6); m.wr(L.kb_rows, new Array(8).fill(0)); m.wr(L.kb_mod, [0]); return [(r.b ^ 0x80) - 0x80, (r.c ^ 0x80) - 0x80]; };
const steps = [[0x79, 'вправо'], [0x19, 'влево'], [0x39, 'вверх'], [0x29, 'вниз']].map(([c, n]) => [n, arrow(c, false), arrow(c, true)]);
console.log('шаг курсора (x, y) без СС и с СС: ' + steps.map(([n, a, b]) => `${n} ${a} → ${b}`).join('; '));
ok(steps.every(([, a, b]) => b[0] === 4 * a[0] && b[1] === 4 * a[1] && Math.abs(a[0]) + Math.abs(a[1]) === 1), 'с СС шаг курсора вчетверо больше');
console.log(bad ? `ПРОВАЛ: ${bad}` : 'MARKET: всё как задумано');
process.exit(bad ? 1 : 0);
