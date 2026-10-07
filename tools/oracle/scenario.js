// Эталонные сценарии по расписанию кадров. Запуск: node tools/oracle/scenario.js [имя] [--write]
// Шаг сценария: [метка, проходов, нажать, отпустить, кадров на проход, записать в память {метка: байты},
// вызвать процедуры [[метка, {a, x, y, c}, записать в память перед вызовом], …]]. Адрес записи — «МЕТКА» или «МЕТКА+n». Результат — хеши состояния на каждом
// проходе; с --write пишется tests/golden/<имя>.json, без него сверяется с записанным.
'use strict';
const fs = require('fs');
const path = require('path');
const { BBC } = require('./bbc.js');
const K = { N: 0x55, SPACE: 0x62, F0: 0x20, A: 0x41, S: 0x51, X: 0x42, LT: 0x66, GT: 0x67, H: 0x54, F1: 0x71, F2: 0x72, F3: 0x73, F4: 0x14, F5: 0x74,
  F6: 0x75, F7: 0x16, F8: 0x76, F9: 0x77, K1: 0x30, K2: 0x31, K3: 0x11, RET: 0x49, Q: 0x10, Y: 0x44, RIGHT: 0x79, LEFT: 0x19, UP: 0x39, DOWN: 0x29, D: 0x32,
  T: 0x23, M: 0x65, E: 0x22, J: 0x45, CTRL: 0x01, ESC: 0x70, K0: 0x27, K4: 0x12, K5: 0x13, K6: 0x34, K7: 0x24, K8: 0x15, K9: 0x26 };
// до стоянки на станции: обе заставки и экран статуса
const DOCK = [['TLL2', 20, [], [], 1], ['TLL2', 1, [K.N]], ['TLL2', 20, [], [K.N], 1], ['MLOOP', 1, [K.SPACE]], ['MLOOP', 5, [], [K.SPACE]]];
// нажать и отпустить клавиши по очереди в ожидании TT217; out — последняя клавиша выводит в главный цикл
const tap = (...ks) => ks.flatMap((k) => [['t', 1, [K[k]]], ['t2', 1, [], [K[k]]]]);
const out = (...ks) => [...tap(...ks.slice(0, -1)), ['MLOOP', 1, [K[ks.at(-1)]]], ['MLOOP', 3, [], [K[ks.at(-1)]]]];
// появление корабля типа t впереди: z_hi = z, байт поведения ai (бит 7 — тактика, бит 6 — враждебен, бит 0 — ECM)
const ship = (t, z, ai) => [['ZINF'], ['NWSHP', { a: t }, { 'INWK+7': [z], 'INWK+32': [ai] }]];
const SCN = {
  title: [['TLL2', 60, [], [], 1]],
  launch: [['TLL2', 60, [], [], 1], ['TLL2', 1, [K.N]], ['TLL2', 60, [], [K.N], 1], ['MLOOP', 1, [K.SPACE]],
    ['MLOOP', 40, [], [K.SPACE]], ['MLOOP', 3, [K.F0]], ['MLOOP', 120, [], [K.F0], 3], ['MLOOP', 40, [K.SPACE], [], 3],
    ['MLOOP', 40, [K.A, K.S], [K.SPACE], 3], ['MLOOP', 60, [K.LT], [K.A, K.S], 3], ['MLOOP', 100, [], [K.LT], 3]],
  // Станция: цены, покупка (2 единицы первого товара, 1 — второго, выход), груз, продажа (первый — да, дальше нет),
  // карты, перекрестие, данные о системе, статус. Метки t и t2 — ожидание клавиши в TT217 (отпущена / нажата).
  trade: [...DOCK, ['MLOOP', 2, [K.F7]], ['MLOOP', 2, [], [K.F7]],
    ['t', 1, [K.F1]], ['t2', 1, [], [K.F1]], ['t', 1, [K.K2]], ['t2', 1, [], [K.K2]], ['t', 1, [K.RET]], ['t2', 1, [], [K.RET]],
    ['t', 1, [K.K1]], ['t2', 1, [], [K.K1]], ['t', 1, [K.RET]], ['t2', 1, [], [K.RET]], ['MLOOP', 1, [K.Q]], ['MLOOP', 3, [], [K.Q]],
    ['MLOOP', 2, [K.F9]], ['MLOOP', 2, [], [K.F9]],
    ['t', 1, [K.F2]], ['t2', 1, [], [K.F2]], ['t', 1, [K.Y]], ['t2', 1, [], [K.Y]], ['MLOOP', 1, [K.N]], ['MLOOP', 3, [], [K.N]],
    ['MLOOP', 2, [K.F4]], ['MLOOP', 2, [], [K.F4]], ['MLOOP', 6, [K.RIGHT]], ['MLOOP', 4, [K.UP], [K.RIGHT]], ['MLOOP', 2, [K.D], [K.UP]], ['MLOOP', 2, [], [K.D]],
    ['MLOOP', 2, [K.F5]], ['MLOOP', 2, [], [K.F5]], ['MLOOP', 5, [K.LEFT]], ['MLOOP', 3, [K.DOWN], [K.LEFT]], ['MLOOP', 2, [K.D], [K.DOWN]], ['MLOOP', 2, [], [K.D]],
    ['MLOOP', 2, [K.F6]], ['MLOOP', 2, [], [K.F6]], ['MLOOP', 2, [K.F8]], ['MLOOP', 3, [], [K.F8]]],
  // Оборудование (f3). На 100 кредитов: ракета, грузовой отсек — «Cash?». Затем денег 19660,8, уровень техники 10,
  // топлива 3,5: отсек, отсек повторно — «Present», ECM, импульсный лазер назад (с неверной клавишей вида),
  // лучевой вперёд (возврат цены импульсного), импульсный вперёд — «Laser Present», остальное по списку, топливо,
  // ракета сверх четырёх — «Present», ноль и число больше списка — выход.
  equip: [...DOCK, ...tap('F3', 'K2', 'RET'), ...out('K3', 'RET'),
    ['MLOOP', 0, [], [], 2, { CASH: [0, 3, 0, 0], tek: [10], QQ14: [35] }],
    ...tap('F3', 'K3', 'RET'), ...out('K3', 'RET'),
    ...tap('F3', 'K4', 'RET', 'K5', 'RET', 'K7', 'K1', 'K6', 'RET', 'K0'), ...out('K5', 'RET', 'K0'),
    ...tap('F3', 'K7', 'RET', 'K8', 'RET', 'K9', 'RET', 'K1', 'K0', 'RET', 'K1', 'K1', 'RET', 'K1', 'K2', 'RET', 'K1', 'RET'), ...out('K2', 'RET'),
    ...tap('F3'), ...out('K0', 'RET'), ...tap('F3'), ...out('K1', 'K3'), ...tap('F3'), ...out('K9', 'RET')],
  // Бой и гибель. Взлёт; Sidewinder стреляет по нам, сбиваем лазером (награда); Mamba — наводим и пускаем ракету;
  // раненая Cobra пускает ракету в нас — гасим её ECM, Cobra таранит и взрывается; при энергии 12 без щитов
  // Sidewinder добивает: гибель (85 проходов цикла D2), снова заставка.
  fight: [...DOCK, ['MLOOP', 3, [K.F0]], ['MLOOP', 70, [], [K.F0], 3],
    ['MLOOP', 1, [], [], 3, {}, ship(1, 3, 0xFF)], ['MLOOP', 30, [], [], 3], ['MLOOP', 60, [K.A], [], 3], ['MLOOP', 40, [], [K.A], 3],
    ['MLOOP', 1, [], [], 3, {}, ship(3, 6, 0xC0)], ['MLOOP', 3, [K.T], [], 3], ['MLOOP', 25, [], [K.T], 3], ['MLOOP', 3, [K.M], [], 3], ['MLOOP', 80, [], [K.M], 3],
    ['MLOOP', 1, [], [], 3, { ECM: [255] }, ship(5, 8, 0xFF)], ['MLOOP', 139, [], [], 3, { 'K%+107': [40] }],
    ['MLOOP', 3, [K.E], [], 3], ['MLOOP', 95, [], [K.E], 3],
    ['MLOOP', 1, [], [], 3, { ENERGY: [12], FSH: [0], ASH: [0] }, ship(1, 3, 0xFF)], ['MLOOP', 11, [], [], 3],
    ['D2', 85, [], [], 3], ['TLL2', 15, [], [], 1]],
  // Прыжки. Взлёт; J у станции — отказ; цель — система (13, 186) в 3,6 св. года: H, отсчёт, прибытие; J — прыжки
  // внутри системы, пока не появятся корабли; цель — обратно, топлива не хватает: «RANGE?»; с полным баком и
  // PATG + CTRL — сбой прыжка, таргоиды; галактический прыжок (CTRL + H); спасательная капсула — на станцию.
  jump: [...DOCK, ['MLOOP', 3, [K.F0]], ['MLOOP', 70, [], [K.F0], 3],
    ['MLOOP', 3, [K.J], [], 3], ['MLOOP', 3, [], [K.J], 3],
    ['MLOOP', 1, [], [], 3, { QQ9: [13], QQ10: [186] }], ['MLOOP', 2, [K.H], [], 3], ['MLOOP', 140, [], [K.H], 3],
    ['MLOOP', 40, [K.J], [], 3], ['MLOOP', 5, [], [K.J], 3],
    ['MLOOP', 1, [], [], 3, { QQ9: [20], QQ10: [173] }], ['MLOOP', 2, [K.H], [], 3], ['MLOOP', 25, [], [K.H], 3],
    ['MLOOP', 1, [], [], 3, { QQ14: [70], PATG: [255] }], ['MLOOP', 2, [K.H], [], 3], ['MLOOP', 78, [], [K.H], 3],
    ['MLOOP', 10, [K.CTRL], [], 3], ['MLOOP', 30, [], [K.CTRL], 3],
    ['MLOOP', 1, [], [], 3, { GHYP: [255], PATG: [0] }], ['MLOOP', 2, [K.CTRL, K.H], [], 3], ['MLOOP', 100, [], [K.CTRL, K.H], 3],
    ['MLOOP', 1, [], [], 3, { ESCP: [255] }], ['MLOOP', 2, [K.ESC], [], 3], ['MLOOP', 6, [], [K.ESC], 3]],
};
// адрес BBC по «МЕТКА» или «МЕТКА+n»
const addr = (lab, k) => { const [n, o] = k.split('+'); if (!(n in lab)) throw new Error('нет метки ' + n); return lab[n] + (+o || 0); };
// записи в память и вызовы шага — для эталона; стенд Вектора делает то же самое у себя (v06c/test/t27.mjs)
function prep(m, step) {
  const [, , , , , poke, calls] = step;
  for (const [a, v] of Object.entries(poke || {})) m.mem.set(v, addr(m.lab, a));
  for (const [label, regs = {}, mem = {}] of calls || []) { for (const [a, v] of Object.entries(mem)) m.mem.set(v, addr(m.lab, a)); m.call(label, regs); }
}
function run(name) {
  const m = new BBC({ sched: true }), out = [];
  for (const step of SCN[name]) {
    const [label, n, down = [], up = [], k = 2] = step;
    prep(m, step);
    down.forEach((c) => m.keys.add(c)); up.forEach((c) => m.keys.delete(c));
    for (let i = 0; i < n; i++) { m.pass(label, k); out.push(Object.values(m.state()).join(' ')); }
  }
  return { m, out };
}
module.exports = { SCN, K, run, prep, addr };
if (require.main === module) {
  const name = process.argv[2] || 'launch', file = path.resolve(__dirname, '../../tests/golden', name + '.json');
  const { m, out } = run(name);
  m.png(path.resolve(__dirname, '../../work/oracle', 'scn-' + name + '.png'));
  const uniq = new Set(out).size;
  if (process.argv.includes('--write')) { fs.writeFileSync(file, JSON.stringify(out, null, 0).replace(/","/g, '",\n"')); console.log(`записано ${out.length} проходов (${uniq} разных состояний), тактов 6502 ${m.cpu.cycles}, звуков ${m.sounds.length}`); }
  else {
    const want = JSON.parse(fs.readFileSync(file, 'utf8'));
    const bad = out.findIndex((v, i) => v !== want[i]);
    console.log(bad < 0 && out.length === want.length ? `${name}: совпало, ${out.length} проходов` : `${name}: РАСХОЖДЕНИЕ с прохода ${bad}`);
    process.exit(bad < 0 ? 0 : 1);
  }
}
