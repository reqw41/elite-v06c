#!/usr/bin/env python3
"""Конвертер словаря BBC WORDS9.bin → исходник для sjasmplus (i8080).

Читает:
  orig/bbc/cassette/3-assembled-output/WORDS9.bin  (1023 байта, адрес 0x0400)

Пишет:
  v06c/data/words.asm   метка QQ18 + байты записей строками db (как в файле,
  зашифрованными), в конце каждой строки комментарий с расшифровкой.

Кодировка: запись заканчивается байтом 0x00 (он не шифруется). Остальные байты:
настоящий код = байт XOR 35. Коды 32-95 - обычный знак ASCII, остальные -
служебные коды (в комментарии как <число>, в байтах как в файле).

Запуск из корня проекта: python3 -I tools/convert/words.py
"""
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
ORIG = os.environ.get('ELITE_ORIG', '/Users/boris/projects/elite-v06c/orig')
WORDS_BIN = os.path.join(ORIG, 'bbc', 'cassette', '3-assembled-output', 'WORDS9.bin')
WORDS_ASM = os.path.join(ROOT, 'v06c', 'data', 'words.asm')

XOR_KEY = 35
HEADER = '; создано tools/convert/words.py, руками не править'


def decode_text(record):
    """Расшифровка записи (без завершающего 0x00) для комментария."""
    parts = []
    for b in record:
        code = b ^ XOR_KEY
        if 32 <= code <= 95:
            parts.append(chr(code))
        else:
            parts.append('<%d>' % code)
    return ''.join(parts)


def db_line(chunk):
    return '\tdb ' + ', '.join('0x%02X' % b for b in chunk)


def main():
    with open(WORDS_BIN, 'rb') as f:
        data = f.read()

    out = [HEADER, 'QQ18:']
    pos = 0
    n = len(data)
    num = 0
    while pos < n:
        end = data.find(b'\x00', pos)
        if end == -1:
            # хвост после последнего завершающего байта
            out.append(db_line(data[pos:]))
            pos = n
            break
        record = data[pos:end]
        line = db_line(list(record) + [0x00])
        out.append('%s ; %d: %s' % (line, num, decode_text(record)))
        pos = end + 1
        num += 1

    os.makedirs(os.path.dirname(WORDS_ASM), exist_ok=True)
    with open(WORDS_ASM, 'w') as f:
        f.write('\n'.join(out) + '\n')

    print(f'words.asm: {n} байт источника, {num} записей')


if __name__ == '__main__':
    main()
