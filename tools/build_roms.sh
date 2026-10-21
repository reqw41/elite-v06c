#!/bin/sh
# ГОТОВЫЕ ОБРАЗЫ В rom/ — одной командой: sh tools/build_roms.sh
#   rom/elite.rom          — цветная, английская (язык оригинала)
#   rom/elite-ru.rom       — цветная, русская (-DRUS)
#   rom/elite-merid.rom    — цветная, планета с меридианами и кратером, как на BBC (-DMERID)
#   rom/elite-bw.rom       — чёрно-белая с двойным буфером, английская (-DDBUF, ветка dbuf)
#   rom/elite-bw-ru.rom    — чёрно-белая, русская (-DDBUF -DRUS, ветка dbuf)
# Все грузятся с 0100h и короче 64 КБ (заставка с Сатурном внутри), поэтому годятся и для Вектора Турбо+
# из CP/M (ключ -V T3). Чёрно-белая живёт в ветке dbuf: она собирается из неё через git archive, рабочие
# каталоги не трогаются.
set -e
cd "$(dirname "$0")/.."
ROOT=$(pwd)
mkdir -p rom
sh v06c/build.sh >/dev/null && cp v06c/build/elite.rom rom/elite.rom
sh v06c/build.sh -DRUS >/dev/null && cp v06c/build/elite_ru.rom rom/elite-ru.rom
sh v06c/build.sh -DMERID >/dev/null && cp v06c/build/elite_merid.rom rom/elite-merid.rom
REF=dbuf
git rev-parse --verify -q "$REF" >/dev/null || REF=origin/dbuf
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
git archive "$REF" | tar -x -C "$T"
# -DDBUF -DRUS пишет тот же elite_db.rom, что и -DDBUF: русскую собираем первой и сразу забираем
(cd "$T" && sh v06c/build.sh -DDBUF -DRUS >/dev/null 2>&1) && cp "$T/v06c/build/elite_db.rom" rom/elite-bw-ru.rom
(cd "$T" && sh v06c/build.sh -DDBUF >/dev/null) && cp "$T/v06c/build/elite_db.rom" rom/elite-bw.rom
ls -l rom
