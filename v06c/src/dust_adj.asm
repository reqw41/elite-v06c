; dust_adj: число пылинок по нагрузке — 18 без объектов рядом, на 2 меньше за каждый объект (корабль, мусор),
; не меньше 10. В подпространстве число задаёт игра. Пылинки между прежним и новым числом переключаются на экране
; (рисуются исключающим ИЛИ): лишние стираются, вернувшиеся появляются на прежних местах.
dust_adj:
	ld	a, (MJ)
	or	a
	ret	nz
	ld	hl, FRIN + 2
	ld	d, NOST
da_1:
	ld	a, (hl)
	or	a
	jp	z, da_2
	inc	hl
	dec	d
	dec	d
	ld	a, d
	cp	10
	jp	nz, da_1
da_2:
	ld	a, (NOSTM)
	cp	d
	ret	z
	ld	b, a			; B — большее из двух чисел, E — меньшее
	ld	e, d
	jp	nc, da_3
	ld	b, d
	ld	e, a
	ifndef	DBUF
	ld	a, 1			; выросло — вернувшиеся нарисовать
	jp	da_4
	endif
da_3:
	ifndef	DBUF
	ld	a, 2			; уменьшилось — лишние стереть
da_4:
	ld	(da_md), a
	endif
	ld	a, d
	ld	(NOSTM), a
da_l:
	push	bc
	push	de
	ld	c, b
	call	st_xyz
	ifndef	DBUF
	ld	a, (da_md)
	ld	(px_md), a
	endif
	call	PIXEL2
	pop	de
	pop	bc
	dec	b
	ld	a, b
	cp	e
	jp	nz, da_l
	ret
