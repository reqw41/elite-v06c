// Скорость Вектора в настоящих кадрах (50 Гц) для сравнения с ZX 48K (tools/analysis/zx48_run.mjs): заставка (проходы
// title_pass) и полёт после вылета с Лейва без нажатий (MCNT). node tools/analysis/speed_zx.mjs [образ = elite]
// ZX 48K: node tools/analysis/zx48_run.mjs "300 60:_ 200 30:1 400 500 3000" — шаг 0 заставка, шаги 4–6 полёт.
import { createVector } from '../../v06c/tools/v06c.mjs';
const name = process.argv[2] || 'elite';
const m = createVector(name), L = m.L;
let tp = 0; { const ins = m.cpu.instruction.bind(m.cpu); m.cpu.instruction = () => { if ((m.cpu.pc & 0xffff) === L.title_pass) tp++; return ins(); }; }
const press = (r, b) => { m.key(r, b, true); m.frame(20); m.key(r, b, false); };
m.frame(100); tp = 0; m.frame(500); const title = tp / 500 * 50;
press(5, 0x40); m.frame(200); press(7, 0x80); m.frame(100);         // N, пробел — в доке
press(1, 0x08);                                                      // F1 — вылет
m.frame(400);                                                        // тоннель и отлёт, как у ZX: шаг 400
const seg = (n) => { let c = 0, p = m.rd(L.MCNT); for (let i = 0; i < n; i++) { m.frame(1); const q = m.rd(L.MCNT); c += (p - q) & 255; p = q; } return c / n * 50; };
const a = seg(500), b = seg(3000);
console.log(`${name}: заставка ${title.toFixed(2)} проходов/с; полёт после вылета: кадры 400–900 — ${a.toFixed(2)}, 900–3900 — ${b.toFixed(2)} проходов/с`);
