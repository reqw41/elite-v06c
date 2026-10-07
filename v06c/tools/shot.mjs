// Снимок экрана: node v06c/tools/shot.mjs [образ=elite] [кадров=60] [файл=work/v06c/<образ>.png] [кадров после нажатия пробела=0]
import path from 'node:path';
import { createVector, savePng, ROOT } from './v06c.mjs';
const name = process.argv[2] || 'elite', n = +(process.argv[3] || 60);
const out = path.resolve(process.argv[4] || path.join(ROOT, 'work/v06c', name + '.png'));
const m = createVector(name);
m.frame(n);
const after = +(process.argv[5] || 0);
if (after) { m.key(7, 0x80, true); m.frame(20); m.key(7, 0x80, false); m.frame(after); }
savePng(m.bmp(), out);
console.log(`кадров ${n}, счётчик кадров программы ${m.rd16('v_frames')} → ${out}`);
