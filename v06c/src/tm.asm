; Стирание надписи в обзоре повторной печатью (обычный образ): корабли и пыль рисуются наложением и стираются
; очисткой, поэтому и знак стирается очисткой (tm_and), иначе там, где по нему прошёл корабль, исключающее ИЛИ
; зажгло бы точки. tm_xor — обычная печать. Портят DE, HL; A и флаги не трогают. mes9e — mes9 очисткой.
; Лежит в пустоте выравнивания (flight.asm).
; mes9e, messe, ee3e — mes9, MESS, ee3 очисткой.
ee3e:
	call	tm_and
	call	ee3
	jp	tm_xor
messe:
	call	tm_and
	call	MESS
	jp	tm_xor
mes9e:
	call	tm_and
	call	mes9
	jp	tm_xor
tm_and:
	ld	hl, 0xAEA6		; and (hl); xor (hl)
	db	0x11			; ld de, nn: съедает «ld hl» и младший байт; старший (00h) — nop
tm_xor:
	ld	hl, 0x00AE		; xor (hl); nop
	ld	(tt_x), hl
	ret
