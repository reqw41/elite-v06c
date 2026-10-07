; Заставка: тело цикла вращения корабля (TLL2 из TITLE кассетной версии BBC). Сама TITLE — в start.asm.

; Один проход цикла TLL2: приблизить корабль, сдвинуть и повернуть, напечатать. Сверка с эталоном — t10.mjs.
title_pass:
	ld	a, (INWK + 7)
	cp	1
	jp	z, tl1
	dec	a
	ld	(INWK + 7), a
tl1:
	call	MVEIT
	ld	a, 128
	ld	(INWK + 6), a
	xor	a
	ld	(INWK), a
	ld	(INWK + 3), a
	call	LL9
	ld	hl, MCNT
	dec	(hl)
	ret
