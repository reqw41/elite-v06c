// Мелкие доработки из дисковой версии BBC (только обычный образ; проверка по смыслу):
// 1. победа засчитывается и за мусор (контейнер, астероид); 2. враги появляются на расстоянии 25, а не 32;
// 3. на второй заставке — Krait; 4. пока идёт автопилот стыковки, сообщение о нём повторяется.
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
  const tally = () => g.rd(L.TALLY) | (g.rd(L.TALLY + 1) << 8);
  const frin = () => Array.from({ length: 13 }, (_, i) => g.rd(L.FRIN + i));
  pass(3); g.wr(L.LASER, [15, 0, 0, 0]);
  for (const [type, name] of [[11, 'контейнер'], [10, 'астероид'], [13, 'капсула']]) {
    const t0 = tally(); g.call('ZINF'); g.wr(L.INWK + 7, [3]); const r = g.call('NWSHP', { a: type });
    if (!r.cf) { ok(false, `${name}: нет места`); continue; }
    const slot = frin().indexOf(type); keyA(true); let n = 0;
    while (frin().includes(type) && n < 400) { g.wr(L.K_ + 36 * slot, [0, 0, 0, 0, 0, 0]); g.wr(L.DELTA, [0]); g.wr(L.GNTMP, [0]); g.wr(L.ENERGY, [255]); pass(1); n++; }
    keyA(false); pass(2);
    ok(!frin().includes(type) && tally() === t0 + 1, `${name} уничтожен лазером за ${n} проходов: побед ${t0} → ${tally()}`);
  }
  // 4. автопилот: сообщение повторяется
  g.wr(L.DKCMP, [0xFF]); g.wr(L.auto, [0xFF]); let shown = 0, was = 0;
  for (let i = 0; i < 200; i++) { pass(1); const on = g.rd(L.mch_x) === 7 && g.rd(L.DLY) > 0; if (on && !was) shown++; was = on; if (g.rd(L.QQ12) !== 0) break; g.wr(L.auto, [0xFF]); }
  ok(shown >= 2, `за 200 проходов под автопилотом сообщение «DOCKING COMPUTERS ON» появлялось ${shown} раз`);
}
console.log(bad ? `ПРОВАЛ: ${bad}` : 'DISCSMALL: всё как задумано');
process.exit(bad ? 1 : 0);
