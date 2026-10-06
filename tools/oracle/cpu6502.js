// Ядро 6502 (NMOS, только документированные команды, без десятичного режима).
// Память и порты — через функции rd(addr) и wr(addr, value) хозяина.
'use strict';

const C = 1, Z = 2, I = 4, D = 8, B = 16, U = 32, V = 64, N = 128;

// Таблица команд: код → [мнемоника, адресация, такты, +1 при переходе через страницу].
const OPS = new Array(256).fill(null);
function def(mn, list) {
  for (const [op, mode, cyc, px] of list) OPS[op] = { mn, mode, cyc, px: !!px };
}
const ALU = (b) => [[b + 0x09, 'imm', 2], [b + 0x05, 'zp', 3], [b + 0x15, 'zpx', 4], [b + 0x0d, 'abs', 4],
  [b + 0x1d, 'abx', 4, 1], [b + 0x19, 'aby', 4, 1], [b + 0x01, 'izx', 6], [b + 0x11, 'izy', 5, 1]];
const RMW = (b) => [[b + 0x0a, 'acc', 2], [b + 0x06, 'zp', 5], [b + 0x16, 'zpx', 6], [b + 0x0e, 'abs', 6],
  [b + 0x1e, 'abx', 7]];
def('ORA', ALU(0x00)); def('AND', ALU(0x20)); def('EOR', ALU(0x40)); def('ADC', ALU(0x60));
def('LDA', ALU(0xa0)); def('CMP', ALU(0xc0)); def('SBC', ALU(0xe0));
def('STA', [[0x85, 'zp', 3], [0x95, 'zpx', 4], [0x8d, 'abs', 4], [0x9d, 'abx', 5], [0x99, 'aby', 5],
  [0x81, 'izx', 6], [0x91, 'izy', 6]]);
def('ASL', RMW(0x00)); def('ROL', RMW(0x20)); def('LSR', RMW(0x40)); def('ROR', RMW(0x60));
def('DEC', [[0xc6, 'zp', 5], [0xd6, 'zpx', 6], [0xce, 'abs', 6], [0xde, 'abx', 7]]);
def('INC', [[0xe6, 'zp', 5], [0xf6, 'zpx', 6], [0xee, 'abs', 6], [0xfe, 'abx', 7]]);
def('LDX', [[0xa2, 'imm', 2], [0xa6, 'zp', 3], [0xb6, 'zpy', 4], [0xae, 'abs', 4], [0xbe, 'aby', 4, 1]]);
def('LDY', [[0xa0, 'imm', 2], [0xa4, 'zp', 3], [0xb4, 'zpx', 4], [0xac, 'abs', 4], [0xbc, 'abx', 4, 1]]);
def('STX', [[0x86, 'zp', 3], [0x96, 'zpy', 4], [0x8e, 'abs', 4]]);
def('STY', [[0x84, 'zp', 3], [0x94, 'zpx', 4], [0x8c, 'abs', 4]]);
def('CPX', [[0xe0, 'imm', 2], [0xe4, 'zp', 3], [0xec, 'abs', 4]]);
def('CPY', [[0xc0, 'imm', 2], [0xc4, 'zp', 3], [0xcc, 'abs', 4]]);
def('BIT', [[0x24, 'zp', 3], [0x2c, 'abs', 4]]);
def('JMP', [[0x4c, 'abs', 3], [0x6c, 'ind', 5]]);
def('JSR', [[0x20, 'abs', 6]]);
for (const [mn, op] of [['BPL', 0x10], ['BMI', 0x30], ['BVC', 0x50], ['BVS', 0x70], ['BCC', 0x90], ['BCS', 0xb0],
  ['BNE', 0xd0], ['BEQ', 0xf0]]) def(mn, [[op, 'rel', 2]]);
for (const [mn, op, cyc] of [['BRK', 0x00, 7], ['RTI', 0x40, 6], ['RTS', 0x60, 6], ['PHP', 0x08, 3], ['PLP', 0x28, 4],
  ['PHA', 0x48, 3], ['PLA', 0x68, 4], ['CLC', 0x18, 2], ['SEC', 0x38, 2], ['CLI', 0x58, 2], ['SEI', 0x78, 2],
  ['CLV', 0xb8, 2], ['CLD', 0xd8, 2], ['SED', 0xf8, 2], ['DEY', 0x88, 2], ['INY', 0xc8, 2], ['DEX', 0xca, 2],
  ['INX', 0xe8, 2], ['TXA', 0x8a, 2], ['TAX', 0xaa, 2], ['TYA', 0x98, 2], ['TAY', 0xa8, 2], ['TXS', 0x9a, 2],
  ['TSX', 0xba, 2], ['NOP', 0xea, 2]]) def(mn, [[op, 'imp', cyc]]);

class CPU6502 {
  constructor(rd, wr) {
    this.rd = rd; this.wr = wr;
    this.a = 0; this.x = 0; this.y = 0; this.s = 0xff; this.p = U | I; this.pc = 0;
    this.cycles = 0;
  }
  push(v) { this.wr(0x100 | this.s, v & 0xff); this.s = (this.s - 1) & 0xff; }
  pull() { this.s = (this.s + 1) & 0xff; return this.rd(0x100 | this.s); }
  rd16(a) { return this.rd(a) | (this.rd((a + 1) & 0xffff) << 8); }
  nz(v) { this.p = (this.p & ~(N | Z)) | (v & 0x80) | (v === 0 ? Z : 0); return v; }
  irq() {
    this.push(this.pc >> 8); this.push(this.pc); this.push((this.p | U) & ~B);
    this.p |= I; this.pc = this.rd16(0xfffe); this.cycles += 7;
  }
  rts() { const lo = this.pull(); this.pc = ((lo | (this.pull() << 8)) + 1) & 0xffff; }
  rti() { this.p = (this.pull() | U) & ~B; const lo = this.pull(); this.pc = lo | (this.pull() << 8); }
  step() {
    const op = this.rd(this.pc); const d = OPS[op];
    if (!d) throw new Error(`недокументированный код ${op.toString(16)} по адресу ${this.pc.toString(16)}`);
    this.pc = (this.pc + 1) & 0xffff;
    let ea = -1, cyc = d.cyc;
    const b = () => { const v = this.rd(this.pc); this.pc = (this.pc + 1) & 0xffff; return v; };
    const w = () => { const lo = b(); return lo | (b() << 8); };
    switch (d.mode) {
      case 'imm': ea = this.pc; this.pc = (this.pc + 1) & 0xffff; break;
      case 'zp': ea = b(); break;
      case 'zpx': ea = (b() + this.x) & 0xff; break;
      case 'zpy': ea = (b() + this.y) & 0xff; break;
      case 'abs': ea = w(); break;
      case 'abx': { const base = w(); ea = (base + this.x) & 0xffff; if (d.px && (ea ^ base) & 0xff00) cyc++; break; }
      case 'aby': { const base = w(); ea = (base + this.y) & 0xffff; if (d.px && (ea ^ base) & 0xff00) cyc++; break; }
      case 'izx': { const z = (b() + this.x) & 0xff; ea = this.rd(z) | (this.rd((z + 1) & 0xff) << 8); break; }
      case 'izy': {
        const z = b(); const base = this.rd(z) | (this.rd((z + 1) & 0xff) << 8);
        ea = (base + this.y) & 0xffff; if (d.px && (ea ^ base) & 0xff00) cyc++; break;
      }
      case 'ind': { const p = w(); ea = this.rd(p) | (this.rd((p & 0xff00) | ((p + 1) & 0xff)) << 8); break; }
      case 'rel': { const o = b(); ea = (this.pc + (o < 0x80 ? o : o - 256)) & 0xffff; break; }
    }
    const rmw = (f) => {
      if (d.mode === 'acc') this.a = f(this.a); else this.wr(ea, f(this.rd(ea)));
    };
    const br = (c) => { if (c) { cyc += 1 + (((ea ^ this.pc) & 0xff00) ? 1 : 0); this.pc = ea; } };
    const cmp = (r, v) => { const t = r - v; this.p = (this.p & ~C) | (t >= 0 ? C : 0); this.nz(t & 0xff); };
    const adc = (v) => {
      if (this.p & D) throw new Error('десятичный режим не поддержан');
      const t = this.a + v + (this.p & C);
      this.p = (this.p & ~(C | V)) | (t > 0xff ? C : 0) | ((~(this.a ^ v) & (this.a ^ t) & 0x80) ? V : 0);
      this.a = this.nz(t & 0xff);
    };
    switch (d.mn) {
      case 'LDA': this.a = this.nz(this.rd(ea)); break;
      case 'LDX': this.x = this.nz(this.rd(ea)); break;
      case 'LDY': this.y = this.nz(this.rd(ea)); break;
      case 'STA': this.wr(ea, this.a); break;
      case 'STX': this.wr(ea, this.x); break;
      case 'STY': this.wr(ea, this.y); break;
      case 'ORA': this.a = this.nz(this.a | this.rd(ea)); break;
      case 'AND': this.a = this.nz(this.a & this.rd(ea)); break;
      case 'EOR': this.a = this.nz(this.a ^ this.rd(ea)); break;
      case 'ADC': adc(this.rd(ea)); break;
      case 'SBC': adc(this.rd(ea) ^ 0xff); break;
      case 'CMP': cmp(this.a, this.rd(ea)); break;
      case 'CPX': cmp(this.x, this.rd(ea)); break;
      case 'CPY': cmp(this.y, this.rd(ea)); break;
      case 'BIT': {
        const v = this.rd(ea);
        this.p = (this.p & ~(N | V | Z)) | (v & 0xc0) | ((v & this.a) === 0 ? Z : 0); break;
      }
      case 'ASL': rmw((v) => { this.p = (this.p & ~C) | (v >> 7); return this.nz((v << 1) & 0xff); }); break;
      case 'LSR': rmw((v) => { this.p = (this.p & ~C) | (v & 1); return this.nz(v >> 1); }); break;
      case 'ROL': rmw((v) => { const c = this.p & C; this.p = (this.p & ~C) | (v >> 7); return this.nz(((v << 1) | c) & 0xff); }); break;
      case 'ROR': rmw((v) => { const c = this.p & C; this.p = (this.p & ~C) | (v & 1); return this.nz((v >> 1) | (c << 7)); }); break;
      case 'INC': this.wr(ea, this.nz((this.rd(ea) + 1) & 0xff)); break;
      case 'DEC': this.wr(ea, this.nz((this.rd(ea) - 1) & 0xff)); break;
      case 'INX': this.x = this.nz((this.x + 1) & 0xff); break;
      case 'INY': this.y = this.nz((this.y + 1) & 0xff); break;
      case 'DEX': this.x = this.nz((this.x - 1) & 0xff); break;
      case 'DEY': this.y = this.nz((this.y - 1) & 0xff); break;
      case 'TAX': this.x = this.nz(this.a); break;
      case 'TAY': this.y = this.nz(this.a); break;
      case 'TXA': this.a = this.nz(this.x); break;
      case 'TYA': this.a = this.nz(this.y); break;
      case 'TSX': this.x = this.nz(this.s); break;
      case 'TXS': this.s = this.x; break;
      case 'PHA': this.push(this.a); break;
      case 'PLA': this.a = this.nz(this.pull()); break;
      case 'PHP': this.push(this.p | B | U); break;
      case 'PLP': this.p = (this.pull() | U) & ~B; break;
      case 'CLC': this.p &= ~C; break;
      case 'SEC': this.p |= C; break;
      case 'CLI': this.p &= ~I; break;
      case 'SEI': this.p |= I; break;
      case 'CLV': this.p &= ~V; break;
      case 'CLD': this.p &= ~D; break;
      case 'SED': throw new Error('SED: десятичный режим не поддержан');
      case 'NOP': break;
      case 'JMP': this.pc = ea; break;
      case 'JSR': { const r = (this.pc - 1) & 0xffff; this.push(r >> 8); this.push(r); this.pc = ea; break; }
      case 'RTS': this.rts(); break;
      case 'RTI': this.rti(); break;
      case 'BRK': throw new Error(`BRK по адресу ${(this.pc - 1).toString(16)}`);
      case 'BPL': br(!(this.p & N)); break;
      case 'BMI': br(this.p & N); break;
      case 'BVC': br(!(this.p & V)); break;
      case 'BVS': br(this.p & V); break;
      case 'BCC': br(!(this.p & C)); break;
      case 'BCS': br(this.p & C); break;
      case 'BNE': br(!(this.p & Z)); break;
      case 'BEQ': br(this.p & Z); break;
    }
    this.cycles += cyc;
    return cyc;
  }
}

module.exports = { CPU6502, FLAGS: { C, Z, I, D, B, U, V, N } };
