// Таблица товаров рынка QQ23 (17 товаров по 4 байта: цена, наклон и единица, запас, маска) из образа кассетной
// версии → v06c/data/qq23.asm. node tools/convert/qq23.js
'use strict';
const fs = require('fs');
const path = require('path');
const { BBC } = require('../oracle/bbc.js');
// метка QQ23 в листинге стоит перед макросом, и общий разбор меток её адрес не берёт: таблица лежит сразу за QQ16 (64 байта)
const b = new BBC({ sched: true }), at = b.lab.QQ23 ?? b.lab.QQ16 + 64, d = [...b.mem.subarray(at, at + 68)];
if (at !== 0x4BBC || d[0] !== 0x13 || d[1] !== 0x82) throw new Error('QQ23 не на месте');
let s = '; Товары рынка (QQ23 кассетной версии BBC). Сделано tools/convert/qq23.js, руками не править.\n; На товар: базовая цена, наклон по экономике (биты 0–4, знак — бит 7) и единица (биты 5–6), базовый запас, маска.\nQQ23:\n';
for (let i = 0; i < 68; i += 4) s += '\tdb ' + d.slice(i, i + 4).map((x) => '0x' + x.toString(16).toUpperCase().padStart(2, '0')).join(', ') + '\n';
fs.writeFileSync(path.resolve(__dirname, '../../v06c/data/qq23.asm'), s);
console.log('v06c/data/qq23.asm: 68 байт');
