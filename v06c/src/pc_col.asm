; pc_col: HL = x (со знаком) -> D = старший байт адреса столбца, A = маска точки. Портит E, HL.
pc_col:
	ld	a, l
	and	7
	add	a, low TWOS
	ld	e, a
	ld	d, high TWOS
	ld	a, (de)
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	ld	e, a
	ld	a, h
	add	a, high SCR_VIEW
	ld	d, a
	ld	a, e
	ret
