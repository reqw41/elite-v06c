// Мелкие доработки из дисковой версии BBC (только обычный образ; проверка по смыслу):
// 1. победа засчитывается и за мусор (контейнер, астероид); 2. враги появляются на расстоянии 25, а не 32;
// 3. на второй заставке — Krait; 4. пока идёт автопилот стыковки, сообщение о нём повторяется;
// 5. каменный отшельник (как в ZX 48K); 6. эффекты Вектора: встряска экрана при попадании, цвет тревоги.
// Изменённые проверки стыковки проверяет dockit.mjs (автопилот доводит до стыковки).
// sh v06c/build.sh && node v06c/test/discsmall.mjs
import { createVector } from '../tools/v06c.mjs';
let bad = 0; const ok = (c, s) => { if (!c) bad++; console.log(`${c ? 'OK  ' : 'FAIL'} ${s}`); };
const K = { SPACE: [7, 0x80], N: [5, 0x40], F1: [1, 0x08], C: [4, 0x08], A: [4, 0x02] };
const mk = () => { const g = createVector('elite'); g.press = (k, n = 20) => { g.key(K[k][0], K[k][1], true); g.frame(n); g.key(K[k][0], K[k][1], false); }; return g; };

// 3. вторая заставка
{ const g = mk(); g.frame(300); g.press('N'); g.frame(120);
  const t = g.rd(g.L.FRIN); ok(t === 14, `на второй заставке корабль типа ${t} (14 — Krait)`); }

// 2. расстояние появления
{ const g = mk(); g.frame(60); g.call('Ze', { cf: 0 });
  const d = [1, 4, 7].map((i) => g.rd(g.L.INWK + i)); ok(d.every((v) => v === 25), `Ze: старшие байты координат нового корабля ${d}`); }

// 1 и 4: в полёте. Машина идёт по командам без прерываний; кадр «тикает» вручную (DL, LASCT), клавиши — в kb_rows.
{ const g = mk(), L = g.L, cpu = g.cpu; g.frame(300); g.press('N'); g.frame(200); g.press('SPACE'); g.frame(200); g.press('F1'); g.frame(400);
  ok(g.rd(L.QQ12) === 0, 'взлёт');
  cpu.iff = false; let cyc = 0;
  const pass = (n = 1) => { for (let i = 0; i < n; i++) { let k = 0; do { cpu.instruction(); cyc += cpu.vcycles | 0; if (cpu.last_opcode === 0xd3) g.io.commit();
      if (cyc >= 59904) { cyc -= 59904; g.wr(L.DL, [30]); const la = g.rd(L.LASCT); if (la) g.wr(L.LASCT, [la - 1]); }
      if (++k > 3e7) throw new Error('проход не кончился'); } while ((cpu.pc & 0xffff) !== L.MLOOP); cpu.iff = false; } };
  const keyA = (d) => { const rows = new Array(8).fill(0); if (d) { const i = g.rd(L.kb_rev + 0x41); rows[i >> 3] |= 1 << (i & 7); } g.wr(L.kb_rows, rows); };
  const tally = () => g.rd(L.ESCP + 4) | (g.rd(L.TALLY) << 8) | (g.rd(L.TALLY + 1) << 16);   // счёт очками
  const PTS = { 10: 0, 11: 16, 13: 24 };
  const frin = () => Array.from({ length: 13 }, (_, i) => g.rd(L.FRIN + i));
  pass(3); g.wr(L.LASER, [15, 0, 0, 0]);
  for (const [type, name] of [[11, 'контейнер'], [10, 'астероид'], [13, 'капсула']]) {
    const t0 = tally(); g.call('ZINF'); g.wr(L.INWK + 7, [3]); const r = g.call('NWSHP', { a: type });
    if (!r.cf) { ok(false, `${name}: нет места`); continue; }
    const slot = frin().indexOf(type); keyA(true); let n = 0;
    while (frin().includes(type) && n < 400) { g.wr(L.K_ + 36 * slot, [0, 0, 0, 0, 0, 0]); g.wr(L.DELTA, [0]); g.wr(L.GNTMP, [0]); g.wr(L.ENERGY, [255]); pass(1); n++; }
    keyA(false); pass(2);
    ok(!frin().includes(type) && tally() === t0 + PTS[type], `${name} уничтожен лазером за ${n} проходов: очков ${t0} → ${tally()}`);
  }
  // каменный отшельник: астероид с флагами 21h под огнём выпускает два корабля стаи, затем ведёт себя как астероид
  { g.call('ZINF'); g.wr(L.INWK + 7, [3]); g.wr(L.nb_pre, [0xA1]); const r = g.call('NWSHP', { a: 10 }); const slot = frin().indexOf(10);
    const f0 = g.rd(L.newb + slot); g.wr(L.LASER, [15, 0, 0, 0]); keyA(true); let n = 0; const born = new Set();
    while (frin().includes(10) && n < 300) { const s = frin().indexOf(10); g.wr(L.K_ + 36 * s, [0, 0, 0, 0, 0, 0]); g.wr(L.K_ + 36 * s + 35, [200]); g.wr(L.DELTA, [0]); g.wr(L.GNTMP, [0]); g.wr(L.ENERGY, [255]); g.wr(L.FSH, [255]); g.wr(L.ASH, [255]); pass(1); n++;
      frin().forEach((t, i) => { if (t && t < 128 && t !== 8 && t !== 10) born.add(t); }); if (n === 120) break; }
    keyA(false); const s = frin().indexOf(10), left = s >= 0 ? g.rd(L.newb + s) : -1, ships = frin().filter((t) => [1, 3, 14, 22, 23, 24, 25, 5].includes(t)).length;
    const pack = [...born].filter((t) => [1, 3, 14, 22, 23, 24, 25, 5].includes(t));
    ok(r.cf === 1 && f0 === 0x21 && pack.length >= 1 && left === 0x01, `каменный отшельник: флаги ${f0.toString(16)}, под огнём выходили корабли стаи типов ${pack.join(', ')}; запас исчерпан (флаги ${left.toString(16)}), сам остался астероидом`);
    for (let i = 0; i < 13; i++) { const t = g.rd(L.FRIN + i); if (t && t < 128 && t !== 8) { const a = L.K_ + 36 * i + 31; if (!(g.rd(a) & 0xA0)) g.wr(a, [g.rd(a) | 0x80]); } } pass(40); }
  // 4. автопилот: сообщение повторяется
  g.wr(L.DKCMP, [0xFF]); g.wr(L.auto, [0xFF]); let shown = 0, was = 0;
  for (let i = 0; i < 200; i++) { pass(1); const on = g.rd(L.mch_x) === 7 && g.rd(L.DLY) > 0; if (on && !was) shown++; was = on; if (g.rd(L.QQ12) !== 0) break; g.wr(L.auto, [0xFF]); }
  ok(shown >= 2, `за 200 проходов под автопилотом сообщение «DOCKING COMPUTERS ON» появлялось ${shown} раз`);
}
// 6. эффекты: в настоящих кадрах. Попадание по нам (OOPS) — прокрутка экрана дрожит четыре кадра; энергия ниже
// четверти — зелёный цвет панели (регистр палитры 3) раз в 32 кадра становится жёлтым.
{ const g = mk(), L = g.L; g.frame(300); g.press('N'); g.frame(200); g.press('SPACE'); g.frame(200); g.press('F1'); g.frame(400);
  const scr = (n) => { const v = new Set(); for (let i = 0; i < n; i++) { g.frame(1); v.add(g.io.PA); } return v; };   // порт A после кадра — регистр прокрутки
  const calm = scr(8); g.wr(L.flash_cnt, [4]); const shaken = scr(4), after = scr(8);
  ok(calm.size === 1 && calm.has(0xFF) && shaken.has(0xFD) && shaken.has(0xFF) && after.size === 1 && after.has(0xFF), `встряска: в покое прокрутка ${[...calm].map((v) => v.toString(16))}, четыре кадра вспышки — ${[...shaken].map((v) => v.toString(16)).join(' и ')}, затем снова ${[...after].map((v) => v.toString(16))}`);
  const green = () => g.rd(L.pal_regs + 3); const seen = new Set();
  g.wr(L.ENERGY, [255]); for (let i = 0; i < 80; i++) { g.frame(1); g.wr(L.ENERGY, [255]); seen.add(green()); } const full = [...seen]; seen.clear();
  for (let i = 0; i < 80; i++) { g.wr(L.ENERGY, [40]); g.frame(1); seen.add(green()); }
  ok(full.length === 1 && full[0] === 0x38 && seen.has(0x3F) && seen.has(0x38), `тревога: при полной энергии цвет 3 всегда ${full.map((v) => v.toString(16))}, при энергии 40 чередуются ${[...seen].map((v) => v.toString(16)).join(' и ')}`); }
console.log(bad ? `ПРОВАЛ: ${bad}` : 'DISCSMALL: всё как задумано');
process.exit(bad ? 1 : 0);
