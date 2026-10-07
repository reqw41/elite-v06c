// T21: клавиатура, разбор клавиш и экран статуса — парные тесты 6502 ↔ i8080. node v06c/test/t21.mjs [случаев = 600]
import fs from 'node:fs';
import path from 'node:path';
import { makePair } from '../tools/pair.mjs';
import { ROOT } from '../tools/v06c.mjs';
const N = +(process.argv[2] || 600);
const P = makePair(), { B, bbc, m } = P;
bbc.mem.set(fs.readFileSync(path.join(ROOT, 'v06c/data/font.bin')), 0xC000);
const TEXT = ['YSAV2', 'XSAV2', ['P', 3], 'SC', 'SCH', ['V', 2], 'Q', 'R', 'S', 'SWAP', 'YSAV', 'T'];
const arr = (b, n) => Array.from({ length: n }, b);
const GAL1 = [0x4a, 0x5a, 0x48, 0x02, 0x53, 0xb7];
// клавиши: эталону — множество номеров BBC, Вектору — матрица kb_rows (обратный перевод по таблице образа)
const KB = []; for (let i = 0; i < 64; i++) { const c = m.rd(m.L.kb_bbc + i); if (c && c !== 0x69) KB.push([c, i]); }   // COPY — пауза: на BBC цикл ожидания, на i8080 ещё не сделана
const press = (list) => { bbc.keys.clear(); const rows = new Array(8).fill(0); for (const [c, i] of list) { bbc.keys.add(c); rows[i >> 3] |= 1 << (i & 7); } m.wr(m.L.kb_rows, rows); m.wr(m.L.kb_mod, [0]); };
const keys = (r, max = 3) => { const n = r(4) ? r(max + 1) : 0, l = []; for (let k = 0; k < n; k++) l.push(KB[r(KB.length)]); press(l); return l.map((x) => x[0]); };
const state = (r, b) => ({ QQ12: r(3) ? 0xFF : 0, QQ21: GAL1, QQ2: GAL1, QQ9: [b(), b()], QQ0: [b(), b()], FIST: r(3) ? 0 : b(), TALLY: r(2) ? [b(), 0] : [b(), r(40)], CRGO: [20, 35][r(2)], BST: r(2) ? 0 : 255,
  ECM: r(2) ? 0 : 255, BOMB: arr(() => (r(2) ? 0 : 255), 4), LASER: arr(() => [0, 15, 143][r(3)], 4), ENERGY: b(), CASH: [0, r(4), b(), b()], QQ14: r(71), GCNT: r(8), MJ: 0, [B.QQ22 + 1]: 0,
  [B.MANY + 10]: r(3), [B.FRIN + 2]: arr(() => r(3), 4), VIEW: r(4) });
const SPECS = [
  { name: 'BUMP2', noreg: 'yc', gen: (r, b) => ({ a: [7, 14, b()][r(3)], x: b(), mem: { DJD: r(2) ? 0 : 255 } }) },
  { name: 'REDU2', noreg: 'yc', gen: (r, b) => ({ a: [7, 14, b()][r(3)], x: b(), mem: { DJD: r(2) ? 0 : 255 } }) },
  { name: 'DKS4', noreg: 'c', gen: (r, b) => { const k = keys(r, 4); return { x: (r(2) && k.length ? k[0] : 16 + r(112)) | (r(2) << 7), y: b() }; } },
  { name: 'RDKEY', noreg: 'yc', gen: (r, b) => { keys(r, 4); return {}; } },
  { name: 'U%', ventry: 'U_', noreg: 'xc', gen: (r, b) => ({ mem: { KL: arr(b, 16) } }) },
  { name: 'DOKEY', noreg: 'axyc', gen: (r, b) => { keys(r, 5); return { mem: { JSTX: b(), JSTY: b(), QQ11: r(2) ? 0 : 8, DJD: r(2) ? 0 : 255, JSTK: 0, KL: arr(b, 16) } }; } },
  { name: 'TT17', noreg: 'c', gen: (r, b) => { keys(r, 2); return { mem: { JSTX: b(), JSTY: b(), QQ11: r(2) ? 0 : 8, DJD: 0, JSTK: 0 } }; } },
  { name: 'STATUS', n: Math.min(N, 300), noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r, b) => ({ mem: state(r, b) }) },
  { name: 'TT102', n: Math.min(N, 300), noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r, b) => ({ a: r(2) ? 0x76 : [0, 0x62, 0x41, 0x99][r(4)], mem: { ...state(r, b), QQ11: [0, 1, 8][r(3)] } }) },
];
for (const s of SPECS) P.run({ n: N, ...s });
press([]);
P.timing();
console.log(P.failed() ? `ПРОВАЛ: ${P.failed()}` : 'T21: всё совпало');
process.exit(P.failed() ? 1 : 0);
