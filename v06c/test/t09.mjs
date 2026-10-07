// T09: отсечение и печать корабля — парные тесты 6502 ↔ i8080. node v06c/test/t09.mjs [случаев = 3000]
import { makePair } from '../tools/pair.mjs';
const N = +(process.argv[2] || 3000);
const P = makePair(), { B, m, bbc } = P;
const WS = m.L.WS, w16 = (v) => [v & 255, (v >> 8) & 255];
const DRAW = ['P', 'Q', 'R', 'S', 'SWAP', 'YSAV', 'SC', 'SCH'];      // рабочие ячейки LOIN на BBC
const PTRS = [['V', 2], ['XX0', 2], ['XX19', 2], ['INF', 2]];
// координата экрана со знаком, 16 бит: чаще около экрана
const sc16 = (r, lim) => { const k = r(6); const v = k < 3 ? r(lim) : k < 5 ? r(700) - 300 : r(65536) - 32768; return w16(v); };
const clipMem = (r) => { const p1 = [...sc16(r, 256), ...sc16(r, 192)], x2 = sc16(r, 256), y2 = sc16(r, 192); return { XX15: [...p1, ...x2], XX12: y2 }; };
// блок корабля: положение перед игроком, ориентация — настоящая матрица поворота длиной 96
const rot = (r) => {
  const a = r(360) * Math.PI / 180, b = r(360) * Math.PI / 180, c = r(360) * Math.PI / 180;
  const [ca, sa, cb, sb, cc, sc] = [Math.cos(a), Math.sin(a), Math.cos(b), Math.sin(b), Math.cos(c), Math.sin(c)];
  const M = [[cb * cc, -cb * sc, sb], [sa * sb * cc + ca * sc, -sa * sb * sc + ca * cc, -sa * cb], [-ca * sb * cc + sa * sc, ca * sb * sc + sa * cc, ca * cb]];
  return M.flat().flatMap((v) => { const q = Math.min(0x6000, Math.round(Math.abs(v) * 0x6000)); return [q & 255, (q >> 8) | (v < 0 ? 0x80 : 0)]; });
};
const sm24 = (r, max) => { const v = r(max); return [v & 255, (v >> 8) & 255, r(2) << 7]; };
let type = 1;
const ship = (r, fresh) => {
  const far = r(5) === 0, near = !far && r(5) === 0, zhi = far ? 8 + r(180) : near ? 0 : 1 + r(12), z = near ? 6 + r(250) : (zhi << 8) | r(256), side = Math.max(2, Math.floor(z * (r(4) ? 0.4 : 1.3)));
  const w = [...sm24(r, side), ...sm24(r, side), z & 255, z >> 8, r(12) ? 0 : 0x80, ...rot(r), r(40), 0, r(256), r(256)];
  const old = bbc.mem[B.INWK + 31];
  w.push((fresh ? 0 : old & 0x08) | (r(6) ? 0 : 0x40) | (r(2) << 4), 0, 0, 0, 0);
  return w;
};
const HEAP = 0x0C00, BLOCK = 0x0900;
const shipCase = (r, i, every) => {
  const fresh = i % every === 0;
  if (fresh) type = 1 + r(13);
  const bp = bbc.mem[B.XX21 + 2 * (type - 1)] | (bbc.mem[B.XX21 + 2 * type - 1] << 8), vp = m.rd16(m.L.XX21 + 2 * (type - 1));
  return { mem: { INWK: ship(r, fresh), TYPE: type, ...(fresh ? { [HEAP]: 0 } : {}) },
    bmem: { XX0: w16(bp), XX19: w16(HEAP), INF: w16(BLOCK) }, vmem: { XX0: w16(vp), XX19: w16(WS + HEAP), INF: w16(WS + BLOCK) } };
};
const SPECS = [
  { name: 'LL118', noreg: 'axyc', gen: (r, b) => ({ mem: { ...clipMem(r), [B.XX12 + 2]: [b(), r(2) << 7], T: r(2) ? 0 : 255 } }) },
  { name: 'LL145', noreg: 'ax', gen: (r, b) => ({ y: b(), mem: clipMem(r) }) },
  { name: 'LL147', noreg: 'ax', gen: (r, b) => { const c = clipMem(r); return { a: c.XX15[5], y: b(), mem: { ...c, SWAP: r(2) ? 0 : 255 } }; } },
  { name: 'LL155', noreg: 'axyc', skip: [...DRAW, ...PTRS], screen: 'view', gen: (r, b) => { const n = r(12), h = [1 + 4 * n]; for (let k = 0; k < n; k++) h.push(r(256), r(192), r(256), r(192));
    return { mem: { [HEAP]: h }, bmem: { XX19: w16(HEAP) }, vmem: { XX19: w16(WS + HEAP) } }; } },
  { name: 'SHPPT', noreg: 'axyc', skip: [...DRAW, ...PTRS], screen: 'view', gen: (r, b, i) => shipCase(r, i, 4) },
  { name: 'LL9', noreg: 'axyc', skip: [...DRAW, ...PTRS], screen: 'view', areas: [[0x0100, 0x01C0]], gen: (r, b, i) => shipCase(r, i, 6) },
];
// покрытие: сколько раз эталон прошёл через ветви LL9 (чтобы «совпало» не означало «не дошло»)
const COV = ['LL10', 'LL14', 'LL13', 'SHPPT', 'LL17', 'EE29', 'LL90', 'LL87', 'LL143', 'ovflw', 'LL92', 'LL49', 'LL52', 'LL54', 'LL56', 'LL140', 'LL57', 'LL61', 'LL69', 'LL62', 'LL70', 'LL67', 'LL72', 'LL79', 'LL80', 'LL78', 'LL115', 'LLX117', 'LL137', 'LL109', 'LL146', 'LL27', 'nono'];
const hits = Object.fromEntries(COV.map((n) => [n, 0])), at = new Map(COV.map((n) => [B[n], n]));
const step = bbc.cpu.step.bind(bbc.cpu); let cov = false;
bbc.cpu.step = () => { if (cov) { const n = at.get(bbc.cpu.pc); if (n) hits[n]++; } step(); };
for (const s of SPECS) { cov = s.name === 'LL9'; P.run({ n: N, ...s }); }
console.log('ветви эталона в серии LL9: ' + COV.map((n) => `${n} ${hits[n]}`).join(', '));
P.timing();
const bb = (B.LL118 - B.LL9) + (B.LL120 - B.LL118) + (B.checksum0 - B.LL145) + (B.LL5 - B.SHPPT), v = m.L.ship_end - m.L.ship_start + m.L.clip_end - m.L.clip_start;
console.log(`\nразмер кода (LL9, LL155, SHPPT, LL118, LL145; у BBC сюда же входят LL61 и LL62): BBC ${bb} Б → Вектор ${v} Б: ×${(v / bb).toFixed(2)}`);
console.log(P.failed() ? `ПРОВАЛ: ${P.failed()}` : 'T09: всё совпало');
process.exit(P.failed() ? 1 : 0);
