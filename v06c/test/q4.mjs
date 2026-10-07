// Q4: арифметика, вторая партия — парные тесты 6502 ↔ i8080. node v06c/test/q4.mjs [случаев = 3000]
import { makePair } from '../tools/pair.mjs';
const N = +(process.argv[2] || 3000);
const P = makePair(), { B } = P;
const SPECS = [
  { name: 'MU5', gen: (r, b) => ({ a: b(), x: b(), y: b(), c: r(2) }) },
  { name: 'DVID96', gen: (r, b) => ({ a: b(), x: b(), y: b(), c: r(2) }) },
  { name: 'TIS1', skip: ['T', 'T1', 'U'], gen: (r, b) => ({ a: b(), x: b(), y: b(), mem: { S: b(), R: b() } }) },
  { name: 'MUT1', gen: (r, b) => ({ a: b(), y: b(), mem: { Q: b(), XX: [b(), b()] } }) },
  { name: 'MUT2', gen: (r, b) => ({ a: b(), y: b(), mem: { Q: b(), XX: [b(), b()] } }) },
  { name: 'MUT3', gen: (r, b) => ({ a: b(), y: b(), mem: { Q: b(), XX: [b(), b()], ALP1: b() } }) },
  { name: 'DV41', gen: (r, b) => ({ a: b(), y: b(), mem: { DELTA: b() } }) },
  { name: 'DV42', gen: (r, b) => { const y = r(19); return { y, mem: { DELTA: b(), [B.SZ + y]: b() } }; } },
];
for (const s of SPECS) P.run({ n: N, ...s });
P.timing();
console.log(P.failed() ? `ПРОВАЛ: ${P.failed()}` : 'Q4: всё совпало');
process.exit(P.failed() ? 1 : 0);
