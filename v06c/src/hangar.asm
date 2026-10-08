; Ангар станции при стыковке — из дисковой версии BBC (в кассетной его нет): HALL, HANGER, HAS1, HAS2, HAS3.
; Эталон — код стоянки дисковой версии (tools/oracle/disc.js), сверка — v06c/test/hangar.mjs (экран).
; Отличия от BBC: отрезки кораблей рисуются исключающим ИЛИ, как в полёте (на BBC на время ангара печать
; переключается на ИЛИ); генератор случайных чисел после ангара возвращается к прежнему значению.

; HALL: в ангаре один корабль случайного вида или группа из двух-трёх; затем пол и стойки.
HALL:
	ld	hl, (RAND)
	push	hl
	ld	hl, (RAND + 2)
	push	hl
	ld	a, 1
	call	TT66
	call	DORND2
	or	a
	jp	p, ha7
	and	3			; группа: строка HATB из трёх кораблей
	ld	c, a
	add	a, a
	add	a, a
	add	a, a
	add	a, c
	ld	e, a
	ld	d, 0
	ld	hl, hatb
	add	hl, de
	ld	b, 3
hal8:
	ld	a, (hl)
	ld	(XX15 + 2), a
	inc	hl
	ld	a, (hl)
	ld	(XX15 + 1), a
	inc	hl
	ld	a, (hl)
	ld	(XX15), a
	inc	hl
	push	hl
	push	bc
	call	has1
	pop	bc
	pop	hl
	dec	b
	jp	nz, hal8
	ld	a, 128
	jp	ha9
ha7:
	or	a
	rra
	ld	(XX15 + 1), a
	call	DORND			; перенос — как на BBC: младший бит предыдущего числа
	ld	(XX15), a
	call	DORND
	and	7
	ld	(XX15 + 2), a
	call	has1
	xor	a
ha9:
; HANGER: пол — 11 горизонталей от краёв к середине до первой занятой точки (при группе — ещё и от середины
; к краям); стойки — вертикали через 16 точек сверху вниз до первой занятой точки. A <> 0 — группа.
	ld	b, a
	ld	de, hangy
hal1:
	ld	a, (de)
	or	a
	jp	z, hal6
	ld	l, a
	ld	h, high SCR_VIEW
	ld	c, 0x20
	call	has2
	ld	h, high SCR_VIEW + 31
	ld	c, 0x04
	call	has3
	ld	a, b
	or	a
	jp	z, ha2
	ld	h, high SCR_VIEW + 16
	ld	c, 0x20
	call	has2
	ld	h, high SCR_VIEW + 16
	ld	c, 0x40
	call	has3
ha2:
	inc	de
	jp	hal1
hal6:
	ld	h, high SCR_VIEW + 2
hal6a:
	ld	l, 254
hal7:
	ld	a, (hl)
	or	a
	jp	m, ha6
	or	0x80
	ld	(hl), a
	dec	l
	jp	hal7
ha6:
	inc	h
	inc	h
	ld	a, h
	cp	high SCR_VIEW + 32
	jp	nz, hal6a
	pop	hl
	ld	(RAND + 2), hl
	pop	hl
	ld	(RAND), hl
	ret
has2:					; вправо от точки (HL, маска C) до занятой точки или края экрана
	ld	a, (hl)
	and	c
	ret	nz
	ld	a, (hl)
	or	c
	ld	(hl), a
	ld	a, c
	rrca
	ld	c, a
	jp	nc, has2
	inc	h
	ld	a, h
	cp	high SCR_VIEW + 32
	jp	nz, has2
	ret
has3:					; влево
	ld	a, (hl)
	and	c
	ret	nz
	ld	a, (hl)
	or	c
	ld	(hl), a
	ld	a, c
	rlca
	ld	c, a
	jp	nc, has3
	dec	h
	ld	a, h
	cp	high SCR_VIEW - 1
	jp	nz, has3
	ret

; has1 (HAS1): корабль в ангаре. XX15 — дальность z, XX15+1 — смещение x (младший бит XX15 — влево),
; XX15+2 — номер вида 1…7 (0 — нет корабля). Корабль случайно повёрнут и стоит на полу.
has1:
	call	ZINF
	ld	a, (XX15)
	ld	(INWK + 6), a
	and	1
	rrca
	ld	(INWK + 2), a
	ld	a, (XX15 + 1)
	ld	(INWK), a
	and	1
	inc	a
	ld	(INWK + 7), a
	ld	a, 0x80
	ld	(INWK + 5), a
	ld	(RAT2), a
	ld	a, high (WS + 0x0B00)
	ld	(INWK + 34), a
	call	DORND2
hal5:
	push	af
	ld	b, 21
	ld	c, 9
	call	MVS5
	ld	b, 23
	ld	c, 11
	call	MVS5
	ld	b, 25
	ld	c, 13
	call	MVS5
	pop	af
	dec	a
	jp	nz, hal5
	ld	a, (XX15 + 2)
	or	a
	ret	z
	ld	e, a
	ld	d, 0
	ld	hl, hall_ty - 1
	add	hl, de
	ld	a, (hl)
	ld	(TYPE), a
	add	a, a
	ld	e, a
	ld	hl, XX21X - 2
	add	hl, de
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a
	ld	(XX0), hl
	inc	hl
	ld	a, (hl)
	ld	(Q), a
	inc	hl
	ld	a, (hl)
	ld	(R_), a
	call	LL5
	ld	a, 100
	jp	c, has_y
	dec	a
has_y:
	ld	hl, Q
	sub	(hl)
	or	a
	rra
	ld	(INWK + 3), a
	call	TIDY
	jp	LL9
