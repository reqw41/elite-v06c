// T25: планета и солнце — парные тесты 6502 ↔ i8080. node v06c/test/t25.mjs [случаев = 600]
import { makePair } from '../tools/pair.mjs';
const N = +(process.argv[2] || 600);
const MER = !!process.env.MERID;                          // MERID=1 — сборка с меридианами и кратером (elite_merid.rom)
const P = makePair(MER ? 'elite_merid' : 'elite'), { B, bbc } = P;
if (!MER) bbc.mem[B.PL25] = 0x60;                         // планета — окружность: в эталоне RTS на месте меридианов
const w16 = (v) => [v & 255, (v >> 8) & 255], arr = (b, n) => Array.from({ length: n }, b);
const DRAW = ['P', 'Q', 'R', 'S', 'SWAP', 'YSAV', 'SC', 'SCH'];
const DRAW_H = [...DRAW, 'T'];                          // HLOIN пишет T на BBC; на Векторе — регистры
const DRAW_ADD = [...DRAW, 'T', 'T1', 'U'];              // PLS22 → ADD
const rot = (r) => {
  const a = r(360) * Math.PI / 180, b = r(360) * Math.PI / 180, c = r(360) * Math.PI / 180;
  const [ca, sa, cb, sb, cc, sc] = [Math.cos(a), Math.sin(a), Math.cos(b), Math.sin(b), Math.cos(c), Math.sin(c)];
  const M = [[cb * cc, -cb * sc, sb], [sa * sb * cc + ca * sc, -sa * sb * sc + ca * cc, -sa * cb], [-ca * sb * cc + sa * sc, ca * sb * sc + sa * cc, ca * cb]];
  return M.flat().flatMap((v) => { const q = Math.min(0x6000, Math.round(Math.abs(v) * 0x6000)); return [q & 255, (q >> 8) | (v < 0 ? 0x80 : 0)]; });
};
const sm24 = (r, max) => { const v = r(max); return [v & 255, (v >> 8) & 255, ((v >> 16) & 127) | (r(2) << 7)]; };
// тело: планета (128 — меридианы, 130 — кратер) или солнце (129); z от вплотную до далеко, иногда сзади или вне экрана
let type = 128;
const body = (r, fresh, sun) => {
  if (fresh) type = sun ? 129 : [128, 130][r(2)];
  const k = r(8), z = k === 0 ? r(0x300000) : (1 + r(46)) * 256 + r(256) + (r(4) ? 0 : r(3) << 16), side = Math.max(2, Math.floor(z * (r(4) ? 0.5 : 1.6)));
  const w = [...sm24(r, side), ...sm24(r, side), z & 255, (z >> 8) & 255, ((z >> 16) & 127) | (r(12) ? 0 : 0x80), ...rot(r), 0, 0, 0, 0, 0, 0, 0, 0, 0];
  const mem = { INWK: w, TYPE: type, RAND: [r(256), r(256), r(256), r(256)] };
  if (fresh) Object.assign(mem, { [B.LSX2]: 0xFF, [B.LSY2]: 0xFF, LSP: 1, [B.LSO]: [0xFF, ...new Array(191).fill(0)], SUNX: w16(128) });
  return { mem };
};
// таблицы синуса и арктангенса в образе — как в эталоне
for (const [t, n] of MER ? [['SNE', 32], ['ACT', 32]] : [['SNE', 32]]) for (let i = 0; i < n; i++) if (P.m.rd(P.m.L[t] + i) !== bbc.mem[B[t] + i]) throw new Error(`таблица ${t}: элемент ${i}: Вектор ${P.m.rd(P.m.L[t] + i)}, BBC ${bbc.mem[B[t] + i]}`);
const SPECS = [
  { name: 'ARCTAN', noreg: 'y', gen: (r, b) => ({ mem: { P: b(), Q: r(6) ? b() : 0 } }) },
  { name: 'PLS1', noreg: 'c', gen: (r, b) => ({ x: 9 + 2 * r(9), mem: { INWK: body(r, false).mem.INWK } }) },
  { name: 'PLS3', noreg: 'c', gen: (r, b) => ({ x: 9 + 2 * r(9), mem: { INWK: body(r, false).mem.INWK } }) },
  { name: 'PLS4', noreg: 'xyc', gen: (r, b) => ({ a: b(), mem: { P: b(), [B.INWK + 14]: b() } }) },
  { name: 'PLS5', noreg: 'ac', gen: (r, b) => ({ x: [15, 21][r(2)], mem: { INWK: body(r, false).mem.INWK } }) },
  { name: 'EDGES', noreg: 'x', gen: (r, b) => ({ a: b(), y: 1 + r(191), mem: { YY: w16(r(4) ? r(256) : r(700) - 220), [B.LSO + 1]: arr(() => r(60), 191) } }) },
  { name: 'HLOIN2', noreg: 'axyc', skip: DRAW_H, screen: 'view', gen: (r, b) => ({ a: 1 + r(120), y: 1 + r(191), mem: { YY: w16(r(4) ? r(256) : r(700) - 220) } }) },
  { name: 'PLANET', noreg: 'axyc', skip: DRAW_ADD, screen: 'view', gen: (r, b, i) => body(r, i % 6 === 0, false) },
  { name: 'PLANET (солнце)', entry: 'PLANET', ventry: 'PLANET', noreg: 'axyc', skip: DRAW_ADD, screen: 'view', gen: (r, b, i) => body(r, i % 6 === 0, true) },
];
// покрытие ветвей эталона в сериях PLANET
const COV = ['PL2', 'PL9', 'PL25', 'PL26', 'PLS2', 'PLS22', 'PL42', 'PL43', 'PL40', 'WPL1', 'WP2', 'WP1', 'SUN', 'PLF3', 'PLF17', 'PLF4', 'PLFL2', 'PLFL', 'PLF44', 'PLF11', 'PLF23', 'PLF16', 'PLF10', 'PLFL3', 'PLF8', 'WPLS', 'ED1', 'ED3', 'AR1', 'AR2', 'AR3', 'BL5', 'BL1', 'LL137'];
const hits = Object.fromEntries(COV.map((n) => [n, 0])), at = new Map(COV.map((n) => [B[n], n]));
const step = bbc.cpu.step.bind(bbc.cpu); let cov = false;
bbc.cpu.step = () => { if (cov) { const n = at.get(bbc.cpu.pc); if (n) hits[n]++; } step(); };
const MERONLY = new Set(['ARCTAN', 'PLS1', 'PLS3', 'PLS4', 'PLS5']);
for (const s of SPECS) { if (!MER && MERONLY.has(s.name)) continue; cov = s.name.startsWith('PLANET'); P.run({ n: N, ...s }); }
console.log('ветви эталона в сериях PLANET: ' + COV.map((n) => `${n} ${hits[n]}`).join(', '));
P.timing();
console.log(P.failed() ? `ПРОВАЛ: ${P.failed()}` : 'T25: всё совпало');
process.exit(P.failed() ? 1 : 0);
