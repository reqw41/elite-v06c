// T10, рубеж М1: цикл заставки (TLL2) на Векторе против эталона, проход за проходом; профиль и скорость.
// node v06c/test/t10.mjs [проходов первой заставки = 300] [второй = 150]
// Подготовка заставки на i8080 не перенесена: в начале каждой заставки состояние эталона (рабочие области,
// экран) копируется на Вектор, указатели переводятся в адреса Вектора. Дальше машины идут сами.
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { createVector, savePng, ROOT } from '../tools/v06c.mjs';
import { bbcView, vecView, bbcDash, vecDash, firstDiff, VIEW, PLANE2 } from '../tools/screen.mjs';
const { BBC } = createRequire(import.meta.url)(path.join(ROOT, 'tools/oracle/bbc.js'));
const N1 = +(process.argv[2] || 300), N2 = +(process.argv[3] || 150);
const m = createVector('elite'), L = m.L, WS = L.WS, bbc = new BBC({ sched: true }), B = bbc.lab;
m.frame(30);
bbc.mem.set(fs.readFileSync(path.join(ROOT, 'v06c/data/font.bin')), 0xC000);   // эталон печатает текст нашим шрифтом (на BBC он в ПЗУ)
const AREAS = [[0x0000, 0x0100], [0x0100, 0x01C0], [0x0300, 0x0372], [0x0900, 0x0F34]];
// вне сравнения: рабочие ячейки LOIN и SCAN на BBC, указатели, указатель списка отрезков в блоке корабля
const SKIP = new Set();
for (const [n, len] of [['P', 1], ['Q', 1], ['R', 1], ['S', 1], ['SWAP', 1], ['YSAV', 1], ['SC', 2], ['X1', 1], ['V', 2], ['XX0', 2], ['XX19', 2], ['INF', 2]]) for (let k = 0; k < len; k++) SKIP.add(B[n] + k);
SKIP.add(B.INWK + 33); SKIP.add(B.INWK + 34);
const names = {}; for (const [n, a] of Object.entries(B)) if (a < 0x0F40 && !(a in names)) names[a] = n;
const cell = (a) => { for (let k = 0; k < 40; k++) if ((a - k) in names) return names[a - k] + (k ? '+' + k : ''); return '&' + a.toString(16); };
const w16 = (a, v) => m.wr(a, [v & 255, v >> 8]), b16 = (a) => bbc.mem[a] | (bbc.mem[a + 1] << 8);

function copyState() {
  for (const [lo, hi] of AREAS) m.wr(WS + lo, bbc.mem.subarray(lo, hi));
  const bp = b16(B.XX0); let type = -1;
  for (let t = 0; t < 13; t++) if (b16(B.XX21 + 2 * t) === bp) type = t;
  if (type < 0) throw new Error('XX0 эталона не указывает на модель');
  w16(L.XX0, m.rd16(L.XX21 + 2 * type));
  w16(L.XX19, b16(B.XX19) + WS); w16(L.INF, b16(B.INF) + WS);
  const view = bbcView(bbc.mem), dash = bbcDash(bbc.mem);
  for (let c = 0; c < 32; c++) for (let y = 0; y < 248; y++) {
    let p1 = 0, p0 = 0;
    if (y < 192) p1 = view[y * 32 + c];
    else for (let i = 0; i < 8; i++) { const col = dash[(y - 192) * 256 + c * 8 + i]; p1 |= (col >> 1) << (7 - i); p0 |= (col & 1) << (7 - i); }
    m.wr(VIEW + c * 256 + 255 - y, [p1]); m.wr(PLANE2 + c * 256 + 255 - y, [p0]);
  }
  return type + 1;
}
const prof = new Float64Array(0x10000);
let bad = 0;
function segment(title, n, shot) {
  const type = copyState(), st = { n: 0, b: 0, v: 0, near: { n: 0, b: 0, v: 0 }, lines: 0 };
  let fail = null;
  for (let i = 0; i < n && !fail; i++) {
    const c0 = bbc.cpu.cycles;
    bbc.pass('TLL2', 1);
    const rv = m.call('title_pass', { prof }, 2e7), db = bbc.cpu.cycles - c0;
    st.n++; st.b += db; st.v += rv.cycles;
    if (bbc.mem[B.INWK + 7] === 1) { st.near.n++; st.near.b += db; st.near.v += rv.cycles; st.lines += (bbc.mem[b16(B.XX19)] - 1) >> 2; }
    const diff = [], vm = m.mem();
    for (const [lo, hi] of AREAS) for (let a = lo; a < hi && diff.length < 6; a++) if (vm[WS + a] !== bbc.mem[a] && !SKIP.has(a)) diff.push(`${cell(a)}: BBC ${bbc.mem[a]}, Вектор ${vm[WS + a]}`);
    let d = firstDiff(vecView(vm), bbcView(bbc.mem)); if (d) diff.push(`обзор: столбец ${d.i % 32}, строка ${Math.floor(d.i / 32)}: Вектор ${d.a}, BBC ${d.b}`);
    d = firstDiff(vecDash(vm), bbcDash(bbc.mem)); if (d) diff.push(`панель: x=${d.i & 255}, строка ${192 + (d.i >> 8)}: Вектор ${d.a}, BBC ${d.b}`);
    if (diff.length) fail = `проход ${i}: ${diff.join('; ')}`;
  }
  console.log(`${fail ? 'FAIL' : 'OK  '} ${title} (тип корабля ${type}): ${st.n} проходов — обзор, панель, блок корабля, список отрезков, вершины, рабочие области = эталон${fail ? ' — ' + fail : ''}`);
  if (fail) bad++;
  if (shot) { m.frame(3); savePng(m.bmp(), path.join(ROOT, 'work/v06c', shot)); }
  return st;
}
bbc.pass('TLL2', 1);
const s1 = segment('первая заставка', N1, 't10-title1.png');
bbc.keys.add(0x55); bbc.pass('TLL2', 1); bbc.keys.delete(0x55);       // N: «загрузить командира? — нет», дальше вторая заставка
const s2 = segment('вторая заставка', N2, 't10-title2.png');

// Скорость. BBC: 2 МГц; Вектор: 3 МГц. В проход BBC входит опрос клавиш (RDKEY), на Векторе его в проходе нет.
console.log('\n                         | проходов | 6502, тактов | мс BBC | i8080, тактов | мс Вектор | Вектор/BBC | проходов в секунду: BBC → Вектор');
for (const [t, s] of [['первая, весь прогон', s1], ['первая, корабль вблизи', s1.near], ['вторая, весь прогон', s2], ['вторая, корабль вблизи', s2.near]]) if (s.n) {
  const b = s.b / s.n / 2e3, v = s.v / s.n / 3e3;
  console.log(`${t.padEnd(24)} | ${String(s.n).padStart(8)} | ${(s.b / s.n).toFixed(0).padStart(12)} | ${b.toFixed(1).padStart(6)} | ${(s.v / s.n).toFixed(0).padStart(13)} | ${v.toFixed(1).padStart(9)} | ${(v / b).toFixed(2).padStart(10)} | ${(1000 / b).toFixed(1)} → ${(1000 / v).toFixed(1)}`);
}
console.log(`отрезков корабля вблизи в среднем: первая ${(s1.lines / Math.max(1, s1.near.n)).toFixed(1)}, вторая ${(s2.lines / Math.max(1, s2.near.n)).toFixed(1)}`);

// Профиль Вектора: такты относятся к процедуре, в которой стоит команда (метка с прописной буквы или общий помощник).
const HELP = new Set(['mul8', 'dash_xor', 'li_div', 'li_addr', 'norm_sq', 'tidy_norm', 'shpt', 'mv_nose', 'mv_rat', 'mvs4_hl', 'title_pass']);
const own = Object.entries(L).filter(([n, a]) => a >= 0x100 && a < L.font && (process.env.FINE || /^[A-Z]/.test(n) || HELP.has(n))).sort((a, b) => a[1] - b[1]);
const cost = {}; let total = 0, k = 0;
for (let a = 0x100; a < 0x10000; a++) { while (k + 1 < own.length && own[k + 1][1] <= a) k++; if (prof[a]) { cost[own[k][0]] = (cost[own[k][0]] || 0) + prof[a]; total += prof[a]; } }
const passes = s1.n + s2.n;
console.log(`\nпрофиль Вектора за ${passes} проходов: ${Math.round(total / passes)} тактов на проход\nдоля  | тактов на проход | процедура`);
for (const [n, c] of Object.entries(cost).sort((a, b) => b[1] - a[1]).slice(0, 24)) console.log(`${(100 * c / total).toFixed(1).padStart(5)} | ${String(Math.round(c / passes)).padStart(16)} | ${n}`);
console.log(bad ? `ПРОВАЛ: ${bad}` : 'T10: всё совпало');
process.exit(bad ? 1 : 0);
