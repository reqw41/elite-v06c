; pc_pt: точка HL с маской A, если она в обзоре (в паре окружностей — и на pc_k строк дальше). Портит A, E.
pc_pt:
	ld	e, a
	ld	a, h
	sub	high SCR_VIEW
	cp	32
	ret	nc
	ld	a, l
	cp	64
	jp	c, pc_g0
	ld	a, e
	xor	(hl)
	ld	(hl), a
pc_g0:
	ret				; pc_two: ld b,b — точка и на pc_k строк дальше
	ld	a, l
	add	a, 0			; pc_k
	ld	l, a
	cp	64
	ret	c
	ld	a, e
	xor	(hl)
	ld	(hl), a
	ret
