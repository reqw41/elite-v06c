# Q3-report. Картинка панели BBC P.DIALS.bin → две плоскости Вектора

## Результат

Задача выполнена. Созданы: `tools/convert/dials.py`, `v06c/data/dials.bin`,
`v06c/data/dials.png`. `tools/convert/test_convert.py` не менялся. Git-коммитов нет.

## Вывод проверок

`python3 -I tools/convert/dials.py`:

```
dials.bin: 3584 байт (плоскость 0 + плоскость 1 по 1792)
dials.png: 512x112, 1575 байт
```

`python3 -I tools/convert/test_convert.py dials`:

```
dials.bin → раскладка BBC: совпало, 1792 байт
```

## Размеры файлов

- `v06c/data/dials.bin` — 3584 байта (плоскость 0: 1792, плоскость 1: 1792);
- `v06c/data/dials.png` — 1575 байт, 512x112, 8-bit/color RGB, non-interlaced
  (проверено `file`).

## Доказано

- Обратная сборка цветов из `dials.bin` тестом `test_convert.py dials` даёт
  побайтовое совпадение с `orig/bbc/cassette/1-source-files/images/P.DIALS.bin`
  («совпало, 1792 байт»), включая проверку одинакового цвета у парных точек
  двойной ширины.
- PNG записан через `zlib` и `struct`, без сторонних библиотек.
