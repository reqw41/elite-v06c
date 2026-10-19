// Снимок ZX 48K с тестовой сценой, как elite_sun.rom на Векторе (scene.asm): после вылета солнце впереди слева
// вверху (блок 7110h, z = 30000h), планета далеко позади (блок 7107h), четыре враждебных Sidewinder в тех же точках,
// что scn_pos. Игра ZX — снимок work/zx48/elite48.z80 под Z80 из vector06js (как в speed3.mjs). Пишет .z80 версии 1
// (48K, без сжатия) и проверяет его: загружает заново, гонит 400 кадров, кладёт снимки экрана.
// node tools/analysis/zx_scene.mjs [выход = work/zx48/elite48_sun.z80]
import fs from 'node:fs'; import path from 'node:path'; import os from 'node:os';
import { savePng, ROOT } from '../../v06c/tools/v06c.mjs';
const OUT = process.argv[2] || path.join(ROOT, 'work/zx48/elite48_sun.z80');
const P = path.join(os.homedir(), 'projects');
const Z80 = new Function(fs.readFileSync(path.join(P, 'vector06js/Z80_v06.js'), 'utf8') + '; return Z80;')();
const rom = fs.readFileSync(path.join(P, 'humphrey-v06c/roms/zx48.rom'));
const OBJ0 = 0x6048, SIDE = 0x69f2, MARK = 0x7FBE, PACK = 0xBCAB;
const SUN = [0x00, 0x80, 0x80, 0x00, 0x40, 0x00, 0x00, 0x00, 0x03], PLAN = [0, 0, 0, 0, 0, 0, 0, 0, 0x90];
const POS = [[0x00, 0x01, 0x80, 0x00, 0x00, 0x00, 0x00, 0x05, 0x00], [0x00, 0x01, 0x00, 0x80, 0x00, 0x00, 0x00, 0x06, 0x00],
  [0x00, 0x00, 0x00, 0x80, 0x00, 0x80, 0x00, 0x07, 0x00], [0x80, 0x01, 0x80, 0xC0, 0x00, 0x00, 0x00, 0x08, 0x00]];
const ROWS = ['^zxcv', 'asdfg', 'qwert', '12345', '09876', 'poiuy', '\nlkjh', '_~mnb'];

function machine(z, { from48 = false } = {}) {
  const mem = new Uint8Array(65536); mem.set(rom, 0); mem.set(z.subarray(30, 30 + 49152), 0x4000);
  const down = new Set();
  const cpu = new Z80({ mem_read: (a) => mem[a & 0xffff], mem_write: (a, v) => { if ((a & 0xffff) >= 0x4000) mem[a & 0xffff] = v; },
    io_read: (p) => { if (p & 1) return (p & 0xff) === 0x1f ? 0 : 0xff; let v = 0xff; const hi = (p >> 8) & 255;
      for (let r = 0; r < 8; r++) if (!(hi & (1 << r))) for (let k = 0; k < 5; k++) if (down.has(ROWS[r][k])) v &= ~(1 << k); return v; },
    io_write: () => {} });
  const st = cpu.getState();
  Object.assign(st, { a: z[0], c: z[2], b: z[3], l: z[4], h: z[5], pc: z[6] | (z[7] << 8), sp: z[8] | (z[9] << 8), i: z[10], r: (z[11] & 0x7f) | ((z[12] & 1) << 7),
    e: z[13], d: z[14], c_prime: z[15], b_prime: z[16], e_prime: z[17], d_prime: z[18], l_prime: z[19], h_prime: z[20], a_prime: z[21],
    iy: z[23] | (z[24] << 8), ix: z[25] | (z[26] << 8), iff1: z[27] ? 1 : 0, iff2: z[28] ? 1 : 0, imode: z[29] & 3 });
  if (from48) Object.assign(st, { i: 0xFD, imode: 2, iff1: 1, iff2: 1 });   // исходный снимок — с запрещёнными прерываниями (как в speed3)
  for (const k of 'SZYHXPNC') { st.flags[k] = (z[1] >> 'CNPXHYZS'.indexOf(k)) & 1; st.flags_prime[k] = (z[22] >> 'CNPXHYZS'.indexOf(k)) & 1; }
  cpu.setState(st);
  let hook = null;
  const frame = () => { let T = 0; while (T < 69888) { if (hook && cpu.pc === MARK) hook(); T += cpu.run_instruction() || 4; } cpu.interrupt(false, 0xff); };
  const run = (n, k) => { down.clear(); if (k) down.add(k); for (let f = 0; f < n; f++) frame(); };
  return { mem, cpu, run, set hook(f) { hook = f; } };
}
function save(m, file) {
  const s = m.cpu.getState(), h = new Uint8Array(30), f = (fl) => [...'CNPXHYZS'].reduce((v, k, i) => v | ((fl[k] ? 1 : 0) << i), 0);
  Object.assign(h, [s.a, f(s.flags), s.c, s.b, s.l, s.h, s.pc & 255, s.pc >> 8, s.sp & 255, s.sp >> 8, s.i, s.r & 0x7f, (s.r >> 7) & 1,
    s.e, s.d, s.c_prime, s.b_prime, s.e_prime, s.d_prime, s.l_prime, s.h_prime, s.a_prime, f(s.flags_prime), s.iy & 255, s.iy >> 8, s.ix & 255, s.ix >> 8,
    s.iff1 ? 1 : 0, s.iff2 ? 1 : 0, s.imode & 3]);
  fs.writeFileSync(file, Buffer.concat([Buffer.from(h), Buffer.from(m.mem.subarray(0x4000))]));
}
const shot = (m, file) => { const bmp = new Uint32Array(576 * 288), pal = [0, 0xC00000, 0x0000C0, 0xC000C0, 0x00C000, 0xC0C000, 0x00C0C0, 0xC0C0C0], mem = m.mem;
  for (let y = 0; y < 192; y++) for (let x = 0; x < 256; x++) { const a = 0x4000 | ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2) | (x >> 3), at = mem[0x5800 + (y >> 3) * 32 + (x >> 3)];
    const c = pal[(mem[a] >> (7 - (x & 7))) & 1 ? at & 7 : (at >> 3) & 7]; bmp[(y + 48) * 576 + x * 2 + 32] = c; bmp[(y + 48) * 576 + x * 2 + 33] = c; }
  savePng(bmp, file); };
const occ = (m, i) => m.mem[OBJ0 + 39 * i + 0x22];
const ships = (m) => { let n = 0; for (let i = 1; i <= 6; i++) if (occ(m, i)) n++; return n; };

// 1. вылет, как в speed3: заставки, взлёт, отлёт
const m = machine(fs.readFileSync(path.join(ROOT, 'work/zx48/elite48.z80')), { from48: true });
m.run(100); m.run(20, '_'); m.run(150); m.run(20, '_'); m.run(150); m.run(20, '1'); m.run(300);
// 2. в начале прохода: стаи пиратов (подпрограмма игры), пока мест не меньше четырёх; лишние — убрать, все — Sidewinder
let phase = 'spawn';
m.hook = () => {
  if (phase === 'spawn') { const st = m.cpu.getState(); st.sp = (st.sp - 2) & 0xffff; m.mem[st.sp] = MARK & 255; m.mem[st.sp + 1] = MARK >> 8; st.pc = PACK; m.cpu.setState(st); phase = 'fix'; return; }
  if (phase === 'fix') {
    if (ships(m) < 4) { phase = 'spawn'; return; }
    let k = 0;
    for (let i = 1; i <= 6; i++) { const b = OBJ0 + 39 * i; if (!occ(m, i)) continue;
      if (k < 4) { m.mem[b + 0x22] = 70; m.mem[b + 0x23] = SIDE & 255; m.mem[b + 0x24] = SIDE >> 8; m.mem.set(POS[k], b); k++; } else m.mem[b + 0x22] = 0; }
    m.mem.set(SUN, 0x7110); m.mem.set(PLAN, 0x7107);
    phase = 'save'; return; }
  if (phase === 'save') { save(m, OUT); phase = 'done'; }
};
while (phase !== 'done') m.run(1);
console.log(`снимок: ${OUT} (${fs.statSync(OUT).size} байт), кораблей ${ships(m)}`);
// 3. проверка: загрузить записанный снимок и лететь
const v = machine(fs.readFileSync(OUT)), dir = path.join(path.dirname(OUT), 'sun_check');
fs.mkdirSync(dir, { recursive: true });
for (let s = 1; s <= 4; s++) { v.run(100); shot(v, path.join(dir, `zx${s}.png`)); console.log(`${s * 2} с: кораблей ${ships(v)}, солнце z ${Array.from(v.mem.subarray(0x7116, 0x7119)).map((b) => b.toString(16)).join(' ')}`); }
