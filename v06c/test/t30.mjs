// T30: карты галактики и данные о системе — парные тесты 6502 ↔ i8080. node v06c/test/t30.mjs [случаев = 300]
import fs from 'node:fs';
import path from 'node:path';
import { makePair } from '../tools/pair.mjs';
import { ROOT } from '../tools/v06c.mjs';
const N = +(process.argv[2] || 300);
const P = makePair('elite_t'), { B, bbc } = P;   // сборка стенда: WSCAN не ждёт кадра (sh v06c/build.sh -DSCHED)
bbc.mem.set(fs.readFileSync(path.join(ROOT, 'v06c/data/font.bin')), 0xC000);
const arr = (b, n) => Array.from({ length: n }, b);
const TEXT = ['YSAV2', 'XSAV2', ['P', 3], 'SC', 'SCH', ['V', 2], 'Q', 'R', 'S', 'SWAP', 'YSAV', 'T', 'T1'];
const GAL = [[0x4a, 0x5a, 0x48, 0x02, 0x53, 0xb7], [0x94, 0xb4, 0x90, 0x04, 0xa6, 0x6f], [0x29, 0x69, 0x21, 0x08, 0x4d, 0xde]];
const pos = (r) => ({ XC: r(12), YC: r(18), QQ17: [0, 0x80, 0xC0][r(3)] });
const gal = (r, b) => { const g = GAL[r(3)]; return { QQ21: g, QQ2: g, QQ9: [b(), b()], QQ0: [b(), b()], QQ14: r(71), GCNT: r(8), MJ: 0, [B.QQ22 + 1]: 0, RAND: arr(b, 4), [B.LSY2]: 0xFF, [B.LSX2]: 0xFF,
  VIEW: r(4), LASER: [15, 0, 0, 0] }; };
const SPECS = [
  { name: 'TT69', noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r) => ({ mem: pos(r) }) },
  { name: 'TTX69', noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r) => ({ mem: pos(r) }) },
  { name: 'TT60', noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r) => ({ a: 32 + r(64), mem: pos(r) }) },
  { name: 'TT146', noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r, b) => ({ mem: { QQ8: r(4) ? [b(), r(3)] : [0, 0], ...pos(r) } }) },
  { name: 'TT123', noreg: 'y', gen: (r, b) => ({ a: r(4) ? b() : [0, 1, 254, 255][r(4)], mem: { [B.QQ19 + 3]: [1, 0xFF, 0, b()][r(4)] } }) },
  { name: 'TT25', n: Math.min(N, 200), noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r, b) => ({ mem: { ...gal(r, b), QQ15: arr(b, 6), QQ3: r(8), QQ4: r(8), QQ5: r(15), QQ6: r(70), QQ7: [b(), b()], QQ8: r(4) ? [b(), r(3)] : [0, 0] } }) },
  { name: 'TT105', noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r, b) => ({ mem: { QQ9: [b(), b()], QQ0: [b(), b()], QQ11: 0x80 } }) },
  { name: 'TT103', noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r, b) => ({ mem: { QQ9: [b(), b()], QQ0: [b(), b()], QQ11: [0, 0x40, 0x80][r(3)] } }) },
  { name: 'TT14', n: Math.min(N, 150), noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r, b) => ({ mem: { ...gal(r, b), QQ11: [0x40, 0x80][r(2)] } }) },
  { name: 'TT16', noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r, b) => ({ x: [0, 1, 0xFF][r(3)], y: [0, 1, 0xFF][r(3)], mem: { QQ9: [b(), b()], QQ0: [b(), b()], QQ11: [0x40, 0x80][r(2)] } }) },
  { name: 'hm', n: Math.min(N, 100), noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r, b) => ({ mem: { ...gal(r, b), QQ11: [0, 0x40, 0x80][r(3)], ...pos(r) } }) },
  { name: 'TT22', n: Math.min(N, 40), long: true, noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r, b) => ({ mem: gal(r, b) }) },
  { name: 'TT23', n: Math.min(N, 40), long: true, noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r, b) => ({ mem: gal(r, b) }) },
];
for (const s of SPECS) P.run({ n: N, ...s });
P.timing();
console.log(P.failed() ? `ПРОВАЛ: ${P.failed()}` : 'T30: всё совпало');
process.exit(P.failed() ? 1 : 0);
