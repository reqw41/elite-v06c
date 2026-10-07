// Вектор под node (vector06js без окна): образ с 0100h, кадры с видеотрактом и прерыванием, вызов одной
// процедуры, снимок кадра в PNG. Эмулятор: ~/projects/vector06js (или каталог в VECTOR06JS), не меняется.
import os from 'node:os';
import fs from 'node:fs';
import vm from 'node:vm';
import path from 'node:path';
import zlib from 'node:zlib';
import { fileURLToPath } from 'node:url';

export const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const VEC = process.env.VECTOR06JS || path.join(os.homedir(), 'projects/vector06js');
const RET = 0x0006;             // сюда возвращается вызванная процедура

export function parseSym(symPath) {
  const L = {};
  for (const line of fs.readFileSync(symPath, 'latin1').split('\n')) {
    const m = line.match(/^([A-Za-z_][\w.]*):\s+EQU\s+0x([0-9A-Fa-f]+)\s*$/i);
    if (m) L[m[1]] = parseInt(m[2], 16);
  }
  return L;
}

let ctx = null;
function emu() {
  if (ctx) return ctx;
  const g = {}; g.window = g;
  const fcx = () => ({ createImageData: () => ({ data: new Uint8ClampedArray(4) }), putImageData() {}, getImageData: () => ({ data: new Uint8ClampedArray(4) }), fillRect() {}, drawImage() {} });
  const fc = () => ({ width: 0, height: 0, style: {}, getContext: () => fcx() });
  g.document = { createElement: fc, getElementById: fc };
  g.requestAnimationFrame = () => 0; g.setTimeout = () => 0; g.print = () => 0;
  g.console = { log() {}, debug() {}, warn() {}, error() {}, info() {} };
  ctx = vm.createContext(g);
  for (const f of ['i8080-js/i8080_trace.js', 'i8080-js/i8080_disasm.js', 'i8080-js/i8080.js', 'src/fili.js', 'src/ay.js', 'src/fd1793.js',
    'src/fddimage.js', 'src/i8253.js', 'src/io.js', 'src/keyboard.js', 'src/memory.js', 'src/sound.js', 'src/tv.js'])
    vm.runInContext(fs.readFileSync(path.join(VEC, f), 'utf8'), ctx, { filename: f });
  return ctx;
}

// name — имя образа в v06c/build без расширения (рядом лежит .sym).
export function createVector(name = 'elite') {
  const c = emu(), base = path.join(ROOT, 'v06c/build', name);
  const memory = new c.Memory(), keyboard = new c.Keyboard(), timer = new c.I8253(), ay = new c.AY(),
    floppy = new (c.Floppy().FD1793)(), io = new c.IO(keyboard, timer, memory, ay, floppy), cpu = new c.I8080(memory, io);
  const v06c = new c.Vector06c(cpu, memory, io, ay, { advance() {}, sample: 0, reset() {} });
  v06c.bmp = new Uint32Array(576 * 288); v06c.displayFrame = () => {}; v06c.check_breakpoint = () => false; v06c.dbg = null;
  const img = new Uint8Array(0x10000); img.set(new Uint8Array(fs.readFileSync(base + '.rom')), 0x100);
  memory.init_from_array(img, 0); memory.detach_boot && memory.detach_boot();
  cpu.pc = 0x100; cpu.sp = 0; cpu.iff = false;
  const R = { b: 0, c: 1, d: 2, e: 3, h: 4, l: 5, a: 7 };
  const m = {
    cpu, memory, keyboard, v06c, io, frames: 0, L: parseSym(base + '.sym'),
    at: (x) => (typeof x === 'number' ? x : (x in m.L ? m.L[x] : (() => { throw new Error('нет метки ' + x); })())),
    rd: (a) => memory.bytes[memory.tobank(m.at(a) & 0xffff)],
    rd16: (a) => m.rd(m.at(a)) | (m.rd(m.at(a) + 1) << 8),
    wr: (a, bytes) => { const at = m.at(a); (Array.isArray(bytes) || ArrayBuffer.isView(bytes) ? [...bytes] : [bytes]).forEach((b, i) => { memory.bytes[memory.tobank((at + i) & 0xffff)] = b & 255; }); },
    mem() { const out = new Uint8Array(0x10000); for (let a = 0; a < 0x10000; a++) out[a] = m.rd(a); return out; },
    // кадры машины: процессор, видеотракт, прерывание кадра
    frame(n = 1) { for (let i = 0; i < n; i++) { v06c.oneInterrupt(true); m.frames++; } },
    key(row, bit, down) { if (down) keyboard.matrix[row] |= bit; else keyboard.matrix[row] &= ~bit; },
    // Вызвать одну процедуру: регистры и память на входе → регистры, флаги, такты на выходе. Прерываний нет.
    call(label, { a = 0, b = 0, c = 0, d = 0, e = 0, h = 0, l = 0, cf = 0, mem = {}, prof = null, tick = null } = {}, maxInsns = 5e6) {
      for (const [k, v] of Object.entries(mem)) m.wr(k in m.L ? m.L[k] : Number(k), Array.isArray(v) ? v : [v]);
      const save = { pc: cpu.pc, sp: cpu.sp, iff: cpu.iff, regs: [...cpu.regs] };
      const inp = { a, b, c, d, e, h, l };
      for (const k of Object.keys(R)) cpu.regs[R[k]] = inp[k] & 255;
      cpu.cf = cf ? 1 : 0; cpu.iff = false;
      const sp = (cpu.sp - 2) & 0xffff;           // под стеком прерванной программы
      m.wr(RET, [0x76]); m.wr(sp, [RET & 255, RET >> 8]);
      cpu.sp = sp; cpu.pc = m.at(label);
      let cycles = 0, n = 0;
      while ((cpu.pc & 0xffff) !== RET) {
        const at = cpu.pc & 0xffff;
        cpu.instruction(); cycles += cpu.vcycles | 0;
        if (tick) tick(cycles);                            // время в тактах — для обмена с магнитофоном
        if (prof) prof[at] += cpu.vcycles | 0;             // профиль: такты по адресам команд
        if (cpu.last_opcode === 0xd3) io.commit();
        if (++n > maxInsns) throw new Error(`call ${label}: не вернулась за ${maxInsns} команд, PC=${(cpu.pc & 0xffff).toString(16)}`);
      }
      const r = { cf: +cpu.cf, zf: +cpu.zf, sf: +cpu.sf, cycles, insns: n };
      for (const k of Object.keys(R)) r[k] = cpu.regs[R[k]];
      r.hl = (r.h << 8) | r.l; r.de = (r.d << 8) | r.e; r.bc = (r.b << 8) | r.c;
      cpu.pc = save.pc; cpu.sp = save.sp; cpu.iff = save.iff; save.regs.forEach((v, i) => { cpu.regs[i] = v; });
      return r;
    },
    // Исполнять программу (без видео и прерываний) до прихода в метку; хотя бы одна команда. Возврат — такты.
    runTo(label, maxInsns = 2e8, prof = null) {
      const at = m.at(label); let cycles = 0, n = 0;
      do { const pc = cpu.pc & 0xffff; cpu.instruction(); cycles += cpu.vcycles | 0; if (prof) prof[pc] += cpu.vcycles | 0; if (cpu.last_opcode === 0xd3) io.commit(); if (++n > maxInsns) throw new Error(`runTo ${label}: не дошли за ${maxInsns} команд, PC=${(cpu.pc & 0xffff).toString(16)}`); } while ((cpu.pc & 0xffff) !== at);
      return cycles;
    },
    bmp: () => v06c.bmp,
  };
  return m;
}

// кадр эмулятора 576×288 (с бордюром) → PNG
export function savePng(bmp, out, Wd = 576, Ht = 288) {
  const raw = Buffer.alloc(Ht * (Wd * 3 + 1));
  for (let y = 0; y < Ht; y++) for (let x = 0; x < Wd; x++) { const c = bmp[y * Wd + x], o = y * (Wd * 3 + 1) + 1 + x * 3; raw[o] = c & 255; raw[o + 1] = (c >> 8) & 255; raw[o + 2] = (c >> 16) & 255; }
  const chunk = (t, d) => { const b = Buffer.alloc(d.length + 12); b.writeUInt32BE(d.length, 0); b.write(t, 4, 'latin1'); d.copy(b, 8); b.writeUInt32BE(zlib.crc32(b.subarray(4, d.length + 8)) >>> 0, d.length + 8); return b; };
  const ih = Buffer.alloc(13); ih.writeUInt32BE(Wd, 0); ih.writeUInt32BE(Ht, 4); ih[8] = 8; ih[9] = 2;
  fs.mkdirSync(path.dirname(out), { recursive: true });
  fs.writeFileSync(out, Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ih), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]));
}
