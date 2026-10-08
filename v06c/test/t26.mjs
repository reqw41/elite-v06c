// T26: части полёта — парные тесты 6502 ↔ i8080. node v06c/test/t26.mjs [случаев = 800]
import fs from 'node:fs';
import path from 'node:path';
import { makePair } from '../tools/pair.mjs';
import { ROOT } from '../tools/v06c.mjs';
const N = +(process.argv[2] || 800);
const P = makePair('elite_t'), { B, bbc, m } = P;   // образ стенда: в обычном станция при технике от 10 — Dodo (дисковая версия)
bbc.mem.set(fs.readFileSync(path.join(ROOT, 'v06c/data/font.bin')), 0xC000);
const WS = m.L.WS, w16 = (v) => [v & 255, (v >> 8) & 255], arr = (b, n) => Array.from({ length: n }, b);
const DRAW = ['P', 'Q', 'R', 'S', 'SWAP', 'YSAV', 'SC', 'SCH', 'X1'];
const TEXT = [...DRAW, 'YSAV2', 'XSAV2', ['P', 3], ['V', 2]];
const ADD = ['T', 'T1', 'U'];                             // ADD не пишет (через MVS*/DIALS)
const PIX = ['T', 'T1'];                                 // PIXEL/LOIN: на Векторе T/T1 не как на BBC (line.asm)
const PTR = [['SLSP', 2], ['INF', 2], ['XX0', 2], [B.INWK + 33, 2]]; for (let i = 0; i < 13; i++) PTR.push([0x900 + 36 * i + 33, 2]);
const GAL1 = [0x4a, 0x5a, 0x48, 0x02, 0x53, 0xb7];
const fly = (r, b) => { const d = r(41), a1 = r(32), b1 = r(32), sa = r(2) << 7, sb = r(2) << 7;
  return { DELTA: d, DELT4: [(d << 2) & 255, d >> 6], ALP1: a1, ALP2: [sa, sa ^ 0x80], ALPHA: a1 | sa, BET1: b1, BET2: [sb, sb ^ 0x80], BETA: b1 | sb }; };
const dust = (r, b) => ({ NOSTM: 18, RAND: arr(b, 4), [B.SX]: arr(() => r(120) | (r(2) << 7), 19), [B.SY]: arr(() => r(120) | (r(2) << 7), 19), [B.SZ]: arr(() => 16 + r(240), 19) });
const bp = (t) => ({ bmem: { XX0: w16(bbc.mem[B.XX21 + 2 * (t - 1)] | (bbc.mem[B.XX21 + 2 * t - 1] << 8)) }, vmem: { XX0: w16(m.rd16(m.L.XX21 + 2 * (t - 1))) } });
const SPECS = [
  { name: 'MULT3', gen: (r, b) => ({ a: b(), x: b(), y: b(), mem: { P: [b(), b()], Q: r(8) ? b() : [0, 128][r(2)] } }) },
  { name: 'MVT3', gen: (r, b) => ({ x: 3 * r(3), y: b(), mem: { K: arr(b, 4), INWK: arr(b, 9) } }) },
  { name: 'MV40', noreg: 'axyc', skip: [...DRAW, ...ADD], gen: (r, b) => ({ mem: { INWK: [...arr(b, 9), ...arr(() => b(), 18), r(40), 0, b(), b(), 0, 0, 0, 0, 0], TYPE: [128, 129, 130][r(3)], ...fly(r, b) } }) },
  { name: 'MAS2', gen: (r, b) => ({ a: b(), y: [0, 36][r(2)], mem: { [0x900]: arr(b, 72) } }) },
  { name: 'MAS3', noreg: 'x', gen: (r, b) => ({ y: [0, 36][r(2)], mem: { [0x900]: arr(() => (r(3) ? r(16) : b()), 72) } }) },
  { name: 'MAS4', gen: (r, b) => ({ a: b(), mem: { INWK: arr(b, 9) } }) },
  { name: 'FAROF', noreg: 'a', gen: (r, b) => ({ mem: { INWK: arr(() => (r(3) ? r(225) : b()), 9) } }) },
  { name: 'FAROF2', gen: (r, b) => ({ a: b(), mem: { INWK: arr(b, 9) } }) },
  { name: 'SPS4', gen: (r, b) => ({ mem: { [0x900 + 36]: [b(), b(), r(128) | (r(2) << 7), b(), b(), r(128) | (r(2) << 7), b(), b(), r(128) | (r(2) << 7)] } }) },
  { name: 'SP1', noreg: 'axyc', skip: ['SC', 'SCH', 'X1'], screen: 'dash', gen: (r, b) => ({ mem: { [0x900 + 36]: [b(), b(), r(128) | (r(2) << 7), b(), b(), r(128) | (r(2) << 7), b(), b(), r(128) | (r(2) << 7)] } }) },
  { name: 'SPBLB', noreg: 'axyc', skip: TEXT, screen: 'dash', gen: () => ({}) },
  { name: 'ECBLB', noreg: 'axyc', skip: TEXT, screen: 'dash', gen: () => ({}) },
  { name: 'ECBLB2', noreg: 'axyc', skip: TEXT, screen: 'dash', gen: () => ({ mem: { DNOIZ: 0xFF } }) },
  { name: 'cntr', noreg: 'ayc', gen: (r, b) => ({ x: r(4) ? b() : [0, 1, 127, 128, 129, 255][r(6)], mem: { DAMP: r(3) ? 0 : 0xFF } }) },
  { name: 'BUMP', noreg: 'ayc', gen: (r, b) => ({ x: r(4) ? b() : [0, 254, 255][r(3)] }) },
  { name: 'REDU', noreg: 'ayc', gen: (r, b) => ({ x: r(4) ? b() : [0, 1, 2][r(3)] }) },
  { name: 'BAD', gen: (r, b) => ({ mem: { QQ20: arr(() => r(60), 17) } }) },
  { name: 'HITCH', noreg: 'a', skip: [['XX0', 2]], gen: (r, b) => { const t = 1 + r(13), near = r(3) > 0;
    return { mem: { INWK: [b(), near ? 0 : r(2), 0, b(), near ? 0 : r(2), 0, b(), b(), r(6) ? 0 : b(), ...arr(b, 22), r(4) ? 0 : 0x20, 0, 0, 0, 0], TYPE: r(8) ? t : 128 }, ...bp(t) }; } },
  { name: 'DENGY', noreg: 'c', gen: (r, b) => ({ a: b(), x: b(), mem: { ENERGY: r(4) ? b() : [0, 1, 2][r(3)] } }) },
  { name: 'SHD', noreg: 'c', gen: (r, b) => ({ a: b(), x: r(4) ? b() : [254, 255][r(2)], mem: { ENERGY: r(4) ? b() : [0, 1, 2][r(3)] } }) },
  { name: 'PLUT', noreg: 'axyc', gen: (r, b) => ({ mem: { VIEW: r(4), INWK: arr(b, 36) } }) },
  { name: 'NwS1', noreg: 'ac', gen: (r, b) => ({ x: 10 + 2 * r(3), mem: { INWK: arr(b, 36) } }) },
  { name: 'FLIP', noreg: 'axyc', skip: [...DRAW, ...PIX], screen: 'view', gen: (r, b) => ({ mem: dust(r, b) }) },
  { name: 'LASLI', noreg: 'axyc', skip: DRAW, screen: 'view', gen: (r, b) => ({ c: r(2), mem: { RAND: arr(b, 4), GNTMP: r(240), ENERGY: 1 + r(255), QQ11: r(5) ? 0 : 8 } }) },
  { name: 'NOISE', noreg: 'axyc', gen: (r, b) => ({ a: 8 * r(10), mem: { DNOIZ: 0xFF } }) },
  { name: 'LOOK1', n: Math.min(N, 60), long: true, noreg: 'axyc', skip: [...TEXT, ...PIX, ...PTR], screen: 'view', gen: (r, b) => ({ x: r(4), mem: { QQ11: r(3) ? 0 : 8, VIEW: r(4), LASER: [15, r(2) ? 143 : 0, 0, 15],
    ...dust(r, b), FRIN: new Array(13).fill(0), [B.QQ22 + 1]: 0 } }) },
  { name: 'SOS1', noreg: 'axy', skip: [...PTR, 'SC', 'SCH'], screen: 'dash', gen: (r, b) => ({ mem: { INWK: arr(b, 36), tek: r(15), NOMSL: r(5), FRIN: new Array(13).fill(0) } }) },
  { name: 'NWSPS', noreg: 'axy', skip: [...PTR, ...TEXT], screen: 'dash', gen: (r, b) => ({ mem: { INWK: arr(b, 36), FRIN: [0x80, 0, ...new Array(11).fill(0)] }, bmem: { SLSP: w16(0x0D3F) }, vmem: { SLSP: w16(0x0D3F + WS) } }) },
  { name: 'TT110', n: 6, long: true, noreg: 'axyc', skip: [...TEXT, ...ADD, ...PTR, ['XX16', 18], 'K3', ['XX15', 6], 'X2', 'Y1', 'Y2'], screen: 'view', gen: (r, b) => ({ mem: { QQ12: r(6) ? 0xFF : 0, QQ11: 8, VIEW: r(3) ? 0 : 1 + r(3),
    QQ21: GAL1, QQ2: GAL1, QQ9: [b(), b()], QQ0: [b(), b()], tek: r(15), FIST: r(3) ? 0 : b(), QQ20: arr(() => r(20), 17), LASER: [15, 0, 0, 0], NOMSL: r(5), ...dust(r, b), FRIN: new Array(13).fill(0),
    MANY: new Array(14).fill(0), SSPR: 0, ECMA: 0, [B.LSY2]: 0xFF, [B.LSX2]: 0xFF, [B.QQ22 + 1]: 0, DNOIZ: 0xFF, MCNT: 0, FLH: 0, ENERGY: 0xFF, FSH: 0xFF, ASH: 0xFF, QQ14: 70, CABTMP: 30, GNTMP: 0, ALTIT: 0xFF } }) },
];
for (const s of SPECS) P.run({ n: N, ...s });
P.timing();
console.log(P.failed() ? `ПРОВАЛ: ${P.failed()}` : 'T26: всё совпало');
process.exit(P.failed() ? 1 : 0);
