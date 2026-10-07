// Парные тесты 6502 ↔ i8080: одна и та же процедура зовётся в эталоне (tools/oracle, m.call) и на Векторе
// (v06c/tools/v06c.mjs, call) с одним входом; после вызова сравниваются A, X ↔ B, Y ↔ C, перенос и рабочие
// области (нулевая страница, T%, K%, WP: адрес Вектора = адрес BBC + WS).
import path from 'node:path';
import { createRequire } from 'node:module';
import { createVector, ROOT } from './v06c.mjs';
import { bbcDash, vecDash, bbcView, vecView, firstDiff } from './screen.mjs';
const { BBC } = createRequire(import.meta.url)(path.join(ROOT, 'tools/oracle/bbc.js'));

export const AREAS = [[0x0000, 0x0100], [0x0300, 0x0372], [0x0900, 0x0F34], [0x0F48, 0x0F51]];
const RESERVED = new Set('A B C D E H L I R M F AF BC DE HL SP IX IY NZ Z NC PO PE P'.split(' '));
// имя метки BBC → имя в исходниках Вектора (то же правило, что в tools/convert/bbcvars.py)
export const vname = (n) => { const s = n.replace(/%/g, '_'); return RESERVED.has(s.toUpperCase()) ? s + '_' : s; };
export const EDGE = [0, 1, 2, 3, 63, 64, 65, 95, 96, 97, 127, 128, 129, 191, 192, 254, 255];

export function makePair(rom = 'elite') {
  const m = createVector(rom), bbc = new BBC({ sched: true }), B = bbc.lab, WS = m.L.WS;
  m.frame(30);
  let seed = 20261007;
  // mulberry32: у линейного генератора младшие биты соседних вызовов связаны, и сочетания условий выпадали не все
  const rnd = (n) => { seed = (seed + 0x6D2B79F5) >>> 0; let t = seed; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return (((t ^ (t >>> 14)) >>> 0) % n); };
  const byte = () => (rnd(3) ? rnd(256) : EDGE[rnd(EDGE.length)]);          // треть случаев — края
  const names = {};                                         // адрес BBC → имя (для сообщений)
  for (const [n, a] of Object.entries(B)) if (a < 0x0F51 && n !== 'S%' && !(a in names)) names[a] = n;
  const cell = (a) => { for (let k = 0; k < 8; k++) if ((a - k) in names) return names[a - k] + (k ? '+' + k : ''); return '&' + a.toString(16); };
  const stats = [];
  // spec: { name, entry (метка BBC или адрес; по умолчанию name), ventry (метка Вектора), n, gen(rnd, byte, i) →
  //   {a, x, y, c, mem: {меткаBBC: байт | [байты]}}, skip: [метки BBC или [метка, длина]] — ячейки вне сравнения,
  //   noreg: 'axyc' — регистры вне сравнения, screen: 'dash' | 'view' — сравнивать ещё и экран;
  //   long: true — долгая процедура (запас по тактам);
  //   areas: [[от, до]] — ещё области BBC для сравнения (например куча вершин XX3);
  //   gen может вернуть bmem / vmem — память только для BBC / только для Вектора (адреса и метки своей машины) }
  function run(spec) {
    const { name, n = 2000, skip = [], noreg = '' } = spec, entry = spec.entry ?? name, ventry = spec.ventry ?? vname(name);
    const st = { name, n: 0, b: 0, v: 0, fail: null };
    stats.push(st);
    if (!(ventry in m.L)) { st.fail = `на Векторе нет метки ${ventry}`; return report(st); }
    const areas = [...AREAS, ...(spec.areas || [])];
    const off = new Set();
    for (const s of skip) { const [lab, len] = Array.isArray(s) ? s : [s, 1]; for (let k = 0; k < len; k++) off.add((typeof lab === 'number' ? lab : B[lab]) + k); }
    for (let a = 0; a < 0x100; a++) { const v = rnd(256); bbc.mem[a] = v; }   // мусор в нулевой странице: чтение лишнего всплывёт
    for (const [lo, hi] of areas) m.wr(WS + lo, bbc.mem.subarray(lo, hi));
    if (spec.screen === 'dash') {                           // панель Вектора — как у эталона (игра в образе её уже обновляла)
      const dash = bbcDash(bbc.mem);
      for (let c = 0; c < 32; c++) for (let y = 0; y < 56; y++) { let p1 = 0, p0 = 0;
        for (let i = 0; i < 8; i++) { const col = dash[y * 256 + c * 8 + i]; p1 |= (col >> 1) << (7 - i); p0 |= (col & 1) << (7 - i); }
        m.wr(0xC000 + c * 256 + 255 - (192 + y), [p1]); m.wr(0xE000 + c * 256 + 255 - (192 + y), [p0]); }
    }
    if (spec.screen === 'view') { bbc.mem.fill(0, 0x6000, 0x7800); for (let c = 0; c < 32; c++) m.wr(0xC000 + c * 256 + 64, new Uint8Array(192)); }
    for (let i = 0; i < n && !st.fail; i++) {
      const inp = spec.gen(rnd, byte, i), mem = inp.mem || {};
      const vmem = {};
      for (const [k, v] of Object.entries(mem)) vmem[WS + (k in B ? B[k] : Number(k))] = v;
      for (const [k, v] of Object.entries(inp.vmem || {})) vmem[k in m.L ? m.L[k] : Number(k)] = v;
      const rb = bbc.call(entry, { a: inp.a, x: inp.x, y: inp.y, c: inp.c, mem: { ...mem, ...(inp.bmem || {}) } }, spec.long ? 4e8 : 2e6);
      const rv = m.call(ventry, { a: inp.a, b: inp.x, c: inp.y, cf: inp.c, mem: vmem }, spec.long ? 4e8 : 5e6);
      st.n++; st.b += rb.cycles; st.v += rv.cycles;
      const diff = [];
      if (!noreg.includes('a') && rb.a !== rv.a) diff.push(`A: BBC ${rb.a}, Вектор ${rv.a}`);
      if (!noreg.includes('x') && rb.x !== rv.b) diff.push(`X: BBC ${rb.x}, Вектор B=${rv.b}`);
      if (!noreg.includes('y') && rb.y !== rv.c) diff.push(`Y: BBC ${rb.y}, Вектор C=${rv.c}`);
      if (!noreg.includes('c') && rb.c !== rv.cf) diff.push(`перенос: BBC ${rb.c}, Вектор ${rv.cf}`);
      for (const [lo, hi] of areas) for (let a = lo; a < hi && diff.length < 6; a++) {
        const v = m.rd(WS + a);
        if (v !== bbc.mem[a] && !off.has(a)) diff.push(`${cell(a)}: BBC ${bbc.mem[a]}, Вектор ${v}`);
      }
      if (spec.screen && !diff.length) {
        const vm = m.mem(), d = spec.screen === 'dash' ? firstDiff(vecDash(vm), bbcDash(bbc.mem)) : firstDiff(vecView(vm), bbcView(bbc.mem));
        if (d) diff.push(spec.screen === 'dash' ? `панель: x=${d.i & 255} строка ${192 + (d.i >> 8)}: Вектор ${d.a}, BBC ${d.b}` : `обзор: столбец ${d.i % 32}, строка ${Math.floor(d.i / 32)}: Вектор ${d.a}, BBC ${d.b}`);
      }
      if (diff.length) {
        st.fail = `случай ${i}, вход ${JSON.stringify(inp)}: ${diff.join('; ')}`;
        for (const [lo, hi] of areas) m.wr(WS + lo, bbc.mem.subarray(lo, hi));
      }
    }
    return report(st);
  }
  function report(st) {
    console.log(`${st.fail ? 'FAIL' : 'OK  '} ${st.name}: ${st.n} случаев${st.fail ? ' — ' + st.fail : ''}`);
    return !st.fail;
  }
  // Время: 6502 на BBC — 2 МГц, i8080 на Векторе — 3 МГц (такты Вектора: команда кратна четырём).
  function timing() {
    console.log('\nпроцедура | случаев | 6502, тактов | i8080, тактов | время Вектор/BBC');
    for (const t of stats) if (t.n) console.log(`${t.name.padEnd(9)} | ${String(t.n).padStart(7)} | ${(t.b / t.n).toFixed(0).padStart(12)} | ${(t.v / t.n).toFixed(0).padStart(13)} | ${((t.v / 3) / (t.b / 2)).toFixed(2).padStart(16)}`);
  }
  return { m, bbc, B, rnd, byte, run, timing, stats, failed: () => stats.filter((s) => s.fail).length };
}
