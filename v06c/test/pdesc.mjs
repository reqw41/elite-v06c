// Расширенные описания планет: PDESC на Векторе против настоящего кода дисковой версии BBC (tools/oracle/pdesc.js).
// Для каждой из 8 × 256 систем знаки, приходящие в TT26, должны быть равны знакам, приходящим в CHPR на BBC —
// вместе с пробелами выравнивания и переводами строк. Сверх того: число вызовов DORND то же, RAND и QQ15 после
// описания прежние, в буфере не больше места, чем отведено. Плюс снимок экрана «Data on Lave» из игры.
// sh v06c/build.sh && node v06c/test/pdesc.mjs [-v]
import path from 'node:path';
import { createRequire } from 'node:module';
import { createVector, savePng, ROOT } from '../tools/v06c.mjs';
const require = createRequire(import.meta.url);
const { Disc, seeds } = require(path.join(ROOT, 'tools/oracle/pdesc.js'));
const verbose = process.argv.includes('-v');
const d = new Disc(), m = createVector('elite'), L = m.L, cpu = m.cpu;
let bad = 0, n = 0, peak = 0, maxCyc = 0, maxLen = 0, lines = 0;
const fail = (s) => { if (++bad <= 10) console.log('FAIL ' + s); };
let rs = 12345; const rnd = () => { rs = (rs * 1103515245 + 12345) >>> 0; return (rs >>> 16) & 255; };
for (let g = 0; g < 8; g++) {
  for (let s = 0; s < 256; s++, n++) {
    const want = d.describe(g, s), sd = seeds(g, s), rand = [rnd(), rnd(), rnd(), rnd()];
    let got = '', dornd = 0;
    const tick = () => {
      const pc = cpu.pc & 0xffff;
      if (pc === L.DORND) dornd++;
      const k = m.rd(L.pd_n); if (k > peak) peak = k;
      if (pc !== L.TT26R) return;
      got += String.fromCharCode(cpu.regs[7]);               // знак принят; сам TT26 не исполняется: RET, перенос 0
      const sp = cpu.sp & 0xffff; cpu.pc = m.rd(sp) | (m.rd(sp + 1) << 8); cpu.sp = (sp + 2) & 0xffff; cpu.cf = 0;
    };
    const r = m.call('PDESC', { mem: { QQ15: sd, RAND: rand, QQ17: 0x80, QQ8: [1, 0] }, tick });
    maxCyc = Math.max(maxCyc, r.cycles); maxLen = Math.max(maxLen, got.length); lines = Math.max(lines, got.split('\f').length - 1);
    if (got !== want.text) fail(`галактика ${g}, система ${s}:\n  BBC    ${JSON.stringify(want.text)}\n  Вектор ${JSON.stringify(got)}`);
    else if (dornd !== want.dornd) fail(`галактика ${g}, система ${s}: вызовов DORND ${dornd}, на BBC ${want.dornd}`);
    const after = [0, 1, 2, 3].map((i) => m.rd(L.RAND + i)), q = [0, 1, 2, 3, 4, 5].map((i) => m.rd(L.QQ15 + i));
    if (after.join() !== rand.join()) fail(`галактика ${g}, система ${s}: RAND после описания ${after}, был ${rand}`);
    if (q.join() !== sd.join()) fail(`галактика ${g}, система ${s}: QQ15 изменён`);
    if (verbose && g === 0 && s < 8) console.log(String(s).padStart(3) + ' ' + got.split('\f').slice(0, -1).join(' | '));
  }
}
// Особые описания (текущая система, QQ8 = 0): все 25 записей таблицы, без миссии и с идущей миссией 1.
{
  const RUPLA = Array.from({ length: 25 }, (_, i) => m.rd(L.pd_rupla + i)), RUGAL = Array.from({ length: 25 }, (_, i) => m.rd(L.pd_rugal + i));
  let nru = 0, special = 0;
  for (let k = 0; k < 25; k++) for (const tp of [0, 1, 2, 3]) {
    const g = RUGAL[k] & 0x7F, s = RUPLA[k], rand = [rnd(), rnd(), rnd(), rnd()], sd = seeds(g, s);
    const want = d.describe(g, s, rand, { here: true, tp });
    let got = '';
    const tick = () => { if ((cpu.pc & 0xffff) !== L.TT26R) return; got += String.fromCharCode(cpu.regs[7]);
      const sp = cpu.sp & 0xffff; cpu.pc = m.rd(sp) | (m.rd(sp + 1) << 8); cpu.sp = (sp + 2) & 0xffff; cpu.cf = 0; };
    m.call('PDESC', { mem: { QQ15: sd, RAND: rand, QQ17: 0x80, QQ8: [0, 0], GCNT: g, pd_zz: (256 - s) & 255, DTP: tp }, tick });
    nru++; if (want.text !== d.describe(g, s, rand).text) special++;
    if (got !== want.text) fail(`особое описание ${k} (галактика ${g}, система ${s}, миссия ${tp}):\n  BBC    ${JSON.stringify(want.text)}\n  Вектор ${JSON.stringify(got)}`);
    if (m.rd(L.pd_cap)) fail(`особое описание ${k}: буфер выравнивания остался включён`);
    if (tp === 1 && k === 1) console.log('пример (галактика 0, система ' + s + ', идёт миссия 1): ' + got.split('\f').slice(0, -1).join(' | '));
  }
  m.wr(L.DTP, [0]); m.wr(L.GCNT, [0]);
  console.log(`особых описаний проверено ${nru}, из них отличных от обычного ${special}`);
}
const room = L.vars_end - L.ll_sh;
if (peak > room) fail(`в буфере ${peak} знаков, отведено ${room}`);
console.log(`описаний ${n}; самое длинное ${maxLen} знаков, строк не больше ${lines}; в буфере не больше ${peak} из ${room}; дольше всего ${maxCyc} тактов (${(maxCyc / 3e6).toFixed(2)} с без печати)`);

// В игре: новый командир на Лейве, СС+F2 — данные о системе. Строки описания на экране — по строке текста на знакоместо.
{
  const g = createVector('elite');
  const KEY = { SPACE: [7, 0x80], N: [5, 0x40], F2: [1, 0x10] };
  const press = (k, ss = false) => { g.keyboard.ss = ss; g.key(KEY[k][0], KEY[k][1], true); g.frame(20); g.key(KEY[k][0], KEY[k][1], false); g.keyboard.ss = false; };
  g.frame(300); press('N'); g.frame(200); press('SPACE'); g.frame(200); press('F2', true); g.frame(200);
  const out = path.join(ROOT, 'work/v06c/pdesc-lave.png');
  savePng(g.bmp(), out);
  // печать знака — исключающим ИЛИ шрифта в плоскость обзора: строка текста row, столбец col
  const font = (ch) => Array.from({ length: 8 }, (_, i) => g.rd(L.font + (ch - 32) * 8 + i));
  const cell = (col, row) => Array.from({ length: 8 }, (_, i) => g.rd(0xC000 + col * 256 + 255 - (row * 8 + i)));
  const want = d.describe(0, 7).text.split('\f').slice(0, -1);
  let row = -1;
  for (let y = 0; y < 24 && row < 0; y++) if ([...want[0]].every((c, i) => cell(1 + i, y).join() === font(c.charCodeAt(0)).join())) row = y;
  if (row < 0) fail('в игре: первая строка описания Лейва на экране не найдена');
  else want.forEach((t, k) => { if (![...t].every((c, i) => cell(1 + i, row + k).join() === font(c.charCodeAt(0)).join())) fail(`в игре: строка ${k} описания Лейва на экране не та`); });
  console.log(`в игре: описание Лейва — со строки ${row}, строк ${want.length}; снимок ${path.relative(ROOT, out)}`);
}
// Самое длинное описание должно помещаться на экране: TT25 для системы с шестью строками, YC в конце не больше 24.
{
  let pick = null;
  for (let g = 0; g < 8 && !pick; g++) for (let s = 0; s < 256 && !pick; s++) if (d.describe(g, s).text.split('\f').length - 1 === lines) pick = [g, s];
  const g = createVector('elite'); g.frame(300);
  const seen = [];                                            // очистки экрана: одна — в начале TT25
  const tick = () => { if ((g.cpu.pc & 0xffff) === g.L.TTX66) seen.push(1); };
  g.call('TT25', { mem: { QQ15: seeds(pick[0], pick[1]), QQ8: [10, 0] }, tick }, 2e7);
  const yc = g.rd(g.L.YC);
  g.frame(2); savePng(g.bmp(), path.join(ROOT, 'work/v06c/pdesc-long.png'));
  if (seen.length !== 1 || yc > 24) fail(`длинное описание (галактика ${pick[0]}, система ${pick[1]}) не поместилось: YC = ${yc}, очисток экрана ${seen.length}`);
  console.log(`самое длинное описание (галактика ${pick[0]}, система ${pick[1]}, строк ${lines}): YC в конце ${yc}; снимок work/v06c/pdesc-long.png`);
}
console.log(bad ? `ПРОВАЛ: ${bad}` : 'PDESC: всё совпало');
process.exit(bad ? 1 : 0);
