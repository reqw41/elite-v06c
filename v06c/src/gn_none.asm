; gn_none (market.asm): напечатать знак A, R = 0 — ничего не введено.
gn_none:
	call	TT26
	xor	a
	ld	(R_), a
	ret
