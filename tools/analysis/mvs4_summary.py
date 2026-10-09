#!/usr/bin/env python3
"""T71: размеры и прирост скорости из .sym и логов prof.mjs, без повторного прогона.
python3 -I tools/analysis/mvs4_summary.py [каталог логов = work/T71]
Снимок прежних elite.rom/.sym хранится в подкаталоге before (до изменения move.asm).
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
LOGS = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'work/T71'


def symbols(file):
    return {m[1]: int(m[2], 16) for line in file.read_text().splitlines()
            if (m := re.match(r'(\S+):\s+EQU\s+0x([0-9A-Fa-f]+)', line))}


for name, file in [('до', LOGS / 'before/elite.sym'),
                   ('после', ROOT / 'v06c/build/elite.sym')]:
    s = symbols(file)
    print(f'{name}: MVS4 {s["MVS5"] - s["MVS4"]} Б, '
          f'игра {s["rom_end"] - 256} Б, свободно {s["divtab"] - s["rom_end"]} Б')

for scene in ['fight', 'roll']:
    nums = []
    for state in ['before', 'after']:
        data = (LOGS / f'{scene}-{state}.log').read_text()
        m = re.search(r'проходов (\d+) \(([\d.]+) в секунду\)', data)
        if not m:
            raise ValueError(f'нет результата профиля: {scene}-{state}.log')
        nums.append(int(m[1]))
    print(f'{scene}: проходов {nums[0]} → {nums[1]}, '
          f'прирост скорости {(nums[1] / nums[0] - 1) * 100:.2f}%')
