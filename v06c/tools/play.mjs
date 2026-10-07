// Сыграть образ по списку шагов и снять кадр: node v06c/tools/play.mjs <файл.png> [образ=elite] шаг ...
// Шаг: число — столько кадров; имя клавиши (SPACE, N, F1…) — нажать на 20 кадров и отпустить.
import path from 'node:path';
import { createVector, savePng } from './v06c.mjs';
const KEYS = { SPACE: [7, 0x80], N: [5, 0x40], Y: [7, 0x02], F1: [1, 0x08], F2: [1, 0x10], F3: [1, 0x20], F4: [1, 0x40], F5: [1, 0x80], A: [4, 0x02], S: [6, 0x08], X: [7, 0x01] };
const [out, ...rest] = process.argv.slice(2);
const m = createVector(KEYS[rest[0]] || /^\d+$/.test(rest[0]) ? 'elite' : rest.shift());
for (const s of rest) {
  if (/^\d+$/.test(s)) m.frame(+s);
  else { const k = KEYS[s]; if (!k) throw new Error('нет клавиши ' + s); m.key(k[0], k[1], true); m.frame(20); m.key(k[0], k[1], false); }
}
savePng(m.bmp(), path.resolve(out));
console.log(`кадров ${m.frames} → ${out}`);
