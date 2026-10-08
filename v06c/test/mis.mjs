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
    ok(g.rd('mch_x') === 6 && g.rd('DLY') > 0, 'в полёте показано «FUEL LEAK!»');
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
const spawn = (g, t, z, ai) => { g.m.call('ZINF'); g.poke({ 'INWK+7': [z], 'INWK+32': [ai] }); const r = g.m.call('NWSHP', { a: t }); if (!r.cf) throw new Error('NWSHP: нет места'); };
const full = (g) => g.poke({ ENERGY: [255], FSH: [255], ASH: [255] });
const frin = (g) => g.rd('FRIN', 13);
Object.assign(TESTS, {
  // «Скрывающее устройство»: Asp не виден, сбит лазером — остаётся контейнер, подобран заборником — устройство наше
  cloakHunt() {
    const vis = game(); vis.steps(DOCK); vis.steps(LAUNCH); spawn(vis, 15, 5, 0x80); vis.pass(4); const bitsVis = vis.viewBits();
    const g = game(); g.steps(DOCK); g.steps(LAUNCH); g.poke({ TP: [0x22] }); spawn(g, 17, 5, 0x80); g.pass(4);
    ok(g.viewBits() < bitsVis - 30, `Asp со скрывающим устройством не виден (точек в обзоре ${g.viewBits()} против ${bitsVis} с обычным Asp)`);
    g.key(K.A, true); let n = 0; while (!frin(g).includes(18) && n < 300) { full(g); g.poke({ DELTA: [0] }); g.pass(1); n++; } g.key(K.A, false);
    ok(frin(g).includes(18), `сбит лазером за ${n} проходов — остался контейнер (корабли: ${frin(g).filter((v) => v).join('.')})`);
    n = 0; while (frin(g).includes(17) && n < 120) { g.pass(1); n++; }
    const slot = frin(g).indexOf(18);
    g.poke({ BST: [255], ['K%+' + 36 * slot]: [0, 0, 0, 30, 0, 0x80, 40, 0, 0] }); g.pass(4); const got = g.rd('TP'); n = 0; while (frin(g).includes(18) && n < 120) { g.pass(1); n++; }
    ok((got & 0x28) === 0x08 && !frin(g).includes(18), `контейнер подобран: устройство есть, охота окончена (флаги ${g.rd('TP').toString(16)})`);
  },
  // Скрывающее устройство в деле: противник не стреляет, энергия убывает, при малой энергии устройство выключается
  cloakUse() {
    const run = (cloak) => { const g = game(); g.steps(DOCK); g.steps(LAUNCH); g.poke({ TP: [8] }); spawn(g, 1, 3, 0xFF); g.pass(3);
      if (cloak) g.hit(K.Y, 2); const on = g.rd('cloak_on'); const e0 = g.rd('ENERGY'); g.pass(40); return { g, on, e0 }; };
    const a = run(false), b = run(true);
    ok(a.g.rd('FSH') < 255 && a.on === 0, `без устройства Sidewinder попадает по нам (передний щит ${a.g.rd('FSH')})`);
    ok(b.on === 1 && b.g.rd('FSH') === 255, `с включённым устройством не попадает (щит ${b.g.rd('FSH')})`);
    ok(b.e0 - b.g.rd('ENERGY') >= 35, `энергия убывает: ${b.e0} → ${b.g.rd('ENERGY')}`);
    b.g.poke({ ENERGY: [60] }); b.g.pass(2);
    ok(b.g.rd('cloak_on') === 0, 'при энергии ниже 64 устройство выключается');
  },
  // «Захват станции»: выдача, предложение на станции, глушилка, станция-цель враждебна, сбита ракетой, награда
  station() {
    const g = game(); g.steps(DOCK); g.steps(LAUNCH); g.poke({ TP: [0x83] }); jump(g, 13, 186);
    ok(g.rd('LASER+5') === 1 && g.rd('TP') === 0x07, `после прыжка миссия выдана (состояние ${g.rd('LASER+5')}, флаги ${g.rd('TP').toString(16)})`);
    g.poke({ 'ESCP+1': [7] }); g.m.call('m3_seeds'); const xy = [g.rd('QQ15+3'), g.rd('QQ15+1')]; g.m.call('m3_back');
    ok(xy[0] === 20 && xy[1] === 173, `цель — система номер 7, Лейв: координаты ${xy}`);
    toStation(g); g.to(['tt217_t2']); g.shot('m3-offer');
    g.key(K.Y, true); g.to(['tt217_t']); g.key(K.Y, false); g.to(['tt217_t2']); g.shot('m3-brief'); g.answer(K.SPACE);
    ok(g.rd('LASER+5') === 3 && (g.rd('TP') & 0x10), 'согласились: задание принято, глушилка выдана');
    g.poke({ QQ14: [70] }); g.steps(LAUNCH); jump(g, 20, 173);
    ok(g.rd('LASER+5') === 4, `прилетели в систему цели (состояние ${g.rd('LASER+5')})`);
    g.poke(NEAR); g.pass(40);
    ok(frin(g)[1] === 8 && (g.rd('K%+68') & 0x80), 'станция появилась и враждебна');
    g.poke({ 'K%+36': [0, 0, 0, 0, 0, 0, 0, 6, 0] }); g.hit(K.T, 3); let n = 0; while (g.rd('MSTG') === 0xFF && n < 60) { full(g); g.poke({ 'K%+36': [0, 0, 0, 0, 0, 0, 0, 6, 0] }); g.pass(1); n++; }
    ok(g.rd('MSTG') === 1, `ракета захватила станцию за ${n} проходов`);
    g.hit(K.M, 3); n = 0; while (g.rd('LASER+5') !== 6 && n < 300) { full(g); g.pass(1); n++; }
    ok(g.rd('LASER+5') === 6 && frin(g)[1] !== 8, `станция уничтожена ракетой за ${n} проходов (состояние ${g.rd('LASER+5')})`);
    g.poke({ QQ14: [70] }); jump(g, 13, 186);
    ok(g.rd('LASER+5') === 5, 'после прыжка из системы — ждёт награда');
    toStation(g); g.to(['tt217_t2']); g.shot('m3-award'); g.answer(K.SPACE);
    ok(g.rd('LASER+5') === 0 && g.rd('QQ12') === 0xFF, 'награда вручена, задание закрыто');
  },
});
Object.assign(TESTS, {
  // стыковочный компьютер: в зоне станции клавиша C — сообщение и стыковка
  dockComp() {
    const g = game(); g.steps(DOCK); g.steps(LAUNCH); g.poke({ DKCMP: [255] });
    g.key(0x52, true); let n = 0, seen = false; while (g.rd('QQ12') === 0 && n < 20) { g.to(['MLOOP', 'DELAY']); if (g.rd('mch_x') === 7) seen = true; if ((g.m.cpu.pc & 0xffff) === g.L.MLOOP) g.tick(3); else g.to(['MLOOP']); n++; } g.key(0x52, false);
    ok(seen && g.rd('QQ12') === 0xFF, `показано «DOCKING COMPUTERS ON», мы на станции (проходов ${n})`);
  },
});
Object.assign(TESTS, {
  // поиск системы по названию: на карте F, название, ВК — цель прыжка переставлена; несуществующее — «NOT FOUND»
  find() {
    const g = game(); g.steps(DOCK); g.hit(K.F4, 2, 2); g.pass(2, 2);
    const type = (str) => { for (const ch of str) { const c = ch === '\r' ? 0x49 : (() => { for (let k = 0x10; k < 0x80; k++) if (g.m.rd(g.L.kb_ascii + k) === ch.toLowerCase().charCodeAt(0)) return k; throw new Error('нет клавиши ' + ch); })();
      g.to(['tt217_t2']); g.key(c, true); g.to(ch === '\r' ? ['MLOOP'] : ['tt217_t']); g.key(c, false); } g.tick(2); g.pass(2, 2); };
    g.key(K.F, true); g.to(['rline']); g.key(K.F, false); type('ZAONCE\r');
    ok(g.rd('QQ9') === 33 && g.rd('QQ10') === 185 && g.rd('QQ8') === 56, `ZAONCE найдена: цель (${g.rd('QQ9')}, ${g.rd('QQ10')}), расстояние ${g.rd('QQ8') / 10} св. года`); g.shot('find');
    g.key(K.F, true); g.to(['rline']); g.key(K.F, false); type('QQQQ\r');
    ok(g.rd('QQ9') === 33 && g.rd('QQ10') === 185, 'несуществующее название: цель прежняя');
    g.key(K.F, true); g.to(['rline']); g.key(K.F, false); type('LAVE\r');
    ok(g.rd('QQ9') === 20 && g.rd('QQ10') === 173 && g.rd('QQ8') === 0, 'LAVE найдена: цель — своя система');
  },
});
const keys = (g, list) => { for (const c of list) { g.to(['tt217_t2']); g.key(c, true); g.to(['tt217_t', 'MLOOP']); g.key(c, false); } };
const cash = (g) => g.rd('CASH', 4).reduce((a, v) => a * 256 + v, 0);
Object.assign(TESTS, {
  // военный и добывающий лазеры в магазине: цена, зачёт прежнего лазера, «Laser Present»
  lasers() {
    const g = game(); g.steps(DOCK); g.poke({ CASH: [0, 3, 0, 0], tek: [12] });
    g.key(K.F3, true); g.to(['tt217_t']); g.key(K.F3, false); g.to(['tt217_t2']); g.shot('lasers');
    keys(g, [K.K1, K.K3, K.RET, K.K0]);
    ok(g.rd('LASER') === 0x97 && cash(g) === 196608 - 60000 + 4000, `военный лазер вперёд: значение ${g.rd('LASER').toString(16)}, денег ${cash(g) / 10} (6000 уплачено, 400 за импульсный возвращено)`);
    keys(g, [K.K1, K.K4, K.RET, K.K1]);
    ok(g.rd('LASER+1') === 50 && cash(g) === 140608 - 8000, `добывающий лазер назад: значение ${g.rd('LASER+1')}, денег ${cash(g) / 10}`);
    keys(g, [K.K1, K.K3, K.RET, K.K0]); g.pass(2, 2);
    ok(g.rd('LASER') === 0x97 && cash(g) === 132608 && g.rd('QQ12') === 0xFF, `повторная покупка военного: «Laser Present», деньги не тронуты (${cash(g) / 10})`);
    g.hit(K.F8, 2, 2); g.pass(2, 2); g.shot('lasers-status'); ok(g.viewBits() > 500, 'экран статуса с новыми лазерами печатается');
  },
  // добывающий лазер: астероид даёт обломки, обломок подбирается заборником — минералы
  mining() {
    const g = game(); g.steps(DOCK); g.steps(LAUNCH); g.poke({ LASER: [50, 0, 0, 0], BST: [255], QQ20: new Array(17).fill(0) });
    // обломок появляется на месте астероида; если тот был точно в перекрестии, обломок гибнет от того же выстрела
    const alive = () => frin(g).findIndex((t, i) => t === 20 && !(g.rd('K%+' + (36 * i + 31)) & 0xA0));
    let tries = 0, slot = -1, seen = 0;
    while (slot < 0 && tries < 20) { tries++; spawn(g, 10, 3, 0); g.poke({ ['K%+' + 36 * frin(g).indexOf(10)]: [40, 0, 0, 30, 0, 0] });   // не по центру прицела: в астероид попадаем, обломки остаются в стороне
      g.key(K.A, true); let n = 0;
      while (frin(g).includes(10) && !frin(g).includes(20) && n < 200) { full(g); g.poke({ DELTA: [0], GNTMP: [0] }); g.pass(1); n++; } g.key(K.A, false);
      if (frin(g).includes(20)) seen++; slot = alive(); if (slot < 0) { let k = 0; while (frin(g).slice(2).some((v) => v) && k < 200) { g.pass(1); k++; } } }
    ok(seen > 0 && slot >= 0, `астероид разбит добывающим лазером — есть обломки (попыток ${tries}, с обломками ${seen}; объекты: ${frin(g).filter((v) => v).join('.')})`);
    g.poke({ ['K%+' + 36 * slot]: [0, 0, 0, 30, 0, 0x80, 40, 0, 0] }); g.pass(4);
    ok(g.rd('QQ20+12') >= 1, `обломок подобран: минералов в трюме ${g.rd('QQ20+12')} (трюм ${g.rd('QQ20', 17)}, объекты ${frin(g).filter((v) => v).join('.')}, место ${slot}, щит ${g.rd('FSH')})`);
  },
  // миссия 1 дисковой версии: «Констриктора» не берёт обычный лазер, берёт военный; гибель отмечается в байте миссий
  constrictor() {
    const g = game(); g.steps(DOCK); g.steps(LAUNCH); g.poke({ LASER: [15, 0, 0, 0], 'ESCP+2': [1] });
    spawn(g, 31, 3, 0); const slot = frin(g).indexOf(31), e = 'K%+' + (36 * slot + 35), e0 = g.rd(e), t0 = g.rd('TALLY');
    const fire = (n) => { g.key(K.A, true); let k = 0; while (frin(g).includes(31) && k < n) { full(g); g.poke({ DELTA: [0], GNTMP: [0], ['K%+' + 36 * slot]: [0, 0, 0, 0, 0, 0] }); g.pass(1); k++; } g.key(K.A, false); return k; };
    fire(80);
    ok(frin(g).includes(31) && g.rd(e) === e0, `импульсный лазер «Констриктора» не берёт: энергия ${g.rd(e)} из ${e0} после 80 проходов огня`);
    g.poke({ LASER: [0x97, 0, 0, 0] }); const k = fire(3000);
    ok(!frin(g).includes(31), `военный лазер уничтожил «Констриктор» за ${k} проходов`);
    ok(g.rd('ESCP+2') === 3 && g.rd('TALLY') === t0 + 1, `гибель отмечена: байт миссий ${g.rd('ESCP+2')}, побед ${g.rd('TALLY')} (было ${t0})`);
  },
});
const only = process.argv[2];
for (const [name, fn] of Object.entries(TESTS)) { if (only && only !== name) continue; console.log(`--- ${name}`); try { fn(); } catch (e) { bad++; console.log('FAIL ' + e.message); } }
console.log(bad ? `ПРОВАЛ: ${bad}` : 'MIS: всё как задумано');
process.exit(bad ? 1 : 0);
