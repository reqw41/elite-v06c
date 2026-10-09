; Движение корабля (T08): MVEIT и её части. Перенесено близко к тексту BBC; сравнение с эталоном —
; v06c/test/t08.mjs. У MVEIT регистры на выходе не сравниваются (она кончается переходом в SCAN).
move_start:

; MVT1: (x_sign x_hi x_lo) += (A R), где координата — INWK+X.. (X = 0, 3, 6), знак A — бит 7.
; MVT1_2 (на BBC — MVT1-2): то же, от A берётся только знак (приращение (0 R)).
; S = |A|, T = знак. X, Y не меняются.
MVT1_2:
	and	0x80
MVT1:
	add	a, a
	ld	d, a
	ld	a, 0
	rra
	ld	(T), a
	ld	e, a			; E = знак приращения
	ld	a, d
	or	a
	rra
	ld	(S), a
	ld	d, a			; D = |A|
	ld	hl, INWK + 2
	ld	a, b
	add	a, l
	ld	l, a
	ld	a, e
	xor	(hl)
	jp	m, mv10
	dec	hl
	dec	hl
	ld	a, (R_)
	add	a, (hl)
	ld	(hl), a
	inc	hl
	ld	a, d
	adc	a, (hl)
	ld	(hl), a
	inc	hl
	ld	a, (hl)
	adc	a, 0
	jp	nc, mvt1_st
	or	e
	ld	(hl), a
	scf
	ret
mvt1_st:
	or	e
	ld	(hl), a
	ret
mv10:					; знаки разные: вычесть
	dec	hl
	dec	hl
	ld	a, (R_)
	ld	e, a
	ld	a, (hl)
	sub	e
	ld	(hl), a
	inc	hl
	ld	a, (hl)
	sbc	a, d
	ld	(hl), a
	sbc	a, a
	ld	e, a			; E = FFh — был заём
	inc	hl
	ld	a, (hl)
	and	0x7F
	add	a, e
	inc	e
	dec	e
	jp	z, mv10_ok
	jp	c, mv10_ok
	or	0x80			; ушли за ноль: сменить знак числа
	ld	d, a
	ld	a, (T)
	xor	d
	ld	(hl), a
	dec	hl
	dec	hl
	xor	a
	sub	(hl)
	ld	(hl), a
	inc	hl
	ld	a, 0
	sbc	a, (hl)
	ld	(hl), a
	inc	hl
	ld	a, 0
	sbc	a, (hl)
	jp	c, mv10_b
	and	0x7F
	ld	d, a
	ld	a, (T)
	or	d
	ld	(hl), a
	scf
	ret
mv10_b:
	and	0x7F
	ld	d, a
	ld	a, (T)
	or	d
	ld	(hl), a
	ret
mv10_ok:
	or	0x80
	ld	d, a
	ld	a, (T)
	xor	d
	ld	(hl), a
	scf
	ret

; MVT6: P(2 1) = INWK(1 0),X ± P(2 1) по знакам (A — знак P, INWK+2,X — знак координаты); A — знак результата.
; Y = A на входе.
MVT6:
	ld	c, a
	ld	hl, INWK + 2
	ld	e, b
	ld	d, 0
	add	hl, de
	xor	(hl)
	jp	m, mv50
	dec	hl
	dec	hl
	ld	a, (P_ + 1)
	add	a, (hl)
	ld	(P_ + 1), a
	inc	hl
	ld	a, (P_ + 2)
	adc	a, (hl)
	ld	(P_ + 2), a
	ld	a, c
	ret
mv50:
	dec	hl
	dec	hl
	ex	de, hl
	ld	hl, P_ + 1
	ld	a, (de)
	sub	(hl)
	ld	(hl), a
	inc	de
	inc	hl
	ld	a, (de)
	sbc	a, (hl)
	ld	(hl), a
	jp	c, mv51
	ld	a, c
	xor	0x80
	scf
	ret
mv51:
	dec	hl
	xor	a
	sub	(hl)
	ld	(hl), a
	inc	hl
	ld	a, 0
	sbc	a, (hl)
	ld	(hl), a
	ccf
	ld	a, c
	ret

; MVS4: повернуть вектор ориентации INWK+Y.. (Y = 9, 15, 21) на крен и тангаж игрока (ALPHA, BETA).
; T71: адрес сохраняется на стеке через MAD; INC/DEC HL не меняют флаги i8080.
; Записи младшего байта множимого в P перед MAD не нужны: MULT1 читает только A/Q и сам пишет P.
; Результаты, рабочие ячейки и A/B/C/CY прежние; проверка — mvs4.mjs и t08.mjs.
MVS4:
	ifndef	SCHED
	ld	a, (ALP1)		; нет крена — первая половина поворота тождественна
	or	a
	jp	z, mvs4_b
	endif
	ld	a, (ALPHA)
	ld	(Q), a
	ld	a, c			; y -= alpha · x; HL = INWK + Y
	add	a, low INWK
	ld	l, a
	ld	h, high INWK
	inc	hl
	ld	d, (hl)			; старший байт x
	inc	hl
	ld	a, (hl)
	ld	(R_), a
	inc	hl
	ld	a, (hl)
	ld	(S), a
	ld	a, d
	xor	0x80
	push	hl			; адрес старшего байта y
	call	MAD
	pop	hl
	ld	(hl), a
	dec	hl
	ld	(hl), b
	dec	hl				; x += alpha · новое y (оно остаётся в A)
	dec	hl
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ex	de, hl
	ld	(R_), hl			; R/S — соседние байты
	ex	de, hl
	dec	hl
	push	hl			; адрес младшего байта x
	call	MAD
	pop	hl
	ld	(hl), b
	inc	hl
	ld	(hl), a
	ld	a, b
	ld	(P_), a			; сохранить прежний P, в том числе при нулевом тангаже
mvs4_b:
	ifndef	SCHED
	ld	a, (BET1)		; нет тангажа — вторая половина тождественна
	or	a
	ret	z
	endif
	ld	a, (BETA)
	ld	(Q), a
	ld	a, c			; y -= beta · z; HL = INWK + Y
	add	a, low INWK
	ld	l, a
	ld	h, high INWK
	inc	hl
	inc	hl
	ld	a, (hl)
	ld	(R_), a
	inc	hl
	ld	a, (hl)
	ld	(S), a
	inc	hl
	inc	hl
	ld	a, (hl)
	xor	0x80
	push	hl			; адрес старшего байта z
	call	MAD
	pop	hl
	dec	hl
	dec	hl
	ld	(hl), a
	dec	hl
	ld	(hl), b
	inc	hl				; z += beta · новое y (оно остаётся в A)
	inc	hl
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ex	de, hl
	ld	(R_), hl
	ex	de, hl
	push	hl			; адрес старшего байта z
	call	MAD
	pop	hl
	ld	(hl), a
	dec	hl
	ld	(hl), b
	ret
; MVS5: повернуть пару координат двух векторов ориентации (INWK+X и INWK+Y) на 1/16 радиана в сторону
; знака RAT2: x = x·(1 - 1/512) + y/16, y = y·(1 - 1/512) - x/16.
MVS5:
	call	mv5_x
	call	mv5_sr
	call	mv5_y
	call	mv5_p
	ld	hl, RAT2
	xor	(hl)
	ld	d, a
	ld	a, b
	ld	(Q), a
	ld	a, d
	call	ADD
	ld	(K + 1), a
	ld	a, b
	ld	(K), a
	ld	a, (Q)
	ld	b, a
	call	mv5_y
	call	mv5_sr
	call	mv5_x
	call	mv5_p
	xor	0x80
	ld	hl, RAT2
	xor	(hl)
	call	ADD
	push	af
	call	mv5_y
	pop	af
	ld	(hl), b
	inc	hl
	ld	(hl), a
	push	af
	ld	a, (Q)
	ld	b, a
	call	mv5_x
	ld	a, (K)
	ld	(hl), a
	inc	hl
	ld	a, (K + 1)
	ld	(hl), a
	pop	af
	ld	a, (K + 1)
	ret
mv5_x:
	ld	hl, INWK
	ld	e, b
	ld	d, 0
	add	hl, de
	ret
mv5_y:
	ld	hl, INWK
	ld	e, c
	ld	d, 0
	add	hl, de
	ret
; HL -> (lo, hi): T = |hi| / 2, (S R) = (hi lo) - T
mv5_sr:
	inc	hl
	ld	a, (hl)
	and	0x7F
	rra
	ld	(T), a
	ld	e, a
	dec	hl
	ld	a, (hl)
	sub	e
	ld	(R_), a
	inc	hl
	ld	a, (hl)
	sbc	a, 0
	ld	(S), a
	ret
; HL -> (lo, hi): (A P) = (|hi| lo) / 16, знак hi — в T и в бите 7 у A
mv5_p:
	ld	a, (hl)
	rrca
	rrca
	rrca
	rrca
	and	0x0F
	ld	e, a
	inc	hl
	ld	a, (hl)
	ld	d, a
	and	0x80
	ld	(T), a
	ld	a, d
	rlca
	rlca
	rlca
	rlca
	and	0xF0
	or	e
	ld	(P_), a
	ld	a, d
	and	0x7F
	rrca
	rrca
	rrca
	rrca
	and	0x07
	ld	e, a
	ld	a, (T)
	or	e
	ret

; MVEIT: шаг движения корабля из INWK: выправить ориентацию (раз в 16 проходов), тактика, стереть со сканера,
; сдвинуть вдоль носа на скорость, разгон, поворот вселенной на крен и тангаж игрока, сдвиг на скорость игрока,
; поворот ориентации, собственное вращение корабля, показать на сканере.
MVEIT:
	ld	a, (INWK + 31)
	and	0xA0
	jp	nz, mv30
	ld	a, (MCNT)
	ld	hl, XSAV
	xor	(hl)
	and	15
	jp	nz, mv3
	call	TIDY
mv3:
	ld	a, (TYPE)
	ld	b, a
	or	a
	jp	m, MV40
	ld	a, (INWK + 32)
	or	a
	jp	p, mv30
	ld	a, b
	cp	9
	jp	z, mv26
	ld	a, (MCNT)
	ld	hl, XSAV
	xor	(hl)
	and	7
	jp	nz, mv30
mv26:
	call	TACTICS
mv30:
	call	SCAN
	ld	a, (INWK + 27)
	add	a, a
	add	a, a
	ld	(Q), a
	ld	a, (INWK + 10)
	ld	b, 0
	call	mv_nose
	ld	a, (INWK + 12)
	ld	b, 3
	call	mv_nose
	ld	a, (INWK + 14)
	ld	b, 6
	call	mv_nose
	ld	a, (INWK + 27)		; разгон, скорость в пределах 0..предел из модели
	ld	hl, INWK + 28
	add	a, (hl)
	jp	p, mv_sp
	ld	a, 0
mv_sp:
	ld	hl, (XX0)
	ld	de, 15
	add	hl, de
	cp	(hl)
	jp	c, mv_sp2
	ld	a, (hl)
mv_sp2:
	ld	(INWK + 27), a
	xor	a
	ld	(INWK + 28), a
	ifndef	SCHED
	ld	a, (ALP1)		; без крена K2 = y; без крена и тангажа поворота нет вовсе
	or	a
	jp	nz, mv_a1
	ld	a, (BET1)
	or	a
	jp	z, mv45
	ld	hl, (INWK + 3)
	ld	(K2 + 1), hl
	ld	(P_ + 1), hl
	ld	a, (INWK + 5)
	ld	(K2 + 3), a
	ld	a, l
	jp	mv_k2
mv_a1:
	endif
	ld	a, (ALP1)		; K2 = y - alpha · x
	ld	b, a
	ld	a, (INWK)
	cpl
	ld	(P_), a
	ld	a, (INWK + 1)
	call	MLTU2_2
	ld	(P_ + 2), a
	ld	a, (ALP2 + 1)
	ld	hl, INWK + 2
	xor	(hl)
	ld	b, 3
	call	MVT6
	ld	(K2 + 3), a
	ld	a, (P_ + 2)
	ld	(K2 + 2), a
	ld	a, (P_ + 1)
	ld	(K2 + 1), a
	ifndef	SCHED
	ld	a, (BET1)		; без тангажа z прежний, y = K2
	or	a
	jp	nz, mv_b1
	ld	hl, (K2 + 1)
	ld	(INWK + 3), hl
	ld	a, (K2 + 3)
	ld	(INWK + 5), a
	jp	mv44
mv_b1:
	ld	a, (K2 + 1)
mv_k2:
	endif
	cpl
	ld	(P_), a
	ld	a, (BET1)		; z = z + beta · K2
	ld	b, a
	ld	a, (P_ + 2)
	call	MLTU2_2
	ld	(P_ + 2), a
	ld	a, (K2 + 3)
	ld	hl, BET2
	xor	(hl)
	ld	b, 6
	call	MVT6
	ld	(INWK + 8), a
	ld	a, (P_ + 2)
	ld	(INWK + 7), a
	ld	a, (P_ + 1)
	ld	(INWK + 6), a
	cpl
	ld	(P_), a
	ld	a, (P_ + 2)
	call	MLTU2			; y = K2 - beta · z
	ld	(P_ + 2), a
	ld	a, (K2 + 3)
	ld	(INWK + 5), a
	ld	hl, BET2
	xor	(hl)
	ld	hl, INWK + 8
	xor	(hl)
	jp	p, mv43
	ld	hl, K2 + 1
	ld	a, (P_ + 1)
	add	a, (hl)
	ld	(INWK + 3), a
	inc	hl
	ld	a, (P_ + 2)
	adc	a, (hl)
	ld	(INWK + 4), a
	jp	mv44
mv43:
	ld	hl, P_ + 1		; на BBC здесь SBC с переносом 0: вычитается на единицу больше
	ld	a, (K2 + 1)
	scf
	sbc	a, (hl)
	ld	(INWK + 3), a
	inc	hl
	ld	a, (K2 + 2)
	sbc	a, (hl)
	ld	(INWK + 4), a
	jp	nc, mv44
	ld	hl, INWK + 3
	xor	a
	sub	(hl)
	ld	(hl), a
	inc	hl
	ld	a, 0
	sbc	a, (hl)
	ld	(hl), a
	inc	hl
	ld	a, (hl)
	xor	0x80
	ld	(hl), a
mv44:
	ifndef	SCHED
	ld	a, (ALP1)
	or	a
	jp	z, mv45
	endif
	ld	a, (ALP1)		; x = x + alpha · y
	ld	b, a
	ld	a, (INWK + 3)
	cpl
	ld	(P_), a
	ld	a, (INWK + 4)
	call	MLTU2_2
	ld	(P_ + 2), a
	ld	a, (ALP2)
	ld	hl, INWK + 5
	xor	(hl)
	ld	b, 0
	call	MVT6
	ld	(INWK + 2), a
	ld	a, (P_ + 2)
	ld	(INWK + 1), a
	ld	a, (P_ + 1)
	ld	(INWK), a
mv45:
	ld	a, (DELTA)		; z -= скорость игрока
	ld	(R_), a
	ld	a, 0x80
	ld	b, 6
	call	MVT1
	ifdef	PCIRC
	ld	a, (TYPE)		; планета — окружность: её ориентация не нужна (как и у солнца)
	or	a
	ret	m
	else
	ld	a, (TYPE)
	and	0x81
	cp	129
	ret	z
	endif
	ifndef	SCHED
	ld	a, (ALP1)		; полёт прямо (ни крена, ни тангажа): поворот — умножения на ноль
	ld	hl, BET1
	or	(hl)
	jp	z, mv_nors
	endif
	ld	c, 9
	call	MVS4
	ld	c, 15
	call	MVS4
	ld	c, 21
	call	MVS4
mv_nors:
	ld	hl, INWK + 30		; тангаж корабля
	call	mv_rat
	jp	z, mv8
	ld	bc, 0x0F09
	call	MVS5
	ld	bc, 0x110B
	call	MVS5
	ld	bc, 0x130D
	call	MVS5
mv8:
	ld	hl, INWK + 29		; крен корабля
	call	mv_rat
	jp	z, mv5
	ld	bc, 0x0F15
	call	MVS5
	ld	bc, 0x1117
	call	MVS5
	ld	bc, 0x1319
	call	MVS5
mv5:
	ld	hl, INWK + 31
	ld	a, (hl)
	and	0xA0
	jp	nz, mvd1
	ld	a, (hl)
	or	0x10
	ld	(hl), a
	jp	SCAN
mvd1:
	ld	a, (hl)
	and	0xEF
	ld	(hl), a
	ret
; сдвиг вдоль носа: A — старший байт составляющей nosev, B — координата (0, 3, 6), Q — скорость · 4
mv_nose:
	ld	d, a
	and	0x7F
	push	de
	call	FMLTU
	pop	de
	ld	(R_), a
	ld	a, d
	jp	MVT1_2
; счётчик вращения по адресу HL: RAT2 = знак; модуль убывает на 1 (127 — не убывает). Z — модуль нулевой.
mv_rat:
	ld	a, (hl)
	and	0x80
	ld	(RAT2), a
	ld	d, a
	ld	a, (hl)
	and	0x7F
	ret	z
	cp	0x7F
	jp	z, mv_rat2
	dec	a
mv_rat2:
	or	d
	ld	(hl), a
	or	1			; Z = 0
	ret
move_end:
