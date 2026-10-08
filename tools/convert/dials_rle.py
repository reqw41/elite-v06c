#!/usr/bin/env python3
"""Картинка панели приборов v06c/data/dials.bin -> v06c/data/dials.rle (сжатие повторов).
Картинка нужна один раз при запуске, а нулей в ней три четверти. Поток: байт n < 80h — дальше n + 1 байт как есть;
n >= 80h — следующий байт повторить (n - 80h) + 2 раза. Распаковка — ds_get в v06c/src/dash.asm.
Запуск: python3 -I tools/convert/dials_rle.py (после tools/convert/dials.py)."""
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))


def pack(d):
    out, lit, i = bytearray(), bytearray(), 0

    def flush():
        while lit:
            chunk = lit[:128]
            out.append(len(chunk) - 1)
            out.extend(chunk)
            del lit[:128]
    while i < len(d):
        j = i
        while j < len(d) and d[j] == d[i] and j - i < 129:
            j += 1
        if j - i >= 3:
            flush()
            out += bytes([0x80 + (j - i) - 2, d[i]])
            i = j
        else:
            lit.append(d[i])
            i += 1
    flush()
    return bytes(out)


def unpack(p, n):
    out, i = bytearray(), 0
    while len(out) < n:
        c = p[i]
        i += 1
        if c < 0x80:
            out += p[i:i + c + 1]
            i += c + 1
        else:
            out += bytes([p[i]]) * (c - 0x80 + 2)
            i += 1
    assert i == len(p), (i, len(p))
    return bytes(out)


def main():
    d = open(os.path.join(ROOT, 'v06c/data/dials.bin'), 'rb').read()
    p = pack(d)
    assert unpack(p, len(d)) == d
    open(os.path.join(ROOT, 'v06c/data/dials.rle'), 'wb').write(p)
    print(f'dials.rle: {len(d)} -> {len(p)} байт')


if __name__ == '__main__':
    main()
