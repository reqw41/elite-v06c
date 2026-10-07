// T20: галактика — парные тесты 6502 ↔ i8080. node v06c/test/t20.mjs [случаев = 1500]
import fs from 'node:fs';
import path from 'node:path';
import { makePair } from '../tools/pair.mjs';
import { ROOT } from '../tools/v06c.mjs';
const N = +(process.argv[2] || 1500);
const P = makePair(), { B, bbc } = P;
bbc.mem.set(fs.readFileSync(path.join(ROOT, 'v06c/data/font.bin')), 0xC000);
const TEXT = ['YSAV2', 'XSAV2', ['P', 3], 'SC', 'SCH', ['V', 2]];
const arr = (b, n) => Array.from({ length: n }, b);
const GAL1 = [0x4a, 0x5a, 0x48, 0x02, 0x53, 0xb7];           // семена первой галактики
const seeds = (r, b) => (r(3) ? arr(b, 6) : GAL1);
const pos = (r) => ({ XC: r(12), YC: r(18), QQ17: [0, 0x80, 0xC0][r(3)] });
const SPECS = [
  { name: 'TT54', noreg: 'axy', gen: (r, b) => ({ mem: { QQ15: arr(b, 6) } }) },
  { name: 'TT20', noreg: 'axy', gen: (r, b) => ({ mem: { QQ15: arr(b, 6) } }) },
  { name: 'TT81', noreg: 'axyc', gen: (r, b) => ({ mem: { QQ21: arr(b, 6) } }) },
  { name: 'jmp', noreg: 'axyc', gen: (r, b) => ({ mem: { QQ9: [b(), b()] } }) },
  { name: 'ping', noreg: 'axyc', gen: (r, b) => ({ mem: { QQ0: [b(), b()] } }) },
  { name: 'TT24', noreg: 'axyc', gen: (r, b) => ({ mem: { QQ15: arr(b, 6) } }) },
  { name: 'TT111', n: Math.min(N, 300), noreg: 'axyc', gen: (r, b) => ({ mem: { QQ21: seeds(r, b), QQ9: [b(), b()], QQ0: [b(), b()] } }) },
  { name: 'hyp1', n: Math.min(N, 200), noreg: 'axyc', gen: (r, b) => ({ mem: { QQ21: seeds(r, b), QQ9: [b(), b()], QQ0: [b(), b()] } }) },
  { name: 'cpl', ventry: 'cpl_', noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r, b) => ({ mem: { QQ15: arr(b, 6), ...pos(r) } }) },
  { name: 'ypl', noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r, b) => ({ mem: { QQ15: arr(b, 6), QQ2: arr(b, 6), MJ: r(5) ? 0 : b(), ...pos(r) } }) },
  { name: 'TT62', noreg: 'axyc', gen: (r, b) => ({ mem: { QQ15: arr(b, 6), QQ2: arr(b, 6) } }) },
  { name: 'tal', noreg: 'axyc', skip: [...TEXT, 'Q', 'R'], screen: 'view', gen: (r, b) => ({ mem: { GCNT: r(8), ...pos(r) } }) },
];
for (const s of SPECS) P.run({ n: N, ...s });
P.timing();
console.log(P.failed() ? `ПРОВАЛ: ${P.failed()}` : 'T20: всё совпало');
process.exit(P.failed() ? 1 : 0);
