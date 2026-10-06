#!/usr/bin/env python3
"""Черновой бюджет профиля «Классика» по размерам из work/lst_sizes.txt.
Запуск: python3 -I tools/analysis/budget.py work/lst_sizes.txt [коэф. Z80->8080, по умолчанию 1.30]
Доля «оставить» для частично режущихся файлов — оценка архитектора (KEEP_PART), уточняется на этапе E1.
"""
import re, sys
K = float(sys.argv[2]) if len(sys.argv) > 2 else 1.30
rows = []
for ln in open(sys.argv[1], encoding='utf-8'):
    m = re.match(r'\s*(\d+)\s+код\s+(\d+)\s+(.+)$', ln)
    if m: rows.append((m.group(3).strip(), int(m.group(1)), int(m.group(2))))
CUT_MODELS = {'Alloys2', 'Alloys3', 'Alloys4', 'Cargo2', 'Cargo3', 'Cargo4', 'AsteroidBig', 'Ring', 'MilitarySt',
              'MilitarySt2', 'Targon6', 'Fighter1', 'Fighter2', 'FuelSt', 'ShipGen', 'NewSt', 'AsteroidSt', 'Drone',
              'Portal', 'TargonInt', 'TargonSpy', 'Platform'}
CUT = ['DemoMode', 'DemoLogo', 'Delivery', 'genContracts', 'BuyShips', 'SaveLoad', 'DrvFdd', 'LibSFX', 'Debug',
       'Pilot.var.a80', 'eObjSetRndShip', 'dzx0_turbo', 'RAMpage', 'PauseInGameMsg']
KEEP_PART = {'MissionsMsg.a80': 0.40, 'Missions.a80': 0.50, 'eMissions.a80': 0.50, 'eMissionsLow.a80': 0.50,
             'InfoShips.a80': 0.10, 'EquipShip.a80': 0.70, 'EquipShipMsg.a80': 0.50, 'priceEquip.a80': 0.50,
             'DevicesRus.a80': 0.50, 'eObjMove.a80': 0.80, 'eObjMoveAI.a80': 0.70, 'eObjPilot.a80': 0.75,
             'eJumpLow.a80': 0.80, 'MsgDescPlanetRus.a80': 0.60, 'PauseInGame.a80': 0.60, 'DrvKey.asm.a80': 0.50}
g = {}
def add(k, total, code, keep):
    r = g.setdefault(k, [0, 0, 0, 0]); r[0] += total; r[1] += code; r[2] += total * keep; r[3] += code * keep
for f, total, code in rows:
    mm = re.match(r'd_(.+?)([DH])\.a80$', f)
    if mm:
        add('модели кораблей', total, 0, 0.0 if mm.group(1) in CUT_MODELS else 1.0); continue
    keep = 0.0 if any(c in f for c in CUT) else KEEP_PART.get(f, 1.0)
    if re.search(r'Msg|Rus\.a80|Eng\.a80|eTxt|Ships\.a80$', f): k = 'тексты'
    elif re.match(r'(e[A-Z]|cocp)', f): k = 'движок полёта (e*, cocp*)'
    elif f in ('PrintTxt.a80', 'ScanKeys.a80', 'Interrupts.a80', 'CalcAdrScr.a80', 'PrnOnScr.a80', 'ProcLow.a80',
               'PrnMessages.a80', 'InputText.a80', 'Sound.a80', 'InitGame.a80', 'DrvKey.asm.a80',
               'dzx0_turbo.a80', 'RAMpage.a80', 'main.a80') or 'LibSFX' in f or 'Drv' in f: k = 'общие и библиотеки'
    elif code == 0: k = 'таблицы и переменные'
    else: k = 'меню, карты, галактика, миссии'
    add(k, total, code, keep)
print(f'{"группа":34s} {"всего":>7s} {"код":>7s} | {"остаётся":>8s} {"код":>7s} {"на 8080":>8s}')
T = [0, 0, 0, 0, 0]
for k, (t, c, kt, kc) in sorted(g.items(), key=lambda x: -x[1][0]):
    n80 = kt - kc + kc * K
    print(f'{k:34s} {t:7d} {c:7d} | {kt:8.0f} {kc:7.0f} {n80:8.0f}')
    for i, v in enumerate((t, c, kt, kc, n80)): T[i] += v
print(f'{"ИТОГО по листингу":34s} {T[0]:7d} {T[1]:7d} | {T[2]:8.0f} {T[3]:7.0f} {T[4]:8.0f}   (коэф. кода {K})')
