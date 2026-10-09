// T71: повороты ориентации против BBC, включая нули, знаки и крайние координаты.
// Бюджет среднего вызова на фиксированной выборке — 3350 тактов (до T71: 3940).
// BASELINE=../../work/T71/before/elite — дополнительно сравнить обычный образ до/после,
// включая всю нулевую страницу, A/B/C/CY и бюджет тактов (не менее 15% на активных осях).
import { makePair } from '../tools/pair.mjs';
import { createVector } from '../tools/v06c.mjs';
const N = 12000;
const pair = makePair('elite_t');
const axes = (i) => {
  const am = [0, 1, 2, 7, 8, 15, 31][i % 7];
  const bm = [0, 1, 2, 7, 8][Math.floor(i / 7) % 5];
  const sa = (Math.floor(i / 35) & 1) << 7, sb = (Math.floor(i / 70) & 1) << 7;
  return { ALPHA: am | sa, ALP1: am, ALP2: [sa, sa ^ 128], BETA: bm | sb, BET1: bm, BET2: [sb, sb ^ 128] };
};
pair.run({ name: 'MVS4', n: N, skip: ['T', 'T1', 'U'], gen: (rnd, byte, i) => ({
  a: byte(), x: byte(), y: [9, 15, 21][Math.floor(i / 140) % 3], c: rnd(2),
  mem: { INWK: Array.from({ length: 36 }, () => byte()), ...axes(i) },
}) });
pair.timing();
let bad = pair.failed();
const mean = pair.stats[0].v / pair.stats[0].n;
if (mean > 3350) { console.log(`FAIL MVS4: ${mean.toFixed(0)} тактов, бюджет 3350`); bad++; }
if (process.env.BASELINE) {
  const old = createVector(process.env.BASELINE), now = createVector('elite');
  old.frame(30); now.frame(30);
  let before = 0, after = 0, active = 0, tested = 0;
  for (let i = 0; i < N && !bad; i++) {
    const zp = Array.from({ length: 256 }, pair.byte);
    const controls = axes(i);
    const args = { a: pair.byte(), b: pair.byte(), c: [9, 15, 21][Math.floor(i / 140) % 3], cf: pair.rnd(2),
      mem: { INWK: Array.from({ length: 36 }, pair.byte), ...controls } };
    for (const m of [old, now]) m.wr(m.L.WS, zp);
    const rb = old.call('MVS4', args), ra = now.call('MVS4', args);
    tested++;
    const diff = ['a', 'b', 'c', 'cf'].filter(k => rb[k] !== ra[k]);
    for (let j = 0; j < 256; j++) if (old.rd(old.L.WS + j) !== now.rd(now.L.WS + j)) diff.push('ZP+' + j);
    if (diff.length) { console.log(`FAIL MVS4 до/после, случай ${i}: ${diff.join(', ')}`); bad++; }
    if (controls.ALP1 && controls.BET1) { before += rb.cycles; after += ra.cycles; active++; }
  }
  const saving = 100 * (1 - after / before);
  console.log(`MVS4 до/после: ${tested} случаев, активных ${active}, тактов ${Math.round(before / active)} -> ${Math.round(after / active)}, экономия ${saving.toFixed(2)}%`);
  if (saving < 15) { console.log('FAIL MVS4: экономия тактов меньше 15%'); bad++; }
}
console.log(bad ? `ПРОВАЛ: ${bad}` : 'MVS4: всё совпало');
process.exit(bad ? 1 : 0);
