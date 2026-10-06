# elite-v06c

Elite для Вектора-06Ц: ванильная машина (48 КБ + две плоскости), i8080, экран 4 цвета, звук ВИ53.
Основа — кассетная версия для BBC Micro (1984); Elite Legend (ZX128) — донор текстов, моделей и миссий.

- План: `docs/PORT_PLAN.md`
- Правила для исполнителей: `docs/CONTRACTS.md`
- Доска задач: `docs/tasks/README.md`

## Каталоги

| путь | что |
|---|---|
| `orig/bbc/` | исходники BBC Elite: кассета, диск, 6502SP (в git не входят; github.com/markmoxon) |
| `orig/EliteLegend_v1_09_source/` | исходники Elite Legend (в git не входят) |
| `docs/research/` | сравнение версий, архив плана по Legend |
| `tools/bin/` | sjasmplus 1.24, salvador |
| `tools/zx/build_orig.sh` | сборка оригинала на Маке → `work/zxbuild/!bin/` |
| `tools/analysis/` | размеры по файлам (`lst_sizes.py`), черновой бюджет (`budget.py`) |
| `work/` | временное, в git не входит |

## Сборка Elite Legend (донор)

```sh
sh tools/zx/build_orig.sh
python3 -I tools/analysis/budget.py work/lst_sizes.txt 1.30
```
