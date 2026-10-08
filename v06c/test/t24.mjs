// T24: окружности, взлётный туннель, прицел, луч лазера — парные тесты 6502 ↔ i8080. node v06c/test/t24.mjs [случаев = 800]
import fs from 'node:fs';
import path from 'node:path';
import { makePair } from '../tools/pair.mjs';
import { ROOT } from '../tools/v06c.mjs';
const N = +(process.argv[2] || 800);
const P = makePair('elite_t'), { B, bbc } = P;   // образ стенда: в обычном окружность планеты — точками
bbc.mem.set(fs.readFileSync(path.join(ROOT, 'v06c/data/font.bin')), 0xC000);
const w16 = (v) => [v & 255, (v >> 8) & 255];
const DRAW = ['P', 'Q', 'R', 'S', 'SWAP', 'YSAV', 'SC', 'SCH', 'T'];
const TEXT = [...DRAW, 'YSAV2', 'XSAV2', ['P', 3], ['V', 2]];
const c16 = (r, lim) => { const k = r(5); return w16(k < 3 ? r(lim) : k < 4 ? r(600) - 200 : r(65536) - 32768); };
const circ = (r, b) => ({ K3: c16(r, 256), K4: c16(r, 192), K: r(4) ? 1 + r(120) : b(), LSP: 1, [B.LSY2]: 0xFF, [B.LSX2]: 0xFF });
const SPECS = [
  { name: 'FMLTU2', noreg: 'y', gen: (r, b) => ({ a: b(), mem: { K: b() } }) },
  { name: 'CHKON', noreg: 'ay', gen: (r, b) => ({ mem: circ(r, b) }) },
  { name: 'BLINE', noreg: 'xyc', skip: DRAW, screen: 'view', gen: (r, b) => ({ x: b(), c: 0, mem: { K4: c16(r, 192), T: [0, 0xFF][r(2)], K6: c16(r, 256), K5: [...c16(r, 256), ...c16(r, 192)], FLAG: r(4) ? 0 : 0xFF, LSP: 1 + r(40),
    CNT: r(64), STP: [2, 4, 8][r(3)], [B.LSY2 + r(40)]: 0xFF } }) },
  { name: 'CIRCLE2', n: Math.min(N, 300), noreg: 'axy', skip: DRAW, screen: 'view', gen: (r, b) => ({ mem: { ...circ(r, b), STP: [2, 4, 8][r(3)] } }) },
  { name: 'CIRCLE', n: Math.min(N, 300), noreg: 'axy', skip: DRAW, screen: 'view', gen: (r, b) => ({ mem: circ(r, b) }) },
  { name: 'HFS2', n: 12, long: true, noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r, b) => ({ a: [8, 4, 2][r(3)], mem: { QQ11: [0, 1][r(2)], VIEW: r(4), [B.QQ22 + 1]: 0, [B.LSY2]: 0xFF } }) },
  { name: 'LAUN', n: 4, long: true, noreg: 'axyc', skip: [...TEXT, ['XX16', 16]], screen: 'view', gen: (r, b) => ({ mem: { QQ11: 0, VIEW: 0, [B.QQ22 + 1]: 0, [B.LSY2]: 0xFF, DNOIZ: 0xFF } }) },
  { name: 'TT15', noreg: 'axyc', skip: DRAW, screen: 'view', gen: (r, b) => ({ mem: { QQ19: [b(), r(170), r(40)], QQ11: [0, 0x80, 0x40][r(3)] } }) },
  { name: 'SIGHT', noreg: 'axyc', skip: DRAW, screen: 'view', gen: (r, b) => ({ mem: { VIEW: r(4), LASER: [r(2) ? 15 : 0, r(2) ? 143 : 0, 0, 15], QQ11: 0 } }) },
  { name: 'LASLI2', noreg: 'axyc', skip: DRAW, screen: 'view', gen: (r, b) => ({ mem: { LASX: 124 + r(8), LASY: 92 + r(8), QQ11: r(4) ? 0 : 8 } }) },
];
for (const s of SPECS) P.run({ n: N, ...s });
P.timing();
console.log(P.failed() ? `ПРОВАЛ: ${P.failed()}` : 'T24: всё совпало');
process.exit(P.failed() ? 1 : 0);
