; Галактика: семена систем и сведения о системе. TT54, TT20, TT81, TT24, TT111, hyp1, jmp, ping, cpl, ypl, tal.
; Перенесено близко к тексту BBC; сверка — v06c/test/t20.mjs.

; TT54: следующая пара семян: (s0, s1, s2) -> (s1, s2, s0 + s1 + s2). TT20: четыре раза — следующая система.
TT20:
	call	tt20_2
tt20_2:
	call	TT54
TT54:
	ld	hl, (QQ15)
	ex	de, hl
	ld	hl, (QQ15 + 2)
	ld	(QQ15), hl
	add	hl, de
	ex	de, hl
	ld	hl, (QQ15 + 4)
	ld	(QQ15 + 2), hl
	add	hl, de
	ld	(QQ15 + 4), hl
	ret

; TT81: семена QQ15 = семена первой системы галактики QQ21.
TT81:
	ld	hl, QQ21
	ld	de, QQ15
	ld	b, 6
	jp	ll9_cp

; jmp: мы — в выбранной системе: (QQ0, QQ1) = (QQ9, QQ10). ping: выбрана наша: (QQ9, QQ10) = (QQ0, QQ1).
jmp:
	ld	hl, (QQ9)
	ld	(QQ0), hl
	ret
ping:
	ld	hl, (QQ0)
	ld	(QQ9), hl
	ret

; TT24: сведения о системе по семенам QQ15: экономика QQ3, правление QQ4, техника QQ5, население QQ6,
; производительность QQ7(1 0).
TT24:
	ld	a, (QQ15 + 1)
	and	7
	ld	(QQ3), a
	ld	a, (QQ15 + 2)
	rrca
	rrca
	rrca
	and	7
	ld	(QQ4), a
	and	6
	jp	nz, tt77
	ld	a, (QQ3)		; анархия и феодализм — не богаче средней экономики
	or	2
	ld	(QQ3), a
tt77:
	ld	a, (QQ3)
	xor	7
	ld	d, a
	ld	a, (QQ15 + 3)
	and	3
	add	a, d
	ld	e, a
	ld	a, (QQ4)
	or	a
	rra
	adc	a, e
	ld	(QQ5), a
	add	a, a
	add	a, a
	ld	hl, QQ3
	add	a, (hl)
	ld	hl, QQ4
	add	a, (hl)
	inc	a
	ld	(QQ6), a
	ld	a, d
	add	a, 3
	ld	(P_), a
	ld	a, (QQ4)
	add	a, 4
	ld	(Q), a
	call	MULTU
	ld	a, (QQ6)
	ld	(Q), a
	call	MULTU
	ld	h, a
	ld	a, (P_)
	ld	l, a
	add	hl, hl
	add	hl, hl
	add	hl, hl
	ld	a, l
	ld	(P_), a
	ld	(QQ7), hl
	ret

; TT111: выбрать систему, ближайшую к точке (QQ9, QQ10): её семена в QQ15, координаты в QQ9, QQ10,
; расстояние от нас в QQ8(1 0) (в десятых светового года); затем TT24.
TT111:
	call	TT81
	ld	c, 127			; лучшее расстояние
	ld	b, 0			; 256 систем
tt130:
	ld	a, (QQ9)
	ld	d, a
	ld	a, (QQ15 + 3)
	sub	d
	jp	nc, tt132
	cpl
	inc	a
tt132:
	or	a
	rra
	ld	e, a
	ld	a, (QQ10)
	ld	d, a
	ld	a, (QQ15 + 1)
	sub	d
	jp	nc, tt134
	cpl
	inc	a
tt134:
	or	a
	rra
	add	a, e
	cp	c
	jp	nc, tt135
	ld	c, a
	push	bc
	ld	a, b
	ld	(pd_zz), a		; номер системы — для особых описаний планет
	ld	hl, QQ15
	ld	de, QQ19
	ld	b, 6
	call	ll9_cp
	pop	bc
tt135:
	push	bc
	call	TT20
	pop	bc
	dec	b
	jp	nz, tt130
	xor	a
	ld	(U), a
	ld	hl, QQ19
	ld	de, QQ15
	ld	b, 6
	call	ll9_cp
	ld	a, (QQ15 + 1)
	ld	(QQ10), a
	ld	a, (QQ15 + 3)
	ld	(QQ9), a
	ld	hl, QQ0
	sub	(hl)
	jp	nc, tt139
	cpl
	inc	a
tt139:
	call	SQUA2
	ld	(K + 1), a
	ld	a, (P_)
	ld	(K), a
	ld	a, (QQ1)
	ld	d, a
	ld	a, (QQ10)
	sub	d
	jp	nc, tt141
	cpl
	inc	a
tt141:
	or	a
	rra
	call	SQUA2
	ld	d, a
	ld	a, (P_)
	ld	hl, K
	add	a, (hl)
	ld	(Q), a
	ld	a, d
	inc	hl
	adc	a, (hl)
	ld	(R_), a
	call	LL5
	ld	a, (Q)			; QQ8 = корень · 4
	ld	l, a
	ld	h, 0
	add	hl, hl
	add	hl, hl
	ld	(QQ8), hl
	jp	TT24

; hyp1: прибыть в выбранную систему: семена в QQ2, экономика, техника и правление — в данные о текущей системе.
hyp1:
	call	TT111
hyp1_3:					; на BBC — hyp1+3: без поиска системы
	call	jmp
	ld	hl, QQ15
	ld	de, QQ2
	ld	b, 6
	call	ll9_cp
	xor	a
	ld	(EV), a
	ld	a, (QQ3)
	ld	(QQ28), a
	ld	a, (QQ5)
	ld	(tek), a
	ld	a, (QQ4)
	ld	(gov), a
	ret

; cpl (на Векторе — cpl_): название системы по семенам QQ15: три или четыре слога.
cpl_:
	ifdef	RUS
	ld	hl, lat			; название — латиницей
	ld	a, (hl)
	push	af
	ld	(hl), 1
	call	cpl_0
	pop	af
	ld	(lat), a
	ret
cpl_0:
	endif
	ld	hl, QQ15
	ld	de, QQ19
	ld	b, 6
	call	ll9_cp
	ld	a, (QQ15)
	and	0x40
	ld	a, 3
	jp	nz, tt53_4
	dec	a
tt53_4:
	ld	(T), a
tt55:
	ld	a, (QQ15 + 5)
	and	0x1F
	jp	z, tt55_n
	or	0x80
	call	TT27
tt55_n:
	call	TT54
	ld	hl, T
	dec	(hl)
	jp	p, tt55
	ld	hl, QQ19
	ld	de, QQ15
	ld	b, 6
	jp	ll9_cp

; ypl: название текущей системы (не печатается в межгалактическом пространстве). TT62: QQ15 <-> QQ2.
ypl:
	ld	a, (MJ)
	or	a
	ret	nz
	call	TT62
	call	cpl_
TT62:
	ld	hl, QQ15
	ld	de, QQ2
	ld	b, 6
tt78:
	ld	a, (de)
	ld	c, (hl)
	ld	(hl), a
	ld	a, c
	ld	(de), a
	inc	hl
	inc	de
	dec	b
	jp	nz, tt78
	ret

; tal: номер галактики (GCNT + 1).
tal:
	ld	a, (GCNT)
	inc	a
	ld	b, a
	or	a
	jp	pr2
