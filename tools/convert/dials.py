#!/usr/bin/env python3
"""Конвертер картинки панели BBC P.DIALS.bin → две плоскости Вектора.

Читает:
  orig/bbc/cassette/1-source-files/images/P.DIALS.bin  (1792 байта,
  128 точек x 56 строк, 4 цвета)

Пишет:
  v06c/data/dials.bin  3584 байта: плоскость 0 (1792) + плоскость 1 (1792),
  ширина 256 (каждая точка BBC занимает две точки рядом), по столбцам:
  смещение байта col*56 + y, старший бит байта - левая точка.
  v06c/data/dials.png  512x112 (каждая точка Вектора - квадрат 2x2), PNG через
  zlib и struct, без сторонних библиотек.

Раскладка BBC: байт для ряда r (0-6), знакоместа cx (0-31), строки l (0-7)
лежит по смещению r*256 + cx*8 + l; в байте 4 точки, слева направо k = 0..3;
цвет точки: c = ((байт >> (7-k)) & 1) * 2 + ((байт >> (3-k)) & 1);
координаты точки: X = cx*4 + k (0-127), y = r*8 + l (0-55).

Запуск из корня проекта: python3 -I tools/convert/dials.py
"""
import os
import struct
import zlib

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
ORIG = os.environ.get('ELITE_ORIG', '/Users/boris/projects/elite-v06c/orig')
DIALS_BIN = os.path.join(ORIG, 'bbc', 'cassette', '1-source-files',
                         'images', 'P.DIALS.bin')

OUT_BIN = os.path.join(ROOT, 'v06c', 'data', 'dials.bin')
OUT_PNG = os.path.join(ROOT, 'v06c', 'data', 'dials.png')

W_BBC = 128          # точек в ширину на BBC
H_BBC = 56           # строк
PLANE_LEN = (2 * W_BBC) // 8 * H_BBC  # 256/8 * 56 = 32*56 = 1792 байт на плоскость
COLORS = [(0, 0, 0), (255, 0, 0), (255, 255, 0), (0, 255, 0)]  # 0..3


def read_source():
    with open(DIALS_BIN, 'rb') as f:
        data = f.read()
    if len(data) != 1792:
        raise SystemExit(f'{DIALS_BIN}: длина {len(data)}, ожидалось 1792')
    return data


def convert(data):
    """Возвращает (planes, colors): planes - 3584 байта, colors - цвета точек Вектора 256x56."""
    planes = bytearray(2 * PLANE_LEN)
    colors = [[0] * W_BBC for _ in range(H_BBC)]  # colors[y][X] = 0..3
    for r in range(7):
        for cx in range(32):
            for l in range(8):
                byte = data[r * 256 + cx * 8 + l]
                y = r * 8 + l
                for k in range(4):
                    c = ((byte >> (7 - k)) & 1) * 2 + ((byte >> (3 - k)) & 1)
                    X = cx * 4 + k
                    colors[y][X] = c
                    for x in (2 * X, 2 * X + 1):
                        col, bit = x >> 3, 7 - (x & 7)
                        off = col * 56 + y
                        if c & 1:
                            planes[off] |= 1 << bit
                        if c >> 1:
                            planes[PLANE_LEN + off] |= 1 << bit
    return bytes(planes), colors


def png_chunk(tag, data):
    return (struct.pack('>I', len(data)) + tag + data +
            struct.pack('>I', zlib.crc32(tag + data) & 0xFFFFFFFF))


def write_png(colors):
    """PNG 512x112: каждая точка Вектора (x 0..255, y 0..55) - квадрат 2x2."""
    w, h = 512, 112
    raw = bytearray()
    for py in range(h):
        y = py // 2
        raw.append(0)  # фильтр "нет"
        row = bytearray()
        for px in range(w):
            # px -> точка Вектора x = px//2 -> точка BBC X = x//2 = px//4
            r, g, b = COLORS[colors[py // 2][px // 4]]
            row += bytes((r, g, b))
        raw += row
    ihdr = struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)
    png = (b'\x89PNG\r\n\x1a\n'
           + png_chunk(b'IHDR', ihdr)
           + png_chunk(b'IDAT', zlib.compress(bytes(raw), 9))
           + png_chunk(b'IEND', b''))
    with open(OUT_PNG, 'wb') as f:
        f.write(png)


def main():
    data = read_source()
    planes, colors = convert(data)
    os.makedirs(os.path.dirname(OUT_BIN), exist_ok=True)
    with open(OUT_BIN, 'wb') as f:
        f.write(planes)
    write_png(colors)
    print(f'dials.bin: {len(planes)} байт (плоскость 0 + плоскость 1 по {PLANE_LEN})')
    print(f'dials.png: 512x112, {os.path.getsize(OUT_PNG)} байт')


if __name__ == '__main__':
    main()
