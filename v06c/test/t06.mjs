// T06: арифметика, первая партия — парные тесты 6502 ↔ i8080, время, рост кода.
// node v06c/test/t06.mjs [случаев на процедуру = 3000]
import { makePair } from '../tools/pair.mjs';
const N = +(process.argv[2] || 3000);
const P = makePair(), { B, m } = P;
const sm = (rnd, byte) => byte();                           // байт со знаком в бите 7 — любой
const SPECS = [
  { name: 'MULTU', gen: (r, b) => ({ y: b(), mem: { P: b(), Q: b() } }) },
  { name: 'MU11', gen: (r, b) => ({ x: b() || 1, y: b(), mem: { P: b() } }) },
  { name: 'MU1', gen: (r, b) => ({ x: b(), y: b() }) },
  { name: 'SQUA', gen: (r, b) => ({ a: b(), y: b() }) },
  { name: 'SQUA2', gen: (r, b) => ({ a: b(), y: b() }) },
  { name: 'MLU2', gen: (r, b) => ({ a: b(), y: b(), mem: { Q: b() } }) },
  { name: 'MLU1', gen: (r, b) => { const y = r(20); return { y, mem: { Q: b(), [B.SY + y]: b() } }; } },
  { name: 'MU6', gen: (r, b) => ({ a: b(), x: b(), y: b(), c: r(2) }) },
  { name: 'FMLTU', gen: (r, b) => ({ a: b(), x: b(), y: b(), mem: { Q: b() } }) },
  { name: 'MULT1', gen: (r, b) => ({ a: sm(r, b), y: b(), mem: { Q: r(8) ? sm(r, b) : [0, 128][r(2)] } }) },
  { name: 'MULT12', gen: (r, b) => ({ a: sm(r, b), y: b(), mem: { Q: r(8) ? sm(r, b) : [0, 128][r(2)] } }) },
  { name: 'ADD', gen: (r, b) => (r(5) ? { a: b(), y: b(), mem: { P: b(), S: b(), R: b() } }
    : (() => { const hi = b() & 127, lo = b(); return { a: hi | (r(2) << 7), y: b(), mem: { P: lo, S: hi | (r(2) << 7), R: r(3) ? lo : b() } }; })()) },   // равные модули
  { name: 'MAD', gen: (r, b) => ({ a: b(), y: b(), mem: { Q: b(), S: b(), R: b() } }) },
  { name: 'DVID4', gen: (r, b) => ({ a: b(), y: b(), mem: { Q: b() } }) },
  { name: 'LL28', gen: (r, b) => ({ a: b(), x: b(), y: b(), mem: { Q: b() } }) },
  { name: 'LL28+4', entry: B.LL28 + 4, ventry: 'LL28_4', gen: (r, b) => ({ a: b(), x: b(), y: b(), mem: { Q: b() } }) },
  { name: 'LL5', gen: (r, b) => ({ mem: { R: r(4) ? b() : r(4), Q: b() } }) },
  { name: 'DORND', gen: (r, b) => ({ y: b(), c: r(2), mem: { RAND: [b(), b(), b(), b()] } }) },
  { name: 'DORND2', gen: (r, b) => ({ y: b(), c: r(2), mem: { RAND: [b(), b(), b(), b()] } }) },
];
for (const s of SPECS) P.run({ n: N, ...s });
P.timing();

// Рост кода: байты BBC (метка и длина, из листинга) против блока arith_start..arith_end на Векторе.
const BBC_SIZE = [['SQUA', B.FMLTU2 - B.SQUA, 'SQUA…MU6'], ['FMLTU', 24, 'FMLTU'], ['MULT1', B.TAS3 - B.MULT1, 'MULT1, MULT12'], ['MAD', B.TIS1 - B.MAD, 'MAD, ADD'],
  ['DVID4', B.DVID3B2 - B.DVID4, 'DVID4'], ['LL5', B.LL28 - B.LL5, 'LL5'], ['LL28', B.LL38 - B.LL28, 'LL28'], ['DORND2', 21, 'DORND']];
const b = BBC_SIZE.reduce((s, r) => s + r[1], 0), v = m.L.arith_end - m.L.arith_start, core = m.L.SQUA - m.L.mul8;
console.log(`\nразмер кода: BBC ${b} Б (${BBC_SIZE.map((r) => `${r[2]} ${r[1]}`).join(', ')}) → Вектор ${v} Б (из них развёрнутое ядро умножения mul8 — ${core}): ×${(v / b).toFixed(2)}`);
console.log(P.failed() ? `ПРОВАЛ: ${P.failed()}` : 'T06: всё совпало');
process.exit(P.failed() ? 1 : 0);
