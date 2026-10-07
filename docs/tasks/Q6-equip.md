# Q6. Оборудование: `EQSHP`, `eq`, `prx`, `qv` — 6502 → i8080

Менять можно только `v06c/src/equip.asm`. Создать — `docs/tasks/Q6-report.md`. Больше ничего не трогать: ни тесты,
ни сценарий, ни другие исходники (файл в сборку уже включён, таблица цен `PRXS` в нём уже есть).

## Сначала прочитать

1. `docs/spec/porting.md` — правила переноса и ловушки.
2. `v06c/src/market.asm` — образец: `TT219` (покупка товара) устроена так же, как `EQSHP`; там же готовые `gnum`,
   `prq`, `dn`, `dn2`, `LCASH`, `MCASH`, `TT217`. Заголовки процедур говорят, что на входе и выходе.

Регистры: A = A, X → B, Y → C, перенос = перенос. Ячейки `P`, `R` на Векторе зовутся `P_`, `R_`; остальные — как на
BBC (`v06c/src/bbc_vars.inc`). Константа `POW` = 15. Мнемоника — Z80 в пределах i8080, сборку проверяет
`tools/check_i8080.py` (нет `jr`, `djnz`, `ldir`, `neg`, команд `CB`/`ED`).

Все вызываемые процедуры уже есть: `DIALS`, `TT66`, `spc`, `NLIN3`, `TT67`, `pr2`, `TT162`, `TT27`, `TT11`, `CLYNS`,
`prq`, `gnum`, `LCASH`, `MCASH`, `msblob`, `dn`, `dn2`, `TT217`, `BAY`. Метки `dn`, `dn2` и `c` из текста ниже заново
не заводить: `dn` и `dn2` лежат в `market.asm`, а `c` — просто `ret`.

## Ловушки этой задачи

- **Перенос при вычитании обратный.** `gnum` на Векторе уже возвращает перенос как на BBC (1 — слишком много).
  После `JSR gnum` на BBC стоит `BEQ bay : BCS bay : SBC #0` — к `SBC` перенос равен 0, значит вычитается единица:
  A = номер − 1. На i8080 `ld` флаги не ставит: проверку на ноль делать так, чтобы не потерять перенос (сначала
  `jp c, …`, потом `or a` / `jp z, …`, потом `dec a`).
- `LCASH` возвращает перенос 1, если денег хватило (как на BBC) — `BCS c` → `jp c, …`.
- `CMP #12 : BCC P%+4` — «если меньше 12, пропустить следующую команду». `cp 12` / `jp c, …`.
- `INC ячейка`, `DEC ячейка` → `ld hl, ячейка` / `inc (hl)` или `dec (hl)`.
- `LDY LASER,X : BEQ … : BMI …` — флаги по загруженному байту: на i8080 после загрузки нужен `or a`.
  X здесь — номер вида 0–3, он в регистре B: `ld hl, LASER` / `ld e, b` / `ld d, 0` / `add hl, de`.
- `PHA … PLA` вокруг `JSR eq` — сохранить номер предмета. `push af` / `pop af` годится: после `PLA` идёт `BNE`,
  которому нужен флаг Z по значению A, — после `pop af` поставьте `or a`.
- Сравнения `CMP #n : BNE` идут цепочкой, и между ними `INY`, `LDX` — следите, чтобы A (номер предмета) и
  C (номер слова для «Present») доживали до своих сравнений: вызовы `qv`, `prx`, `MCASH` их портят, как и на BBC,
  где после них A загружают заново (`LDA #4`, `LDA #5`).
- `JSR prx-3` — вход в `prx` на три байта раньше, с `SEC : SBC #1` (A = A − 1). Сделайте отдельную метку `prx_m1`:
  `dec a` и дальше `prx`. `prx`: (Y X) = цена предмета A, то есть C — старший байт, B — младший из `PRXS + 2·A`.
- `eq` при нехватке денег делает `JMP err`, не возвращаясь к вызвавшему: на стеке остаются адрес возврата и
  сохранённый A. На BBC это безопасно, потому что главный цикл `MLOOP`, куда ведёт `BAY`, ставит стек заново; на Векторе так же —
  повторять как есть.
- Печать цены: `SEC` перед `JSR TT11` — перенос 1 (с десятичной точкой): `scf` прямо перед `call TT11`, после
  загрузки A, B, C.
- Цена топлива: `(70 − QQ14) · 2` записывается в младший байт `PRXS` (`STA PRXS`).

## Что перенести (текст BBC, кассетная версия)

```
.EQSHP
 JSR DIALS
 LDA #32
 JSR TT66
 LDA #12
 STA XC
 LDA #207
 JSR spc
 LDA #185
 JSR NLIN3
 LDA #%10000000
 STA QQ17
 INC YC
 LDA tek
 CLC
 ADC #3
 CMP #12
 BCC P%+4
 LDA #12
 STA Q
 STA QQ25
 INC Q
 LDA #70
 SEC
 SBC QQ14
 ASL A
 STA PRXS
 LDX #1
.EQL1
 STX XX13
 JSR TT67
 LDX XX13
 CLC
 JSR pr2
 JSR TT162
 LDA XX13
 CLC
 ADC #104
 JSR TT27
 LDA XX13
 JSR prx-3
 SEC
 LDA #25
 STA XC
 LDA #6
 JSR TT11
 LDX XX13
 INX
 CPX Q
 BCC EQL1
 JSR CLYNS
 LDA #127
 JSR prq
 JSR gnum
 BEQ bay
 BCS bay
 SBC #0
 LDX #2
 STX XC
 INC YC
 PHA
 JSR eq
 PLA
 BNE et0
 STA MCNT
 LDX #70
 STX QQ14
.et0
 CMP #1
 BNE et1
 LDX NOMSL
 INX
 LDY #117
 CPX #5
 BCS pres
 STX NOMSL
 JSR msblob
.et1
 LDY #107
 CMP #2
 BNE et2
 LDX #37
 CPX CRGO
 BEQ pres
 STX CRGO
.et2
 CMP #3
 BNE et3
 INY
 LDX ECM
 BNE pres
 DEC ECM
.et3
 CMP #4
 BNE et4
 JSR qv
 LDA #4
 LDY LASER,X
 BEQ ed4
.ed7
 LDY #187
 BNE pres
.ed4
 LDA #POW
 STA LASER,X
 LDA #4
.et4
 CMP #5
 BNE et5
 JSR qv
 STX T1
 LDA #5
 LDY LASER,X
 BEQ ed5
 BMI ed7
 LDA #4
 JSR prx
 JSR MCASH
.ed5
 LDA #POW+128
 LDX T1
 STA LASER,X
.et5
 LDY #111
 CMP #6
 BNE et6
 LDX BST
 BEQ ed9
.pres
 STY K
 JSR prx
 JSR MCASH
 LDA K
 JSR spc
 LDA #31
 JSR TT27
.err
 JSR dn2
 JMP BAY
.ed9
 DEC BST
.et6
 INY
 CMP #7
 BNE et7
 LDX ESCP
 BNE pres
 DEC ESCP
.et7
 INY
 CMP #8
 BNE et8
 LDX BOMB
 BNE pres
 LDX #&7F
 STX BOMB
.et8
 INY
 CMP #9
 BNE etA
 LDX ENGY
 BNE pres
 INC ENGY
.etA
 INY
 CMP #10
 BNE etB
 LDX DKCMP
 BNE pres
 DEC DKCMP
.etB
 INY
 CMP #11
 BNE et9
 LDX GHYP
 BNE pres
 DEC GHYP
.et9
 JSR dn
 JMP EQSHP
.dn
 JSR TT162
 LDA #119
 JSR spc
.dn2
 JSR BEEP
 LDY #50
 JMP DELAY
.eq
 JSR prx
 JSR LCASH
 BCS c
 LDA #197
 JSR prq
 JMP err
 SEC
 SBC #1
.prx
 ASL A
 TAY
 LDX PRXS,Y
 LDA PRXS+1,Y
 TAY
.c
 RTS
.qv
 LDY #16
 STY YC
.qv1
 LDX #12
 STX XC
 TYA
 CLC
 ADC #'0'-16
 JSR spc
 LDA YC
 CLC
 ADC #80
 JSR TT27
 INC YC
 LDY YC
 CPY #20
 BCC qv1
.qv3
 JSR CLYNS
.qv2
 LDA #175
 JSR prq
 JSR TT217
```

## Проверка

```sh
sh v06c/build.sh -DSCHED && node v06c/test/t27.mjs equip | grep -v "%"
sh v06c/build.sh -DSCHED && node v06c/test/t27.mjs trade | tail -1     # не сломать соседей
```

Сейчас первая команда печатает `FAIL сценарий equip: 47 проходов …` и `ПРОВАЛ`. Готово — когда она печатает
`T27 (equip): всё совпало` (165 проходов), а вторая — `T27 (trade): всё совпало`. При расхождении тест называет
проход, ячейку или место на экране: шаги сценария с номерами видны в `tools/oracle/scenario.js` (`equip`).

Снимок экрана эталона после сценария: `node tools/oracle/scenario.js equip` → `work/oracle/scn-equip.png`.

## Отчёт

`docs/tasks/Q6-report.md`: что сделано, вывод обеих команд проверки дословно, размер `equip.asm` в байтах кода
(по листингу), что было трудно. Числа — только из вывода команд. Тест не проходит — так и написать, с выводом.
