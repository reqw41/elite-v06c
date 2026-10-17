// Прыжок как на ZX 48K (обычный образ, WARP в hyper.asm): пока J (П) держат, z планеты и солнца − 2000h за проход
// со знаком (проскочивший объект — позади), обзор не очищается, пыль в проходе с прыжком сдвигается ещё раз.
// Сценарий: вылет, разворот от планеты, уход из зоны станции, появление кораблей выключено (sp_last), J зажата, крен и тангаж
// меняются каждые 400 кадров. Проверки: каждый вызов wa_z для планеты — (z_sign z_hi) − 20h со знаком; прыжков
// хотя бы сотня; в обзоре нет точек, горящих на месте дольше 24 с (как soak.mjs). node v06c/test/zxjump.mjs [кадров = 6000]
import { createVector } from '../tools/v06c.mjs';
const FRAMES = +(process.argv[2] || 6000), STEP = 20, STUCK = 60;
const g = createVector('elite'), L = g.L, cpu = g.cpu;
const K = { SPACE: [7, 0x80], N: [5, 0x40], F1: [1, 0x08], UP: [0, 0x20], DOWN: [0, 0x80], LT: [0, 0x10], GT: [0, 0x40], FAST: [6, 0x02], JUMP: [6, 0x01] };
const key = (k, d) => g.key(K[k][0], K[k][1], d);
const press = (k) => { key(k, true); g.frame(20); key(k, false); };
let bad = 0;
const fail = (s) => { if (bad++ < 5) console.log('FAIL ' + s); };
g.frame(300); press('N'); g.frame(200); press('SPACE'); g.frame(200); press('F1'); g.frame(300);
const calm = () => { const f = g.rd16('v_frames'); g.wr(L.sp_last, [f & 255, f >> 8]); g.wr(L.ENERGY, [255]); g.wr(L.FSH, [255]); g.wr(L.ASH, [255]); };
key('UP', true); for (let i = 0; i < 2000 && !(g.rd(L.K_ + 8) & 0x80); i++) g.frame(1); key('UP', false);   // планету — за спину
key('FAST', true); for (let i = 0; i < 6000 && g.rd(L.SSPR); i++) { g.frame(1); calm(); } key('FAST', false);
if (g.rd(L.SSPR) || g.rd(L.QQ12)) { console.log('ПРОВАЛ: не вышли из зоны станции'); process.exit(1); }
for (let i = 2; i < 12; i++) if (g.rd(L.FRIN + i)) { console.log(`ПРОВАЛ: рядом корабль (место ${i}), прыжок невозможен`); process.exit(1); }
// смысл одного шага: (sign hi) — 16 бит со знаком в бите 15, минус 20h
const step = (s, h) => { const v = (s & 0x80 ? -1 : 1) * (((s & 0x7f) << 8) | h) - 0x20; return [(v < 0 ? 0x80 : 0) | ((Math.abs(v) >> 8) & 0x7f), Math.abs(v) & 255]; };
let warps = 0, pend = null;
const ins = cpu.instruction.bind(cpu);
cpu.instruction = () => { const pc = cpu.pc & 0xffff;
  if (pc === L.wa_z && ((cpu.regs[4] << 8) | cpu.regs[5]) === L.K_ + 7) { warps++; pend = step(g.rd(L.K_ + 8), g.rd(L.K_ + 7)); }
  else if (pend && pc === L.wa_z) { const got = [g.rd(L.K_ + 8), g.rd(L.K_ + 7)];   // второй вызов (солнце): планета уже сдвинута
    if (got[0] !== pend[0] || got[1] !== pend[1]) fail(`шаг планеты: ${got.map((v) => v.toString(16))}, ждали ${pend.map((v) => v.toString(16))}`); pend = null; }
  return ins(); };
const skip = (x, y) => y < 16 || y > 183 || x < 2 || x > 253 || (Math.abs(x - 128) < 3 && Math.abs(y - 96) < 28) || (Math.abs(y - 96) < 3 && Math.abs(x - 128) < 28);
const streak = new Uint16Array(256 * 192), worst = new Uint16Array(256 * 192);
const held = new Set(['JUMP']); key('JUMP', true);
for (let f = 0; f < FRAMES; f += STEP) {
  if (f % 400 === 0) { for (const k of held) if (k !== 'JUMP') key(k, false); for (const k of [...held]) if (k !== 'JUMP') held.delete(k);
    for (const k of [['LT', 'GT'][(f / 400) & 1], ['UP', 'DOWN'][(f / 800) & 1]]) { key(k, true); held.add(k); } }
  for (let i = 0; i < STEP; i++) { g.frame(1); calm(); }
  if (g.rd(L.QQ11) || g.rd(L.QQ12) || g.rd(L.MJ)) { fail('ушли из полёта'); break; }
  for (let col = 0; col < 32; col++) for (let y = 16; y < 184; y++) {
    const v = g.rd(0xC000 + col * 256 + 255 - y) | g.rd(0xE000 + col * 256 + 255 - y);
    for (let b = 0; b < 8; b++) { const x = col * 8 + b, i = y * 256 + x;
      if ((v >> (7 - b)) & 1 && !skip(x, y)) { if (++streak[i] > worst[i]) worst[i] = streak[i]; } else streak[i] = 0; } }
}
const top = Math.max(...worst), stuck = []; for (let i = 0; i < worst.length; i++) if (worst[i] >= STUCK) stuck.push(`(${i & 255},${i >> 8})×${worst[i]}`);
console.log(`кадров ${FRAMES}, прыжков ${warps}; дольше всего точка горела ${top} проверок (${(top * STEP / 50).toFixed(0)} с), порог ${STUCK}`);
if (warps < 100) fail(`прыжков мало: ${warps}`);
if (stuck.length) fail(`залипших точек ${stuck.length}: ${stuck.slice(0, 10).join(' ')}`);
console.log(bad ? `ПРОВАЛ: ${bad}` : 'ZXJUMP: всё как задумано');
process.exit(bad ? 1 : 0);
