// Флаги поведения кораблей (как NEWB дисковой версии; только обычный образ; проверка по смыслу):
// 1. новый корабль получает флаги своего типа, торговец — заданные при появлении; 2. при удалении корабля флаги
// следующих мест сдвигаются; 3. ветви тактики по флагам; 4. нападение на мирного злит станцию; 5. в игре торговец
// с флагом «стыкуется» долетает до станции и исчезает в ней.
// sh v06c/build.sh && node v06c/test/newb.mjs
import { createVector } from '../tools/v06c.mjs';
let bad = 0; const ok = (c, s) => { if (!c) bad++; console.log(`${c ? 'OK  ' : 'FAIL'} ${s}`); };
const m = createVector('elite'), L = m.L, cpu = m.cpu; m.frame(60);
const ret = () => { const sp = cpu.sp & 0xffff; cpu.pc = m.rd(sp) | (m.rd(sp + 1) << 8); cpu.sp = (sp + 2) & 0xffff; };
const frin = () => Array.from({ length: 13 }, (_, i) => m.rd(L.FRIN + i));
const flags = () => Array.from({ length: 13 }, (_, i) => m.rd(L.newb + i));
const slsp = [m.rd(L.SLSP), m.rd(L.SLSP + 1)];
const clear = () => { m.wr(L.FRIN, new Array(13).fill(0)); m.wr(L.FRIN, [128, 8]); m.wr(L.SLSP, slsp); m.wr(L.newb, new Array(13).fill(0)); m.wr(L.nb_pre, [0]); };
const spawn = (t, pre = 0) => { m.call('ZINF'); m.wr(L.INWK + 7, [5]); m.wr(L.nb_pre, [pre]); const r = m.call('NWSHP', { a: t }); return r.cf ? frin().lastIndexOf(t) : -1; };

// 1. флаги нового корабля
{ const want = { 1: 0x0C, 2: 0x42, 3: 0x0C, 7: 0x20, 11: 0, 13: 1, 16: 0x02, 27: 0x20, 28: 0x21, 29: 0x21, 30: 0x61, 31: 0x04 }; let okAll = true; const seen = [];
  for (const [t, f] of Object.entries(want)) { clear(); const s = spawn(+t); const got = m.rd(L.newb + s); seen.push(`${t}:${got.toString(16)}`); if (s < 0 || got !== f) okAll = false; }
  ok(okAll, `флаги по типу при появлении — ${seen.join(' ')}`);
  clear(); const s = spawn(4, 0xB0); ok(m.rd(L.newb + s) === 0x30 && m.rd(L.nb_pre) === 0, `Python-торговец с заданными флагами: ${m.rd(L.newb + s).toString(16)} (мирный, стыкуется), добавка сброшена`); }

// 2. сдвиг при удалении
{ clear(); const a = spawn(1), b = spawn(7), c = spawn(2); const before = flags().slice(0, 6);
  m.wr(L.XX4, [a]); const blk = m.rd16(L.UNIV + 2 * a); m.wr(L.INF, [blk & 255, blk >> 8]); const xx0 = m.rd16(L.XX21X); m.wr(L.XX0, [xx0 & 255, xx0 >> 8]);
  m.call('KILLSHP', { b: a }, 2e6);
  const after = flags().slice(0, 6), fr = frin().slice(0, 6);
  ok(fr[a] === 7 && fr[a + 1] === 2 && after[a] === 0x20 && after[a + 1] === 0x42, `после удаления места ${a}: типы ${fr}, флаги ${after.map((v) => v.toString(16))} (были ${before.map((v) => v.toString(16))})`); }

// 3. ветви тактики
{ const run = (fl, { fist = 0, sspr = 0, n = 400 } = {}) => { const res = { attack: 0, dock: 0, planet: 0, idle: 0 }; let ai = 0xFF, nb = fl;
    for (let i = 0; i < n; i++) { m.wr(L.XSAV, [3]); m.wr(L.newb + 3, [fl]); m.wr(L.FIST, [fist]); m.wr(L.SSPR, [sspr]); m.wr(L.INWK + 32, [0xFF]);
      let hit = 'idle'; const tick = () => { const pc = cpu.pc & 0xffff; if (pc === L.TA62) { hit = 'attack'; ret(); } else if (pc === L.DOCKIT) { hit = 'dock'; ret(); } else if (pc === L.dk_gopl) { hit = 'planet'; ret(); } };
      m.call('nb_tact', { tick }, 1e5); res[hit]++; ai &= m.rd(L.INWK + 32); nb |= m.rd(L.newb + 3); }
    return { ...res, ai, nb }; };
  let r = run(0x0C); ok(r.attack === 400, `пират в открытом космосе: в бой ${r.attack} из 400`);
  r = run(0x0C, { sspr: 1 }); ok(r.attack === 400 && r.ai === 0x81, `пират у станции: враждебность снята (INWK+32 = ${r.ai.toString(16)})`);
  r = run(0x20); ok(r.planet === 400, `мирный торговец: к планете ${r.planet} из 400`);
  r = run(0x30); ok(r.dock === 400, `торговец с флагом «стыкуется»: в станцию ${r.dock} из 400`);
  r = run(0x21); ok(r.planet > 110 && r.planet < 210 && r.idle === 400 - r.planet, `челнок (торговец, мирный): к планете ${r.planet}, ничего не делает ${r.idle} из 400 (ждали около 156 и 244)`);
  r = run(0x42); ok(r.planet === 400 && !(r.nb & 4), `полиция, мы чисты: не нападает (к планете ${r.planet})`);
  r = run(0x42, { fist: 50 }); ok(r.attack === 400 && (r.nb & 4), `полиция, мы в розыске (FIST 50): в бой ${r.attack}, флаг враждебности поставлен`);
  r = run(0x02, { fist: 39 }); ok(r.planet === 400, 'охотник за наградой при FIST 39 не нападает'); }

// 4. нападение на мирного
{ clear(); const s = spawn(27); const blk = m.rd16(L.UNIV + 2 * s); m.wr(blk + 32, [0x80]); m.wr(L.K_ + 36 + 32, [0]); m.wr(L.INF, [blk & 255, blk >> 8]);
  m.call('ANGRY', { a: 27 });
  ok((m.rd(L.newb + s) & 4) && (m.rd(L.K_ + 36 + 32) & 0x80), `Boa атакован: флаги ${m.rd(L.newb + s).toString(16)} (враждебен), станция злится (${(m.rd(L.K_ + 36 + 32) & 0x80) ? 'да' : 'нет'})`);
  clear(); const p = spawn(1); const b2 = m.rd16(L.UNIV + 2 * p); m.wr(b2 + 32, [0x80]); m.wr(L.K_ + 36 + 32, [0]); m.wr(L.INF, [b2 & 255, b2 >> 8]); m.call('ANGRY', { a: 1 });
  ok(!(m.rd(L.K_ + 36 + 32) & 0x80), 'пират атакован: станция не злится'); }

// 5. в игре: торговец с флагом «стыкуется» у станции — в нескольких сценах (станция на разном удалении, торговец
// перед нами и позади): на диске условие стыковки случайное, здесь — близость к станции
for (const WAIT of [400, 440, 500, 700]) { const g = createVector('elite'), G = g.L, c = g.cpu, K = { SPACE: [7, 0x80], N: [5, 0x40], F1: [1, 0x08] };
  const press = (k) => { g.key(K[k][0], K[k][1], true); g.frame(20); g.key(K[k][0], K[k][1], false); };
  g.frame(300); press('N'); g.frame(200); press('SPACE'); g.frame(200); press('F1'); g.frame(WAIT);
  c.iff = false; let cyc = 0;
  const pass = () => { let k = 0; do { c.instruction(); cyc += c.vcycles | 0; if (c.last_opcode === 0xd3) g.io.commit();
      if (cyc >= 59904) { cyc -= 59904; g.wr(G.DL, [30]); } if (++k > 3e7) throw new Error('проход не кончился'); } while ((c.pc & 0xffff) !== G.MLOOP); c.iff = false; };
  const fr = () => Array.from({ length: 13 }, (_, i) => g.rd(G.FRIN + i));
  for (let i = 0; i < 3; i++) pass();
  g.wr(G.DELTA, [0]);
  // торговец в 2000 единиц перед щелью станции (вдоль её носа), носом куда попало
  const st = Array.from({ length: 36 }, (_, i) => g.rd(G.K_ + 36 + i));
  g.call('ZINF'); const w = Array.from({ length: 36 }, (_, i) => g.rd(G.INWK + i));
  for (let ax = 0; ax < 3; ax++) { const sgn = (b) => (b & 0x80 ? -1 : 1), pos = sgn(st[3 * ax + 2]) * (st[3 * ax] | (st[3 * ax + 1] << 8) | ((st[3 * ax + 2] & 127) << 16));
    const nose = sgn(st[9 + 2 * ax + 1]) * (st[9 + 2 * ax + 1] & 127), v = pos + nose * 20, a = Math.abs(v); w[3 * ax] = a & 255; w[3 * ax + 1] = (a >> 8) & 255; w[3 * ax + 2] = ((a >> 16) & 127) | (v < 0 ? 0x80 : 0); }
  w[32] = 0xC0; w[27] = 8; g.wr(G.INWK, w); g.wr(G.nb_pre, [0xB0]);
  const r = g.call('NWSHP', { a: 7 }); const slot = fr().lastIndexOf(7);
  let n = 0, minD = 1e9, maxSeen = 0;
  while (fr().includes(7) && n < 2500) { g.wr(G.DELTA, [0]); g.wr(G.ENERGY, [255]); g.wr(G.EV, [50]); pass(); n++;
    const s = fr().indexOf(7); if (s > 0) { const b = G.K_ + 36 * s, d = Math.hypot(...[0, 1, 2].map((ax) => { const q = (i) => g.rd(G.K_ + i); const sg = (base) => (q(base + 3 * ax + 2) & 0x80 ? -1 : 1) * (q(base + 3 * ax) | (q(base + 3 * ax + 1) << 8)); return sg(36 * s) - sg(36); })); minD = Math.min(minD, d); } }
  ok(r.cf === 1 && slot > 0 && !fr().includes(7), `в игре (сцена через ${WAIT} кадров после взлёта): торговец появился у станции и через ${n} проходов исчез в ней (ближе всего к центру станции — ${minD.toFixed(0)}); энергия ${g.rd(G.ENERGY)}, станция ${(g.rd(G.K_ + 36 + 32) & 0x80) ? 'злится' : 'мирная'}`);
}
// 6. в игре: разозлённая станция выпускает враждебную полицию (на диске потомок наследует враждебность родителя)
{ const g = createVector('elite'), G = g.L, c = g.cpu, K = { SPACE: [7, 0x80], N: [5, 0x40], F1: [1, 0x08] };
  const press = (k) => { g.key(K[k][0], K[k][1], true); g.frame(20); g.key(K[k][0], K[k][1], false); };
  g.frame(300); press('N'); g.frame(200); press('SPACE'); g.frame(200); press('F1'); g.frame(400);
  const fr = () => Array.from({ length: 13 }, (_, i) => g.rd(G.FRIN + i));
  g.wr(G.K_ + 36 + 32, [g.rd(G.K_ + 36 + 32) | 0x80]); g.wr(G.FIST, [0]);
  let f = 0; while (fr().filter((t) => t === 2).length < 2 && f < 3000) { g.frame(10); f += 10; g.wr(G.ENERGY, [255]); }
  const cops = fr().map((t, i) => (t === 2 ? g.rd(G.newb + i) : -1)).filter((v) => v >= 0);
  ok(cops.length >= 2 && cops.every((v) => v & 4) && g.rd(G.FIST) === 0, `в игре: злая станция за ${f} кадров выпустила полицию, флаги ${cops.map((v) => v.toString(16)).join(', ')} — враждебна при чистом статусе игрока`); }
console.log(bad ? `ПРОВАЛ: ${bad}` : 'NEWB: всё как задумано');
process.exit(bad ? 1 : 0);
