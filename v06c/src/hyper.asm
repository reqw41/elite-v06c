; Прыжки: hyp (клавиша H), отсчёт ee3, wW, галактический прыжок Ghy, zZ, прибытие TT18, сбой прыжка MJP, новая
; система SOLAR, туннель LL164, прыжок внутри системы WARP (клавиша J), спасательная капсула ESCAPE, CTRL.
; Перенесено близко к тексту BBC (вариант кассеты, как в эталоне). Сверка — сценарий jump (v06c/test/t27.mjs jump).

; CTRL: нажата ли CTRL (на Векторе — УС): знак A.
CTRL:
	ld	b, 1
	jp	DKS4

; hyp: начать прыжок к выбранной системе: проверить дальность и топливо, напечатать название, запустить отсчёт.
hyp:
	ld	a, (QQ12)
	or	a
	jp	nz, hy6
	ld	a, (QQ22 + 1)
	or	a
	ret	nz			; отсчёт уже идёт
	call	CTRL
	jp	m, Ghy
	call	hm
	ld	hl, (QQ8)
	ld	a, h
	or	l
	ret	z
	ld	a, 7
	ld	(XC), a
	ld	a, 23
	ld	(YC), a
	xor	a
	ld	(QQ17), a
	ld	a, 189
	call	TT27
	ld	a, (QQ8 + 1)
	or	a
	jp	nz, TT147
	ld	a, (QQ8)
	ld	d, a
	ld	a, (QQ14)
	cp	d
	jp	c, TT147
	ld	a, '-'
	call	TT27
	call	cpl_
wW:
	ld	a, 15
	ld	(QQ22 + 1), a
	ld	(QQ22), a
	ld	b, a
; ee3: число X в левом верхнем углу (отсчёт перед прыжком).
ee3:
	ld	a, 1
	ld	(YC), a
	xor	a
	ld	(XC), a
	ld	c, a
	jp	pr6
hy6:					; на станции: «Docked»
	call	CLYNS
	ld	a, 15
	ld	(XC), a
	jp	TT27
TT147:					; «RANGE?»
	ld	a, 202
	jp	prq

; Ghy: галактический прыжок (CTRL + H при наличии привода): семена галактики поворачиваются на бит.
Ghy:
	ld	a, (GHYP)
	or	a
	ret	z
	inc	a
	ld	(GHYP), a
	ld	(FIST), a
	call	wW
	ld	hl, GCNT
	ld	a, (hl)
	inc	a
	and	7
	ld	(hl), a
	ld	hl, QQ21
	ld	b, 6
g1:
	ld	a, (hl)
	rlca
	ld	(hl), a
	inc	hl
	dec	b
	jp	nz, g1
zZ:
	ld	a, 96
	ld	(QQ9), a
	ld	(QQ10), a
	call	TT110
	call	TT111
	ld	hl, 0
	ld	(QQ8), hl
	ld	a, 116
	call	MESS
	jp	jmp

; LL164: туннель прыжка.
LL164:
	ld	a, 56
	call	NOISE
	ld	a, 1
	ld	(HFX), a
	ld	a, 4
	call	HFS2
	ld	hl, HFX
	dec	(hl)
	ret

; TT18: прибытие: топливо, туннель, новая система (или сбой прыжка — MJP), вид вперёд.
TT18:
	ld	a, (QQ8)
	ld	d, a
	ld	a, (QQ14)
	sub	d
	ld	(QQ14), a
	ld	a, (QQ11)
	or	a
	jp	nz, ee5
	call	TT66
	call	LL164
ee5:
	call	CTRL
	ld	hl, PATG
	and	(hl)
	jp	m, ptg
	scf				; перенос 6502 здесь всегда 1
	call	DORND
	cp	253
	jp	nc, MJP
	call	hyp1_3
	or	a
	call	GVL
	call	RES2
	call	SOLAR
	ld	a, (QQ11)
	and	0x3F
	ret	nz
	call	TTX66
	ld	a, (QQ11)
	or	a
	jp	nz, TT114
	inc	a
	ld	(QQ11), a
	jp	TT110
ptg:					; сбой прыжка по заказу (PATG и CTRL): отметка в COK
	ld	hl, COK
	ld	a, (hl)
	or	1
	ld	(hl), a
MJP:					; сбой прыжка: межзвёздное пространство, таргоиды
	ld	a, 1
	call	TT66
	call	LL164
	call	RES2
	ld	a, 0xFF
	ld	(MJ), a
	or	a
mjp1:
	call	GTHG
	ld	a, (MANY + 6)
	ld	d, a
	ld	a, 3
	cp	d
	jp	c, mjp_e
	scf
	jp	mjp1
mjp_e:
	ld	(NOSTM), a
	ld	b, 0
	call	LOOK1
	ld	a, (QQ1)
	xor	0x1F
	ld	(QQ1), a
	ret

; SOLAR: новая система: розыск вдвое меньше, планета и солнце по семенам QQ15, новая пыль.
SOLAR:
	call	ZINF
	ld	hl, FIST
	ld	a, (hl)
	or	a
	rra
	ld	(hl), a
	push	af
	ld	a, (QQ15 + 1)
	and	7
	ld	d, a
	pop	af
	ld	a, d
	adc	a, 6
	rra
	ld	(INWK + 8), a
	rra
	ld	(INWK + 2), a
	ld	(INWK + 5), a
	call	SOS1
	ld	a, (QQ15 + 3)
	and	7
	or	0x81
	ld	(INWK + 8), a
	ld	a, (QQ15 + 5)
	and	3
	ld	(INWK + 2), a
	ld	(INWK + 1), a
	xor	a
	ld	(INWK + 29), a
	ld	(INWK + 30), a
	ld	a, 129
	call	NWSHP
	jp	NWSTARS

; WARP: прыжок внутри системы — если рядом нет кораблей и станции и мы не вплотную к планете или солнцу.
WARP:
	ld	a, (MANY + 10)
	ld	hl, MANY + 13
	add	a, (hl)
	ld	hl, MANY + 11
	adc	a, (hl)
	ld	e, a
	ld	d, 0
	ld	hl, FRIN + 2
	add	hl, de
	ld	a, (hl)
	ld	hl, SSPR
	or	(hl)
	ld	hl, MJ
	or	(hl)
	jp	nz, wa1
	ld	a, (K_ + 8)
	or	a
	jp	m, wa3
	xor	a
	ld	c, a
	call	MAS2
	and	0xFE
	jp	z, wa1
wa3:
	ld	a, (K_ + NI + 8)
	or	a
	jp	m, wa2
	xor	a
	ld	c, NI
	call	MAS2
	and	0xFE
	jp	z, wa1
wa2:
	ld	a, 0x81
	ld	(S), a
	ld	(R_), a
	ld	(P_), a
	ld	a, (K_ + 8)
	call	ADD
	ld	(K_ + 8), a
	ld	a, (K_ + NI + 8)
	call	ADD
	ld	(K_ + NI + 8), a
	ld	a, 1
	ld	(QQ11), a
	ld	(MCNT), a
	xor	a
	ld	(EV), a
	ld	a, (VIEW)
	ld	b, a
	jp	LOOK1
wa1:
	ld	a, 40
	jp	NOISE

; ESCAPE: спасательная капсула: наш корабль улетает вперёд, мы оказываемся на станции без груза и розыска.
ESCAPE:
	ld	a, (MJ)
	push	af
	call	RES2
	ld	a, 7
	ld	(TYPE), a
	ld	b, a
	call	FRS1
	ld	a, 8
	ld	(INWK + 27), a
	ld	a, 194
	ld	(INWK + 30), a
	ld	a, 97
	ld	(INWK + 32), a
esl1:
	call	MVEIT
	call	LL9
	ld	hl, INWK + 32
	dec	(hl)
	jp	nz, esl1
	call	SCAN
	call	RESET
	pop	af
	or	a
	jp	nz, DEATH		; в межзвёздном пространстве капсула не спасает
	ld	hl, QQ20
	ld	b, 17
esl2:
	ld	(hl), a
	inc	hl
	dec	b
	jp	nz, esl2
	ld	(FIST), a
	ld	(ESCP), a
	ld	a, 70
	ld	(QQ14), a
	jp	BAY
