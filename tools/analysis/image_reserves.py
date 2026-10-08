#!/usr/bin/env python3
"""Резервы памяти образа: что в нём лежит, но не используется или дублируется.
1. Метки, на которые нет ни одной ссылки в исходниках (кроме определения), с размером до следующей метки —
   кандидаты в мёртвый код (нужна проверка глазами: вход может быть «проваливанием» сверху).
2. Пустоты выравнивания (align) по листингу. 3. Известные дубли и разовые данные.
Запуск после сборки: python3 -I tools/analysis/image_reserves.py"""
import glob, os, re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
src = {}
for f in glob.glob(os.path.join(ROOT, 'v06c/src/*.asm')) + glob.glob(os.path.join(ROOT, 'v06c/data/*.asm')):
    src[os.path.basename(f)] = open(f, encoding='utf-8').read()
alltext = '\n'.join(re.sub(r';.*', '', t) for t in src.values())
words = {}
for w in re.findall(r'[A-Za-z_][A-Za-z_0-9]*', alltext):
    words[w] = words.get(w, 0) + 1
sym = {}
for l in open(os.path.join(ROOT, 'v06c/build/elite.sym')):
    m = re.match(r'(\S+):\s+EQU\s+0x([0-9A-Fa-f]+)', l)
    if m:
        sym[m.group(1)] = int(m.group(2), 16)
end = sym['rom_end']
code = sorted((a, n) for n, a in sym.items() if 0x100 <= a < end and not n.startswith('_'))
addrs = sorted(set(a for a, n in code))
nxt = {a: (addrs[i + 1] if i + 1 < len(addrs) else end) for i, a in enumerate(addrs)}
# в какой файл попадает адрес — по первой метке файла
defs = {}
for f, t in src.items():
    for m in re.finditer(r'^([A-Za-z_][A-Za-z_0-9]*):', t, re.M):
        defs.setdefault(m.group(1), f)
print('1. Метки без ссылок (имя, файл, байт до следующей метки):')
tot = 0
dead = []
for a, n in code:
    if words.get(n, 0) <= 1 and n in defs:
        dead.append((nxt[a] - a, n, defs[n], a))
for sz, n, f, a in sorted(dead, reverse=True):
    if sz >= 8:
        print('   %-12s %-16s %4d' % (n, f, sz))
        tot += sz
print('   всего в метках без ссылок (от 8 Б): %d Б — верхняя оценка, часть — входы «проваливанием»' % tot)
print('2. Пустоты выравнивания:')
prev, gaps = None, 0
for l in open(os.path.join(ROOT, 'v06c/build/elite.lst'), encoding='latin1'):
    m = re.match(r'\s*\d+\+*\s+([0-9A-F]{4})', l)
    if not m:
        continue
    a = int(m.group(1), 16)
    if re.search(r'\balign\b', l, re.I):
        prev = (a, l.strip()[:60])
    elif prev and a != prev[0]:
        if 0 < a - prev[0] < 256 and a < end:
            print('   %3d Б  %s' % (a - prev[0], re.sub(r'\s+', ' ', prev[1])))
            gaps += a - prev[0]
        prev = None
print('   всего %d Б' % gaps)
print('3. Дубли и разовые данные:')
print('   таблица XX21 (ships.asm) повторена в начале XX21X: 26 Б')
t = src['missions.asm']
strs = sum(len(re.findall(r'0x[0-9A-Fa-f]{2}|\d+', l)) for l in re.findall(r'^\s*db\s+(.*)$', re.sub(r'"[^"]*"', lambda m: ','.join(['0'] * len(m.group(0)[1:-1])), t), re.M))
print('   тексты миссий ZX простыми строками (missions.asm, строки db): около %d Б' % strs)
print('   картинка панели dials.rle: %d Б, нужна один раз при запуске (место годится под буферы, не под код)' % os.path.getsize(os.path.join(ROOT, 'v06c/data/dials.rle')))
