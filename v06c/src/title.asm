; Заставка: цикл вращения корабля (TLL2 из TITLE кассетной версии BBC) и показ для образа.
; Подготовка заставки BBC (RESET, TT66, NWSHP, текст из словаря) ещё не перенесена: title_demo ставит корабль сам.

; Один проход цикла TLL2: приблизить корабль, сдвинуть и повернуть, напечатать. Сверка с эталоном — t10.mjs.
title_pass:
	ld	a, (INWK + 7)
	cp	1
	jp	z, tl1
	dec	a
	ld	(INWK + 7), a
tl1:
	call	MVEIT
	ld	a, 128
	ld	(INWK + 6), a
	xor	a
	ld	(INWK), a
	ld	(INWK + 3), a
	call	LL9
	ld	hl, MCNT
	dec	(hl)
	ret

; Корабль типа A для показа: блок INWK как после ZINF и начала TITLE.
title_demo:
	ld	(TYPE), a
	dec	a
	add	a, a
	ld	e, a
	ld	d, 0
	ld	hl, XX21
	add	hl, de
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ex	de, hl
	ld	(XX0), hl
	ld	hl, INWK
	ld	b, 36
td_z:
	ld	(hl), 0
	inc	hl
	dec	b
	jp	nz, td_z
	ld	a, 96
	ld	(INWK + 18), a		; roofv_y
	ld	(INWK + 22), a		; sidev_x
	ld	(INWK + 14), a		; nosev_z: носом от нас
	ld	(INWK + 7), a		; издалека
	ld	a, 127
	ld	(INWK + 29), a
	ld	(INWK + 30), a
	ld	hl, K_
	ld	(INF), hl
	ld	hl, K_ + 0x0300		; список отрезков корабля
	ld	(XX19), hl
	ld	(hl), 0
	ret
