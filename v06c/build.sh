#!/bin/sh
# Сборка v06c/build/elite.rom (i8080, старт 0100h). Ассемблер: tools/bin/sjasmplus, режим --i8080.
# sh v06c/build.sh [-DИМЯ ...] — например -DVIEW_YELLOW (обзор жёлтый), -DSCHED (кадры считает стенд).
# -DMERID — планета с меридианами и кратером, как на BBC (по умолчанию — окружность), пишется в elite_merid.rom.
# -DRUS — русская сборка, пишется в elite_ru.rom.
# -DSCENE — тестовая сцена (пауза + M: солнце и четыре врага), без мелодии; пишется в elite_sun.rom.
# -DDBUF — чёрно-белая с двойным буфером (v06c/src/db.asm), пишется в elite_db.rom.
# -DSCHED — сборка для стенда, пишется в v06c/build/elite_t.rom.
# Отладка на железе (вместе с -DSCENE): -DPASSCNT — счётчик проходов точками в левом верхнем углу обзора,
# -DAUTO — клавиши до сцены сами (N, пробел, F1, СТР, M, ЗБ по расписанию, auto_t в mainflight.asm).
set -e
cd "$(dirname "$0")/.."
ROOT=$(pwd)
mkdir -p v06c/build
NAME=elite
for a in "$@"; do [ "$a" = "-DMERID" ] && NAME=${NAME}_merid; [ "$a" = "-DRUS" ] && NAME=${NAME}_ru; [ "$a" = "-DDBUF" ] && NAME=${NAME}_db; [ "$a" = "-DSCENE" ] && NAME=${NAME}_sun; done
for a in "$@"; do [ "$a" = "-DSCHED" ] && NAME=${NAME}_t; done
out=$("$ROOT/tools/bin/sjasmplus" --i8080 --fullpath -i v06c/src -i v06c/data "$@" \
	--lst=v06c/build/$NAME.lst --sym=v06c/build/$NAME.sym v06c/src/elite.asm 2>&1) || {
	echo "$out"
	echo "СБОРКА ПРОВАЛЕНА"
	exit 1
}
if echo "$out" | grep -Eiq 'warning:|warnings: [1-9]'; then
	echo "$out"
	echo "ЕСТЬ ПРЕДУПРЕЖДЕНИЯ sjasmplus — провал"
	exit 1
fi
python3 -I tools/check_i8080.py v06c/build/$NAME.lst
sz=$(wc -c < v06c/build/$NAME.rom | tr -d ' ')
# размер игры в памяти — по метке rom_end: файл обычного образа длиннее на заставку с Сатурном, которая лежит
# в рабочих областях и после показа обнуляется
end=$(sed -n 's/^rom_end: *EQU *0x0*\([0-9A-Fa-f]*\).*/\1/p' v06c/build/$NAME.sym)
game=$((0x$end - 0x100))
lim=B000; lname="рабочих областей B000h"
dt=$(sed -n 's/^divtab: *EQU *0x0*\([0-9A-Fa-f]*\).*/\1/p' v06c/build/$NAME.sym)
[ $((0x$dt)) -ge $((0x$end)) ] && { lim=$dt; lname="таблицы наклонов ${dt}h"; }
echo "OK: v06c/build/$NAME.rom (игра $game Б, файл $sz Б, до $lname свободно $((0x$lim - 0x$end)))"
