// T36: бой — парные тесты 6502 ↔ i8080 на случайных входах (ветви, которых нет в сценарии fight).
// sh v06c/build.sh && node v06c/test/t36.mjs [случаев = 1500]
import fs from 'node:fs';
import path from 'node:path';
import { makePair } from '../tools/pair.mjs';
import { ROOT } from '../tools/v06c.mjs';
const N = +(process.argv[2] || 1500);
const P = makePair(), { B, bbc, m } = P;
bbc.mem.set(fs.readFileSync(path.join(ROOT, 'v06c/data/font.bin')), 0xC000);
const WS = m.L.WS, w16 = (v) => [v & 255, (v >> 8) & 255], arr = (b, n) => Array.from({ length: n }, b);
const K = 0x900, NI = 36, TOP = 0x0D40;
const ADD = ['T', 'T1', 'U'];                               // ADD на Векторе их не пишет (liveness launch, fight)
const DRAW = ['SC', 'SCH', 'X1', 'YSAV', 'SWAP'];
const TEXT = [...DRAW, 'YSAV2', 'XSAV2', ['P', 3], ['V', 2], 'Q', 'R', 'S', ...ADD, ['XX15', 6]];
const PTR = [['SLSP', 2], ['INF', 2], ['XX0', 2], ['XX19', 2], ['V', 2], ['SC', 2], [B.INWK + 33, 2], [0x121, 2]];   // &121 — указатель в копии блока (XX3)
for (let i = 0; i < 13; i++) PTR.push([K + NI * i + 33, 2]);
const bpB = (t) => bbc.mem[B.XX21 + 2 * (t - 1)] | (bbc.mem[B.XX21 + 2 * t - 1] << 8);
const bpV = (t) => m.rd16(m.L.XX21 + 2 * (t - 1));
const MSGS = [0, 101, 108, 111, 120, 200, 201, 208, 215, 224];
// корабль: положение чаще близкое, векторы ориентации, скорость, флаги
const shipw = (r, b) => { const w = arr(b, 36); for (const k of [1, 4, 7]) w[k] = r(3) ? r(8) : b(); for (const k of [2, 5, 8]) w[k] = r(2) << 7;
  w[27] = r(41); w[31] = (b() & 0xE8) | r(8); w[32] = r(5) ? 0x80 | b() : b(); return w; };
// вселенная: планета, станция или солнце, корабли; у каждого корабля список отрезков в куче (вниз от WP)
function universe(r, b, n = r(9)) {
  const types = [0x80, r(2) ? 8 : 0x82]; let room = TOP - (K + NI * 13) - 260;      // куча не доходит до блоков (в игре за этим следит NWSHP)
  if (types[1] === 8) room -= bbc.mem[bpB(8) + 5];
  for (let i = 0; i < n; i++) { const t = 1 + r(13), sz = bbc.mem[bpB(t) + 5]; if (sz > room) break; room -= sz; types.push(t); }
  const frin = new Array(13).fill(0), many = new Array(14).fill(0), mem = {}, vmem = {};
  let ptr = TOP;
  types.forEach((t, i) => { frin[i] = t; const w = shipw(r, b);
    if (t < 0x80) { many[t]++; ptr -= bbc.mem[bpB(t) + 5]; w[33] = ptr & 255; w[34] = ptr >> 8; vmem[WS + K + NI * i + 33] = w16(ptr + WS); }
    mem[K + NI * i] = w; });
  mem[ptr] = arr(b, TOP - ptr); mem.FRIN = frin; mem.MANY = many;
  return { types, mem, bmem: { SLSP: w16(ptr) }, vmem: { ...vmem, SLSP: w16(ptr + WS) }, heap: ptr };
}
// корабль из места s в INWK, INF и XX0 — на него
function pick(u, s) { const t = u.types[s];
  u.mem.INWK = u.mem[K + NI * s].slice(); u.mem.TYPE = t; u.mem.XSAV = s;
  u.bmem.INF = w16(K + NI * s); u.vmem.INF = w16(WS + K + NI * s);
  u.bmem[B.INWK + 33] = [u.mem.INWK[33], u.mem.INWK[34]]; u.vmem[WS + B.INWK + 33] = u.vmem[WS + K + NI * s + 33];
  if (t < 0x80) { u.bmem.XX0 = w16(bpB(t)); u.vmem.XX0 = w16(bpV(t)); }
  return t; }
const state = (r, b) => ({ RAND: arr(b, 4), ENERGY: 255, FSH: b(), ASH: b(), DLY: r(3) ? 0 : 1 + r(22), MCH: MSGS[r(MSGS.length)], de: r(4), QQ17: [0, 0x80, 0xFF][r(3)],
  QQ20: arr(() => (r(3) ? 0 : 1 + r(20)), 17), ECMA: r(4) ? 0 : 1 + r(32), SSPR: r(2) * 255, MSTG: 0xFF, DNOIZ: r(4) ? 0 : 0xFF, DELTA: r(41), TALLY: [r(8) ? b() : 255, b()],
  XC: 1, YC: 1 });
const gear = (r, b) => ({ ECM: r(2) * 255, BST: r(2) * 255, BOMB: r(2) * 127, ENGY: r(2), DKCMP: r(2) * 255, GHYP: r(2) * 255, ESCP: r(2) * 255 });
const SPECS = [
  { name: 'TAS1', skip: PTR, gen: (r, b) => { const s = r(13); return { y: [2, 5, 8][r(3)], mem: { [K + NI * s]: shipw(r, b), INWK: shipw(r, b), K3: arr(b, 9) },
    bmem: { V: w16(K + NI * s) }, vmem: { V: w16(WS + K + NI * s) } }; } },
  { name: 'TAS3', skip: ADD, gen: (r, b) => ({ y: [10, 16, 22][r(3)], mem: { INWK: shipw(r, b), XX15: arr(() => r(97) | (r(2) << 7), 3) } }) },
  { name: 'ANGRY', noreg: 'axy', skip: PTR, gen: (r, b) => { const u = universe(r, b, 1 + r(6)), s = r(u.types.length); pick(u, s); return { a: r(6) ? u.types[s] & 15 : b(), ...u }; } },
  { name: 'Ze', gen: (r, b) => ({ c: r(2), mem: { RAND: arr(b, 4), INWK: arr(b, 36) } }) },
  { name: 'EXNO', noreg: 'axyc', gen: (r, b) => ({ x: [7, 15, b()][r(3)], mem: { [B.INWK + 7]: b(), DNOIZ: r(2) * 255 } }) },
  { name: 'EXNO3', noreg: 'axyc', gen: (r, b) => ({ mem: { DNOIZ: r(2) * 255 } }) },
  { name: 'EXNO2', noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r, b) => ({ mem: { ...state(r, b), [B.INWK + 7]: b() } }) },
  { name: 'MESS', noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r, b) => ({ a: MSGS[r(MSGS.length)], mem: state(r, b) }) },
  { name: 'OUCH', noreg: 'axyc', skip: TEXT, screen: 'view', gen: (r, b) => ({ mem: { ...state(r, b), ...gear(r, b) } }) },
  { name: 'OOPS', noreg: 'axyc', skip: [...TEXT, ...PTR], screen: 'view', gen: (r, b) => { const u = universe(r, b, 1 + r(4)); pick(u, 2);
    return { a: r(3) ? r(60) : r(251), c: r(2), ...u, mem: { ...u.mem, ...state(r, b), ...gear(r, b), FSH: r(3) ? r(40) : b(), ASH: r(3) ? r(40) : b() } }; } },
  { name: 'ABORT2', noreg: 'ac', screen: 'dash', gen: (r, b) => ({ x: r(4) ? r(13) : 255, y: [0, 0xEE, 0xE0, 0x0E][r(4)], mem: { NOMSL: 1 + r(4), MSAR: b() } }) },
  { name: 'KILLSHP', noreg: 'axyc', skip: [...PTR, ['P', 3]], gen: (r, b) => { const u = universe(r, b, 1 + r(9)), s = 2 + r(u.types.length - 2); pick(u, s);
    u.types.forEach((t, i) => { if (t === 9 && r(3)) u.mem[K + NI * i][32] = 0x80 | (2 * r(u.types.length)); });
    return { x: s, ...u, mem: { ...u.mem, MSTG: 0xFF } }; } },
  { name: 'SFS1', noreg: 'axyc', skip: [...PTR, 'R', 'S', 'T'], areas: [[0x100, 0x124]], gen: (r, b) => { const u = universe(r, b, r(11)); const s = r(u.types.length); const t = pick(u, s);
    if (t >= 0x80) { u.bmem.XX0 = w16(bpB(1)); u.vmem.XX0 = w16(bpV(1)); }
    return { a: b(), x: r(3) ? 1 + r(13) : 11, ...u, mem: { ...u.mem, RAND: arr(b, 4) } }; } },
  { name: 'FRMIS', noreg: 'axyc', skip: [...TEXT, ...PTR], screen: 'view', gen: (r, b) => { const u = universe(r, b, 1 + r(10)); const s = 2 + r(u.types.length - 2); pick(u, s);
    return { ...u, mem: { ...u.mem, ...state(r, b), MSTG: s, NOMSL: 1 + r(4), INWK: arr(b, 36) } }; } },
  { name: 'DOEXP', noreg: 'axyc', skip: [...PTR, 'SC', 'SCH', 'T1', 'X1'], screen: 'view', areas: [[0x100, 0x1C0]], gen: (r, b) => { const nv = 1 + r(8), H = 0x0C00;
    const cloud = [r(2) ? b() : r(40), b(), 6 + 4 * nv, b(), b(), b(), b(), ...arr(() => (r(4) ? 0 : b()), 4 * nv).map((v, i) => (i % 2 ? v : (r(2) ? b() : v)))];
    for (let i = 0; i < nv; i++) { cloud[7 + 4 * i] = r(5) ? 0 : b(); cloud[8 + 4 * i] = b(); cloud[9 + 4 * i] = r(5) ? 0 : b(); cloud[10 + 4 * i] = b(); }
    const w = shipw(r, b); w[31] = (b() & 0xB7) | (r(2) << 6) | (r(2) << 3); w[7] = r(3) ? r(32) : b();
    return { mem: { INWK: w, [H]: cloud, [B.XX3]: arr(b, 48), RAND: arr(b, 4), [K + 6]: b() }, bmem: { XX19: w16(H) }, vmem: { XX19: w16(WS + H) } }; } },
  { name: 'TACTICS', n: 3 * N, noreg: 'axyc', skip: [...TEXT, ...PTR], screen: 'view', areas: [[0x100, 0x124]],
    gen: (r, b) => { const u = universe(r, b, 1 + r(9)); let s = 1 + r(u.types.length - 1); if (u.types[s] >= 0x80) s = 2; const t = pick(u, s);
      if (t === 9) u.mem.INWK[32] = r(3) ? 0x80 | (2 * r(u.types.length)) : 0xC0 | r(64);
      if (t === 8 && r(2)) u.mem.INWK[32] |= 0x80;
      const w = u.mem.INWK; if (r(3) === 0) { w[0] = w[3] = w[6] = 0; } if (r(4) === 0) { w[1] = w[4] = w[7] = 0; }
      w[35] = r(3) ? r(40) : b(); u.mem[K + NI * s] = w.slice(); u.bmem[B.INWK + 33] = [w[33], w[34]];
      return { x: t, ...u, mem: { ...u.mem, ...state(r, b), ...gear(r, b), [K]: shipw(r, b), MCNT: b() } }; } },
];
for (const s of SPECS) P.run({ n: N, ...s });
P.timing();
console.log(P.failed() ? `ПРОВАЛ: ${P.failed()}` : 'T36: всё совпало');
process.exit(P.failed() ? 1 : 0);
