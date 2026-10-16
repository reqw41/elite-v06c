; Печать чисел и мелкие процедуры текста: BPRNT, TT11, pr2, pr5, pr6, csh, cmn, fwl, PCASH, spc, plf2, TT68,
; NLIN, NLIN2, NLIN3, NLIN4. Перенесено близко к тексту BBC; сверка — v06c/test/t19.mjs.

; pr2: число X тремя знаками. pr6: (Y X) пятью знаками без точки. pr5: пятью знаками. TT11: (Y X), знаков A.
; Перенос на входе (кроме pr6) — печатать десятичную точку перед последней цифрой.
pr2:
	ld	a, 3
	ld	c, 0
	jp	TT11
pr6:
	or	a
pr5:
	ld	a, 5
TT11:
	ld	(U), a
	ld	a, 0
	ld	(K), a
	ld	(K + 1), a
	ld	a, c
	ld	(K + 2), a
	ld	a, b
	ld	(K + 3), a
; BPRNT: число K(0 1 2 3) (старший байт первым) десятичной записью в U знаков с пробелами слева; перенос —
; с десятичной точкой перед последней цифрой. Рабочие: S, T, XX17, XX15(4..0).
BPRNT:
	push	af			; перенос — до последней цифры
	ld	a, 11
	jp	nc, tt30
	ld	hl, U
	dec	(hl)
	dec	a
tt30:
	ld	(T), a
	ld	a, 11
	ld	(XX17), a
	ld	hl, U
	sub	(hl)
	inc	a
	ld	(hl), a
	xor	a
	ld	(S), a
	jp	tt36
tt35:					; (S K) умножить на 10
	call	bp_shl
	ld	hl, K
	ld	de, XX15
	ld	b, 4
	call	ll9_cp
	ld	a, (S)
	ld	(de), a
	call	bp_shl
	call	bp_shl
	ld	hl, K + 3
	ld	de, XX15 + 3
	ld	b, 4
	or	a
bp_add:
	ld	a, (de)
	adc	a, (hl)
	ld	(hl), a
	dec	hl
	dec	de
	dec	b
	jp	nz, bp_add
	ld	hl, S
	ld	a, (XX15 + 4)
	adc	a, (hl)
	ld	(hl), a
tt36:					; цифра = сколько раз вычитается 10^11
	ld	c, 0
tt36_l:
	ld	a, (K + 3)		; XX15(4..0) = (S K) - 10^11 (17 48 76 E8 00h)
	sub	0x00
	ld	(XX15 + 3), a
	ld	a, (K + 2)
	sbc	a, 0xE8
	ld	(XX15 + 2), a
	ld	a, (K + 1)
	sbc	a, 0x76
	ld	(XX15 + 1), a
	ld	a, (K)
	sbc	a, 0x48
	ld	(XX15), a
	ld	a, (S)
	sbc	a, 0x17
	ld	(XX15 + 4), a
	jp	c, tt37
	ld	hl, XX15
	ld	de, K
	ld	b, 4
	call	ll9_cp
	ld	a, (hl)
	ld	(S), a
	inc	c
	jp	tt36_l
tt37:
	ld	a, c
	or	a
	jp	nz, tt32
	ld	a, (T)
	or	a
	jp	z, tt32
	ld	hl, U			; ведущий ноль: за пределами ширины — ничего, в пределах — пробел
	dec	(hl)
	jp	p, tt34
	ld	a, ' '
	jp	tt34_p
tt32:
	ld	hl, T
	ld	(hl), 0
	add	a, '0'
tt34_p:
	call	TT26
tt34:
	ld	hl, T
	dec	(hl)
	jp	p, tt34_t
	inc	(hl)
tt34_t:
	ld	hl, XX17
	dec	(hl)
	ret	m
	jp	nz, tt35
	pop	af
	jp	nc, tt35
	ld	a, '.'
	call	TT26
	jp	tt35
bp_shl:					; (S K) влево на бит
	ld	hl, K + 3
	ld	a, (hl)
	add	a, a
	ld	(hl), a
	ld	b, 3
bp_shl_l:
	dec	hl
	ld	a, (hl)
	rla
	ld	(hl), a
	dec	b
	jp	nz, bp_shl_l
	ld	hl, S
	ld	a, (hl)
	rla
	ld	(hl), a
	ret

; fwl: «Fuel: n.n Light Years», затем PCASH: «Cash: … Cr».
fwl:
	ld	a, 105
	ifdef	RUS			; «ТОПЛИВО :» — двоеточия блока статуса в одном столбце
	call	spc
	call	TT73
	call	TT162			; и пробел — как после «СТАТУС  :»
	else
	call	TT68
	endif
	ld	a, (QQ14)
	ld	b, a
	scf
	call	pr2
	ld	a, 195
	call	plf
PCASH:
	ld	a, 119
	jp	TT27
; csh: деньги (CASH, четыре байта) с десятыми и « Cr», перевод строки.
csh:
	ld	hl, (CASH)
	ld	(K), hl
	ld	hl, (CASH + 2)
	ld	(K + 2), hl
	ld	a, 9
	ld	(U), a
	scf
	call	BPRNT
	ld	a, 226
	jp	plf
; cmn: имя командира (до знака 13).
cmn:
	ld	hl, NA_
cmn_l:
	ld	a, (hl)
	cp	13
	ret	z
	call	TT26
	inc	hl
	jp	cmn_l
; spc: слово A и пробел. plf2: слово A, перевод строки, курсор в столбец 6. TT68: слово A и двоеточие.
spc:
	call	TT27
	jp	TT162
plf2:
	call	plf
	ld	a, 6
	ld	(XC), a
	ret
TT68:
	call	TT27
	jp	TT73
; NLIN3: слово A и линия под заголовком (строка 19). NLIN4: линия в строке 19. NLIN: курсор на строку ниже
; и линия в строке 23. NLIN2: линия в строке A от x = 2 до 253.
NLIN3:
	call	TT27
NLIN4:
	ld	a, 19
	jp	NLIN2
NLIN:
	ld	hl, YC
	inc	(hl)
	ld	a, 23
NLIN2:
	ld	(Y1), a
	ld	a, 2
	ld	(X1), a
	ld	a, 254
	ld	(X2), a
	jp	HLOIN
