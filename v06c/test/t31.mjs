// T31: рынок — парные тесты 6502 ↔ i8080 (без ввода с клавиатуры; ввод — в сценарии t32.mjs).
// sh v06c/build.sh -DSCHED && node v06c/test/t31.mjs [случаев = 600]
import fs from 'node:fs';
import path from 'node:path';
import { makePair } from '../tools/pair.mjs';
import { ROOT } from '../tools/v06c.mjs';
const N = +(process.argv[2] || 600);
const P = makePair('elite_t'), { B, bbc, m } = P;
bbc.mem.set(fs.readFileSync(path.join(ROOT, 'v06c/data/font.bin')), 0xC000);
const arr = (b, n) => Array.from({ length: n }, b);
const TEXT = ['YSAV2', 'XSAV2', ['P', 3], 'SC', 'SCH', ['V', 2], 'Q', 'R', 'S', 'SWAP', 'YSAV', 'T', 'T1', ['TRTB%', 2], ['XX15', 6]];
const QQ23 = B.QQ16 + 64;
for (let i = 0; i < 68; i++) if (m.rd(m.L.QQ23 + i) !== bbc.mem[QQ23 + i]) throw new Error('таблица товаров в образе не равна эталону');
const pos = (r) => ({ XC: r(12), YC: r(18), QQ17: [0, 0x80, 0xC0][r(3)] });
const mkt = (r, b) => ({ QQ26: b(), QQ28: r(8), AVL: arr(() => (r(4) ? r(64) : 0), 17), QQ20: arr(() => (r(3) ? 0 : r(40)), 17), CRGO: [20, 35][r(2)], CASH: [0, r(3), b(), b()], QQ14: r(71),
  [B.QQ22 + 1]: 0, VIEW: 0, GCNT: 0, MJ: 0 });
const SPECS = [
  { name: 'TT163', noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r) => ({ mem: pos(r) }) },
  { name: 'TT152', noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r, b) => ({ mem: { [B.QQ19 + 1]: b(), ...pos(r) } }) },
  { name: 'var', noreg: 'axy', gen: (r, b) => ({ mem: { [B.QQ19 + 1]: b(), QQ28: r(8) } }) },
  { name: 'GVL', noreg: 'axyc', gen: (r, b) => ({ c: r(2), mem: { RAND: arr(b, 4), QQ28: r(8) } }) },
  { name: 'GC2', noreg: 'c', gen: (r, b) => ({ a: r(64), mem: { P: b() } }) },
  { name: 'GCASH', noreg: 'c', gen: (r, b) => ({ mem: { P: r(64), Q: b() } }) },
  { name: 'MCASH', noreg: 'a', gen: (r, b) => ({ x: b(), y: b(), mem: { CASH: arr(b, 4) } }) },
  { name: 'LCASH', noreg: 'a', skip: ['T1'], gen: (r, b) => ({ x: b(), y: r(3) ? r(4) : b(), mem: { CASH: r(2) ? [0, 0, r(4), b()] : arr(b, 4) } }) },
  { name: 'tnpr', noreg: 'xy', gen: (r, b) => ({ a: r(40), mem: { QQ29: r(17), QQ20: arr(() => r(12), 17), CRGO: [20, 35][r(2)] } }) },
  { name: 'prq', noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r) => ({ a: 160 + r(90) === 165 ? 170 : 176, mem: pos(r) }) },
  { name: 'TT151', noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r, b) => ({ a: r(17), mem: { ...mkt(r, b), XC: 0, YC: 2 + r(18), QQ17: [0x80, 0xFF][r(5) ? 0 : 1] } }) },
  { name: 'TT167', n: Math.min(N, 150), long: true, noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r, b) => ({ mem: mkt(r, b) }) },
  { name: 'TT213', n: Math.min(N, 150), long: true, noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r, b) => ({ mem: mkt(r, b) }) },
  { name: 'dn', n: 60, noreg: 'axyc', skip: [...TEXT, ['XX16', 16]], screen: 'view', gen: (r, b) => ({ mem: { ...mkt(r, b), ...pos(r), DNOIZ: 0xFF } }) },
];
for (const s of SPECS) P.run({ n: N, ...s });
P.timing();
console.log(P.failed() ? `ПРОВАЛ: ${P.failed()}` : 'T31: всё совпало');
process.exit(P.failed() ? 1 : 0);
