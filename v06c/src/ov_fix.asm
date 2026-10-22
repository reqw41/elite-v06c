; ov_fix (обычный образ, в конце STARS; of_s, of_v и of_tab — в пустотах выравнивания): неподвижное в обзоре —
; рамка и прицел — дорисовывается каждый проход: очистка кораблей, пыли и планеты (and) выбивает из него точки.
; Полосы рамки — только если очистка могла их задеть (of_dirt; отрезок с концом у края чинит их сам, la_r).
; Строка 0 — здесь (пыль) и сразу после отрезка с концом на ней (la_r); точки окружности планеты строку 0 не
; трогают. Строка заголовка (название вида, отсчёт) в полёте — только во второй плоскости (text.asm, tt_wmk),
; её чинить не надо. Портит всё.
ov_fix:
of_dt:	ld	hl, 0			; L (of_dirt): не 0 — точку рамки могла стереть пыль или планета (PIXEL, pa_and);
	ld	a, l			; H — мусор от pa_and (ld (of_dirt), hl)
	or	a
	jp	z, of_1
	xor	a
	ld	(of_dirt), a
	ld	hl, (high SCR_VIEW << 8) | 255		; рамка: x = 0, 1 и 254, 255 в строках 0–191
	ld	de, ((high SCR_VIEW + 31) << 8) | 255
	ld	b, 192
	call	of_s
of_1:
	call	of_t0			; строка 0
	ld	hl, LASER		; прицел, если лазер в этом виде есть (как SIGHT): строка 96 — x 108–117 и 138–147,
	ld	a, (VIEW)		; столбец x = 128 — строки 77–86 и 107–116 (два перекрестия исключающим ИЛИ)
	add	a, l			; LASER + VIEW (0–3) — в одной странице
	ld	l, a
	ld	a, (hl)
	or	a
	ret	z
	ld	de, of_tab
	ld	l, 255 - 96
	ld	b, 4
of_h:
	ld	a, (de)
	ld	h, a
	inc	de
	ld	a, (de)
	inc	de
	or	(hl)
	ld	(hl), a
	dec	b
	jp	nz, of_h
	ld	h, high SCR_VIEW + 16
	ld	l, 255 - 77
	call	of_v
	ld	l, 255 - 107
	jp	of_v
of_dirt	equ	of_dt + 1
; of_t0: строка 0 рамки — все 32 байта. Портит A, HL.
of_t0:
	ld	hl, (high SCR_VIEW << 8) | 255
of_t:
	ld	(hl), 0xFF
	inc	h
	ld	a, h
	cp	high SCR_VIEW + 32
	jp	nz, of_t
	ret
; la_r: вход LOIN в режиме очистки (lm_set ставит jp la_r на место первых команд loin_r). Отрезок с концом
; в x = 0, 1 или 254, 255 стирает и точки полос рамки — их дорисовать сразу, на строках отрезка; с концом на y = 0 —
; строку 0 (обрезанный сверху корабль или окружность планеты): так рамка не мигает.
la_r:
	ld	a, e
	add	a, 2
	cp	4
	jp	c, la_g
	ld	a, l
	add	a, 2
	cp	4
	jp	c, la_g
	xor	a			; конец на строке 0 — отрезок по строке 0 рамки
	cp	d
	jp	z, la_g
	cp	h
	jp	z, la_g
la_b:
	push	bc			; первые команды loin_r
	ld	a, l
	sub	e
	jp	loin_r + 3
la_g:
	push	bc
	ld	a, h
	sub	d
	ld	c, d			; меньший y — D…
	jp	nc, la_1
	cpl
	inc	a			; D - H
	ld	c, h			; …или H
la_1:
	inc	a
	ld	b, a			; строк отрезка
	ld	a, c
	cpl
	ld	c, a			; строка меньшего y в экране
	call	la_b			; отрезок (BC сохраняет)
	ld	l, c
	ld	e, c
	ld	h, high SCR_VIEW
	ld	d, high SCR_VIEW + 31
	call	of_s
	inc	c			; верхняя строка отрезка — 0: вернуть строку 0 рамки
	call	z, of_t0
	pop	bc
	ret
	ifdef	AUTO			; отладочная сборка: пустоты выравнивания сдвинуты (см. flight.asm)
	include	"px_a.asm"
	include	"px_o.asm"
	endif
