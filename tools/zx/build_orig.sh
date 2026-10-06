#!/bin/sh
# Сборка ZX-оригинала Elite Legend 1.09 на Маке (sjasmplus 1.24 вместо авторского 1.07 RC7).
# Берёт orig/EliteLegend_v1_09_source, кладёт копию в work/zxbuild, правит три места, несовместимые
# с новым sjasmplus, и собирает. Результат: work/zxbuild/!bin/*.bin, eliterus.sna, листинг !log/log.txt.
set -e
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
SRC="$ROOT/orig/EliteLegend_v1_09_source"
OUT="$ROOT/work/zxbuild"
export LC_ALL=C
rm -rf "$OUT"; mkdir -p "$ROOT/work"; cp -R "$SRC" "$OUT"; cd "$OUT"; mkdir -p '!bin' '!log'
# 1. Новый sjasmplus подставляет DEFINE внутрь имён по «_»: TrDos_3D13 превращался в _3D13.
grep -rla 'TrDos_3D13' . | while read -r f; do sed -i '' 's/TrDos_3D13/TrDosCall3D13/g' "$f"; done
# 2. Перенос строки комментария без «;» в GS.mac, строка 25.
sed -i '' '25s/^/;/' INCLUDE/GS.mac
# 3. DUP внутри IFDEF/ELSE в PauseInGame.a80: число повторов выносим в константу.
python3 -I - <<'PY'
p = 'INCLUDE/Menu/PauseInGame.a80'
L = open(p, 'rb').read().split(b'\r\n')
assert L[237].strip() == b'IFDEF\tRussian' and L[238].strip() == b'DUP\t12', L[237:243]
L[237:242] = [b'\tDUP\tPauseDupN']
L.insert(0, b'\tIFDEF\tRussian\r\nPauseDupN\tequ 12\r\n\tELSE\r\nPauseDupN\tequ 10\r\n\tENDIF')
open(p, 'wb').write(b'\r\n'.join(L))
PY
"$ROOT/tools/bin/sjasmplus" --lst='!log/log.txt' --msg=war Elite.a80 > '!log/build.txt' 2>&1 || { tail -20 '!log/build.txt'; exit 1; }
if grep -a -q 'error' '!log/build.txt'; then grep -a 'error' '!log/build.txt' | head; exit 1; fi
cd "$ROOT"
python3 -I tools/analysis/lst_sizes.py 'work/zxbuild/!log/log.txt' > work/lst_sizes.txt
ls -l 'work/zxbuild/!bin' | awk 'NR>1{print $5, $9}'
