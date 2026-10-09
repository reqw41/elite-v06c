// Выдача и награды миссий версии ZX, как в ZX 48K и Elite Legend (только обычный образ; проверка по смыслу):
// 1. счётчик прибытий: миссии — на 32-м, 128-м и 254-м прибытии, по порядку, не в первой галактике; счёт стоит,
//    пока идёт миссия дисковой версии; 2. цель «Захвата станции» — система 0; 3. награды: 256 побед за каждую
//    миссию, большой трюм за беженцев; 4. отладочный вход на паузе.
// sh v06c/build.sh && node v06c/test/mischain.mjs
import { createVector } from '../tools/v06c.mjs';
let bad = 0; const ok = (c, s) => { if (!c) bad++; console.log(`${c ? 'OK  ' : 'FAIL'} ${s}`); };
const m = createVector('elite'), L = m.L, cpu = m.cpu; m.frame(60);
const ret = () => { const sp = cpu.sp & 0xffff; cpu.pc = m.rd(sp) | (m.rd(sp + 1) << 8); cpu.sp = (sp + 2) & 0xffff; };
const skip = (...labs) => () => { for (;;) { const pc = cpu.pc & 0xffff; if (labs.some((l) => L[l] === pc)) ret(); else return; } };
const MISF = L.TP, MJC = L.ESCP + 3, M1ST = L.LASER + 4, M3ST = L.LASER + 5, M3PL = L.ESCP + 1, DTP = L.ESCP + 2, T1 = L.TALLY + 1;
const reset = () => { m.wr(MISF, [0]); m.wr(MJC, [0]); m.wr(M1ST, [0]); m.wr(M3ST, [0]); m.wr(DTP, [0]); m.wr(L.TALLY, [0, 0]); m.wr(L.GCNT, [0]); };

// 1. счётчик прибытий
{ reset(); for (let i = 0; i < 300; i++) m.call('mis_count');
  ok(m.rd(MISF) === 0 && m.rd(MJC) === 0, `первая галактика: за 300 прибытий ничего не выдано, счётчик ${m.rd(MJC)}`);
  reset(); m.wr(L.GCNT, [1]); const when = []; let issued = 0;
  for (let i = 1; i <= 600; i++) { m.call('mis_count'); if (m.rd(MISF) & 0x80) { when.push(i); issued = (issued << 1) | 1; m.wr(MISF, [issued]); } }
  ok(when.join() === '32,128,254', `вторая галактика: миссии выданы на прибытиях ${when.join(', ')} (ждали 32, 128, 254), дальше — ничего`);
  reset(); m.wr(L.GCNT, [2]); m.wr(DTP, [1]); for (let i = 0; i < 100; i++) m.call('mis_count');
  ok(m.rd(MJC) === 0 && m.rd(MISF) === 0, 'идёт охота на «Констриктора»: счёт стоит');
  m.wr(DTP, [0x0A]); for (let i = 0; i < 100; i++) m.call('mis_count');
  ok(m.rd(MJC) === 0, 'планы таргоидов на борту: счёт стоит');
  m.wr(DTP, [0x0E]); for (let i = 0; i < 40; i++) m.call('mis_count');
  ok(m.rd(MJC) === 40 && (m.rd(MISF) & 0x80), `обе дисковые миссии закончены: счёт идёт (${m.rd(MJC)}), миссия выдана`); }

// 2. цель третьей миссии
{ reset(); m.wr(L.GCNT, [1]); m.wr(MISF, [0x83]); m.wr(M3PL, [99]); m.wr(MJC, [10]);
  m.call('mis_arrive', {}, 2e6);
  ok(m.rd(M3ST) === 1 && m.rd(M3PL) !== 99 && (m.rd(MISF) & 0x87) === 0x07, `«Захват станции» выдан: состояние ${m.rd(M3ST)}, цель — система ${m.rd(M3PL)}`); }

// 3. награды
{ reset(); m.wr(M1ST, [0x80]); m.wr(L.CRGO, [22]); m.wr(L.QQ20 + 15, [0]);
  m.call('mis_dock', { tick: skip('mz_scr', 'TT217', 'md_m3') }, 2e6);
  ok(m.rd(L.QQ20 + 15) === 100 && m.rd(L.CRGO) === 37 && m.rd(T1) === 1 && m.rd(M1ST) === 0, `беженцы доставлены: камней ${m.rd(L.QQ20 + 15)}, трюм ${m.rd(L.CRGO)} (большой), побед ${m.rd(T1) * 256}`);
  reset(); m.call('mis_cloakgot', { tick: skip('messx') });
  ok(m.rd(T1) === 1 && (m.rd(MISF) & 8), `скрывающее устройство подобрано: побед ${m.rd(T1) * 256}, флаг устройства стоит`);
  reset(); m.wr(M3ST, [5]); m.call('md_m3', { tick: skip('mz_scr', 'TT217') }, 2e6);
  ok(m.rd(T1) === 1 && m.rd(M3ST) === 0, `«Захват станции», стыковка после победы: побед ${m.rd(T1) * 256}`);
  reset(); m.wr(M3ST, [4]); m.call('KS4', { tick: skip('ZINF', 'FLFLLS', 'SPBLB', 'NWSHP') }, 2e6);
  ok(m.rd(T1) === 1 && m.rd(M3ST) === 6, `захваченная станция уничтожена: побед ${m.rd(T1) * 256}, состояние ${m.rd(M3ST)}`); }

// 4. отладочный вход
{ reset(); m.call('mis_dbg_m', { b: 0x65, tick: skip('TT26', 'DELAY') }); const a = m.rd(MISF);
  m.call('mis_dbg_k', { b: 0x46, tick: skip('TT26', 'DELAY') });
  ok(a === 0x80 && m.rd(T1) === 1, `пауза + M: флаг «пора выдавать» (${a.toString(16)}); пауза + K: побед ${m.rd(T1) * 256}`);
  // в игре: на станции пауза (СТР), M, продолжить (ЗБ) — флаг стоит
  const g = createVector('elite'), K = { N: [5, 0x40], SPACE: [7, 0x80], STR: [1, 0x02], M: [5, 0x20], ZB: [0, 0x08] };
  const press = (k, n = 20) => { g.key(K[k][0], K[k][1], true); g.frame(n); g.key(K[k][0], K[k][1], false); g.frame(10); };
  g.frame(300); press('N'); g.frame(200); press('SPACE'); g.frame(200);
  press('STR'); press('M', 30); press('ZB'); g.frame(50);
  ok((g.rd(g.L.TP) & 0x80) !== 0, `в игре: СТР, M, ЗБ — флаг «пора выдавать» ${(g.rd(g.L.TP) & 0x80) ? 'стоит' : 'не стоит'}`); }
console.log(bad ? `ПРОВАЛ: ${bad}` : 'MISCHAIN: всё как задумано');
process.exit(bad ? 1 : 0);
