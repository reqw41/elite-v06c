// T05: точка, отрезок, горизонтальная линия — экран Вектора = экран эталона; замер тактов и размера.
// node v06c/test/t05.mjs [число случаев на процедуру = 4000]
import path from 'node:path';
import { createRequire } from 'node:module';
import { createVector, ROOT } from '../tools/v06c.mjs';
import { bbcView, firstDiff, VIEW } from '../tools/screen.mjs';
const { BBC } = createRequire(import.meta.url)(path.join(ROOT, 'tools/oracle/bbc.js'));

const N = +(process.argv[2] || 4000);
let bad = 0;
const m = createVector('elite'), L = m.L, bbc = new BBC({ sched: true }), B = bbc.lab;
m.frame(30);
let seed = 2026; const rnd = (n) => { seed = (seed + 0x6D2B79F5) >>> 0; let t = seed; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return (((t ^ (t >>> 14)) >>> 0) % n); };
const view = () => { const v = new Uint8Array(32 * 192); for (let y = 0; y < 192; y++) for (let c = 0; c < 32; c++) v[y * 32 + c] = m.rd(VIEW + c * 256 + 255 - y); return v; };
const clear = () => { bbc.mem.fill(0, 0x6000, 0x7800); for (let c = 0; c < 32; c++) m.wr(VIEW + c * 256 + 64, new Uint8Array(192)); };
const where = (d) => `столбец ${d.i % 32}, строка ${Math.floor(d.i / 32)}: Вектор ${d.a.toString(2)}, BBC ${d.b.toString(2)}`;
const xx15 = (o) => [0, 1, 2, 3].map((i) => o(i)).join(',');
const T = {};                                              // имя → {n, t6502, t8080, px}
const acc = (name, rb, rv, px) => { const t = T[name] ??= { n: 0, b: 0, v: 0, px: 0 }; t.n++; t.b += rb.cycles; t.v += rv.cycles; t.px += px; };

function series(name, n, gen, run) {
  clear(); let fail = null, done = 0;
  for (let i = 0; i < n && !fail; i++) {
    if (i % 200 === 0) clear();                            // между очистками отрезки накладываются: проверяется исключающее ИЛИ
    const inp = gen(i), before = bbcView(bbc.mem);
    const { rb, rv, extra } = run(inp);
    const after = bbcView(bbc.mem); let px = 0;
    for (let k = 0; k < after.length; k++) { let x = after[k] ^ before[k]; while (x) { px++; x &= x - 1; } }
    acc(name, rb, rv, px); done++;
    const d = firstDiff(view(), after);
    if (d || extra || rv.b !== 0x5A || rv.c !== 0xA5) fail = `${JSON.stringify(inp)}: ${d ? where(d) : ''} ${extra || ''} BC=${rv.bc.toString(16)}`;
  }
  console.log(`${fail ? 'FAIL' : 'OK  '} ${name}: ${done} случаев — экран и концы = эталон${fail ? ' — ' + fail : ''}`);
  if (fail) bad++;
}

// отрезки: случайные, короткие, по осям и диагонали, точки, края экрана
const lineGen = (i) => {
  const k = i % 8, x1 = rnd(256), y1 = rnd(192);
  if (k === 0) return [x1, y1, x1, rnd(192)];
  if (k === 1) return [x1, y1, rnd(256), y1];
  if (k === 2) { const dd = rnd(Math.min(192 - y1, 256 - x1)); return rnd(2) ? [x1, y1, x1 + dd, y1 + dd] : [x1 + dd, y1, x1, y1 + dd]; }
  if (k === 3) return [x1, y1, Math.min(255, Math.max(0, x1 + rnd(17) - 8)), Math.min(191, Math.max(0, y1 + rnd(17) - 8))];
  if (k === 4) return [[0, 255][rnd(2)], rnd(192), [0, 255][rnd(2)], rnd(192)];
  if (k === 5) return [rnd(256), [0, 191][rnd(2)], rnd(256), [0, 191][rnd(2)]];
  return [x1, y1, rnd(256), rnd(192)];
};
series('LOIN', N, lineGen, (p) => {
  bbc.mem.set(p, B.X1); m.wr('X1', p);
  const rb = bbc.call('LOIN', { y: 0x44 }), rv = m.call('LOIN', { b: 0x5A, c: 0xA5 });
  const eb = xx15((i) => bbc.mem[B.X1 + i]), ev = xx15((i) => m.rd(L.X1 + i));
  return { rb, rv, extra: eb === ev && rb.y === 0x44 ? '' : `концы BBC ${eb}, Вектор ${ev}` };
});
series('HLOIN', N, (i) => (i % 5 === 0 ? [rnd(256), rnd(192), [0, 255][rnd(2)]] : i % 7 === 0 ? [rnd(256), rnd(192), -1] : [rnd(256), rnd(192), rnd(256)]), ([x1, y, x2]) => {
  if (x2 < 0) x2 = x1;
  const p = [x1, y, x2, 0];
  bbc.mem.set(p, B.X1); m.wr('X1', p);
  const rb = bbc.call('HLOIN', { y: 0x44 }), rv = m.call('HLOIN', { b: 0x5A, c: 0xA5 });
  const eb = xx15((i) => bbc.mem[B.X1 + i]), ev = xx15((i) => m.rd(L.X1 + i));
  return { rb, rv, extra: eb === ev ? '' : `концы BBC ${eb}, Вектор ${ev}` };
});
series('PIXEL', N, () => [rnd(256), rnd(192), [0, 79, 80, 143, 144, 255, rnd(256), rnd(256)][rnd(8)]], ([x, y, zz]) => {
  bbc.mem[B.ZZ] = zz; m.wr('ZZ', [zz]);
  const rb = bbc.call('PIXEL', { x, a: y, y: 0x44 }), rv = m.call('PIXEL', { b: x, a: y, c: 0xA5 });
  rv.b = 0x5A;                                             // B — вход (x)
  return { rb, rv, extra: rb.y === 0x44 ? '' : 'Y' };
});

// Время: 6502 на BBC — 2 МГц, i8080 на Векторе — 3 МГц (такты Вектора: команда кратна 4).
console.log('\nпроцедура | случаев | 6502, тактов | i8080, тактов | время Вектор/BBC | точек | i8080 тактов на точку');
for (const [name, t] of Object.entries(T)) {
  const b = t.b / t.n, v = t.v / t.n;
  console.log(`${name.padEnd(9)} | ${String(t.n).padStart(7)} | ${b.toFixed(0).padStart(12)} | ${v.toFixed(0).padStart(13)} | ${((v / 3) / (b / 2)).toFixed(2).padStart(16)} | ${(t.px / t.n).toFixed(1).padStart(5)} | ${(t.v / t.px).toFixed(1)}`);
}
// длинный отрезок: чистая цена точки
for (const [nm, p] of [['пологий 200 точек', [10, 50, 210, 120]], ['крутой 150 точек', [100, 170, 160, 20]]]) {
  clear(); bbc.mem.set(p, B.X1); m.wr('X1', p);
  const rb = bbc.call('LOIN'), rv = m.call('LOIN');
  console.log(`LOIN ${nm}: 6502 ${rb.cycles} тактов (${(rb.cycles / 2e3).toFixed(2)} мс), i8080 ${rv.cycles} (${(rv.cycles / 3e3).toFixed(2)} мс)`);
}
// Размер кода
const size = [['PIXEL', B.BLINE - B.PIXEL + (B.PIX1 - B.PX3), L.LOIN - L.PIXEL], ['LOIN', B.NLIN3 - B.LOIN, L.HLOIN - L.LOIN], ['HLOIN', B.TWFL - B.HLOIN, L.line_code_end - L.HLOIN]];
console.log('\nразмер кода, байт (без таблиц масок): ' + size.map(([n, b, v]) => `${n} ${b} → ${v} (×${(v / b).toFixed(2)})`).join(', ')
  + `; всего ${size.reduce((s, r) => s + r[1], 0)} → ${size.reduce((s, r) => s + r[2], 0)} (×${(size.reduce((s, r) => s + r[2], 0) / size.reduce((s, r) => s + r[1], 0)).toFixed(2)})`);
console.log(bad ? `ПРОВАЛ: ${bad}` : 'T05: всё совпало');
process.exit(bad ? 1 : 0);
