// T04, каркас Вектора: кадры, палитра, панель и печать знака против эталона, клавиатура.
// node v06c/test/t04.mjs   (перед этим sh v06c/build.sh)
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { createVector, ROOT } from '../tools/v06c.mjs';
import { bbcView, vecView, bbcDash, vecDash, firstDiff, VIEW } from '../tools/screen.mjs';
const { BBC } = createRequire(import.meta.url)(path.join(ROOT, 'tools/oracle/bbc.js'));

let bad = 0;
const ok = (cond, text) => { console.log(`${cond ? 'OK  ' : 'FAIL'} ${text}`); if (!cond) bad++; };
const m = createVector('elite'), L = m.L;
const bbc = new BBC({ sched: true });

// 1. запуск и кадры
m.frame(40);
ok(m.rd(0x38) === 0xC3 && m.rd16(0x39) === L.isr, `вектор прерывания 0038h → isr (${L.isr.toString(16)}h)`);
const f0 = m.rd16('v_frames'); m.frame(25); const f1 = m.rd16('v_frames');
ok(f0 > 0 && f1 - f0 === 25, `счётчик кадров: за 25 кадров машины +${f1 - f0} (до этого ${f0} из 40: запуск занял ${40 - f0})`);
ok(m.rd('DL') === 30, `обработчик кадра ставит DL = 30 (ячейка BBC &9A → ${L.DL.toString(16)}h)`);
m.wr('LASCT', [3]); m.frame(2); const la = m.rd('LASCT'); m.frame(5);
ok(la === 1 && m.rd('LASCT') === 0, `LASCT убывает на 1 за кадр и останавливается на 0`);

// 2. палитра: регистр i = цвет i & 3
const want = [...fs.readFileSync(path.join(ROOT, 'v06c/build/elite.rom')).subarray(L.pal_flight - 0x100, L.pal_flight - 0x100 + 4)];
const rgb = (w) => (0xff000000 | ((w >> 6) << 22) | (((w >> 3) & 7) << 13) | ((w & 7) << 5)) >>> 0;
const pal = [...m.io.Palette].slice(0, 16).map((v) => v >>> 0);
ok(pal.every((v, i) => v === rgb(want[i & 3])), `палитра машины: 16 регистров = цвета ${want.map((b) => b.toString(16).padStart(2, '0')).join(' ')} по (номер & 3)`);

// 3. панель: экран Вектора = экран эталона (игра уже идёт и обновляет приборы, поэтому картинка кладётся заново)
m.call('dash_show');
const mem = m.mem();
let d = firstDiff(vecDash(mem), bbcDash(bbc.mem));
ok(!d, `панель 256×56 = панель эталона (&7800)${d ? ` — точка x=${d.i & 255} y=${d.i >> 8}: Вектор ${d.a}, BBC ${d.b}` : ''}`);
let junk = 0; for (let c = 0; c < 32; c++) for (let y = 248; y < 256; y++) junk += mem[0xC000 + c * 256 + 255 - y] | mem[0xE000 + c * 256 + 255 - y];
ok(junk === 0, 'строки 248–255 под панелью пусты');

// 4. клавиатура
m.key(7, 0x80, true); m.key(4, 0x02, true); m.keyboard.ss = true; m.frame(2);
const rows = [...Array(9)].map((_, i) => m.rd(L.kb_rows + i));
ok(rows[7] === 0x80 && rows[4] === 0x02 && rows[8] === 0x20 && rows.filter((v) => v).length === 3, `пробел, A и СС: матрица ${rows.map((b) => b.toString(16).padStart(2, '0')).join(' ')}`);
ok(m.call('kb_test', { a: 7 * 8 + 7 }).zf === 0 && m.call('kb_test', { a: 4 * 8 + 1 }).zf === 0 && m.call('kb_test', { a: 4 * 8 + 2 }).zf === 1, 'kb_test: пробел и A нажаты, B — нет');
m.key(7, 0x80, false); m.key(4, 0x02, false); m.keyboard.ss = false; m.frame(2);
ok([...Array(9)].every((_, i) => m.rd(L.kb_rows + i) === 0), 'после отпускания матрица пуста');

// 5. печать знака: TT26 на i8080 против TT26 на 6502. Эталону подставлен наш шрифт (на BBC он в ПЗУ, &C000).
bbc.mem.set(fs.readFileSync(path.join(ROOT, 'v06c/data/font.bin')), 0xC000);
let seed = 12345; const rnd = (n) => { seed = (seed + 0x6D2B79F5) >>> 0; let t = seed; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return (((t ^ (t >>> 14)) >>> 0) % n); };
let chars = 0, runs = 0, fail = null;
for (let run = 0; run < 300 && !fail; run++) {
  bbc.mem.fill(0, 0x6000, 0x7800);
  for (let c = 0; c < 32; c++) m.wr(VIEW + c * 256 + 64, new Uint8Array(192));
  const xc = run < 20 ? 0 : rnd(40), yc = rnd(23), q = run % 37 === 5 ? 255 : 0;
  bbc.mem[bbc.lab.XC] = xc; bbc.mem[bbc.lab.YC] = yc; bbc.mem[bbc.lab.QQ17] = q;
  m.wr('XC', [xc]); m.wr('YC', [yc]); m.wr('QQ17', [q]);
  const n = 1 + rnd(60);
  for (let i = 0; i < n && !fail; i++) {
    const bx = bbc.mem[bbc.lab.XC], by = bbc.mem[bbc.lab.YC];
    if (by >= 24) break;                                   // дальше — очистка экрана (TTX66), это этап P5
    let ch = [10, 12, 13, 127, 127][rnd(40)] ?? 32 + rnd(95);
    if (ch === 127 && (bx & 31) === 0 && by === 0) ch = 65;  // на BBC стирание отсюда пишет мимо экрана
    const rb = bbc.call('TT26', { a: ch }), rv = m.call('TT26', { a: ch, b: 0x11, c: 0x22, d: 0x33, e: 0x44, h: 0x55, l: 0x66 });
    chars++;
    const vm = m.mem(), dd = firstDiff(vecView(vm), bbcView(bbc.mem));
    const st = (o) => `XC=${o[0]} YC=${o[1]} K3=${o[2]} A=${o[3]} C=${o[4]}`;
    const sb = [bbc.mem[bbc.lab.XC], bbc.mem[bbc.lab.YC], bbc.mem[bbc.lab.K3], rb.a, rb.c], sv = [m.rd('XC'), m.rd('YC'), m.rd('K3'), rv.a, rv.cf];
    if (dd || st(sb) !== st(sv) || rv.bc !== 0x1122 || rv.de !== 0x3344 || rv.hl !== 0x5566)
      fail = `знак ${ch} при XC=${bx} YC=${by} QQ17=${q}: BBC ${st(sb)}, Вектор ${st(sv)} BC=${rv.bc.toString(16)} DE=${rv.de.toString(16)} HL=${rv.hl.toString(16)}${dd ? `, экран: столбец ${dd.i % 32}, строка ${Math.floor(dd.i / 32)}: Вектор ${dd.a}, BBC ${dd.b}` : ''}`;
  }
  runs++;
}
ok(!fail, `TT26: ${chars} знаков в ${runs} строках (в т. ч. 10, 12, 13, 127, QQ17 = 255, XC до 100) — экран, XC, YC, K3, A, C = эталон${fail ? ' — ' + fail : ''}`);

console.log(bad ? `ПРОВАЛ: ${bad}` : 'T04: всё совпало');
process.exit(bad ? 1 : 0);
