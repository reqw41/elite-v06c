; Планета без мерцания, часть 2 (ws_brk). В обычном образе — в нижней памяти (0007h).
ws_brk:					; разрыв: следующая запись — начало нового куска
	inc	c
	ld	hl, wp_sx
	add	hl, bc
	ld	a, (hl)
	ld	(wp_x1), a
	ld	hl, wp_sy
	add	hl, bc
	ld	a, (hl)
	ld	(wp_x1 + 1), a
	inc	c
	ld	a, c
	ld	(wp_i), a
	ld	a, (wp_touch)
	or	a
	jp	nz, ws_l
	ld	hl, (wp_x1)
	ld	(X1), hl
	jp	ws_l
