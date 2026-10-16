// T19: печать чисел и мелкие процедуры текста — парные тесты 6502 ↔ i8080. node v06c/test/t19.mjs [случаев = 1500]
import fs from 'node:fs';
import path from 'node:path';
import { makePair } from '../tools/pair.mjs';
import { ROOT } from '../tools/v06c.mjs';
const N = +(process.argv[2] || 1500);
const P = makePair(), { B, bbc } = P;
bbc.mem.set(fs.readFileSync(path.join(ROOT, 'v06c/data/font.bin')), 0xC000);
const TEXT = ['YSAV2', 'XSAV2', ['P', 3], 'SC', 'SCH', ['V', 2], 'Q', 'R', 'YSAV'];
const pos = (r) => ({ XC: r(12), YC: r(18), QQ17: [0, 0x80, 0xC0][r(3)] });
const num = (r, b) => { const k = r(5); return k === 0 ? [0, 0, 0, b()] : k === 1 ? [0, 0, b(), b()] : k === 2 ? [0, b(), b(), b()] : k === 3 ? [b(), b(), b(), b()] : [0, 0, 0, 0]; };
const SPECS = [
  { name: 'BPRNT', gen: (r, b) => ({ c: r(2), mem: { K: num(r, b), U: 1 + r(11), ...pos(r) } }) },
  { name: 'TT11', gen: (r, b) => ({ a: 1 + r(8), x: b(), y: b(), c: r(2), mem: pos(r) }) },
  { name: 'pr2', gen: (r, b) => ({ x: b(), c: r(2), mem: pos(r) }) },
  { name: 'pr5', gen: (r, b) => ({ x: b(), y: b(), c: r(2), mem: pos(r) }) },
  { name: 'pr6', gen: (r, b) => ({ x: b(), y: b(), c: r(2), mem: pos(r) }) },
  { name: 'csh', gen: (r, b) => ({ mem: { CASH: num(r, b), ...pos(r) } }) },
  { name: 'cmn', gen: (r, b) => ({ mem: pos(r) }) },
  { name: 'fwl', gen: (r, b) => ({ mem: { QQ14: r(71), CASH: num(r, b), ...pos(r) } }) },
  { name: 'PCASH', gen: (r, b) => ({ mem: { CASH: num(r, b), ...pos(r) } }) },
  { name: 'spc', gen: (r, b) => ({ a: 32 + r(64), mem: pos(r) }) },
  { name: 'plf2', gen: (r, b) => ({ a: 32 + r(64), mem: pos(r) }) },
  { name: 'TT68', gen: (r, b) => ({ a: 32 + r(64), mem: pos(r) }) },
  { name: 'NLIN3', gen: (r, b) => ({ a: 32 + r(64), mem: pos(r) }) },
  { name: 'NLIN4', gen: (r, b) => ({ mem: pos(r) }) },
  { name: 'NLIN', gen: (r, b) => ({ mem: pos(r) }) },
  { name: 'NLIN2', gen: (r, b) => ({ a: r(192), mem: pos(r) }) },
];
for (const s of SPECS) P.run({ n: N, noreg: 'axyc', skip: s.name.startsWith('NLIN') ? [...TEXT, 'T'] : TEXT, screen: 'text', ...s });   // T — рабочая ячейка HLOIN на BBC
P.timing();
console.log(P.failed() ? `ПРОВАЛ: ${P.failed()}` : 'T19: всё совпало');
process.exit(P.failed() ? 1 : 0);
