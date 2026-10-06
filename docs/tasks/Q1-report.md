# Q1-report. Модели кораблей BBC → исходник для sjasmplus

## Результат

Задача выполнена. Созданы: `tools/convert/ships.py`, `v06c/data/ships.asm`, `v06c/data/python.asm`.
`tools/convert/test_convert.py` не менялся. Git-коммитов нет.

## Вывод проверок

`python3 -I tools/convert/ships.py`:

```
ships.asm: 2502 байт, python.asm: 256 байт
ship_5654: смещение 26 (0x001A)
ship_56FC: смещение 194 (0x00C2)
ship_57D6: смещение 412 (0x019C)
ship_5904: смещение 714 (0x02CA)
ship_5A8C: смещение 1106 (0x0452)
ship_5BA8: смещение 1390 (0x056E)
ship_5CC4: смещение 1674 (0x068A)
ship_5DC2: смещение 1928 (0x0788)
ship_5E98: смещение 2142 (0x085E)
ship_5F40: смещение 2310 (0x0906)
ship_5FAC: смещение 2418 (0x0972)
```

`python3 -I tools/convert/test_convert.py ships`:

```
ships.asm: совпало, 2502 байт
python.asm: совпало, 256 байт
```

## Доказано

- Таблица из 13 адресов в SHIPS.bin (BASE = 0x563A): 0x5654, 0x56FC, 0x57D6, 0x7F00, 0x5904,
  0x5A8C, 0x5904 (повтор), 0x5BA8, 0x5CC4, 0x5DC2, 0x5E98, 0x5F40, 0x5FAC.
  0x7F00 — Python (отдельный файл), остальные 11 уникальных адресов идут по возрастанию,
  первый = 0x5654 = 0x563A + 26 (ровно конец таблицы).
- Метки `ship_XXXX` в ships.asm и их смещения от начала файла (= адрес − 0x563A):

  | метка | адрес | смещение в файле |
  |---|---|---|
  | ship_5654 | 0x5654 | 26 |
  | ship_56FC | 0x56FC | 194 |
  | ship_57D6 | 0x57D6 | 412 |
  | ship_5904 | 0x5904 | 714 |
  | ship_5A8C | 0x5A8C | 1106 |
  | ship_5BA8 | 0x5BA8 | 1390 |
  | ship_5CC4 | 0x5CC4 | 1674 |
  | ship_5DC2 | 0x5DC2 | 1928 |
  | ship_5E98 | 0x5E98 | 2142 |
  | ship_5F40 | 0x5F40 | 2310 |
  | ship_5FAC | 0x5FAC | 2418 |

- `ship_python` в ships.asm не определяется (в тесте задан как `EQU 0x7F00`); определена в python.asm.
- Совпадение байтов собранного ships.asm / python.asm с SHIPS.bin / PYTHON.bin — вывод теста выше.

## Гипотезы

Нет.
