; fk_bit: A = строка · 8 + 7 − бит -> HL = kb_rows + строка, C = маска бита (из TWOS). Портит A.
fk_bit:
	ld	h, a
	and	7
	add	a, low TWOS
	ld	l, a
	ld	a, h
	ld	h, high TWOS
	ld	c, (hl)
	rrca
	rrca
	rrca
	and	7
	ld	l, a			; low kb_rows = 0
	ld	h, high kb_rows
	ret
