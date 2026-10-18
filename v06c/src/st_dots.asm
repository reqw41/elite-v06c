; st_dots: след прыжка (как штрихи пыли на ZX 48K) — у каждой пылинки отрезок по её лучу от центра до 3/4
; расстояния; исключающим ИЛИ (LOIN): второй вызов с теми же SX, SY стирает. Только вид вперёд (STARS1).
st_dots:
	ld	a, (NOSTM)
	ld	c, a
	ld	b, 0
sd_l:
	ld	hl, SY
	add	hl, bc
	ld	a, (hl)
	ld	d, a
	and	0x7F
	cp	96
	jp	nc, sd_n		; за краем обзора (как в PIXEL2)
	ld	a, d
	call	st_cy
	ld	(Y1), a
	ld	a, d
	call	st_qy
	ld	(Y2), a
	ld	hl, SX
	add	hl, bc
	ld	a, (hl)
	ld	d, a
	call	st_cx
	ld	(X1), a
	ld	a, d
	call	st_qx
	ld	(X2), a
	call	LOIN			; сохраняет BC
sd_n:
	dec	c
	jp	nz, sd_l
	ret
