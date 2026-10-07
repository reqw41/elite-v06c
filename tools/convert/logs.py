#!/usr/bin/env python3
"""Таблицы логарифмов для быстрой сборки → v06c/data/logs.bin (1024 байта): log, logL, antilog, antilogODD.

Таблицы считаются по формулам (это значения двоичного логарифма и степени двойки):
  log[n], logL[n]  — старший и младший байты числа int(0x2000 * log2(n)), n = 1..255 (для 8 и 64 — на единицу
                     меньше: так в таблице BBC, а сверяемся мы с ней до бита; нулевой элемент не используется);
  antilog[n]       — int(2 ** (n / 32 + 8)) // 256;
  antilogODD[n]    — int(2 ** ((n + 0.5) / 32 + 8)) // 256.
С аргументом --cmp сверяются с таблицами версии BBC Elite для второго процессора
(orig/bbc/6502-second-processor/3-assembled-output/P.CODE.unprot.bin, &5B00–&5EFF при загрузке с &1000).
Запуск из корня проекта: python3 -I tools/convert/logs.py [--cmp]
"""
import math
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
ORIG = os.environ.get('ELITE_ORIG', '/Users/boris/projects/elite-v06c/orig')


def tables():
    log, logl, alog, aodd = bytearray(256), bytearray(256), bytearray(256), bytearray(256)
    for n in range(1, 256):
        v = int(0x2000 * math.log2(n))
        if n in (8, 64):          # как в таблице BBC: её считал BBC BASIC, и здесь он ошибся на единицу вниз
            v -= 1
        log[n], logl[n] = v >> 8, v & 0xFF
    for n in range(256):
        alog[n] = int(2 ** (n / 32 + 8)) // 256
        aodd[n] = int(2 ** ((n + 0.5) / 32 + 8)) // 256
    return log, logl, alog, aodd


def main():
    t = tables()
    open(os.path.join(ROOT, 'v06c/data/logs.bin'), 'wb').write(b''.join(bytes(x) for x in t))
    print('v06c/data/logs.bin: 1024 байта')
    if '--cmp' in sys.argv:
        code = open(os.path.join(ORIG, 'bbc/6502-second-processor/3-assembled-output/P.CODE.unprot.bin'), 'rb').read()
        for name, tab, at in zip(('log', 'logL', 'antilog', 'antilogODD'), t, (0x5B00, 0x5C00, 0x5D00, 0x5E00)):
            ref = code[at - 0x1000:at - 0x1000 + 256]
            diff = [i for i in range(256) if ref[i] != tab[i]]
            print(f'{name}: отличий от версии для второго процессора {len(diff)}' + (f': индексы {diff[:12]}, там {[ref[i] for i in diff[:12]]}, здесь {[tab[i] for i in diff[:12]]}' if diff else ''))


if __name__ == '__main__':
    main()
