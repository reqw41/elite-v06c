// Долгий прогон обычного образа на «нестёртые» точки. Сценарии сверки проверяют экран против BBC только в образе
// стенда и только на своих маршрутах; здесь — обычный образ (корабли ZX и дисковой версии, второй цвет, печать
// без мерцания) в настоящих кадрах: взлёт, постоянный крен и тангаж со сменой направления, огонь, беглец
// (полиция нападает), щиты и энергия пополняются; корабли появляются чаще обычного и время от времени взрываются. Всё, что нарисовано в обзоре, при этом движется; точка, которая
// горит на одном месте много проверок подряд, — мусор, оставшийся от нестёртого отрезка.
// Не считаются: рамка, строка названия вида и сообщений, перекрестие прицела.
// node v06c/test/soak.mjs [кадров = 60000]
import path from 'node:path';
import { createVector, savePng, ROOT } from '../tools/v06c.mjs';
const FRAMES = +(process.argv[2] || 60000), STEP = 20, STUCK = 60;      // 60 проверок подряд = 24 с на одном месте
const g = createVector('elite'), L = g.L;
const K = { SPACE: [7, 0x80], N: [5, 0x40], F1: [1, 0x08], A: [4, 0x02], S: [6, 0x08], X: [7, 0x01], LT: [3, 0x10], GT: [3, 0x40] };
const key = (k, d) => g.key(K[k][0], K[k][1], d);
const press = (k) => { key(k, true); g.frame(20); key(k, false); };
g.frame(300); press('N'); g.frame(200); press('SPACE'); g.frame(200); press('F1'); g.frame(300);
key('SPACE', true); g.frame(1500); key('SPACE', false);                 // разгон: уйти из зоны станции
if (g.rd(L.QQ12) !== 0) { console.log('ПРОВАЛ: взлёт не состоялся'); process.exit(1); }
g.wr(L.LASER, [0x97, 0x97, 0x97, 0x97]); g.wr(L.FIST, [0xFF]);
const skip = (x, y) => y < 16 || y > 183 || x < 2 || x > 253 || (Math.abs(x - 128) < 3 && Math.abs(y - 96) < 28) || (Math.abs(y - 96) < 3 && Math.abs(x - 128) < 28);
const streak = new Uint16Array(256 * 192), worst = new Uint16Array(256 * 192);
let types = new Set(), kills0 = g.rd(L.TALLY) | (g.rd(L.TALLY + 1) << 8), deaths = 0, maxShips = 0, samples = 0, bad = 0, blown = 0;
let rs = 2024; const rnd = (n) => { rs = (rs * 1103515245 + 12345) >>> 0; return (rs >>> 16) % n; };
const held = new Set();
for (let f = 0; f < FRAMES; f += STEP) {
  if (f % 400 === 0) { for (const k of held) key(k, false); held.clear();
    for (const k of [['LT', 'GT'][rnd(2)], ['S', 'X'][rnd(2)], 'A']) { key(k, true); held.add(k); } if (rnd(3) === 0) { key('SPACE', true); held.add('SPACE'); } }
  g.frame(STEP);
  if (g.rd(L.QQ12) !== 0) {                                    // погибли или пристыковались: заново в полёт
    deaths++; for (const k of held) key(k, false); held.clear();
    g.frame(400); press('N'); g.frame(200); press('SPACE'); g.frame(200); press('F1'); g.frame(300);
    g.wr(L.LASER, [0x97, 0x97, 0x97, 0x97]); g.wr(L.FIST, [0xFF]); streak.fill(0); continue; }
  // чаще новые корабли: счётчик появления почти истёк, анархия; раз в 10 с один из кораблей взрывается (как от бомбы)
  g.wr(L.EV, [0]); g.wr(L.gov, [0]); if (f % 60 === 0) { const v = ((g.rd(L.v_frames) | (g.rd(L.v_frames + 1) << 8)) - 0x500) & 0xffff; g.wr(L.sp_last, [v & 255, v >> 8]); }   // проверка появления — раз в 60 кадров
  if (f % 500 === 0) { const live = []; for (let i = 2; i < 12; i++) { const t = g.rd(L.FRIN + i); if (t && t < 128 && t !== 8 && !(g.rd(L.K_ + 36 * i + 31) & 0xA0)) live.push(i); }   // как бомба: уже взрывающиеся не трогаем
    if (live.length) { const i = live[rnd(live.length)], a = L.K_ + 36 * i + 31; g.wr(a, [g.rd(a) | 0x80]); blown++; } }
  g.wr(L.ENERGY, [255]); g.wr(L.FSH, [255]); g.wr(L.ASH, [255]); g.wr(L.GNTMP, [0]); g.wr(L.CABTMP, [0]); g.wr(L.ALTIT, [255]);
  if (g.rd(L.QQ11) !== 0 || g.rd(L.MJ) !== 0) { streak.fill(0); continue; }
  const fr = Array.from({ length: 13 }, (_, i) => g.rd(L.FRIN + i)); fr.forEach((t) => { if (t && t < 128) types.add(t); });
  maxShips = Math.max(maxShips, fr.filter((t) => t && t < 128).length); samples++;
  for (let col = 0; col < 32; col++) for (let y = 16; y < 184; y++) {
    const v = g.rd(0xC000 + col * 256 + 255 - y) | g.rd(0xE000 + col * 256 + 255 - y);
    for (let b = 0; b < 8; b++) { const x = col * 8 + b, i = y * 256 + x;
      if ((v >> (7 - b)) & 1 && !skip(x, y)) { if (++streak[i] > worst[i]) worst[i] = streak[i]; } else streak[i] = 0; } }
}
const stuck = []; for (let i = 0; i < worst.length; i++) if (worst[i] >= STUCK) stuck.push([i & 255, i >> 8, worst[i]]);
const kills = (g.rd(L.TALLY) | (g.rd(L.TALLY + 1) << 8)) - kills0;
const top = Math.max(...worst);
savePng(g.bmp(), path.join(ROOT, 'work/v06c/soak-end.png'));
console.log(`прогон ${FRAMES} кадров (${(FRAMES / 3000).toFixed(0)} мин игры), проверок экрана ${samples}; типы объектов: ${[...types].sort((a, b) => a - b).join(' ')}; кораблей разом до ${maxShips}; взорвано ${blown}, побед ${kills}, гибелей и стыковок ${deaths}`);
console.log(`дольше всего одна точка горела на месте ${top} проверок подряд (${(top * STEP / 50).toFixed(0)} с); порог «залипла» — ${STUCK}`);
if (stuck.length) { bad = 1; console.log(`залипших точек ${stuck.length}: ` + stuck.slice(0, 20).map(([x, y, n]) => `(${x},${y})×${n}`).join(' ')); }
console.log(bad ? 'ПРОВАЛ: 1' : 'SOAK: нестёртых точек нет');
process.exit(bad);
