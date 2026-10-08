; Автопилот стыковки — из дисковой версии BBC (в кассетной стыковочный компьютер стыкует сразу): DOCKIT, VCSU1,
; TAS4, TAS6, DCS1, TAS7, седьмая часть TACTICS в дисковом виде (TA151, nroll — с RAT, RAT2, CNT2) и кусок DOKEY,
; который превращает решения DOCKIT в нажатия клавиш. Эталон — полётный код дисковой версии (tools/oracle/disc.js),
; сверка — v06c/test/dockit.mjs. Чужие корабли в станцию не заходят: флагов NEWB в блоке корабля здесь нет.

; dk_auto (DOKEY, auton): корабль игрока — как чужой корабль в INWK; DOCKIT решает, клавиши «нажимаются».
dk_auto:
	call	ZINF
	ld	a, 96
	ld	(INWK + 14), a
	or	0x80
	ld	(INWK + 22), a
	ld	(TYPE), a
	ld	a, (DELTA)
	ld	(INWK + 27), a
	call	DOCKIT
	ld	a, (INWK + 27)
	cp	22
	jp	c, dk_sp
	ld	a, 22
dk_sp:
	ld	(DELTA), a
	ld	a, (INWK + 28)
	or	a
	jp	z, dk11
	ld	hl, KY1
	jp	m, dk10
	inc	hl
dk10:
	ld	(hl), 0xFF
dk11:
	ld	hl, INWK + 29
	ld	a, (hl)
	add	a, a
	ld	(hl), a
	ld	a, 128
	jp	z, dk12
	ld	hl, KY3
	jp	nc, dk11a
	inc	hl
dk11a:
	ld	a, (INWK + 29)
	or	a
	jp	p, dk14
	ld	a, 64
	ld	(JSTX), a
	ld	(hl), 0
	jp	dk12x
dk14:
	ld	(hl), 128
	jp	dk12x
dk12:
	ld	(JSTX), a
dk12x:
	ld	hl, INWK + 30
	ld	a, (hl)
	add	a, a
	ld	(hl), a
	ld	a, 128
	jp	z, dk13
	ld	hl, KY5
	jp	c, dk13a
	inc	hl
dk13a:
	ld	(hl), a
	ret
dk13:
	ld	(JSTY), a
	ret

; DOCKIT: корабль в INWK летит к станции и входит в щель; TYPE с битом 7 — это мы сами.
DOCKIT:
	ld	a, 6
	ld	(RAT2), a
	ld	a, 3
	ld	(RAT), a
	ld	a, 29
	ld	(CNT2), a
	ld	a, (SSPR)
	or	a
	jp	z, dk_gopl
	call	VCSU1
	ld	a, (K3 + 2)
	ld	hl, K3 + 5
	or	(hl)
	ld	hl, K3 + 8
	or	(hl)
	and	0x7F
	jp	nz, dk_gopl
	call	ta2
	ld	a, (Q)
	ld	(K), a
	call	TAS2
	ld	c, 10
	call	TAS4
	or	a
	jp	m, dk_ph1
	cp	35
	jp	c, dk_ph1
	ld	c, 10
	call	TAS3
	cp	0xA2
	jp	nc, dk_ph3
	ld	a, (K)
	cp	157
	jp	c, dk_ph2
	ld	a, (TYPE)
	or	a
	jp	m, dk_ph3
dk_ph2:
	call	TAS6
	call	dk_ta151
dk_ph22:
	xor	a
	ld	(INWK + 28), a
	inc	a
	ld	(INWK + 27), a
	ret
dk_ph1:
	call	VCSU1
	call	DCS1
	call	DCS1
	call	TAS2
	call	TAS6
	jp	dk_ta151
dk_gopl:
	call	SPS1
	jp	dk_ta151
dk_tn11:
	ld	hl, INWK + 28
	inc	(hl)
	ld	a, 0x7F
	ld	(INWK + 29), a
	ret
dk_ph3:
	xor	a
	ld	(RAT2), a
	ld	(INWK + 30), a
	ld	a, (TYPE)
	or	a
	jp	p, dk_ph32
	ld	hl, XX15
	xor	(hl)
	inc	hl
	xor	(hl)
	rla
	ld	a, 2
	rra
	ld	(INWK + 29), a
	ld	a, (XX15)
	add	a, a
	cp	12
	jp	nc, dk_ph22
	ld	a, (XX15 + 1)
	rla
	ld	a, 2
	rra
	ld	(INWK + 30), a
	ld	a, (XX15 + 1)
	add	a, a
	cp	12
	jp	nc, dk_ph22
dk_ph32:
	xor	a
	ld	(INWK + 29), a
	ld	a, (INWK + 22)
	ld	(XX15), a
	ld	a, (INWK + 24)
	ld	(XX15 + 1), a
	ld	a, (INWK + 26)
	ld	(XX15 + 2), a
	ld	c, 16
	call	TAS4
	add	a, a
	cp	66
	jp	nc, dk_tn11
	jp	dk_ph22

; VCSU1: K3 = вектор от корабля INWK до станции.
VCSU1:
	ld	hl, K_ + NI
	ld	(V), hl
	ld	c, 2
	call	TAS1
	ld	c, 5
	call	TAS1
	ld	c, 8
	jp	TAS1
; TAS4: скалярное произведение XX15 на вектор станции K%+NI%+Y, +2, +4 (как TAS3 для INWK).
TAS4:
	push	bc
	ld	hl, K_ + NI
	jp	tas3_hl
; TAS6: обратить вектор XX15.
TAS6:
	ld	hl, XX15
	ld	b, 3
tas6_l:
	ld	a, (hl)
	xor	0x80
	ld	(hl), a
	inc	hl
	dec	b
	jp	nz, tas6_l
	ret
; DCS1: K3 += нос станции · 4 (точка перед щелью). TAS7: слагаемое A · 2 к составляющей по адресу HL.
DCS1:
	call	dcs_1
dcs_1:
	ld	a, (K_ + NI + 10)
	ld	hl, K3
	call	TAS7
	ld	a, (K_ + NI + 12)
	ld	hl, K3 + 3
	call	TAS7
	ld	a, (K_ + NI + 14)
	ld	hl, K3 + 6
TAS7:
	add	a, a
	ld	e, a
	ld	a, 0
	rra
	xor	0x80
	inc	hl
	inc	hl
	xor	(hl)
	dec	hl
	dec	hl
	jp	m, ts71
	ld	a, (hl)
	add	a, e
	ld	(hl), a
	ret	nc
	inc	hl
	inc	(hl)
	ret
ts71:
	ld	a, (hl)
	sub	e
	ld	(hl), a
	inc	hl
	ld	a, (hl)
	sbc	a, 0
	ld	(hl), a
	ret	nc
	dec	hl
	ld	a, (hl)
	cpl
	add	a, 1
	ld	(hl), a
	inc	hl
	ld	a, (hl)
	cpl
	adc	a, 0
	ld	(hl), a
	inc	hl
	ld	a, (hl)
	xor	0x80
	ld	(hl), a
	ret

; dk_ta151 (TA151 и седьмая часть TACTICS дисковой версии): повернуть корабль к направлению XX15.
dk_ta151:
	ld	c, 10
	call	TAS3
	cp	0x98
	jp	c, dk_ttt
	ld	d, a
	xor	a
	ld	(RAT2), a
	ld	a, d
dk_ttt:
	ld	(CNT), a
	ld	c, 16
	call	TAS3
	ld	d, a
	call	dk_nroll
	ld	(INWK + 30), a
	ld	a, (INWK + 29)
	add	a, a
	cp	32
	jp	nc, dk_ta6
	ld	c, 22
	call	TAS3
	ld	d, a
	ld	hl, INWK + 30
	xor	(hl)
	call	dk_nroll
	ld	(INWK + 29), a
dk_ta6:
	ld	a, (CNT)
	or	a
	jp	m, dk_ta9
	ld	hl, CNT2
	cp	(hl)
	jp	c, dk_ta9
	ld	a, 3
	ld	(INWK + 28), a
	ret
dk_ta9:
	and	0x7F
	cp	18
	ret	c
	ld	a, 0xFF
	ld	(INWK + 28), a
	ret
dk_nroll:				; знак — обратный знаку A; величина RAT, если |D| · 2 не меньше RAT2
	xor	0x80
	and	0x80
	ld	e, a
	ld	a, d
	add	a, a
	ld	hl, RAT2
	cp	(hl)
	ld	a, e
	ret	c
	ld	hl, RAT
	or	(hl)
	ret
