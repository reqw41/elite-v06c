// Экран BBC и экран Вектора в одном виде — для сверки до точки.
// Обзор: 192 строки по 32 байта, [y*32 + col], бит 7 — левая точка.
// Панель: 56 строк по 256 точек, [y*256 + x], цвет 0..3 (логический цвет BBC; точка BBC — две точки Вектора).
export const VIEW = 0xC000, PLANE2 = 0xE000, DASH_Y = 192, DASH_H = 56;

export function bbcView(mem) {
  const v = new Uint8Array(32 * 192);
  for (let y = 0; y < 192; y++) for (let c = 0; c < 32; c++) v[y * 32 + c] = mem[0x6000 + (y >> 3) * 256 + c * 8 + (y & 7)];
  return v;
}
export function vecView(mem, plane = VIEW) {
  const v = new Uint8Array(32 * 192);
  for (let y = 0; y < 192; y++) for (let c = 0; c < 32; c++) v[y * 32 + c] = mem[plane + c * 256 + 255 - y];
  return v;
}
export function bbcDash(mem) {
  const v = new Uint8Array(256 * DASH_H);
  for (let y = 0; y < DASH_H; y++) for (let X = 0; X < 128; X++) {
    const b = mem[0x7800 + (y >> 3) * 256 + (X >> 2) * 8 + (y & 7)], k = X & 3;
    v[y * 256 + 2 * X] = v[y * 256 + 2 * X + 1] = ((b >> (7 - k)) & 1) * 2 + ((b >> (3 - k)) & 1);
  }
  return v;
}
export function vecDash(mem) {
  const v = new Uint8Array(256 * DASH_H);
  for (let y = 0; y < DASH_H; y++) for (let x = 0; x < 256; x++) {
    const off = (x >> 3) * 256 + 255 - (DASH_Y + y), bit = 7 - (x & 7);
    v[y * 256 + x] = ((mem[VIEW + off] >> bit) & 1) * 2 + ((mem[PLANE2 + off] >> bit) & 1);
  }
  return v;
}
// Первое различие двух массивов: {i, a, b} или null.
export function firstDiff(a, b) {
  if (a.length !== b.length) return { i: -1, a: a.length, b: b.length };
  for (let i = 0; i < a.length; i++) if (a[i] !== b[i]) return { i, a: a[i], b: b[i] };
  return null;
}
