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
// перед записью — подсказка и ожидание клавиши (TT217); в тесте ожидание перехвачено: отмечается и сразу кончается
let waited = 0;
const rs = w.call('QUS1', { a: 0, tick: (c) => { now = c; if ((w.cpu.pc & 0xffff) === w.L.TT217) { waited = c; const sp = w.cpu.sp & 0xffff; w.cpu.pc = w.rd(sp) | (w.rd(sp + 1) << 8); w.cpu.sp = (sp + 2) & 0xffff; } } }, 5e7);
const secs = (rs.cycles - ev[0][0]) / 3e6;
if (!waited || ev[0][0] < waited) { console.log('FAIL запись началась, не дожидаясь клавиши'); process.exitCode = 1; }
else console.log('OK   запись начинается после подсказки и ожидания клавиши');
console.log(`запись: ${ev.length} перепадов, ${secs.toFixed(2)} с, бит ${(ev[20][0] - ev[18][0])} тактов (${(3e6 / (ev[20][0] - ev[18][0])).toFixed(0)} бит/с)`);
const levelAt = (t) => { let lo = 0, hi = ev.length - 1; if (t < ev[0][0]) return 0; while (lo < hi) { const mid = (lo + hi + 1) >> 1; if (ev[mid][0] <= t) lo = mid; else hi = mid - 1; } return ev[lo][1]; };
let bad = 0;
const T0 = ev[0][0];           // начало записи на «ленте»
function read(name, { inv = false, speed = 1, corrupt = false, silent = false, start = 200000, slot = false, want, key = null, maxSec = 0 }) {
  const m = mk(); m.wr(WSB(m), new Array(N).fill(0x55));
  if (slot) { m.wr('save_slot', data.map((v) => v ^ 1)); m.wr('save_used', [1]); }
  let t = 0;
  const gap = corrupt ? ev[Math.floor(ev.length * 0.97)][0] : -1;      // «выпадение» ленты на 3 мс внутри данных
  m.io.tape_player = { get sample() { if (silent) return 0; const tt = (t - start) * speed + T0; if (corrupt && tt > gap && tt < gap + 9000) return 0; return levelAt(tt) ^ (inv ? 1 : 0); } };
  const r = m.call('QUS1', { a: 0xFF, tick: (c) => { t = c; if (key && c > key.at && !key.done) { key.done = true; if (key.ss) m.keyboard.ss = true; else m.key(7, 0x80, true); } } }, 2e8);
  const got = Array.from(m.mem().subarray(WSB(m), WSB(m) + N));
  const exp = want === 'tape' ? data : [0xFF, ...new Array(N - 1).fill(0x55)];      // не прочитано: FFh в первом байте — «файл негодный», остальное не тронуто
  const ok = got.every((v, i) => v === exp[i]) && (!maxSec || r.cycles / 3e6 < maxSec);
  if (!ok) bad++;
  console.log(`${ok ? 'OK  ' : 'FAIL'} ${name}: ${(r.cycles / 3e6).toFixed(1)} с, в &0B00 — ${want === 'tape' ? 'блок с ленты' : 'файл помечен негодным'}${ok ? '' : ' — НЕ ТАК: ' + got.slice(0, 8)}`);
}
read('чтение как записано', { want: 'tape' });
read('лента пущена с середины пилота', { start: -4e6, want: 'tape' });
read('перевёрнутая полярность', { inv: true, want: 'tape' });
read('лента быстрее на 8 %', { speed: 1.08, want: 'tape' });
read('лента медленнее на 8 %', { speed: 0.92, want: 'tape' });
read('выпадение сигнала в блоке', { corrupt: true, want: 'none' });
read('нет сигнала', { silent: true, want: 'none' });
read('нет сигнала, через 2 с нажат пробел — ожидание прервано', { silent: true, key: { at: 6e6 }, maxSec: 2.2, want: 'none' });
read('нет сигнала, через 1 с нажата СС — ожидание прервано', { silent: true, key: { at: 3e6, ss: true }, maxSec: 1.2, want: 'none' });
read('лента идёт, но пробел нажат заранее — чтение отменено', { key: { at: 1 }, maxSec: 0.5, want: 'none' });
// В игре: заставка, Y, имя, ВК — ожидание ленты; пробел — снова вопрос «Load New Commander (Y/N)?», командир прежний;
// затем N и пробел — игра с прежним командиром.
{
  const g = createVector('elite'), L = g.L, K = { Y: [7, 0x02], N: [5, 0x40], SPACE: [7, 0x80], VK: [0, 0x04], B: [4, 0x04], O: [5, 0x80] };
  const press = (k, n = 12) => { g.key(K[k][0], K[k][1], true); g.frame(n); g.key(K[k][0], K[k][1], false); g.frame(8); };
  const cmdr = () => String.fromCharCode(...Array.from({ length: 7 }, (_, i) => g.rd(L.NA_ + i))).replace(/\r.*/, '');
  g.frame(300); press('Y'); g.frame(60); press('B'); press('O'); press('VK'); g.frame(60);
  const waiting = g.cpu.iff === false || true; const f0 = g.frames;
  press('SPACE'); g.frame(250);
  const name1 = cmdr();
  press('N'); g.frame(200); press('SPACE'); g.frame(200);
  const docked = g.rd(L.QQ12) === 0xFF, cash = [0, 1, 2, 3].reduce((q, i) => q * 256 + g.rd(L.CASH + i), 0);
  const ok = name1 === 'JAMESON' && docked && cash === 1000;
  if (!ok) bad++;
  console.log(`${ok ? 'OK  ' : 'FAIL'} в игре: загрузка отменена пробелом — командир ${name1}, после N и пробела мы на станции (${docked}), денег ${cash / 10} Cr`);
}
console.log(bad ? `ПРОВАЛ: ${bad}` : 'TAPE: всё как задумано');
process.exit(bad ? 1 : 0);
