// Джойстик: нажатия на порте 06h («Джойстик П») становятся нажатиями клавиш в kb_rows; порт 0Eh игра не читает
// (на Турбо+ там мусор) — тест кладёт туда случайные байты, клавиш от них быть не должно. Тест подменяет чтение портов.
// JOY_INJECT=1 — негативный контроль: порт 06h «молчит» (всегда покой), тест обязан покраснеть.
// Порты опрашиваются через кадр (с 19.10), поэтому после смены состояния — несколько кадров. node v06c/test/joy.mjs
import { createVector } from '../tools/v06c.mjs';
const m = createVector('elite'); m.frame(30);
const L = m.L, WS = L.WS;
let p6 = m.io.input(6), pE = m.io.input(0x0E);              // состояние покоя — как при запуске
const rest6 = p6, restE = pE, in0 = m.io.input.bind(m.io);
let seed = 7; const noise = () => (seed = (seed * 1103515245 + 12345) & 0x7fffffff) >> 16 & 255;
const INJ = process.env.JOY_INJECT === '1';
m.io.input = (port) => (port === 6 ? (INJ ? rest6 : p6) : port === 0x0E ? noise() : in0(port));
const rows = () => Array.from(m.mem().subarray(L.kb_rows, L.kb_rows + 8));
const key = (code) => { const i = m.rd(L.kb_rev + code); return [i >> 3, 1 << (i & 7)]; };
const K = { '<': 0x66, '>': 0x67, S: 0x51, X: 0x42, A: 0x41, SPACE: 0x62, LEFT: 0x19, RIGHT: 0x79, UP: 0x39, DOWN: 0x29, RET: 0x49 };
const CASES = [[0x01, '>', 'RIGHT'], [0x02, '<', 'LEFT'], [0x04, 'S', 'UP'], [0x08, 'X', 'DOWN'], [0x40, 'A', 'SPACE'], [0x80, 'SPACE', 'RET']];
let bad = 0;
const check = (what, want) => { const r = rows(), exp = new Array(8).fill(0); for (const k of want) { const [row, mask] = key(K[k]); exp[row] |= mask; }
  const ok = r.every((v, i) => v === exp[i]); if (!ok) bad++; console.log(`${ok ? 'OK  ' : 'FAIL'} ${what}: клавиши ${want.join(', ') || 'нет'}${ok ? '' : ' — в kb_rows ' + r + ', ждали ' + exp}`); };
for (const [port, name] of [[6, 'порт 06h, нажатие нулём'], [6, 'порт 06h, нажатие единицей']]) {
  for (const view of [0, 8]) {
    for (const [bit, fly, scr] of CASES) {
      m.wr('QQ11', [view]);
      const active = name.includes('единицей') ? rest6 | bit : (port === 6 ? rest6 : restE) ^ bit;
      if (port === 6) { p6 = active; pE = restE; } else { pE = active; p6 = rest6; }
      if (name.includes('единицей') && (rest6 & bit)) continue;         // в покое уже единица — случай покрыт первым проходом
      for (let f = 0; f < 4; f++) { m.wr('QQ11', [view]); m.frame(1); }   // заставка игры сама пишет QQ11 — ставим перед каждым кадром
      check(`${name}, ${view ? 'экран с текстом' : 'полёт'}, бит ${bit.toString(16)}`, [view ? scr : fly]);
    }
  }
}
p6 = rest6; pE = restE; m.frame(2); check('покой', []);
p6 = rest6 ^ 0x45; m.wr('QQ11', [0]); m.frame(2); check('вправо + вверх + огонь в полёте', ['>', 'S', 'A']);
p6 = rest6 ^ 0x30; m.frame(2); check('биты 4 и 5 не в счёт', []);
console.log(bad ? `ПРОВАЛ: ${bad}` : 'JOY: всё как задумано');
process.exit(bad ? 1 : 0);
