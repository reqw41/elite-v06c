#!/usr/bin/env python3
"""Надписи заставки загрузчика кассетной BBC (P.A-SOFT, P.ELITE, P.(C)ASFT — по 256 байт, строка экрана режима 4:
32 знакоместа по 8 байт сверху вниз) → v06c/data/sat_*.bin без изменений: раскладку по столбцам экрана Вектора
делает sat_row (v06c/src/saturn.asm). Верхняя надпись — не ACORNSOFT (он есть в строке прав внизу), а «ВЕКТОР 06Ц»
(решение владельца 17.10.2026): буквы нарисованы здесь в манере ACORNSOFT — прямые глифы со штрихами по 5 точек,
строка за строкой сдвинутые влево на 3 точки (курсив), по середине строки.
Запуск из корня проекта: python3 -I tools/convert/saturn.py [--show]"""
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
ORIG = os.environ.get('ELITE_ORIG', '/Users/boris/projects/elite-v06c/orig')
SRC = os.path.join(ORIG, 'bbc/cassette/1-source-files/images')

# прямые глифы, 7 строк (строки 1–7 знакоместа; строка 0 пустая, как у ACORNSOFT)
G = {
    'В': ['###########...', '#####....#####', '#####....#####', '############..', '#####....#####', '#####....#####', '############..'],
    'Е': ['#############', '#####........', '#####........', '##########...', '#####........', '#####........', '#############'],
    'К': ['#####...#####', '#####..#####.', '#####.#####..', '#########....', '#####.#####..', '#####..#####.', '#####...#####'],
    'Т': ['##############', '....#####.....', '....#####.....', '....#####.....', '....#####.....', '....#####.....', '....#####.....'],
    'О': ['...########...', '#####....#####', '#####....#####', '#####....#####', '#####....#####', '#####....#####', '...########...'],
    'Р': ['###########...', '#####....#####', '#####....#####', '###########...', '#####.........', '#####.........', '#####.........'],
    '0': ['..#######..', '####...####', '####...####', '####...####', '####...####', '####...####', '..#######..'],
    '6': ['...#########', '#####.......', '#####.......', '###########.', '#####....####', '#####....####', '...########.'],
    'Ц': ['#####....#####..', '#####....#####..', '#####....#####..', '#####....#####..', '#####....#####..', '#####....#####..', '################'],
    ' ': ['.......'] * 7,
}
GAP, SLANT = 3, 3


def banner(text):
    rows = [''] * 7
    for i, ch in enumerate(text):
        w = max(len(r) for r in G[ch])
        for k in range(7):
            rows[k] += G[ch][k].ljust(w, '.') + ('.' * GAP if i < len(text) - 1 else '')
    w = len(rows[0]) + SLANT * 6
    x0 = (256 - w) // 2
    img = [[0] * 256 for _ in range(8)]
    for k in range(7):
        x = x0 + SLANT * (6 - k)              # верх правее, низ левее
        for j, c in enumerate(rows[k]):
            if c == '#':
                img[k + 1][x + j] = 1
    out = bytearray(256)
    for c in range(32):
        for k in range(8):
            out[c * 8 + k] = sum(img[k][c * 8 + b] << (7 - b) for b in range(8))
    return bytes(out)


def show(d):
    for k in range(8):
        print(''.join(''.join('#' if d[c * 8 + k] & (0x80 >> b) else '.' for b in range(8)) for c in range(32)))


vec = banner('ВЕКТОР 06Ц')
if '--show' in sys.argv:
    show(vec)
    show(open(os.path.join(SRC, 'P.A-SOFT.bin'), 'rb').read())
    sys.exit()
open(os.path.join(ROOT, 'v06c/data/sat_asoft.bin'), 'wb').write(vec)
print('ВЕКТОР 06Ц → v06c/data/sat_asoft.bin')
for src, dst in [('P.ELITE.bin', 'sat_elite.bin'), ('P.(C)ASFT.bin', 'sat_casft.bin')]:
    d = open(os.path.join(SRC, src), 'rb').read()
    assert len(d) == 256, src
    open(os.path.join(ROOT, 'v06c/data', dst), 'wb').write(d)
    print('%s → v06c/data/%s' % (src, dst))
