#!/usr/bin/env python3
"""Корабли версии для ZX Spectrum, которых нет в кассетной BBC: Krait, Asp Mk II, Fer-de-Lance.
Модели берутся из файлов кораблей дисковой версии BBC (D.MO?.bin: таблица адресов по &5600 и модели), формат
модели тот же, смещения внутри неё относительные. Пишет v06c/data/ships_zx.asm.
Запуск: python3 -I tools/convert/ships_zx.py"""
import glob
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
ORIG = os.environ.get('ELITE_ORIG', '/Users/boris/projects/elite-v06c/orig')
DISC = os.path.join(ORIG, 'bbc/disc/3-assembled-output')
BASE = 0x5600
WANT = [(19, 'krait', 'Krait'), (25, 'asp', 'Asp Mk II'), (27, 'fer', 'Fer-de-Lance')]   # номера типов дисковой версии
JUNK = [(4, 'plate', 'пластина обшивки'), (8, 'splinter', 'обломок астероида')]         # типы 19 и 20


def model(typ):
    for f in sorted(glob.glob(os.path.join(DISC, 'D.MO?.bin'))):
        d = open(f, 'rb').read()
        a = d[2 * (typ - 1)] | (d[2 * (typ - 1) + 1] << 8)
        if not a:
            continue
        o = a - BASE
        h = d[o:o + 20]
        # Рёбра и грани модели могут лежать в чужой модели (обломок берёт их у спасательной капсулы): собираем
        # модель заново — заголовок, вершины, рёбра, грани подряд — и правим смещения в заголовке.
        sgn = lambda v: v - 65536 if v >= 32768 else v
        edges, faces = sgn(h[3] | (h[16] << 8)), sgn(h[4] | (h[17] << 8))
        nv, ne, nf = h[8], 4 * h[9], h[12]
        hd = bytearray(h)
        e2, f2 = 20 + nv, 20 + nv + ne
        hd[3], hd[16], hd[4], hd[17] = e2 & 255, e2 >> 8, f2 & 255, f2 >> 8
        return os.path.basename(f), bytes(hd) + d[o + 20:o + 20 + nv] + d[o + edges:o + edges + ne] + d[o + faces:o + faces + nf]
    raise SystemExit(f'тип {typ}: модели нет ни в одном файле')


def main():
    base = [l.split()[1] for l in open(os.path.join(ROOT, 'v06c/data/ships.asm')) if l.startswith('\tdw ')]
    assert len(base) == 13, base
    out = ['; создано tools/convert/ships_zx.py, руками не править',
           '; Корабли версии для ZX Spectrum (модели дисковой версии BBC): типы 14, 15, 16.',
           '; XX21X: таблица адресов моделей всех типов — 13 кассетных (как XX21) и три новых.',
           'XX21X:'] + ['\tdw ' + l for l in base] + ['\tdw ship_' + lab for _, lab, _ in WANT] + [
           '\tdw ship_asp\t\t; 17: Asp со скрывающим устройством (миссия)', f'\tdw {base[10]}\t\t; 18: контейнер со скрывающим устройством',
           '\tdw ship_plate\t\t; 19: пластина обшивки', '\tdw ship_splinter\t; 20: обломок астероида']
    for typ, lab, name in WANT + JUNK:
        f, m = model(typ)
        out.append(f'ship_{lab}:\t\t\t\t; {name}: {len(m)} байт, вершин {m[8] // 6}, рёбер {m[9]}, граней {m[12] // 4}, '
                   f'отрезков в куче {m[5]}, энергия {m[14]}, награда {(m[10] | (m[11] << 8)) / 10:g} ({f})')
        for i in range(0, len(m), 16):
            out.append('\tdb ' + ', '.join('0x%02X' % b for b in m[i:i + 16]))
    open(os.path.join(ROOT, 'v06c/data/ships_zx.asm'), 'w').write('\n'.join(out) + '\n')
    print('v06c/data/ships_zx.asm:', ', '.join(l for l in out if l.startswith('ship_')))


if __name__ == '__main__':
    main()
