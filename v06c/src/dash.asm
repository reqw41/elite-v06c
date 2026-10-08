; Панель приборов: картинка BBC (P.DIALS, 128×56, 4 цвета) точками двойной ширины в двух плоскостях.

; Показать панель: строки DASH_Y..DASH_Y+55, бит 0 цвета — в SCR_2, бит 1 — в SCR_VIEW.
dash_show:
	ld	de, dials
	ld	h, high SCR_2
	call	ds_plane
	ifndef	SCHED
	ld	de, dials2		; обычный образ: плоскости сжаты порознь и лежат в разных местах
	endif
	ld	h, high SCR_VIEW
ds_plane:
	ld	c, 32
ds_col:
	ld	l, 255 - DASH_Y
	ld	b, DASH_H
ds_b:
	call	ds_get
	ld	(hl), a
	dec	l
	dec	b
	jp	nz, ds_b
ds_z:
	ld	(hl), b			; восемь строк под панелью — чистые (после заставки загрузчика там её звёзды)
	dec	l
	jp	p, ds_z
	inc	h
	dec	c
	jp	nz, ds_col
	ret
; ds_get: следующий байт картинки панели из сжатого потока (tools/convert/dials_rle.py): байт n < 80h — дальше
; n + 1 байт как есть; n >= 80h — следующий байт повторить (n - 80h) + 2 раза. DE — поток. Сохраняет BC, HL.
ds_get:
	push	hl
	ld	hl, ds_n
	ld	a, (hl)
	or	a
	jp	nz, dg_have
	ld	a, (de)
	inc	de
	or	a
	jp	m, dg_run
	inc	a
	ld	(hl), a
	xor	a
	ld	(ds_rep), a
	jp	dg_have
dg_run:
	and	0x7F
	add	a, 2
	ld	(hl), a
	ld	(ds_rep), a
	ld	a, (de)
	inc	de
	ld	(ds_v), a
dg_have:
	dec	(hl)
	ld	a, (ds_rep)
	or	a
	jp	z, dg_lit
	ld	a, (ds_v)
	pop	hl
	ret
dg_lit:
	ld	a, (de)
	inc	de
	pop	hl
	ret
