#!/usr/bin/env python3
"""Словарь расширенных описаний планет: дисковая версия BBC (TKN1, MTIN, TKN2) → v06c/data/tkn1.asm.

Читает orig/bbc/disc/3-assembled-output: T.CODE.unprot.bin (стоянка, адрес 0x11E3) и compile.txt (адреса меток).
Из 256 слов TKN1 берутся только достижимые из слова 5 (описание планеты) и слова 153 («IAN»); слова
перенумерованы, чтобы обойтись без таблицы MTIN:

  слова 0…NG-1          — одиночные (0 — корень, бывшее слово 5);
  слова NG+5g … NG+5g+4 — группа g: пять вариантов на выбор.

Байты слова (без шифрования, конец — 0):
  1…31     управляющий код, как на BBC (2, 3, 12, 13, 14, 15, 17, 18, 19);
  32…90    знак;
  91+g     случайное слово из группы g;
  129+n    слово n (n < 86);
  215+k    пара букв номер k таблицы TKN2 (нумерация BBC).

Пары TKN2 с номера 13 — это QQ16 кассетной версии; в файл идут только пары 1…12, файл включается прямо перед
qq16.asm. Запуск из корня проекта: python3 -I tools/convert/tkn1.py
"""
import os
import re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
ORIG = os.environ.get('ELITE_ORIG', '/Users/boris/projects/elite-v06c/orig')
OUT = os.path.join(ORIG, 'bbc', 'disc', '3-assembled-output')
ASM = os.path.join(ROOT, 'v06c', 'data', 'tkn1.asm')
LOAD = 0x11E3
VE = 0x57
ROOT_TOKEN, IAN = 5, 153


def labels():
    t = open(os.path.join(OUT, 'compile.txt'), encoding='latin1').read()
    a = t.index("Saving file '3-assembled-output/D.CODE.unprot.bin'")
    b = t.index("Saving file '3-assembled-output/T.CODE.unprot.bin'")
    lab = {}
    for m in re.finditer(r'^\.(\S+) *\r?\n\s+([0-9A-F]{4})\b', t[a:b], re.M):
        lab.setdefault(m.group(1), int(m.group(2), 16))
    return lab


def main():
    lab = labels()
    img = open(os.path.join(OUT, 'T.CODE.unprot.bin'), 'rb').read()
    at = lambda a: img[a - LOAD]
    toks, cur, p = [], [], lab['TKN1']
    while len(toks) < 256:
        b = at(p) ^ VE
        p += 1
        if b == 0:
            toks.append(cur)
            cur = []
        else:
            cur.append(b)
    mtin = [at(lab['MTIN'] + i) for i in range(38)]
    tkn2 = bytes(at(lab['TKN2'] + i) for i in range(2 + 2 * 44))
    assert lab['QQ16'] == lab['TKN2'] + 26
    qq16 = bytes(int(x, 16) for x in re.findall(r'0x([0-9A-F]{2})', open(os.path.join(ROOT, 'v06c/data/qq16.asm')).read()))
    assert tkn2[26:26 + len(qq16)] == qq16, 'пары TKN2 с 13-й должны совпадать с QQ16 кассетной версии'

    seen, groups, refs, order = set(), [], set(), []

    def visit(n):
        if n in seen:
            return
        seen.add(n)
        for b in toks[n]:
            if 91 <= b < 129:
                if b not in groups:
                    groups.append(b)
                for k in range(5):
                    visit(mtin[b - 91] + k)
            elif 129 <= b < 215:
                refs.add(b)
                visit(b)
            elif b < 32:
                assert b in (2, 3, 12, 13, 14, 15, 17, 18, 19), 'управляющий код %d не перенесён' % b
    visit(ROOT_TOKEN)
    visit(IAN)
    member = {mtin[g - 91] + k: g for g in groups for k in range(5)}
    single = [ROOT_TOKEN] + sorted(n for n in seen if n not in member and n != ROOT_TOKEN)
    # группы, на слова которых есть прямые ссылки, идут первыми: номер такого слова должен быть меньше 86
    groups.sort(key=lambda g: (not any(mtin[g - 91] + k in refs for k in range(5)), g))
    new = {n: i for i, n in enumerate(single)}
    for gi, g in enumerate(groups):
        for k in range(5):
            new[mtin[g - 91] + k] = len(single) + 5 * gi + k
    gnew = {g: i for i, g in enumerate(groups)}
    assert len(groups) <= 38 and all(new[r] < 86 for r in refs)
    old = sorted(new, key=new.get)

    def enc(n):
        out = []
        for b in toks[n]:
            if 91 <= b < 129:
                out.append(91 + gnew[b])
            elif 129 <= b < 215:
                out.append(129 + new[b])
            else:
                out.append(b)
        return out

    def text(n):
        s = ''
        for b in toks[n]:
            if b < 32:
                s += '{%d}' % b
            elif b < 91:
                s += chr(b)
            elif b < 129:
                s += '[группа %d]' % gnew[b]
            elif b < 215:
                s += '<%d>' % new[b]
            else:
                s += chr(tkn2[(b - 215) * 2]) + chr(tkn2[(b - 215) * 2 + 1])
        return s

    lines = ['; Словарь расширенных описаний планет (дисковая версия BBC: TKN1, MTIN, TKN2).',
             '; создано tools/convert/tkn1.py, руками не править',
             'PD_NG\t\tequ\t%d\t\t; одиночных слов; дальше группы по пять' % len(single),
             'PD_IAN\t\tequ\t%d\t\t; слово «IAN»' % new[IAN],
             'pd_tkn:']
    size = 0
    for n in old:
        e = enc(n) + [0]
        size += len(e)
        lines.append('\tdb ' + ', '.join('0x%02X' % b for b in e) + '\t; %d: %s' % (new[n], text(n)))
    lines.append('; пары букв TKN2 с номера 1; пары с 13-й — QQ16, поэтому файл стоит прямо перед qq16.asm')
    lines.append('pd_tkn2\t\tequ\t$ - 2')
    lines.append('\tdb ' + ', '.join('0x%02X' % b for b in tkn2[2:26]) + '\t; ' + tkn2[2:26].decode())
    open(ASM, 'w').write('\n'.join(lines) + '\n')
    print('tkn1: слов %d (одиночных %d, групп %d), %d Б + 24 Б пар → %s' % (len(old), len(single), len(groups), size, os.path.relpath(ASM, ROOT)))


if __name__ == '__main__':
    main()
