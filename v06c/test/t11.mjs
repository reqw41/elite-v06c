// T11: быстрая сборка (-DFAST) — умножение и деление по логарифмам против процедур версии BBC Elite для второго
// процессора, полным перебором входов. node v06c/test/t11.mjs   (перед этим sh v06c/build.sh -DFAST)
import path from 'node:path';
import { createRequire } from 'node:module';
import { createVector, ROOT } from '../tools/v06c.mjs';
const { SPCode } = createRequire(import.meta.url)(path.join(ROOT, 'tools/oracle/sp.js'));
const m = createVector('elite_fast'), L = m.L, sp = new SPCode(), S = sp.lab;
m.frame(30);
let bad = 0;
const report = (name, n, fail, extra = '') => { console.log(`${fail ? 'FAIL' : 'OK  '} ${name}: ${n} входов${extra}${fail ? ' — ' + fail : ''}`); if (fail) bad++; };

// FMLTU: A = A · Q / 256
{ let fail = null, n = 0, tv = 0, tb = 0, err = 0, maxe = 0;
  for (let a = 0; a < 256 && !fail; a++) for (let q = 0; q < 256 && !fail; q++) {
    const rb = sp.call('FMLTU', { a, x: 0x5A, mem: { Q: q } }), rv = m.call('FMLTU', { a, b: 0x5A, c: 0xA5, mem: { [L.Q]: q } });
    n++; tv += rv.cycles; tb += rb.cycles; const e = Math.abs(rb.a - ((a * q) >> 8)); err += e; maxe = Math.max(maxe, e);
    if (rb.a !== rv.a || rv.b !== 0x5A || rv.c !== 0xA5) fail = `A=${a} Q=${q}: второй процессор ${rb.a}, Вектор ${rv.a}, BC=${rv.bc.toString(16)}`;
  }
  report('FMLTU', n, fail, `; тактов i8080 ${(tv / n).toFixed(0)} (6502 второго процессора ${(tb / n).toFixed(0)}); отличие от точного произведения: в среднем ${(err / n).toFixed(2)}, наибольшее ${maxe}`); }
// LL28: R = 256 · A / Q
{ let fail = null, n = 0, tv = 0, err = 0, maxe = 0;
  for (let a = 0; a < 256 && !fail; a++) for (let q = 0; q < 256 && !fail; q++) {
    const rb = sp.call('LL28', { a, mem: { Q: q } }), rR = sp.mem[S.R], rv = m.call('LL28', { a, c: 0xA5, mem: { [L.Q]: q } }), vR = m.rd('R_');
    n++; tv += rv.cycles; if (a < q) { const e = Math.abs(rR - Math.floor(256 * a / q)); err += e; maxe = Math.max(maxe, e); }
    if (rR !== vR || rb.c !== rv.cf || rv.c !== 0xA5 || (a < q && rv.a !== vR)) fail = `A=${a} Q=${q}: второй процессор R=${rR} C=${rb.c}, Вектор R=${vR} C=${rv.cf} A=${rv.a}`;
  }
  report('LL28', n, fail, `; тактов i8080 ${(tv / n).toFixed(0)}; отличие от точного частного: в среднем ${(err / (n / 2)).toFixed(2)}, наибольшее ${maxe}`); }
// наклон отрезка: li_div(D, E), D <= E, E <> 0 — то же деление; при D = E — 255, при D = 0 — 0
{ let fail = null, n = 0, tv = 0;
  for (let e = 1; e < 256 && !fail; e++) for (let d = 0; d <= e && !fail; d++) {
    let want; if (d === 0) want = 0; else if (d === e) want = 255; else { sp.call('LL28', { a: d, mem: { Q: e } }); want = sp.mem[S.R]; }
    const rv = m.call('li_div', { d, e, c: 0xA5, h: 0x12, l: 0x34 });
    n++; tv += rv.cycles;
    if (rv.a !== want || rv.e !== e || rv.c !== 0xA5 || rv.hl !== 0x1234) fail = `D=${d} E=${e}: ждали ${want}, Вектор ${rv.a}, E=${rv.e} C=${rv.c} HL=${rv.hl.toString(16)}`;
  }
  report('li_div', n, fail, `; тактов i8080 ${(tv / n).toFixed(0)}`); }
console.log(bad ? `ПРОВАЛ: ${bad}` : 'T11: всё совпало');
process.exit(bad ? 1 : 0);
