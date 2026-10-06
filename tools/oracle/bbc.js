// Эталон: кассетная версия BBC Elite в голом ядре 6502 с заглушками системы BBC.
// Образ памяти собирается из файлов orig/bbc/cassette (как его оставляет загрузчик), ПЗУ системы нужно
// только ради шрифта (&C000–&C2FF). Всё, что игра делает с железом: VIA (кадр, таймер, клавиши),
// видеосхема (&FE20/&FE21), OSBYTE, OSWORD, OSFILE.
'use strict';
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const { CPU6502, FLAGS } = require('./cpu6502.js');

const ROOT = path.resolve(__dirname, '../..');
const CAS = path.join(ROOT, 'orig/bbc/cassette');
const FRAME = 40000;            // тактов 6502 на кадр: 2 МГц, 50 Гц
const VEC_STUB = 0xff80;        // сюда указывает VEC: «системное» завершение прерывания
const IRQ_STUB = 0xff90;        // вход в прерывание: STA &FC, JMP (&0204)

function loadLabels() {
  const t = fs.readFileSync(path.join(CAS, '3-assembled-output/compile.txt'), 'latin1');
  const lab = {};
  // Метки загрузчика идут в листинге после меток игры; при совпадении имён берём первую (игру).
  for (const m of t.matchAll(/^\.(\S+)\r?\n\s+([0-9A-F]{4})\b/gm)) if (!(m[1] in lab)) lab[m[1]] = parseInt(m[2], 16);
  return lab;
}

class BBC {
  // sched: true — время по расписанию: прерываний кадра нет, кадры отсчитывает tick() на границе прохода.
  constructor({ sched = false } = {}) {
    this.sched = sched;
    this.mem = new Uint8Array(0x10000);
    this.lab = loadLabels();
    this.cpu = new CPU6502((a) => this.rd(a), (a, v) => this.wr(a, v));
    this.keys = new Set();      // нажатые клавиши, внутренние номера BBC
    this.ifr = 0; this.t1 = -1; this.t1latch = 0; this.kbLatch = 0;
    this.nextVsync = FRAME; this.frames = 0;
    this.ula = new Uint8Array(16); this.palView = new Uint8Array(16); this.palDash = new Uint8Array(16);
    this.sounds = [];           // журнал звуков: {frame, block: 8 байт}
    this.hooks = new Map();     // адрес → функция; вернуть true — «выполнить RTS»
    this.watch = new Map();     // адрес → функция наблюдения, исполнение продолжается
    this.load();
  }

  load() {
    const m = this.mem, L = this.lab;
    const out = (f) => fs.readFileSync(path.join(CAS, '3-assembled-output', f));
    const code = Buffer.concat(['ELTA', 'ELTB', 'ELTC', 'ELTD', 'ELTE', 'ELTF', 'ELTG'].map((n) => out(n + '.bin')));
    m.set(code, L['S%']);
    // Между кодом и моделями — байт контрольной суммы (checksum0); модели начинаются с метки XX21.
    m.set(out('SHIPS.bin'), L.XX21);
    this.codeEnd = L.XX21 + out('SHIPS.bin').length;
    m[L.checksum0] = 0x20;
    // Генератор случайных чисел игра сама не засевает: в RAND остаётся то, что оставил загрузчик (он рисует
    // Сатурн случайными точками). Значение снято с настоящего BBC в jsbeeb (tools/oracle/jsbeeb_dump.mjs).
    m.set([0xc7, 0x94, 0x27, 0x1d], L.RAND);
    m.set(out('WORDS9.bin'), 0x0400);
    m.set(out('PYTHON.bin'), 0x7f00);
    m.set(fs.readFileSync(path.join(CAS, '1-source-files/images/P.DIALS.bin')), 0x7800);
    const rom = path.join(ROOT, 'orig/bbc/mos/os120.rom');
    if (!fs.existsSync(rom)) throw new Error('нет orig/bbc/mos/os120.rom (ПЗУ системы BBC, нужен шрифт)');
    m.set(fs.readFileSync(rom), 0xc000);
    const w16 = (a, v) => { m[a] = v & 0xff; m[a + 1] = v >> 8; };
    // Векторы, которые ставит загрузчик из таблицы S%: WRCHV, IRQ1V, BRKV; VEC — прежний IRQ1V.
    w16(0x020e, L.TT26); w16(0x0204, L.IRQ1); w16(0x0202, L.BR1);
    w16(L.VEC, VEC_STUB);
    w16(0xfffe, IRQ_STUB);
    m.set([0x85, 0xfc, 0x6c, 0x04, 0x02], IRQ_STUB);      // STA &FC : JMP (&0204)
    m.set([0xa5, 0xfc, 0x40], VEC_STUB);                  // LDA &FC : RTI
    this.watch.set(VEC_STUB, () => { this.ifr = 0; });    // система сбрасывает запросы прерывания
    this.hooks.set(0xfff4, () => this.osbyte());
    this.hooks.set(0xfff1, () => this.osword());
    this.hooks.set(0xffdd, () => { throw new Error('OSFILE: сохранение в эталоне не сделано'); });
    if (this.sched) {
      // WSCAN ждёт кадра по флагу DL, который ставит обработчик: по расписанию возвращаемся сразу.
      this.hooks.set(L.WSCAN, () => { m[L.DL] = 30; this.cpu.a = 30; this.cpu.p &= ~0x82; return true; });
    }
    this.cpu.pc = m[L['S%']] | (m[L['S%'] + 1] << 8);      // TT170
    this.cpu.s = 0xff; this.cpu.p = FLAGS.U;
  }

  rd(a) {
    if (a >= 0xfe00 && a < 0xff00) return this.ioRead(a);
    return this.mem[a];
  }
  wr(a, v) {
    if (a >= 0xfe00 && a < 0xff00) return this.ioWrite(a, v);
    if (a < 0x8000) this.mem[a] = v;
  }
  ioRead(a) {
    switch (a) {
      case 0xfe4d: return this.ifr | ((this.ifr & 0x42) ? 0x80 : 0);
      case 0xfe41: this.ifr &= ~0x02; return 0xff;         // чтение IRA снимает запрос кадра
      case 0xfe44: this.ifr &= ~0x40; return 0;
      case 0xfe4f: return (this.kbLatch & 0x7f) | (this.keys.has(this.kbLatch & 0x7f) ? 0x80 : 0);
      case 0xfe40: return 0xff;                            // бит 4 = 1: кнопка джойстика не нажата
      default: return 0xff;
    }
  }
  ioWrite(a, v) {
    switch (a) {
      case 0xfe44: this.t1latch = v; break;
      case 0xfe45: this.t1 = this.cpu.cycles + ((v << 8) | this.t1latch) * 2; this.ifr &= ~0x40; break;
      case 0xfe4f: this.kbLatch = v; break;
      case 0xfe21: this.ula[v >> 4] = (v & 0x0f) ^ 7; break;
      default: break;
    }
  }
  osbyte() {
    const c = this.cpu;
    if (c.a === 128) { c.x = 0; c.y = 0x80; }             // джойстик в середине
    return true;                                           // 15 (сброс буферов), 200 — без действия
  }
  osword() {
    const c = this.cpu;
    if (c.a === 7) {
      const p = c.x | (c.y << 8);
      this.sounds.push({ frame: this.frames, block: Array.from(this.mem.subarray(p, p + 8)) });
      return true;
    }
    throw new Error(`OSWORD ${c.a}: в эталоне не сделано`);
  }

  // Один шаг: прерывания, перехваты, команда.
  step() {
    const c = this.cpu;
    if (this.sched) { const h0 = this.hooks.get(c.pc); if (h0) { if (h0(this)) c.rts(); return; } const w0 = this.watch.get(c.pc); if (w0) w0(this); c.step(); return; }
    if (c.cycles >= this.nextVsync) {
      this.nextVsync += FRAME; this.frames++; this.ifr |= 0x02;
      this.palDash.set(this.ula);                          // к концу кадра стоит палитра панели
    }
    if (this.t1 >= 0 && c.cycles >= this.t1) { this.t1 = -1; this.ifr |= 0x40; this.palView.set(this.ula); }
    if ((this.ifr & 0x42) && !(c.p & FLAGS.I)) c.irq();
    const w = this.watch.get(c.pc); if (w) w(this);
    const h = this.hooks.get(c.pc);
    if (h) { if (h(this)) c.rts(); return; }
    c.step();
  }
  runFrames(n) { const end = this.frames + n; while (this.frames < end) this.step(); }
  // Исполнять до прихода в адрес (метку); вернуть false, если не дошли за maxFrames кадров.
  runTo(label, maxFrames = 500) {
    const a = typeof label === 'number' ? label : this.lab[label];
    const end = this.frames + maxFrames;
    do { this.step(); } while (this.cpu.pc !== a && this.frames < end);
    return this.cpu.pc === a;
  }
  // Вызвать одну процедуру игры: регистры и память на входе → регистры, флаги и такты на выходе.
  // Прерывания на время вызова закрыты, память после вызова остаётся изменённой.
  call(label, { a = 0, x = 0, y = 0, c = 0, mem = {} } = {}, maxCycles = 2e6) {
    const cpu = this.cpu, RET = 0xffa0;
    for (const [k, v] of Object.entries(mem)) {
      const at = k in this.lab ? this.lab[k] : Number(k);
      (Array.isArray(v) ? v : [v]).forEach((b, i) => { this.mem[at + i] = b & 0xff; });
    }
    const save = { pc: cpu.pc, s: cpu.s, p: cpu.p };
    cpu.a = a & 0xff; cpu.x = x & 0xff; cpu.y = y & 0xff; cpu.p = FLAGS.U | FLAGS.I | (c ? FLAGS.C : 0);
    cpu.s = 0xfd; this.mem[0x1fe] = (RET - 1) & 0xff; this.mem[0x1ff] = (RET - 1) >> 8;
    cpu.pc = typeof label === 'number' ? label : this.lab[label];
    const start = cpu.cycles;
    while (cpu.pc !== RET) {
      const h = this.hooks.get(cpu.pc);
      if (h) { if (h(this)) cpu.rts(); } else cpu.step();
      if (cpu.cycles - start > maxCycles) throw new Error(`call ${label}: не вернулась за ${maxCycles} тактов`);
    }
    const r = { a: cpu.a, x: cpu.x, y: cpu.y, c: cpu.p & 1, z: (cpu.p >> 1) & 1, n: cpu.p >> 7, v: (cpu.p >> 6) & 1, cycles: cpu.cycles - start };
    this.nextVsync += cpu.cycles - start;                 // время вызова в кадры не идёт
    Object.assign(cpu, save);
    return r;
  }
  peek(label, n = 1) { const at = typeof label === 'number' ? label : this.lab[label]; return n === 1 ? this.mem[at] : Array.from(this.mem.subarray(at, at + n)); }
  // Кадр по расписанию: всё, что обработчик кадра делает с состоянием игры, — DL и счётчик паузы лазера.
  tick(n = 1) {
    const L = this.lab;
    for (let i = 0; i < n; i++) { this.frames++; this.mem[L.DL] = 30; if (this.mem[L.LASCT]) this.mem[L.LASCT]--; }
    this.palView.set([0, 0, 0, 0, 0, 0, 0, 0, 7, 7, 7, 7, 7, 7, 7, 7]);
    this.palDash.set([0, 0, 1, 1, 0, 0, 1, 1, 3, 3, 2, 2, 3, 3, 2, 2]);
  }
  // Один проход цикла по расписанию: идти до метки, затем отсчитать k кадров.
  pass(label, k = 2, maxCycles = 4e7) {
    const a = this.lab[label], end = this.cpu.cycles + maxCycles;
    do { this.step(); } while (this.cpu.pc !== a && this.cpu.cycles < end);
    if (this.cpu.pc !== a) throw new Error(`проход не дошёл до ${label}`);
    this.tick(k);
  }
  // Состояние игры для сверки: нулевая страница игры, пилот, блоки кораблей, слоты и переменные, экран.
  state() {
    return { zp: this.hash(0, 0xb0), t: this.hash(0x300, 0x372), k: this.hash(0x900, 0xd40), wp: this.hash(0xd40, 0xf34),
      scr: this.hash(0x6000, 0x7f00) };
  }
  press(code, frames = 6) { this.keys.add(code); this.runFrames(frames); this.keys.delete(code); }

  // Экран 256×248: сверху режим 4 (1 бит), снизу 56 строк режима 5 (2 бита, точки двойной ширины).
  screen() {
    const W = 256, H = 248, px = new Uint8Array(W * H);    // физический цвет BBC 0–7
    for (let y = 0; y < H; y++) {
      const row = 0x6000 + (y >> 3) * 256 + (y & 7);
      for (let cx = 0; cx < 32; cx++) {
        const b = this.mem[row + cx * 8];
        for (let i = 0; i < 8; i++) {
          let col;
          if (y < 192) col = this.palView[((b >> (7 - i)) & 1) ? 8 : 0];
          else { const k = i >> 1; col = this.palDash[(((b >> (7 - k)) & 1) << 3) | (((b >> (3 - k)) & 1) << 1)]; }
          px[y * W + cx * 8 + i] = col;
        }
      }
    }
    return { w: W, h: H, px };
  }
  png(file, scale = 2) {
    const { w, h, px } = this.screen();
    const W = w * scale, H = h * scale, raw = Buffer.alloc((W * 3 + 1) * H);
    for (let y = 0; y < H; y++) {
      const o = y * (W * 3 + 1);
      for (let x = 0; x < W; x++) {
        const c = px[Math.floor(y / scale) * w + Math.floor(x / scale)];
        raw[o + 1 + x * 3] = (c & 1) ? 255 : 0; raw[o + 2 + x * 3] = (c & 2) ? 255 : 0; raw[o + 3 + x * 3] = (c & 4) ? 255 : 0;
      }
    }
    const chunk = (t, d) => {
      const b = Buffer.alloc(d.length + 12); b.writeUInt32BE(d.length, 0); b.write(t, 4, 'latin1'); d.copy(b, 8);
      b.writeUInt32BE(zlib.crc32(b.subarray(4, d.length + 8)) >>> 0, d.length + 8); return b;
    };
    const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(W, 0); ihdr.writeUInt32BE(H, 4); ihdr[8] = 8; ihdr[9] = 2;
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr),
      chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]));
  }
  hash(from, to) { return require('crypto').createHash('sha1').update(this.mem.subarray(from, to)).digest('hex').slice(0, 12); }
}

module.exports = { BBC, FRAME };
