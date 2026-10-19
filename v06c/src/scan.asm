; Сканер на панели: SCAN, CPIX2, CPIX4. Написано по смыслу, не по командам BBC: панель на Векторе — две
; плоскости, точка режима 5 BBC — две точки Вектора. Сверяется экран панели (v06c/test/t08.mjs); регистры на
; выходе и ячейки SC, SCH, X1 с BBC не совпадают (на BBC в них адрес и маска экрана).
; Цвет COL: старшая тетрада — бит 1 цвета (плоскость SCR_VIEW), младшая — бит 0 (SCR_2).

; b = маска, HL — адрес в SCR_VIEW: исключающее ИЛИ в плоскости по COL. Сохраняет BC, DE, HL.
dash_xor:
	ld	a, (COL)
	and	0xF0
	jp	z, dx_2
	ld	a, (hl)
	xor	b
	ld	(hl), a
dx_2:
	ld	a, (COL)
	and	0x0F
	ret	z
	ld	a, h
	add	a, high (SCR_2 - SCR_VIEW)
	ld	h, a
	ld	a, (hl)
	xor	b
	ld	(hl), a
	ld	a, h
	sub	high (SCR_2 - SCR_VIEW)
	ld	h, a
	ret

; CPIX4: чёрточка CPIX2 в строках Y1 и Y1 - 1; в Y1 остаётся верхняя строка.
CPIX4:
	call	CPIX2
	ld	hl, Y1
	dec	(hl)
; CPIX2: чёрточка из двух точек режима 5 (четыре точки Вектора) в строке Y1, начиная с X1 & FEh, цветом COL.
CPIX2:
	ld	a, (Y1)
	cpl
	ld	l, a
	ld	a, (X1)
	ld	d, a
	rrca
	rrca
	rrca
	and	31
	or	high SCR_VIEW
	ld	h, a
	ld	a, d
	and	6
	add	a, low ctw4
	ld	e, a
	ld	d, high ctw4
	ld	a, (de)
	ld	b, a
	call	dash_xor
	inc	e
	ld	a, (de)
	or	a
	ret	z
	ld	b, a
	inc	h
	jp	dash_xor

; SCAN: показать (или стереть) корабль на сканере: точка 2×2 и палочка от неё до плоскости сканера.
; Условия: бит 4 в INWK+31, TYPE < 128, старшие байты координат меньше 64.
SCAN:
	ld	a, (INWK + 31)
	and	0x10
	ret	z
	ld	a, (TYPE)
	or	a
	ret	m
	ld	b, 0xFF
	cp	9			; ракета — цвет 2, остальные — цвет 3
	jp	nz, sc_col
	ld	b, 0xF0
sc_col:
	ld	a, b
	ld	(COL), a
	ld	a, (INWK + 1)
	ld	hl, INWK + 4
	or	(hl)
	ld	hl, INWK + 7
	or	(hl)
	and	0xC0
	ret	nz
	ld	a, (INWK + 2)		; x экрана = 123 ± x_hi (у BBC при x_hi = 0 со знаком минус выходит 124)
	or	a
	ld	a, (INWK + 1)
	jp	p, sc_x
	cpl
	add	a, 1
sc_x:
	adc	a, 123
	ld	(X1), a
	ld	a, (INWK + 7)		; плоскость сканера: строка SC = 255 - (35 ± z_hi / 4)
	rrca
	rrca
	and	0x3F
	ld	e, a
	ld	a, (INWK + 8)
	or	a
	ld	a, e
	jp	p, sc_z
	cpl
	scf
sc_z:
	adc	a, 35
	cpl
	ld	e, a
	ld	a, (INWK + 4)		; строка точки = SC ∓ y_hi / 2, в пределах 194..246
	or	a
	rra
	ld	d, a
	ld	a, (INWK + 5)
	or	a
	ld	a, d
	jp	m, sc_y
	cpl
	scf
sc_y:
	adc	a, e
	jp	p, sc_246
	cp	194
	jp	nc, sc_y1
	ld	a, 194
sc_y1:
	cp	247
	jp	c, sc_y2
sc_246:
	ld	a, 246
sc_y2:
	ld	(Y1), a
	sub	e			; высота палочки; CY — палочка вниз
	push	af
	call	CPIX4
	ld	a, (X1)			; палочка — правая точка режима 5 из двух
	and	0xFE
	add	a, 2
	ld	d, a
	rrca
	rrca
	rrca
	and	31
	or	high SCR_VIEW
	ld	h, a
	ld	a, d
	and	6
	rrca
	add	a, low sc_stick
	ld	e, a
	ld	d, high sc_stick
	ld	a, (de)
	ld	b, a
	ld	a, (Y1)
	cpl
	ld	l, a			; строка верха точки
	pop	af
	ret	z
	jp	c, sc_down
	ld	c, a
sc_up:
	inc	l			; вверх от точки
	call	dash_xor
	dec	c
	jp	nz, sc_up
	ret
sc_down:
	cpl
	inc	a
	ld	c, a
	dec	l			; под точкой
sc_dn:
	dec	l
	call	dash_xor
	dec	c
	jp	nz, sc_dn
	ret
	ifdef	PCIRC
	include	"pc_pt.asm"		; в пустоту выравнивания (окружность планеты, planet.asm)
	endif
	ifndef	SCHED
	ifndef	RUS
	include	"gn_none.asm"		; в пустоту выравнивания (ввод количества, market.asm)
	endif
	endif

	align	16
ctw4:	db	0xF0, 0x00, 0x3C, 0x00, 0x0F, 0x00, 0x03, 0xC0	; четыре точки с x & 6 = 0, 2, 4, 6: байт и следующий
sc_stick:
	db	0xC0, 0x30, 0x0C, 0x03
