; Нужно один раз, при запуске: в обычном образе лежит в рабочих областях (см. elite.asm), в образе стенда — в игре.
; div_init: построить таблицу наклонов коротких отрезков: divtab[d · 32 + n] = 256 · n / d нацело для n < d < 32,
; 255 при n = d, прочее — 0 (то же, что давал tools/convert/divtab.py; сверка — v06c/test/t05.mjs).
div_init:
	ld	hl, divtab
	ld	bc, 0x0400
di_z:
	ld	(hl), 0
	inc	hl
	dec	bc
	ld	a, b
	or	c
	jp	nz, di_z
	ld	d, 1
di_d:
	ld	a, d
	rrca
	rrca
	rrca
	ld	l, a
	and	0x03
	add	a, high divtab
	ld	h, a
	ld	a, l
	and	0xE0
	ld	l, a
	ld	a, 255			; E = 256 / d нацело, T = остаток (через 255 / d: всё в байте)
	ld	e, 0xFF
di_q:
	inc	e
	sub	d
	jp	nc, di_q
	add	a, d
	inc	a
	cp	d
	jp	nz, di_r
	xor	a
	inc	e
di_r:
	ld	(T), a
	ld	bc, 0			; B — частное 256 · n / d, C — остаток
di_n:
	ld	(hl), b
	ld	a, b
	add	a, e
	ld	b, a
	ld	a, (T)
	add	a, c
	cp	d
	jp	c, di_k
	sub	d
	inc	b
di_k:
	ld	c, a
	inc	l
	ld	a, l
	and	0x1F
	cp	d
	jp	nz, di_n
	ld	(hl), 255
	inc	d
	ld	a, d
	cp	32
	jp	nz, di_d
	ret
