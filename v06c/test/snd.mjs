// Звук ВИ53: запись в счётчики по кадрам для каждого звука игры. Эталона звука нет — тест проверяет, что звук
// начинается, меняет высоту по огибающей и кончается в срок. node v06c/test/snd.mjs [-v]
import { createVector } from '../tools/v06c.mjs';
const V = process.argv.includes('-v');
const NAMES = { 0: 'лазер', 8: 'попадание в нас', 16: 'взрыв, тон', 24: 'взрыв, шум', 32: 'короткий гудок', 40: 'длинный низкий гудок', 48: 'пуск ракеты',
  56: 'прыжок', 64: 'ECM включён', 72: 'ECM выключен' };
// [счётчик, кадров звучит (0 — только глушит, -1 — без конца), шум?]
const WANT = { 0: [1, 39, 0], 8: [1, 19, 0], 16: [1, 59, 0], 24: [0, 64, 1], 32: [2, 1, 0], 40: [2, 19, 0], 48: [0, 29, 1], 56: [0, 39, 0], 64: [2, -1, 0], 72: [2, 0, 0] };
let bad = 0;
for (const snd of Object.keys(NAMES).map(Number)) {
  const m = createVector('elite'); m.frame(40); m.wr('DNOIZ', [0]);
  const log = []; let frame = 0; const T = m.io.Timer, w0 = T.Write.bind(T);
  T.Write = (addr, v) => { log.push([frame, addr & 3, v]); return w0(addr, v); };
  m.call('NOISE', { a: snd });
  for (frame = 1; frame <= 80; frame++) m.frame(1);
  // делители по кадрам: пары записей (младший, старший) в один счётчик
  const div = {}; const cw = [];
  for (let i = 0; i < log.length; i++) { const [f, a, v] = log[i]; if (a === 3) { cw.push([f, v >> 6]); continue; }
    if (log[i + 1] && log[i + 1][1] === a && log[i + 1][0] === f) { (div[a] ??= []).push([f, v | (log[i + 1][2] << 8)]); i++; } }
  const [ch, frames, noise] = WANT[snd], d = div[ch] || [], hz = d.map(([, x]) => Math.round(1.5e6 / x));
  const stops = cw.filter(([f, c]) => c === ch && f > 0).map(([f]) => f);
  let err = null;
  if (frames === 0) { if (d.length) err = 'звучит, а должен только глушить'; }
  else if (frames < 0) { if (d.length < 79 || stops.length) err = `должен звучать без конца: кадров ${d.length}, остановок ${stops.length}`; }
  else if (d.length !== frames || stops[0] !== frames + 1) err = `кадров ${d.length} (ждали ${frames}), остановка на кадре ${stops[0]} (ждали ${frames + 1})`;
  if (!err && d.length && hz.some((h) => h < 20 || h > 6000)) err = `частота вне слышимого разумного: ${Math.min(...hz)}–${Math.max(...hz)} Гц`;
  if (!err && noise && new Set(hz).size < d.length / 2) err = 'шум не меняется от кадра к кадру';
  if (Object.keys(div).some((k) => +k !== ch)) err = `пишет в чужой счётчик ${Object.keys(div)}`;
  if (err) bad++;
  console.log(`${err ? 'FAIL' : 'OK  '} ${String(snd).padStart(2)} ${NAMES[snd].padEnd(22)} счётчик ${ch}, кадров ${d.length}` + (d.length ? `, ${Math.min(...hz)}–${Math.max(...hz)} Гц` : '') + (err ? ' — ' + err : ''));
  if (V && d.length) console.log('     Гц по кадрам: ' + hz.slice(0, 40).join(' '));
}
// звук не трогает состояние игры: вызов NOISE при выключенном звуке ничего не пишет в счётчики
{ const m = createVector('elite'); m.frame(40); m.wr('DNOIZ', [0xFF]); let n = 0; const T = m.io.Timer, w0 = T.Write.bind(T); T.Write = (a, v) => { n++; return w0(a, v); };
  m.call('NOISE', { a: 16 }); m.frame(10); if (n) bad++; console.log(`${n ? 'FAIL' : 'OK  '} звук выключен (DNOIZ): записей в ВИ53 ${n}`); }
console.log(bad ? `ПРОВАЛ: ${bad}` : 'SND: всё как задумано');
process.exit(bad ? 1 : 0);
