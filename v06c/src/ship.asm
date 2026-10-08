; Печать корабля: LL9 кассетной версии BBC, SHPPT (корабль-точка), LL155 (печать списка отрезков), EE51.
; Перенесено близко к тексту BBC, часть за частью; сравнение с эталоном — v06c/test/t09.mjs: экран обзора,
; блок корабля, список отрезков, куча вершин XX3, рабочие области. Регистры на выходе не определены.
; Указатели: XX0 — модель, XX19 — список отрезков корабля, INF — блок корабля, V — рабочий.
ship_start:

; EE51: если корабль на экране (бит 3 в XX1+31) — стереть его и сбросить бит.
EE51:
	ld	hl, XX1 + 31
	ld	a, (hl)
	and	0x08
	ret	z
	xor	(hl)
	ld	(hl), a
	jp	LL155

; SHPPT: корабль далеко — две чёрточки по четыре точки.
SHPPT:
	call	EE51
	call	PROJ
	ld	hl, K3 + 1
	or	(hl)
	jp	nz, nono
	ld	a, (K4)
	cp	190
	jp	nc, nono
	ld	hl, (XX19)
	inc	hl
	call	shpt
	jp	c, nono
	ld	a, (K4)
	inc	a
	call	shpt
	jp	c, nono
	ld	hl, XX1 + 31
	ld	a, (hl)
	or	0x08
	ld	(hl), a
	ld	a, 8
	jp	LL81_2
nono:
	ld	hl, XX1 + 31
	ld	a, (hl)
	and	0xF7
	ld	(hl), a
	ret
; отрезок (K3 + 3, A) – (K3, A) в список по адресу HL; CY — вышел за правый край
shpt:
	ld	d, a
	ld	a, (K3)
	ld	e, a
	inc	hl
	ld	(hl), d
	inc	hl
	ld	(hl), e
	inc	hl
	ld	(hl), d
	ld	a, e
	add	a, 3
	ret	c
	dec	hl
	dec	hl
	dec	hl
	ld	(hl), a
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ret

LL9:
	ld	a, (TYPE)
	or	a
	jp	m, PLANET
	cp	17
	jp	nz, ll9_vis
	ld	a, (XX1 + 31)		; Asp со скрывающим устройством: пока цел (энергия от 52), не взрывается
	and	0xE0			; и не стреляет — его не видно
	jp	nz, ll9_vis
	ld	a, (XX1 + 35)
	cp	52
	jp	nc, EE51
ll9_vis:
	ld	a, 31
	ld	(XX4), a
	ld	a, (XX1 + 31)
	ld	d, a
	and	0x20
	jp	nz, ee28
	ld	a, d
	or	a
	jp	p, ee28
	ld	a, d			; корабль убит: начать взрыв
	or	0x20
	and	0x3F
	ld	(XX1 + 31), a
	ld	hl, (INF)
	ld	de, 28
	add	hl, de
	ld	(hl), 0
	inc	hl
	inc	hl
	ld	(hl), 0
	ld	a, (XX1 + 31)		; перенос перед первым DORND — как на BBC: корабль на экране — после
	and	0x08			; стирания (LL155: число байт списка >= 4), иначе — тот, с которым LL9 вызвана
	jp	z, ee_inv
	call	EE51
	ld	a, (XX20)
	cp	4
	ccf
	jp	ee_sd
ee_inv:
	ld	a, (ll9_cy)
	rra
ee_sd:
	push	af
	ld	hl, (XX0)
	ld	de, 7
	add	hl, de
	ld	a, (hl)
	ld	hl, (XX19)
	inc	hl
	ld	(hl), 18
	inc	hl
	ld	(hl), a
	pop	af
	ld	c, 4
ee55:
	inc	hl
	push	hl
	call	DORND
	pop	hl
	ld	(hl), a
	or	a			; дальше перенос 0 (на BBC — после CPY #6)
	dec	c
	jp	nz, ee55
ee28:
	ld	a, (XX1 + 8)
	or	a
	jp	p, ll10
ll14:
	ld	a, (XX1 + 31)
	and	0x20
	jp	z, EE51
	ld	a, (XX1 + 31)
	and	0xF7
	ld	(XX1 + 31), a
	jp	DOEXP

; --- часть 2: виден ли корабль, на каком он расстоянии ---
ll10:
	ld	a, (XX1 + 7)
	cp	192
	jp	nc, ll14
	ld	hl, XX1 + 6
	ld	a, (XX1)
	cp	(hl)
	inc	hl
	ld	a, (XX1 + 1)
	sbc	a, (hl)
	jp	nc, ll14		; x >= z: вне угла зрения
	dec	hl
	ld	a, (XX1 + 3)
	cp	(hl)
	inc	hl
	ld	a, (XX1 + 4)
	sbc	a, (hl)
	jp	nc, ll14
	ld	hl, (XX0)
	ld	de, 6
	add	hl, de
	ld	l, (hl)
	ld	h, high XX3
	ld	(hl), 255
	inc	l
	ld	(hl), 255
	ld	hl, (XX1 + 6)		; z / 8
	ld	b, 3
ll10_sh:
	ld	a, h
	or	a
	rra
	ld	h, a
	ld	a, l
	rra
	ld	l, a
	dec	b
	jp	nz, ll10_sh
	ld	a, l
	ld	(T), a
	ld	a, h
	or	a
	rra
	ld	d, a
	ld	a, l
	rra
	ld	e, a
	ld	a, d
	or	a
	jp	nz, ll13
	ld	a, e			; XX4 = z / 128, не больше 31
	and	0xF8
	rrca
	rrca
	rrca
	ld	(XX4), a
	jp	ll17
ll13:
	ld	hl, (XX0)
	ld	de, 13
	add	hl, de
	ld	a, (XX1 + 7)
	ld	d, a
	ld	a, (hl)
	cp	d
	jp	nc, ll17
	ld	a, (XX1 + 31)
	and	0x20
	jp	nz, ll17
	jp	SHPPT

; --- часть 3: матрица ориентации в XX16, нормировка, положение в XX18 ---
ll17:
	ld	hl, XX1 + 21
	ld	de, XX16
	call	ll9_cp6
	ld	hl, XX1 + 15
	call	ll9_cp6
	ld	hl, XX1 + 9
	call	ll9_cp6
	ld	a, 197
	ld	(Q), a
	ld	hl, XX16 + 16
	ld	c, 9
ll21:
	ld	a, (hl)
	add	a, a
	inc	hl
	ld	a, (hl)
	rla
	dec	hl
	push	hl
	call	LL28
	pop	hl
	ld	a, (R_)
	ld	(hl), a
	dec	hl
	dec	hl
	dec	c
	jp	nz, ll21
	ld	hl, XX1
	ld	de, XX18
	ld	b, 9
	call	ll9_cp
	ld	a, 255
	ld	(XX2 + 15), a
	ld	hl, (XX0)
	ld	de, 12
	add	hl, de
	ld	a, (XX1 + 31)
	and	0x20
	jp	z, ee29
	ld	a, (hl)			; взрыв: все грани видимы
	rrca
	rrca
	and	0x3F
	ld	b, a
	inc	b
	ld	hl, XX2
ee30:
	ld	(hl), 255
	inc	hl
	dec	b
	jp	nz, ee30
	xor	a
	ld	(XX4), a
	jp	ll42

; --- части 4, 5: видимость граней ---
ee29:
	ld	a, (hl)
	or	a
	jp	z, ll42
	ld	(XX20), a
	ld	hl, (XX0)
	ld	de, 18
	add	hl, de
	ld	b, (hl)			; X — степень масштаба нормалей
	ld	a, (XX18 + 7)
	ld	d, a
ll90:
	ld	a, d
	or	a
	jp	z, ll91
	inc	b
	ld	hl, XX18 + 4
	call	ll9_shr16
	ld	hl, XX18 + 1
	call	ll9_shr16
	ld	a, d
	or	a
	rra
	ld	d, a
	ld	hl, XX18 + 6
	ld	a, (hl)
	rra
	ld	(hl), a
	jp	ll90
ll91:
	ld	a, b
	ld	(XX17), a
	call	ll9_18to15
	ld	a, (XX18 + 8)
	ld	(XX15 + 5), a
	call	LL51
	ld	hl, (XX12)
	ld	a, l
	ld	(XX18), a
	ld	a, h
	ld	(XX18 + 2), a
	ld	hl, (XX12 + 2)
	ld	a, l
	ld	(XX18 + 3), a
	ld	a, h
	ld	(XX18 + 5), a
	ld	hl, (XX12 + 4)
	ld	a, l
	ld	(XX18 + 6), a
	ld	a, h
	ld	(XX18 + 8), a
	ld	hl, (XX0)		; V -> нормали граней
	ld	de, 4
	add	hl, de
	ld	a, (hl)
	ld	de, 13
	add	hl, de
	ld	d, (hl)
	ld	e, a
	ld	hl, (XX0)
	add	hl, de
	ld	(V), hl
	ld	c, 0
ll86:
	ld	hl, (V)
	ld	b, 0
	add	hl, bc
	ld	a, (hl)
	ld	(XX12 + 1), a
	and	0x1F
	ld	d, a
	ld	a, (XX4)
	ld	e, a
	ld	a, d
	cp	e
	jp	nc, ll87
	ld	a, c			; грань видна на таком расстоянии всегда
	rrca
	rrca
	and	0x3F
	add	a, low XX2
	ld	e, a
	ld	d, high XX2
	ld	a, 255
	ld	(de), a
	ld	a, c
	add	a, 4
	ld	c, a
	jp	ll88
ll87:
	ld	a, (XX12 + 1)
	add	a, a
	ld	(XX12 + 3), a
	add	a, a
	ld	(XX12 + 5), a
	inc	hl
	ld	a, (hl)
	ld	(XX12), a
	inc	hl
	ld	a, (hl)
	ld	(XX12 + 2), a
	inc	hl
	ld	a, (hl)
	ld	(XX12 + 4), a
	inc	c
	inc	c
	inc	c
	ld	a, (XX17)
	ld	b, a
	cp	4
	jp	c, ll92
ll143:
	call	ll9_18to15
	ld	a, (XX18 + 8)
	ld	(XX15 + 5), a
	jp	ll89
ovflw:
	ld	hl, XX18
	call	ll9_lsr
	ld	hl, XX18 + 6
	call	ll9_lsr
	ld	hl, XX18 + 3
	call	ll9_lsr
	ld	b, 1
ll92:
	ld	a, (XX12)
	ld	h, a
	ld	a, (XX12 + 2)
	ld	l, a
	ld	a, (XX12 + 4)
	ld	d, a
	inc	b
ll93:
	dec	b
	jp	z, ll94_0
	ld	a, h
	or	a
	rra
	ld	h, a
	ld	a, l
	or	a
	rra
	ld	l, a
	ld	a, d
	or	a
	rra
	ld	d, a
	jp	ll93
ll94_0:
	ld	b, 0xFF			; на BBC X выходит из цикла равным FFh
	ld	a, h
	ld	(XX15), a
	ld	a, l
	ld	(XX15 + 2), a
	ld	a, d
	ld	(R_), a
	ld	a, (XX12 + 5)
	ld	(S), a
	ld	a, (XX18 + 6)
	ld	(Q), a
	ld	a, (XX18 + 8)
	call	LL38
	jp	c, ovflw
	ld	(XX15 + 4), a
	ld	a, (S)
	ld	(XX15 + 5), a
	ld	a, (XX15)
	ld	(R_), a
	ld	a, (XX12 + 1)
	ld	(S), a
	ld	a, (XX18)
	ld	(Q), a
	ld	a, (XX18 + 2)
	call	LL38
	jp	c, ovflw
	ld	(XX15), a
	ld	a, (S)
	ld	(XX15 + 1), a
	ld	a, (XX15 + 2)
	ld	(R_), a
	ld	a, (XX12 + 3)
	ld	(S), a
	ld	a, (XX18 + 3)
	ld	(Q), a
	ld	a, (XX18 + 5)
	call	LL38
	jp	c, ovflw
	ld	(XX15 + 2), a
	ld	a, (S)
	ld	(XX15 + 3), a
ll89:
	ld	a, (XX12)		; нормаль · направление на грань
	ld	(Q), a
	ld	a, (XX15)
	call	FMLTU
	ld	(T), a
	ld	a, (XX12 + 1)
	ld	hl, XX15 + 1
	xor	(hl)
	ld	(S), a
	ld	a, (XX12 + 2)
	ld	(Q), a
	ld	a, (XX15 + 2)
	call	FMLTU
	ld	(Q), a
	ld	a, (T)
	ld	(R_), a
	ld	a, (XX12 + 3)
	ld	hl, XX15 + 3
	xor	(hl)
	call	LL38
	ld	(T), a
	ld	a, (XX12 + 4)
	ld	(Q), a
	ld	a, (XX15 + 4)
	call	FMLTU
	ld	(Q), a
	ld	a, (T)
	ld	(R_), a
	ld	a, (XX15 + 5)
	ld	hl, XX12 + 5
	xor	(hl)
	call	LL38
	ld	d, a
	ld	a, c
	rrca
	rrca
	and	0x3F
	add	a, low XX2
	ld	l, a
	ld	h, high XX2
	ld	a, (S)
	or	a
	ld	a, d
	jp	m, ll89_v
	ld	a, 0
ll89_v:
	ld	(hl), a
	inc	c
ll88:
	ld	a, (XX20)
	ld	d, a
	ld	a, c
	cp	d
	jp	c, ll86

; --- части 6, 7: вершины ---
ll42:
	ld	hl, XX16 + 2		; транспонировать матрицу
	ld	de, XX16 + 6
	call	ll9_sw2
	ld	hl, XX16 + 4
	ld	de, XX16 + 12
	call	ll9_sw2
	ld	hl, XX16 + 10
	ld	de, XX16 + 14
	call	ll9_sw2
	ld	hl, (XX0)
	ld	de, 8
	add	hl, de
	ld	a, (hl)
	ld	(XX20), a
	ld	de, 12
	add	hl, de
	ld	(V), hl
	xor	a
	ld	(CNT), a
	ld	c, a
ll48:
	ld	a, c
	ld	(XX17), a
	ld	hl, (V)
	ld	b, 0
	add	hl, bc
	ld	a, (hl)
	ld	(XX15), a
	inc	hl
	ld	a, (hl)
	ld	(XX15 + 2), a
	inc	hl
	ld	a, (hl)
	ld	(XX15 + 4), a
	inc	hl
	ld	a, (hl)
	ld	(T), a
	and	0x1F
	ld	d, a
	ld	a, (XX4)
	ld	e, a
	ld	a, d
	cp	e
	jp	c, ll50
	inc	hl
	call	ll9_faces
	jp	nz, ll49
	inc	hl
	call	ll9_faces
	jp	z, ll50
ll49:
	ld	a, (T)
	ld	(XX15 + 1), a
	add	a, a
	ld	(XX15 + 3), a
	add	a, a
	ld	(XX15 + 5), a
	call	LL51
	ld	a, (XX1 + 2)		; x = x корабля + x вершины
	ld	(XX15 + 2), a
	ld	hl, XX12 + 1
	xor	(hl)
	jp	m, ll52
	ld	hl, XX1
	ld	a, (XX12)
	add	a, (hl)
	ld	(XX15), a
	inc	hl
	ld	a, (hl)
	adc	a, 0
	ld	(XX15 + 1), a
	jp	ll53
ll52:
	ld	hl, XX12
	ld	a, (XX1)
	sub	(hl)
	ld	(XX15), a
	ld	a, (XX1 + 1)
	sbc	a, 0
	ld	(XX15 + 1), a
	jp	nc, ll53
	cpl
	ld	(XX15 + 1), a
	ld	hl, XX15
	xor	a
	sub	(hl)
	ld	(hl), a
	jp	c, ll52_s
	inc	hl
	inc	(hl)
ll52_s:
	ld	hl, XX15 + 2
	ld	a, (hl)
	xor	0x80
	ld	(hl), a
ll53:
	ld	a, (XX1 + 5)		; y
	ld	(XX15 + 5), a
	ld	hl, XX12 + 3
	xor	(hl)
	jp	m, ll54
	ld	hl, XX1 + 3
	ld	a, (XX12 + 2)
	add	a, (hl)
	ld	(XX15 + 3), a
	inc	hl
	ld	a, (hl)
	adc	a, 0
	ld	(XX15 + 4), a
	jp	ll55
ll54:
	ld	hl, XX12 + 2
	ld	a, (XX1 + 3)
	sub	(hl)
	ld	(XX15 + 3), a
	ld	a, (XX1 + 4)
	sbc	a, 0
	ld	(XX15 + 4), a
	jp	nc, ll55
	cpl
	ld	(XX15 + 4), a
	ld	hl, XX15 + 3
	xor	a
	sub	(hl)
	ld	(hl), a
	push	af
	ld	hl, XX15 + 5
	ld	a, (hl)
	xor	0x80
	ld	(hl), a
	pop	af
	jp	c, ll55
	ld	hl, XX15 + 4
	inc	(hl)
ll55:
	ld	a, (XX12 + 5)		; z
	or	a
	jp	m, ll56
	ld	hl, XX1 + 6
	ld	a, (XX12 + 4)
	add	a, (hl)
	ld	c, a
	inc	hl
	ld	a, (hl)
	adc	a, 0
	ld	b, a
	jp	ll57
ll56:
	ld	hl, XX12 + 4
	ld	a, (XX1 + 6)
	sub	(hl)
	ld	c, a
	ld	a, (XX1 + 7)
	sbc	a, 0
	ld	b, a
	jp	c, ll140
	jp	nz, ll57
	ld	a, c
	cp	4
	jp	nc, ll57
ll140:
	ld	bc, 0x0004		; z не меньше 4
ll57:
	ld	hl, (XX15)		; x, y, z вправо, пока x и y не станут байтами, а z — байтом
	ex	de, hl
	ld	hl, (XX15 + 3)
ll57_l:
	ld	a, b
	or	d
	or	h
	jp	z, ll60
	ld	a, d
	or	a
	rra
	ld	d, a
	ld	a, e
	rra
	ld	e, a
	ld	a, h
	or	a
	rra
	ld	h, a
	ld	a, l
	rra
	ld	l, a
	ld	a, b
	or	a
	rra
	ld	b, a
	ld	a, c
	rra
	ld	c, a
	jp	ll57_l
ll60:
	ld	(XX15 + 3), hl
	ex	de, hl
	ld	(XX15), hl
	ld	a, b
	ld	(U), a
	ld	a, c
	ld	(T), a
	ld	(Q), a
	ld	d, a
	ld	a, (XX15)
	cp	d
	jp	c, ll69
	call	LL61
	jp	ll65
ll69:
	call	LL28
ll65:
	ld	a, (CNT)
	ld	l, a
	ld	h, high XX3
	ld	a, (XX15 + 2)
	or	a
	jp	m, ll62
	ld	a, (R_)
	add	a, 128
	ld	(hl), a
	inc	l
	ld	a, (U)
	adc	a, 0
	ld	(hl), a
	jp	ll66
ll62:
	ld	a, (R_)
	ld	d, a
	ld	a, 128
	sub	d
	ld	(hl), a
	inc	l
	ld	a, (U)
	ld	d, a
	ld	a, 0
	sbc	a, d
	ld	(hl), a
ll66:
	push	hl
	xor	a
	ld	(U), a
	ld	a, (T)
	ld	(Q), a
	ld	d, a
	ld	a, (XX15 + 3)
	cp	d
	jp	c, ll67
	call	LL61
	jp	ll68
ll67:
	call	LL28
ll68:
	pop	hl
	inc	l
	ld	a, (XX15 + 5)
	or	a
	jp	m, ll70
	ld	a, (R_)
	ld	d, a
	ld	a, 96
	sub	d
	ld	(hl), a
	inc	l
	ld	a, (U)
	ld	d, a
	ld	a, 0
	sbc	a, d
	ld	(hl), a
	jp	ll50
ll70:
	ld	a, (R_)
	add	a, 96
	ld	(hl), a
	inc	l
	ld	a, (U)
	adc	a, 0
	ld	(hl), a
ll50:
	ld	a, (CNT)
	add	a, 4
	ld	(CNT), a
	ld	a, (XX17)
	adc	a, 6
	ld	c, a
	jp	c, ll72
	ld	d, a
	ld	a, (XX20)
	ld	e, a
	ld	a, d
	cp	e
	jp	c, ll48

; --- части 8–12: лазер, рёбра, список отрезков ---
ll72:
	ld	a, (XX1 + 31)
	and	0x20
	jp	z, ee31
	ld	a, (XX1 + 31)
	or	0x08
	ld	(XX1 + 31), a
	jp	DOEXP
ee31:					; на BBC здесь прежние отрезки стираются (LL155) — и корабля нет на экране,
	xor	a			; пока считаются новые. Здесь прежний список копируется в сторону, а стирается
	ld	(ll_on), a		; в конце, по отрезку вслед за новым (ll155_ff): без мерцания, итог тот же
	ld	(ll_edge), a
	ld	(ll_lp), a
	ld	a, (XX1 + 31)
	and	0x08
	jp	z, ll74
	ld	hl, (XX19)
	ld	a, (hl)
	cp	4
	jp	c, ll74
	ld	b, a
	inc	b			; с байтом длины и байтом за списком (LL155 при длине 4 читает и его)
	ld	de, ll_sh
	call	ll9_cp
	ld	a, (ll_sh)
	add	a, 2
	rra
	or	a
	rra
	ld	(ll_on), a		; прежних отрезков
ll74:
	ld	hl, XX1 + 31
	ld	a, (hl)
	or	0x08
	ld	(hl), a
	ld	hl, (XX0)
	ld	de, 9
	add	hl, de
	ld	a, (hl)
	ld	(XX20), a
	xor	a
	ld	(XX17), a
	inc	a
	ld	(U), a
	ld	a, (XX1 + 31)
	and	0x40
	jp	z, ll170
	ld	a, (XX1 + 31)		; корабль стреляет: луч от вершины-пушки
	and	0xBF
	ld	(XX1 + 31), a
	ld	hl, (XX0)
	ld	de, 6
	add	hl, de
	ld	l, (hl)
	ld	h, high XX3
	ld	a, (hl)
	ld	(XX15), a
	ld	(ll_lx), a
	inc	a
	jp	z, ll_lab1		; вершины нет: в XX15 записан только x
	inc	l
	ld	a, (hl)
	ld	(XX15 + 1), a
	inc	a
	jp	z, ll_lab2		; записаны только x и y
	inc	l
	ld	a, (hl)
	ld	(XX15 + 2), a
	inc	l
	ld	a, (hl)
	ld	(XX15 + 3), a
	ld	a, 1
	ld	(ll_edge), a		; XX15 переписаны целиком
	xor	a
	ld	(XX15 + 4), a
	ld	(XX15 + 5), a
	ld	(XX12 + 1), a
	ld	a, (XX1 + 6)
	ld	(XX12), a
	ld	a, (XX1 + 2)
	or	a
	jp	p, ll9_las
	ld	a, 0xFF
	ld	(XX15 + 4), a
ll9_las:
	call	LL145
	call	nc, ll9_put
	jp	ll170
ll_lab1:
	ld	a, 1
	ld	(ll_lp), a
	jp	ll170
ll_lab2:
	ld	a, 2
	ld	(ll_lp), a
ll170:
	ld	hl, (XX0)		; V -> рёбра
	ld	de, 3
	add	hl, de
	ld	a, (hl)
	ld	de, 13
	add	hl, de
	ld	d, (hl)
	ld	e, a
	ld	hl, (XX0)
	add	hl, de
	ld	(V), hl
	ld	hl, (XX0)
	ld	de, 5
	add	hl, de
	ld	a, (hl)
	ld	(T1), a
ll75:
	ld	hl, (V)
	ld	a, (XX4)
	ld	d, a
	ld	a, (hl)
	cp	d
	jp	c, ll78
	inc	hl
	call	ll9_faces
	jp	z, ll78
	inc	hl
	ld	e, (hl)			; первая вершина
	inc	hl
	ld	a, (hl)
	ld	(Q), a
	ld	d, a			; вторая вершина
	ld	a, 1
	ld	(ll_edge), a		; с этого места XX15 пишут рёбра (см. ll155_ff)
	ld	h, high XX3
	ld	l, e
	ld	a, (hl)
	ld	(XX15), a
	inc	l
	ld	a, (hl)
	ld	(XX15 + 1), a
	inc	l
	ld	a, (hl)
	ld	(XX15 + 2), a
	inc	l
	ld	a, (hl)
	ld	(XX15 + 3), a
	ld	l, d
	ld	a, (hl)
	ld	(XX15 + 4), a
	inc	l
	ld	a, (hl)
	ld	(XX15 + 5), a
	inc	l
	ld	a, (hl)
	ld	(XX12), a
	inc	l
	ld	a, (hl)
	ld	(XX12 + 1), a
	ld	a, (XX15 + 5)
	call	LL147
	jp	c, ll78
	call	ll9_put
	ld	a, (T1)
	ld	d, a
	ld	a, (U)
	cp	d
	jp	nc, ll81
ll78:
	ld	hl, XX17
	inc	(hl)
	ld	a, (XX20)
	ld	d, a
	ld	a, (hl)
	cp	d
	jp	nc, ll81
	ld	hl, (V)
	ld	de, 4
	add	hl, de
	ld	(V), hl
	jp	ll75
ll81:
	ld	a, (U)
	ld	hl, (XX19)
	ld	(hl), a
	jp	ll155_ff
LL81_2:
	ld	hl, (XX19)
	ld	(hl), a

; LL155: напечатать (или стереть) отрезки корабля из списка XX19: байт 0 — длина списка, дальше по четыре байта.
; ll155_at — то же для списка по адресу HL.
LL155:
	ld	hl, (XX19)
ll155_at:
	ld	a, (hl)
	ld	(XX20), a
	cp	4
	ret	c
	inc	hl
	ld	a, 0xC9			; концы — в регистрах, ячейки X1..Y2 не трогать
	ld	(lo_swhook), a
	ld	c, 1
ll27:
	ld	a, c
	add	a, 4
	ld	c, a
	ld	a, (XX20)
	ld	d, a
	ld	a, c
	cp	d
	jp	nc, ll27_last
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	inc	hl
	ld	a, (hl)
	inc	hl
	push	hl
	ld	h, (hl)
	ld	l, a
	call	loin_r
	pop	hl
	inc	hl
	jp	ll27
ll27_last:				; последний отрезок — через ячейки: после LL155 в XX15 его концы, как на BBC
	ld	a, 0xC3
	ld	(lo_swhook), a
	ld	de, XX15
	ld	b, 4
	call	ll9_cp
	jp	LOIN

; ll155_ff: печать корабля без мерцания: новые отрезки (список XX19) рисуются, а прежние (копия ll_sh) стираются
; вперемежку — один новый, один прежний. Рисование — исключающее ИЛИ, от порядка итог не зависит: экран и
; рабочие области — как после «стереть всё, нарисовать всё» на BBC. Ячейки XX15 в конце — концы последнего
; нового отрезка; если рёбра не разбирались (ll_edge = 0), — как после стирания на BBC.
ll155_ff:
	ld	a, (ll_edge)
	or	a
	jp	nz, lf_mix
	ld	a, (ll_on)
	or	a
	jp	z, LL155
	ld	hl, ll_sh
	call	ll155_at
	ld	a, (ll_lp)		; луч без вершины: после стирания на BBC в XX15 успели записать x (и y = FFh)
	or	a
	jp	z, LL155
	ld	hl, ll_lx
	ld	b, (hl)
	ld	hl, XX15
	ld	(hl), b
	dec	a
	jp	z, LL155
	inc	hl
	ld	(hl), 0xFF
	jp	LL155
lf_mix:
	ld	hl, (XX19)
	ld	a, (hl)
	ld	(XX20), a
	inc	hl
	ld	(ll_np), hl
	cp	4
	jp	nc, lf_n
	xor	a
	jp	lf_n2
lf_n:
	add	a, 2
	rra
	or	a
	rra
lf_n2:
	ld	(ll_nn), a
	ld	hl, ll_sh + 1
	ld	(ll_op), hl
	ld	a, 0xC9			; концы — в регистрах, ячейки X1..Y2 не трогать
	ld	(lo_swhook), a
lf_l:
	ld	a, (ll_nn)
	or	a
	jp	z, lf_old
	dec	a
	ld	(ll_nn), a
	jp	z, lf_last
	ld	hl, (ll_np)
	call	lf_draw
	ld	(ll_np), hl
lf_old:
	ld	a, (ll_on)
	or	a
	jp	z, lf_chk
	dec	a
	ld	(ll_on), a
	ld	hl, (ll_op)
	call	lf_draw
	ld	(ll_op), hl
	jp	lf_l
lf_chk:
	ld	a, (ll_nn)
	or	a
	jp	nz, lf_l
	ld	a, 0xC3
	ld	(lo_swhook), a
	ret
lf_last:				; последний новый отрезок — через ячейки XX15, как на BBC
	ld	a, 0xC3
	ld	(lo_swhook), a
	ld	hl, (ll_np)
	ld	de, XX15
	ld	b, 4
	call	ll9_cp
	call	LOIN
	ld	a, 0xC9
	ld	(lo_swhook), a
	jp	lf_old
lf_draw:				; отрезок по адресу HL; на выходе HL — за ним
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	inc	hl
	ld	a, (hl)
	inc	hl
	push	hl
	ld	h, (hl)
	ld	l, a
	call	loin_r
	pop	hl
	inc	hl
	ret
ll_on:	db	0			; прежних отрезков осталось стереть
ll_nn:	db	0			; новых отрезков осталось нарисовать
ll_edge:	db	0		; рёбра уже писали XX15
ll_lp:	db	0			; луч: записан только x (1) или x и y (2)
ll_lx:	db	0
ll_np:	dw	0
ll_op:	dw	0

; перенос 6502 на входе LL9 из главного цикла полёта (бит 0) — нужен только при начале взрыва
ll9_cy:	db	0
; --- помощники ---
ll9_cp6:
	ld	b, 6
ll9_cp:					; B байт из HL в DE
	ld	a, (hl)
	ld	(de), a
	inc	hl
	inc	de
	dec	b
	jp	nz, ll9_cp
	ret
ll9_shr16:				; слово по адресу HL - 1 (HL — старший байт) вправо на бит
	ld	a, (hl)
	or	a
	rra
	ld	(hl), a
	dec	hl
	ld	a, (hl)
	rra
	ld	(hl), a
	ret
ll9_lsr:
	ld	a, (hl)
	or	a
	rra
	ld	(hl), a
	ret
ll9_sw2:				; поменять два байта по HL и по DE
	ld	b, 2
ll9_sw:
	ld	a, (de)
	ld	c, (hl)
	ld	(hl), a
	ld	a, c
	ld	(de), a
	inc	hl
	inc	de
	dec	b
	jp	nz, ll9_sw
	ret
ll9_18to15:				; XX15(4..0) = XX18, XX18+2, XX18+3, XX18+5, XX18+6
	ld	a, (XX18)
	ld	(XX15), a
	ld	hl, (XX18 + 2)
	ld	(XX15 + 1), hl
	ld	hl, (XX18 + 5)
	ld	(XX15 + 3), hl
	ret
; HL -> байт с двумя номерами граней: P = байт; NZ — хотя бы одна видима
ll9_faces:
	ld	a, (hl)
	ld	(P_), a
	ld	d, a
	and	0x0F
	add	a, low XX2
	ld	e, a
	ld	a, d
	ld	d, high XX2
	ex	de, hl
	ld	b, (hl)
	ex	de, hl
	inc	b
	dec	b
	ret	nz
	rrca
	rrca
	rrca
	rrca
	and	0x0F
	add	a, low XX2
	ld	e, a
	ld	a, (de)
	or	a
	ret
; отрезок XX15(3..0) в конец списка, U += 4
ll9_put:
	ld	hl, (XX19)
	ld	a, (U)
	ld	e, a
	ld	d, 0
	add	hl, de
	add	a, 4
	ld	(U), a
	ex	de, hl
	ld	hl, XX15
	ld	b, 4
	jp	ll9_cp
ship_end:
