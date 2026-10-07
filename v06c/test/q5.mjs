// Q5: арифметика, третья партия — парные тесты 6502 ↔ i8080. node v06c/test/q5.mjs [случаев = 3000]
import { makePair } from '../tools/pair.mjs';
const N = +(process.argv[2] || 3000);
const P = makePair(), { B } = P;
const SPECS = [
  { name: 'LL38', gen: (r, b) => ({ a: b(), x: b(), y: b(), c: r(2), mem: { S: b(), Q: b(), R: b() } }) },
  { name: 'TIS2', gen: (r, b) => ({ a: b(), x: b(), y: b(), c: r(2), mem: { Q: b() } }) },
  { name: 'DVIDT', gen: (r, b) => ({ a: b(), x: b(), y: b(), c: r(2), mem: { P: b(), Q: b() } }) },
  { name: 'LL129', gen: (r, b) => ({ a: b(), x: b(), y: b(), c: r(2), mem: { S: r(4) ? b() : [0, 128, 255][r(3)], R: r(4) ? b() : 0, [B.XX12 + 2]: b(), [B.XX12 + 3]: b() } }) },
  { name: 'LL61', gen: (r, b) => ({ a: b(), x: b(), y: b(), c: r(2), mem: { Q: b(), U: b() } }) },
];
for (const s of SPECS) P.run({ n: N, ...s });
P.timing();
console.log(P.failed() ? `ПРОВАЛ: ${P.failed()}` : 'Q5: всё совпало');
process.exit(P.failed() ? 1 : 0);
