#!/usr/bin/env python3
"""Чтение кода снимка ZX 48K: дизассемблер с именами и подписями.
  zx48_show.py АДРЕС [АДРЕС_ДО | +N]   — листинг куска (адреса шестнадцатеричные)
  zx48_show.py ref АДРЕС                — кто ссылается на адрес (CALL, JP, JR, чтение и запись ячейки)
Имена — tools/analysis/zx48_names.txt (адрес имя [пояснение]); после CALL печати слова подставляется текст
(docs/research/zx48_texts.md). Команды разбираются с заданного адреса подряд; байты-параметры после вызовов
D421h, E2BCh, F068h учитываются."""
import os, re, subprocess, sys, tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
ram = open(os.path.join(ROOT, 'work/zx48/zxram.bin'), 'rb').read()
names, notes = {}, {}
nf = os.path.join(os.path.dirname(__file__), 'zx48_names.txt')
if os.path.exists(nf):
    for l in open(nf, encoding='utf-8'):
        p = l.split('#')[0].split(None, 2)
        if len(p) >= 2:
            names[int(p[0], 16)] = p[1]
            if len(p) > 2:
                notes[int(p[0], 16)] = p[2].strip()
words, ext = {}, {}
for l in open(os.path.join(ROOT, 'docs/research/zx48_texts.md'), encoding='utf-8'):
    m = re.match(r'^(\d+) 0x([0-9a-f]{4}) ?(.*)$', l)
    if m:
        (words if int(m.group(2), 16) < 0xF4F5 else ext)[int(m.group(1))] = m.group(3)
INLINE = {0xD421: 1, 0xE2BC: 1, 0xF068: 1}


def dis(a, b):
    """Список (адрес, длина, текст) с a до b."""
    out = []
    with tempfile.TemporaryDirectory() as d:
        while a < b:
            n = min(b - a, 6)
            f = os.path.join(d, 'x.bin')
            open(f, 'wb').write(ram[a - 0x4000:a - 0x4000 + 8])
            t = subprocess.run(['z80dasm', '-a', '-t', '-g', hex(a), f], capture_output=True, text=True).stdout
            line = [x for x in t.split('\n') if '\t;%04x' % a in x]
            if not line:
                out.append((a, 1, 'defb %02Xh' % ram[a - 0x4000]))
                a += 1
                continue
            parts = line[0].split('\t')
            txt = parts[1]
            ln = len(parts[-2].split()) if len(parts) > 3 else 1
            m = re.search(r';[0-9a-f]{4}\t([0-9a-f ]+)', line[0])
            ln = len(m.group(1).split()) if m else 1
            m3 = re.search(r'\$([+-]\d+)', txt)
            if m3:
                txt = txt[:m3.start()] + '%04xh' % ((a + int(m3.group(1))) & 0xFFFF) + txt[m3.end():]
            out.append((a, ln, txt))
            a += ln
            m2 = re.match(r'call 0?([0-9a-f]{4})h', txt)
            if m2 and int(m2.group(1), 16) in INLINE:
                k = ram[a - 0x4000]
                out.append((a, 1, 'defb %d' % k + ('   ; «%s»' % words.get(k, '?') if int(m2.group(1), 16) != 0xE2BC else '')))
                a += 1
    return out


def nm(txt):
    def r(m):
        v = int(m.group(1), 16)
        return names[v] if v in names else m.group(0)
    return re.sub(r'\b0?([0-9a-f]{4})h\b', r, txt)


def main():
    if sys.argv[1] == 'ref':
        t = int(sys.argv[2], 16)
        lo, hi = t & 255, t >> 8
        for a in range(0x6FF8, 0xFFFD):
            if ram[a - 0x4000 + 1] == lo and ram[a - 0x4000 + 2] == hi and not (0xC000 <= a < 0xD000) and not (0xF117 <= a < 0xFD8F):
                op = ram[a - 0x4000]
                pre = ram[a - 0x4000 - 1]
                kind = {0xCD: 'call', 0xC3: 'jp', 0x32: 'ld (),a', 0x3A: 'ld a,()', 0x21: 'ld hl,', 0x22: 'ld (),hl', 0x2A: 'ld hl,()', 0x11: 'ld de,', 0x01: 'ld bc,'}.get(op)
                if op & 0xC7 in (0xC2, 0xC4):
                    kind = 'jp/call cc'
                if pre == 0xED and op in (0x43, 0x4B, 0x53, 0x5B, 0x73, 0x7B):
                    kind = 'ld 16'
                if pre in (0xDD, 0xFD) and op in (0x21, 0x22, 0x2A):
                    kind = 'ix/iy'
                if kind:
                    print('%04X %s' % (a, kind))
        return
    a = int(sys.argv[1], 16)
    b = a + 80
    if len(sys.argv) > 2:
        b = a + int(sys.argv[2][1:]) if sys.argv[2].startswith('+') else int(sys.argv[2], 16) + 1
    row = []
    for ad, ln, txt in dis(a, b):
        lab = (names[ad] + ': ') if ad in names else ''
        s = '%04X %s%s' % (ad, lab, nm(txt))
        m = re.match(r'ld a,0?([0-9a-f]{2})h', txt)
        row.append(s)
        if txt.startswith(('ret', 'jp ', 'jr ')) and 'nz' not in txt and ' z,' not in txt and ' c,' not in txt and 'nc,' not in txt and ' m,' not in txt and ' p,' not in txt:
            print(' | '.join(row))
            row = []
        elif len(row) >= 5:
            print(' | '.join(row))
            row = []
    if row:
        print(' | '.join(row))


if __name__ == '__main__':
    main()
