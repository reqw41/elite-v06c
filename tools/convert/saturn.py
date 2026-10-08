#!/usr/bin/env python3
"""Надписи заставки загрузчика кассетной BBC (P.A-SOFT, P.ELITE, P.(C)ASFT — по 256 байт, строка экрана режима 4:
32 знакоместа по 8 байт сверху вниз) → v06c/data/sat_*.bin без изменений: раскладку по столбцам экрана Вектора
делает sat_row (v06c/src/saturn.asm). Запуск из корня проекта: python3 -I tools/convert/saturn.py"""
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
ORIG = os.environ.get('ELITE_ORIG', '/Users/boris/projects/elite-v06c/orig')
SRC = os.path.join(ORIG, 'bbc/cassette/1-source-files/images')
for src, dst in [('P.A-SOFT.bin', 'sat_asoft.bin'), ('P.ELITE.bin', 'sat_elite.bin'), ('P.(C)ASFT.bin', 'sat_casft.bin')]:
    d = open(os.path.join(SRC, src), 'rb').read()
    assert len(d) == 256, src
    open(os.path.join(ROOT, 'v06c/data', dst), 'wb').write(d)
    print('%s → v06c/data/%s' % (src, dst))
