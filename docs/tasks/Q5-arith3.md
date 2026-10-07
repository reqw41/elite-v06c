# Q5. Арифметика, третья партия: пять процедур 6502 → i8080

Менять можно только `v06c/src/arith3.asm`. Создать — `docs/tasks/Q5-report.md`. Больше ничего не трогать
(файл `arith3.asm` в сборку уже включён).

## Сначала прочитать

1. `docs/spec/porting.md` — правила переноса и ловушки.
2. `v06c/src/arith.asm` и `v06c/src/arith2.asm` — образцы. `LL28` уже перенесена — её надо вызывать.

Регистры: A = A, X → B, Y → C, перенос = перенос. Сравнивается всё: A, X, Y, перенос, вся нулевая страница.
Ячейки `P` и `R` на Векторе зовутся `P_` и `R_`. `XX12+2` — это `XX12 + 2`.

Дополнительные ловушки этой партии:

- `PHA … PLA` на 6502 сохраняет только A. `push af … pop af` на i8080 возвращает и флаги — перенос после `pop af`
  станет старым. Если после `PLA` на BBC перенос важен (он попадает на выход), сохраняйте A в регистре
  (`ld d, a … ld a, d`), а не в стеке.
- `TAY`, `TAX`, `LDX`, `LDY` меняют X и Y — значит, на выходе B и C должны быть такими же, как X и Y на BBC.
- `ASL ячейка`, `LSR ячейка`, `ROL ячейка` — через A: `ld a, (яч)` / сдвиг / `ld (яч), a`; перенос из сдвига
  должен дожить до следующей команды (`ld` флаги не меняет).
- `BMI`/`BPL` после `LDA`, `ROL` и т. п. смотрят на бит 7 результата. На i8080 `ld` флаги не ставит: перед
  `jp m` / `jp p` нужен `or a` (он сбрасывает перенос!) или проверка другим способом (`add a, a` / `rla` и
  `jp c`, если значение потом не нужно).

## Что перенести (текст BBC)

```
.LL38                   \ (S A) = (S R) + (A Q), знак — в бите 7 у S и у A
 EOR S
 BMI LL39
 LDA Q
 CLC
 ADC R
 RTS
.LL39
 LDA R
 SEC
 SBC Q
 BCC P%+4               \ P%+4 — через две команды: на PHA
 CLC
 RTS
 PHA
 LDA S
 EOR #%10000000
 STA S
 PLA
 EOR #%11111111
 ADC #1
 RTS

.TIS2                   \ A = A * 96 / Q
 TAY
 AND #%01111111
 CMP Q
 BCS TI4
 LDX #%11111110
 STX T
.TIL2
 ASL A
 CMP Q
 BCC P%+4               \ через одну команду: на ROL T
 SBC Q
 ROL T
 BCS TIL2
 LDA T
 LSR A
 LSR A
 STA T
 LSR A
 ADC T
 STA T
 TYA
 AND #%10000000
 ORA T
 RTS
.TI4
 TYA
 AND #%10000000
 ORA #96
 RTS

.DVIDT                  \ (P+1 A) = (A P) / Q
 STA P+1
 EOR Q
 AND #%10000000
 STA T
 LDA #0
 LDX #16
 ASL P
 ROL P+1
 ASL Q
 LSR Q
.DVL2
 ROL A
 CMP Q
 BCC P%+4               \ через одну команду: на ROL P
 SBC Q
 ROL P
 ROL P+1
 DEX
 BNE DVL2
 LDA P
 ORA T
 RTS

.LL129
 LDX XX12+2
 STX Q
 LDA S
 BPL LL127
 LDA #0
 SEC
 SBC R
 STA R
 LDA S
 PHA
 EOR #%11111111
 ADC #0
 STA S
 PLA
.LL127
 EOR XX12+3
 RTS

.LL61                   \ (U R) = 256 * A / Q
 LDX Q
 BEQ LL84
 LDX #0
.LL63
 LSR A
 INX
 CMP Q
 BCS LL63
 STX S
 JSR LL28
 LDX S
 LDA R
.LL64
 ASL A
 ROL U
 BMI LL84
 DEX
 BNE LL64
 STA R
 RTS
.LL84
 LDA #50
 STA R
 STA U
 RTS
```

Подсказки.

- `TIS2`, цикл `TIL2`, и `DVIDT`, цикл `DVL2`: тот же приём, что в `DVID96` из Q4 — в `ROL` должен попасть
  перенос 6502 (1, если вычитали; 0, если нет), а после `cp` на i8080 он перевёрнут. В `DVIDT` перенос после
  `ROL P+1` идёт в `ROL A` следующего шага.
- В `TIS2` после `LSR A : LSR A : STA T : LSR A : ADC T` в сложение идёт перенос от последнего сдвига.
- `LL38`: на пути `LL39` при `BCC` не взятом — `CLC : RTS`; при взятом перенос на входе в `ADC #1` равен 0.

## Проверка (сейчас красная, должна стать зелёной)

```sh
sh v06c/build.sh && node v06c/test/q5.mjs
```

Нужно: `Z80-only 0`, пять строк `OK` и `Q5: всё совпало`. Прежние тесты не должны сломаться:
`node v06c/test/t06.mjs 500` и `node v06c/test/q4.mjs 500`.

## Отчёт

`docs/tasks/Q5-report.md`: вывод команд целиком. Коммитов не делать.
