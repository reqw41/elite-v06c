// Корабли версии ZX (Krait 14, Asp Mk II 15, Fer-de-Lance 16). На BBC их нет — сверять не с чем; тест проверяет,
// что игра с ними живёт: боевой сценарий fight идёт на Векторе с подменой типов (Sidewinder → Krait,
// Mamba → Asp, Cobra → Fer-de-Lance) до конца — бой лазером, ракета, таран, гибель, заставка; счёт побед растёт,
// в конце — заставка. До последней фазы щиты держатся полными: с другими противниками бой идёт не так, как в сценарии. Плюс снимки кораблей и статистика замены zx_pick.
// sh v06c/build.sh -DSCHED && sh v06c/build.sh && node v06c/test/zxships.mjs
import path from 'node:path';
import { createRequire } from 'node:module';
import { createVector, savePng, ROOT } from '../tools/v06c.mjs';
const require = createRequire(import.meta.url);
const { BBC } = require(path.join(ROOT, 'tools/oracle/bbc.js'));
const { SCN, addr } = require(path.join(ROOT, 'tools/oracle/scenario.js'));
const B = new BBC({ sched: true }).lab;
const SUB = { 1: 14, 3: 15, 5: 16 }, NAME = { 14: 'krait', 15: 'asp', 16: 'fer' };
const m = createVector('elite_t'), L = m.L, WS = L.WS;
const rows = new Array(8).fill(0);
const setKey = (code, down) => { const i = m.rd(L.kb_rev + code); if (i >= 64) return; if (down) rows[i >> 3] |= 1 << (i & 7); else rows[i >> 3] &= ~(1 << (i & 7)); m.wr(L.kb_rows, rows); };
const VL = { D2: 'death_d2' };
let idx = 0, bad = 0, seen = [], maxTally = 0, mortal = false, pend = null;
const fail = (s) => { bad++; console.log('FAIL ' + s); };
try {
  for (const step of SCN.fight) {
    const [label, n, down = [], up = [], k = 2, poke, calls] = step;
    const vput = (map) => { for (const [a, v] of Object.entries(map || {})) m.wr(WS + addr(B, a), v); };
    vput(poke);
    if (poke && poke.ENERGY) mortal = true;                  // последняя фаза сценария: гибель
    let shot = null;
    for (const [lab, { a = 0, x = 0, y = 0, c = 0 } = {}, mem] of calls || []) { vput(mem); const t = lab === 'NWSHP' && SUB[a] ? SUB[a] : a;
      const r = m.call(lab, { a: t, b: x, c: y, cf: c }); if (lab === 'NWSHP') { if (!r.cf) fail(`NWSHP типа ${t}: места нет`); seen.push(t); shot = t; } }
    down.forEach((c) => setKey(c, true)); up.forEach((c) => setKey(c, false));
    for (let i = 0; i < n; i++, idx++) {
      if (!mortal) { m.wr(WS + B.ENERGY, [255]); m.wr(WS + B.FSH, [255]); m.wr(WS + B.ASH, [255]); }   // с другими кораблями бой идёт иначе: до последней фазы щиты полные
      m.runTo(VL[label] || label, 6e7);
      for (let f = 0; f < k; f++) { m.wr('DL', [30]); const la = m.rd('LASCT'); if (la) m.wr('LASCT', [la - 1]); }
      maxTally = Math.max(maxTally, m.rd(WS + B.TALLY));
      if (shot && NAME[shot]) { pend = [shot, idx + 6]; shot = null; }
      if (pend && idx === pend[1]) { const shot = pend[0]; pend = null;               // корабль только что появился: снимок (копия машины не нужна — кадр без хода игры)
        const snap = m.mem().slice(0xC000, 0x10000), o = path.join(ROOT, 'work/v06c', `zx-${NAME[shot]}.png`);
        const m2 = createVector('elite'); m2.frame(40); m2.wr(0xC000, snap); m2.cpu.iff = false; m2.frame(1); savePng(m2.bmp(), o);
      }
    }
  }
} catch (e) { fail(`проход ${idx}: ${e.message}`); }
const frin = Array.from(m.mem().subarray(WS + B.FRIN, WS + B.FRIN + 13));
console.log(`${bad ? 'FAIL' : 'OK  '} сценарий fight с кораблями ZX: ${idx} проходов, появлялись типы ${seen.join(', ')}; побед за бой ${maxTally}`);
if (maxTally < 2) fail(`побед ${maxTally}, ждали не меньше 2`);
if (m.rd(WS + B.QQ12) !== 0xFF) fail('в конце не заставка');
// появление кораблей по правилам дисковой версии (обычный образ): доли типов на 4000 вызовов
{ const r = createVector('elite'); r.frame(40);
  const stat = (fn, arg) => { const c = {}; for (let i = 0; i < 4000; i++) { const a = r.call(fn, arg ? arg(i) : {}).a; c[a] = (c[a] || 0) + 1; } return c; };
  const show = (c) => Object.entries(c).map(([t, n]) => `${t}: ${(n / 40).toFixed(0)} %`).join(', ');
  const near = (c, want) => Object.keys(c).every((t) => t in want) && Object.entries(want).every(([t, p]) => Math.abs((c[t] || 0) / 40 - p) < Math.max(3, p * 0.2));
  let c = stat('ds_lone'); console.log('одиночный охотник: ' + show(c)); if (!near(c, { 5: 25, 15: 25, 4: 25, 16: 25 })) fail('одиночный охотник: доли не те');
  c = stat('ds_trade'); console.log('торговец: ' + show(c)); if (!near(c, { 7: 25, 4: 25, 27: 25, 28: 25 })) fail('торговец: доли не те');
  c = stat('ds_pack'); console.log('корабль стаи: ' + show(c)); if (!near(c, { 1: 42.2, 3: 14.1, 14: 14.1, 22: 4.7, 23: 14.1, 24: 4.7, 25: 4.7, 5: 1.6 })) fail('стая: доли не те');
  c = stat('ds_junk', (i) => ({ a: (i * 97) & 255 })); console.log('мусор: ' + show(c)); if (!near(c, { 11: 2, 21: 50, 10: 48 })) fail('мусор: доли не те'); }
// корабли дисковой версии (типы 21–31): каждый появляется, рисуется (снимок), гибнет как корабль; валун — как астероид
{ const NAMES = { 21: 'boulder', 22: 'adder', 23: 'gecko', 24: 'cobra1', 25: 'worm', 26: 'moray', 27: 'boa', 28: 'anaconda', 29: 'shuttle', 30: 'transporter', 31: 'constrictor' };
  const made = [];
  for (const t of Object.keys(NAMES).map(Number)) {
    const r = createVector('elite'); r.frame(40); const W = r.L.WS;
    r.call('ZINF'); r.wr(W + B.INWK + 7, [t === 30 || t >= 27 ? 2 : 1]); r.wr(W + B.INWK + 6, [0x40]);
    const q = r.call('NWSHP', { a: t });
    if (!q.cf) { fail(`тип ${t} (${NAMES[t]}): NWSHP не дал места`); continue; }
    r.wr(W + B.QQ11, [0]); r.call('TT66', { a: 0 }); r.call('ZINF'); r.wr(W + B.INWK + 7, [t === 30 || t >= 27 ? 2 : 1]); r.wr(W + B.INWK + 6, [0x40]);
    r.wr(W + B.TYPE, [t]); const xx0 = r.rd16(r.L.XX21X + 2 * (t - 1)); r.wr(W + B.XX0, [xx0 & 255, xx0 >> 8]);
    r.wr(W + B.INWK + 33, [(W + 0xC00) & 255, (W + 0xC00) >> 8]); r.wr(W + 0xC00, [0]);
    r.call('LL9', {}, 2e7);
    let px = 0; for (let a = 0xC000; a < 0xE000; a++) { const v = r.rd(a); if ((a & 255) >= 64) for (let k = 0; k < 8; k++) px += (v >> k) & 1; }
    if (px < 30) fail(`тип ${t} (${NAMES[t]}): на экране ${px} точек`);
    r.cpu.iff = false; r.frame(1); savePng(r.bmp(), path.join(ROOT, 'work/v06c', `disc-${NAMES[t]}.png`)); made.push(`${NAMES[t]} ${px}`);
  }
  console.log('корабли дисковой версии, точек на экране: ' + made.join(', '));
  // свойства типов: злость, подбор, кувыркание
  const r = createVector('elite'); r.frame(40); const W = r.L.WS;
  r.call('ZINF'); r.wr(W + B.INWK + 7, [3]); r.wr(W + B.INWK + 32, [0x80]); r.call('NWSHP', { a: 22 });
  const blk = r.rd16(r.L.UNIV + 2 * Array.from(r.mem().subarray(W + B.FRIN, W + B.FRIN + 13)).indexOf(22));
  r.wr(W + B.INF, [blk & 255, blk >> 8]); r.call('ANGRY', { a: 22 });
  if (!(r.rd(blk + 32) & 0x40) && r.rd(blk + 28) !== 2) fail('Adder не разозлился');
  // Anaconda выпускает Worm, станция — челнок; статистика на 4000 вызовов тактики
  let worms = 0, shut = 0; const slsp = [r.rd(W + B.SLSP), r.rd(W + B.SLSP + 1)];
  for (let i = 0; i < 4000; i++) { r.wr(W + B.SLSP, slsp); r.wr(W + B.FRIN, new Array(13).fill(0)); r.wr(W + B.FRIN, [128, 8, 28]);
    r.call('ZINF'); r.wr(W + B.INWK + 7, [3]); r.wr(W + B.TYPE, [28]); r.wr(W + B.INF, [(W + 0x900 + 72) & 255, (W + 0x900 + 72) >> 8]);
    const a28 = r.rd16(r.L.XX21X + 2 * 27); r.wr(W + B.XX0, [a28 & 255, a28 >> 8]);
    r.call('zx_tact', { b: 28 });
    r.wr(W + B.TYPE, [8]); r.wr(W + B.INWK + 32, [0]); r.wr(W + B.INF, [(W + 0x900 + 36) & 255, (W + 0x900 + 36) >> 8]);
    r.call('zx_tact', { b: 8 });
    const f = Array.from(r.mem().subarray(W + B.FRIN, W + B.FRIN + 13));
    if (f.includes(25)) worms++; if (f.includes(29) || f.includes(30)) shut++; }
  console.log(`за 4000 вызовов тактики: Anaconda выпустила Worm ${worms} раз, станция выпустила челнок ${shut} раз`);
  if (worms < 30 || worms > 100) fail(`Worm: ${worms}, ждали около 62`); if (shut < 20 || shut > 80) fail(`челнок: ${shut}, ждали около 47`);
  // станция Dodo при технике от 10
  for (const [tek, dodo] of [[5, false], [9, false], [10, true], [14, true]]) { r.wr(r.L.tek, [tek]); r.wr(W + B.FRIN, new Array(13).fill(0)); r.wr(W + B.FRIN, [128]);
    r.call('NWSPS'); const is = r.rd16(r.L.XX21X + 14) === r.L.ship_dodo; if (is !== dodo) fail(`техника ${tek}: станция ${is ? 'Dodo' : 'Coriolis'}`); }
  r.wr(r.L.tek, [12]); r.call('TT66', { a: 0 }); r.wr(W + B.QQ11, [0]); r.call('ZINF'); r.wr(W + B.INWK + 7, [3]); r.wr(W + B.TYPE, [8]);
  r.wr(W + B.XX0, [r.L.ship_dodo & 255, r.L.ship_dodo >> 8]); r.wr(W + B.INWK + 33, [(W + 0xC00) & 255, (W + 0xC00) >> 8]); r.wr(W + 0xC00, [0]);
  r.call('LL9', {}, 2e7); r.cpu.iff = false; r.frame(1); savePng(r.bmp(), path.join(ROOT, 'work/v06c/disc-dodo.png'));
  console.log('станция: Coriolis при технике до 9, Dodo от 10; снимок work/v06c/disc-dodo.png'); }
// утечка топлива при уроне (обычный образ): из 3000 ударов по энергии около 47 раз топливо обнуляется
{ const r = createVector('elite'); r.frame(40); const WS2 = r.L.WS; let leaks = 0, msg = 0;
  for (let i = 0; i < 3000; i++) { r.wr(WS2 + B.QQ14, [70]); r.wr(WS2 + B.ENERGY, [255]); r.wr(WS2 + B.FSH, [0]); r.wr(WS2 + B.ASH, [0]); r.wr(WS2 + B.DLY, [0]); r.wr(r.L.mch_x, [0]);
    r.wr(WS2 + B.INF, [(WS2 + 0x900) & 255, (WS2 + 0x900) >> 8]); r.call('OOPS', { a: 5, cf: 1 });
    if (r.rd(WS2 + B.QQ14) === 0) { leaks++; if (r.rd(r.L.mch_x) === 6) msg++; } }
  console.log(`утечка топлива: ${leaks} из 3000 ударов, сообщение «FUEL LEAK» показано ${msg} раз`);
  if (leaks < 25 || leaks > 75) fail(`утечек ${leaks}, ждали около 47`); if (msg < leaks - 3) fail('утечка без сообщения'); }
// пластина обшивки при гибели корабля (обычный образ): за 12 гибелей хотя бы одна
{ const r = createVector('elite'); r.frame(40); const WS2 = r.L.WS; r.call('ZINF'); r.wr(WS2 + B.INWK + 7, [5]); r.call('NWSHP', { a: 1 }); r.wr(WS2 + B.TYPE, [1]);
  let n = 0; const has = () => Array.from(r.mem().subarray(WS2 + B.FRIN, WS2 + B.FRIN + 13)).includes(19);
  while (!has() && n < 12) { r.call('zx_plate'); n++; }
  console.log(`пластина обшивки: появилась после ${n} гибелей`); if (!has()) fail('пластина не появилась'); }
console.log(bad ? `ПРОВАЛ: ${bad}` : 'ZXSHIPS: всё как задумано');
process.exit(bad ? 1 : 0);
