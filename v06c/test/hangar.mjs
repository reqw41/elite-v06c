// Ангар станции дисковой версии: HALL на Векторе против HALL кода стоянки дисковой BBC (tools/oracle/disc.js).
// Обе стороны получают одно и то же число RAND; на BBC таблица кораблей ангара подменена моделями Вектора (те же
// семь видов в том же порядке), очистка экрана TT66 и переключение печати на ИЛИ (UNWISE) перехвачены — отрезки
// рисуются исключающим ИЛИ, как на Векторе. Сверяется обзор до точки и RAND после вызова (на Векторе — прежний).
// sh v06c/build.sh && node v06c/test/hangar.mjs [случаев = 300]
import path from 'node:path';
import { createRequire } from 'node:module';
import { createVector, savePng, ROOT } from '../tools/v06c.mjs';
import { bbcView, vecView, firstDiff } from '../tools/screen.mjs';
const require = createRequire(import.meta.url);
const { DiscCode } = require(path.join(ROOT, 'tools/oracle/disc.js'));
const N = +(process.argv[2] || 300);
const d = new DiscCode('docked'), m = createVector('elite'), L = m.L, cpu = m.cpu;
m.frame(40);
let bad = 0; const fail = (s) => { if (++bad <= 8) console.log('FAIL ' + s); };
let rs = 4242; const rnd = () => { rs = (rs * 1103515245 + 12345) >>> 0; return (rs >>> 16) & 255; };
const TYPES = Array.from({ length: 7 }, (_, i) => m.rd(L.hall_ty + i));
const model = (t) => { const a = m.rd16(L.XX21X + 2 * (t - 1)); const nv = m.rd(a + 8), ne = m.rd(a + 9), nf = m.rd(a + 12);
  const end = Math.max(20 + nv, (m.rd(a + 3) | (m.rd(a + 16) << 8)) + 4 * ne, (m.rd(a + 4) | (m.rd(a + 17) << 8)) + nf); return Array.from({ length: end }, (_, i) => m.rd(a + i)); };
const SLOT = [5, 9, 10, 11, 12, 16, 19];                      // места этих видов в таблице XX21 стоянки
const blank = () => { for (let a = 0xC000; a < 0x10000; a++) if ((a & 255) >= 64) m.wr(a, [0]); };
const stat = { one: 0, group: 0, empty: 0 }; let shot = 0;
for (let i = 0; i < N; i++) {
  const rand = [rnd(), rnd(), rnd(), rnd()];
  d.reset();
  let at = 0x8000; TYPES.forEach((t, k) => { const b = model(t); d.poke(at, b); d.poke(d.lab.XX21 + 2 * (SLOT[k] - 1), [at & 255, at >> 8]); at += b.length; });
  d.hooks.set(d.lab.TT66, (o) => { o.cpu.p &= ~1; return true; }); d.hooks.set(d.lab.UNWISE, () => true);
  d.poke('RAND', rand);
  d.call('HALL', {}, 4e7);
  blank(); m.wr('RAND', rand);
  const tick = () => { if ((cpu.pc & 0xffff) !== L.TT66) return; const sp = cpu.sp & 0xffff; cpu.pc = m.rd(sp) | (m.rd(sp + 1) << 8); cpu.sp = (sp + 2) & 0xffff; };
  m.call('HALL', { tick }, 4e7);
  const mem = m.mem(), df = firstDiff(bbcView(d.mem), vecView(mem, 0xC000));
  const group = rand[0] === undefined ? 0 : null;
  let px = 0; for (const b of vecView(mem, 0xC000)) for (let k = 0; k < 8; k++) px += (b >> k) & 1;
  if (df) fail(`случай ${i}, RAND ${rand}: экран — строка ${df.i >> 5}, столбец ${df.i & 31}: BBC ${df.a.toString(2)}, Вектор ${df.b.toString(2)}`);
  const after = [0, 1, 2, 3].map((k) => m.rd(L.RAND + k));
  if (after.join() !== rand.join()) fail(`случай ${i}: RAND после ангара ${after}, был ${rand}`);
  if (px < 1500) fail(`случай ${i}: на экране ${px} точек`);
  if (!df && shot < 3 && (i % 7 === 0)) { cpu.iff = false; m.frame(1); savePng(m.bmp(), path.join(ROOT, `work/v06c/hangar-${shot++}.png`)); }
}
console.log(`HALL: случаев ${N}; снимки work/v06c/hangar-0…2.png`);
// в игре: после стыковки автопилотом ангар показан
console.log(bad ? `ПРОВАЛ: ${bad}` : 'HANGAR: всё совпало');
process.exit(bad ? 1 : 0);
