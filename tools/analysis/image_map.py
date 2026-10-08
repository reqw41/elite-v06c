#!/usr/bin/env python3
"""Куда ушла память образа: размер каждого включаемого файла по листингу сборки (v06c/build/elite.lst).
Печатает таблицу по группам и файлам. Запуск после сборки: python3 -I tools/analysis/image_map.py [имя образа = elite]"""
import os, re, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
name = sys.argv[1] if len(sys.argv) > 1 else 'elite'
# Каждая строка листинга принадлежит файлу по глубине вложенности («+» после номера строки); байты строки —
# разность адресов со следующей строкой. Так вложенные файлы и выравнивание считаются один раз.
sym = {}
for l in open(os.path.join(ROOT, 'v06c/build', name + '.sym')):
    m = re.match(r'(\S+):\s+EQU\s+0x([0-9A-Fa-f]+)', l)
    if m:
        sym[m.group(1)] = int(m.group(2), 16)
end = sym['rom_end']
rows = []                                    # (адрес, уровень, файл-включение или None, incbin)
for l in open(os.path.join(ROOT, 'v06c/build', name + '.lst'), encoding='latin1'):
    m = re.match(r'\s*\d+(\+*)\s+([0-9A-F]{4})\s', l)
    if not m:
        continue
    i = re.search(r'\b(include|incbin)\s+"([^"]+)"', l)
    rows.append((int(m.group(2), 16), len(m.group(1)), i.group(2) if i and i.group(1) == 'include' else None, i.group(2) if i and i.group(1) == 'incbin' else None))
sizes, stack, pending = {}, ['elite.asm'], None
for k, (a, lev, inc, binf) in enumerate(rows):
    if pending is not None and lev == len(stack):        # вошли во включённый файл
        stack.append(pending)
    pending = None
    while lev < len(stack) - 1:
        stack.pop()
    nxt = rows[k + 1][0] if k + 1 < len(rows) else a
    n = nxt - a if 0x100 <= a < end and a <= nxt <= end else 0
    if n > 0:
        f = binf if binf else stack[-1]
        sizes[f] = sizes.get(f, 0) + n
    if inc:
        pending = inc
GROUPS = [('движок кассетной BBC: код', ['sys.asm', 'text.asm', 'tokens.asm', 'numbers.asm', 'screen.asm', 'dials.asm', 'reset.asm', 'universe.asm', 'stars.asm', 'circle.asm',
                                         'planet.asm', 'flight.asm', 'mainflight.asm', 'dash.asm', 'line.asm', 'arith.asm', 'arith2.asm', 'arith3.asm', 'geom.asm', 'move.asm',
                                         'scan.asm', 'clip.asm', 'ship.asm', 'stubs.asm', 'title.asm', 'start.asm', 'mainloop.asm', 'status.asm', 'charts.asm', 'market.asm',
                                         'equip.asm', 'tactics.asm', 'combat.asm', 'explode.asm', 'death.asm', 'hyper.asm', 'save.asm']),
          ('данные кассетной BBC: модели, словарь, таблицы', ['ships.asm', 'python.asm', 'words.asm', 'qq16.asm', 'na.asm', 'qq23.asm']),
          ('слой Вектора: звук, лента, таблицы клавиш, наклоны, шрифт, панель', ['snd.asm', 'tape.asm', 'keys.asm', 'kbgap.asm', 'divtab.bin', 'font.bin', 'dials.rle', 'front.asm']),
          ('добавки ZX 48K: миссии, поиск, модели', ['missions.asm', 'find.asm']),
          ('добавки дисковой BBC: код', ['pdesc.asm', 'dockit.asm', 'hangar.asm', 'discmis.asm']),
          ('добавки дисковой BBC и ZX: модели кораблей', ['ships_zx.asm']),
          ('добавки дисковой BBC: словарь описаний и миссий', ['tkn1.asm'])]
tot = sum(sizes.values())
print('образ %s: %d Б (0100h…%04Xh), по файлам учтено %d Б, свободно до B000h %d Б' % (name, end - 0x100, end - 1, tot, 0xB000 - end))
seen = set()
for g, files in GROUPS:
    n = sum(sizes.get(f, 0) for f in files)
    seen.update(files)
    print('\n%-62s %6d Б  %4.1f %%' % (g, n, 100.0 * n / (end - 0x100)))
    for f in sorted(files, key=lambda f: -sizes.get(f, 0)):
        if sizes.get(f, 0) >= 300:
            print('    %-18s %6d' % (f, sizes[f]))
    small = [f for f in files if 0 < sizes.get(f, 0) < 300]
    if small:
        print('    прочие (%d файлов) %6d' % (len(small), sum(sizes[f] for f in small)))
rest = {f: n for f, n in sizes.items() if f not in seen}
print('\nпрочее:', rest, '; не учтено %d Б' % (end - 0x100 - tot))
