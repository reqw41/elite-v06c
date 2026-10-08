; Тактика кораблей: TACTICS (семь частей BBC), TAS1, TAS3, пуск ракет FRS1, FRMIS, SFRMIS, появление корабля
; рядом с другим SFS1, SFS2, SESCP, злость ANGRY. Перенесено близко к тексту BBC.
; Сверка — сценарий fight (v06c/test/t27.mjs fight) и парные тесты v06c/test/t36.mjs.
; Перенос перед каждым вызовом DORND выставлен как на BBC: от него зависит случайное число.

; TAS1: K3+X.. = координата корабля из блока по адресу V (байты Y-2..Y, знак обращён) + координата INWK+X..,
; где X = Y - 2. На выходе X = Y = U = Y - 2, перенос — как у MVT3.
TAS1:
	ld	hl, (V)
	ld	b, 0
	add	hl, bc
	ld	a, (hl)
	xor	0x80
	ld	(K + 3), a
	dec	hl
	ld	a, (hl)
	ld	(K + 2), a
	dec	hl
	ld	a, (hl)
	ld	(K + 1), a
	dec	c
	dec	c
	ld	a, c
	ld	(U), a
	ld	b, a
	call	MVT3
	push	af
	ld	a, (U)
	ld	b, a
	ld	c, a
	ld	e, a
	ld	d, 0
	ld	hl, K3 + 2
	add	hl, de
	pop	af
	push	af
	ld	(hl), a
	dec	hl
	ld	a, (K + 2)
	ld	(hl), a
	dec	hl
	ld	a, (K + 1)
	ld	(hl), a
	pop	af
	ld	a, (K + 1)
	ret

; TAS3: (A X) = скалярное произведение XX15 на вектор INWK+Y, +2, +4 (старшие байты). Y сохраняется.
TAS3:
	push	bc
	ld	hl, INWK
	ld	b, 0
	add	hl, bc
	push	hl
	ld	a, (hl)
	ld	(Q), a
	ld	a, (XX15)
	call	MULT12
	pop	hl
	inc	hl
	inc	hl
	push	hl
	ld	a, (hl)
	ld	(Q), a
	ld	a, (XX15 + 1)
	call	MAD
	ld	(S), a
	ld	a, b
	ld	(R_), a
	pop	hl
	inc	hl
	inc	hl
	ld	a, (hl)
	ld	(Q), a
	ld	a, (XX15 + 2)
	call	MAD
	pop	hl
	ld	c, l
	ret

; --- TACTICS, часть 1: ракета ---
TA34:					; ракета летит в нас: рядом — взрыв и урон 250
	xor	a
	call	MAS4
	jp	nz, TA21
	call	ta87_3
	call	EXNO3
	ld	a, 250
	or	a			; перенос 6502 после EXNO3 равен 0
	jp	OOPS
TA18:
	ld	a, (ECMA)
	or	a
	jp	nz, ta35_c1		; ECM работает: ракета гибнет (перенос 6502 = 1 после CPX #MSL)
	ld	a, (INWK + 32)
	add	a, a
	jp	m, TA34
	or	a
	rra
	ld	e, a			; место цели · 2
	ld	d, 0
	ld	hl, UNIV
	add	hl, de
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a
	ld	(V), hl
	ld	c, 2
	call	TAS1
	ld	c, 5
	call	TAS1
	ld	c, 8
	call	TAS1
	push	af			; перенос последней MVT3 идёт в DORND
	ld	a, (K3 + 2)
	ld	hl, K3 + 5
	or	(hl)
	ld	hl, K3 + 8
	or	(hl)
	and	0x7F
	ld	hl, K3 + 1
	or	(hl)
	ld	hl, K3 + 4
	or	(hl)
	ld	hl, K3 + 7
	or	(hl)
	jp	nz, TA64
	pop	af
	ld	a, (INWK + 32)
	cp	0x82
	jp	z, ta35_c1
	ccf				; перенос 6502: INWK+32 >= 82h
	push	af
	ld	hl, (V)
	ld	de, 31
	add	hl, de
	ld	a, (hl)
	ld	d, a
	and	32
	jp	nz, ta35_p
	ld	a, d
	or	0x80
	ld	(hl), a
ta35_p:
	pop	af
	jp	TA35
ta35_c1:
	scf
TA35:					; перенос = перенос 6502
	push	af
	ld	a, (INWK)
	ld	hl, INWK + 3
	or	(hl)
	ld	hl, INWK + 6
	or	(hl)
	jp	nz, ta87_p
	pop	af
	ld	a, 80
	call	OOPS
	jp	TA87
ta87_p:
	pop	af
TA87:
	call	EXNO2
ta87_3:
	ld	hl, INWK + 31
	ld	a, (hl)
	or	0x80
	ld	(hl), a
	ret
TA64:
	pop	af
	call	DORND
	cp	16
	jp	nc, TA19
	ld	hl, (V)
	ld	de, 32
	add	hl, de
	ld	a, (hl)
	rra
	jp	nc, TA19
	jp	ECBLB2

; --- TACTICS: X (регистр B) = тип корабля, блок — в INWK ---
TACTICS:
	ld	a, b
	cp	9
	jp	z, TA18
	cp	13
	jp	nz, ta_nesc
	call	SPS1			; спасательная капсула летит к планете
	jp	TA15
ta_nesc:
	cp	8
	jp	nz, TA13
	scf				; станция: иногда выпускает полицию
	call	DORND
	cp	140
	ret	c
	ld	a, (MANY + 2)
	cp	4
	ret	nc
	ld	b, 2
	ld	a, 0xF1
	jp	SFS1
TA13:
	cp	12
	jp	nz, TA14
	ld	a, (MANY + 6)
	or	a
	jp	nz, TA14
	ld	hl, INWK + 32		; таргон без носителя: без тактики, тормозит
	ld	a, (hl)
	and	0xFE
	ld	(hl), a
	ld	hl, INWK + 27
	ld	a, (hl)
	or	a
	rra
	ld	(hl), a
	ret
TA14:
	ld	a, b
	cp	NTY + 1
	jp	nc, ta14_p		; корабли версии ZX — пираты
	cp	7
	jp	nc, TA62
ta14_p:
	cp	2
	jp	z, TA62
	ld	a, (SSPR)
	or	a
	jp	z, TA62
	ld	hl, INWK + 32		; пираты у станции не нападают
	ld	a, (hl)
	and	0x81
	ld	(hl), a
TA62:
	ld	hl, (XX0)
	ld	de, 14
	add	hl, de
	ld	a, (INWK + 35)
	cp	(hl)
	jp	nc, TA21
	inc	a
	ld	(INWK + 35), a
TA21:
	ld	hl, INWK
	ld	de, K3
	ld	b, 9
tal1:
	ld	a, (hl)
	ld	(de), a
	inc	hl
	inc	de
	dec	b
	jp	nz, tal1
TA19:
	call	TAS2
	ld	c, 10
	call	TAS3
	ld	(CNT), a
	ld	a, (TYPE)
	cp	9
	jp	z, TA20
	ccf				; перенос 6502 после CMP #MSL
	call	DORND
	cp	250
	jp	c, TA7
	scf
	call	DORND
	or	104
	ld	(INWK + 29), a
TA7:
	ld	hl, (XX0)
	ld	de, 14
	add	hl, de
	ld	a, (hl)
	or	a
	rra
	ld	hl, INWK + 35
	cp	(hl)
	jp	c, TA3
	or	a
	rra
	or	a
	rra
	cp	(hl)
	jp	c, ta3_c0
	scf
	call	DORND
	cp	230
	jp	c, ta3_c0
	ld	a, (TYPE)
	cp	6
	jp	z, ta3_c1
	xor	a			; мало энергии: бросить корабль, выпустить капсулу
	ld	(INWK + 32), a
	jp	SESCP
ta3_c1:
	scf
	jp	ta3
ta3_c0:
	or	a
ta3:					; перенос = перенос 6502
	push	af
	ld	a, (INWK + 31)
	and	7
	jp	z, ta3_none
	ld	(T), a
	pop	af
	call	DORND
	and	31
	ld	hl, T
	cp	(hl)
	jp	nc, TA3
	ld	a, (ECMA)
	or	a
	jp	nz, TA3
	ld	hl, INWK + 31
	dec	(hl)
	ld	a, (TYPE)
	cp	6
	jp	nz, SFRMIS
	ld	b, 12			; таргоид выпускает таргон
	ld	a, (INWK + 32)
	jp	SFS1
ta3_none:
	pop	af
TA3:
	xor	a
	call	MAS4
	and	0xE0
	jp	nz, TA4
	ld	a, (CNT)
	ld	b, a
	cp	160
	jp	c, TA4
	ld	hl, INWK + 31
	ld	a, (hl)
	or	0x40
	ld	(hl), a
	ld	a, b
	cp	163
	jp	c, TA4
	ld	hl, (XX0)		; HIT: попали в нас
	ld	de, 19
	add	hl, de
	ld	a, (hl)
	or	a
	rra
	call	OOPS
	ld	hl, INWK + 28
	dec	(hl)
	ld	a, (ECMA)
	or	a
	ret	nz
	ld	a, 8
	jp	NOISE
TA4:
	ld	a, (INWK + 7)
	cp	3
	jp	nc, ta5_c1
	ld	a, (INWK + 1)
	ld	hl, INWK + 4
	or	(hl)
	and	0xFE
	jp	z, TA15
	jp	TA5			; перенос 0
ta5_c1:
	scf
TA5:
	call	DORND
	or	0x80
	ld	hl, INWK + 32
	cp	(hl)
	jp	nc, TA15
TA20:
	ld	hl, XX15
	ld	a, (hl)
	xor	0x80
	ld	(hl), a
	inc	hl
	ld	a, (hl)
	xor	0x80
	ld	(hl), a
	inc	hl
	ld	a, (hl)
	xor	0x80
	ld	(hl), a
	ld	hl, CNT
	ld	a, (hl)
	xor	0x80
	ld	(hl), a
TA15:
	ld	c, 16
	call	TAS3
	xor	0x80
	and	0x80
	or	3
	ld	(INWK + 30), a
	ld	a, (INWK + 29)
	and	0x7F
	cp	16
	jp	nc, TA6
	ld	c, 22
	call	TAS3
	ld	hl, INWK + 30
	xor	(hl)
	and	0x80
	xor	0x85
	ld	(INWK + 29), a
TA6:
	ld	a, (CNT)
	or	a
	jp	m, TA9
	cp	22
	jp	c, TA9
	ld	a, 3
	ld	(INWK + 28), a
	ret
TA9:
	and	0x7F
	cp	18
	ret	c
	ld	a, (TYPE)
	cp	9
	ld	a, 0xFF
	jp	nz, ta9_s
	ld	a, 0xFE
ta9_s:
	ld	(INWK + 28), a
	ret

; FRS1: завести ракету или капсулу типа X перед нашим кораблём: перенос 1 — заведена.
; fq1: то же с готовым положением в INWK; скорость = DELTA · 2 + перенос на входе.
FRS1:
	push	bc
	call	ZINF
	pop	bc
	ld	a, 28
	ld	(INWK + 3), a
	ld	a, 14
	ld	(INWK + 6), a
	ld	a, 0x80
	ld	(INWK + 5), a
	ld	a, (MSTG)
	add	a, a
	push	af
	or	0x80
	ld	(INWK + 32), a
	pop	af
fq1:
	ld	a, 0x60
	ld	(INWK + 14), a
	ld	a, 0xE0
	ld	(INWK + 22), a
	ld	a, (DELTA)
	rla
	ld	(INWK + 27), a
	ld	a, b
	jp	NWSHP

; FRMIS: пуск нашей ракеты по захваченной цели.
FRMIS:
	ld	b, 9
	call	FRS1
	jp	nc, fr1
	ld	a, (MSTG)
	ld	b, a
	call	GINF
	ld	e, b
	ld	d, 0
	ld	hl, FRIN
	add	hl, de
	ld	a, (hl)
	call	ANGRY
	ld	c, 0
	call	ABORT
	ld	hl, NOMSL
	dec	(hl)
	ld	a, 48
	jp	NOISE
fr1:
	ld	a, 201
	jp	MESS

; ANGRY: корабль типа A (блок по адресу INF) становится враждебным; станция — тоже (AN2).
; Перенос на выходе — как на BBC: 1 при типе больше 8.
ANGRY:
	cp	NTY + 1
	jp	c, an_bbc
	cp	NTY + 4
	jp	c, an_ship		; корабли версии ZX (14–16) злятся, как все
an_bbc:
	cp	8
	jp	z, AN2
	ccf
	ret	c			; не корабль: перенос 1, как на BBC
	cp	7
	call	z, AN2
an_ship:
	ld	hl, (INF)
	ld	de, 32
	add	hl, de
	ld	a, (hl)
	or	a
	ret	z
	or	0x80
	ld	(hl), a
	ld	hl, (INF)
	ld	de, 28
	add	hl, de
	ld	(hl), 2
	inc	hl
	inc	hl
	ld	(hl), 4
	ret
AN2:
	ld	hl, K_ + NI + 32
	ld	a, (hl)
	or	0x80
	ld	(hl), a
	or	a
	ret

; SFRMIS: корабль пускает ракету в нас.
SFRMIS:
	ld	b, 9
	ld	a, 0xFE
	call	SFS1
	ret	nc
	ld	a, 120
	call	MESS
	ld	a, 48
	jp	NOISE

; SESCP: корабль выпускает спасательную капсулу. SFS1: завести корабль типа X с байтом поведения A на месте
; корабля из INWK (тот остаётся как был). Перенос 1 — заведён.
SESCP:
	ld	b, 13
	ld	a, 0xFE
SFS1:
	ld	(T1), a
	ld	hl, (XX0)
	push	hl
	ld	hl, (INF)
	push	hl
	push	bc
	ld	de, INWK
	ld	bc, XX3
	ld	a, NI
sfs_l2:
	push	af
	ld	a, (de)
	ld	(bc), a
	ld	a, (hl)
	ld	(de), a
	inc	hl
	inc	de
	inc	bc
	pop	af
	dec	a
	jp	nz, sfs_l2
	pop	bc
	ld	a, (TYPE)
	cp	8
	jp	nz, sfs_rx
	push	bc			; из станции: вылет из щели
	ld	a, 32
	ld	(INWK + 27), a
	ld	b, 0
	ld	a, (INWK + 10)
	call	SFS2
	ld	b, 3
	ld	a, (INWK + 12)
	call	SFS2
	ld	b, 6
	ld	a, (INWK + 14)
	call	SFS2
	pop	bc
sfs_rx:
	ld	a, (T1)
	ld	(INWK + 32), a
	ld	hl, INWK + 29
	ld	a, (hl)
	and	0xFE
	ld	(hl), a
	ld	a, b
	cp	11
	jp	nz, sfs_noil
	scf				; контейнер кувыркается и медленно летит
	call	DORND
	add	a, a
	ld	(INWK + 30), a
	ld	a, 0xFF
	rra
	ld	(INWK + 29), a
	ld	a, b
	and	15
	ld	(INWK + 27), a
	ld	a, 11
sfs_noil:
	call	NWSHP
	pop	hl
	ld	(INF), hl
	ld	hl, XX3
	ld	de, INWK
	ld	b, NI
sfs_l3:
	ld	a, (hl)
	ld	(de), a
	inc	hl
	inc	de
	dec	b
	jp	nz, sfs_l3
	pop	hl
	ld	(XX0), hl
	ret
SFS2:
	add	a, a
	ld	(R_), a
	ld	a, 0
	rra
	jp	MVT1
