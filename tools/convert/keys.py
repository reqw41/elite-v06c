#!/usr/bin/env python3
"""Таблицы клавиатуры → v06c/data/keys.asm.

kb_bbc: клавиша Вектора (строка матрицы · 8 + бит) → внутренний номер клавиши BBC, 0 — нет.
kb_rev: номер клавиши BBC (0–127) → клавиша Вектора, FFh — нет; 80h + бит — модификатор (бит kb_mod).
kb_ss:  F1–F5 при нажатой СС → номера клавиш BBC f5–f9 (решение владельца 07.10.2026).
Раскладка — здесь, в одном месте. F1–F5 Вектора — f0–f4 BBC, СС + F1–F5 — f5–f9.
В kb_rev у f5–f9 стоит 40h + клавиша Вектора: нажата, только если нажата и СС.
Запуск из корня проекта: python3 -I tools/convert/keys.py
"""
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
# строки матрицы Вектора, биты 0..7
ROWS = [
    ['TAB', None, 'RETURN', 'DELETE', 'LEFT', 'UP', 'RIGHT', 'DOWN'],       # ТАБ, ПС, ВК, ЗБ, стрелки
    [None, 'COPY', 'ESCAPE', 'f0', 'f1', 'f2', 'f3', 'f4'],                 # ↖, СТР, АР2, F1–F5
    list('01234567'),
    ['8', '9', ':', ';', ',', '-', '.', '/'],
    list('@ABCDEFG'),
    list('HIJKLMNO'),
    list('PQRSTUVW'),
    ['X', 'Y', 'Z', '[', '\\', ']', '^', 'SPACE'],
]
BBC = {  # внутренние номера клавиш BBC Micro
    'Q': 0x10, '3': 0x11, '4': 0x12, '5': 0x13, 'f4': 0x14, '8': 0x15, 'f7': 0x16, '-': 0x17, '^': 0x18, 'LEFT': 0x19,
    'f0': 0x20, 'W': 0x21, 'E': 0x22, 'T': 0x23, '7': 0x24, 'I': 0x25, '9': 0x26, '0': 0x27, '_': 0x28, 'DOWN': 0x29,
    '1': 0x30, '2': 0x31, 'D': 0x32, 'R': 0x33, '6': 0x34, 'U': 0x35, 'O': 0x36, 'P': 0x37, '[': 0x38, 'UP': 0x39,
    'A': 0x41, 'X': 0x42, 'F': 0x43, 'Y': 0x44, 'J': 0x45, 'K': 0x46, '@': 0x47, ':': 0x48, 'RETURN': 0x49,
    'S': 0x51, 'C': 0x52, 'G': 0x53, 'H': 0x54, 'N': 0x55, 'L': 0x56, ';': 0x57, ']': 0x58, 'DELETE': 0x59,
    'TAB': 0x60, 'Z': 0x61, 'SPACE': 0x62, 'V': 0x63, 'B': 0x64, 'M': 0x65, ',': 0x66, '.': 0x67, '/': 0x68, 'COPY': 0x69,
    'ESCAPE': 0x70, 'f1': 0x71, 'f2': 0x72, 'f3': 0x73, 'f5': 0x74, 'f6': 0x75, 'f8': 0x76, 'f9': 0x77, '\\': 0x78, 'RIGHT': 0x79,
}
MODS = {0x00: 5, 0x01: 6}        # SHIFT BBC — СС (бит 5 kb_mod), CTRL BBC — УС (бит 6)
SHIFTED = ['f5', 'f6', 'f7', 'f8', 'f9']   # СС + F1..F5
# знак, который BBC выдаёт по клавише (таблица ПЗУ системы, TRTB%): буквы — строчные
ASCII = {'RETURN': 13, 'DELETE': 127, 'SPACE': 32, 'ESCAPE': 27, 'TAB': 0, 'COPY': 0x8B, 'LEFT': 0x8C, 'RIGHT': 0x8D, 'DOWN': 0x8E, 'UP': 0x8F}


def db(vals):
    return '\n'.join('\tdb ' + ', '.join(f'0x{v:02X}' for v in vals[i:i + 8]) for i in range(0, len(vals), 8)) + '\n'


def main():
    fwd = [BBC[k] if k else 0 for row in ROWS for k in row]
    rev = [0xFF] * 128
    for i, c in enumerate(fwd):
        if c:
            assert rev[c] == 0xFF, hex(c)
            rev[c] = i
    for c, bit in MODS.items():
        rev[c] = 0x80 + bit
    ss = [BBC[k] for k in SHIFTED]
    for n, c in enumerate(ss):
        assert rev[c] == 0xFF, hex(c)
        rev[c] = 0x40 + 11 + n          # F1..F5 — клавиши 11..15 (строка 1, биты 3..7)
    s = ('; Таблицы клавиатуры. Сделано tools/convert/keys.py, руками не править.\n'
         '; kb_bbc: клавиша Вектора (строка · 8 + бит) -> номер клавиши BBC, 0 — нет.\n\talign\t128\nkb_bbc:\n' + db(fwd) +
         '; kb_ss: F1..F5 при нажатой СС -> f5..f9 BBC.\nkb_ss:\n' + db(ss) +
         '; kb_rev: номер клавиши BBC -> клавиша Вектора; FFh — нет; 80h + бит — модификатор в kb_mod;\n'
         '; 40h + клавиша — только вместе с СС.\n\talign\t128\nkb_rev:\n' + db(rev))
    asc = [0] * 128
    for k, c in BBC.items():
        if k in ASCII:
            asc[c] = ASCII[k]
        elif len(k) == 1:
            asc[c] = ord(k.lower())
    s += ('; kb_ascii: номер клавиши BBC -> знак (как таблица ПЗУ BBC по адресу TRTB%); 0 — нет.\n\talign\t128\nkb_ascii:\n' + db(asc))
    # джойстик: бит порта -> клавиша Вектора (смещение строки в kb_rows, маска). В полёте — клавиши управления,
    # на остальных экранах — стрелки и пробел.
    def joy(pairs):
        out = []
        for bit, key in pairs:
            i = rev[BBC[key]]
            assert i < 64, key
            out += [1 << bit, i >> 3, 1 << (i & 7)]
        return out
    s += ('; joy_fly, joy_scr: джойстик -> клавиши: бит порта, строка в kb_rows, маска клавиши; по шесть записей.\n'
          '; Биты: 0 вправо, 1 влево, 2 вверх, 3 вниз, 6 огонь, 7 вторая кнопка.\njoy_fly:\n'
          + db(joy([(0, '.'), (1, ','), (2, 'S'), (3, 'X'), (6, 'A'), (7, 'SPACE')]))
          + 'joy_scr:\n' + db(joy([(0, 'RIGHT'), (1, 'LEFT'), (2, 'UP'), (3, 'DOWN'), (6, 'SPACE'), (7, 'RETURN')])))
    open(os.path.join(ROOT, 'v06c/data/keys.asm'), 'w').write(s)
    print(f'v06c/data/keys.asm: назначено клавиш {sum(1 for c in fwd if c)} и {len(ss)} с СС, без клавиши на Векторе: '
          + ' '.join(k for k, c in BBC.items() if rev[c] == 0xFF))


if __name__ == '__main__':
    main()
