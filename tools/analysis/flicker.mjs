// Мерцание: что луч на самом деле показал в каждом кадре, против готовых картинок прохода. Сцена elite_sun: вылет,
// пауза, M, ЗБ (как на железе); игрок неуязвим. Готовая картинка S_p — память экрана в начале прохода p (TT100).
// Для каждого байта, прочитанного лучом во время прохода p, сравнение с S_p и S_{p+1}:
//   пропало — точка есть и в S_p, и в S_{p+1} (стоит на месте), а луч её не показал;
//   лишнее  — точки нет ни в S_p, ни в S_{p+1}, а луч её показал (промежуточное состояние);
//   сдвиг   — точка только в S_p или только в S_{p+1} (движется): сколько из них луч не показал ни в каком виде.
// Виновник: для каждой точки «пропало» — метка кода, который последним писал этот байт перед показом.
// node tools/analysis/flicker.mjs [секунд = 20] [папка для снимков]; IMG=образ (elite_sun), FRAMES=n — снимки n кадров
import fs from 'node:fs';
import { createVector, savePng } from '../../v06c/tools/v06c.mjs';
const SEC = +(process.argv[2] || 20), OUT = process.argv[3];
const g = createVector(process.env.IMG || 'elite_sun'), L = g.L, cpu = g.cpu;
const K = { SPACE: [7, 0x80], N: [5, 0x40], F1: [1, 0x08], STR: [1, 0x02], M: [5, 0x20], ZB: [0, 0x08] };
const press = (k, n = 20) => { g.key(K[k][0], K[k][1], true); g.frame(n); g.key(K[k][0], K[k][1], false); g.frame(10); };
g.frame(300); press('N'); g.frame(200); press('SPACE'); g.frame(200); press('F1'); g.frame(600);
press('STR'); g.frame(20); press('M'); g.frame(20); press('ZB'); g.frame(50);
// метки по адресу: ближайшая снизу
const labs = Object.entries(L).filter(([n, a]) => a >= 0x100 && a < 0xC000 && !/^\./.test(n)).sort((a, b) => a[1] - b[1]);
const labAt = (pc) => { let lo = 0, hi = labs.length - 1; while (lo < hi) { const m = (lo + hi + 1) >> 1; if (labs[m][1] <= pc) lo = m; else hi = m - 1; } return labs[lo][0]; };
const snap = () => { const s = new Uint8Array(0x4000); for (let i = 0; i < 0x4000; i++) s[i] = g.rd(0xC000 + i); return s; };   // C000–FFFF: обе плоскости
const shots = [snap()];   // S_p
let pass = 0;
const writer = new Int32Array(0x4000).fill(-1);   // последний писавший байт экрана (pc)
const mem = g.memory, wr0 = mem.write.bind(mem);
mem.write = (a, v, ...r) => { if (a >= 0xC000) writer[a - 0xC000] = curPc; return wr0(a, v, ...r); };
let curPc = 0;
const ins = cpu.instruction.bind(cpu);
cpu.instruction = () => { const pc = cpu.pc & 0xffff; curPc = pc;
  if (pc === L.TT100) { pass++; shots.push(snap()); for (const v of ['ENERGY', 'FSH', 'ASH']) g.wr(L[v], [255]); }
  return ins(); };
// луч: каждый прочитанный байт (столбец, строка) — значения плоскостей C000 и E000, проход, виновник
const fl = g.v06c.filler, fetch0 = fl.fetchPixels.bind(fl);
let frame = [];
fl.fetchPixels = function () { fetch0(); const addr = ((this.fb_column & 0xff) << 8) | (this.fb_row & 0xff), p = this.pixel32;
  frame.push(addr, (p >>> 16) & 255, (p >>> 24) & 255, pass, writer[addr], writer[0x2000 + addr]); };
const frames = [];
for (let f = 0; f < SEC * 50; f++) { frame = []; g.frame(1); frames.push(frame); }
shots.push(snap());
const pc8 = (x) => { x -= (x >> 1) & 0x55; x = (x & 0x33) + ((x >> 2) & 0x33); return (x + (x >> 4)) & 15; };
const who = new Map(); const add = (pc, n) => { if (pc < 0 || !n) return; const l = labAt(pc); who.set(l, (who.get(l) || 0) + n); };
const pres = []; let lost = 0, extra = 0, movT = 0, movLost = 0, steadyT = 0, worst = [];
frames.forEach((fr, fi) => { if (fi < +(process.env.SKIP || 0)) return;
  let fLost = 0, fExtra = 0, oT = 0, oS = 0, nT = 0, nS = 0;
  for (let i = 0; i < fr.length; i += 6) {
    const a = fr[i], p = fr[i + 3]; if (p < 1 || p + 1 >= shots.length) continue;
    const A = shots[p], B = shots[p + 1];
    for (const [d, off, wpc] of [[fr[i + 1], 0, fr[i + 4]], [fr[i + 2], 0x2000, fr[i + 5]]]) {
      const s0 = A[off + a], s1 = B[off + a], st = s0 & s1, mov = s0 ^ s1;
      const l = st & ~d & 255, e = ~(s0 | s1) & d & 255, ml = mov & ~d & ~(s0 & d) & ~(s1 & d);
      steadyT += pc8(st); movT += pc8(mov);
      fLost += pc8(l); fExtra += pc8(e); movLost += pc8(mov & ~d);
      add(wpc, pc8(l)); const oo = off ? 0 : s0 & ~s1 & 255, nn = off ? 0 : s1 & ~s0 & 255; oT += pc8(oo); oS += pc8(oo & d); nT += pc8(nn); nS += pc8(nn & d);
    }
  }
  lost += fLost; extra += fExtra; worst.push([fLost + fExtra, fi]);
  if (oT + nT > 20) { const pr = (oS + nS) / Math.max(oT, nT); pres.push(pr); if (process.env.BYPRES) worst[worst.length - 1][0] = 1 - pr; }
});
const nf = frames.length;
console.log(`кадров ${nf}, проходов ${pass} (${(pass / SEC).toFixed(2)} в секунду)`);
console.log(`на кадр: стоящих точек ${(steadyT / nf).toFixed(0)}, из них пропало ${(lost / nf).toFixed(1)}; лишних ${(extra / nf).toFixed(1)}; движущихся ${(movT / nf).toFixed(0)}, не показано ни в каком виде ${(movLost / nf).toFixed(1)}`);
pres.sort((a, b) => a - b); const q = (f) => pres[Math.floor(f * (pres.length - 1))].toFixed(2);
console.log(`движущееся в плоскости линий: видно (старое + новое) / большее из них по кадрам: мин ${q(0)}, 5% ${q(0.05)}, 25% ${q(0.25)}, медиана ${q(0.5)}; кадров ниже 0.7 — ${pres.filter((v) => v < 0.7).length} из ${pres.length}`);
console.log('пропавшие стоящие точки — кто стёр (доля):');
const tot = [...who.values()].reduce((s, v) => s + v, 0) || 1;
[...who.entries()].sort((a, b) => b[1] - a[1]).slice(0, 15).forEach(([n, v]) => console.log(`  ${(v / tot * 100).toFixed(1).padStart(5)}%  ${n}`));
if (OUT) {   // снимки худших кадров: белое — показано и стоит, красное — пропало, синее — лишнее, жёлтое — движется
  fs.mkdirSync(OUT, { recursive: true });
  worst.sort((a, b) => b[0] - a[0]).slice(0, +(process.env.FRAMES || 4)).forEach(([n, fi]) => {
    const fr = frames[fi], bmp = new Uint32Array(576 * 288);
    for (let i = 0; i < fr.length; i += 6) { const a = fr[i], p = fr[i + 3]; if (p < 1 || p + 1 >= shots.length) continue;
      const col = a >> 8, row = a & 255; if (row < 64) continue; const y = 255 - row;
      for (let b = 0; b < 8; b++) { const m = 0x80 >> b; let c = 0;
        for (const [d, off] of [[fr[i + 1], 0], [fr[i + 2], 0x2000]]) { const s0 = shots[p][off + a] & m, s1 = shots[p + 1][off + a] & m, v = d & m;
          if (s0 && s1) c = v ? (c || 0x808080) : 0x0000FF; else if (!s0 && !s1) { if (v) c = 0xFF0000; } else if (!c) c = v ? 0x00C0C0 : 0x003060; }
        const x = col * 8 + b; bmp[(y + 48) * 576 + x * 2 + 32] = c; bmp[(y + 48) * 576 + x * 2 + 33] = c; } }
    savePng(bmp, `${OUT}/f${fi}.png`); console.log(`снимок f${fi}: пропало+лишнее ${n}`); });
}
if (process.env.DUMP && OUT) {   // DUMP=кадр: готовые картинки прохода до и после этого кадра (плоскость линий)
  const fi = +process.env.DUMP, p = frames[fi][3];
  for (const [nm, sh] of [['before', shots[p]], ['after', shots[p + 1]]]) { const bmp = new Uint32Array(576 * 288);
    for (let a = 0; a < 0x2000; a++) { const row = a & 255; if (row < 64) continue; const y = 255 - row, col = a >> 8;
      for (let b = 0; b < 8; b++) if (sh[a] & (0x80 >> b)) { const x = col * 8 + b; bmp[(y + 48) * 576 + x * 2 + 32] = 0xFFFFFF; bmp[(y + 48) * 576 + x * 2 + 33] = 0xFFFFFF; } }
    savePng(bmp, `${OUT}/p${p}_${nm}.png`); }
  console.log(`проход ${p}: p${p}_before.png, p${p}_after.png`);
}
