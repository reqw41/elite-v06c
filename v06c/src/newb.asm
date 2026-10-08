; Флаги поведения кораблей — как NEWB дисковой версии BBC (в кассетной их нет): бит 0 — торговец, 1 — охотник
; за наградой, 2 — враждебен, 3 — пират, 4 — идёт стыковаться, 5 — мирный, 6 — полиция. В блоке корабля места под
; них нет (блок — 36 байт, как в кассетной версии), поэтому флаги лежат отдельной таблицей newb, по байту на место.
; Только в обычном образе. Сверка по смыслу — v06c/test/newb.mjs.
	ifndef	SCHED
; nb_e: флаги по умолчанию для типов 1…31 (таблица E% дисковой версии, в нашей нумерации типов)
nb_e:	db	0x0C, 0x42, 0x0C, 0x0C, 0x0C, 0x0C, 0x20	; Sidewinder, Viper, Mamba, Python, Cobra (пират), Thargoid, Cobra-торговец
	db	0x00, 0x00, 0x00, 0x00, 0x04, 0x01		; станция, ракета, астероид, контейнер, таргон, капсула
	db	0x0C, 0x0C, 0x02, 0x0C, 0x00, 0x00, 0x00, 0x00	; Krait, Asp, Fer-de-Lance, Asp с устройством, мусор: 18–21
	db	0x0C, 0x0C, 0x0C, 0x04, 0x0C, 0x20, 0x21	; Adder, Gecko, Cobra Mk I, Worm, Moray, Boa, Anaconda
	db	0x21, 0x61, 0x04				; Shuttle, Transporter, Constrictor

; nb_new (из NWSHP): флаги нового корабля. E — место, B — тип; A, B, DE сохраняются. nb_pre: что добавить к
; флагам по умолчанию; с битом 7 — взять вместо них (торговец, каким бы кораблём он ни вышел).
nb_new:
	push	de
	ld	hl, newb
	add	hl, de
	push	hl
	ld	e, b
	ld	hl, nb_e - 1
	add	hl, de
	ld	e, (hl)
	ld	hl, nb_pre
	ld	a, (hl)
	ld	(hl), d
	or	a
	jp	m, nb_n1
	or	e
nb_n1:
	and	0x7F
	pop	hl
	ld	(hl), a
	pop	de
	ld	a, b
	ret
; nb_kill (из KILLSHP): место B освободилось — флаги следующих мест сдвигаются вниз. Сохраняет BC.
nb_kill:
	ld	hl, newb
	ld	e, b
	ld	d, 0
	add	hl, de
	ld	a, NOSH
	sub	b
	ret	z
	ret	c
	ld	e, a
nb_k1:
	inc	hl
	ld	a, (hl)
	dec	hl
	ld	(hl), a
	inc	hl
	dec	e
	jp	nz, nb_k1
	ret
; nb_inf: HL -> флаги корабля, чей блок по адресу INF.
nb_inf:
	ld	hl, (INF)
	ld	de, -K_
	add	hl, de
	ld	de, -NI
	ld	c, 0xFF
nb_i1:
	inc	c
	add	hl, de
	jp	c, nb_i1
	ld	b, 0
	ld	hl, newb
	add	hl, bc
	ret
; nb_tact (из TACTICS, вместо проверок типа кассетной версии): поведение по флагам. Торговец большей частью
; ничего не делает; охотник за наградой нападает на преступника (FIST от 40); невраждебный корабль летит к планете
; или, если собрался стыковаться, — в станцию; пират у станции не нападает. Враждебные идут дальше, в боевую
; тактику (TA62). Случайное число — своё.
nb_tact:
	ld	a, (XSAV)
	ld	e, a
	ld	d, 0
	ld	hl, newb
	add	hl, de
	ld	d, (hl)
	call	mis_rnd
	ld	e, a
	ld	a, d
	rra
	jp	nc, nb_t1
	ld	a, e
	cp	100
	ret	nc
nb_t1:
	ld	a, d
	and	2
	jp	z, nb_t2
	ld	a, (FIST)
	cp	40
	jp	c, nb_t2
	ld	a, d
	or	4
	ld	d, a
	ld	(hl), a
nb_t2:
	ld	a, d
	and	4
	jp	nz, nb_t3
	ld	a, d
	and	0x10
	jp	nz, DOCKIT
	ld	a, 4			; к планете: поворотливость обычной тактики диска (RAT 3, RAT2 4, CNT2 22)
	ld	(RAT2), a
	dec	a
	ld	(RAT), a
	ld	a, 22
	ld	(CNT2), a
	jp	dk_gopl
nb_t3:
	ld	a, d
	and	8
	jp	z, TA62
	ld	a, (SSPR)
	or	a
	jp	z, TA62
	ld	hl, INWK + 32
	ld	a, (hl)
	and	0x81
	ld	(hl), a
	jp	TA62
	endif
