// Запуск снимка ZX 48K Elite без окна: ядро Z80 (~/projects/vector06js/Z80_v06.js), ПЗУ 48K, прерывание раз в 69 888
// тактов (50,08 Гц при 3,5 МГц). Считает проходы в полёте (по вызову переноса буфера на экран, 7FBEh; MARK=адрес — другой счётчик) и время машины.
// node tools/analysis/zx48_run.mjs "<кадров>[:<клавиша>] ..." [снимок.png на каждом шаге]
// Клавиша — знак (a–z, 0–9, _ — пробел, ^ — Enter); держится все кадры шага.
import fs from 'node:fs'; import path from 'node:path'; import os from 'node:os';
import { savePng, ROOT } from '../../v06c/tools/v06c.mjs';
const P = path.join(os.homedir(), 'projects');
const Z80 = new Function(fs.readFileSync(path.join(P, 'vector06js/Z80_v06.js'), 'utf8') + '; return Z80;')();
const rom = fs.readFileSync(path.join(P, 'humphrey-v06c/roms/zx48.rom'));
const z = fs.readFileSync(path.join(ROOT, 'work/zx48/elite48.z80'));
const mem = new Uint8Array(65536); mem.set(rom, 0); mem.set(z.subarray(30, 30 + 49152), 0x4000);
const ROWS = ['^zxcv', 'asdfg', 'qwert', '12345', '09876', 'poiuy', '\nlkjh', '_~mnb'];   // ^ здесь Caps Shift; Enter — \n
const down = new Set(); let border = 0;
const core = { mem_read: (a) => mem[a & 0xffff], mem_write: (a, v) => { if ((a & 0xffff) >= 0x4000) mem[a & 0xffff] = v; },
  io_read: (p) => { if (p & 1) return (p & 0xff) === 0x1f ? 0 : 0xff; let v = 0xff; const hi = (p >> 8) & 255;
    for (let r = 0; r < 8; r++) if (!(hi & (1 << r))) for (let b = 0; b < 5; b++) if (down.has(ROWS[r][b])) v &= ~(1 << b); return v; },
  io_write: (p, v) => { if (!(p & 1)) border = v & 7; } };
const cpu = new Z80(core);
const st = cpu.getState();
Object.assign(st, { a: z[0], c: z[2], b: z[3], l: z[4], h: z[5], pc: z[6] | (z[7] << 8), sp: z[8] | (z[9] << 8), i: z[10], r: z[11], e: z[13], d: z[14],
  c_prime: z[15], b_prime: z[16], e_prime: z[17], d_prime: z[18], l_prime: z[19], h_prime: z[20], a_prime: z[21],
  iy: z[23] | (z[24] << 8), ix: z[25] | (z[26] << 8), iff1: z[27] ? 1 : 0, iff2: z[28] ? 1 : 0, imode: z[29] & 3 });
for (const k of 'SZYHXPNC') st.flags[k] = (z[1] >> 'CNPXHYZS'.indexOf(k)) & 1;
// в заголовке снимка прерывания выключены; игра работает в IM 2 с I = FDh (FF4Ch) — ставим так
st.i = 0xFD; st.imode = 2; st.iff1 = 1; st.iff2 = 1;
cpu.setState(st);
const MARK = +(process.env.MARK || 0x7FBE);   // 7FBEh — перенос буфера обзора на экран: раз за проход в полёте
const FRAME = 69888; let T = 0, frames = 0, loops = 0;
const hot = new Map();
const frame = () => { const end = T + FRAME; while (T < end) { const pc = cpu.pc; if (pc === MARK) loops++; T += cpu.run_instruction() || 4; } frames++; cpu.interrupt(false, 0xff); };
const shot = (f) => { const bmp = new Uint32Array(576 * 288), pal = [0, 0xC00000, 0x0000C0, 0xC000C0, 0x00C000, 0xC0C000, 0x00C0C0, 0xC0C0C0];
  for (let y = 0; y < 192; y++) for (let x = 0; x < 256; x++) { const a = 0x4000 | ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2) | (x >> 3), at = mem[0x5800 + (y >> 3) * 32 + (x >> 3)];
    const on = (mem[a] >> (7 - (x & 7))) & 1, c = pal[on ? at & 7 : (at >> 3) & 7]; bmp[(y + 48) * 576 + x * 2 + 32] = c; bmp[(y + 48) * 576 + x * 2 + 33] = c; }
  savePng(bmp, f); };
// SHIPS=n — держать в полёте n кораблей: когда их меньше, в начале прохода вызывается игровая процедура «стая»
// (BCABh: 2–4 Sidewinder и Krait), все делаются враждебными (бит 0 байта 25h блока). Игрок не гибнет: щиты и
// энергия не трогаются — если гибель случится, это видно по падению числа проходов.
const OBJ0 = +(process.env.OBJ0 || 0), WANT = +(process.env.SHIPS || 0);
const ships = () => { let n = 0; for (let i = 1; i <= 6; i++) if (mem[OBJ0 + 39 * i + 0x22]) n++; return n; };
let inject = false, shipSum = 0, shipN = 0;
const frame0 = frame;
const frameS = () => { const end = T + FRAME; while (T < end) { const pc = cpu.pc; if (pc === MARK) { loops++; shipSum += ships(); shipN++;
      if (WANT && ships() < WANT) { const st = cpu.getState(); st.sp = (st.sp - 2) & 0xffff; mem[st.sp] = pc & 255; mem[st.sp + 1] = pc >> 8; st.pc = 0xBCAB; cpu.setState(st); }
      else if (WANT) for (let i = 1; i <= 6; i++) if (mem[OBJ0 + 39 * i + 0x22]) mem[OBJ0 + 39 * i + 0x25] |= 1; }
    T += cpu.run_instruction() || 4; } frames++; cpu.interrupt(false, 0xff); };
const steps = (process.argv[2] || '500').split(/\s+/), png = process.argv[3];
steps.forEach((s, i) => { const [n, k] = s.split(':'); down.clear(); if (k) for (const ch of k) down.add(ch === '_' ? '_' : ch === '^' ? '\n' : ch);
  const l0 = loops, t0 = T; shipSum = 0; shipN = 0; for (let f = 0; f < +n; f++) (WANT && i >= 6 ? frameS : frame)();
  console.log(`шаг ${i} (${s}): кадров ${n}, проходов ${loops - l0}, ${((loops - l0) / ((T - t0) / 3.5e6)).toFixed(2)} в секунду; кораблей в среднем ${shipN ? (shipSum / shipN).toFixed(1) : '-'}; pc ${cpu.pc.toString(16)}`);
  if (process.env.DUMP && OBJ0) for (let k = 0; k < 8; k++) { const b = OBJ0 + 39 * k; if (mem[b + 0x22] || k === 0 || k === 7) console.log(`   место ${k}: занято ${mem[b + 0x22]}, модель ${(mem[b + 0x23] | (mem[b + 0x24] << 8)).toString(16)}, флаги ${mem[b + 0x25].toString(16)} ${mem[b + 0x26].toString(16)}, байты 0–8: ${Array.from(mem.subarray(b, b + 9)).map((v) => v.toString(16).padStart(2, '0')).join(' ')}`); }
  if (png) shot(png.replace('.png', `-${i}.png`)); });
