// Миссии версии ZX: свои сценарии на Векторе (эталона BBC для них нет). Образ стенда elite_t.rom идёт по шагам,
// после ключевых шагов проверяется состояние. sh v06c/build.sh -DSCHED && node v06c/test/mis.mjs [имя]
import path from 'node:path';
import { createRequire } from 'node:module';
import { createVector, savePng, ROOT } from '../tools/v06c.mjs';
const require = createRequire(import.meta.url);
const { BBC } = require(path.join(ROOT, 'tools/oracle/bbc.js'));
const { SCN, K, addr } = require(path.join(ROOT, 'tools/oracle/scenario.js'));
const B = new BBC({ sched: true }).lab;
let bad = 0;
function game() {
  const m = createVector('elite_t'), L = m.L, WS = L.WS, rows = new Array(8).fill(0); let mod = 0, idx = 0;
  const g = {
    m, L,
    rd: (a, n = 1) => { const at = typeof a === 'number' ? a : (a in L ? L[a] : WS + addr(B, a)); const v = Array.from(m.mem().subarray(at, at + n)); return n === 1 ? v[0] : v; },
    poke: (map) => { for (const [a, v] of Object.entries(map)) m.wr(a in L && !(a.split('+')[0] in B) ? L[a] : WS + addr(B, a), v); },
    key: (code, down) => { let i = m.rd(L.kb_rev + code); if (i === 255) throw new Error('нет клавиши &' + code.toString(16));
      if (i & 0x80) { const bit = 1 << (i & 7); mod = down ? mod | bit : mod & ~bit; m.wr(L.kb_mod, [mod]); return; }
      if (i & 0x40) { i &= 63; mod = down ? mod | 0x20 : mod & ~0x20; m.wr(L.kb_mod, [mod]); }
      if (down) rows[i >> 3] |= 1 << (i & 7); else rows[i >> 3] &= ~(1 << (i & 7)); m.wr(L.kb_rows, rows); },
    // идти до любой из меток; вернуть имя достигнутой
    to: (labels, max = 6e7) => { const at = new Map(labels.map((n) => [L[n], n])); let n = 0;
      do { m.cpu.instruction(); if (m.cpu.last_opcode === 0xd3) m.io.commit(); if (++n > max) throw new Error(`не дошли до ${labels} за ${max} команд, PC=${(m.cpu.pc & 0xffff).toString(16)}`); } while (!at.has(m.cpu.pc & 0xffff));
      return at.get(m.cpu.pc & 0xffff); },
    tick: (k) => { for (let f = 0; f < k; f++) { m.wr('DL', [30]); const la = m.rd('LASCT'); if (la) m.wr('LASCT', [la - 1]); } },
    pass: (n = 1, k = 3, label = 'MLOOP') => { for (let i = 0; i < n; i++, idx++) { g.to([label]); g.tick(k); } },
    steps: (list) => { for (const [label, n, down = [], up = [], k = 2, poke] of list) { if (poke) g.poke(poke); down.forEach((c) => g.key(c, true)); up.forEach((c) => g.key(c, false)); g.pass(n, k, { t: 'tt217_t', t2: 'tt217_t2' }[label] || label); } },
    hit: (code, n = 2, k = 3) => { g.key(code, true); g.pass(n, k); g.key(code, false); },
    // ответ на вопрос: дождаться ожидания клавиши, нажать, дойти до главного цикла
    answer: (code) => { g.to(['tt217_t2']); g.key(code, true); g.to(['MLOOP']); g.tick(2); g.key(code, false); g.pass(2, 2); },
    viewBits: () => { const mem = m.mem(); let c = 0; for (let col = 1; col < 31; col++) for (let y = 16; y < 176; y++) { let v = mem[0xC000 + col * 256 + 255 - y]; while (v) { c += v & 1; v >>= 1; } } return c; },
    shot: (name) => { const snap = m.mem().slice(0xC000, 0x10000), m2 = createVector('elite'); m2.frame(40); m2.wr(0xC000, snap); m2.cpu.iff = false; m2.frame(1); savePng(m2.bmp(), path.join(ROOT, 'work/v06c', `mis-${name}.png`)); },
    get idx() { return idx; },
  };
  return g;
}
const ok = (cond, what) => { if (!cond) bad++; console.log(`${cond ? 'OK  ' : 'FAIL'} ${what}`); };
const DOCK = SCN.fight.slice(0, 5), LAUNCH = [['MLOOP', 3, [K.F0]], ['MLOOP', 70, [], [K.F0], 3]];
const NEAR = { 'K%': [0, 0, 0, 0, 0, 0, 0, 112, 0] };                     // планета рядом — появится станция
const SLOT = { 'K%+36': [0, 0, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0xE0, 0, 0x60, 0, 0, 0, 0, 0, 0, 0, 0x60, 0, 0] };   // станция щелью к нам
const jump = (g, x, y, n = 92) => { g.poke({ QQ9: [x], QQ10: [y] }); g.hit(K.H); g.pass(n); };
const toStation = (g) => { g.poke(NEAR); g.pass(40); g.poke(SLOT); };

const TESTS = {
  // «Сверхновая»: выдача при прибытии, вопрос на станции, беженцы, прыжок в соседнюю галактику, награда
  nova() {
    const g = game(); g.steps(DOCK); g.poke({ 'QQ20': [5, 0, 3] }); g.steps(LAUNCH);
    g.poke({ TP: [0x80] }); jump(g, 13, 186);
    ok(g.rd('LASER+4') === 1 && g.rd('QQ14') === 0 && g.rd('TP') === 1, `после прыжка миссия выдана: состояние ${g.rd('LASER+4')}, топливо ${g.rd('QQ14')}, флаги ${g.rd('TP')}`);
    toStation(g); g.to(['tt217_t2']);
    ok(g.viewBits() > 300, `на станции вопрос на экране (точек ${g.viewBits()})`); g.shot('nova-ask');
    g.answer(K.Y);
    ok(g.rd('LASER+4') === 0x81 && g.rd('QQ20', 17).every((v) => v === 0) && g.rd('QQ12') === 0xFF, `ответ Y: беженцы на борту, груз сброшен, мы на станции (состояние ${g.rd('LASER+4').toString(16)})`);
    g.poke({ QQ29: [0] }); const r = g.m.call('tnpr', { a: 1 }); ok(r.cf === 1, 'в трюм больше ничего не помещается');
    g.steps(LAUNCH);
    ok(g.rd('LASER+4') === 0x82, 'после взлёта солнце начинает расти');
    g.hit(K.H); g.pass(100);
    ok(g.rd('GCNT') === 1 && g.rd('LASER+4') === 0x80 && g.rd('QQ12') === 0, `прыжок без топлива унёс в соседнюю галактику (галактика ${g.rd('GCNT')}, состояние ${g.rd('LASER+4').toString(16)})`);
    toStation(g); g.to(['tt217_t2']); g.shot('nova-saved');
    g.answer(K.SPACE);
    ok(g.rd('LASER+4') === 0 && g.rd('QQ20+15') === 100 && g.rd('QQ12') === 0xFF, `стыковка в новой галактике: беженцы высажены, награда — камней ${g.rd('QQ20+15')}`);
  },
  // «Сверхновая», отказ: вопрос повторяется; после взлёта без прыжка — гибель от взрыва солнца
  novaDeath() {
    const g = game(); g.steps(DOCK); g.steps(LAUNCH); g.poke({ TP: [0x80] }); jump(g, 13, 186);
    toStation(g); g.answer(K.N);
    ok(g.rd('LASER+4') === 1, 'ответ N: беженцев не взяли, миссия остаётся');
    g.steps(LAUNCH);
    let n = 0, where = 'MLOOP';
    while (where === 'MLOOP' && n < 900) { g.poke({ ENERGY: [255], FSH: [255], ASH: [255], CABTMP: [30] }); where = g.to(['MLOOP', 'death_d2']); g.tick(3); n++; }
    ok(where === 'death_d2' && n > 650 && n < 750, `без прыжка солнце взрывается: гибель на ${n}-м проходе после взлёта`);
  },
};
const only = process.argv[2];
for (const [name, fn] of Object.entries(TESTS)) { if (only && only !== name) continue; console.log(`--- ${name}`); try { fn(); } catch (e) { bad++; console.log('FAIL ' + e.message); } }
console.log(bad ? `ПРОВАЛ: ${bad}` : 'MIS: всё как задумано');
process.exit(bad ? 1 : 0);
