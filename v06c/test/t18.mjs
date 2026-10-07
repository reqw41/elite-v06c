// T18: заставка от включения. Образ стенда elite_t.rom (sh v06c/build.sh -DSCHED) идёт с первой команды, эталон —
// с TT170; состояние сравнивается при каждом приходе в цикл заставки TLL2. Ничего не копируется.
// node v06c/test/t18.mjs [проходов первой заставки = 150] [второй = 150]
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { createVector, savePng, ROOT } from '../tools/v06c.mjs';
import { bbcView, vecView, bbcDash, vecDash, firstDiff } from '../tools/screen.mjs';
const { BBC } = createRequire(import.meta.url)(path.join(ROOT, 'tools/oracle/bbc.js'));
const N1 = +(process.argv[2] || 150), N2 = +(process.argv[3] || 150);
const m = createVector('elite_t'), L = m.L, WS = L.WS, bbc = new BBC({ sched: true }), B = bbc.lab;
bbc.mem.set(fs.readFileSync(path.join(ROOT, 'v06c/data/font.bin')), 0xC000);     // эталон печатает нашим шрифтом
const AREAS = [[0x0000, 0x0100], [0x0100, 0x01C0], [0x0300, 0x0372], [0x0900, 0x0F34], [0x0F48, 0x0F51]];
// вне сравнения: рабочие ячейки рисования и печати на BBC и указатели (в них адреса своей машины)
const SKIP = new Set();
const skip = (n, len = 1) => { for (let k = 0; k < len; k++) SKIP.add((typeof n === 'number' ? n : B[n]) + k); };
for (const [n, len] of [['TRTB%', 2], ['P', 3], ['Q', 1], ['R', 1], ['S', 1], ['SWAP', 1], ['YSAV', 1], ['SC', 2], ['X1', 1], ['V', 2], ['XX0', 2], ['INF', 2], ['SLSP', 2],
  ['YSAV2', 1], ['XSAV2', 1]]) skip(n, len);
skip(B.INWK + 33, 2); for (let i = 0; i < 13; i++) skip(0x900 + 36 * i + 33, 2);
const names = {}; for (const [n, a] of Object.entries(B)) if (a < 0x0F51 && n !== 'S%' && !(a in names)) names[a] = n;
const cell = (a) => { for (let k = 0; k < 40; k++) if ((a - k) in names) return names[a - k] + (k ? '+' + k : ''); return '&' + a.toString(16); };
let bad = 0, tv = 0, passes = 0;
function compare(what) {
  const diff = [], vm = m.mem();
  for (const [lo, hi] of AREAS) for (let a = lo; a < hi && diff.length < 8; a++) if (vm[WS + a] !== bbc.mem[a] && !SKIP.has(a)) diff.push(`${cell(a)}: BBC ${bbc.mem[a]}, Вектор ${vm[WS + a]}`);
  let d = firstDiff(vecView(vm), bbcView(bbc.mem)); if (d) diff.push(`обзор: столбец ${d.i % 32}, строка ${Math.floor(d.i / 32)}: Вектор ${d.a}, BBC ${d.b}`);
  d = firstDiff(vecDash(vm), bbcDash(bbc.mem)); if (d) diff.push(`панель: x=${d.i & 255}, строка ${192 + (d.i >> 8)}: Вектор ${d.a}, BBC ${d.b}`);
  return diff.length ? `${what}: ${diff.join('; ')}` : null;
}
function segment(title, n, shot) {
  let fail = compare('приход в заставку');
  for (let i = 0; i < n && !fail; i++) { bbc.pass('TLL2', 1); tv += m.runTo('TLL2'); passes++; fail = compare(`проход ${i}`); }
  console.log(`${fail ? 'FAIL' : 'OK  '} ${title}: подготовка и ${n} проходов — обзор, панель и рабочие области = эталон${fail ? ' — ' + fail : ''}`);
  if (fail) bad++;
  return !fail;
}
const KEY_N = [5, 0x40];                                   // N на Векторе: строка 5, бит 6
bbc.pass('TLL2', 1);
const boot = m.runTo('TLL2');
console.log(`от включения до первого прохода заставки: ${boot} тактов i8080 (${(boot / 3e6).toFixed(2)} с)`);
if (segment('первая заставка (от включения)', N1)) {
  bbc.keys.add(0x55); m.wr(L.kb_rows + KEY_N[0], [KEY_N[1]]);            // нажать N: «новый командир? — нет»
  bbc.pass('TLL2', 1); const t2 = m.runTo('TLL2');
  bbc.keys.delete(0x55); m.wr(L.kb_rows + KEY_N[0], [0]);
  console.log(`переход ко второй заставке: ${t2} тактов i8080 (${(t2 / 3e6).toFixed(2)} с)`);
  segment('вторая заставка', N2);
}
// стоянка на станции: пробел на второй заставке → экран статуса → проходы главного цикла
if (!bad) {
  const N3 = +(process.argv[4] || 40);
  bbc.keys.add(0x62); m.wr(L.kb_rows + 7, [0x80]);
  bbc.pass('MLOOP', 1); const t3 = m.runTo('MLOOP');
  bbc.keys.delete(0x62); m.wr(L.kb_rows + 7, [0]);
  console.log(`вторая заставка → станция, экран статуса: ${t3} тактов i8080 (${(t3 / 3e6).toFixed(2)} с)`);
  let fail = compare('приход в главный цикл');
  for (let i = 0; i < N3 && !fail; i++) { bbc.pass('MLOOP', 1); m.runTo('MLOOP'); fail = compare(`проход главного цикла ${i}`); }
  console.log(`${fail ? 'FAIL' : 'OK  '} стоянка: экран статуса и ${N3} проходов главного цикла — обзор, панель и рабочие области = эталон${fail ? ' — ' + fail : ''}`);
  if (fail) bad++;
  m.frame(0);
}
console.log(bad ? `ПРОВАЛ: ${bad}` : 'T18: всё совпало');
process.exit(bad ? 1 : 0);
