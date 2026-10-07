// Двухбуквенные слоги текста: 64 байта таблицы QQ16 из образа кассетной версии → v06c/data/qq16.asm.
// node tools/convert/qq16.js
'use strict';
const fs = require('fs');
const path = require('path');
const { BBC } = require('../oracle/bbc.js');
const b = new BBC({ sched: true }), d = [...b.mem.subarray(b.lab.QQ16, b.lab.QQ16 + 64)];
let s = '; Двухбуквенные слоги текста (QQ16 кассетной версии BBC). Сделано tools/convert/qq16.js, руками не править.\nQQ16:\n';
for (let i = 0; i < 64; i += 16) s += '\tdb ' + d.slice(i, i + 16).map((x) => '0x' + x.toString(16).toUpperCase().padStart(2, '0')).join(', ') + '\n';
fs.writeFileSync(path.resolve(__dirname, '../../v06c/data/qq16.asm'), s);
console.log('v06c/data/qq16.asm: 64 байта');
