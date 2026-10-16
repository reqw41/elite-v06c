#!/usr/bin/env python3
"""Мелодия заставки — главная тема вальса «На прекрасном голубом Дунае» (И. Штраус), три голоса → v06c/data/danube.asm.

Ноты — запись Elite для Commodore 64 (C.COMUDAT из orig/c64, проигрыватель BDirqhere; разбор — decode() ниже):
кадры 1163…3203 записи (главная тема после вступления), все три голоса SID как есть, без тембров: голос 1 — бас
и «умпа-па», голос 2 — гармония, голос 3 — мелодия. ВИ53 по нашей таблице делителей (snd_div) не берёт ниже си
большой октавы — такие ноты баса подняты на октаву. Решение владельца 17.10.2026: «Дунай» на заставке, многоголосо.

Поток: заголовок — биты 0–2: какие голоса берут новую ноту (1 — голос C64 1 → snd_v0, 2 — голос 2 → snd_v1,
4 — голос 3 → snd_v2), биты 3–6: номер задержки до следующего заголовка в mus_len (кадров); за ним по байту на
каждую новую ноту (по порядку голосов) — высота BBC (53 — до первой октавы, 4 на полутон). 0 — конец, дальше с начала.
Запуск из корня проекта: python3 -I tools/convert/danube.py"""
import math
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
ORIG = os.environ.get('ELITE_ORIG', os.path.join(ROOT, 'orig'))
DATA = os.path.join(ORIG, 'c64/1-source-files/music/gma/C.COMUDAT.bin')
T0, T1 = 1163, 1163 + 2000                     # главная тема (после вступления) до заключительного аккорда D;
END_PAUSE = 42                                 # с кадра 2008 начинается следующая фраза — её не берём (владелец: «подрезать»)
ARGS = {1: 2, 2: 2, 3: 2, 4: 4, 5: 6, 7: 6, 10: 6, 12: 1, 13: 3, 14: 3}


def decode(d):
    """Музыка C64 → события (кадр, голос 0–2, частота SID). Команды — как в BDirqhere (elite-source.asm C64)."""
    pos, buff, counter, value4, frame, ev = -1, 0, 0, 0, 0, []

    def nxt():
        nonlocal pos
        pos += 1
        return d[pos]
    while True:
        if counter:
            counter -= 1
            frame += 1
            continue
        while True:
            if buff < 0x10:
                if buff == 0:
                    buff = nxt()
                    continue
                x = buff
            else:
                x = buff & 15
            buff >>= 4
            if x in (1, 2, 3, 4, 5):
                vs = {1: [0], 2: [1], 3: [2], 4: [0, 1], 5: [0, 1, 2]}[x]
                fs = [(v, nxt() * 256 + nxt()) for v in vs]
                ev += [(frame, v, f) for v, f in fs]
            elif x == 12:
                value4 = nxt()
            elif x in ARGS:
                for _ in range(ARGS[x]):
                    nxt()
            elif x in (8, 15):
                if x == 15:
                    buff = (buff << 4) | 8
                counter = value4 - 1 if value4 else 0
                frame += 1
                break
            elif x in (9, 11):
                return ev


def main():
    ev = decode(open(DATA, 'rb').read())
    midi = lambda f: round(12 * math.log2(f * 985248 / 16777216 / 440) + 69)
    notes = {}
    for t, v, f in ev:
        if T0 <= t < T1:
            m = midi(f)
            while m < 47:                       # ниже си большой октавы ВИ53 по snd_div не возьмёт — октавой выше
                m += 12
            notes.setdefault(t - T0, {})[v] = 53 + 4 * (m - 60)
    times = sorted(notes)
    delays = [b - a for a, b in zip(times, times[1:])] + [T1 - T0 - times[-1] + END_PAUSE]
    lens = sorted(set(delays))
    assert len(lens) <= 16, lens
    out = []
    for t, dl in zip(times, delays):
        mask = sum(1 << v for v in notes[t])
        out.append(mask | (lens.index(dl) << 3))
        out += [notes[t][v] for v in sorted(notes[t])]
    lines = ['; создано tools/convert/danube.py, руками не править',
             'mus_len:\tdb ' + ', '.join(map(str, lens)), 'mus_dat:']
    lines += ['\tdb ' + ', '.join('%d' % b for b in out[i:i + 16]) for i in range(0, len(out), 16)]
    lines.append('\tdb 0')
    open(os.path.join(ROOT, 'v06c/data/danube.asm'), 'w').write('\n'.join(lines) + '\n')
    print('v06c/data/danube.asm: моментов %d, нот %d, задержек %d, %d Б, %.1f с' % (
        len(times), sum(len(n) for n in notes.values()), len(lens), len(out) + 1 + len(lens), sum(delays) / 50))


if __name__ == '__main__':
    main()
