; Показ: надписи шрифтом игры. Уйдёт, когда появится настоящая заставка с текстом из словаря.

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

dm_lines:
	db	6, 1, "---- E L I T E ----", 0
	db	3, 21, "Vector-06C  i8080  48K", 0
	db	7, 22, "Press any key", 0
	db	0xFF
