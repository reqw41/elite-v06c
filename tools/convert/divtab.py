#!/usr/bin/env python3
"""Таблица наклонов коротких отрезков → v06c/data/divtab.bin (1024 байта).

divtab[d · 32 + n] = 256 · n / d нацело для n < d < 32; при n = d — 255 (как выходит у деления в LOIN на BBC);
при d = 0 и n > d — 0 (не используется). Результат тот же, что у точного деления: тесты отрезка не меняются.
Запуск из корня проекта: python3 -I tools/convert/divtab.py
"""
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
t = bytearray(1024)
for d in range(1, 32):
    for n in range(0, d + 1):
        t[d * 32 + n] = 255 if n == d else (256 * n) // d
open(os.path.join(ROOT, 'v06c/data/divtab.bin'), 'wb').write(bytes(t))
print('v06c/data/divtab.bin: 1024 байта')
