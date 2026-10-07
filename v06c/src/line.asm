; Точка, отрезок, горизонтальная линия — PIXEL, LOIN (LL30), HLOIN кассетной версии BBC под столбцовый экран.
; Всё рисуется исключающим ИЛИ в плоскость обзора. Шаг по y — INC L / DEC L, шаг по x — сдвиг маски и INC H.
; Соглашение о регистрах: A — как на BBC, X -> B, Y -> C. Рабочие ячейки BBC (P, Q, R, S, SWAP, T, T1, YSAV,
; SC, SCH) не воспроизводятся: их заменяют регистры.

; PIXEL: точка звёздной пыли. B = x, A = y, ZZ — расстояние: ZZ >= 144 — одна точка, ZZ >= 80 — две рядом,
; ближе — квадрат 2×2 (вторая строка выше; в верхней строке знакоместа — ниже, как на BBC).
; Сохраняет BC. Портит A, DE, HL. Перенос на выходе — как на BBC: 1 при ZZ >= 80 (от него зависит генератор
; случайных чисел при засеве пыли).
PIXEL:
	cpl
	ld	l, a			; 255 - y
	ld	a, b
	rrca
	rrca
	rrca
	and	31
	or	high SCR_VIEW
	ld	h, a
	ld	a, b
	and	7
	ld	e, a
	ld	d, high TWOS
	ld	a, (ZZ)
	cp	144
	jp	nc, px_one
	ld	a, e
	add	a, low TWOS2
	ld	e, a
	ld	a, (de)
	ld	d, a
	xor	(hl)
	ld	(hl), a
	ld	a, (ZZ)
	cp	80
	jp	nc, px_c1
	ld	a, l
	and	7
	cp	7			; y кратно 8?
	jp	z, px_dn
	inc	l
	inc	l
px_dn:
	dec	l
	ld	a, d
	xor	(hl)
	ld	(hl), a
	ret
px_one:
	ld	a, e
	add	a, low TWOS
	ld	e, a
	ld	a, (de)
	xor	(hl)
	ld	(hl), a
px_c1:
	scf
	ret

; LOIN: отрезок (X1, Y1) – (X2, Y2). Один конец не рисуется (какой — как на BBC: зависит от порядка концов и
; направления). Концы в X1..Y2 меняются местами так же, как на BBC: при пологом отрезке слева должен быть X1,
; при крутом Y1 >= Y2. Сохраняет BC. Портит A, DE, HL.
LOIN:
	ld	hl, (X1)
	ex	de, hl			; E = X1, D = Y1
	ld	hl, (X2)		; L = X2, H = Y2
; loin_r: то же с концами в регистрах: E = X1, D = Y1, L = X2, H = Y2.
loin_r:
	push	bc
	ld	a, l
	sub	e
	jp	nc, li_1
	cpl
	inc	a
li_1:
	ld	b, a			; B = |X2 - X1|
	ld	a, h
	sub	d
	jp	nc, li_2
	cpl
	inc	a
li_2:
	ld	c, a			; C = |Y2 - Y1|
	cp	b
	jp	nc, li_steep

; --- пологий: шаг по x, наклон = 256·dy/dx ---
	ld	a, e
	cp	l
	ld	a, 0
	jp	c, lx_ord		; X1 < X2
	ex	de, hl			; поменять концы: E = X1, D = Y1, H = Y2 — уже новые
	call	lo_swhook
	ld	a, 0xFF
lx_ord:
	ld	l, a			; L = 0 — не меняли, FFh — меняли
	ld	a, d
	cp	h			; CY: Y1 < Y2 — вниз по экрану
	ld	a, 0x2C			; INC L — вверх
	jp	nc, lx_dir
	inc	a			; DEC L — вниз
	inc	l			; вниз первая точка пропускается, если концы НЕ меняли
lx_dir:
	ld	h, a
	ld	a, (lxu_y0)
	cp	h
	call	nz, lx_patch		; направление сменилось: подменить команду шага по y в восьми местах
	ld	a, l
	or	a
	ld	hl, lxu_tabp
	jp	z, lx_tab
	ld	hl, lxu_tabs		; NZ — пропустить первую точку (иначе не рисуется последняя)
lx_tab:
	push	af
	ld	a, e
	and	7
	add	a, a
	add	a, l
	ld	l, a
	ld	a, (hl)
	inc	l
	ld	h, (hl)
	ld	l, a
	pop	af
	push	hl			; куда войти в развёрнутый цикл
	push	af
	ld	a, d
	cpl
	ld	l, a
	ld	a, e
	rrca
	rrca
	rrca
	and	31
	or	high SCR_VIEW
	ld	h, a			; HL — адрес байта точки (X1, Y1)
	ld	d, c
	ld	e, b
	call	li_div			; A = 256·dy/dx
	ld	d, a
	ld	b, e
	ld	e, 128
	pop	af
	ret	z			; вход с печати первой точки, точек dx
	inc	b
	ret				; вход с шага, точек dx + 1 без первой
lx_done:
	pop	bc
	ret
; Цикл развёрнут по восьми положениям точки в байте: маска — константа, сдвигать её не нужно.
lxu_p0:
	ld	a, (hl)
	xor	0x80
	ld	(hl), a
lxu_s0:
	ld	a, e
	add	a, d
	ld	e, a
	jp	nc, $ + 4
lxu_y0:
	inc	l
	dec	b
	jp	z, lx_done
lxu_p1:
	ld	a, (hl)
	xor	0x40
	ld	(hl), a
lxu_s1:
	ld	a, e
	add	a, d
	ld	e, a
	jp	nc, $ + 4
lxu_y1:
	inc	l
	dec	b
	jp	z, lx_done
lxu_p2:
	ld	a, (hl)
	xor	0x20
	ld	(hl), a
lxu_s2:
	ld	a, e
	add	a, d
	ld	e, a
	jp	nc, $ + 4
lxu_y2:
	inc	l
	dec	b
	jp	z, lx_done
lxu_p3:
	ld	a, (hl)
	xor	0x10
	ld	(hl), a
lxu_s3:
	ld	a, e
	add	a, d
	ld	e, a
	jp	nc, $ + 4
lxu_y3:
	inc	l
	dec	b
	jp	z, lx_done
lxu_p4:
	ld	a, (hl)
	xor	0x08
	ld	(hl), a
lxu_s4:
	ld	a, e
	add	a, d
	ld	e, a
	jp	nc, $ + 4
lxu_y4:
	inc	l
	dec	b
	jp	z, lx_done
lxu_p5:
	ld	a, (hl)
	xor	0x04
	ld	(hl), a
lxu_s5:
	ld	a, e
	add	a, d
	ld	e, a
	jp	nc, $ + 4
lxu_y5:
	inc	l
	dec	b
	jp	z, lx_done
lxu_p6:
	ld	a, (hl)
	xor	0x02
	ld	(hl), a
lxu_s6:
	ld	a, e
	add	a, d
	ld	e, a
	jp	nc, $ + 4
lxu_y6:
	inc	l
	dec	b
	jp	z, lx_done
lxu_p7:
	ld	a, (hl)
	xor	0x01
	ld	(hl), a
lxu_s7:
	ld	a, e
	add	a, d
	ld	e, a
	jp	nc, $ + 4
lxu_y7:
	inc	l
	dec	b
	jp	z, lx_done
	inc	h
	jp	lxu_p0
lx_patch:
	ld	a, h
	ld	(lxu_y0), a
	ld	(lxu_y1), a
	ld	(lxu_y2), a
	ld	(lxu_y3), a
	ld	(lxu_y4), a
	ld	(lxu_y5), a
	ld	(lxu_y6), a
	ld	(lxu_y7), a
	ret

; --- крутой: шаг по y вверх, наклон = 256·dx/dy ---
li_steep:
	ld	a, d
	cp	h
	ld	a, 0
	jp	nc, ly_ord		; Y1 >= Y2
	ex	de, hl
	call	lo_swhook
	ld	a, 0xFF
ly_ord:
	or	a
	push	af			; Z — концы не меняли: пропустить первую точку
	ld	a, l
	cp	e			; CY: X2 < X1 — влево
	ld	hl, 0x240F		; INC H, RRCA
	jp	nc, ly_dir
	ld	hl, 0x2507		; DEC H, RLCA
ly_dir:
	ld	a, l
	ld	(ly_rot), a
	ld	a, h
	ld	(ly_hstep), a
	call	li_addr
	push	af
	ld	d, b
	ld	e, c
	call	li_div			; A = 256·dx/dy (при dx = dy — FFh)
	ld	d, a
	ld	b, e
	inc	b
	pop	af
	ld	c, a
	ld	e, 128
	pop	af
	jp	z, ly_step
	dec	b
ly_loop:
	ld	a, (hl)
	xor	c
	ld	(hl), a
ly_step:
	inc	l
	ld	a, e
	add	a, d
	ld	e, a
	jp	nc, ly_2
	ld	a, c
ly_rot:
	rrca
	ld	c, a
	jp	nc, ly_2
ly_hstep:
	inc	h
ly_2:
	dec	b
	jp	nz, ly_loop
	pop	bc
	ret

; Перестановка концов в ячейках X1..Y2, как на BBC. LL155 на время печати списка ставит сюда RET (C9h):
; ячейки нужны только после последнего отрезка.
lo_swhook:
	jp	lo_swst
lo_swst:
	ld	(X2), hl
	ex	de, hl
	ld	(X1), hl
	ex	de, hl
	ret

; Адрес и маска точки: E = x, D = y -> HL, A. Портит DE.
li_addr:
	ld	a, d
	cpl
	ld	l, a
	ld	a, e
	rrca
	rrca
	rrca
	and	31
	or	high SCR_VIEW
	ld	h, a
	ld	a, e
	and	7
	add	a, low TWOS
	ld	e, a
	ld	d, high TWOS
	ld	a, (de)
	ret

; Деление как в LOIN на BBC: A = восемь бит частного 256·D/E (D <= E; при D = E выходит FFh).
; Портит B, D. Сохраняет C, E, HL.
li_div:
	ifdef	FAST
	ld	a, d			; быстрая сборка: по логарифмам, как отрезок второго процессора
	or	a
	ret	z
	push	hl
	call	divlog
	pop	hl
	ret	nc
	ld	a, 255
	ret
	endif
	ld	b, 1			; биты частного копятся перевёрнутыми; единица выйдет на восьмом сдвиге
ld_lp:
	ld	a, d
	add	a, a
	jp	c, ld_sub
	cp	e
	jp	c, ld_bit		; меньше делителя: бит 0
ld_sub:
	sub	e
	or	a
ld_bit:
	ld	d, a
	ld	a, b
	rla
	ld	b, a
	jp	nc, ld_lp
	cpl
	ret

; HLOIN: горизонтальная линия в строке Y1 от меньшего из X1, X2 до большего, не включая его.
; Как на BBC, в X1 остаётся меньший конец, в X2 — больший минус 1. При X1 = X2 ничего не делает.
; Сохраняет BC. Портит A, DE, HL.
HLOIN:
	push	bc
	ld	hl, (X1)		; L = X1, H = Y1
	ld	a, (X2)
	cp	l
	jp	z, hl_ret
	jp	nc, hl_ord
	ld	b, l
	ld	l, a
	ld	(X1), a
	ld	a, b
hl_ord:
	dec	a
	ld	(X2), a
	ld	b, a			; B — правая точка, L — левая
	ld	c, h			; C = y
	ld	h, high TWOS
	ld	a, l
	ld	d, a
	and	7
	add	a, low TWFR
	ld	l, a
	ld	e, (hl)			; E — маска левого байта
	ld	a, b
	and	7
	add	a, low TWFL
	ld	l, a
	ld	l, (hl)			; L — маска правого байта
	ld	a, b
	rrca
	rrca
	rrca
	and	31
	ld	b, a
	ld	a, d
	rrca
	rrca
	rrca
	and	31
	ld	d, a
	ld	a, b
	sub	d
	ld	b, a			; B — на сколько столбцов правый байт правее левого
	ld	a, c
	cpl
	ld	c, l
	ld	l, a
	ld	a, d
	or	high SCR_VIEW
	ld	h, a
	ld	a, b
	or	a
	jp	nz, hl_multi
	ld	a, e
	and	c
	xor	(hl)
	ld	(hl), a
hl_ret:
	pop	bc
	ret
hl_multi:
	ld	a, e
	xor	(hl)
	ld	(hl), a
	inc	h
	dec	b
	jp	z, hl_last
hl_mid:
	ld	a, (hl)
	cpl
	ld	(hl), a
	inc	h
	dec	b
	jp	nz, hl_mid
hl_last:
	ld	a, c
	xor	(hl)
	ld	(hl), a
	pop	bc
	ret

line_code_end:
; Маски точек — все в одной странице памяти.
	align	64
TWOS:	db	0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01
TWOS2:	db	0xC0, 0x60, 0x30, 0x18, 0x0C, 0x06, 0x03, 0x03
TWFL:	db	0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC, 0xFE, 0xFF
TWFR:	db	0xFF, 0x7F, 0x3F, 0x1F, 0x0F, 0x07, 0x03, 0x01
lxu_tabp:
	dw	lxu_p0, lxu_p1, lxu_p2, lxu_p3, lxu_p4, lxu_p5, lxu_p6, lxu_p7
lxu_tabs:
	dw	lxu_s0, lxu_s1, lxu_s2, lxu_s3, lxu_s4, lxu_s5, lxu_s6, lxu_s7
