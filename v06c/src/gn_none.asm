; gn_all, gn_none (market.asm): напечатать знак A; R = всё, что можно (QQ25), или 0 — ничего.
gn_all:
	call	TT26
	ld	a, (QQ25)
	ld	(R_), a
	or	a
	ret
gn_none:
	call	TT26
	xor	a
	ld	(R_), a
	ret
