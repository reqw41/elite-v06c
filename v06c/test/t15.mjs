// T15: очистка экрана, рамка, нижние строки — парные тесты 6502 ↔ i8080. node v06c/test/t15.mjs [случаев = 400]
import fs from 'node:fs';
import path from 'node:path';
import { makePair } from '../tools/pair.mjs';
import { ROOT } from '../tools/v06c.mjs';
const N = +(process.argv[2] || 400);
const P = makePair(), { B, bbc, m } = P;
bbc.mem.set(fs.readFileSync(path.join(ROOT, 'v06c/data/font.bin')), 0xC000);
const SKIP = ['YSAV2', 'XSAV2', ['P', 3], 'Q', 'R', 'S', 'SWAP', 'YSAV', 'SC', 'SCH', ['V', 2], 'T'];
// одинаковый мусор на обоих экранах перед вызовом
const junk = (r) => { for (let y = 0; y < 192; y++) for (let c = 0; c < 32; c++) { const v = r(4) ? 0 : r(256); bbc.mem[0x6000 + (y >> 3) * 256 + c * 8 + (y & 7)] = v; m.wr(0xC000 + c * 256 + 255 - y, [v]); } };
const SPECS = [
  { name: 'TT66', gen: (r, b) => { junk(r); return { a: [0, 1, 4, 8, 16, 32, 64, 128][r(8)], mem: { VIEW: r(4), [B.QQ22 + 1]: 0, XC: r(30), YC: r(24), LAS2: b(), DLY: b(), de: b() } }; } },
  { name: 'TTX66', gen: (r, b) => { junk(r); return { mem: { QQ11: r(2) ? 0 : b(), VIEW: r(4), [B.QQ22 + 1]: 0, XC: r(30), YC: r(24) } }; } },
  { name: 'CLYNS', gen: (r, b) => { junk(r); return { mem: { XC: r(30), YC: r(24), QQ17: [0, 0x80, 0xC0][r(3)] } }; } },
];
for (const s of SPECS) P.run({ n: N, noreg: 'axc', skip: SKIP, screen: 'view', ...s, ...(s.name === 'CLYNS' ? {} : { noreg: 'axyc' }) });
P.timing();
console.log(P.failed() ? `ПРОВАЛ: ${P.failed()}` : 'T15: всё совпало');
process.exit(P.failed() ? 1 : 0);
