#!/usr/bin/env python3
"""Разбор снимка памяти Elite для ZX Spectrum 48K (Firebird, 1985): обход кода по переходам.

Снимок (work/zx48/zxram.bin — память 4000h…FFFFh, 49152 байта; в репозиторий не входит) делится на код и данные:
от точек входа идём по командам Z80, собираем адреса вызовов и переходов. Точки входа — счётчик команд снимка,
адреса возврата на стеке, таблицы переходов (JP подряд) и адреса из файла tools/analysis/zx48_seeds.txt (по одному в строке,
шестнадцатеричные; добавляются руками по мере разбора косвенных вызовов).

Пишет work/zx48/map.txt (области кода и данных), work/zx48/calls.txt (процедуры: адрес, откуда зовут) и блок-файл
для z80dasm; печатает сводку. Запуск: python3 -I tools/analysis/zx48_trace.py"""
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
W = os.path.join(ROOT, 'work/zx48')
ram = open(os.path.join(W, 'zxram.bin'), 'rb').read()
BASE = 0x4000
rb = lambda a: ram[a - BASE]
rw = lambda a: rb(a) | (rb(a + 1) << 8)


def ilen(a):
    """Длина команды Z80 по адресу a и её вид: ('', None) | ('jp'|'call'|'jr', цель) | ('ret',) | ('jpi',) | ('rst', n)."""
    op = rb(a)
    if op == 0xCB:
        return 2, ('', None)
    if op == 0xED:
        o2 = rb(a + 1)
        if o2 in (0x43, 0x4B, 0x53, 0x5B, 0x63, 0x6B, 0x73, 0x7B):
            return 4, ('', None)
        if o2 in (0x45, 0x4D, 0x55, 0x5D, 0x65, 0x6D, 0x75, 0x7D):
            return 2, ('ret', None)
        return 2, ('', None)
    if op in (0xDD, 0xFD):
        o2 = rb(a + 1)
        if o2 == 0xCB:
            return 4, ('', None)
        if o2 == 0xE9:
            return 2, ('jpi', None)
        if o2 in (0x21, 0x22, 0x2A):
            return 4, ('', None)
        if o2 == 0x36:
            return 4, ('', None)
        if o2 in (0x34, 0x35) or (0x40 <= o2 < 0xC0 and ((o2 & 7) == 6 or (o2 & 0xF8) == 0x70) and o2 != 0x76):
            return 3, ('', None)
        if o2 in (0x26, 0x2E):
            return 3, ('', None)
        n, k = ilen(a + 1)
        return n + 1, k
    x, y, z = op >> 6, (op >> 3) & 7, op & 7
    if x == 0:
        if z == 0:
            if y == 0 or y == 1:
                return 1, ('', None)
            t = (a + 2 + ((rb(a + 1) ^ 0x80) - 0x80)) & 0xFFFF
            return 2, ('jr' if y == 3 else 'jrc', t)
        if z == 1:
            return (3, ('', None)) if not (y & 1) else (1, ('', None))
        if z == 2:
            return (3, ('', None)) if y >= 4 else (1, ('', None))
        if z == 6:
            return 2, ('', None)
        return 1, ('', None)
    if x == 1:
        return 1, (('halt', None) if op == 0x76 else ('', None))
    if x == 2:
        return 1, ('', None)
    if z == 0:
        return 1, ('retc', None)
    if z == 1:
        if op == 0xC9:
            return 1, ('ret', None)
        if op == 0xE9:
            return 1, ('jpi', None)
        return 1, ('', None)
    if z == 2:
        return 3, ('jpc', rw(a + 1))
    if z == 3:
        if op == 0xC3:
            return 3, ('jp', rw(a + 1))
        if op in (0xD3, 0xDB):
            return 2, ('', None)
        return 1, ('', None)
    if z == 4:
        return 3, ('callc', rw(a + 1))
    if z == 5:
        if op == 0xCD:
            return 3, ('call', rw(a + 1))
        return 1, ('', None)
    if z == 6:
        return 2, ('', None)
    return 1, ('rst', op & 0x38)


# области, где кода заведомо нет: экран, рабочие области и блоки объектов, модели кораблей (найдены сравнением вершин с BBC),
# тексты (расшифрованы — docs/research/zx48_texts.md)
NOCODE = [(0x4000, 0x6FF8), (0xC000, 0xD000), (0xF11A, 0xFD8F)]   # 5B00…6FF7: рабочие области, блоки объектов (6048h, по 39 байт), модели; C000…CFFF: буфер обзора 256×128
nocode = lambda a: any(lo <= a < hi for lo, hi in NOCODE)


def main():
    seeds = set()
    hdr = open(os.path.join(W, 'elite48.z80'), 'rb').read()[:30]
    seeds.add(hdr[6] | hdr[7] << 8)
    sp = hdr[8] | hdr[9] << 8
    stack = [rw(a) for a in range(sp, 0xFFFE, 2)]   # для справки; в точки входа не идёт: на стеке бывают данные
    sf = os.path.join(os.path.dirname(__file__), 'zx48_seeds.txt')
    inline = {}                                  # процедуры с байтами после CALL: адрес -> сколько байт
    if os.path.exists(sf):
        for l in open(sf):
            l = l.split('#')[0].split()
            if not l:
                continue
            if l[0] == 'inline':
                inline[int(l[1], 16)] = int(l[2])
            elif l[0] == 'table':                # table адрес число: слова-адреса процедур
                for i in range(int(l[2])):
                    seeds.add(rw(int(l[1], 16) + 2 * i))
            else:
                seeds.add(int(l[0], 16))
    code = {}                                    # адрес -> длина
    calls, jumps = {}, {}
    todo = [s for s in seeds if 0x5B00 <= s < 0x10000 and not nocode(s)]
    entry = set(todo)
    while todo:
        a = todo.pop()
        while 0x4000 <= a < 0xFFFD and a not in code and not nocode(a):
            try:
                n, (k, t) = ilen(a)
            except IndexError:
                break
            code[a] = n
            nxt = a + n
            if k in ('call', 'callc'):
                calls.setdefault(t, set()).add(a)
                if t >= 0x5B00:
                    todo.append(t)
                nxt += inline.get(t, 0)
            elif k in ('jp', 'jpc', 'jr', 'jrc'):
                jumps.setdefault(t, set()).add(a)
                if t >= 0x5B00:
                    todo.append(t)
            if k in ('jp', 'jr', 'ret', 'jpi', 'halt'):
                break
            a = nxt
    covered = bytearray(0x10000)
    for a, n in code.items():
        for i in range(n):
            covered[a + i] = 1
    regions, a = [], 0x4000
    while a < 0x10000:
        b = a
        while b < 0x10000 and covered[b] == covered[a]:
            b += 1
        regions.append((a, b, 'код' if covered[a] else 'данные'))
        a = b
    ncode = sum(covered)
    with open(os.path.join(W, 'map.txt'), 'w') as f:
        for a, b, k in regions:
            f.write('%04X-%04X %6d %s\n' % (a, b - 1, b - a, k))
    with open(os.path.join(W, 'calls.txt'), 'w') as f:
        for t in sorted(calls):
            f.write('%04X %3d %s\n' % (t, len(calls[t]), ' '.join('%04X' % c for c in sorted(calls[t])[:12])))
    with open(os.path.join(W, 'blocks.txt'), 'w') as f:
        for i, (a, b, k) in enumerate(regions):
            f.write('b%d: start 0x%04x end 0x%04x type %s\n' % (i, a, b, 'code' if k == 'код' else 'bytedata'))
    print('стек снимка:', ' '.join('%04X' % v for v in stack))
    print('точек входа %d, команд %d, байт кода %d, процедур (целей CALL) %d' % (len(entry), len(code), ncode, len(calls)))
    big = [(b - a, a, b, k) for a, b, k in regions if b - a >= 64]
    for n, a, b, k in sorted(big, key=lambda r: r[1]):
        print('%04X-%04X %6d %s' % (a, b - 1, n, k))
    print('по крупным диапазонам (всего байт, из них код):')
    for lo, hi, name in [(0x4000, 0x5B00, 'экран и атрибуты'), (0x5B00, 0x6048, 'рабочие области'), (0x6048, 0x6180, 'блоки объектов, 8 × 39'),
                         (0x6180, 0x61CC, 'таблица типов, 19 × 4'), (0x61CC, 0x6FF8, 'модели кораблей'), (0x6FF8, 0xC000, 'код полёта'),
                         (0xC000, 0xD000, 'буфер обзора 256×128'), (0xD000, 0xD03F, 'таблица переходов'), (0xD03F, 0xD0E4, 'переменные командира и игры'),
                         (0xD0E4, 0xF117, 'код экранов станции, текста, миссий'), (0xF117, 0xFD8F, 'тексты'), (0xFD8F, 0x10000, 'хвост: код, стек')]:
        print('%04X-%04X %6d %6d  %s' % (lo, hi - 1, hi - lo, sum(covered[lo:hi]), name))
    rom = sorted((t, len(c)) for t, c in calls.items() if t < 0x4000)
    print('вызовы ПЗУ:', ' '.join('%04X×%d' % r for r in rom))


if __name__ == '__main__':
    main()
