; pc_pt: точка HL с маской A, если она в обзоре. Портит A, E.
pc_pt:
	ld	e, a
	ld	a, h
	sub	high SCR_VIEW
	cp	32
	ret	nc
	ld	a, l
	cp	64
	ret	c
	ld	a, e
	xor	(hl)
	ld	(hl), a
	ret
