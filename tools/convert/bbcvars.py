#!/usr/bin/env python3
"""Переменные рабочих областей BBC → v06c/src/bbc_vars.inc.

Читает листинг orig/bbc/cassette/3-assembled-output/compile.txt, берёт метки игры с адресами ниже кода
(&0000–&0F3F: нулевая страница, XX3, T%, K%, WP) и пишет их как `ИМЯ equ WS + адрес BBC`.
Смещение внутри области то же, что на BBC, поэтому состояние сравнивается побайтно сдвигом на WS.

Имена: `%` заменяется на `_` (K% → K_). Имя, совпадающее с регистром или командой, получает `_` в конце.
Запуск из корня проекта: python3 -I tools/convert/bbcvars.py
"""
import os
import re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
ORIG = os.environ.get('ELITE_ORIG', '/Users/boris/projects/elite-v06c/orig')
LST = os.path.join(ORIG, 'bbc', 'cassette', '3-assembled-output', 'compile.txt')
OUT = os.path.join(ROOT, 'v06c', 'src', 'bbc_vars.inc')

AREAS = [  # имя, начало, конец (не включая), что
    ('ZP', 0x0000, 0x0100, 'нулевая страница'),
    ('XX3', 0x0100, 0x0200, 'куча XX3 (на BBC — низ страницы стека)'),
    ('T_', 0x0300, 0x0400, 'пилот, звёздная пыль'),
    ('K_', 0x0900, 0x0D40, 'блоки кораблей и куча отрезков'),
    ('WP', 0x0D40, 0x0F40, 'слоты и переменные'),
    ('COMC', 0x0F48, 0x0F51, 'настройки (на BBC — в начале кода)'),
]
RESERVED = set('A B C D E H L I R M F AF BC DE HL SP IX IY NZ Z NC PO PE P'.split())
RESERVED |= set('''ADC ADD AND BIT CALL CCF CP CPL DAA DEC DI EI EX HALT IN INC JP JR LD NOP OR OUT POP PUSH RES RET RLA
RLCA RRA RRCA RST SBC SCF SET SUB XOR DB DW DS ORG EQU END'''.split())


def labels():
    text = open(LST, encoding='latin-1').read()
    seen, out = set(), []
    for m in re.finditer(r'^\.(\S+)\r?\n\s+([0-9A-F]{4})\b', text, re.M):
        name, addr = m.group(1), int(m.group(2), 16)
        if name in seen:            # метки загрузчика идут после меток игры — берём первую
            continue
        seen.add(name)
        out.append((name, addr))
    return out


def vname(name):
    n = name.replace('%', '_')
    return n + '_' if n.upper() in RESERVED else n


def main():
    labs = labels()
    lines = ['; Сделано tools/convert/bbcvars.py из листинга кассетной версии BBC. Руками не править.',
             '; ИМЯ equ WS + адрес на BBC: раскладка внутри рабочих областей та же, что на BBC.', '']
    total = 0
    for area, lo, hi, what in AREAS:
        part = [(n, a) for n, a in labs if lo <= a < hi]
        lines.append(f'; --- {what}: BBC &{lo:04X} ---')
        for n, a in part:
            lines.append(f'{vname(n)}\tequ\tWS + 0x{a:04X}')
        lines.append('')
        total += len(part)
        print(f'{area:4s} &{lo:04X}: меток {len(part)}, последняя &{max(a for _, a in part):04X}')
    renamed = sorted({n for n, a in labs if a < 0x0F51 and vname(n) != n and '%' not in n})
    open(OUT, 'w').write('\n'.join(lines))
    print(f'{os.path.relpath(OUT, ROOT)}: меток {total}; переименованы из-за совпадения с регистром: {" ".join(renamed)}')


if __name__ == '__main__':
    main()
