// Магнитофон: файл командира пишется на «ленту» (перепады на выходе с отметками времени в тактах) и читается
// обратно — как есть, с перевёрнутой полярностью, на скорости ±8 %, с испорченным байтом, без сигнала.
// node v06c/test/tape.mjs
import { createVector } from '../tools/v06c.mjs';
const NT = 75, N = NT + 2;
const mk = () => { const m = createVector('elite'); m.frame(40); return m; };
const WSB = (m) => m.L.WS + 0x0B00;
const data = Array.from({ length: N }, (_, i) => (i * 37 + 11) & 0x7F);
// запись
const w = mk(); w.wr(WSB(w), data);
const ev = []; let now = 0;
w.io.ontapeoutchange = (b) => { if (!ev.length || ev.at(-1)[1] !== b) ev.push([now, b]); };
const rs = w.call('QUS1', { a: 0, tick: (c) => { now = c; } }, 5e7);
const secs = rs.cycles / 3e6;
console.log(`запись: ${ev.length} перепадов, ${secs.toFixed(2)} с, бит ${(ev[20][0] - ev[18][0])} тактов (${(3e6 / (ev[20][0] - ev[18][0])).toFixed(0)} бит/с)`);
const levelAt = (t) => { let lo = 0, hi = ev.length - 1; if (t < ev[0][0]) return 0; while (lo < hi) { const mid = (lo + hi + 1) >> 1; if (ev[mid][0] <= t) lo = mid; else hi = mid - 1; } return ev[lo][1]; };
let bad = 0;
function read(name, { inv = false, speed = 1, corrupt = false, silent = false, start = 200000, slot = false, want }) {
  const m = mk(); m.wr(WSB(m), new Array(N).fill(0x55));
  if (slot) { m.wr('save_slot', data.map((v) => v ^ 1)); m.wr('save_used', [1]); }
  let t = 0;
  const gap = corrupt ? ev[Math.floor(ev.length * 0.97)][0] : -1;      // «выпадение» ленты на 3 мс внутри данных
  m.io.tape_player = { get sample() { if (silent) return 0; const tt = (t - start) * speed; if (corrupt && tt > gap && tt < gap + 9000) return 0; return levelAt(tt) ^ (inv ? 1 : 0); } };
  const r = m.call('QUS1', { a: 0xFF, tick: (c) => { t = c; } }, 2e8);
  const got = Array.from(m.mem().subarray(WSB(m), WSB(m) + N));
  const exp = want === 'tape' ? data : want === 'slot' ? data.map((v) => v ^ 1) : new Array(N).fill(0x55);
  const ok = got.every((v, i) => v === exp[i]);
  if (!ok) bad++;
  console.log(`${ok ? 'OK  ' : 'FAIL'} ${name}: ${(r.cycles / 3e6).toFixed(1)} с, в &0B00 — ${want === 'tape' ? 'блок с ленты' : want === 'slot' ? 'сохранение из памяти' : 'без изменений'}${ok ? '' : ' — НЕ ТАК: ' + got.slice(0, 8)}`);
}
read('чтение как записано', { want: 'tape' });
read('лента пущена с середины пилота', { start: -4e6, want: 'tape' });
read('перевёрнутая полярность', { inv: true, want: 'tape' });
read('лента быстрее на 8 %', { speed: 1.08, want: 'tape' });
read('лента медленнее на 8 %', { speed: 0.92, want: 'tape' });
read('выпадение сигнала в блоке, памяти нет', { corrupt: true, want: 'none' });
read('выпадение сигнала в блоке, в памяти есть сохранение', { corrupt: true, slot: true, want: 'slot' });
read('нет сигнала, памяти нет', { silent: true, want: 'none' });
read('нет сигнала, в памяти есть сохранение', { silent: true, slot: true, want: 'slot' });
console.log(bad ? `ПРОВАЛ: ${bad}` : 'TAPE: всё как задумано');
process.exit(bad ? 1 : 0);
