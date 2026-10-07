// T14: текст из словаря (TT27) — парные тесты 6502 ↔ i8080. node v06c/test/t14.mjs [случаев = 3000]
import fs from 'node:fs';
import path from 'node:path';
import { makePair } from '../tools/pair.mjs';
import { ROOT } from '../tools/v06c.mjs';
const N = +(process.argv[2] || 3000);
const P = makePair(), { B, bbc } = P;
bbc.mem.set(fs.readFileSync(path.join(ROOT, 'v06c/data/font.bin')), 0xC000);     // эталон печатает нашим шрифтом
// Слова, в которых встречаются деньги, названия систем и т. п. (знаки 0–5) и гудок (7), на i8080 — заглушки:
// такие слова в тест не идут. Разбор слова — как в TT27.
const words = []; { let a = 0x400; for (let i = 0; i < 148; i++) { const w = []; while (bbc.mem[a]) w.push(bbc.mem[a++] ^ 0x23); a++; words.push(w); } }
const memo = new Map();
const safe = (t, depth = 0) => {
  if (depth > 8) return false;
  if (t < 6 || t === 7) return false;
  if (t === 6 || t === 8 || t === 9) return true;
  if (t >= 128 && t < 160) return true;
  let w = -1; if (t >= 160) w = t - 160; else if (t >= 96) w = t; else if (t >= 14 && t < 32) w = t + 114;
  if (w < 0) return true;
  if (w >= words.length) return false;
  if (!memo.has(w)) { memo.set(w, false); memo.set(w, words[w].every((c) => safe(c, depth + 1))); }
  return memo.get(w);
};
const all = []; for (let t = 0; t < 256; t++) if (safe(t)) all.push(t);
const TEXT = ['YSAV2', 'XSAV2', ['P', 3], 'SC', 'SCH', ['V', 2]];        // рабочие ячейки печати на BBC
const tok = (r) => (r(3) ? all[r(all.length)] : 32 + r(64));
const SPECS = [
  { name: 'TT27', gen: (r) => ({ a: tok(r), mem: { XC: r(22), YC: r(18), QQ17: [0, 0x80, 0xC0, 0x40, 0x80, 0, 255][r(7)] } }) },
  { name: 'ex', gen: (r) => { let w; do w = r(148); while (!safe(160 + w > 255 ? 96 : 160 + w) && !(w >= 96 && safe(w))); if (w > 95 && !safe(w)) w = 20; return { a: w <= 95 ? (safe(160 + w) ? w : 20) : w, mem: { XC: r(10), YC: r(18), QQ17: [0, 0x80, 0xC0][r(3)] } }; } },
  { name: 'plf', gen: (r) => ({ a: tok(r), mem: { XC: r(22), YC: r(18), QQ17: [0, 0x80][r(2)] } }) },
  { name: 'TT67', gen: (r) => ({ mem: { XC: r(22), YC: r(18), QQ17: [0, 0x80, 0xC0, 255][r(4)] } }) },
  { name: 'TT162', gen: (r) => ({ mem: { XC: r(22), YC: r(18), QQ17: [0, 0x80, 0xC0, 255][r(4)] } }) },
  { name: 'TT73', gen: (r) => ({ mem: { XC: r(22), YC: r(18), QQ17: [0, 0x80, 0xC0, 255][r(4)] } }) },
];
console.log(`слов и знаков, годных для теста: ${all.length} из 256`);
for (const s of SPECS) P.run({ n: N, noreg: 'axyc', skip: TEXT, screen: 'view', ...s });
P.timing();
console.log(P.failed() ? `ПРОВАЛ: ${P.failed()}` : 'T14: всё совпало');
process.exit(P.failed() ? 1 : 0);
