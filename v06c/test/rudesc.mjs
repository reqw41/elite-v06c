// Русская сборка (elite_ru.rom): описания всех 8 × 256 систем и 25 особых — знаки, приходящие в TT26R:
// только русские буквы (96–126), латиница (названия систем), цифры и знаки; буфер выравнивания не переполнен;
// RAND и QQ15 после описания прежние, буфер выключен; на экране описание не длиннее 24 строки текста
// (YC в конце). Плюс выгрузка примеров. sh v06c/build.sh -DRUS && node v06c/test/rudesc.mjs [-v]
import path from 'node:path';
import { createRequire } from 'node:module';
import { createVector, ROOT } from '../tools/v06c.mjs';
const require = createRequire(import.meta.url);
const { seeds } = require(path.join(ROOT, 'tools/oracle/pdesc.js'));
const verbose = process.argv.includes('-v');
const m = createVector('elite_ru'), L = m.L, cpu = m.cpu;
const KOI7 = 'ЮАБЦДЕФГХИЙКЛМНОПЯРСТУЖВЬЫЗШЭЩЧ';
const show = (s) => [...s].map((c) => { const k = c.charCodeAt(0); return k >= 96 && k < 127 ? KOI7[k - 96] : k === 12 ? ' | ' : c; }).join('');
let bad = 0, n = 0, peak = 0, maxLen = 0, maxLines = 0;
const fail = (s) => { if (++bad <= 10) console.log('FAIL ' + s); };
let rs = 777; const rnd = () => { rs = (rs * 1103515245 + 12345) >>> 0; return (rs >>> 16) & 255; };
const room = L.vars_end - L.ll_sh;
const okChar = (k) => k === 12 || (k >= 32 && k <= 63) || (k >= 65 && k <= 90) || (k >= 96 && k <= 126);
const one = (mem, what) => {
  let got = '';
  const tick = () => {
    const pc = cpu.pc & 0xffff, k = m.rd(L.pd_n);
    if (k > peak) peak = k;
    if (pc !== L.TT26R) return;
    got += String.fromCharCode(cpu.regs[7]);
    const sp = cpu.sp & 0xffff; cpu.pc = m.rd(sp) | (m.rd(sp + 1) << 8); cpu.sp = (sp + 2) & 0xffff; cpu.cf = 0;
  };
  const rand = [rnd(), rnd(), rnd(), rnd()];
  m.call('PDESC', { mem: { RAND: rand, QQ17: 0x80, ...mem }, tick });
  n++;
  const bad1 = [...got].find((c) => !okChar(c.charCodeAt(0)));
  if (bad1 !== undefined) fail(`${what}: знак ${bad1.charCodeAt(0)} в «${show(got)}»`);
  if ([0, 1, 2, 3].map((i) => m.rd(L.RAND + i)).join() !== rand.join()) fail(`${what}: RAND изменён`);
  if (m.rd(L.pd_cap)) fail(`${what}: буфер выравнивания остался включён`);
  const lines = got.split('\f').length - 1;
  maxLen = Math.max(maxLen, got.length); maxLines = Math.max(maxLines, lines);
  return got;
};
for (let g = 0; g < 8; g++) for (let s = 0; s < 256; s++) {
  const sd = seeds(g, s), got = one({ QQ15: sd, QQ8: [1, 0] }, `галактика ${g}, система ${s}`);
  if ([0, 1, 2, 3, 4, 5].map((i) => m.rd(L.QQ15 + i)).join() !== sd.join()) fail(`галактика ${g}, система ${s}: QQ15 изменён`);
  if (verbose && g === 0 && (s < 8 || process.env.SYS === 'all' || process.env.SYS == s)) console.log(String(s).padStart(3) + ' ' + show(got));
}
const RUPLA = Array.from({ length: 25 }, (_, i) => m.rd(L.pd_rupla + i)), RUGAL = Array.from({ length: 25 }, (_, i) => m.rd(L.pd_rugal + i));
for (let k = 0; k < 25; k++) for (const tp of [0, 1, 2, 3]) {
  const g = RUGAL[k] & 0x7F, s = RUPLA[k];
  const got = one({ QQ15: seeds(g, s), QQ8: [0, 0], GCNT: g, pd_zz: (256 - s) & 255, DTP: tp }, `особое ${k}, миссия ${tp}`);
  if (verbose && tp === 1) console.log('особое ' + k + ': ' + show(got));
}
if (peak > room) fail(`в буфере ${peak} знаков, отведено ${room}`);
// строк текста на экране: описание начинается не выше строки 11 экрана данных — значит, не больше 13 строк
if (maxLines > 13) fail(`описание в ${maxLines} строк — не помещается на экран данных`);
console.log(`описаний ${n}; самое длинное ${maxLen} знаков, строк не больше ${maxLines}; в буфере не больше ${peak} из ${room}`);
console.log(bad ? `ПРОВАЛ: ${bad}` : 'RUDESC: всё в порядке');
process.exit(bad ? 1 : 0);
