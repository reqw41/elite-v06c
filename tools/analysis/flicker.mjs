// Мигание планеты (ветка planet-flicker): 8 выборок за кадр, точки планеты = горящие в обзоре − фон без планеты; провал — меньше половины
// точек планеты от числа в начале прохода. Сцена: планета по курсу со сдвигом вправо, z от D000h до 4000h (радиус ~118..384).
// IMG=<образ> node tools/analysis/flicker.mjs (по умолчанию elite)
import { createVector } from '../../v06c/tools/v06c.mjs';
const g = createVector(process.env.IMG || 'elite'), L = g.L, cpu = g.cpu;
const K = { SPACE: [7, 0x80], N: [5, 0x40], F1: [1, 0x08], UP: [0, 0x20], FAST: [6, 0x02], JUMP: [6, 0x01], SLOW: [0, 0x01] };
const key = (k, d) => g.key(K[k][0], K[k][1], d); const press = (k) => { key(k, true); g.frame(20); key(k, false); };
const pc8 = new Uint8Array(256); for (let i = 0; i < 256; i++) pc8[i] = (i & 1) + pc8[i >> 1];
const lit = () => { let n = 0; for (let col = 0; col < 32; col++) for (let r = 72; r < 256; r++) n += pc8[g.rd(0xC000 + col * 256 + r)]; return n; };
let base = 0, cyc = 0, on = false, passes = 0, frames = 0; const samples = [], meta = [];
const ins = cpu.instruction.bind(cpu);
let refNow = 0; const bandP = {}, bandF = {}; const refs = [];
cpu.instruction = () => { if (on && (cpu.pc & 0xffff) === L.TT100) { passes++; refNow = lit(); const r = Math.round(0x6000 / Math.max(1, g.rd(L.K_ + 7))); const b = r < 128 ? 'r<128' : r < 160 ? 'r 128–159' : r < 200 ? 'r 160–199' : r < 260 ? 'r 200–259' : 'r 260+'; bandP[b] = (bandP[b] || 0) + 1; } const r = ins(); if (on) { cyc += cpu.vcycles | 0; if (cyc >= 7488) { cyc -= 7488; samples.push(lit()); refs.push(refNow); meta.push([g.rd(L.LSX2), 0, g.rd(L.K_ + 7)]); } } return r; };
const report = (name) => { let dips = 0; const why = {}, all = {};
  for (let i = 0; i < samples.length; i++) {
    const r = Math.min(999, Math.round(0x6000 / Math.max(1, meta[i][2])));
    const k = (meta[i][0] === 1 ? 'точками ' : 'отрезками ') + (r < 128 ? 'r<128' : r < 160 ? 'r 128–159' : r < 200 ? 'r 160–199' : r < 260 ? 'r 200–259' : 'r 260+');
    all[k] = (all[k] || 0) + 1;
    const ref = refs[i] - base;
    if (ref > 100 && samples[i] - base < ref * 0.5) { dips++; why[k] = (why[k] || 0) + 1; } }
  console.log(`${name}: выборок ${samples.length}, провалов (видно меньше половины планеты) ${dips} (${(dips / samples.length * 100).toFixed(1)} %), проходов в секунду ${(passes / (samples.length / 8) * 50).toFixed(2)}`);
  for (const k of Object.keys(all).sort()) console.log(`   ${k.padEnd(20)} выборок ${String(all[k]).padStart(5)}, провалов ${why[k] || 0} (${((why[k] || 0) / all[k] * 100).toFixed(1)} %)`);
  passes = 0; samples.length = 0; meta.length = 0; refs.length = 0; };
const calm = () => { const f = g.rd16('v_frames'); g.wr(L.sp_last, [f & 255, f >> 8]); g.wr(L.ENERGY, [255]); };
g.frame(300); press('N'); g.frame(200); press('SPACE'); g.frame(200); press('F1'); g.frame(200);
// планета прямо по курсу, z уменьшается каждый кадр: радиус от ~118 до ~384
key('UP', true); for (let i = 0; i < 2000 && !(g.rd(L.K_ + 8) & 0x80); i++) g.frame(1); key('UP', false);
key('FAST', true); for (let i = 0; i < 6000 && g.rd(L.SSPR); i++) { g.frame(1); calm(); } key('FAST', false);
key('SLOW', true); g.frame(300); key('SLOW', false);
g.wr(L.K_, [0, 0, 0, 0, 0, 0, 0, 0xD0, 0x80]); g.frame(30); calm(); const bg = []; for (let k = 0; k < 40; k++) { g.frame(1); calm(); bg.push(lit()); }
base = bg.sort((a, b) => a - b)[20]; console.log('фон без планеты:', base, 'точек');
const rad = []; on = true;
for (let f = 0; f < 1500; f++) { const z = 0xD000 - f * 24, x = Math.round(z * 0.55); g.wr(L.K_, [x & 255, x >> 8, 0, 0, 0x10, 0x80, z & 255, z >> 8, 0]); { const r = Math.round(0x6000 / Math.max(1, z >> 8)); const b = r < 128 ? 'r<128' : r < 160 ? 'r 128–159' : r < 200 ? 'r 160–199' : r < 260 ? 'r 200–259' : 'r 260+'; bandF[b] = (bandF[b] || 0) + 1; } g.frame(1); calm(); if (f % 250 === 0) rad.push((0xD000 - f * 24).toString(16)); }
on = false; console.log('проходов в секунду по радиусу: ' + Object.keys(bandF).map((b) => `${b} — ${((bandP[b] || 0) / bandF[b] * 50).toFixed(1)}`).join(', ')); report('планета по курсу, приближается'); console.log('радиус по ходу:', rad.join(' '));
