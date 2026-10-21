; Пыль: число пылинок по нагрузке (dust_adj) и режимы точки (px_ent). Обычный образ; лежит за всеми выравниваниями.

; Пыль не портит линии кораблей. Всё рисуется исключающим ИЛИ, и пылинка, попавшая на линию, гасила её точку —
; у далёкого корабля из нескольких точек выходила каша. Теперь пылинка C рисуется (px2_d), только если её точка
; пуста, и признак DUSTF+C помнит, нарисована ли она; стирается (px2_e, PIX1, da_l) — только нарисованная. Каждая
; точка по-прежнему ставится парой (рисование — стирание), поэтому ничего не залипает.
px2_d:
	ld	a, 1
	ld	(px_md), a
	jp	PIXEL2
px2_e:
	ld	a, 2
	ld	(px_md), a
	jp	PIXEL2
; px_ent (вместо PIXEL в конце PIXEL2): B = x, A = y; C — номер пылинки. px_md: 0 — обычная точка; 1 — рисовать,
; если точка пуста (признак — нарисована ли); 2 — только если нарисована. Не рисовать — перенос, как у PIXEL.
px_ent:
	push	af			; y
	ld	a, (px_md)
	or	a
	jp	z, pe_go
	ld	e, a			; E — режим
	xor	a
	ld	(px_md), a
	ld	a, c
	add	a, low DUSTF
	ld	l, a
	ld	h, high DUSTF		; HL — признак пылинки
	ld	a, e
	cp	2
	jp	z, pe_e
	pop	af
	push	af
	push	hl
	cpl
	ld	l, a			; 255 - y
	ld	a, b
	rrca
	rrca
	rrca
	and	31
	ld	h, a
	ld	a, (col_p1 + 1)		; плоскость обзора (в чёрно-белой сборке — плоскость рисования)
	or	h
	ld	h, a
	ld	a, b
	and	7
	add	a, low TWOS
	ld	e, a
	ld	d, high TWOS
	ld	a, (de)
	and	(hl)			; точка уже горит (линия корабля)?
	pop	hl
	ld	(hl), 1
	jp	z, pe_go
	ld	(hl), 0
pe_no:
	pop	af
	ld	a, (ZZ)			; перенос — как у PIXEL: 1 при ZZ >= 80
	cp	80
	ccf
	ret
pe_e:
	ld	a, (hl)
	or	a
	jp	z, pe_no
pe_go:
	pop	af
	jp	PIXEL

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
	ld	a, 1			; выросло — вернувшиеся нарисовать
	jp	da_4
da_3:
	ld	a, 2			; уменьшилось — лишние стереть
da_4:
	ld	(da_md), a
	ld	a, d
	ld	(NOSTM), a
da_l:
	push	bc
	push	de
	ld	c, b
	call	st_xyz
	ld	a, (da_md)
	ld	(px_md), a
	call	PIXEL2
	pop	de
	pop	bc
	dec	b
	ld	a, b
	cp	e
	jp	nz, da_l
	ret
