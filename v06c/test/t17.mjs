// T16, T17: сброс, запуск корабля и панель приборов — парные тесты 6502 ↔ i8080.
// node v06c/test/t17.mjs [случаев = 1500]
import { makePair } from '../tools/pair.mjs';
const N = +(process.argv[2] || 1500);
const P = makePair('elite_t'), { B, m, bbc } = P;   // образ стенда: в обычном 12 пылинок вместо 18
const WS = m.L.WS, w16 = (v) => [v & 255, (v >> 8) & 255], arr = (b, n) => Array.from({ length: n }, b);
const COLS = [0xF0, 0x0F, 0xFF];
const sc = (r) => [[0x10, 0xD0][r(2)], 0x78 + r(6)];
const CP = ['SC', 'SCH', 'X1'];
const DRAW = [...CP, 'P', 'Q', 'R', 'S', 'SWAP', 'YSAV'];
const PTR = [['SLSP', 2], ['INF', 2], ['XX0', 2], [B.INWK + 33, 2]];
const blockPtrs = []; for (let i = 0; i < 13; i++) blockPtrs.push([0x900 + 36 * i + 33, 2]);
const vec3 = (r, b) => [b(), r(128), r(2) << 7, b(), r(128), r(2) << 7, b(), r(128), r(2) << 7];
const planet = (r, b) => ({ [0x901]: [b(), b(), b(), b(), b(), b(), b(), b()] });
const flight = (r, b) => ({ DELTA: r(41), ALP1: r(32), ALP2: r(2) << 7, BET1: r(32), BETA: b(), MCNT: r(3) ? 4 * r(64) : b(), FLH: r(2) ? 0 : 255, ENERGY: b(), FSH: b(), ASH: b(),
  QQ14: r(71), CABTMP: b(), GNTMP: b(), ALTIT: b(), SSPR: 0, COMX: 186 + r(19), COMY: 195 + r(17), COMC: [0xF0, 0xFF][r(2)], ...planet(r, b) });
const slots = (r) => { const n = r(13), f = new Array(13).fill(0); for (let i = 0; i < n; i++) f[i] = r(6) ? 1 + r(13) : 0x80 + 2 * r(2); return f; };
const SPECS = [
  { name: 'PZW', gen: (r, b) => ({ x: b(), y: b(), mem: { MCNT: b(), FLH: r(2) ? 0 : b() } }) },
  { name: 'DIL', noreg: 'axyc', screen: 'dash', gen: (r, b) => ({ a: r(21), mem: { T1: r(18), K: COLS[r(3)], [B.K + 1]: COLS[r(3)], SC: sc(r) } }) },
  { name: 'DILX', noreg: 'axyc', screen: 'dash', gen: (r, b) => ({ a: b(), mem: { T1: r(18), K: COLS[r(3)], [B.K + 1]: COLS[r(3)], SC: sc(r) } }) },
  { name: 'DILX+2', entry: B.DILX + 2, ventry: 'DILX_2', noreg: 'axyc', screen: 'dash', gen: (r, b) => ({ a: r(72), mem: { T1: r(18), K: COLS[r(3)], [B.K + 1]: COLS[r(3)], SC: sc(r) } }) },
  { name: 'DIL-1', entry: B.DIL - 1, ventry: 'DIL_1', noreg: 'axyc', screen: 'dash', gen: (r, b) => ({ a: r(41), mem: { T1: r(18), K: COLS[r(3)], [B.K + 1]: COLS[r(3)], SC: sc(r) } }) },
  { name: 'DIL2', noreg: 'axyc', screen: 'dash', gen: (r, b) => ({ a: r(4) ? r(16) : b(), mem: { SC: [0xD0, 0x79 + r(2)] } }) },
  { name: 'MSBAR', noreg: 'ac', screen: 'dash', gen: (r, b) => ({ x: 1 + r(4), y: [0, 0xEE, 0xE0, 0x0E][r(4)] }) },
  { name: 'msblob', noreg: 'axyc', screen: 'dash', gen: (r, b) => ({ mem: { NOMSL: r(5) } }) },
  { name: 'SPS2', noreg: 'a', gen: (r, b) => ({ a: b() }) },
  { name: 'TAS2', gen: (r, b) => ({ mem: { K3: vec3(r, b) } }) },
  { name: 'SPS1', gen: (r, b) => ({ mem: planet(r, b) }) },
  { name: 'DOT', noreg: 'axyc', skip: CP, screen: 'dash', gen: (r, b) => ({ mem: { COMX: 186 + r(19), COMY: 195 + r(17), COMC: [0xF0, 0xFF][r(2)] } }) },
  { name: 'SP2', noreg: 'axyc', skip: CP, screen: 'dash', gen: (r, b) => ({ mem: { XX15: [r(97) | (r(2) << 7), r(97) | (r(2) << 7), r(97) | (r(2) << 7)] } }) },
  { name: 'COMPAS', noreg: 'axyc', skip: CP, screen: 'dash', gen: (r, b) => ({ mem: { SSPR: 0, COMX: 186 + r(19), COMY: 195 + r(17), COMC: [0xF0, 0xFF][r(2)], ...planet(r, b) } }) },
  { name: 'DIALS', noreg: 'axyc', skip: [...CP, 'T', 'T1', 'U'], screen: 'dash', gen: (r, b) => ({ mem: flight(r, b) }) },
  { name: 'ZERO', gen: (r, b) => ({ mem: { [0x9F0 + r(0x400)]: arr(b, 16) } }) },
  { name: 'ZINF', noreg: 'x', gen: (r, b) => ({ mem: { INWK: arr(b, 36) } }) },
  { name: 'GINF', noreg: 'ay', skip: PTR, gen: (r, b) => ({ x: r(13), y: b() }) },
  { name: 'FLFLLS', noreg: 'x', gen: (r, b) => ({ mem: { [B.LSO + r(180)]: arr(b, 12) } }) },
  { name: 'NWSHP', noreg: 'ay', skip: [...PTR, ...blockPtrs], gen: (r, b) => { const heap = r(4) ? 0x0D3F - r(300) : 0x0900 + r(0x440);
    return { a: r(8) ? 1 + r(13) : 0x80 + 2 * r(2), mem: { FRIN: slots(r), INWK: arr(b, 36) }, bmem: { SLSP: w16(heap) }, vmem: { SLSP: w16(heap + WS) } }; } },
  { name: 'WPSHPS', noreg: 'axyc', skip: [...CP, ...PTR], screen: 'dash', gen: (r, b) => { const f = slots(r), mem = { FRIN: f };
    f.forEach((t, i) => { if (t) { const w = arr(b, 36); if (r(2)) for (const k of [1, 4, 7]) w[k] = r(64); mem[0x900 + 36 * i] = w; } }); return { mem }; } },
  { name: 'RESET', n: Math.min(N, 300), noreg: 'axyc', skip: [...CP, ...PTR, ...blockPtrs], screen: 'dash', gen: (r, b) => { const f = slots(r), mem = { FRIN: f, ...flight(r, b), ECMA: 0 };
    f.forEach((t, i) => { if (t) { const w = arr(b, 36); for (const k of [1, 4, 7]) w[k] = r(64); mem[0x900 + 36 * i] = w; } }); return { mem }; } },
  { name: 'RES2', n: Math.min(N, 300), noreg: 'axyc', skip: [...CP, 'T', 'T1', 'U', ...PTR, ...blockPtrs], screen: 'dash', gen: (r, b) => ({ mem: { FRIN: new Array(13).fill(0), ...flight(r, b), ECMA: 0 } }) },
];
for (const s of SPECS) P.run({ n: N, ...s });
P.timing();
console.log(P.failed() ? `ПРОВАЛ: ${P.failed()}` : 'T16, T17: всё совпало');
process.exit(P.failed() ? 1 : 0);
