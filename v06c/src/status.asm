; Экран статуса (f8): STATUS кассетной версии BBC. Сверка — v06c/test/t21.mjs и t18.mjs.
STATUS:
	ld	a, 8
	call	TT66
	call	TT111
	ld	a, 7
	ld	(XC), a
	ld	a, 126			; «COMMANDER имя», система, условие
	call	NLIN3
	ld	a, 15			; «Docked»
	ld	hl, QQ12
	inc	(hl)
	dec	(hl)
	jp	nz, st6
	ld	a, 230			; в космосе: «Green», рядом корабли — «Yellow», мало энергии — «Red»
	ld	hl, MANY + 10
	ld	e, (hl)
	ld	d, 0
	ld	hl, FRIN + 2
	add	hl, de
	inc	(hl)
	dec	(hl)
	jp	z, st6
	ld	d, a
	ld	a, (ENERGY)
	cp	128
	ccf
	ld	a, d
	adc	a, 1
st6:
	call	plf
	ld	a, 125			; правовой статус
	call	spc
	ld	a, 19
	ld	hl, FIST
	inc	(hl)
	dec	(hl)
	jp	z, st5
	ld	d, a
	ld	a, (hl)
	cp	50
	ccf
	ld	a, d
	adc	a, 1
st5:
	call	plf
	ld	a, 16			; рейтинг
	call	spc
	ld	a, (TALLY + 1)
	or	a
	jp	nz, st4
	ld	b, a
	ld	a, (TALLY)
	rrca
	rrca
	and	0x3F
st5l:
	inc	b
	or	a
	rra
	or	a
	jp	nz, st5l
st3:
	ld	a, b
	add	a, 21
	call	plf
	ld	a, 18			; «Ship:» и оборудование
	call	plf2
	ld	a, (CRGO)
	cp	26
	ld	a, 107
	call	nc, plf2
	ld	a, (BST)
	or	a
	ld	a, 111
	call	nz, plf2
	ld	a, (ECM)
	or	a
	ld	a, 108
	call	nz, plf2
	ld	a, 113
stqv:
	ld	(XX4), a
	ld	e, a
	ld	d, 0
	ld	hl, BOMB - 113
	add	hl, de
	inc	(hl)
	dec	(hl)
	call	nz, plf2
	ld	hl, XX4
	inc	(hl)
	ld	a, (hl)
	cp	117
	jp	c, stqv
	xor	a
st_las:
	ld	(CNT), a
	ld	e, a
	ld	d, 0
	ld	hl, LASER
	add	hl, de
	ld	a, (hl)
	or	a
	jp	z, st1
	ld	a, (CNT)
	add	a, 96
	call	spc
	ld	a, (CNT)
	ld	e, a
	ld	d, 0
	ld	hl, LASER
	add	hl, de
	ld	a, (hl)
	cp	0x97
	jp	z, st_mil
	cp	50
	jp	z, st_min
	or	a
	ld	a, 103
	jp	p, st_pl
	ld	a, 104
st_pl:
	call	plf2
	jp	st1
st_mil:					; военный и добывающий лазеры: слов в словаре BBC нет
	ld	hl, t_mil
	jp	st_xl
st_min:
	ld	hl, t_minl
st_xl:
	call	mis_str
	call	TT67
	ld	a, 6
	ld	(XC), a
st1:
	ld	a, (CNT)
	inc	a
	cp	4
	jp	c, st_las
	ret
; рейтинг при старшем байте счёта не ноль: на BBC — st4
st4:
	ld	b, 9			; ELITE
	cp	25
	jp	nc, st3
	dec	b
	cp	10
	jp	nc, st3
	dec	b
	cp	2
	jp	nc, st3
	dec	b
	jp	st3
