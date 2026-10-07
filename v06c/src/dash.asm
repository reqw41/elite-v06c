; Панель приборов: картинка BBC (P.DIALS, 128×56, 4 цвета) точками двойной ширины в двух плоскостях.

; Показать панель: строки DASH_Y..DASH_Y+55, бит 0 цвета — в SCR_2, бит 1 — в SCR_VIEW.
dash_show:
	ld	de, dials
	ld	h, high SCR_2
	call	ds_plane
	ld	h, high SCR_VIEW
ds_plane:
	ld	c, 32
ds_col:
	ld	l, 255 - DASH_Y
	ld	b, DASH_H
ds_b:
	ld	a, (de)
	ld	(hl), a
	inc	de
	dec	l
	dec	b
	jp	nz, ds_b
	inc	h
	dec	c
	jp	nz, ds_col
	ret
