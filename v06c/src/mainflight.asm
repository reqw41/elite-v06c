; Главный цикл полёта: M% (16 частей кассетной версии BBC), TT100 (появление кораблей), MAS1, ECMOF, GOIN.
; Перенесено близко к тексту BBC. Сверка — v06c/test/t27.mjs: сценарий launch целиком против эталона.
; Ветви боя, сбора груза, гибели и удаления корабля зовут ещё не перенесённые процедуры (unported).

; MAS1: INWK(X+2 X+1 X) += 2 · INWK(Y+1 Y) — сдвинуть точку вдоль вектора ориентации; A = |старший байт|.
MAS1:
	ld	hl, INWK
	ld	d, 0
	ld	e, c
	add	hl, de
	ld	a, (hl)
	add	a, a
	ld	(K + 1), a
	inc	hl
	ld	a, (hl)
	rla
	ld	(K + 2), a
	ld	a, 0
	rra
	ld	(K + 3), a
	push	bc
	call	MVT3
	pop	bc
	ld	hl, INWK + 2
	ld	d, 0
	ld	e, b
	add	hl, de
	ld	(hl), a
	ld	d, a
	dec	hl
	ld	a, (K + 2)
	ld	(hl), a
	dec	hl
	ld	a, (K + 1)
	ld	(hl), a
	ld	a, d
	and	0x7F
	ret

; ECMOF: выключить ECM: счётчики, лампа, звук.
ECMOF:
	xor	a
	ld	(ECMA), a
	ld	(ECMP), a
	call	ECBLB
	ld	a, 72
	jp	NOISE

; GOIN: стыковка: туннель, заправка щитов и энергии, на станцию.
GOIN:
	xor	a
	ld	(QQ22 + 1), a
	call	LAUN
	call	RES4
	ifndef	SCHED
	call	HALL			; ангар станции, как в дисковой версии
	ld	c, 44
	call	DELAY
	endif
	call	mis_dock		; вопросы и награды миссий
	jp	BAY

; TT100: проход главного цикла в полёте: M%, счётчик сообщения, раз в 256 проходов — новые корабли.
TT100:
	call	M_
	call	mis_fly			; миссии: сохраняет A и флаги
	ld	hl, DLY
	dec	(hl)
	jp	z, me2
	jp	p, me3
	inc	(hl)
me3:
	ld	hl, MCNT
	dec	(hl)
	jp	nz, MLOOP
	ld	hl, MJ			; проверка без сброса переноса: он идёт в генератор случайных чисел
	inc	(hl)
	dec	(hl)
	jp	nz, MLOOP
	call	DORND			; астероид или контейнер
	cp	35
	jp	nc, mtt1
	ld	a, (MANY + 10)
	cp	3
	jp	nc, mtt1
	call	ZINF
	ld	a, 38
	ld	(INWK + 7), a
	or	a			; на BBC перенос здесь — от сравнения выше (ноль)
	call	DORND
	ld	(INWK), a
	ld	d, a
	ld	a, b
	ld	(INWK + 3), a
	ld	a, d
	push	af
	and	0x80
	ld	(INWK + 2), a
	ld	a, b
	and	0x80
	ld	(INWK + 5), a
	pop	af
	ld	a, (INWK + 1)
	rla
	rla
	ld	(INWK + 1), a
	ld	a, (RAND + 3)
	ld	e, a
	call	DORND
	ld	d, a
	push	af
	xor	e			; переполнение 6502 при последнем сложении в DORND: знак суммы отличается
	ld	l, a			; от знака обоих слагаемых
	ld	a, b
	xor	d
	and	l
	jp	m, mtt4
	pop	af
	push	af
	or	0x6F
	ld	(INWK + 29), a
	ld	a, (SSPR)
	or	a
	jp	nz, mtt1_p
	pop	af
	ld	a, b
	jp	c, mtt2
	and	31
	or	16
	ld	(INWK + 27), a
	or	a
	jp	mtt3
mtt2:
	or	0x7F
	ld	(INWK + 30), a
	scf
mtt3:
	call	DORND
	cp	5
	ld	a, 10
	jp	nc, mtt3_n
	ld	a, 11
mtt3_n:
	ifndef	SCHED
	call	zx_rock			; вместо астероида иногда валун
	endif
	call	NWSHP
	jp	mtt1
mtt4:					; торговец
	pop	af
	or	a
	rra
	ld	(INWK + 32), a
	ld	(INWK + 29), a
	ld	d, a
	ld	hl, INWK + 31
	ld	a, (hl)
	rla
	ld	(hl), a
	ld	a, d
	and	31
	or	16
	ld	(INWK + 27), a
	ld	a, 7
	ifndef	SCHED
	call	zx_pick			; торговец: иногда Python, Boa или Anaconda
	endif
	call	NWSHP
	jp	TT100
mtt1_p:
	pop	af
mtt1:
	ld	a, (SSPR)		; полиция и пираты — только вне зоны станции
	or	a
	jp	nz, MLOOP
	call	BAD
	add	a, a
	ld	d, a
	push	af			; перенос сдвига идёт в Ze
	ld	a, (MANY + 2)
	or	a
	ld	a, d
	jp	z, mtt1_t
	ld	hl, FIST
	or	(hl)
mtt1_t:
	ld	(T), a
	pop	af
	call	Ze
	ld	hl, T
	cp	(hl)
	ld	e, 1			; перенос 6502 для DORND ниже: 1 после сравнения, 0 после NWSHP без места
	jp	nc, mtt1_c
	ld	a, 2
	call	NWSHP
	ld	e, 0
mtt1_c:
	ld	a, (MANY + 2)
	or	a
	jp	nz, MLOOP
	ld	hl, EV
	dec	(hl)
	jp	p, MLOOP
	inc	(hl)
	ld	a, e
	rra
	call	DORND
	ld	d, a
	push	af
	ld	a, (gov)
	or	a
	jp	z, label_2p		; анархия: пираты всегда; перенос — от DORND
	pop	af
	ld	a, d
	cp	90
	jp	nc, MLOOP
	and	7
	ld	hl, gov
	cp	(hl)
	jp	c, MLOOP
	scf
	jp	label_2
label_2p:
	pop	af
label_2:
	call	Ze
	cp	200
	jp	nc, mt1
	ld	hl, EV
	inc	(hl)
	and	3
	add	a, 3
	ld	c, a
	ld	a, b
	cp	200
	ccf
	rla
	or	0xC0
	ld	d, a
	ld	a, c
	cp	6
	jp	z, tha
	ld	a, d
	ld	(INWK + 32), a
	ld	a, c
	ifndef	SCHED
	call	zx_pick
	endif
	call	mis_pick		; охота за скрывающим устройством: иногда — Asp с ним
	call	NWSHP
	jp	MLOOP
tha:
	scf
	call	DORND
	cp	200
	jp	c, MLOOP
	scf
	call	GTHG
	jp	MLOOP
mt1:					; стая пиратов
	and	3
	ld	(EV), a
	ld	(XX13), a
	scf
mt3:
	call	DORND
	and	3
	or	1
	ifndef	SCHED
	call	zx_pick
	endif
	call	NWSHP
	ld	hl, XX13
	dec	(hl)
	jp	p, mt3
	jp	MLOOP
me2:
	ld	a, (MCH)
	call	MESS
	xor	a
	ld	(DLY), a
	ld	(mch_x), a
	jp	me3

; M%: проход цикла полёта.
M_:
	ld	a, (K_)			; подмешать в генератор случайных чисел координату планеты
	ld	(RAND), a
	; --- часть 2: крен и тангаж по ручкам JSTX, JSTY ---
	ld	a, (JSTX)
	ld	b, a
	call	cntr
	call	cntr
	ld	a, b
	ld	(JSTX), a
	xor	0x80
	ld	c, a
	and	0x80
	ld	(ALP2), a
	xor	0x80
	ld	(ALP2 + 1), a
	ld	a, c
	or	a
	jp	p, m_roll
	cpl
	inc	a
m_roll:
	rrca
	rrca
	and	0x3F
	ld	e, 1			; E — перенос 6502 после этого места: 1, если крен не меньше 8
	cp	8
	jp	nc, m_roll2
	or	a
	rra
	ld	e, 0
m_roll2:
	ld	(ALP1), a
	ld	hl, ALP2
	or	(hl)
	ld	(ALPHA), a
	ld	a, (JSTY)
	ld	b, a
	push	de
	call	cntr
	pop	de
	ld	a, b
	ld	(JSTY), a
	xor	0x80
	ld	c, a
	and	0x80
	ld	(BET2 + 1), a
	xor	0x80
	ld	(BET2), a
	ld	a, c
	or	a
	jp	p, m_pitch
	cpl
m_pitch:
	add	a, 4			; на BBC сюда приходит перенос от расчёта крена
	add	a, e
	rrca
	rrca
	rrca
	rrca
	and	0x0F
	cp	3
	jp	nc, m_pitch2
	or	a
	rra
m_pitch2:
	ld	(BET1), a
	ld	hl, BET2
	or	(hl)
	ld	(BETA), a
	; --- часть 3: скорость, ракеты, бомба, капсула, ECM, стыковочный компьютер, лазер ---
	ld	a, (KY2)
	or	a
	jp	z, ma17
	ld	a, (DELTA)
	cp	40
	jp	nc, ma17
	inc	a
	ld	(DELTA), a
ma17:
	ld	a, (KY1)
	or	a
	jp	z, ma4
	ld	hl, DELTA
	dec	(hl)
	jp	nz, ma4
	inc	(hl)
ma4:
	ld	hl, NOMSL
	ld	a, (KY15)
	and	(hl)
	jp	z, ma20
	ld	c, 0xEE			; снять ракету с цели
	call	ABORT
	ld	a, 40
	call	NOISE
	xor	a
	ld	(MSAR), a
ma20:
	ld	a, (MSTG)
	or	a
	jp	p, ma25
	ld	a, (KY14)
	or	a
	jp	z, ma25
	ld	d, a
	ld	a, (NOMSL)
	or	a
	jp	z, ma25
	ld	b, a
	ld	a, d
	ld	(MSAR), a		; взвести ракету
	ld	c, 0xE0
	call	MSBAR
ma25:
	ld	a, (KY16)
	or	a
	jp	z, ma24
	ld	a, (MSTG)
	or	a
	jp	m, ma64
	call	FRMIS
ma24:
	ld	a, (KY12)
	or	a
	jp	z, ma76
	ld	hl, BOMB
	ld	a, (hl)
	add	a, a
	ld	(hl), a
ma76:
	ld	hl, ESCP
	ld	a, (KY13)
	and	(hl)
	jp	nz, ESCAPE
	ld	a, (KY18)
	or	a
	call	nz, WARP
	ld	a, (M3ST)		; в системе, захваченной таргонами, ECM не работает ни у кого (глушилка)
	cp	4
	jp	z, ma64
	ld	hl, ECM
	ld	a, (KY17)
	and	(hl)
	jp	z, ma64
	ld	a, (ECMA)
	or	a
	jp	nz, ma64
	ld	hl, ECMP
	dec	(hl)
	call	ECBLB2
ma64:
	ld	hl, DKCMP
	ld	a, (KY19)
	and	(hl)
	ld	hl, SSPR
	and	(hl)
	jp	z, ma68
	ld	a, (K_ + NI + 32)
	or	a
	jp	m, ma68
	ifdef	SCHED
	ld	a, 7			; стыковочный компьютер: сообщение, как на ZX, и секунда на прочтение
	call	messx
	ld	c, 50
	call	DELAY
	jp	GOIN
	else
	ld	hl, auto		; обычный образ: автопилот ведёт корабль в станцию, как в дисковой версии
	ld	a, (hl)
	or	a
	jp	nz, ma68
	ld	(hl), 0xFF
	ld	a, 7
	call	messx
	endif
ma68:
	xor	a
	ld	(LAS), a
	ld	a, (DELTA)		; DELT4 = скорость · 64
	ld	l, 0
	or	a
	rra
	ld	h, a
	ld	a, l
	rra
	ld	l, a
	ld	a, h
	or	a
	rra
	ld	h, a
	ld	a, l
	rra
	ld	l, a
	ld	(DELT4), hl
	ld	a, (LASCT)
	or	a
	jp	nz, ma3
	ld	a, (KY7)
	or	a
	jp	z, ma3
	ld	a, (GNTMP)
	cp	242
	jp	nc, ma3
	ld	a, (VIEW)
	ld	e, a
	ld	d, 0
	ld	hl, LASER
	add	hl, de
	ld	a, (hl)
	or	a
	jp	z, ma3
	push	af			; огонь
	and	0x7F
	ld	(LAS), a
	ld	(LAS2), a
	xor	a
	call	NOISE
	call	LASLI
	pop	af
	or	a
	jp	p, ma1
	xor	a
ma1:
	and	0xFA
	ld	(LASCT), a
	; --- части 4–12: корабли по местам ---
ma3:
	xor	a
mal1:
	ld	(XSAV), a
	ld	b, a
	ld	e, a
	ld	d, 0
	ld	hl, FRIN
	add	hl, de
	ld	a, (hl)
	or	a
	jp	z, ma18
	ld	(TYPE), a
	call	GINF
	ld	hl, (INF)
	ld	de, INWK
	ld	b, NI
	call	ll9_cp
	ld	a, (TYPE)
	or	a
	jp	m, ma21
	add	a, a
	ld	e, a
	ld	d, 0
	ld	hl, XX21X - 2
	add	hl, de
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a
	ld	(XX0), hl
	ld	a, (BOMB)
	or	a
	jp	p, ma21
	ld	a, e
	cp	2 * 8
	jp	z, ma21
	ld	a, (INWK + 31)
	and	0x20
	jp	nz, ma21
	ld	a, (INWK + 31)		; бомба: всё, кроме станции, гибнет
	or	0x80
	ld	(INWK + 31), a
	call	EXNO2
ma21:
	call	MVEIT
	ld	hl, (INF)
	ex	de, hl
	ld	hl, INWK
	ld	b, NI
	call	ll9_cp
	ld	a, (INWK + 31)		; часть 6: столкновение, стыковка, сбор груза — только вплотную
	and	0xA0
	call	MAS4
	jp	nz, ma26
	ld	a, (INWK)
	ld	hl, INWK + 3
	or	(hl)
	ld	hl, INWK + 6
	or	(hl)
	jp	m, ma26
	ld	d, a
	ld	a, (TYPE)
	ld	b, a
	or	a
	jp	m, ma26
	cp	8
	jp	z, isdk
	ld	a, d
	and	0xC0
	jp	nz, ma26
	ld	a, b
	cp	9
	jp	z, ma26
	cp	11
	jp	c, ma58
	cp	NTY + 1
	jp	c, ma_sc
	cp	18
	jp	c, ma58			; корабли версии ZX не подбираются; 18 — контейнер с устройством,
	cp	21			; 19 — пластина, 20 — обломок; 21 — валун и корабли дисковой версии — нет
	jp	nc, ma58
ma_sc:
	ld	hl, INWK + 5
	ld	a, (BST)
	and	(hl)
	jp	p, ma58
	ld	a, b
	cp	18
	jp	nz, ma_std
	call	mis_cloakgot		; контейнер со скрывающим устройством
	jp	ma60
ma_std:
	ld	a, b
	cp	19
	ld	a, 9			; пластина — сплавы
	jp	z, ma_slvy2
	ld	a, b
	cp	20
	ld	a, 12			; обломок — минералы
	jp	z, ma_slvy2
	ld	a, b			; сбор груза заборником: контейнер — случайный товар, таргон — чужие
	cp	12			; изделия, капсула — рабы
	ld	a, 3
	jp	c, ma_oily
	jp	nz, ma_slvy2
	ld	a, 16
	jp	ma_slvy2
ma_oily:
	or	a
	call	DORND
	and	7
ma_slvy2:
	ld	(QQ29), a
	ld	a, 1
	call	tnpr
	jp	c, ma59			; нет места: груз пропал
	ld	a, (QQ29)
	ld	e, a
	ld	d, 0
	ld	hl, QQ20
	add	hl, de
	inc	(hl)
	ld	a, e
	add	a, 208
	call	MESS
	jp	ma60
ma59:
	call	EXNO3
ma60:
	ld	hl, INWK + 31
	ld	a, (hl)
	or	0x80
	ld	(hl), a
	jp	ma26
isdk:
	ld	a, (K_ + NI + 32)	; стыковка: станция не злится, мы носом в щель, щель горизонтальна
	or	a
	jp	m, ma62
	ld	a, (INWK + 14)
	cp	214
	jp	c, ma62
	call	SPS4
	ld	a, (XX15 + 2)
	or	a
	jp	m, ma62
	cp	89
	jp	c, ma62
	ld	a, (INWK + 16)
	and	0x7F
	cp	80
	jp	nc, GOIN
ma62:
	ld	a, (DELTA)
	cp	5
	jp	nc, DEATH
	ld	a, 1			; отскок от станции
	ld	(DELTA), a
	ld	a, 5
	or	a			; перенос 6502 = 0
	jp	ma63
ma58:
	ld	hl, INWK + 31		; столкновение: корабль гибнет, нам — урон в половину его энергии
	ld	a, (hl)
	or	0x80
	ld	(hl), a
	ld	a, (INWK + 35)
	scf
	rra
ma63:
	call	OOPS
	call	EXNO3
	; --- часть 10: прицел и попадание ---
ma26:
	ld	a, (QQ11)
	or	a
	jp	nz, ma15
	call	PLUT
	call	HITCH
	jp	nc, ma8_0
	ld	a, (MSAR)
	or	a
	jp	z, ma47
	call	BEEP			; ракета захватила цель
	ld	a, (XSAV)
	ld	b, a
	ld	c, 0x0E
	call	ABORT2
ma47:
	ld	a, (LAS)
	or	a
	jp	z, ma8_1
	ld	b, 15			; попали лазером
	call	EXNO
	ld	a, (LAS)
	ld	d, a
	ld	a, (INWK + 35)
	sub	d
	jp	nc, ma14
	ld	a, (TYPE)
	cp	8
	jp	z, ma14_2		; станцию не убить
	ld	hl, INWK + 31
	ld	a, (hl)
	or	0x80
	ld	(hl), a
	ld	a, (TYPE)
	cp	22
	jp	nc, ma_zx		; корабли дисковой версии гибнут как корабли
	cp	19
	jp	nc, ma8_1		; пластина, обломок, валун — без обломков и счёта
	cp	NTY + 1
	jp	nc, ma_zx		; корабли версии ZX гибнут как корабли: обломки и счёт побед
	cp	10
	jp	nz, ma_nast
	ld	a, (LAS)		; астероид, разбитый добывающим лазером, даёт до трёх обломков
	cp	50
	jp	nz, ma8_1
	or	a
	call	DORND
	and	3
	jp	z, ma8_1
	ld	(CNT), a
ma_spl:
	ld	b, 20
	xor	a
	call	SFS1
	ld	hl, CNT
	dec	(hl)
	jp	nz, ma_spl
	jp	ma8_1
ma_nast:
	cp	8
	jp	nc, ma8_1		; ракета, астероид, контейнер — без обломков
ma_zx:
	cp	17
	jp	nz, ma_deb
	ld	b, 18			; Asp со скрывающим устройством: контейнер с ним
	xor	a
	call	SFS1
	jp	ma_oh
ma_deb:
	ifndef	SCHED
	call	zx_plate		; версия ZX: иногда — пластина обшивки (в сборке стенда нет: там игра равна BBC)
	endif
	or	a
	call	DORND
	or	a
	jp	p, ma_oh
	ld	hl, (XX0)
	and	(hl)
	ld	(CNT), a
ma_um:
	jp	z, ma_oh
	ld	b, 11
	xor	a
	call	SFS1
	ld	hl, CNT
	dec	(hl)
	jp	p, ma_um
ma_oh:
	call	EXNO2
	ld	a, (DNOIZ)		; на BBC в энергию корабля попадает A после звука: 7 или байт блока звука
	or	a
	ld	a, 7
	jp	z, ma14
	ld	a, (XX16)
ma14:
	ld	(INWK + 35), a
ma14_2:
	ld	a, (TYPE)
	call	ANGRY
	ld	a, (TYPE)		; перенос 6502 после ANGRY: тип > 8
	cp	9
	jp	nc, ma8_1
ma8_0:
	xor	a
	jp	ma8
ma8_1:
	ld	a, 1
ma8:
	ld	(ll9_cy), a		; перенос 6502 на входе LL9 (нужен при начале взрыва)
	call	LL9
	; --- часть 12: сохранить блок, убрать улетевших ---
ma15:
	ld	hl, (INF)
	ld	de, 35
	add	hl, de
	ld	a, (INWK + 35)
	ld	(hl), a
	ld	a, (INWK + 31)
	or	a
	jp	p, mac1
	and	0x20
	jp	z, mac1
	ld	a, (TYPE)		; корабль взорвался: за полицейского — в розыск, за остальных — награда
	cp	2
	jp	nz, ma_q2
	ld	hl, FIST
	ld	a, (hl)
	or	64
	ld	(hl), a
ma_q2:
	ld	a, (DLY)
	ld	hl, MJ
	or	(hl)
	jp	nz, KS1
	ld	hl, (XX0)
	ld	de, 10
	add	hl, de
	ld	a, (hl)
	or	a
	jp	z, KS1
	ld	b, a
	inc	hl
	ld	c, (hl)
	call	MCASH
	xor	a
	call	MESS
	jp	KS1
mac1:
	ld	a, (TYPE)
	or	a
	jp	m, ma27
	call	FAROF
	jp	nc, KS1
ma27:
	ld	hl, (INF)
	ld	de, 31
	add	hl, de
	ld	a, (INWK + 31)
	ld	(hl), a
	ld	a, (XSAV)
	inc	a
	jp	mal1
	; --- часть 13: бомба, щиты, энергия, станция при подлёте к планете ---
ma18:
	ld	a, (BOMB)
	or	a
	jp	p, ma77
	add	a, a
	ld	(BOMB), a
	call	WSCAN
	call	flash			; вспышка: фон на два кадра — жёлтый
ma77:
	ld	a, (MCNT)
	and	7
	jp	nz, ma22
	ld	a, (ENERGY)
	or	a
	jp	p, ma_b
	ld	a, (ASH)
	ld	b, a
	call	SHD
	ld	a, b
	ld	(ASH), a
	ld	a, (FSH)
	ld	b, a
	call	SHD
	ld	a, b
	ld	(FSH), a
ma_b:
	ld	hl, ENERGY
	ld	a, (ENGY)
	scf
	adc	a, (hl)
	jp	c, ma_b2
	ld	(hl), a
ma_b2:
	ld	a, (MJ)
	or	a
	jp	nz, ma23
	ld	a, (MCNT)
	and	31
	jp	nz, ma93
	ld	a, (SSPR)
	or	a
	jp	nz, ma23
	ld	c, a
	call	MAS2
	jp	nz, ma23
	ld	hl, K_			; близко к планете: поставить станцию на орбиту
	ld	de, INWK
	ld	b, 29
	call	ll9_cp
	ld	bc, 0x0009
	call	MAS1
	jp	nz, ma23
	ld	bc, 0x030B
	call	MAS1
	jp	nz, ma23
	ld	bc, 0x060D
	call	MAS1
	jp	nz, ma23
	ld	a, 192
	call	FAROF2
	jp	nc, ma23
	ld	a, (QQ11)
	or	a
	call	z, wpls_red
	call	NWSPS
	jp	ma23
	; --- часть 15: высота над планетой, жар солнца ---
ma22:
	ld	a, (MJ)
	or	a
	jp	nz, ma23
	ld	a, (MCNT)
	and	31
ma93:
	cp	10
	jp	nz, ma29
	ld	hl, ENERGY
	ld	a, 50
	cp	(hl)
	jp	c, ma93_e
	add	a, a			; «ENERGY LOW»
	call	MESS
ma93_e:
	ld	a, 0xFF
	ld	(ALTIT), a
	ld	c, 0
	xor	a
	call	MAS2
	jp	nz, ma23
	call	MAS3
	jp	c, ma23
	sub	37			; на BBC SBC #36 при переносе 0
	jp	c, DEATH		; врезались в планету
	ld	(R_), a
	call	LL5
	ld	a, (Q)
	ld	(ALTIT), a
	or	a
	jp	nz, ma23
	jp	DEATH
ma29:
	cp	20
	jp	nz, ma23
	ld	a, 30
	ld	(CABTMP), a
	ld	a, (SSPR)
	or	a
	jp	nz, ma23
	ld	c, NI
	call	MAS2
	jp	nz, ma23
	call	MAS3
	cpl
	adc	a, 30
	ld	(CABTMP), a
	jp	c, DEATH		; сгорели у солнца
	cp	224
	jp	c, ma23
	ld	a, (BST)
	or	a
	jp	z, ma23
	ld	a, (DELT4 + 1)		; топливозаборники
	or	a
	rra
	ld	hl, QQ14
	adc	a, (hl)
	cp	70
	jp	c, ma29_f
	ld	a, 70
ma29_f:
	ld	(hl), a
	ld	a, 160
	call	MESS
	; --- часть 16: луч лазера, ECM, пыль ---
ma23:
	ld	a, (LAS2)
	or	a
	jp	z, ma16
	ld	a, (LASCT)
	cp	8
	jp	nc, ma16
	call	LASLI2
	xor	a
	ld	(LAS2), a
ma16:
	ld	a, (ECMP)
	or	a
	jp	z, ma69
	call	DENGY
	jp	z, ma70
ma69:
	ld	a, (ECMA)
	or	a
	jp	z, ma66
	ld	hl, ECMA
	dec	(hl)
	jp	nz, ma66
ma70:
	call	ECMOF
ma66:
	ld	a, (QQ11)
	or	a
	ret	nz
	jp	STARS

; zx_pick: корабли версий ZX и дисковой BBC. A — тип, выбранный игрой, как в кассетной BBC (1 Sidewinder, 3 Mamba,
; 4 Python, 5 Cobra — пираты и охотники, 7 — Cobra-торговец); в половине случаев вместо него выходит один из
; четырёх типов строки zp_tab. Генератор случайных чисел свой (mis_rnd): ход игры и её случайные числа не
; меняются. Перенос сохраняется (он идёт в DORND). В сборке стенда (SCHED) замены нет — там игра равна эталону.
zx_pick:
	push	af
	cp	8
	jp	nc, zp_keep
	ld	e, a
	ld	d, 0
	ld	hl, zp_map - 1
	add	hl, de
	ld	a, (hl)
	or	a
	jp	m, zp_keep
	ld	e, a
	call	mis_rnd
	rra
	jp	c, zp_keep
	and	3
	add	a, e
	ld	e, a
	ld	hl, zp_tab
	add	hl, de
	pop	af
	ld	a, (hl)
	ret
zp_keep:
	pop	af
	ret
zp_map:	db	0, 0xFF, 4, 8, 12, 0xFF, 16
zp_tab:	db	14, 22, 23, 25		; Sidewinder: Krait, Adder, Gecko, Worm
	db	14, 24, 26, 23		; Mamba: Krait, Cobra Mk I, Moray, Gecko
	db	15, 15, 4, 4		; Python: Asp Mk II
	db	16, 16, 5, 15		; Cobra: Fer-de-Lance, Asp Mk II
	db	27, 28, 4, 7		; торговец: Boa, Anaconda, Python
; zx_rock: вместо астероида (10) в одном случае из четырёх — валун (21).
zx_rock:
	cp	10
	ret	nz
	call	mis_rnd
	and	3
	ld	a, 10
	ret	nz
	ld	a, 21
	ret
; zx_tact: добавки дисковой версии в тактику (B — тип, сохраняется). Anaconda (28) изредка выпускает Worm (25);
; мирная станция, пока рядом нет челнока, изредка выпускает Shuttle (29) или Transporter (30) — он без тактики,
; летит прямо из щели, к планете. Случайные числа свои.
zx_tact:
	ld	a, b
	cp	8
	jp	z, zt_st
	cp	28
	ret	nz
	call	mis_rnd
	cp	252
	ret	c
	push	bc
	ld	b, 25
	ld	a, 0xCA
	call	SFS1
	pop	bc
	ret
zt_st:
	ld	a, (INWK + 32)
	add	a, a
	ret	m
	call	mis_rnd
	cp	253
	ret	c
	and	1
	add	a, 29
	ld	e, a
	ld	hl, FRIN
	ld	c, NOSH
zt_1:
	ld	a, (hl)
	sub	29
	cp	2
	ret	c
	inc	hl
	dec	c
	jp	nz, zt_1
	push	bc
	ld	b, e
	xor	a
	call	SFS1
	pop	bc
	ret

