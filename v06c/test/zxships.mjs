// Корабли версии ZX (Krait 14, Asp Mk II 15, Fer-de-Lance 16). На BBC их нет — сверять не с чем; тест проверяет,
// что игра с ними живёт: боевой сценарий fight идёт на Векторе с подменой типов (Sidewinder → Krait,
// Mamba → Asp, Cobra → Fer-de-Lance) до конца — бой лазером, ракета, таран, гибель, заставка; счёт побед растёт,
// в конце — заставка. До последней фазы щиты держатся полными: с другими противниками бой идёт не так, как в сценарии. Плюс снимки кораблей и статистика замены zx_pick.
// sh v06c/build.sh -DSCHED && sh v06c/build.sh && node v06c/test/zxships.mjs
import path from 'node:path';
import { createRequire } from 'node:module';
import { createVector, savePng, ROOT } from '../tools/v06c.mjs';
const require = createRequire(import.meta.url);
const { BBC } = require(path.join(ROOT, 'tools/oracle/bbc.js'));
const { SCN, addr } = require(path.join(ROOT, 'tools/oracle/scenario.js'));
const B = new BBC({ sched: true }).lab;
const SUB = { 1: 14, 3: 15, 5: 16 }, NAME = { 14: 'krait', 15: 'asp', 16: 'fer' };
const m = createVector('elite_t'), L = m.L, WS = L.WS;
const rows = new Array(8).fill(0);
const setKey = (code, down) => { const i = m.rd(L.kb_rev + code); if (i >= 64) return; if (down) rows[i >> 3] |= 1 << (i & 7); else rows[i >> 3] &= ~(1 << (i & 7)); m.wr(L.kb_rows, rows); };
const VL = { D2: 'death_d2' };
let idx = 0, bad = 0, seen = [], maxTally = 0, mortal = false, pend = null;
const fail = (s) => { bad++; console.log('FAIL ' + s); };
try {
  for (const step of SCN.fight) {
    const [label, n, down = [], up = [], k = 2, poke, calls] = step;
    const vput = (map) => { for (const [a, v] of Object.entries(map || {})) m.wr(WS + addr(B, a), v); };
    vput(poke);
    if (poke && poke.ENERGY) mortal = true;                  // последняя фаза сценария: гибель
    let shot = null;
    for (const [lab, { a = 0, x = 0, y = 0, c = 0 } = {}, mem] of calls || []) { vput(mem); const t = lab === 'NWSHP' && SUB[a] ? SUB[a] : a;
      const r = m.call(lab, { a: t, b: x, c: y, cf: c }); if (lab === 'NWSHP') { if (!r.cf) fail(`NWSHP типа ${t}: места нет`); seen.push(t); shot = t; } }
    down.forEach((c) => setKey(c, true)); up.forEach((c) => setKey(c, false));
    for (let i = 0; i < n; i++, idx++) {
      if (!mortal) { m.wr(WS + B.ENERGY, [255]); m.wr(WS + B.FSH, [255]); m.wr(WS + B.ASH, [255]); }   // с другими кораблями бой идёт иначе: до последней фазы щиты полные
      m.runTo(VL[label] || label, 6e7);
      for (let f = 0; f < k; f++) { m.wr('DL', [30]); const la = m.rd('LASCT'); if (la) m.wr('LASCT', [la - 1]); }
      maxTally = Math.max(maxTally, m.rd(WS + B.TALLY));
      if (shot && NAME[shot]) { pend = [shot, idx + 6]; shot = null; }
      if (pend && idx === pend[1]) { const shot = pend[0]; pend = null;               // корабль только что появился: снимок (копия машины не нужна — кадр без хода игры)
        const snap = m.mem().slice(0xC000, 0x10000), o = path.join(ROOT, 'work/v06c', `zx-${NAME[shot]}.png`);
        const m2 = createVector('elite'); m2.frame(40); m2.wr(0xC000, snap); m2.cpu.iff = false; m2.frame(1); savePng(m2.bmp(), o);
      }
    }
  }
} catch (e) { fail(`проход ${idx}: ${e.message}`); }
const frin = Array.from(m.mem().subarray(WS + B.FRIN, WS + B.FRIN + 13));
console.log(`${bad ? 'FAIL' : 'OK  '} сценарий fight с кораблями ZX: ${idx} проходов, появлялись типы ${seen.join(', ')}; побед за бой ${maxTally}`);
if (maxTally < 2) fail(`побед ${maxTally}, ждали не меньше 2`);
if (m.rd(WS + B.QQ12) !== 0xFF) fail('в конце не заставка');
// статистика замены (обычный образ: в образе стенда zx_pick нет)
{ const r = createVector('elite'); r.frame(40); const cnt = {};
  for (const t of [1, 3, 4, 5, 2]) { cnt[t] = {}; for (let i = 0; i < 2000; i++) { const q = r.call('zx_pick', { a: t, cf: i & 1 }); if (q.cf !== (i & 1)) { fail('zx_pick не сохранил перенос'); break; } cnt[t][q.a] = (cnt[t][q.a] || 0) + 1; } }
  console.log('замена типа при появлении (из 2000): ' + Object.entries(cnt).map(([t, c]) => `${t} → ` + Object.entries(c).map(([a, n]) => `${a}: ${n}`).join(', ')).join(' | '));
  for (const [t, to] of [[1, 14], [3, 14], [4, 15], [5, 16]]) { const n = cnt[t][to] || 0; if (n < 350 || n > 650) fail(`тип ${t}: замен ${n}, ждали около 500`); if (Object.keys(cnt[t]).some((a) => +a !== +t && +a !== to)) fail(`тип ${t}: лишняя замена`); }
  if (Object.keys(cnt[2]).length !== 1) fail('полицейский Viper заменяться не должен'); }
console.log(bad ? `ПРОВАЛ: ${bad}` : 'ZXSHIPS: всё как задумано');
process.exit(bad ? 1 : 0);
