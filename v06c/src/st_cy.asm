; st_cy: координата y пыли -> строка экрана 96 − y; st_qy, st_qx — то же для 3/4 координаты (st_q).
st_cy:
	call	st_cv
	ld	e, a
	ld	a, 96
	sub	e
	ret
st_qy:
	call	st_q
	jp	st_cy
st_qx:
	call	st_q
	jp	st_cx
