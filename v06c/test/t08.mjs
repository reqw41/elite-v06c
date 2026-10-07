// T08: движение корабля и сканер — парные тесты 6502 ↔ i8080. node v06c/test/t08.mjs [случаев = 3000]
import { makePair } from '../tools/pair.mjs';
const N = +(process.argv[2] || 3000);
const P = makePair(), { B, m, bbc } = P;
const arr = (b, n) => Array.from({ length: n }, b);
const DRAW = ['SC', 'SCH', 'X1', 'T', 'T1', 'U'];          // T/T1/U — ADD не пишет (liveness launch)
// блок корабля: координаты, ориентация, скорость, вращение, флаги; ИИ выключен (тактика — этап P4)
const ship = (r, b) => {
  const w = arr(b, 36);
  if (r(2)) for (const i of [1, 4, 7]) w[i] = r(64);       // в пределах сканера
  if (r(2)) for (let i = 9; i < 27; i += 2) { w[i] = 0; w[i + 1] = r(97) | (r(2) << 7); }   // ориентация как в игре
  w[27] = r(45); w[28] = r(5) ? 0 : b(); w[32] &= 0x7f;
  if (r(4) === 0) w[29] = [0, 127, 255, 128][r(4)];
  if (r(4) === 0) w[30] = [0, 127, 255, 128][r(4)];
  return w;
};
const bp0 = bbc.mem[B.XX21] | (bbc.mem[B.XX21 + 1] << 8), vp0 = m.L.ship_5654;      // первая модель: предел скорости в байте 15
const player = (r, b) => { const a1 = r(32), b1 = r(32), sa = r(2) << 7, sb = r(2) << 7; return { ALP1: a1, ALP2: [sa, sa ^ 0x80], BET1: b1, BET2: [sb, sb ^ 0x80], ALPHA: a1 | sa, BETA: b1 | sb, DELTA: r(41) }; };
const SPECS = [
  { name: 'MVT1', gen: (r, b) => ({ a: b(), x: 3 * r(3), y: b(), c: r(2), mem: { R: b(), INWK: arr(b, 9) } }) },
  { name: 'MVT1-2', entry: B.MVT1 - 2, ventry: 'MVT1_2', gen: (r, b) => ({ a: b(), x: 3 * r(3), y: b(), c: r(2), mem: { R: b(), INWK: arr(b, 9) } }) },
  { name: 'MVT6', gen: (r, b) => ({ a: b(), x: 3 * r(3), y: b(), c: r(2), mem: { [B.P + 1]: [b(), b()], INWK: arr(b, 9) } }) },
  { name: 'MLTU2-2', entry: B.MLTU2 - 2, ventry: 'MLTU2_2', gen: (r, b) => ({ a: b(), x: b(), y: b(), c: r(2), mem: { P: b() } }) },
  { name: 'MVS4', skip: ['T', 'T1', 'U'], gen: (r, b) => ({ y: [9, 15, 21][r(3)], mem: { INWK: ship(r, b), ...player(r, b) } }) },
  { name: 'MVS5', skip: ['T', 'T1', 'U'], gen: (r, b) => { const k = r(6); return { x: 15 + 2 * (k % 3), y: (k < 3 ? 9 : 21) + 2 * (k % 3), mem: { INWK: ship(r, b), RAT2: r(2) << 7 } }; } },
  { name: 'CPIX2', noreg: 'axyc', skip: DRAW, screen: 'dash', gen: (r, b) => ({ mem: { X1: r(250), Y1: 193 + r(54), COL: [0xff, 0xf0, 0x0f][r(3)] } }) },
  { name: 'CPIX4', noreg: 'axyc', skip: DRAW, screen: 'dash', gen: (r, b) => ({ mem: { X1: r(250), Y1: 194 + r(53), COL: [0xff, 0xf0, 0x0f][r(3)] } }) },
  { name: 'SCAN', noreg: 'axyc', skip: DRAW, screen: 'dash', gen: (r, b) => { const w = ship(r, b); if (r(4)) w[31] |= 0x10; return { mem: { INWK: w, TYPE: r(8) ? 1 + r(12) : b() } }; } },
  { name: 'MVEIT', noreg: 'axyc', skip: [...DRAW, ['XX0', 2]], screen: 'dash',
    gen: (r, b) => ({ mem: { INWK: ship(r, b), TYPE: 1 + r(12), MCNT: b(), XSAV: b(), ...player(r, b) }, bmem: { XX0: [bp0 & 255, bp0 >> 8] }, vmem: { XX0: [vp0 & 255, vp0 >> 8] } }) },
];
for (const s of SPECS) P.run({ n: N, ...s });
P.timing();
const b = B.MVT6 - B.MVEIT + (B.cntr - B.cntr) + (B.MVS5 - B.MVS4) + 0, v = m.L.move_end - m.L.move_start;
console.log(`\nразмер кода движения: Вектор ${v} Б`);
console.log(P.failed() ? `ПРОВАЛ: ${P.failed()}` : 'T08: всё совпало');
process.exit(P.failed() ? 1 : 0);
