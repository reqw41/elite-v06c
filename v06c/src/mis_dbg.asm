; Отладочный вход (на паузе): M — выдать очередную миссию версии ZX при следующем прибытии, где бы мы ни были;
; K — добавить 256 побед (условие миссий дисковой версии). Гудок и короткая задержка. A сохраняется.
mis_dbg_m:
	ld	hl, MISF
	ld	a, (hl)
	or	0x80
	ld	(hl), a
	jp	mis_dbg
mis_dbg_k:
	ld	hl, MISF		; условие «Планов таргоидов»: «Сверхновая» уже выдавалась
	ld	a, (hl)
	or	1
	ld	(hl), a
	ld	hl, TALLY + 1
	inc	(hl)
mis_dbg:
	push	bc
	ld	a, 7
	call	TT26
	ld	c, 25
	call	DELAY
	pop	bc
	ld	a, b
	ret
