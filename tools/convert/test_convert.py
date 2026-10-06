#!/usr/bin/env python3
"""Проверки конвертеров данных BBC → Вектор. Запуск: python3 -I tools/convert/test_convert.py ships|words|dials
Оригиналы читаются из основного каталога проекта (orig/ в git и в worktree не входит)."""
import os, subprocess, sys
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
ORIG = os.environ.get('ELITE_ORIG', '/Users/boris/projects/elite-v06c/orig')
CAS = os.path.join(ORIG, 'bbc/cassette')
ASM = os.environ.get('SJASMPLUS', '/Users/boris/projects/elite-v06c/tools/bin/sjasmplus')
WORK = os.path.join(ROOT, 'work/convert'); os.makedirs(WORK, exist_ok=True)

def assemble(name, text):
    src = os.path.join(WORK, name + '.asm'); out = os.path.join(WORK, name + '.bin')
    open(src, 'w').write(text + f'\n\tSAVEBIN "{out}", start, $-start\n')
    r = subprocess.run([ASM, '--i8080', '--nologo', '--msg=war', src], capture_output=True, text=True)
    if r.returncode or 'error' in (r.stdout + r.stderr).lower(): sys.exit('sjasmplus:\n' + r.stdout + r.stderr)
    return open(out, 'rb').read()

def same(got, want, what):
    if got == want: print(f'{what}: совпало, {len(want)} байт'); return
    n = next((i for i in range(min(len(got), len(want))) if got[i] != want[i]), min(len(got), len(want)))
    sys.exit(f'{what}: РАСХОЖДЕНИЕ, длина {len(got)} против {len(want)}, первое различие по смещению {n}')

def ships():
    inc = os.path.join(ROOT, 'v06c/data/ships.asm')
    got = assemble('ships', f'\tDEVICE NOSLOT64K\nship_python EQU 0x7F00\n\tORG 0x563A\nstart:\n\tINCLUDE "{inc}"')
    same(got, open(os.path.join(CAS, '3-assembled-output/SHIPS.bin'), 'rb').read(), 'ships.asm')
    inc = os.path.join(ROOT, 'v06c/data/python.asm')
    got = assemble('python', f'\tDEVICE NOSLOT64K\n\tORG 0x7F00\nstart:\n\tINCLUDE "{inc}"')
    same(got, open(os.path.join(CAS, '3-assembled-output/PYTHON.bin'), 'rb').read(), 'python.asm')

def words():
    inc = os.path.join(ROOT, 'v06c/data/words.asm')
    got = assemble('words', f'\tDEVICE NOSLOT64K\n\tORG 0x0400\nstart:\n\tINCLUDE "{inc}"')
    same(got, open(os.path.join(CAS, '3-assembled-output/WORDS9.bin'), 'rb').read(), 'words.asm')

def dials():
    d = open(os.path.join(ROOT, 'v06c/data/dials.bin'), 'rb').read()
    if len(d) != 2 * 32 * 56: sys.exit(f'dials.bin: длина {len(d)}, нужно 3584')
    def px(x, y):   # цвет 0..3 точки экрана Вектора (x 0..255, y 0..55)
        col, bit = x >> 3, 7 - (x & 7)
        return ((d[col * 56 + y] >> bit) & 1) | (((d[1792 + col * 56 + y] >> bit) & 1) << 1)
    out = bytearray(1792)
    for y in range(56):
        for X in range(128):
            c = px(2 * X, y)
            if px(2 * X + 1, y) != c: sys.exit(f'dials.bin: точка двойной ширины X={X} y={y} разного цвета')
            k = X & 3; i = (y >> 3) * 256 + (X >> 2) * 8 + (y & 7)
            out[i] |= ((c >> 1) << (7 - k)) | ((c & 1) << (3 - k))
    same(bytes(out), open(os.path.join(CAS, '1-source-files/images/P.DIALS.bin'), 'rb').read(), 'dials.bin → раскладка BBC')
    if not os.path.exists(os.path.join(ROOT, 'v06c/data/dials.png')): sys.exit('нет v06c/data/dials.png')

{'ships': ships, 'words': words, 'dials': dials}[sys.argv[1]]()
