// Миссии дисковой версии BBC («Констриктор», «Планы таргоидов») — против кода стоянки дисковой версии.
// 1. Тексты: знаки (с текстовой позицией XC, YC) и события «очистка экрана», «корабль и клавиша», «клавиша»
//    на Векторе равны тому, что даёт DETOK дисковой версии (tools/oracle/pdesc.js, detok).
// 2. Логика стыковки: dm_dock против DOENTRY дисковой версии (tools/oracle/disc.js) на всех состояниях миссий:
//    байт миссий, счёт побед, блок энергии, деньги и номер показанного текста.
// 3. Вставки полёта: выход «Констриктора» (dm_pick), таргоиды при миссии 2 (dm_thg).
// 4. Задание миссии 1 в игре: снимок экрана с «Констриктором».
// Бой с «Констриктором» (лазеры, гибель) — сценарий constrictor в v06c/test/mis.mjs.
// sh v06c/build.sh && node v06c/test/discmis.mjs
import path from 'node:path';
import { createRequire } from 'node:module';
import { createVector, savePng, ROOT } from '../tools/v06c.mjs';
const require = createRequire(import.meta.url);
const { Disc } = require(path.join(ROOT, 'tools/oracle/pdesc.js'));
const { DiscCode } = require(path.join(ROOT, 'tools/oracle/disc.js'));
const d = new Disc(), m = createVector('elite'), L = m.L, cpu = m.cpu;
m.frame(40);
let bad = 0; const fail = (s) => { if (++bad <= 12) console.log('FAIL ' + s); };
const ret = () => { const sp = cpu.sp & 0xffff; cpu.pc = m.rd(sp) | (m.rd(sp + 1) << 8); cpu.sp = (sp + 2) & 0xffff; };
const show = (o) => { let s = '', px = -1, py = -1; for (const [c, x, y] of o) { if (x !== px || y !== py) { s += `<${x},${y}>`; px = x; py = y; } s += c === '\f' ? '|' : c; } return s; };

// --- 1. тексты
const TEXTS = [['BRIEF1', 10, [0, 1]], ['BRIEF2', 11, [2]], ['DEBRIEF1', 15, [0, 1]], ['BRIEF3', 222, [2]], ['DEBRIEF2', 223, [2]]];
let peak = 0, chars = 0;
for (const [name, tok, gals] of TEXTS) for (const gcnt of gals) for (const cmdr of ['JAMESON', 'BO']) {
  const want = d.detok(tok, { gcnt, name: cmdr });
  const got = [];
  const at = () => [m.rd(L.XC), m.rd(L.YC)];
  const tick = () => { const pc = cpu.pc & 0xffff; const k = m.rd(L.pd_n); if (k > peak) peak = k;
    if (pc === L.TT26R) { got.push([String.fromCharCode(cpu.regs[7]), ...at()]); ret(); cpu.cf = 0; }
    else if (pc === L.TT66) { got.push(['{cls}', ...at()]); ret(); }
    else if (pc === L.DELAY) ret();
    else if (pc === L.dm_pause) { got.push(['{ship}', ...at()]); ret(); }
    else if (pc === L.TT217) { got.push(['{key}', ...at()]); ret(); } };
  m.wr(L.NA_, [...cmdr].map((c) => c.charCodeAt(0)).concat([13]));
  m.call('dm_text', { a: L['PD_' + name], mem: { GCNT: gcnt, QQ17: 0x80, XC: 1, YC: 1, pd_cap: 0, pd_w2: 0xFF, pd_w8: 0xFF, pd_w1: 0x20, pd_w6: 0 }, tick }, 2e7);
  chars += got.length;
  if (show(got) !== show(want)) fail(`текст ${name}, галактика ${gcnt}, командир ${cmdr}:\n  BBC    ${show(want)}\n  Вектор ${show(got)}`);
  if (m.rd(L.pd_cap)) fail(`текст ${name}: буфер выравнивания остался включён`);
  if (name === 'BRIEF3' && cmdr === 'JAMESON') console.log('пример: ' + show(got).slice(0, 330) + '…');
}
m.wr(L.NA_, [...'JAMESON'].map((c) => c.charCodeAt(0)).concat([13])); m.wr(L.GCNT, [0]);
const room = L.vars_end - L.ll_sh;
if (peak > room) fail(`в буфере ${peak} знаков, отведено ${room}`);
console.log(`тексты миссий: ${TEXTS.reduce((q, t) => q + t[2].length * 2, 0)} прогонов, ${chars} знаков и событий; в буфере не больше ${peak} из ${room}`);

// --- 2. логика стыковки против DOENTRY
{
  const dk = new DiscCode('docked');
  const TOK = { 10: 'BRIEF1', 11: 'BRIEF2', 15: 'DEBRIEF1', 222: 'BRIEF3', 223: 'DEBRIEF2', 216: 'INCOMING' };
  let n = 0, shown = 0;
  const places = [[20, 173], [215, 84], [63, 72], [144, 33]];
  for (let tp = 0; tp < 16; tp++) for (const tally of [0, 1, 4, 5, 9]) for (let gcnt = 0; gcnt < 4; gcnt++) for (const [q0, q1] of places) {
    dk.reset(); const seenB = [];
    for (const l of ['DEEOR', 'RES2', 'HFS1', 'HALL', 'DELAY', 'BAY', 'NWSHP', 'LL9', 'MVEIT', 'TT66', 'ZINF']) dk.hooks.set(dk.lab[l], () => true);
    dk.hooks.set(dk.lab.DETOK, (o) => { seenB.push(TOK[o.cpu.a] || o.cpu.a); return true; });
    dk.poke('TP', tp); dk.poke(dk.lab.TALLY + 1, tally); dk.poke('GCNT', gcnt); dk.poke('QQ0', q0); dk.poke('QQ1', q1); dk.poke('ENGY', 1); dk.poke('CASH', [0, 0, 3, 232]);
    dk.poke(dk.lab.INWK + 6, 250);                                    // «Констриктор» на задании быстро уходит вдаль
    dk.call('DOENTRY', {}, 4e6);
    const want = [dk.peek('TP') & 15, dk.peek(dk.lab.TALLY + 1), dk.peek('ENGY'), dk.peek('CASH', 4).join('.'), seenB.join('+')].join(' / ');
    const seenV = [];
    const tick = () => { const pc = cpu.pc & 0xffff;
      if (pc === L.pd_tok) { const a = cpu.regs[7]; seenV.push(Object.values(TOK).find((nm) => L['PD_' + nm] === a) || a); ret(); }
      else if (pc === L.DELAY || pc === L.NWSHP || pc === L.LL9 || pc === L.MVEIT || pc === L.TT66 || pc === L.ZINF) ret(); };
    m.wr(L.TALLY + 1, [tally]); m.wr(L.CASH, [0, 0, 3, 232]); m.wr(L.INWK + 6, [250]);
    m.call('dm_dock', { mem: { DTP: tp, GCNT: gcnt, QQ0: q0, QQ1: q1, ENGY: 1, M1ST: 0, M3ST: 0 }, tick }, 2e6);
    const got = [m.rd(L.DTP) & 15, m.rd(L.TALLY + 1), m.rd(L.ENGY), [0, 1, 2, 3].map((k) => m.rd(L.CASH + k)).join('.'), seenV.join('+')].join(' / ');
    n++; if (seenB.length) shown++;
    if (want !== got) fail(`стыковка: миссии ${tp.toString(2)}, побед ${tally * 256}, галактика ${gcnt}, система ${q0},${q1}:\n  BBC    ${want}\n  Вектор ${got}`);
  }
  console.log(`логика стыковки: состояний ${n}, из них с текстом ${shown}`);
  // пока идёт миссия версии ZX, дисковые не предлагаются
  let t = 0; m.call('dm_dock', { mem: { DTP: 0, GCNT: 0, M1ST: 1, M3ST: 0 }, tick: () => { if ((cpu.pc & 0xffff) === L.pd_tok) t++; } }, 2e6);
  m.wr(L.TALLY + 1, [1]); m.call('dm_dock', { mem: { DTP: 0, GCNT: 0, M1ST: 1, M3ST: 0 }, tick: () => { if ((cpu.pc & 0xffff) === L.pd_tok) t++; } }, 2e6);
  if (t || m.rd(L.DTP)) fail('миссия дисковой версии предложена при идущей миссии ZX');
  m.wr(L.M1ST, [0]); m.wr(L.TALLY + 1, [0]); m.wr(L.DTP, [0]); m.wr(L.ENGY, [0]);
}

// --- 3. вставки полёта
{
  const pick = (mem, a = 5) => { m.wr(L.FRIN, new Array(13).fill(0)); m.wr(L.INWK + 32, [0xC0]); const r = m.call('dm_pick', { a, mem }); return [r.a, m.rd(L.INWK + 32)]; };
  const chk = (what, got, want) => { if (got.join() !== want.join()) fail(`dm_pick, ${what}: тип и тактика ${got}, ждали ${want}`); };
  chk('чужая система', pick({ GCNT: 1, QQ0: 20, QQ1: 33, DTP: 1 }), [5, 0xC0]);
  chk('Orarra без миссии', pick({ GCNT: 1, QQ0: 144, QQ1: 33, DTP: 0 }), [5, 0xF9]);
  chk('Orarra, миссия идёт', pick({ GCNT: 1, QQ0: 144, QQ1: 33, DTP: 1 }), [31, 0xF9]);
  chk('Orarra, «Констриктор» убит', pick({ GCNT: 1, QQ0: 144, QQ1: 33, DTP: 3 }), [5, 0xF9]);
  chk('не та галактика', pick({ GCNT: 0, QQ0: 144, QQ1: 33, DTP: 1 }), [5, 0xC0]);
  m.wr(L.FRIN, [128, 8, 31]); const r = m.call('dm_pick', { a: 4, mem: { GCNT: 1, QQ0: 144, QQ1: 33, DTP: 1 } });
  if (r.a !== 4) fail('второй «Констриктор» при живом первом');
  const slsp = [m.rd(L.SLSP), m.rd(L.SLSP + 1)]; const cnt = {};
  for (const dtp of [0, 6, 0x0A, 0x0E]) { cnt[dtp] = 0; for (let i = 0; i < 500; i++) { m.wr(L.SLSP, slsp); m.wr(L.FRIN, new Array(13).fill(0)); m.wr(L.FRIN, [128]); m.call('dm_thg', { e: 77, mem: { DTP: dtp } }, 2e6);
    if (Array.from({ length: 13 }, (_, k) => m.rd(L.FRIN + k)).includes(6)) cnt[dtp]++; } }
  console.log(`таргоиды за 500 проверок: без миссии ${cnt[0]}, вызван на Ceerdi ${cnt[6]}, планы на борту ${cnt[10]}, миссия закончена ${cnt[14]}`);
  if (cnt[0] || cnt[6] || cnt[14] || cnt[10] < 70 || cnt[10] > 160) fail('таргоиды при миссии 2: ждали около 109 из 500 только с планами на борту');
  m.wr(L.DTP, [0]); m.wr(L.GCNT, [0]);
}

// --- 4. задание миссии 1 в игре: стыковка автопилотом при 256 победах
{
  const g = createVector('elite'), K = { SPACE: [7, 0x80], N: [5, 0x40], F1: [1, 0x08], C: [4, 0x08] };
  const press = (k) => { g.key(K[k][0], K[k][1], true); g.frame(20); g.key(K[k][0], K[k][1], false); };
  g.frame(300); press('N'); g.frame(200); press('SPACE'); g.frame(200); press('F1'); g.frame(600);
  g.wr(g.L.DKCMP, [0xFF]); g.wr(g.L.TALLY + 1, [1]); press('C');
  let f = 0; while (g.rd(g.L.DTP) === 0 && f < 30000) { g.frame(25); f += 25; }
  if (g.rd(g.L.DTP) !== 1) fail('в игре: задание миссии 1 не выдано');
  g.frame(450); savePng(g.bmp(), path.join(ROOT, 'work/v06c/discmis-ship.png'));
  let show = 450; while (g.rd(g.L.YC) < 14 && show < 6000) { g.frame(25); show += 25; }          // текст задания дошёл до середины экрана
  g.frame(100); savePng(g.bmp(), path.join(ROOT, 'work/v06c/discmis-brief.png'));
  let n = 0; while (g.rd(g.L.QQ12) !== 0xFF && n < 12) { press('SPACE'); g.frame(150); n++; }
  console.log(`в игре: задание выдано через ${f} кадров после включения автопилота; показ корабля до текста — ${show} кадров (${(show / 50).toFixed(0)} с); до экрана станции — ${n} нажатий; снимки work/v06c/discmis-ship.png, discmis-brief.png`);
  if (g.rd(g.L.QQ12) !== 0xFF) fail('в игре: после задания не попали на станцию');
}
console.log(bad ? `ПРОВАЛ: ${bad}` : 'DISCMIS: всё совпало');
process.exit(bad ? 1 : 0);
