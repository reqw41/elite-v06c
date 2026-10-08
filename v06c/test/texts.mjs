// Свои тексты (миссии версии ZX, сообщения, подсказки) лежат во второй таблице словаря v06c/data/tkn1.asm и
// печатаются тем же кодом, что описания планет. Проверка: каждый текст на выходе TT26 равен исходной строке из
// tools/convert/tkn1.py (в комментариях tkn1.asm) — при любом состоянии печати, оставшемся от прежнего текста.
// sh v06c/build.sh && node v06c/test/texts.mjs
import fs from 'node:fs';
import path from 'node:path';
import { createVector, ROOT } from '../tools/v06c.mjs';
const m = createVector('elite'), L = m.L, cpu = m.cpu; m.frame(60);
const src = fs.readFileSync(path.join(ROOT, 'v06c/data/tkn1.asm'), 'utf8');
const texts = [...src.slice(src.indexOf('mz_tkn:')).matchAll(/^; (\d+): (.*)$/gm)].map((x) => [+x[1], x[2]]);
const names = Object.fromEntries([...src.matchAll(/^MZ_(\w+)\s+equ\s+(\d+)/gm)].map((x) => [+x[2], x[1]]));
const ret = () => { const sp = cpu.sp & 0xffff; cpu.pc = m.rd(sp) | (m.rd(sp + 1) << 8); cpu.sp = (sp + 2) & 0xffff; };
let bad = 0, chars = 0;
for (const state of [{ pd_w1: 0x20, pd_w6: 0x80, pd_w2: 0, pd_w8: 0xFF }, { pd_w1: 0, pd_w6: 0, pd_w2: 0xFF, pd_w8: 0xDF }]) for (const [n, text] of texts) {
  const mil = text.startsWith('{2}{19}');
  const want = text.replace(/^\{1\}|^\{2\}\{19\}/, '').replace(/\{10\}/g, '\n').replace(/\{11\}/g, '<система>');
  const exp = mil ? want.toLowerCase().replace(/(^|\s)([a-z])/g, (q, a, b) => a + b.toUpperCase()) : want;
  let got = '';
  const tick = () => { for (;;) { const pc = cpu.pc & 0xffff;
    if (pc === L.TT26R) { got += String.fromCharCode(cpu.regs[7]); cpu.cf = 0; ret(); }
    else if (pc === L.mz_nl) { got += '\n'; ret(); }
    else if (pc === L.mz_name) { got += '<система>'; ret(); }
    else return; } };
  m.call('mz_str', { a: n, mem: { ...state, pd_cap: 0, QQ17: 0 }, tick }, 2e6);
  chars += got.length;
  if (got !== exp) { bad++; console.log(`FAIL ${names[n]}: ждали ${JSON.stringify(exp)}, вышло ${JSON.stringify(got)}`); }
}
console.log(`текстов ${texts.length} × 2 состояния печати, знаков ${chars}`);
console.log(bad ? `ПРОВАЛ: ${bad}` : 'TEXTS: всё совпало');
process.exit(bad ? 1 : 0);
