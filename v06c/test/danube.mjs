// Мелодия заставки с Сатурном («Голубой Дунай» в три голоса, v06c/data/danube.asm, проигрыватель mus.asm — в области
// заставки): по кадрам, пока Сатурн ждёт клавишу, — моменты через задержки mus_len, высоты нот в голосах snd_v0–v2,
// голос глушится до своей следующей ноты, после конца — снова с начала; по клавише мелодия замолкает, переходы
// mus_tick, mus_start, mus_stop становятся RET, область обнуляется; на заставках игры и в игре — тишина; заставки
// печатают свои строки. node v06c/test/danube.mjs [образ = elite]
import { createVector } from '../tools/v06c.mjs';
const name = process.argv[2] || 'elite';
const m = createVector(name, { saturn: true }), L = m.L;
let bad = 0; const ok = (c, s) => { if (!c) bad++; console.log(`${c ? 'OK  ' : 'FAIL'} ${s}`); };
if (L.mus_dat === undefined) { console.log('DANUBE: мелодии в этом образе нет (NOMUS) — пропуск'); process.exit(0); }
// слова, которые печатает ex (строки заставок): вызов мелодии в TITLE не должен портить номер строки
const exs = []; { const ins = m.cpu.instruction.bind(m.cpu); m.cpu.instruction = () => { if ((m.cpu.pc & 0xffff) === L.ex) exs.push(m.cpu.regs[7]); return ins(); }; }
// заголовки и ноты: [маска, задержка, [высоты]]
const len = Array.from({ length: 16 }, (_, i) => m.rd(L.mus_len + i));
const hdr = []; for (let a = L.mus_dat; m.rd(a); ) { const h = m.rd(a++), notes = []; for (let v = 0; v < 3; v++) if (h & (1 << v)) notes.push(m.rd(a++)); hdr.push([h & 7, len[(h >> 3) & 15], notes]); }
const rw = (a) => m.rd(a) | (m.rd(a + 1) << 8);
const V = [L.snd_v0, L.snd_v1, L.snd_v2];
// ждём первый заголовок
let f = 0; while ((rw(L.mus_p) === 0 || rw(L.mus_p) === L.mus_dat) && f < 400) { m.frame(1); f++; }   // первый момент разобран
ok(rw(L.mus_p) > L.mus_dat, `мелодия начинается на заставке с Сатурном (кадр ${f})`);
let k = 0, wrong = 0, first = '', notes = 0;
const fail1 = (s) => { if (!wrong++) first = s; };
const check = () => {
  const [mask, d, ps] = hdr[k % hdr.length], [nmask] = hdr[(k + 1) % hdr.length];
  let j = 0;
  for (let v = 0; v < 3; v++) {
    const fr = m.rd(V[v]), p = m.rd(V[v] + 2);
    if (mask & (1 << v)) { notes++; if (p !== ps[j++]) fail1(`момент ${k}, голос ${v}: высота ${p}, ждали ${ps[j - 1]}`); }
    if ((nmask & (1 << v)) && fr > d - 2) fail1(`момент ${k}, голос ${v}: звучит ${fr} кадров, а следующая нота через ${d}`);
  }
};
let prevP = rw(L.mus_p), since = 0;
check();
const total = 2 * hdr.length;
for (let i = 1; i < total; ) {
  m.frame(1); since++;
  const p = rw(L.mus_p);
  if (p !== prevP) {
    const want = hdr[k % hdr.length][1];
    if (since !== want) fail1(`момент ${k}: следующий через ${since} кадров, ждали ${want}`);
    k++; i++; since = 0; prevP = p; check();
  }
  if (since > 200) { fail1('мелодия встала'); break; }
}
ok(!wrong, `${total} моментов подряд (две мелодии по ${hdr.length}, нот ${notes}): задержки, высоты, раздельность${wrong ? ' — ' + first : ''}`);
// пробел — конец заставки с Сатурном: мелодия убрана; дальше заставки игры и игра — без неё
m.key(7, 0x80, true); m.frame(20); m.key(7, 0x80, false); m.frame(100);
const rets = ['mus_tick', 'mus_start', 'mus_stop'].every((n) => m.rd(L[n]) === 0xC9);
let loud = 0; for (const v of V) loud += m.rd(v);
ok(rets && rw(L.mus_p) === 0 && loud === 0, `после Сатурна: переходы — RET ${rets}, указатель ${rw(L.mus_p)}, голоса молчат (${loud})`);
let z = 0; for (let a = L.mt_go; a < L.mus_off + 16; a++) z += m.rd(a); ok(z === 0, `проигрыватель и ноты обнулены вместе с заставкой (сумма байт ${z})`);
m.frame(200); let tick = 0; for (let i = 0; i < 300; i++) { m.frame(1); for (const v of V) tick += m.rd(v); }
ok(tick === 0, `заставка игры без мелодии (звучало кадро-голосов ${tick})`);
m.key(5, 0x40, true); m.frame(20); m.key(5, 0x40, false); m.frame(100);
m.key(7, 0x80, true); m.frame(20); m.key(7, 0x80, false); m.frame(200);
ok(rw(L.mus_p) === 0, `в игре мелодия молчит (указатель ${rw(L.mus_p)})`);
const t1 = exs.indexOf(128), t2 = exs.indexOf(147);
ok(t1 >= 0 && exs.indexOf(148, t1) > t1 && t2 > t1 && exs.indexOf(148, t2) > t2, `строки заставок: слово 128 (загрузить командира) — в ${t1}-м вызове ex, 147 (огонь или пробел) — в ${t2}-м, за каждым — 148 (строка прав)`);
console.log(bad ? `ПРОВАЛ: ${bad}` : 'DANUBE: всё как задумано');
process.exit(bad ? 1 : 0);
