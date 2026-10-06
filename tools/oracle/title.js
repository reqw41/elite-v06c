// Проверка эталона: запуск до заставки, ответ «N», пробел, снимки экрана в work/oracle/.
// Запуск: node tools/oracle/title.js
'use strict';
const path = require('path');
const { BBC } = require('./bbc.js');

const OUT = path.resolve(__dirname, '../../work/oracle');
const KEY = { N: 0x55, Y: 0x44, SPACE: 0x62 };

function run() {
  const m = new BBC();
  const log = [];
  const snap = (name) => {
    m.png(path.join(OUT, name + '.png'));
    log.push(`${name}: кадр ${m.frames}, такты ${m.cpu.cycles}, экран ${m.hash(0x6000, 0x7f00)}, K% ${m.hash(0x900, 0xd40)}, ` +
      `RAND ${Array.from(m.mem.subarray(m.lab.RAND, m.lab.RAND + 4)).map((v) => v.toString(16).padStart(2, '0')).join('')}`);
  };
  m.runFrames(100); snap('1-title');
  m.press(KEY.N); m.runFrames(100); snap('2-press-space');
  m.press(KEY.SPACE); m.runFrames(100); snap('3-docked');
  log.push(`звуков: ${m.sounds.length}, код до ${m.codeEnd.toString(16)}`);
  return log;
}

const a = run(), b = run();
console.log(a.join('\n'));
console.log(JSON.stringify(a) === JSON.stringify(b) ? 'повтор: совпал' : 'повтор: РАСХОЖДЕНИЕ');
