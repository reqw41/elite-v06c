#!/usr/bin/env python3
"""Q1: SHIPS.bin + PYTHON.bin (BBC) -> v06c/data/ships.asm, v06c/data/python.asm.
Только стандартная библиотека. Запуск: python3 -I tools/convert/ships.py"""
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
ORIG = os.environ.get('ELITE_ORIG', '/Users/boris/projects/elite-v06c/orig')
CAS = os.path.join(ORIG, 'bbc/cassette', '3-assembled-output')
SHIPS_BIN = os.path.join(CAS, 'SHIPS.bin')
PYTHON_BIN = os.path.join(CAS, 'PYTHON.bin')
OUT_DIR = os.path.join(ROOT, 'v06c', 'data')

BASE = 0x563A      # адрес SHIPS.bin на BBC
PYTHON_ADDR = 0x7F00
TABLE_LEN = 26     # 13 слов (адреса моделей, младший байт первым)
HDR = '; создано tools/convert/ships.py, руками не править'


def words(data, start, count):
    return [data[start + 2 * i] | (data[start + 2 * i + 1] << 8) for i in range(count)]


def db_lines(data):
    """Строки db по 16 байт, вид 0x12."""
    for off in range(0, len(data), 16):
        chunk = data[off:off + 16]
        yield '\tdb ' + ', '.join('0x%02X' % b for b in chunk)


def main():
    ships = open(SHIPS_BIN, 'rb').read()
    python = open(PYTHON_BIN, 'rb').read()
    assert len(ships) == 2502, f'SHIPS.bin: {len(ships)} байт, нужно 2502'
    assert len(python) == 256, f'PYTHON.bin: {len(python)} байт, нужно 256'

    addrs = words(ships, 0, 13)
    # метки моделей: адрес -> смещение в файле; python определяется вне ships.asm
    labels = {}
    for a in addrs:
        if a == PYTHON_ADDR:
            continue
        off = a - BASE
        assert TABLE_LEN <= off < len(ships), f'адрес 0x{a:04X} вне моделей'
        labels.setdefault(a, off)
    label_at = {off: f'ship_{a:04X}' for a, off in labels.items()}
    assert label_at[TABLE_LEN], 'первая модель должна начинаться сразу после таблицы'

    lines = [HDR, '\tifndef\tNOXX21\t\t\t; обычный образ: таблица — XX21X (ships_zx.asm)', 'XX21:']
    for a in addrs:
        lines.append('\tdw ' + ('ship_python' if a == PYTHON_ADDR else f'ship_{a:04X}'))
    lines.append('\tendif')

    body = ships[TABLE_LEN:]
    line = []
    for i, b in enumerate(body):
        off = TABLE_LEN + i
        if off in label_at:
            if line:
                lines.extend(db_lines(bytes(line)))
                line = []
            lines.append(label_at[off] + ':')
        line.append(b)
    if line:
        lines.extend(db_lines(bytes(line)))

    os.makedirs(OUT_DIR, exist_ok=True)
    with open(os.path.join(OUT_DIR, 'ships.asm'), 'w') as f:
        f.write('\n'.join(lines) + '\n')

    plines = [HDR, 'ship_python:']
    plines.extend(db_lines(python))
    with open(os.path.join(OUT_DIR, 'python.asm'), 'w') as f:
        f.write('\n'.join(plines) + '\n')

    print(f'ships.asm: {len(ships)} байт, python.asm: {len(python)} байт')
    for a in sorted(labels):
        print(f'ship_{a:04X}: смещение {labels[a]} (0x{labels[a]:04X})')


if __name__ == '__main__':
    main()
