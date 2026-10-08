; Нужно один раз, при запуске: в обычном образе лежит в рабочих областях (см. elite.asm), в образе стенда — в игре.
; Построить таблицу четвертей квадратов: f(x + 1) = f(x) + (x + 1) / 2 нацело, x = 0..511.
sq_init:
	ld	hl, 0
	ld	de, SQLO
	ld	b, h
	ld	c, l
sq_lp:
	ld	a, l
	ld	(de), a
	inc	d
	inc	d
	ld	a, h
	ld	(de), a
	dec	d
	dec	d
	inc	de
	inc	bc
	push	bc
	ld	a, b
	or	a
	rra
	ld	b, a
	ld	a, c
	rra
	ld	c, a
	add	hl, bc
	pop	bc
	ld	a, b
	cp	2
	jp	nz, sq_lp
	ret
