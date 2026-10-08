// Замеры скорости для docs/research/versions.md. Числа — в машинном времени: BBC 2 МГц (6502), Вектор 3 МГц (i8080).
// 1. Проходы главного цикла в полёте по сценариям сверки (образ стенда против кассетной BBC) — строка «полёт»
//    теста t27.mjs. 2. Обычный образ в настоящих кадрах: проходов в секунду после взлёта (по счётчику MCNT).
// 3. Добавки дисковой версии: одна процедура на обеих машинах — такты и время.
// sh v06c/build.sh && sh v06c/build.sh -DSCHED && node v06c/tools/speed.mjs
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { createVector, ROOT } from './v06c.mjs';
const require = createRequire(import.meta.url);
const { Disc, seeds } = require(path.join(ROOT, 'tools/oracle/pdesc.js'));
const { DiscCode } = require(path.join(ROOT, 'tools/oracle/disc.js'));
const ms = (cyc, mhz) => cyc / (mhz * 1000);

console.log('--- 1. полёт по сценариям сверки (образ стенда, кассетная BBC)');
for (const s of ['launch', 'fight', 'jump', 'voyage']) {
  const out = execFileSync('node', [path.join(ROOT, 'v06c/test/t27.mjs'), s], { encoding: 'utf8', maxBuffer: 1 << 26 });
  console.log(`${s}: ` + (out.split('\n').find((l) => l.startsWith('полёт')) || 'нет строки «полёт»'));
}

console.log('--- 2. обычный образ, настоящие кадры (50 в секунду)');
{
  const g = createVector('elite'), K = { SPACE: [7, 0x80], N: [5, 0x40], F1: [1, 0x08], C: [4, 0x08] };
  const press = (k) => { g.key(K[k][0], K[k][1], true); g.frame(20); g.key(K[k][0], K[k][1], false); };
  const rate = (frames) => { let n = 0, prev = g.rd(g.L.MCNT); for (let f = 0; f < frames; f++) { g.frame(1); const c = g.rd(g.L.MCNT); n += (prev - c) & 255; prev = c; } return n * 50 / frames; };
  g.frame(300); press('N'); g.frame(200); press('SPACE'); g.frame(200); press('F1'); g.frame(400);
  console.log(`после взлёта, планета и станция позади: ${rate(1000).toFixed(1)} прохода в секунду`);
  g.wr(g.L.DKCMP, [0xFF]); press('C');
  console.log(`под автопилотом стыковки (разворот к станции, станция в кадре): ${rate(1000).toFixed(1)} прохода в секунду`);
}

console.log('--- 3. добавки дисковой версии: одна процедура');
{
  const d = new Disc(), m = createVector('elite'), L = m.L, cpu = m.cpu; m.frame(40);
  let b = 0, v = 0, n = 0;
  for (let s = 0; s < 256; s++) { const sd = seeds(0, s); b += d.describe(0, s).cycles;
    const tick = () => { if ((cpu.pc & 0xffff) !== L.TT26R) return; const sp = cpu.sp & 0xffff; cpu.pc = m.rd(sp) | (m.rd(sp + 1) << 8); cpu.sp = (sp + 2) & 0xffff; cpu.cf = 0; };
    v += m.call('PDESC', { mem: { QQ15: sd, QQ17: 0x80, QQ8: [1, 0] }, tick }).cycles; n++; }
  console.log(`описание планеты без печати знаков, среднее по галактике 0: BBC ${(b / n).toFixed(0)} тактов (${ms(b / n, 2).toFixed(0)} мс), Вектор ${(v / n).toFixed(0)} тактов (${ms(v / n, 3).toFixed(0)} мс), Вектор/BBC ${(ms(v / n, 3) / ms(b / n, 2)).toFixed(2)}`);
}
{
  const d = new DiscCode('flight'), m = createVector('elite'), L = m.L; m.frame(40);
  let rs = 99; const rnd = (k = 256) => { rs = (rs * 1103515245 + 12345) >>> 0; return (rs >>> 16) % k; };
  let b = 0, v = 0, n = 0;
  for (let i = 0; i < 500; i++) {
    const stn = new Array(36).fill(0); [0, 3, 6].forEach((k) => { stn[k] = rnd(); stn[k + 1] = rnd(40); stn[k + 2] = rnd(2) << 7; }); stn[10] = 96; stn[18] = 96; stn[14 + 12] = 0x60; stn[14] = 0xE0;
    const inwk = new Array(36).fill(0); inwk[10] = 96; inwk[14] = 96; inwk[22] = 0xE0; inwk[18] = 96; inwk[27] = 10;
    d.reset(); d.poke(d.lab['K%'] + 37, stn); d.poke('INWK', inwk); d.poke('TYPE', 0xE0); d.poke('SSPR', 1); b += d.call('DOCKIT').cycles;
    m.wr(L.K_ + 36, stn); m.wr('INWK', inwk); m.wr('TYPE', [0xE0]); m.wr('SSPR', [1]); v += m.call('DOCKIT').cycles; n++; }
  console.log(`решение автопилота DOCKIT, среднее по 500 положениям: BBC ${(b / n).toFixed(0)} тактов (${ms(b / n, 2).toFixed(1)} мс), Вектор ${(v / n).toFixed(0)} тактов (${ms(v / n, 3).toFixed(1)} мс), Вектор/BBC ${(ms(v / n, 3) / ms(b / n, 2)).toFixed(2)}`);
}
{
  const d = new DiscCode('docked'), m = createVector('elite'), L = m.L, cpu = m.cpu; m.frame(40);
  const TYPES = Array.from({ length: 7 }, (_, i) => m.rd(L.hall_ty + i)), SLOT = [5, 9, 10, 11, 12, 16, 19];
  const model = (t) => { const a = m.rd16(L.XX21X + 2 * (t - 1)); const nv = m.rd(a + 8), ne = m.rd(a + 9), nf = m.rd(a + 12);
    const end = Math.max(20 + nv, (m.rd(a + 3) | (m.rd(a + 16) << 8)) + 4 * ne, (m.rd(a + 4) | (m.rd(a + 17) << 8)) + nf); return Array.from({ length: end }, (_, i) => m.rd(a + i)); };
  let rs = 5; const rnd = () => { rs = (rs * 1103515245 + 12345) >>> 0; return (rs >>> 16) & 255; };
  let b = 0, v = 0, n = 0;
  for (let i = 0; i < 40; i++) { const rand = [rnd(), rnd(), rnd(), rnd()];
    d.reset(); let at = 0x8000; TYPES.forEach((t, k) => { const bl = model(t); d.poke(at, bl); d.poke(d.lab.XX21 + 2 * (SLOT[k] - 1), [at & 255, at >> 8]); at += bl.length; });
    d.hooks.set(d.lab.TT66, (o) => { o.cpu.p &= ~1; return true; }); d.hooks.set(d.lab.UNWISE, () => true); d.poke('RAND', rand);
    b += d.call('HALL', {}, 4e7).cycles;
    for (let a = 0xC000; a < 0x10000; a++) if ((a & 255) >= 64) m.wr(a, [0]);
    m.wr('RAND', rand);
    const tick = () => { if ((cpu.pc & 0xffff) !== L.TT66) return; const sp = cpu.sp & 0xffff; cpu.pc = m.rd(sp) | (m.rd(sp + 1) << 8); cpu.sp = (sp + 2) & 0xffff; };
    v += m.call('HALL', { tick }, 4e7).cycles; n++; }
  console.log(`ангар HALL без очистки экрана, среднее по 40 случаям: BBC ${(b / n).toFixed(0)} тактов (${(ms(b / n, 2) / 1000).toFixed(2)} с), Вектор ${(v / n).toFixed(0)} тактов (${(ms(v / n, 3) / 1000).toFixed(2)} с), Вектор/BBC ${(ms(v / n, 3) / ms(b / n, 2)).toFixed(2)}`);
}
