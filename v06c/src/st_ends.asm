; Штрихи пыли при прыжке (обычный образ, вид вперёд), часть в пустоте выравнивания перед keys.asm (elite.asm).
; st_off: в начале STARS1, пока пылинки на прежних местах, — стереть точки следа (HL -> st_fx <> 0).
st_off:
	ld	(hl), 0
	ld	a, LM_AND		; стереть очисткой
	jp	st_dots
; st_end: в конце STARS1 — после прыжка (st_j <> 0, ставит wa_zx) нарисовать след и отметить, что он на экране.
st_end:
	ld	hl, st_j
	ld	a, (hl)
	or	a
	ret	z
	dec	(hl)
	inc	hl			; st_fx — следом за st_j
	ld	(hl), 1
	ld	a, LM_OR		; нарисовать наложением
	jp	st_dots
