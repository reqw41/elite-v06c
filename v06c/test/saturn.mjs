// Заставка с Сатурном: рисование на Векторе (sat_draw) против настоящего кода загрузчика кассетной BBC (PLL1 из
// ELITE.unprot.bin в ядре 6502). «Таймер» VIA, которым загрузчик затравливает генератор, на обеих сторонах один
// и тот же — счётчик с шагом 2Fh. Сверяется весь экран 256×256 до точки и генератор после рисования; отдельно —
// три надписи против файлов картинок BBC; затем запуск образа с заставкой: она показана, панель на месте,
// игра доходит до своей заставки, а область рабочих областей, где лежал код Сатурна, обнулена.
// sh v06c/build.sh && node v06c/test/saturn.mjs
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { createVector, savePng, ROOT } from '../tools/v06c.mjs';
const require = createRequire(import.meta.url);
const { CPU6502, FLAGS } = require(path.join(ROOT, 'tools/oracle/cpu6502.js'));
const ORIG = process.env.ELITE_ORIG || path.join(ROOT, 'orig');
let bad = 0; const ok = (c, s) => { if (!c) bad++; console.log(`${c ? 'OK  ' : 'FAIL'} ${s}`); };

// --- BBC: загрузчик с адреса 1100h, PLL1 = 22A6h
const mem = new Uint8Array(0x10000); let tmr = 0, reads = 0;
mem.set(fs.readFileSync(path.join(ORIG, 'bbc/cassette/3-assembled-output/ELITE.unprot.bin')), 0x1100);
const cpu = new CPU6502((a) => { if (a === 0xFE44) { const v = tmr; tmr = (tmr + 0x2F) & 255; reads++; return v; } return mem[a]; }, (a, v) => { mem[a] = v; });
const rand0 = Array.from(mem.subarray(0x2264, 0x2268));
cpu.pc = 0x22A6; cpu.s = 0xFD; cpu.p = FLAGS.U | FLAGS.I; mem[0x1FE] = 0x9F; mem[0x1FF] = 0xFF;   // возврат на FFA0h
let steps = 0; while (cpu.pc !== 0xFFA0) { cpu.step(); if (++steps > 4e7) throw new Error('PLL1 не вернулась'); }
const bbcPix = (x, y) => (mem[0x6000 + (y >> 3) * 256 + (x >> 3) * 8 + (y & 7)] >> (7 - (x & 7))) & 1;

// --- Вектор: запуск без заставки до заставки игры, затем sat_draw на чистом экране
const m = createVector('elite'), L = m.L;
ok(L.sat_show >= 0xB900 && L.sat_end <= 0xBF51 && L.rom_end <= 0xB000, `код заставки лежит в рабочих областях: ${L.sat_show.toString(16)}…${(L.sat_end - 1).toString(16)} (${L.sat_end - L.sat_show} Б), игра кончается на ${(L.rom_end - 1).toString(16)}`);
m.runTo('sq_init', 5e7); m.runTo('cls_all', 5e7); m.runTo('pal_set', 5e7);        // таблица квадратов готова, экран чист
for (let a = 0xC000; a < 0x10000; a++) m.wr(a, [0]);
m.wr(L.RAND, rand0); m.wr(L.sat_t, [0]); m.wr(L.sat_c, [0]);
const r = m.call('sat_draw', {}, 6e7);
const vecPix = (x, y) => (m.rd(0xC000 + (x >> 3) * 256 + 255 - y) >> (7 - (x & 7))) & 1;
let diff = 0, first = null, dots = 0;
for (let y = 0; y < 256; y++) for (let x = 0; x < 256; x++) { const a = bbcPix(x, y), b = vecPix(x, y); dots += a; if (a !== b) { diff++; first = first || [x, y, a, b]; } }
ok(diff === 0 && dots > 1000, `Сатурн: точек на BBC ${dots}, различий с Вектором ${diff}${first ? ` (первое: x=${first[0]} y=${first[1]} BBC ${first[2]} Вектор ${first[3]})` : ''}`);
const randV = [0, 1, 2, 3].map((i) => m.rd(L.RAND + i)), randB = Array.from(mem.subarray(0x2264, 0x2268));
// на BBC после последней точки исполнение проваливается в DORND ещё раз: прежние RAND, RAND+1 уходят в RAND+2, RAND+3
ok(randV[0] === randB[2] && randV[1] === randB[3], `генератор после рисования: Вектор ${randV}, BBC (на шаг дальше) ${randB}; обращений к «таймеру» на BBC ${reads}`);
console.log(`время рисования на Векторе: ${r.cycles} тактов (${(r.cycles / 3e6).toFixed(1)} с)`);

// --- надписи
{ for (let a = 0xC000; a < 0xE000; a++) m.wr(a, [0]);
  m.call('sat_show', { tick: () => { if ((m.cpu.pc & 0xffff) === L.sat_draw) { const sp = m.cpu.sp & 0xffff; m.cpu.pc = m.rd(sp) | (m.rd(sp + 1) << 8); m.cpu.sp = (sp + 2) & 0xffff; } } }, 1e6);
  let d = 0; for (const [file, row] of [['v06c/data/sat_asoft.bin', 1], ['P.ELITE.bin', 3], ['P.(C)ASFT.bin', 22]]) { const img = fs.readFileSync(file.startsWith('v06c') ? path.join(ROOT, file) : path.join(ORIG, 'bbc/cassette/1-source-files/images', file));
    for (let c = 0; c < 32; c++) for (let k = 0; k < 8; k++) if (m.rd(0xC000 + c * 256 + 255 - (row * 8 + k)) !== img[c * 8 + k]) d++; }
  ok(d === 0, `надписи ВЕКТОР 06Ц (вместо ACORNSOFT, tools/convert/saturn.py), ELITE и строка прав стоят в строках 1, 3 и 22, как на BBC (различий ${d})`); }

// --- образ с заставкой от включения: заставка ждёт клавишу
{ const g = createVector('elite', { saturn: true });
  const title = (v) => v.rd(v.L.TYPE) === 7 && v.rd(v.L.QQ11) !== 0;
  const till = (v, max) => { let f = 0; while (f < max && !title(v)) { v.frame(5); f += 5; } return f; };
  g.frame(150); savePng(g.bmp(), path.join(ROOT, 'work/v06c/saturn.png')); g.frame(850);
  ok(!title(g), 'без клавиши заставка стоит (1000 кадров от включения)');
  g.key(7, 0x80, true); const f = till(g, 500); g.key(7, 0x80, false);
  let left = 0; for (let a = g.L.sat_show; a < g.L.sat_end; a++) if (g.rd(a) !== 0 && a >= 0xBD40) left += 0;
  const k0 = g.L.WS + 0x0900; let code = 0; for (let a = g.L.sat_asoft; a < g.L.sat_asoft + 64; a++) if (g.rd(a) === fs.readFileSync(path.join(ROOT, 'v06c/data/sat_asoft.bin'))[a - g.L.sat_asoft] && g.rd(a) !== 0) code++;
  ok(f < 100 && code === 0, `пробел: заставка игры появилась через ${f} кадров; картинки заставки в памяти не осталось; снимок work/v06c/saturn.png`);
  const g3 = createVector('elite', { saturn: true }); g3.key(7, 0x80, true); g3.frame(1000);
  ok(!title(g3), 'клавиша, зажатая с включения, заставку не сбрасывает (1000 кадров)');
  // в эмуляторе пробел — ещё и кнопка джойстика: его отпускание после съёма «покоя» само выглядит нажатием
  g3.key(7, 0x80, false); let f3 = till(g3, 20); if (!title(g3)) { g3.key(7, 0x80, true); f3 += till(g3, 500); g3.key(7, 0x80, false); }
  ok(f3 < 100, `отпустили (и нажали снова): заставка игры через ${f3} кадров`);
  let under = 0; for (const base of [0xC000, 0xE000]) for (let col = 0; col < 32; col++) for (let l = 0; l < 8; l++) if (g.rd(base + col * 256 + l)) under++;
  ok(under === 0, `под панелью (строки 248–255) после заставки чисто: ненулевых байт ${under}`); }
console.log(bad ? `ПРОВАЛ: ${bad}` : 'SATURN: всё совпало');
process.exit(bad ? 1 : 0);
