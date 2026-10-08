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


MISSION = [10, 11, 15, 216, 222, 223]        # брифинги и награды двух миссий дисковой версии
CAPT, M28 = [217, 218, 219], [220, 221]      # имя капитана и «последний раз видели…» — по номеру галактики
NRU = 25                                     # особых описаний систем (RUPLA, RUGAL, RUTOK)
JUMPS = (1, 2, 3, 4, 8, 9, 12, 13, 14, 15, 17, 18, 19, 22, 23, 24, 25, 27, 28, 29)
# слова основного словаря игры внутри текста ({6}[n]{5}) — буквами: в кассетном словаре у них другие номера
STD = {117: 'MILITARY  LASER', 108: 'E.C.M.SYSTEM', 114: 'ENERGY UNIT'}


def split(at, start, n):
    toks, cur, p = [], [], start
    while len(toks) < n:
        b = at(p) ^ VE
        p += 1
        if b == 0:
            toks.append(cur)
            cur = []
        else:
            cur.append(b)
    return toks


def unstd(t):
    """Заменить {6}[n]{5} на буквы слова n с {19} перед каждым словом."""
    out, i = [], 0
    while i < len(t):
        if t[i] == 6:
            j = t.index(5, i)
            for n in t[i + 1:j]:                 # каждое слово — с прописной, как печатает TT27
                prev = ' '
                for c in STD[n]:
                    if c.isalpha() and not prev.isalpha():
                        out.append(19)
                    out.append(ord(c))
                    prev = c
            i = j + 1
        else:
            out.append(t[i])
            i += 1
    return out


def main():
    lab = labels()
    img = open(os.path.join(OUT, 'T.CODE.unprot.bin'), 'rb').read()
    at = lambda a: img[a - LOAD]
    toks = [unstd(t) for t in split(at, lab['TKN1'], 256)]
    ru = [unstd(t) for t in split(at, lab['RUTOK'], NRU + 1)]
    for k in range(1, NRU + 1):                  # особые описания — словами 256…
        toks.append(ru[k])
    RU0 = 256
    mtin = [at(lab['MTIN'] + i) for i in range(38)]
    tkn2 = bytes(at(lab['TKN2'] + i) for i in range(2 + 2 * 44))
    assert lab['QQ16'] == lab['TKN2'] + 26
    qq16 = bytes(int(x, 16) for x in re.findall(r'0x([0-9A-F]{2})', open(os.path.join(ROOT, 'v06c/data/qq16.asm')).read()))
    assert tkn2[26:26 + len(qq16)] == qq16, 'пары TKN2 с 13-й должны совпадать с QQ16 кассетной версии'

    seen, groups, refs = set(), [], set()

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
                assert b in JUMPS, 'управляющий код %d в слове %d не перенесён' % (b, n)
    code_only = [ROOT_TOKEN, IAN] + MISSION + CAPT + M28 + list(range(RU0, RU0 + NRU))
    for n in code_only:
        visit(n)
    refs.add(IAN)                                # MT17 зовёт его из кода, номер нужен маленький
    member = {mtin[g - 91] + k: g for g in groups for k in range(5)}
    assert not any(n in member for n in code_only)
    first = [ROOT_TOKEN] + sorted(n for n in seen if n not in member and n in refs)
    last = [n for n in code_only if n not in first]
    assert sorted(first + last) == sorted(n for n in seen if n not in member)
    # группы, на слова которых есть прямые ссылки, идут первыми: номер такого слова должен быть меньше 86
    groups.sort(key=lambda g: (not any(mtin[g - 91] + k in refs for k in range(5)), g))
    new = {n: i for i, n in enumerate(first)}
    for gi, g in enumerate(groups):
        for k in range(5):
            new[mtin[g - 91] + k] = len(first) + 5 * gi + k
    for n in last:
        new[n] = len(new)
    gnew = {g: i for i, g in enumerate(groups)}
    assert len(groups) <= 38 and all(new[r] < 86 for r in refs) and len(new) <= 256, (len(groups), max(new[r] for r in refs), len(new))
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

    eq = [('PD_NG', len(first), 'одиночных слов со ссылками; дальше группы по пять'), ('PD_IAN', new[IAN], 'слово «IAN»'),
          ('PD_BRIEF1', new[10], 'миссия 1: задание'), ('PD_BRIEF2', new[11], 'миссия 2: вызов'), ('PD_DEBRIEF1', new[15], 'миссия 1: награда'),
          ('PD_INCOMING', new[216], '«INCOMING MESSAGE»'), ('PD_BRIEF3', new[222], 'миссия 2: задание'), ('PD_DEBRIEF2', new[223], 'миссия 2: награда'),
          ('PD_CAPT', new[CAPT[0]], 'имя капитана + номер галактики'), ('PD_M28', new[M28[0]], 'где видели «Констриктор» + номер галактики'),
          ('PD_OPEN', 129 + new[176], 'байт-ссылка на слово «начать описание»'), ('PD_CLOSE', new[177], 'слово «точка, конец описания»'),
          ('PD_RU', new[RU0], 'особые описания систем: + номер 0…%d' % (NRU - 1)), ('PD_NRU', NRU, '')]
    assert [new[n] for n in CAPT] == list(range(new[CAPT[0]], new[CAPT[0]] + 3)) and new[M28[1]] == new[M28[0]] + 1
    assert [new[RU0 + k] for k in range(NRU)] == list(range(new[RU0], new[RU0] + NRU))
    lines = ['; Словарь расширенных описаний планет и миссий (дисковая версия BBC: TKN1, MTIN, TKN2, RUTOK).',
             '; создано tools/convert/tkn1.py, руками не править'] + ['%s\t\tequ\t%d\t\t; %s' % e for e in eq] + [
             '; особые описания: номер системы и галактика (бит 7 — показывать всегда, иначе только при миссии 1)',
             'pd_rupla:\tdb ' + ', '.join(str(at(lab['RUPLA'] + i)) for i in range(NRU)),
             'pd_rugal:\tdb ' + ', '.join('0x%02X' % at(lab['RUGAL'] + i) for i in range(NRU)),
             'pd_tkn:']
    size = 0
    for n in old:
        e = enc(n) + [0]
        size += len(e)
        lines.append('; %d: %s' % (new[n], text(n)[:400]))
        for i in range(0, len(e), 24):
            lines.append('\tdb ' + ', '.join('0x%02X' % b for b in e[i:i + 24]))
    lines.append('; пары букв TKN2 с номера 1; пары с 13-й — QQ16, поэтому файл стоит прямо перед qq16.asm')
    lines.append('pd_tkn2\t\tequ\t$ - 2')
    lines.append('\tdb ' + ', '.join('0x%02X' % b for b in tkn2[2:26]) + '\t; ' + tkn2[2:26].decode())
    open(ASM, 'w').write('\n'.join(lines) + '\n')
    print('tkn1: слов %d (одиночных %d, групп %d, из кода %d), %d Б + 24 Б пар + %d Б таблиц → %s' % (len(old), len(first), len(groups), len(last), size, 2 * NRU, os.path.relpath(ASM, ROOT)))


if __name__ == '__main__':
    main()
