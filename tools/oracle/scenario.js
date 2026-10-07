// Эталонные сценарии по расписанию кадров. Запуск: node tools/oracle/scenario.js [имя] [--write]
// Шаг сценария: [метка, проходов, нажать, отпустить, кадров на проход]. Результат — хеши состояния на каждом
// проходе; с --write пишется tests/golden/<имя>.json, без него сверяется с записанным.
'use strict';
const fs = require('fs');
const path = require('path');
const { BBC } = require('./bbc.js');
const K = { N: 0x55, SPACE: 0x62, F0: 0x20, A: 0x41, S: 0x51, X: 0x42, LT: 0x66, GT: 0x67, H: 0x54, F1: 0x71 };
const SCN = {
  title: [['TLL2', 60, [], [], 1]],
  launch: [['TLL2', 60, [], [], 1], ['TLL2', 1, [K.N]], ['TLL2', 60, [], [K.N], 1], ['MLOOP', 1, [K.SPACE]],
    ['MLOOP', 40, [], [K.SPACE]], ['MLOOP', 3, [K.F0]], ['MLOOP', 120, [], [K.F0], 3], ['MLOOP', 40, [K.SPACE], [], 3],
    ['MLOOP', 40, [K.A, K.S], [K.SPACE], 3], ['MLOOP', 60, [K.LT], [K.A, K.S], 3], ['MLOOP', 100, [], [K.LT], 3]],
};
function run(name) {
  const m = new BBC({ sched: true }), out = [];
  for (const [label, n, down = [], up = [], k = 2] of SCN[name]) {
    down.forEach((c) => m.keys.add(c)); up.forEach((c) => m.keys.delete(c));
    for (let i = 0; i < n; i++) { m.pass(label, k); out.push(Object.values(m.state()).join(' ')); }
  }
  return { m, out };
}
module.exports = { SCN, K, run };
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
