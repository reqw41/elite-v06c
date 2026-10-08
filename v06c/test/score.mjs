// Счёт очками, как в ZX 48K (обычный образ): цена каждого типа, перенос в старшие байты и «Right on, Commander!»,
// границы рангов, очки за цель ракеты; в образе стенда счёт остаётся BBC (победа = 1, границы 8…6400).
// sh v06c/build.sh && node v06c/test/score.mjs
import { createVector } from '../tools/v06c.mjs';
let bad = 0; const ok = (c, s) => { if (!c) { bad++; console.log('FAIL ' + s); } };
// половина числа из заголовка модели: ZX 48K (снимок, таблица 6180h) и Legend для типов, которых в ZX 48K нет
const ZX = { 1: 128, 2: 40, 3: 448, 4: 448, 5: 448, 6: 1024, 7: 256, 8: 0, 9: 224, 10: 0, 11: 15, 12: 50, 13: 25, 14: 128, 15: 416, 16: 384, 17: 416,
  18: 15, 19: 16, 20: 0, 21: 0, 22: 136, 23: 288, 24: 384, 25: 192, 26: 448, 27: 496, 28: 576, 29: 192, 30: 128, 31: 296 };
const m = createVector('elite'), L = m.L, cpu = m.cpu; m.frame(60);
const TFR = L.ESCP + 4, score = () => m.rd(TFR) | (m.rd(L.TALLY) << 8) | (m.rd(L.TALLY + 1) << 16);
const set = (v) => { m.wr(TFR, [v & 255]); m.wr(L.TALLY, [(v >> 8) & 255, (v >> 16) & 255]); };
const ret = () => { const sp = cpu.sp & 0xffff; cpu.pc = m.rd(sp) | (m.rd(sp + 1) << 8); cpu.sp = (sp + 2) & 0xffff; };
let mess = [];
const tick = () => { for (;;) { const pc = cpu.pc & 0xffff; if (pc === L.MESS) { mess.push(cpu.regs[7]); ret(); } else if (pc === L.NOISE) ret(); else return; } };
let maxErr = 0;
for (let t = 1; t <= 31; t++) { set(0x012345); mess = []; m.call('EXNO2', { mem: { TYPE: t }, tick });
  const d = score() - 0x012345, err = Math.abs(d - ZX[t]); maxErr = Math.max(maxErr, err);
  ok(err <= 4 && (ZX[t] === 0) === (d === 0), `тип ${t}: начислено ${d}, в ZX ${ZX[t]}`); ok(mess.length === 0, `тип ${t}: лишнее сообщение`); }
set(0x02FFF0); mess = []; m.call('EXNO2', { mem: { TYPE: 1 }, tick });
ok(score() === 0x030070 && mess.join() === '101', `перенос в старший байт: счёт ${score().toString(16)}, сообщения ${mess}`);
// ранги: граница — первое значение счёта с новым рангом
const rank = (img, v) => { let r = -1; img.wr(img.L.TALLY, [(v >> 8) & 255, (v >> 16) & 255]);
  img.call('STATUS', { tick: () => { if ((img.cpu.pc & 0xffff) === img.L.st3) r = img.cpu.regs[0]; } }, 2e7); return r; };
const bounds = (img) => { const b = []; let prev = rank(img, 0); for (let v = 0x100; v < 0x1C0000; v += 0x100) { if ((v & 0xFF00) > 0x8200 || (v >= 0x10000 && (v & 0xFF00))) continue;
  const r = rank(img, v); if (r !== prev) { b.push(v); prev = r; } } return b; };
const bz = bounds(m), wantZ = [0x0900, 0x1100, 0x2100, 0x4100, 0x8100, 0x030000, 0x0B0000, 0x1A0000];
ok(bz.join() === wantZ.join(), `границы рангов: ${bz.map((x) => x.toString(16))}`);
const s = createVector('elite_t'); s.frame(60);
const bs = bounds(s).map((x) => x >> 8), wantB = [8, 16, 32, 64, 128, 512, 2560, 6400];
ok(bs.join() === wantB.join(), `стенд, границы рангов в победах: ${bs}`);
s.wr(s.L.TALLY, [5, 0]); s.call('EXNO2', { mem: { TYPE: 10 }, tick: () => { for (;;) { const pc = s.cpu.pc & 0xffff; if (pc === s.L.NOISE || pc === s.L.MESS) { const sp = s.cpu.sp & 0xffff; s.cpu.pc = s.rd(sp) | (s.rd(sp + 1) << 8); s.cpu.sp = (sp + 2) & 0xffff; } else return; } } });
ok(s.rd(s.L.TALLY) === 6, `стенд: победа = 1 (стало ${s.rd(s.L.TALLY)})`);
console.log(`цены 31 типа: наибольшее отклонение от ZX ${maxErr} очка; границы рангов обычного образа: ${bz.map((x) => x.toString(16).toUpperCase() + 'h').join(' ')}; стенда: ${bs.join(' ')} побед`);
console.log(bad ? `ПРОВАЛ: ${bad}` : 'SCORE: всё как задумано');
process.exit(bad ? 1 : 0);
