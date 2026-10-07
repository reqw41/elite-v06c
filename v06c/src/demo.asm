; Показ каркаса (T04): текст шрифтом игры и матрица клавиатуры. Уйдёт, когда появится заставка.

demo_text:
	ld	hl, dm_lines
dt_line:
	ld	a, (hl)
	inc	a
	ret	z			; FFh — конец
	dec	a
	ld	(XC), a
	inc	hl
	ld	a, (hl)
	ld	(YC), a
	inc	hl
	call	prstr
	inc	hl
	jp	dt_line

; Строка 17: восемь строк матрицы и модификаторы, шестнадцатерично. Печать исключающим ИЛИ: старое значение
; стирается повторной печатью.
demo_keys:
	ld	hl, kb_rows
	ld	de, demo_old
	ld	b, 0
dk_lp:
	ld	a, (de)
	cp	(hl)
	jp	z, dk_next
	ld	c, a
	call	dk_at
	ld	a, c
	call	prhex			; стереть старое
	call	dk_at
	ld	a, (hl)
	ld	(de), a
	call	prhex
dk_next:
	inc	hl
	inc	de
	inc	b
	ld	a, b
	cp	9
	jp	nz, dk_lp
	ret
dk_at:
	ld	a, b
	add	a, a
	add	a, b
	add	a, 3
	ld	(XC), a
	ld	a, 17
	ld	(YC), a
	ret

dm_lines:
	db	6, 1, "E L I T E", 0
	db	6, 3, "Vector-06C  i8080  48K", 0
	db	0, 6, " !\"#$%&'()*+,-./0123456789:;<=>?", 0
	db	0, 8, "@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_", 0
	db	0, 10, "`abcdefghijklmnopqrstuvwxyz{|}~", 0
	db	1, 13, "Commander Jameson  100.0 Cr", 0
	db	1, 15, "Keys 0-7, mod:", 0
	db	3, 17, "00 00 00 00 00 00 00 00 00", 0
	db	0xFF
