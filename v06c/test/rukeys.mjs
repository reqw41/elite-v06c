// Полёт под русскую клавиатуру Вектора (обычный образ, fly_keys в sys.asm, таблицы — tools/convert/keys.py):
// в полёте клавиша Вектора нажимает клавишу BBC своего действия, клавиши, чьё действие ушло, гаснут; на экранах
// с текстом и на паузе и до первого прохода в полёте (fly_on = 0) матрица — как есть. Сверяется kb_rows после кадра. node v06c/test/rukeys.mjs
import { createVector } from '../tools/v06c.mjs';
const m = createVector('elite'); m.frame(30);
const L = m.L;
// джойстик — в покое: в эмуляторе порт 0Eh — ещё и стрелки и пробел его клавиатуры (джойстик проверяет joy.mjs)
{ const r6 = m.io.input(6), rE = m.io.input(0x0E), in0 = m.io.input.bind(m.io); m.io.input = (port) => (port === 6 ? r6 : port === 0x0E ? rE : in0(port)); }
const rows = () => Array.from(m.mem().subarray(L.kb_rows, L.kb_rows + 8));
const BBC = { ',': 0x66, '.': 0x67, S: 0x51, X: 0x42, A: 0x41, SPACE: 0x62, '/': 0x68, TAB: 0x60, ESCAPE: 0x70, C: 0x52, P: 0x37,
  T: 0x23, M: 0x65, U: 0x35, J: 0x45, H: 0x54, Y: 0x44, E: 0x22, F1: 0x20, COPY: 0x69, Q: 0x10, B: 0x64, K: 0x46, R: 0x33, G: 0x53, O: 0x36 };
const bbcKey = (n) => { const i = m.rd(L.kb_rev + BBC[n]); return [i >> 3, 1 << (i & 7)]; };   // где клавиша BBC на Векторе
// клавиши Вектора: строка, бит (ROWS в keys.py)
const VK = { '←': [0, 0x10], '↑': [0, 0x20], '→': [0, 0x40], '↓': [0, 0x80], 'ТАБ': [0, 0x01], 'АР2': [1, 0x04], 'СТР': [1, 0x02], 'F1': [1, 0x08],
  'Пробел': [7, 0x80], 'Я': [6, 0x02], 'Б': [4, 0x04], 'К': [5, 0x08], 'А': [4, 0x02], 'О': [5, 0x80], 'Ц': [4, 0x08], 'Р': [6, 0x04],
  'С': [6, 0x08], 'П': [6, 0x01], 'Г': [4, 0x80], 'М': [5, 0x20], 'Е': [4, 0x20], ',': [3, 0x10], '.': [3, 0x40], 'Ь': [7, 0x01],
  '/': [3, 0x80], 'Т': [6, 0x10], 'У': [6, 0x20], 'Й': [5, 0x04], 'Х': [5, 0x01], 'Ы': [7, 0x02] };
// в полёте: клавиша Вектора -> клавиша BBC (null — гаснет)
const FLY = { '←': ',', '→': '.', '↑': 'S', '↓': 'X', 'Пробел': 'A', 'Я': 'SPACE', 'ТАБ': '/', 'Б': 'TAB', 'К': 'ESCAPE', 'А': 'C', 'О': 'P',
  'Ц': 'T', 'Р': 'M', 'С': 'U', 'П': 'J', 'Г': 'H', 'М': 'Y', 'Е': 'E', 'F1': 'F1', 'СТР': 'COPY',
  ',': null, '.': null, 'Ь': null, '/': null, 'Т': null, 'У': null, 'Й': null, 'Х': null, 'Ы': null, 'АР2': null };
let bad = 0;
const press = (keys, view, off) => {
  for (const k of keys) m.key(...VK[k], true);
  m.wr('QQ11', [view]); m.wr('fly_on', [off ? 0 : 1]); m.frame(1); m.wr('QQ11', [view]); m.wr('fly_on', [off ? 0 : 1]); m.frame(1);
  const r = rows(); for (const k of keys) m.key(...VK[k], false); m.frame(1); return r;
};
const check = (what, keys, view, off, want) => {
  const r = press(keys, view, off), exp = new Array(8).fill(0);
  for (const w of want) { const [row, mask] = w in BBC ? bbcKey(w) : VK[w]; exp[row] |= mask; }
  const ok = r.every((v, i) => v === exp[i]); if (!ok) bad++;
  console.log(`${ok ? 'OK  ' : 'FAIL'} ${what}${ok ? '' : ' — в kb_rows ' + r + ', ждали ' + exp}`);
};
for (const [k, b] of Object.entries(FLY)) check(`полёт: ${k} -> ${b ?? 'ничего'}`, [k], 0, 0, b ? [b] : []);
for (const k of Object.keys(FLY)) check(`экран с текстом: ${k} как есть`, [k], 8, 0, [k]);
for (const k of ['Я', 'С', 'А', 'АР2', 'Ь', '↑']) check(`пауза: ${k} как есть`, [k], 0, 1, [k]);
check('полёт: ← ↑ Пробел Я вместе', ['←', '↑', 'Пробел', 'Я'], 0, 0, [',', 'S', 'A', 'SPACE']);
check('полёт: Р и М вместе — пуск и маскировка, без цепочек', ['Р', 'М'], 0, 0, ['M', 'Y']);
check('полёт: С и ↑ вместе — снять и нос вниз', ['С', '↑'], 0, 0, ['U', 'S']);
// fly_keys на случайных матрицах против смысла таблиц (keys.py): строка = (строка И fly_keep) ИЛИ замены по fly_map
// (номер клавиши там — строка · 8 + 7 − бит). На входе матрица и в kb_rows, и в fly_raw (так её кладёт прерывание кадра;
// с 19.10 перевод зовётся только при перемене матрицы, своей памяти у fly_keys нет). Каждая матрица переводится
// дважды — результат тот же. Чаще одна-две клавиши, иногда много.
{
  const keep = Array.from({ length: 8 }, (_, i) => m.rd(L.fly_keep + i)), map = [];
  for (let i = 0; i < 2 * 17; i += 2) map.push([m.rd(L.fly_map + i), m.rd(L.fly_map + i + 1)]);
  let seed = 12345; const rnd = () => (seed = (seed * 1103515245 + 12345) >>> 0) >>> 16;
  let fails = 0, cyc = [0, 0], cnt = [0, 0], prev = null;
  for (let n = 0; n < 20000; n++) {
    const rows = new Array(8).fill(0), k = n % 4 === 3 ? rnd() % 20 : rnd() % 3;
    for (let j = 0; j < k; j++) rows[rnd() & 7] |= 1 << (rnd() & 7);
    const exp = rows.map((v, i) => v & keep[i]);
    for (const [a, b] of map) if (rows[a >> 3] & (1 << (7 - (a & 7)))) exp[b >> 3] |= 1 << (7 - (b & 7));
    const kb = () => Array.from({ length: 8 }, (_, i) => m.rd(L.kb_rows + i));
    const r = m.call('fly_keys', { mem: { kb_rows: rows, fly_raw: rows } }), got = kb();
    const r2 = m.call('fly_keys', { mem: { kb_rows: rows, fly_raw: rows } }), got2 = kb();
    if (got.some((v, i) => v !== exp[i]) || got2.some((v, i) => v !== exp[i])) { if (fails++ < 5) console.log(`FAIL fly_keys: ${rows} -> ${got} / повтор ${got2}, ждали ${exp}`); }
    const changed = n === 0 || prev.some((v, i) => v !== rows[i]); prev = rows;
    if (changed) { cyc[0] += r.cycles; cnt[0]++; } cyc[1] += r2.cycles; cnt[1]++;
  }
  if (fails) bad++;
  console.log(`${fails ? 'FAIL' : 'OK  '} fly_keys на 20000 матрицах; тактов: матрица сменилась ${(cyc[0] / cnt[0]).toFixed(0)}, та же ${(cyc[1] / cnt[1]).toFixed(0)}`);
}
console.log(bad ? `ПРОВАЛ: ${bad}` : 'RUKEYS: всё как задумано');
process.exit(bad ? 1 : 0);
