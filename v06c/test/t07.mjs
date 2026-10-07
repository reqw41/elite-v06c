// T07: арифметика и геометрия заставки — парные тесты 6502 ↔ i8080. node v06c/test/t07.mjs [случаев = 3000]
import { makePair } from '../tools/pair.mjs';
const N = +(process.argv[2] || 3000);
const P = makePair(), { B, m } = P;
const z = (b) => { for (;;) { const v = [b(), b(), b()]; if (v[0] | v[1] | (v[2] & 127)) return v; } };   // расстояние не ноль
const arr = (b, n) => Array.from({ length: n }, b);
// матрица ориентации: старшие байты около ±96, как в игре, или любые
const orient = (r, b, n) => Array.from({ length: n }, (_, i) => (r(3) ? (i & 1 ? (r(97) | (r(2) << 7)) : b()) : b()));
const SPECS = [
  { name: 'LL31', gen: (r, b) => ({ a: b(), x: b(), y: b(), mem: { Q: b(), R: 254 } }) },
  { name: 'DVID3B2', gen: (r, b) => ({ a: b(), x: b(), y: b(), mem: { P: [b(), b()], [B.INWK + 6]: z(b) } }) },
  { name: 'PLS6', gen: (r, b) => ({ a: r(3) ? b() : r(4) | (r(2) << 7), x: b(), y: b(), mem: { P: [b(), b()], [B.INWK + 6]: r(3) ? z(b) : [b(), r(8) + 1, r(2) << 7] } }) },
  { name: 'PROJ', gen: (r, b) => ({ x: b(), y: b(), mem: { INWK: r(3) ? [...arr(b, 6), ...z(b)] : [b(), b(), r(2) << 7, b(), b(), r(2) << 7, b(), r(30) + 1, 0] } }) },
  { name: 'LL51', skip: ['P', 'Q', 'R', 'S', 'T'], gen: (r, b) => ({ mem: { XX15: arr(b, 6), XX16: arr(b, 18) } }) },
  { name: 'LL120', gen: (r, b) => ({ x: b(), y: b(), mem: { XX15: b(), S: r(4) ? b() : [0, 128, 255][r(3)], T: r(2) ? 0 : b() || 1, [B.XX12 + 2]: b(), [B.XX12 + 3]: b() } }) },
  { name: 'LL123', gen: (r, b) => ({ x: b(), y: b(), mem: { R: b(), S: r(4) ? b() : [0, 128, 255][r(3)], T: r(2) ? 0 : b() || 1, [B.XX12 + 2]: b(), [B.XX12 + 3]: b() } }) },
  { name: 'NORM', gen: (r, b) => ({ x: b(), mem: { XX15: arr(b, 3) } }) },
  { name: 'TIS3', gen: (r, b) => { const k = r(3); return { a: 2 * k, x: 2 * ((k + 1) % 3), y: 2 * ((k + 2) % 3), mem: { [B.INWK + 9]: orient(r, b, 18) } }; } },
  { name: 'TIDY', gen: (r, b) => ({ mem: { [B.INWK + 9]: orient(r, b, 18) } }) },
];
for (const s of SPECS) P.run({ n: N, ...s });
P.timing();
const BBC_SIZE = [['DVID3B2', B.cntr - B.DVID3B2], ['PLS6', B.PL44 + 2 - B.PLS6], ['PROJ', B.PL2 - B.PROJ], ['LL51', B.LL9 - B.LL51], ['LL120', B.LL129 - B.LL120], ['NORM', B.RDKEY - B.NORM], ['TIDY', B.TIS2 - B.TI2], ['TIS3', B.DVIDT - B.TIS3]];
const b = BBC_SIZE.reduce((s, r) => s + r[1], 0), v = m.L.geom_end - m.L.geom_start;
console.log(`\nразмер кода: BBC ${b} Б (${BBC_SIZE.map((r) => r.join(' ')).join(', ')}) → Вектор ${v} Б: ×${(v / b).toFixed(2)}`);
console.log(P.failed() ? `ПРОВАЛ: ${P.failed()}` : 'T07: всё совпало');
process.exit(P.failed() ? 1 : 0);
