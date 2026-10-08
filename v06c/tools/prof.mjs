// Профиль обычного образа в настоящих кадрах (с прерываниями и ожиданием кадра): такты по меткам и по файлам
// исходника. Сцена: взлёт, клавиши не нажаты (как замер ZX 48K в docs/research/versions.md), после разворота от планеты
// (SCENE=space) или там же с тремя кораблями перед игроком (Sidewinder, Mamba, Krait; выбывшие заменяются), игрок неуязвим (SCENE=fight);
// FOUR=1 — четыре корабля, два Sidewinder и два Krait, как стая в замере ZX 48K (tools/analysis/zx48_run.mjs). node v06c/tools/prof.mjs [кадров = 1500] [сколько строк = 45]
import fs from 'node:fs'; import path from 'node:path';
import { createVector, ROOT } from './v06c.mjs';
const FR = +(process.argv[2] || 1500), TOP = +(process.argv[3] || 45), IMG = process.env.IMG || 'elite';
const g = createVector(IMG), L = g.L, cpu = g.cpu;
const K = { SPACE: [7, 0x80], N: [5, 0x40], F1: [1, 0x08], S: [6, 0x08] };
const press = (k) => { g.key(K[k][0], K[k][1], true); g.frame(20); g.key(K[k][0], K[k][1], false); };
g.frame(300); press('N'); g.frame(200); press('SPACE'); g.frame(200); press('F1'); g.frame(300);
if (process.env.SCENE === 'space' || process.env.SCENE === 'fight') { g.key(6, 8, true); for (let i = 0; i < 400 && !(g.rd(L.K_ + 8) & 0x80); i++) g.frame(5); g.key(6, 8, false); g.frame(100); }
if (process.env.DUST) g.wr(L.NOSTM, [+process.env.DUST]);   // опыт: меньше пылинок (лишние остаются на экране)
const prof = new Float64Array(0x10000); let on = false;
const orig = cpu.instruction.bind(cpu);
let tt = 0;
cpu.instruction = () => { const pc = cpu.pc & 0xffff, r = orig(); if (on) { prof[pc] += cpu.vcycles | 0; if (pc === L.TT100) tt++; } return r; };
if (process.env.ROLL) g.key(3, 0x10, true);   // держать крен: короткие пути «полёт прямо» не работают
let loops = 0, mc = g.rd(L.MCNT); on = true;
const FIGHT = process.env.SCENE === 'fight'; let shipsSum = 0, polls = 0;
for (let f = 0; f < FR; f += 5) { g.frame(5);
  if (FIGHT) { for (const v of ['ENERGY', 'FSH', 'ASH']) g.wr(L[v], [255]);
    if (f % 250 === 0) { let n = 0; for (let i = 2; i < 13; i++) { const t = g.rd(L.FRIN + i); if (t && t < 128) n++; }
      for (const t of (process.env.FOUR ? [1, 14, 1, 14] : [1, 3, 14]).slice(n)) { g.call('ZINF'); g.wr(L.INWK + 7, [2]); g.wr(L.INWK + 1, [t * 9]); g.call('NWSHP', { a: t }); } } }
  { let n = 0; for (let i = 2; i < 13; i++) { const t = g.rd(L.FRIN + i); if (t && t < 128) n++; } shipsSum += n; polls++; }
  const m = g.rd(L.MCNT); loops += (mc - m) & 255; mc = m; }
on = false; loops = tt;
console.log(`кораблей в среднем ${(shipsSum / polls).toFixed(1)}`);
const labs = Object.entries(L).filter(([n, a]) => a >= 0x100 && a < 0xB000 && typeof a === 'number').sort((a, b) => a[1] - b[1]);
const big = labs.filter(([n]) => /^[A-Z]/.test(n) || /^(sun_|sat_|div_|cls_|pal_|mis_|nb_|ds_|zx_|dk_|pd_|joy_|snd_|kb_|irq|isr|wait|vs)/.test(n));
const acc = (list) => { const cost = {}; let k = 0, total = 0;
  for (let a = 0x100; a < 0x10000; a++) { if (!prof[a]) continue; while (k + 1 < list.length && list[k + 1][1] <= a) k++; const n = a < list[0][1] ? '?' : list[k][0]; cost[n] = (cost[n] || 0) + prof[a]; total += prof[a]; }
  return [cost, total]; };
const [cost, total] = acc(labs);
console.log(`${IMG}, сцена ${process.env.SCENE || 'launch'}: кадров ${FR}, проходов ${loops} (${(loops / (FR / 50)).toFixed(2)} в секунду), тактов на проход ${(total / loops).toFixed(0)} (${(total / loops / 3e6 * 1000).toFixed(1)} мс)`);
// по файлам: из листинга sjasmplus
const lst = path.join(ROOT, 'v06c/build', IMG + '.lst');
if (fs.existsSync(lst)) { const byFile = {}; let file = '?'; const fileOf = new Map();
  // грубо: файл метки ищем по исходникам
  for (const f of fs.readdirSync(path.join(ROOT, 'v06c/src')).filter((x) => x.endsWith('.asm'))) for (const l of fs.readFileSync(path.join(ROOT, 'v06c/src', f), 'utf8').split('\n')) { const m = /^([A-Za-z_][A-Za-z0-9_]*):/.exec(l); if (m && !fileOf.has(m[1])) fileOf.set(m[1], f); }
  for (const [n, c] of Object.entries(cost)) { const f = fileOf.get(n) || '?'; byFile[f] = (byFile[f] || 0) + c; }
  console.log('по файлам: ' + Object.entries(byFile).sort((a, b) => b[1] - a[1]).slice(0, 14).map(([f, c]) => `${f.replace('.asm', '')} ${(c / total * 100).toFixed(1)}%`).join(', ')); }
const [cb] = acc(big);
if (process.env.ALL) { console.log('по всем меткам:'); Object.entries(cost).sort((a, b) => b[1] - a[1]).slice(0, TOP).forEach(([n, c]) => console.log(`  ${(c / total * 100).toFixed(1).padStart(5)}%  ${(c / loops).toFixed(0).padStart(7)} т/проход  ${n}`)); }
console.log('по крупным меткам:'); Object.entries(cb).sort((a, b) => b[1] - a[1]).slice(0, TOP).forEach(([n, c]) => console.log(`  ${(c / total * 100).toFixed(1).padStart(5)}%  ${(c / loops).toFixed(0).padStart(7)} т/проход  ${n}`));
