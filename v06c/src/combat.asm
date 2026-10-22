; Бой: урон OOPS, потеря груза OUCH, сообщения MESS, звуки взрыва EXNO, EXNO2, EXNO3, сброс захвата ABORT,
; удаление корабля KS1, KILLSHP, KS2–KS4, новый корабль в случайном месте Ze, таргоид GTHG.
; Перенесено близко к тексту BBC. Сверка — сценарий fight (v06c/test/t27.mjs fight).

; OOPS: урон A по щиту (переднему или заднему — по знаку z корабля из блока INF), остаток — по энергии.
; Перенос на входе — как на BBC (вычитание 6502 с заёмом): 0 — урон на единицу больше.
OOPS:
	call	tint_hit		; экран на миг краснеет (палитра; на состояние игры не влияет)
	ld	(T), a
	ld	d, a
	ld	a, 0
	ccf
	adc	a, 0
	ld	e, a			; 1 — вычесть лишнюю единицу
	ld	hl, (INF)
	ld	bc, 8
	add	hl, bc
	ld	a, (hl)
	or	a
	ld	hl, FSH
	jp	p, oo_sub
	ld	hl, ASH
oo_sub:
	ld	a, (hl)
	sub	d
	jp	c, oo_w
	sub	e
	jp	c, oo_n
	ld	(hl), a
	ret
oo_w:
	sub	e
oo_n:
	ld	(hl), 0			; щит пробит
	ld	hl, ENERGY
	add	a, (hl)
	ld	(hl), a
	jp	z, DEATH
	jp	nc, DEATH
	call	EXNO3
	ifndef	SCHED
	call	zx_leak			; версия ZX: изредка — утечка топлива (в сборке стенда нет: там игра равна BBC)
	endif
; OUCH: при уроне по энергии иногда гибнет груз или прибор.
OUCH:
	ifdef	SCHED
	call	DORND2
	or	a
	ret	m
	ld	a, b
	cp	22
	ret	nc
	else
; Как в ZX 48K: 10 ударов из 64 губят единицу груза (случайный товар из шестнадцати, если он есть в трюме);
; приборы не гибнут. В кассетной BBC гибнет весь товар или прибор, реже.
	call	DORND2
	and	63
	cp	10
	ret	nc
	ld	a, b
	and	15
	ld	b, a
	endif
	ld	e, b
	ld	d, 0
	ld	hl, QQ20
	add	hl, de
	ld	a, (hl)
	or	a
	ret	z
	ld	a, (DLY)
	or	a
	ret	nz
	ld	a, 3
	ld	(de_), a
	ifdef	SCHED
	ld	(hl), 0
	else
	dec	(hl)
	endif
	ld	a, b
	cp	17
	jp	nc, ou1
	add	a, 208
	jp	MESS
ou1:
	jp	z, ou2
	cp	18
	jp	z, ou3
	add	a, 94
	jp	MESS
ou2:
	ld	a, 108
	jp	MESS
ou3:
	ld	a, 111
; MESS: сообщение (слово A) внизу обзора на 22 прохода; прежнее сообщение сначала стирается (me1).
; mes9: напечатать слово A и, если бит 0 ячейки de стоит, — « DESTROYED».
MESS:
	ld	d, a
	xor	a
	ld	(QQ17), a
	ld	a, 9
	ld	(XC), a
	ld	a, 22
	ld	(YC), a
	ld	a, (DLY)
	or	a
	jp	nz, me1
	ld	a, 22
	ld	(DLY), a
	ld	a, d
	ld	(MCH), a
mes9:
	ld	e, a
	ld	a, (mch_x)		; на экране своё сообщение миссии — печатать (стирать) его
	or	a
	jp	nz, mes9x
	ld	a, e
	call	TT27
	ld	hl, de_
	ld	a, (hl)
	or	a
	rra
	ld	(hl), a
	ret	nc
	ld	a, 253
	jp	TT27
me1:
	xor	a
	ld	(DLY), a
	push	de
	ld	a, (MCH)
	ifdef	ORAND
	call	mes9e			; стереть прежнее — очисткой
	else
	call	mes9
	endif
	xor	a
	ld	(mch_x), a
	pop	de
	ld	a, d
	jp	MESS

; EXNO3: два звука взрыва. EXNO2: счёт побед + 1 (на каждые 256 — «Right on, Commander!») и звук взрыва.
; EXNO: звук попадания, высота — по расстоянию до корабля и маске X.
EXNO3:
	ld	a, 16
	call	NOISE
	ld	a, 24
	jp	NOISE
EXNO2:
	ifdef	SCHED
	ld	hl, TALLY
	inc	(hl)
	jp	nz, exno_7
	else
; Счёт очками, как в ZX 48K: [TFR, TALLY, TALLY+1] — 24 разряда, за объект — ex_pts[тип] · 4 очка; ранги и
; «Right on, Commander!» — по двум старшим байтам. ex_add: A — тип (0 — ничего).
	ld	a, (TYPE)
ex_add:
	and	0x1F
	ld	e, a
	ld	d, 0
	ld	hl, ex_pts
	add	hl, de
	ld	l, (hl)
	ld	h, d
	add	hl, hl
	add	hl, hl
	ex	de, hl
	ld	hl, TFR
	ld	a, (hl)
	add	a, e
	ld	(hl), a
	ld	hl, TALLY
	ld	a, (hl)
	adc	a, d
	ld	(hl), a
	jp	nc, exno_7
	endif
	inc	hl
	inc	(hl)
	ld	a, 101
	call	MESS
exno_7:
	ld	b, 7
EXNO:
	ld	a, b
	ld	(T), a
	ld	a, 24
	call	NOISE
	ld	a, (INWK + 7)
	or	a
	rra
	or	a
	rra
	ld	hl, T
	and	(hl)
	or	0xF1
	ld	(XX16 + 2), a		; на BBC — громкость первого звука по расстоянию; у ВИ53 громкости нет
	ld	a, 16
	jp	NOISE

; ABORT: снять захват ракеты, полоска цветом Y. ABORT2: захват цели в месте X, полоска цветом Y.
ABORT:
	ld	b, 0xFF
ABORT2:
	ld	a, b
	ld	(MSTG), a
	ld	a, (NOMSL)
	ld	b, a
	call	MSBAR
	xor	a
	ld	(MSAR), a
	ld	c, a
	ret

; KS1: убрать корабль в месте XSAV и продолжить обход с того же места.
KS1:
	ld	a, (XSAV)
	ld	b, a
	call	KILLSHP
	ld	a, (XSAV)
	jp	mal1
; KS4: убрана станция: вместо неё снова солнце.
KS4:
	ld	a, (M3ST)		; захваченная станция уничтожена: задание выполнено
	cp	4
	jp	nz, ks4_g
	ld	a, 6
	ld	(M3ST), a
	call	mis_256			; как в ZX 48K: награда рейтингом сразу за станцию и ещё раз при стыковке
ks4_g:
	call	ZINF
	call	FLFLLS
	xor	a
	ld	(FRIN + 1), a
	ld	(SSPR), a
	call	SPBLB
	ld	a, 6
	ld	(INWK + 5), a
	ld	a, 129
	jp	NWSHP
; KS2: после удаления корабля поправить цели летящих ракет: цель убрана — ракета без цели, цель дальше
; по списку — номер места на единицу меньше. KS3: новый низ кучи отрезков.
KS2:
	ld	b, 0xFF
ksl4:
	inc	b
	ld	e, b
	ld	d, 0
	ld	hl, FRIN
	add	hl, de
	ld	a, (hl)
	or	a
	jp	z, KS3
	cp	9
	jp	nz, ksl4
	ld	a, b
	add	a, a
	ld	e, a
	ld	hl, UNIV
	add	hl, de
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a
	ld	(SC), hl
	ld	e, 32
	add	hl, de
	ld	a, (hl)
	or	a
	jp	p, ksl4
	and	0x7F
	rra
	ld	e, a
	ld	a, (XX4)
	ld	d, a
	ld	a, e
	cp	d
	jp	c, ksl4
	jp	z, ks6
	dec	a
	add	a, a
	or	0x80
	ld	(hl), a
	jp	ksl4
ks6:
	ld	(hl), 0
	jp	ksl4
KS3:
	ld	hl, (P_)
	ld	(SLSP), hl
	ret
; KILLSHP: убрать корабль из места X: сдвинуть места, блоки и списки отрезков в куче остальных кораблей.
; XX0 — описание убираемого корабля, INF — его блок. Ячейки K, K+1 получают адрес списка, как на BBC
; (старший байт — без смещения рабочих областей).
KILLSHP:
	ld	a, b
	ld	(XX4), a
	ld	hl, MSTG
	cp	(hl)
	jp	nz, ks5
	ld	c, 0xEE			; убрана цель ракеты
	call	ABORT
	ld	a, 200
	call	MESS
ks5:
	ifndef	SCHED
	ld	a, (XX4)
	ld	b, a
	call	nb_kill			; флаги поведения следующих мест — на место вниз
	endif
	ld	a, (XX4)
	ld	e, a
	ld	d, 0
	ld	hl, FRIN
	add	hl, de
	ld	a, (hl)
	cp	8
	jp	z, KS4
	cp	NTY + 1
	jp	nc, ks_zx		; корабли версии ZX в MANY не числятся
	ld	e, a
	ld	hl, MANY
	add	hl, de
	dec	(hl)
	jp	ks_nm
ks_zx:
	cp	31
	jp	nz, ks_nm
	ld	hl, DTP		; «Констриктор» убит
	ld	a, (hl)
	or	2
	ld	(hl), a
ks_nm:
	ld	hl, (XX0)
	ld	e, 5
	add	hl, de
	ld	c, (hl)			; байт в куче у убираемого
	ld	hl, (INF)
	ld	e, 33
	add	hl, de
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a
	ld	b, 0
	add	hl, bc
	ld	(P_), hl		; верх освобождаемого места
	ld	a, (XX4)
	ld	b, a
ksl1:
	inc	b
	ld	e, b
	ld	d, 0
	ld	hl, FRIN
	add	hl, de
	ld	a, (hl)
	dec	hl
	ld	(hl), a
	or	a
	jp	z, KS2
	add	a, a
	ld	e, a
	ld	hl, XX21X - 2
	add	hl, de
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a
	ld	e, 5
	add	hl, de
	ld	a, (hl)
	ld	(T), a			; байт в куче у следующего корабля
	ld	e, a
	ld	hl, (P_)
	ld	a, l
	sub	e
	ld	l, a
	ld	a, h
	sbc	a, 0
	ld	h, a
	ld	(P_), hl
	ld	a, b
	add	a, a
	ld	e, a
	ld	hl, UNIV
	add	hl, de
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a
	ld	(SC), hl
	push	bc
	ex	de, hl			; DE — блок следующего корабля, HL — блок на место раньше
	ld	hl, (INF)
	ld	c, 33
ksl2:
	ld	a, (de)
	ld	(hl), a
	inc	de
	inc	hl
	dec	c
	jp	nz, ksl2
	ld	a, (de)			; адрес списка отрезков: старый — в K и BC, новый — P
	ld	(K), a
	ld	c, a
	ld	a, (P_)
	ld	(hl), a
	inc	de
	inc	hl
	ld	a, (de)
	ld	b, a
	sub	high WS
	ld	(K + 1), a
	ld	a, (P_ + 1)
	ld	(hl), a
	inc	de
	inc	hl
	ld	a, (de)
	ld	(hl), a
	ld	hl, (SC)
	ld	(INF), hl
	ld	a, (T)			; список отрезков — на новое место, с верхнего байта (места перекрываются)
	dec	a
	ld	e, a
	ld	d, 0
	ld	h, b
	ld	l, c
	add	hl, de
	ld	b, h
	ld	c, l
	ld	hl, (P_)
	add	hl, de
	inc	e
ksl3:
	ld	a, (bc)
	ld	(hl), a
	dec	bc
	dec	hl
	dec	e
	jp	nz, ksl3
	pop	bc
	jp	ksl1

; Ze: новый корабль в случайном месте вдали: блок INWK, поведение — враждебный, с тактикой, ECM — случайно.
; На выходе случайное число в A и X (как DORND2). Перенос на входе идёт в DORND, как на BBC.
Ze:
	push	af
	call	ZINF
	pop	af
	call	DORND
	ld	(T1), a
	and	0x80
	ld	(INWK + 2), a
	ld	a, b
	and	0x80
	ld	(INWK + 5), a
	ifdef	SCHED
	ld	a, 32
	else
	ld	a, 25			; враги появляются ближе, как в дисковой версии
	endif
	ld	(INWK + 1), a
	ld	(INWK + 4), a
	ld	(INWK + 7), a
	ld	a, b
	cp	245
	ccf
	rla
	or	0xC0
	ld	(INWK + 32), a
	jp	DORND2
; GTHG: таргоид и таргон при нём.
GTHG:
	call	Ze
	ld	a, 0xFF
	ld	(INWK + 32), a
	ld	a, 6
	call	NWSHP
	ld	a, 12
	jp	NWSHP
