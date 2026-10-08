// T23: звёздная пыль — парные тесты 6502 ↔ i8080. node v06c/test/t23.mjs [случаев = 1500]
import { makePair } from '../tools/pair.mjs';
const N = +(process.argv[2] || 1500);
const P = makePair('elite_t'), { B, m, bbc } = P;   // образ стенда: в обычном при полёте прямо — короткие пути (straight.mjs)
const arr = (b, n) => Array.from({ length: n }, b);
const DRAW = ['SC', 'SCH', 'T1', 'X1', 'T', 'U'];	// T,U — ADD/PIXEL2 после STARS1/PIX1 не читают (liveness launch)
const sm = (r, lim) => r(lim) | (r(2) << 7);
const dust = (r, b, n) => { const mem = { NOSTM: n, RAND: arr(b, 4) };
  mem[B.SX] = arr(() => sm(r, r(8) ? 120 : 128), 19); mem[B.SY] = arr(() => sm(r, r(8) ? 120 : 128), 19); mem[B.SZ] = arr(() => (r(8) ? 16 + r(240) : b()), 19);
  mem[B.SXL] = arr(b, 19); mem[B.SYL] = arr(b, 19); mem[B.SZL] = arr(b, 19); return mem; };
const fly = (r, b, view = 0) => { const d = r(41), a1 = r(32), b1 = r(32), sa = r(2) << 7, sb = r(2) << 7;
  return { DELTA: d, DELT4: [(d << 2) & 255, d >> 6], ALP1: a1, ALP2: [sa, sa ^ 0x80], ALPHA: a1 | sa, BET1: b1, BET2: [sb, sb ^ 0x80], BETA: b1 | sb, VIEW: view, QQ11: 0 }; };
const dustFly = (r, b, i, view = 0) => (i % 8 ? { mem: fly(r, b, view) } : { mem: { ...dust(r, b, 18), ...fly(r, b, view) } });
const SPECS = [
  { name: 'PIXEL2', noreg: 'axy', skip: DRAW, screen: 'view', gen: (r, b) => ({ mem: { X1: b(), Y1: r(6) ? sm(r, 100) : [0x80, 0, 95, 96, 0xDF, 0xE0][r(6)], ZZ: [0, 79, 80, 143, 144, 255, b(), b()][r(8)] } }) },
  { name: 'PIX1', noreg: 'axy', skip: DRAW, screen: 'view', gen: (r, b) => ({ a: b(), y: 1 + r(18), mem: { P: b(), S: b(), R: b(), X1: b(), Y1: sm(r, 100), ZZ: b() } }) },
  { name: 'MULTS-2', entry: B.MULTS - 2, ventry: 'MULTS_2', gen: (r, b) => ({ a: r(6) ? b() : [0, 128][r(2)], x: b(), y: b(), c: r(2) }) },
  { name: 'nWq', noreg: 'axyc', skip: [...DRAW, ['INF', 2]], screen: 'view', gen: (r, b) => ({ c: r(2), mem: { ...dust(r, b, 1 + r(18)), FRIN: new Array(13).fill(0) } }) },
  { name: 'NWSTARS', noreg: 'axyc', skip: [...DRAW, ['INF', 2]], screen: 'view', gen: (r, b) => ({ c: r(2), mem: { ...dust(r, b, 18), QQ11: r(3) ? 0 : 8, FRIN: new Array(13).fill(0) } }) },
  { name: 'STARS1', noreg: 'axy', skip: DRAW, screen: 'view', gen: (r, b, i) => dustFly(r, b, i, 0) },
  { name: 'STARS6', noreg: 'axy', skip: DRAW, screen: 'view', gen: (r, b, i) => dustFly(r, b, i, 1) },
  { name: 'STARS2', noreg: 'axy', skip: DRAW, screen: 'view', gen: (r, b, i) => { const side = 1 + r(2); return { x: side, ...dustFly(r, b, i, side + 1) }; } },
  { name: 'STARS', noreg: 'axy', skip: DRAW, screen: 'view', gen: (r, b, i) => dustFly(r, b, i, 0) },
  { name: 'STARS (назад)', entry: 'STARS', ventry: 'STARS', noreg: 'axy', skip: DRAW, screen: 'view', gen: (r, b, i) => dustFly(r, b, i, 1) },
  { name: 'STARS (влево)', entry: 'STARS', ventry: 'STARS', noreg: 'axy', skip: DRAW, screen: 'view', gen: (r, b, i) => dustFly(r, b, i, 2) },
  { name: 'STARS (вправо)', entry: 'STARS', ventry: 'STARS', noreg: 'axy', skip: DRAW, screen: 'view', gen: (r, b, i) => dustFly(r, b, i, 3) },
];
for (const s of SPECS) P.run({ n: N, ...s });
P.timing();
console.log(P.failed() ? `ПРОВАЛ: ${P.failed()}` : 'T23: всё совпало');
process.exit(P.failed() ? 1 : 0);
