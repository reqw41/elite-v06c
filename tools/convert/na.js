// Командир по умолчанию: 84 байта блока NA% из образа кассетной версии (имя, данные, контрольные суммы)
// → v06c/data/na.asm. node tools/convert/na.js
'use strict';
const fs = require('fs');
const path = require('path');
const { BBC } = require('../oracle/bbc.js');
const b = new BBC({ sched: true }), L = b.lab, d = [...b.mem.subarray(L['NA%'], L.CHK + 1)];
if (d.length !== 84 || L.CHK2 !== L['NA%'] + 82) throw new Error('раскладка NA% не та');
const row = (a) => '\tdb ' + a.map((x) => '0x' + x.toString(16).toUpperCase().padStart(2, '0')).join(', ') + '\n';
let s = '; Командир по умолчанию (NA% кассетной версии BBC). Сделано tools/convert/na.js, руками не править.\n; 8 байт имени, 74 байта данных, CHK2, CHK.\nNA_:\n';
for (let i = 0; i < 82; i += 16) s += row(d.slice(i, Math.min(82, i + 16)));
s += 'CHK2:\n' + row([d[82]]) + 'CHK:\n' + row([d[83]]);
fs.writeFileSync(path.resolve(__dirname, '../../v06c/data/na.asm'), s);
console.log('v06c/data/na.asm: 84 байта');
