// Окружность планеты точками (pcirc, обычный образ): точки против расчёта тем же алгоритмом средней точки на JS,
// с отсечением по обзору; повторное рисование стирает всё; память вне плоскости обзора (панель, вторая плоскость,
// рабочие области) не меняется. Плюс логика PLANET: та же окружность не перерисовывается, смена — без остатка.
// sh v06c/build.sh && node v06c/test/pcirc.mjs
import { createVector } from '../tools/v06c.mjs';
let bad = 0; const fail = (s) => { if (++bad <= 10) console.log('FAIL ' + s); };
const m = createVector('elite'), L = m.L; m.frame(60);
const VIEW = 0xC000;
const clear = () => { for (let a = VIEW; a < VIEW + 0x2000; a++) if ((a & 255) >= 64) m.wr(a, [0]); };
const pixels = () => { const s = new Set(); for (let col = 0; col < 32; col++) for (let y = 0; y < 192; y++) { const v = m.rd(VIEW + col * 256 + 255 - y); if (v) for (let b = 0; b < 8; b++) if ((v >> (7 - b)) & 1) s.add((col * 8 + b) + y * 256); } return s; };
const ref = (X, Y, r) => { const s = new Set(), p = (x, y) => { if (x < 0 || x > 255 || y < 0 || y > 191) return; const k = x + y * 256; if (s.has(k)) s.delete(k); else s.add(k); };
  let x = 0, y = r, d = 1 - r; p(X, Y + r); p(X, Y - r); p(X + r, Y); p(X - r, Y);
  for (;;) { x++; if (d < 0) d += 2 * x + 1; else { y--; d += 2 * x - 2 * y + 1; } if (x > y) break;
    p(X + x, Y + y); p(X + x, Y - y); p(X - x, Y + y); p(X - x, Y - y); if (x === y) break; p(X + y, Y + x); p(X + y, Y - x); p(X - y, Y + x); p(X - y, Y - x); } return s; };
const snap = () => { const o = new Uint8Array(0x10000); for (let a = 0; a < 0x10000; a++) o[a] = m.rd(a); return o; };
let rs = 777; const rnd = (n) => { rs = (rs * 1103515245 + 12345) >>> 0; return (rs >>> 8) % n; };
let n = 0, maxCyc = 0, sumCyc = 0, sumPx = 0, inside = 0, inCyc = 0, inPx = 0;
const codeLo = L.pc_try, codeHi = L.pc_m4 + 1;
for (let i = 0; i < 1500; i++) {
  const r = 2 + rnd(126), Y = i < 300 ? r + rnd(Math.max(1, 192 - 2 * r)) : -64 + r + rnd(Math.max(1, 255 - r - (-64 + r) + 1)), X = i < 300 ? Math.min(255 - r, r + rnd(Math.max(1, 256 - 2 * r))) : -300 + rnd(860);
  if (Y + r > 255 || Y - r < -64 || X - r < -512) continue;
  clear(); const before = snap();
  m.wr(L.pc_n, [X & 255, (X >> 8) & 255, Y & 255, r]);
  const c = m.call('pcirc', { h: L.pc_n >> 8, l: L.pc_n & 255 }, 2e6);
  const got = pixels(), want = ref(X, Y, r); n++;
  if (got.size !== want.size || [...want].some((k) => !got.has(k))) fail(`X ${X}, Y ${Y}, r ${r}: точек ${got.size}, по расчёту ${want.size}`);
  const after = snap();
  for (let a = 0; a < 0x10000; a++) if (after[a] !== before[a] && !(a >= VIEW && a < VIEW + 0x2000 && (a & 255) >= 64) && !(a >= codeLo && a < codeHi) && a >= 0x100 && !(a >= ((m.cpu.sp - 16) & 0xffff) && a <= (m.cpu.sp & 0xffff))) { fail(`X ${X}, Y ${Y}, r ${r}: изменён байт ${a.toString(16)}`); break; }
  if (want.size) { maxCyc = Math.max(maxCyc, c.cycles); sumCyc += c.cycles; sumPx += want.size; }
  if (X - r >= 0 && X + r <= 255 && Y - r >= 0 && Y + r <= 191) { inside++; inCyc += c.cycles; inPx += want.size; }
  m.call('pcirc', { h: L.pc_n >> 8, l: L.pc_n & 255 }, 2e6);
  if (pixels().size) fail(`X ${X}, Y ${Y}, r ${r}: повтор не стёр окружность`);
}
console.log(`окружностей ${n}, из них целиком в обзоре ${inside}; тактов на точку: целиком в обзоре ${(inCyc / inPx).toFixed(0)}, по всем ${(sumCyc / sumPx).toFixed(0)}; самая долгая ${maxCyc} тактов (${(maxCyc / 3000).toFixed(1)} мс)`);
// PLANET: планета перед нами; та же окружность — без перерисовки; сдвиг — прежняя стёрта
{ clear(); m.wr(L.LSX2, [0xFF]); m.wr(L.LSP, [1]);
  const planet = (zs, x, zh = 0) => m.call('PLANET', { mem: { TYPE: 128, INWK: [0, x, 0, 0, 0, 0, 0, zh, zs] } }, 5e6);   // радиус 24576 / (zs·256 + zh)
  const c1 = planet(2, 0); const p1 = pixels();
  if (m.rd(L.LSX2) !== 1 || !p1.size) fail(`PLANET: быстрая окружность не нарисована (LSX2 ${m.rd(L.LSX2)}, точек ${p1.size})`);
  const c2 = planet(2, 0); const p2 = pixels();
  if (p2.size !== p1.size || c2.cycles > c1.cycles / 4) fail(`PLANET: та же окружность перерисована (${c1.cycles} → ${c2.cycles} тактов)`);
  planet(2, 1); const p3 = pixels(), w = ref(m.rd16(L.pc_s) << 16 >> 16, m.rd(L.pc_s + 2), m.rd(L.pc_s + 3));
  if (p3.size !== w.size || [...w].some((k) => !p3.has(k))) fail(`PLANET: после сдвига на экране ${p3.size} точек, по расчёту ${w.size}`);
  planet(0x82, 0);              // планета позади
  if (pixels().size || m.rd(L.LSX2) !== 0xFF) fail(`PLANET: ушедшая планета не стёрта (точек ${pixels().size})`);
  planet(47, 0); const far = pixels().size; planet(0, 0, 0x80); const near = pixels(); if (m.rd(L.LSX2) !== 0) fail('PLANET: радиус 192 нарисован не отрезками');                 // близко: радиус от 128 — прежний путь
  planet(2, 0); const back = pixels(), wb = ref(m.rd16(L.pc_s), m.rd(L.pc_s + 2), m.rd(L.pc_s + 3));
  if (back.size !== wb.size || [...wb].some((k) => !back.has(k))) fail(`PLANET: после перехода с отрезков на точки на экране ${back.size}, по расчёту ${wb.size}`);
  console.log(`PLANET: первая ${c1.cycles} тактов, повтор той же ${c2.cycles}; далёкая ${far} точек, близкая (отрезками) ${near.size}, снова точками ${back.size}`);
}
console.log(bad ? `ПРОВАЛ: ${bad}` : 'PCIRC: всё совпало');
process.exit(bad ? 1 : 0);
