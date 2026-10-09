// Правила ZX 48K в обычном образе (эталона нет — проверка по смыслу и по числам из кода ZX, docs/research/zx48_analysis.md):
// 1. дерево появления zx_spawn: доли исходов на тысячах розыгрышей при разном правлении и контрабанде;
// 2. проверка появления — по времени (SP_PERIOD кадров), вне зоны станции; 3. нападение на мирного делает враждебными всех;
// 4. «в розыск» за убитого мирного; галактический прыжок обнуляет статус; 5. урон губит единицу груза, приборы целы;
// 6. при включённом скрывающем устройстве тактика чужих кораблей не выполняется.
// sh v06c/build.sh && node v06c/test/zxrules.mjs
import { createVector } from '../tools/v06c.mjs';
let bad = 0; const ok = (c, s) => { if (!c) bad++; console.log(`${c ? 'OK  ' : 'FAIL'} ${s}`); };
const m = createVector('elite'), L = m.L, cpu = m.cpu; m.frame(60);
const ret = (cf) => { const sp = cpu.sp & 0xffff; cpu.pc = m.rd(sp) | (m.rd(sp + 1) << 8); cpu.sp = (sp + 2) & 0xffff; if (cf !== undefined) cpu.cf = cf; };
const near = (got, want, n) => Math.abs(got - want) <= 3.5 * Math.sqrt(Math.max(want * (1 - want), 1e-4) / n) + 0.003;
let rs = 987654321; const rnd = () => { rs ^= rs << 13; rs >>>= 0; rs ^= rs >>> 17; rs ^= rs << 5; rs >>>= 0; return (rs >>> 11) & 255; };
const PACK = [1, 3, 5, 14, 22, 23, 24, 25], LONE = [4, 5, 15, 16], TRADE = [4, 7, 27, 28];

// 1. дерево появления: NWSHP и GTHG перехвачены — записываем, что создаётся
const roll = (N, set) => { const c = { none: 0, junk: 0, lone: 0, loneHost: 0, thg: 0, cop: 0, trader: 0, herm: 0, pack: 0, packShips: 0, other: 0 };
  for (let i = 0; i < N; i++) { const ev = [];
    const tick = () => { for (;;) { const pc = cpu.pc & 0xffff;
      if (pc === L.NWSHP) { ev.push({ t: cpu.regs[7], pre: m.rd(L.nb_pre), ai: m.rd(L.INWK + 32) }); m.wr(L.nb_pre, [0]); ret(1); }
      else if (pc === L.GTHG) { ev.push({ t: 'thg' }); ret(); } else return; } };
    m.wr(L.MISF, [0]); m.wr(L.DTP, [0]); m.wr(L.M3ST, [0]); m.wr(L.gov, [set.gov]); m.wr(L.QQ20, new Array(17).fill(0)); m.wr(L.QQ20 + 10, [set.bad || 0]); m.wr(L.GCNT, [0]); m.wr(L.QQ0, [0, 0]);
    m.wr(L.RAND, [rnd(), rnd(), rnd(), rnd()]);            // между проверками в игре проходят сотни вызовов генератора
    m.call('zx_spawn', { tick }, 2e6);
    if (!ev.length) c.none++; else if (ev[0].t === 'thg') c.thg++;
    else if (ev.length > 1) { c.pack++; c.packShips += ev.length; if (!ev.every((e) => PACK.includes(e.t))) c.other++; }
    else { const e = ev[0];
      if (e.pre === 0xA1 && e.t === 10 && e.ai === 0 && false) c.herm++;
      else if ([10, 11, 21].includes(e.t) && e.ai === 0 && (e.pre === 0 || e.pre === 0xA1)) { if (set.kind) set.kind.push(e); c.junk++; }
      else if (e.t === 2) c.cop++;
      else if (e.pre === 0xA0 || e.pre === 0xB0) { c.trader++; if (!TRADE.includes(e.t)) c.other++; }
      else if (LONE.includes(e.t)) { c.lone++; if (e.pre === 0) c.loneHost++; else if ((e.pre & 0x84) !== 0x80) c.other++; }
      else c.other++; } }
  return c; };
for (const set of [{ gov: 0 }, { gov: 3 }, { gov: 7 }, { gov: 0, bad: 40 }, { gov: 5, bad: 100 }]) {
  const N = 6000, c = roll(N, set), g = set.gov, b = set.bad || 0;
  // ожидание: точный перебор двух первых чисел дерева (остальные — доли)
  let ships = 0, lone = 0, peace = 0, pack = 0, junk = 0;
  for (let r = 0; r < 256; r++) { const d = r - b; let isShip = d < 0 || d < 80; if (!isShip) { if (d >= 80 && d < 90) junk++; continue; }
    const v = d & 255, e0 = v & 7; if (g !== 0 && g >= e0 + 1) continue; ships++;
    if (v & 8) { lone++; continue; } const e = g !== 0 ? e0 + 1 : e0; const pPack = Math.max(0, 8 - e) / 8; pack += pPack; peace += 1 - pPack; }
  const W = { junk: junk / 256, lone: lone / 256 * 63 / 64, thg: lone / 256 / 64, pack: pack / 256, peace: peace / 256 };
  const got = { junk: c.junk / N, lone: c.lone / N, thg: c.thg / N, pack: c.pack / N, peace: (c.cop + c.trader + c.junk * 0) / N };
  // мирные: 1 из 8 — отшельник (он попадает в «мусор» по виду), 1 из 8 — полиция, 6 из 8 — торговцы
  const wantJunk = W.junk + W.peace / 8, wantPeace = W.peace * 7 / 8;
  const pct = (x) => (100 * x).toFixed(1);
  const fine = near(got.junk, wantJunk, N) && near(got.lone, W.lone, N) && near(got.pack, W.pack, N) && near(got.peace, wantPeace, N) && near(got.thg, W.thg, N) && c.other === 0;
  ok(fine, `правление ${g}, контрабанда ${b}: одиночка ${pct(got.lone)} % (ждали ${pct(W.lone)}), стая ${pct(got.pack)} (${pct(W.pack)}), мирные ${pct(got.peace)} (${pct(wantPeace)}), мусор и отшельник ${pct(got.junk)} (${pct(wantJunk)}), таргоид ${pct(got.thg)} (${pct(W.thg)}); прочее ${c.other}`);
  if (g === 0 && !b) { const h = c.loneHost / c.lone, sz = c.packShips / c.pack, cp = c.cop / (c.cop + c.trader);
    ok(near(h, 51 / 256, c.lone) && Math.abs(sz - 3) < 0.15 && near(cp, 1 / 7, c.cop + c.trader), `одиночка враждебен сразу в ${pct(h)} % (ждали ${pct(51 / 256)}); в стае в среднем ${sz.toFixed(2)} корабля (ждали 3); полиция среди мирных кораблей ${pct(cp)} % (ждали ${pct(1 / 7)})`); }
}

// 3. нападение на мирного, полицейского или станцию делает враждебными все корабли вокруг
{ const frin = () => Array.from({ length: 13 }, (_, i) => m.rd(L.FRIN + i));
  const slsp = [m.rd(L.SLSP), m.rd(L.SLSP + 1)];
  const clear = () => { m.wr(L.FRIN, new Array(13).fill(0)); m.wr(L.FRIN, [128, 8]); m.wr(L.SLSP, slsp); m.wr(L.newb, new Array(13).fill(0)); m.wr(L.nb_pre, [0]); m.wr(L.K_ + 36 + 32, [1]); };
  const spawn = (t, pre = 0) => { m.call('ZINF'); m.wr(L.INWK + 7, [5]); m.wr(L.nb_pre, [pre]); const r = m.call('NWSHP', { a: t }); return r.cf ? frin().lastIndexOf(t) : -1; };
  const angry = (s, t) => { const blk = m.rd16(L.UNIV + 2 * s); m.wr(blk + 32, [0x80]); m.wr(L.INF, [blk & 255, blk >> 8]); m.call('ANGRY', { a: t }); };
  const fl = () => Array.from({ length: 13 }, (_, i) => m.rd(L.newb + i)).slice(2, 6).map((v) => v.toString(16)).join(' ');
  for (const [victim, name, all] of [[27, 'Boa (мирный)', true], [2, 'Viper (полиция)', true], [1, 'Sidewinder (пират)', false], [8, 'станция', true]]) {
    clear(); const a = spawn(16), b = spawn(27, 0xA0), c = spawn(2), d = spawn(11);        // охотник, торговец, полиция, контейнер
    const v = victim === 8 ? 1 : spawn(victim); angry(v, victim);
    const host = [a, b, c].map((i) => !!(m.rd(L.newb + i) & 4)), junk = m.rd(L.newb + d), st = !!(m.rd(L.K_ + 36 + 32) & 0x80);
    ok(host.every((h) => h === all) && junk === 0 && st === all, `попадание в ${name}: Fer-de-Lance, Boa, Viper враждебны — ${host.join(', ')}; станция злится — ${st}; контейнер без флагов (${junk})`); }
}
// 7. мирная станция выпускает челноки и торговцев; торговец — с флагами мирного
{ const seen = {}; let badPre = 0;
  for (let i = 0; i < 30000; i++) { m.wr(L.FRIN, [128, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]); m.wr(L.nb_pre, [0]);
    m.call('zx_tact', { b: 8, mem: { INWK: new Array(32).fill(0).concat([1]) }, tick: () => { if ((cpu.pc & 0xffff) === L.SFS1) { const t = cpu.regs[0], pre = m.rd(L.nb_pre); seen[t] = (seen[t] || 0) + 1; if ((t < 29) !== (pre === 0xA0)) badPre++; ret(1); } } }, 2e6);
    if (m.rd(L.nb_pre)) badPre++; }
  const tr = [4, 7, 27, 28].reduce((a, t) => a + (seen[t] || 0), 0), sh = (seen[29] || 0) + (seen[30] || 0), other = Object.keys(seen).filter((t) => ![4, 7, 27, 28, 29, 30].includes(+t)).length;
  ok(tr > 60 && tr < 180 && sh > 140 && sh < 340 && !other && !badPre, `станция за 30 000 вызовов тактики: торговцев ${tr} (ждали около 117), челноков ${sh} (около 234); флаги торговца заданы верно (ошибок ${badPre})`);
  let n = 0; m.call('zx_tact', { b: 8, mem: { INWK: new Array(32).fill(0).concat([0x81]) }, tick: () => { if ((cpu.pc & 0xffff) === L.SFS1) { n++; ret(1); } } }, 2e6);
  for (let i = 0; i < 3000; i++) m.call('zx_tact', { b: 8, mem: { INWK: new Array(32).fill(0).concat([0x81]) }, tick: () => { if ((cpu.pc & 0xffff) === L.SFS1) { n++; ret(1); } } }, 2e6);
  ok(n === 0, `злая станция за 3000 вызовов мирных кораблей не выпустила (${n})`); }
// 4–6 — в игре: проход цикла идёт по командам, кадры считаются вручную (v_frames)
{ const g = createVector('elite'), G = g.L, c = g.cpu, K = { SPACE: [7, 0x80], N: [5, 0x40], F1: [1, 0x08] };
  const press = (k) => { g.key(K[k][0], K[k][1], true); g.frame(20); g.key(K[k][0], K[k][1], false); };
  g.frame(300); press('N'); g.frame(200); press('SPACE'); g.frame(200); press('F1'); g.frame(400);
  c.iff = false; let cyc = 0, spawns = 0, tin = {}, tgo = {};
  const pass = () => { let k = 0; do { const pc = c.pc & 0xffff; if (pc === G.zx_spawn) spawns++; if (pc === G.TACTICS) tin[c.regs[0]] = (tin[c.regs[0]] || 0) + 1; if (pc === G.ta_see) tgo[c.regs[0]] = (tgo[c.regs[0]] || 0) + 1; c.instruction(); cyc += c.vcycles | 0; if (c.last_opcode === 0xd3) g.io.commit();
      if (cyc >= 59904) { cyc -= 59904; g.wr(G.DL, [30]); const la = g.rd(G.LASCT); if (la) g.wr(G.LASCT, [la - 1]); const f = (g.rd(G.v_frames) | (g.rd(G.v_frames + 1) << 8)) + 1; g.wr(G.v_frames, [f & 255, (f >> 8) & 255]); }
      if (++k > 3e7) throw new Error('проход не кончился'); } while ((c.pc & 0xffff) !== G.MLOOP); c.iff = false; };
  const fr = () => Array.from({ length: 13 }, (_, i) => g.rd(G.FRIN + i));
  const keep = () => { g.wr(G.ENERGY, [255]); g.wr(G.FSH, [255]); g.wr(G.ASH, [255]); g.wr(G.DELTA, [0]); g.wr(G.K_ + 36 + 32, [1]); };
  const wipe = () => { for (let i = 2; i < 13; i++) { const t = g.rd(G.FRIN + i); if (t && t < 128) { const a = G.K_ + 36 * i + 31; g.wr(a, [g.rd(a) | 0x80]); } } for (let i = 0; i < 300 && (i < 6 || fr().slice(2).some((t) => t && t < 128)); i++) { keep(); pass(); } };
  const keyA = (d) => { const rows = new Array(8).fill(0); if (d) { const i = g.rd(G.kb_rev + 0x41); rows[i >> 3] |= 1 << (i & 7); } g.wr(G.kb_rows, rows); };
  for (let i = 0; i < 3; i++) pass();
  // 2. проверка появления по времени: в зоне станции zx_spawn не вызывается, а отметка времени идёт
  { const fr0 = () => g.rd(G.v_frames) | (g.rd(G.v_frames + 1) << 8); const f0 = fr0(); let marks = 0, last = g.rd(G.sp_last) | (g.rd(G.sp_last + 1) << 8); spawns = 0;
    while (((fr0() - f0) & 0xffff) < 6400) { keep(); pass(); const v = g.rd(G.sp_last) | (g.rd(G.sp_last + 1) << 8); if (v !== last) { marks++; last = v; } }
    ok(g.rd(G.SSPR) !== 0 && spawns === 0 && marks >= 4 && marks <= 5, `в зоне станции за 6400 кадров: отметок времени ${marks} (ждали 5 — раз в 1280 кадров), появлений ${spawns}`); }
  // 4. «в розыск» за убитого мирного; за пирата — нет; каменный отшельник не в счёт
  for (const [t, pre, name, want] of [[27, 0xA0, 'Boa-торговец', 64], [1, 0, 'Sidewinder', 0], [10, 0xA1, 'каменный отшельник', 0]]) { wipe(); g.wr(G.FIST, [0]); g.wr(G.LASER, [15, 0, 0, 0]); g.call('ZINF'); g.wr(G.INWK + 7, [3]); g.wr(G.nb_pre, [pre]); g.call('NWSHP', { a: t }); keyA(true); let n = 0;
    while (fr().includes(t) && n < 900) { const s = fr().indexOf(t); g.wr(G.K_ + 36 * s, [0, 0, 0, 0, 0, 0, 0, 3, 0]); g.wr(G.K_ + 36 * s + 32, [0]); g.wr(G.GNTMP, [0]); keep(); pass(); n++; }
    keyA(false); for (let i = 0; i < 3; i++) { keep(); pass(); }
    ok(!fr().includes(t) && (g.rd(G.FIST) & 64) === want, `${name} уничтожен за ${n} проходов: правовой статус ${g.rd(G.FIST)}`); }
  { g.wr(G.FIST, [50]); g.call('mis_gal'); ok(g.rd(G.FIST) === 0, `галактический прыжок: правовой статус ${g.rd(G.FIST)}`); }
  // 5. урон: гибнет единица груза, приборы целы
  { let lost = 0, eq = 0; const N = 3000; for (let i = 0; i < N; i++) { g.wr(G.QQ20, new Array(17).fill(5)); const e0 = Array.from({ length: 5 }, (_, k) => g.rd(G.QQ20 + 17 + k)); g.wr(G.DLY, [0]); g.wr(G.RAND, [rnd(), rnd(), rnd(), rnd()]);
      g.call('OUCH', { tick: () => { if ((c.pc & 0xffff) === G.MESS) { const sp = c.sp & 0xffff; c.pc = g.rd(sp) | (g.rd(sp + 1) << 8); c.sp = (sp + 2) & 0xffff; }; } }, 2e6);
      const q = Array.from({ length: 17 }, (_, k) => g.rd(G.QQ20 + k)), d = q.reduce((a, v) => a + 5 - v, 0); if (d === 1) lost++; else if (d) eq += 100;
      if (Array.from({ length: 5 }, (_, k) => g.rd(G.QQ20 + 17 + k)).join() !== e0.join()) eq++; }
    ok(near(lost / N, 10 / 64, N) && eq === 0, `урон по энергии: единица груза гибнет в ${(100 * lost / N).toFixed(1)} % ударов (ждали ${(1000 / 64).toFixed(1)}), приборы и прочий груз целы (${eq})`); }
  // 6. скрывающее устройство: тактика чужих кораблей не выполняется, ракета летит
  { wipe(); g.call('ZINF'); g.wr(G.INWK + 7, [20]); g.wr(G.INWK + 32, [0xFF]); g.call('NWSHP', { a: 1 }); g.call('ZINF'); g.wr(G.INWK + 7, [20]); g.wr(G.INWK + 32, [0xFF]); g.call('NWSHP', { a: 9 });
    const run = (on) => { tin = {}; tgo = {}; for (let n = 0; n < 160; n++) { g.wr(G.cloak_on, [on]); keep(); const s = fr().indexOf(1); if (s > 0) g.wr(G.K_ + 36 * s + 35, [200]); pass(); } return [tin[1] || 0, tgo[1] || 0, Object.keys(tgo).filter((t) => +t !== 9 && +t !== 1).length]; };
    const off = run(0), on = run(1);
    ok(off[0] > 5 && off[1] === off[0] && on[0] > 5 && on[1] === 0 && on[2] === 0, `тактика Sidewinder за 160 проходов: без устройства вызвана ${off[0]} раз и выполнена ${off[1]}; с устройством вызвана ${on[0]}, выполнена ${on[1]}`); }
}
console.log(bad ? `ПРОВАЛ: ${bad}` : 'ZXRULES: всё как задумано');
process.exit(bad ? 1 : 0);
