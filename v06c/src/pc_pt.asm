; pc_pt: точка HL с маской A, если она в обзоре. Портит A, E.
pc_pt:
	ld	e, a
	ld	a, h
	sub	high SCR_VIEW
	cp	32
	ret	nc
	ld	a, l
	ifdef	ORAND
	inc	a			; строка 0 — рамка, не трогать
	cp	65
	else
	cp	64
	endif
	ret	c
	ld	a, e
pc_px:	xor	(hl)
	ifdef	ORAND
	nop				; как места x1..x8 первого набора (pa_or, pa_and)
	endif
	ld	(hl), a
	ret
