// Скорость в одной сцене на трёх машинах: кассетная BBC (эталон, настоящие кадры), ZX 48K (снимок под Z80) и обычный
// образ Вектора. Сцена: вылет с Лейва, клавиши не нажаты, впереди планета; затем три Sidewinder в одних и тех же
// точках перед игроком (положение ставится заново в начале каждого прохода), игрок неуязвим.
// node tools/analysis/speed3.mjs [кадров замера = 1500] [папка для снимков]
import fs from 'node:fs'; import path from 'node:path'; import os from 'node:os';
import { createRequire } from 'node:module';
import { createVector, savePng, ROOT } from '../../v06c/tools/v06c.mjs';
const require = createRequire(import.meta.url);
const { BBC } = require(path.join(ROOT, 'tools/oracle/bbc.js'));
const FR = +(process.argv[2] || 1500), SHOT = process.argv[3];
const PITCH = !!process.env.PITCH;   // PITCH=1 — тангаж зажат весь замер (короткие пути «полёт прямо» не работают)
const NSHIPS = process.env.NSHIPS === undefined ? 3 : +process.env.NSHIPS;
// координаты 3 байта (младший, старший, знак): x, y, z
const POS = [[[0, 1, 0x80], [0, 0, 0], [0, 4, 0]], [[0, 1, 0], [0x80, 0, 0], [0, 5, 0]], [[0, 0, 0], [0x80, 0, 0x80], [0, 6, 0]],
  [[0x80, 1, 0x80], [0xC0, 0, 0], [0, 7, 0]], [[0x80, 1, 0], [0xA0, 0, 0x80], [0x80, 6, 0]], [[0, 0, 0], [0, 1, 0], [0, 8, 0]]].slice(0, NSHIPS);   // до шести (у ZX мест под корабли шесть)
const flat = (p) => p.flat();
const out = [];

// --- BBC: кассета, прерывание кадра 50 Гц, 2 МГц; планета окружностью (PL25 = RTS), как у Вектора и ZX; MERID=1 — с меридианами
{
  const b = new BBC(), L = b.lab, m = b.mem;
  if (!process.env.MERID) m[L.PL25] = 0x60;
  const K = { N: 0x55, SPACE: 0x62, F0: 0x20 };
  b.runFrames(300); b.press(K.N, 20); b.runFrames(200); b.press(K.SPACE, 20); b.runFrames(200); b.press(K.F0, 20); b.runFrames(300);
  // корабли создаются в начале прохода (TT100): посреди прохода вызов затёр бы рабочую копию текущего объекта (INWK).
  // call стенда пишет адрес возврата в 1FEh/1FFh и не хранит A, X, Y — их надо сберечь
  const call = (l, o) => { const c = b.cpu, r = { a: c.a, x: c.x, y: c.y }, st = [m[0x1fe], m[0x1ff]]; b.call(l, o); Object.assign(c, r); m[0x1fe] = st[0]; m[0x1ff] = st[1]; };
  let slots = null, passes = 0, shipsSum = 0;
  b.watch.set(L.TT100, () => {
    if (!slots) { for (let i = 0; i < NSHIPS; i++) { call('ZINF'); m[L.INWK + 7] = 4; m[L.INWK + 32] = 0xbf; call('NWSHP', { a: 1 }); }
      slots = []; for (let i = 2; i < 12; i++) if (m[L.FRIN + i] === 1) slots.push(i); }
    passes++; let n = 0; for (let i = 2; i < 12; i++) if (m[L.FRIN + i]) n++; shipsSum += n;
    slots.forEach((s, k) => m.set(flat(POS[k]), L['K%'] + 36 * s)); m[L.ENERGY] = 255; m[L.FSH] = 255; m[L.ASH] = 255; });
  b.runFrames(50); if (PITCH) b.keys.add(0x51);
  const c0 = b.cpu.cycles; let mc = 0, prev = m[L.MCNT]; passes = 0; shipsSum = 0;
  for (let f = 0; f < FR; f++) { b.runFrames(1); mc += (prev - m[L.MCNT]) & 255; prev = m[L.MCNT]; }
  out.push(['BBC кассета' + (process.env.MERID ? ', меридианы' : ''), mc / ((b.cpu.cycles - c0) / 2e6), shipsSum / passes]);
  if (SHOT) b.png(path.join(SHOT, 'bbc.png'));
}

// --- Вектор: обычный образ, 3 МГц, прерывание кадра
{
  const g = createVector(process.env.IMG || 'elite'), L = g.L, cpu = g.cpu;
  const K = { SPACE: [7, 0x80], N: [5, 0x40], F1: [1, 0x08] };
  const press = (k) => { g.key(K[k][0], K[k][1], true); g.frame(20); g.key(K[k][0], K[k][1], false); };
  g.frame(300); press('N'); g.frame(200); press('SPACE'); g.frame(200); press('F1'); g.frame(300);
  let slots = null, passes = 0, shipsSum = 0, busy = false;
  const PROF = process.env.PROF ? new Float64Array(0x10000) : null;   // PROF=n — n самых дорогих меток
  const ins = cpu.instruction.bind(cpu);
  cpu.instruction = () => { if (!busy && (cpu.pc & 0xffff) === L.TT100) {
      if (!slots) { busy = true; for (let i = 0; i < NSHIPS; i++) { g.call('ZINF'); g.wr(L.INWK + 7, [4]); g.wr(L.INWK + 32, [0xbf]); g.call('NWSHP', { a: 1 }); } busy = false;
        slots = []; for (let i = 2; i < 12; i++) if (g.rd(L.FRIN + i) === 1) slots.push(i); }
      passes++; let n = 0; for (let i = 2; i < 12; i++) if (g.rd(L.FRIN + i)) n++; shipsSum += n;
      slots.forEach((s, k) => g.wr(L.K_ + 36 * s, flat(POS[k]))); for (const v of ['ENERGY', 'FSH', 'ASH']) g.wr(L[v], [255]); }
    if (PROF) { const pc = cpu.pc & 0xffff, r = ins(); PROF[pc] += cpu.vcycles | 0; return r; } return ins(); };
  g.frame(50); passes = 0; shipsSum = 0; if (PITCH) g.key(0, 0x20, true);
  if (PROF) PROF.fill(0);
  g.frame(FR);
  if (PROF) { const labs = Object.entries(L).filter(([n, a]) => typeof a === 'number' && a >= 0x100 && a < 0xB000 && /^[A-Za-z]/.test(n)).sort((x, y) => x[1] - y[1]);
    const cost = {}; let k = 0, tot = 0; for (let a = 0x100; a < 0x10000; a++) { if (!PROF[a]) continue; while (k + 1 < labs.length && labs[k + 1][1] <= a) k++; const n = a < labs[0][1] || a >= 0xB000 ? '?' : labs[k][0]; cost[n] = (cost[n] || 0) + PROF[a]; tot += PROF[a]; }
    console.log('Вектор, профиль (доля всех тактов, такты на проход):'); Object.entries(cost).sort((x, y) => y[1] - x[1]).slice(0, +process.env.PROF).forEach(([n, c]) => console.log(`  ${(c / tot * 100).toFixed(1).padStart(5)}%  ${(c / passes).toFixed(0).padStart(7)}  ${n}`)); }
  out.push(['Вектор' + (process.env.IMG ? ', ' + process.env.IMG : ''), passes / (FR / 50), shipsSum / passes]);
  if (SHOT) savePng(g.bmp(), path.join(SHOT, 'v06c.png'));
}

// --- ZX 48K: снимок игры, Z80 3,5 МГц, прерывание раз в 69 888 тактов; проход — перенос буфера на экран (7FBEh)
{
  const P = path.join(os.homedir(), 'projects');
  const Z80 = new Function(fs.readFileSync(path.join(P, 'vector06js/Z80_v06.js'), 'utf8') + '; return Z80;')();
  const rom = fs.readFileSync(path.join(P, 'humphrey-v06c/roms/zx48.rom'));
  const z = fs.readFileSync(path.join(ROOT, 'work/zx48/elite48.z80'));
  const mem = new Uint8Array(65536); mem.set(rom, 0); mem.set(z.subarray(30, 30 + 49152), 0x4000);
  const ROWS = ['^zxcv', 'asdfg', 'qwert', '12345', '09876', 'poiuy', '\nlkjh', '_~mnb'];
  const down = new Set();
  const cpu = new Z80({ mem_read: (a) => mem[a & 0xffff], mem_write: (a, v) => { if ((a & 0xffff) >= 0x4000) mem[a & 0xffff] = v; },
    io_read: (p) => { if (p & 1) return (p & 0xff) === 0x1f ? 0 : 0xff; let v = 0xff; const hi = (p >> 8) & 255;
      for (let r = 0; r < 8; r++) if (!(hi & (1 << r))) for (let k = 0; k < 5; k++) if (down.has(ROWS[r][k])) v &= ~(1 << k); return v; },
    io_write: () => {} });
  const st = cpu.getState();
  Object.assign(st, { a: z[0], c: z[2], b: z[3], l: z[4], h: z[5], pc: z[6] | (z[7] << 8), sp: z[8] | (z[9] << 8), r: z[11], e: z[13], d: z[14],
    c_prime: z[15], b_prime: z[16], e_prime: z[17], d_prime: z[18], l_prime: z[19], h_prime: z[20], a_prime: z[21],
    iy: z[23] | (z[24] << 8), ix: z[25] | (z[26] << 8), i: 0xFD, imode: 2, iff1: 1, iff2: 1 });
  for (const k of 'SZYHXPNC') st.flags[k] = (z[1] >> 'CNPXHYZS'.indexOf(k)) & 1;
  cpu.setState(st);
  const OBJ0 = 0x6048, SIDE = 0x69f2, MARK = 0x7FBE, PACK = 0xBCAB;
  let T = 0, passes = 0, shipsSum = 0, phase = 'idle', slots = [];
  const occ = (i) => mem[OBJ0 + 39 * i + 0x22];
  const onPass = (pc) => {
    if (phase === 'spawn') {                       // игровая «стая» (2–4 Sidewinder и Krait) в начале прохода
      const st = cpu.getState(); st.sp = (st.sp - 2) & 0xffff; mem[st.sp] = pc & 255; mem[st.sp + 1] = pc >> 8; st.pc = PACK; cpu.setState(st); phase = 'fix'; return; }
    if (phase === 'fix') {                         // оставить NSHIPS мест, все — Sidewinder (модель и «занято» как у типа 16)
      let have = 0; for (let i = 1; i <= 6; i++) if (occ(i)) have++;
      if (have < NSHIPS) { phase = 'spawn'; return; }   // мало — ещё одна стая
      slots = []; for (let i = 1; i <= 6; i++) if (occ(i)) { if (slots.length < NSHIPS) slots.push(i); else mem[OBJ0 + 39 * i + 0x22] = 0; }
      for (const s of slots) { const b = OBJ0 + 39 * s; mem[b + 0x22] = 70; mem[b + 0x23] = SIDE & 255; mem[b + 0x24] = SIDE >> 8; }
      phase = 'run'; }
    if (phase === 'run') { passes++; let n = 0; for (let i = 1; i <= 6; i++) if (occ(i)) n++; shipsSum += n;
      slots.forEach((s, k) => { const b = OBJ0 + 39 * s; mem.set(flat(POS[k]), b); mem[b + 0x25] |= 1; }); }
  };
  const frame = () => { const end = T + 69888; while (T < end) { const pc = cpu.pc; if (pc === MARK) onPass(pc); T += cpu.run_instruction() || 4; } cpu.interrupt(false, 0xff); };
  const run = (n, k) => { down.clear(); if (k) down.add(k); for (let f = 0; f < n; f++) frame(); };
  run(100); run(20, '_'); run(150); run(20, '_'); run(150); run(20, '1'); run(300);   // заставки, вылет, отлёт
  if (NSHIPS) { phase = 'spawn'; while (phase !== 'run') frame(); } else phase = 'run';
  passes = 0; shipsSum = 0; const t0 = T; run(FR, PITCH ? 's' : null);
  out.push(['ZX 48K', passes / ((T - t0) / 3.5e6), shipsSum / passes]);
  if (SHOT) { const bmp = new Uint32Array(576 * 288), pal = [0, 0xC00000, 0x0000C0, 0xC000C0, 0x00C000, 0xC0C000, 0x00C0C0, 0xC0C0C0];
    for (let y = 0; y < 192; y++) for (let x = 0; x < 256; x++) { const a = 0x4000 | ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2) | (x >> 3), at = mem[0x5800 + (y >> 3) * 32 + (x >> 3)];
      const c = pal[(mem[a] >> (7 - (x & 7))) & 1 ? at & 7 : (at >> 3) & 7]; bmp[(y + 48) * 576 + x * 2 + 32] = c; bmp[(y + 48) * 576 + x * 2 + 33] = c; }
    savePng(bmp, path.join(SHOT, 'zx.png')); }
}

console.log(`кораблей Sidewinder: ${NSHIPS}, кадров замера ${FR}${PITCH ? ', тангаж зажат' : ''}`);
for (const [n, r, s] of out) console.log(`${n.padEnd(12)} ${r.toFixed(2)} прохода в секунду; кораблей в среднем ${s.toFixed(1)}`);
