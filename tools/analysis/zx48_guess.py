#!/usr/bin/env python3
"""Кандидаты в код среди областей, до которых обход zx48_trace.py не дошёл (косвенные вызовы, таблицы адресов).
Область считается кодом, если с её начала команды идут подряд до конца области, последняя — безусловный переход
или возврат, а все цели переходов попадают в начало уже известной команды или внутрь этой же цепочки.
Найденные начала дописываются в tools/analysis/zx48_seeds.txt. Запускать по очереди с zx48_trace.py, пока находит."""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
import zx48_trace as T

W = T.W
known = set()
regions = []
for l in open(os.path.join(W, 'map.txt')):
    r, n, k = l.split()
    a, b = [int(x, 16) for x in r.split('-')]
    regions.append((a, b + 1, k))
# известные начала команд: повторить обход нельзя дёшево — берём границы областей кода и цели из calls.txt
starts = set(int(l.split()[0], 16) for l in open(os.path.join(W, 'calls.txt')))
iscode = bytearray(0x10000)
for a, b, k in regions:
    if k == 'код':
        for x in range(a, b):
            iscode[x] = 1
found = []
for a, b, k in regions:
    if k != 'данные' or T.nocode(a):
        continue
    p = a
    while p < b:
        # пропустить нули и одиночные байты-заглушки
        q, chain, ok, last = p, [], True, ''
        while q < b:
            try:
                n, (kind, t) = T.ilen(q)
            except IndexError:
                ok = False
                break
            if T.rb(q) in (0x00, 0xFF) and not chain:
                ok = False
                break
            chain.append((q, n, kind, t))
            q += n
            last = kind
            if kind in ('jp', 'jr', 'ret', 'jpi'):
                break
        if ok and chain and last in ('jp', 'jr', 'ret', 'jpi') and len(chain) >= 3:
            own = set(c[0] for c in chain)
            good = all(t is None or t < 0x4000 or iscode[t] or t in own or (a <= t < b) for _, _, kind, t in chain)
            calls = sum(1 for c in chain if c[2] in ('call', 'callc') and c[3] is not None and (iscode[c[3]] or c[3] < 0x4000))
            if good and (calls >= 1 or len(chain) >= 8):
                found.append(p)
                p = q
                continue
        p += 1
with open(os.path.join(os.path.dirname(__file__), 'zx48_seeds.txt'), 'a') as f:
    f.write('# кандидаты zx48_guess.py\n' + ''.join('%04X\n' % x for x in found))
print('кандидатов', len(found), ' '.join('%04X' % x for x in found[:60]))
