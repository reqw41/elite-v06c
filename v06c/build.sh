#!/bin/sh
# Сборка v06c/build/elite.rom (i8080, старт 0100h). Ассемблер: tools/bin/sjasmplus, режим --i8080.
# sh v06c/build.sh [-DИМЯ ...] — например -DVIEW_YELLOW (обзор жёлтый), -DSCHED (кадры считает стенд).
set -e
cd "$(dirname "$0")/.."
ROOT=$(pwd)
mkdir -p v06c/build
out=$("$ROOT/tools/bin/sjasmplus" --i8080 --fullpath -i v06c/src -i v06c/data "$@" \
	--lst=v06c/build/elite.lst --sym=v06c/build/elite.sym v06c/src/elite.asm 2>&1) || {
	echo "$out"
	echo "СБОРКА ПРОВАЛЕНА"
	exit 1
}
if echo "$out" | grep -Eiq 'warning:|warnings: [1-9]'; then
	echo "$out"
	echo "ЕСТЬ ПРЕДУПРЕЖДЕНИЯ sjasmplus — провал"
	exit 1
fi
python3 -I tools/check_i8080.py v06c/build/elite.lst
sz=$(wc -c < v06c/build/elite.rom | tr -d ' ')
echo "OK: v06c/build/elite.rom ($sz Б, до рабочих областей B000h свободно $((0xB000 - 0x100 - sz)))"
