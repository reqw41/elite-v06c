#!/usr/bin/env python3
"""Размеры по исходным файлам и статистика Z80-команд по листингу sjasmplus.
Запуск: python3 -I tools/analysis/lst_sizes.py work/zxbuild/'!log'/log.txt
"""
import re, sys, collections
lst = open(sys.argv[1], 'rb').read().decode('cp866', 'replace').splitlines()
stack = []; size = collections.Counter(); z80 = collections.Counter(); code = collections.Counter()
rx = re.compile(r'^\s*(\d+)(\++)?\s*([0-9A-F]{4})((?: [0-9A-F]{2})+)?(?:\s(.*))?$')
MN = re.compile(r'^(?:[.@\w]+:?)?\s+(\w+)\s*(.*?)\s*(?:;.*)?$')
def cls(m, a):
    a = a.lower().replace(' ', '').replace('\t', '')
    if re.search(r'\b(ix|iy|ixl|ixh|iyl|iyh|lx|hx|ly|hy)\b', a): return 'IX/IY'
    if m in ('jr', 'djnz'): return m
    if m in ('exx',) or (m == 'ex' and a.startswith('af')): return 'exx/ex af'
    if m in ('ldir', 'lddr', 'ldi', 'ldd', 'cpir', 'cpi', 'cpdr', 'cpd'): return 'блочные'
    if m in ('bit', 'set', 'res'): return 'bit/set/res'
    if m in ('rlc', 'rrc', 'rl', 'rr', 'sla', 'sra', 'srl', 'sll', 'sli', 'rld', 'rrd'): return 'сдвиги CB'
    if m == 'neg': return 'neg'
    if m in ('sbc', 'adc') and a.startswith('hl'): return 'adc/sbc hl'
    if m == 'ld' and re.match(r'(\(.+\),(bc|de|sp)|(bc|de|sp),\(.+\))$', a): return 'ld (nn),rr'
    if m in ('in', 'out') and '(c)' in a: return 'in/out (c)'
    if m == 'ld' and re.match(r'(a,[ir]|[ir],a)$', a): return 'ld a,r/i'
    if m in ('im', 'retn', 'reti'): return m
    return None
OPS = set('ld call jp jr add sub inc dec push pop and or xor cp ret djnz exx ex ldir lddr ldi ldd cpir neg bit set res rlc rrc rl rr sla sra srl adc sbc in out rla rra rlca rrca cpl scf ccf halt di ei nop daa rst im cpi sll'.split())
for ln in lst:
    if ln.startswith('# file opened:'): stack.append(ln.split(':', 1)[1].strip()); continue
    if ln.startswith('# file closed:'):
        if stack: stack.pop()
        continue
    m = rx.match(ln)
    if not m or not stack: continue
    f = stack[-1]; nb = len(m.group(4).split()) if m.group(4) else 0
    size[f] += nb
    src = m.group(5) or ''
    mm = MN.match(src) if nb else None
    if mm and mm.group(1).lower() in OPS:
        mn = mm.group(1).lower(); code[f] += nb
        c = cls(mn, mm.group(2))
        z80['всего команд'] += 1
        if c: z80[c] += 1
tot = sum(size.values())
print(f'ВСЕГО байт в листинге: {tot}')
for f, n in sorted(size.items(), key=lambda x: -x[1]):
    if n: print(f'{n:6d}  код {code[f]:6d}  {f}')
print('--- Z80-специфика (число команд)')
for k, n in z80.most_common(): print(f'{n:6d}  {k}')
