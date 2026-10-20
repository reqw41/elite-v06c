// Доля стирания прежних отрезков кораблей (lf_draw из lf_old) против рисования новых в живой сцене elite_sun.
// sh v06c/build.sh -DSCENE && node tools/analysis/erase_share.mjs (FR=кадров замера, IMG=образ)
import { createVector } from '../../v06c/tools/v06c.mjs';
const g = createVector(process.env.IMG || 'elite_sun'), L = g.L, cpu = g.cpu;
const K = { SPACE: [7, 0x80], N: [5, 0x40], F1: [1, 0x08], STR: [1, 0x02], M: [5, 0x20], ZB: [0, 0x08] };
const press = (k, n = 20) => { g.key(K[k][0], K[k][1], true); g.frame(n); g.key(K[k][0], K[k][1], false); g.frame(10); };
g.frame(300); press('N'); g.frame(200); press('SPACE'); g.frame(200); press('F1'); g.frame(600);
press('STR'); g.frame(20); press('M'); g.frame(20); press('ZB'); g.frame(100);
const ERA = L.lf_old + 17, names = ['lf_draw', 'll155_at', 'SUN', 'sun_red', 'LL9', 'STARS', 'wpls_red'];
const ent = new Map(names.map((n, i) => [L[n], i])), acc = { er: 0, dr: 0 }, inc = names.map(() => 0); let open = names.map(() => null);
let tot = 0, passes = 0; const ins = cpu.instruction.bind(cpu);
cpu.instruction = () => { const pc = cpu.pc & 0xffff;
  if (pc === L.TT100) passes++;
  const k = ent.get(pc); if (k !== undefined && !open[k]) { const sp = cpu.sp & 0xffff; const ret = g.rd(sp) | g.rd(sp + 1) << 8; open[k] = { sp, ret }; }
  const r = ins(), c = cpu.vcycles | 0; tot += c;
  open.forEach((o, i) => { if (o) { inc[i] += c; if (i === 0) acc[o.ret === ERA ? 'er' : 'dr'] += c; if ((cpu.pc & 0xffff) === o.ret && (cpu.sp & 0xffff) === ((o.sp + 2) & 0xffff)) open[i] = null; } });
  return r; };
g.frame(+(process.env.FR || 1000));
const p = (v) => `${(v / passes).toFixed(0)} (${(v / tot * 100).toFixed(1)}%)`;
console.log(`проходов ${passes}, тактов на проход ${(tot / passes).toFixed(0)}`);
console.log(`lf_draw стирание: ${p(acc.er)}, рисование: ${p(acc.dr)}`);
names.forEach((n, i) => console.log(`${n}: ${p(inc[i])}`));
