; Планета и солнце: PLANET, PL2, PLS1–PLS5, PLS2, PLS22, ARCTAN, WPLS2, WP1, SUN, WPLS, EDGES, HLOIN2.
; Перенесено близко к тексту BBC, с его особенностями (перенос из сложения в координату точки меридиана).
; Сверка — v06c/test/t25.mjs. По умолчанию планета — простая окружность (как на ZX Spectrum); меридианы и
; кратер BBC собираются с -DMERID.

	ifndef	SCHED
	ifndef	MERID
	define	PCIRC			; окружность планеты точками (pcirc)
	endif
	endif
	ifdef	MERID			; меридианы и кратер планеты — только в сборке -DMERID (как на BBC)
; Арктангенс: ACT+n = 128 / pi · atan(n / 32), округлённо, n = 0..31.
ACT:
	db	0, 1, 3, 4, 5, 6, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18
	db	19, 20, 21, 22, 23, 24, 25, 25, 26, 27, 28, 29, 29, 30, 31, 31

; ARCTAN: A = arctan(P / Q) в 256-х долях круга, знаки P и Q — в битах 7.
ARCTAN:
	ld	a, (P_)
	ld	hl, Q
	xor	(hl)
	ld	(T1), a
	ld	a, (hl)
	or	a
	jp	z, ar2
	add	a, a
	ld	(hl), a
	ld	d, a
	ld	a, (P_)
	add	a, a
	cp	d
	jp	nc, ar1
	call	ARS1
	scf
ar4:
	push	af
	ld	a, (T1)
	ld	b, a
	or	a
	jp	m, ar3
	pop	af
	ret
ar3:
	pop	af
	ld	(T), a
	ld	e, a
	ld	a, 128
	jp	c, ar3_s
	dec	a
ar3_s:
	sub	e
	ccf
	ret
ar1:
	ld	e, a
	ld	a, d
	ld	(P_), a
	ld	a, e
	ld	(Q), a
	ld	a, d
	call	ARS1
	ld	(T), a
	ld	e, a
	ld	a, 64
	jp	c, ar1_s
	dec	a
ar1_s:
	sub	e
	jp	c, ar2
	scf
	jp	ar4
ar2:
	ld	a, 63
	ret
; ARS1: A = arctan(A / Q) по таблице, A < Q; перенос — бит 2 частного (как на BBC)
ARS1:
	call	LL28
	ld	a, (R_)
	or	a
	rra
	or	a
	rra
	or	a
	rra
	push	af
	ld	b, a
	ld	e, a
	ld	d, 0
	ld	hl, ACT
	add	hl, de
	pop	af
	ld	a, (hl)
	ret

; PLS1: A = INWK(X+1 X) / z (не больше 254), Y — знак; X += 2.
PLS1:
	ld	hl, INWK
	ld	e, b
	ld	d, 0
	add	hl, de
	ld	a, (hl)
	ld	(P_), a
	inc	hl
	ld	a, (hl)
	ld	d, a
	and	0x7F
	ld	(P_ + 1), a
	ld	a, d
	and	0x80
	call	DVID3B2
	ld	a, (K + 1)
	or	a
	ld	a, (K)
	jp	z, pls1_a
	ld	a, 254
pls1_a:
	ld	d, a
	ld	a, (K + 3)
	ld	c, a
	ld	a, d
	inc	b
	inc	b
	ret
; PLS3: (Y A) = 222 · INWK(X+1 X) / z со знаком — смещение центра кратера.
PLS3:
	call	PLS1
	ld	(P_), a
	ld	a, 222
	ld	(Q), a
	ld	a, b
	ld	(U), a
	call	MULTU
	ld	d, a
	ld	a, (U)
	ld	b, a
	ld	a, (K + 3)
	or	a
	ld	a, d
	jp	p, pl12
	cpl
	add	a, 1
	jp	z, pl12
	ld	c, 0xFF
	ret
pl12:
	ld	c, 0
	ret
; PLS4: CNT2 = arctan(P / A) / 4 — с какой точки начинать меридиан.
PLS4:
	ld	(Q), a
	call	ARCTAN
	ld	d, a
	ld	a, (INWK + 14)
	ld	b, a
	or	a
	ld	a, d
	jp	m, pls4_a
	xor	0x80
pls4_a:
	rrca
	rrca
	and	0x3F
	ld	(CNT2), a
	ret
; PLS5: K2+2, K2+3 и их знаки XX16+2, XX16+3 = INWK(X+1 X) / z и следующая пара.
PLS5:
	call	PLS1
	ld	(K2 + 2), a
	ld	a, c
	ld	(XX16 + 2), a
	call	PLS1
	ld	(K2 + 3), a
	ld	a, c
	ld	(XX16 + 3), a
	ret

	endif

; PLANET: планета или солнце из блока INWK (TYPE: 128, 130 — планета, 129 — солнце).
PL2:
	ld	a, (TYPE)
	rrca
	jp	c, wpls_red
	jp	WPLS2
PLANET:
	ld	a, (INWK + 8)
	or	a
	jp	m, PL2
	cp	48
	jp	nc, PL2
	ld	hl, INWK + 7
	or	(hl)
	jp	z, PL2
	call	PROJ
	jp	c, PL2
	ld	hl, 0x6000		; радиус на экране K = 24576 / z
	ld	(P_), hl
	xor	a
	call	DVID3B2
	ld	a, (K + 1)
	or	a
	jp	z, pl82
	ld	a, 248
	ld	(K), a
pl82:
	ld	a, (TYPE)
	rrca
	jp	c, sun_red
	ifdef	PCIRC
	call	pc_try			; окружность целиком в обзоре — рисуется точками (pcirc)
	ret	z
	endif
	call	wp_begin		; прежняя окружность стирается по отрезку вслед за новой (wp_step в BLINE) — без мерцания
	call	CIRCLE
	ifndef	MERID
	jp	wp_finish		; планета — окружность, как на ZX Spectrum (решение владельца); в эталоне — RTS в PL25
	else
	push	af
	call	wp_finish
	pop	af
	ret	c
	ld	a, (K + 1)
	or	a
	ret	nz
	ld	a, (TYPE)
	cp	128
	jp	nz, pl26
	ld	a, (K)			; планета с меридианами
	cp	6
	ret	c
	ld	a, (INWK + 14)
	xor	0x80
	ld	(P_), a
	ld	a, (INWK + 20)
	call	PLS4
	ld	b, 9
	call	pl_k2
	ld	b, 15
	call	PLS5
	call	PLS2
	ld	a, (INWK + 14)
	xor	0x80
	ld	(P_), a
	ld	a, (INWK + 26)
	call	PLS4
	ld	b, 21
	call	PLS5
	jp	PLS2
pl_k2:					; K2, K2+1, XX16, XX16+1 по двум парам с INWK+X
	call	PLS1
	ld	(K2), a
	ld	a, c
	ld	(XX16), a
	call	PLS1
	ld	(K2 + 1), a
	ld	a, c
	ld	(XX16 + 1), a
	ret
pl26:					; планета с кратером
	ld	a, (INWK + 20)
	or	a
	ret	m
	ld	b, 15
	call	PLS3
	ld	hl, K3
	add	a, (hl)
	ld	(hl), a
	inc	hl
	ld	a, c
	adc	a, (hl)
	ld	(hl), a
	call	PLS3
	ld	(P_), a
	ld	e, a
	ld	hl, K4
	ld	a, (hl)
	sub	e
	ld	(hl), a
	ld	a, c
	ld	(P_), a
	ld	e, a
	inc	hl
	ld	a, (hl)
	sbc	a, e
	ld	(hl), a
	ld	b, 9
	ld	hl, K2
	ld	de, XX16
	call	pl26_h
	call	pl26_h
	ld	b, 21
	call	pl26_h
	call	pl26_h
	ld	a, 64
	ld	(TGT), a
	xor	a
	ld	(CNT2), a
	jp	PLS22
pl26_h:
	push	hl
	push	de
	call	PLS1
	pop	de
	pop	hl
	or	a
	rra
	ld	(hl), a
	ld	a, c
	ld	(de), a
	inc	hl
	inc	de
	ret

; PLS2: половина эллипса (меридиан). PLS22: эллипс до точки TGT, начиная с CNT2: центр K3, K4; полуоси —
; векторы (K2, K2+1) и (K2+2, K2+3) со знаками в XX16..XX16+3.
PLS2:
	ld	a, 31
	ld	(TGT), a
PLS22:
	xor	a
	ld	(CNT), a
	dec	a
	ld	(FLAG), a
pll4:
	ld	a, (CNT2)		; sin/cos · полуоси через mul8 (без FMLTU/Q)
	call	pl_sin
	ld	e, a
	ld	a, (K2 + 2)
	call	mul8
	ld	a, h
	ld	(R_), a
	ld	a, (K2 + 3)
	ld	e, a
	ld	a, (Q)
	call	mul8
	ld	a, h
	ld	(K), a
	ld	a, (CNT2)
	cp	33
	ccf
	ld	a, 0
	rra
	ld	(XX16 + 5), a
	ld	a, (CNT2)
	add	a, 16
	call	pl_sin
	ld	e, a
	ld	a, (K2 + 1)
	call	mul8
	ld	a, h
	ld	(K + 2), a
	ld	a, (K2)
	ld	e, a
	ld	a, (Q)
	call	mul8
	ld	a, h
	ld	(P_), a
	ld	a, (CNT2)
	add	a, 16
	and	63
	cp	33
	ccf
	ld	a, 0
	rra
	ld	(XX16 + 4), a
	ld	hl, XX16 + 2		; x
	ld	a, (XX16 + 5)
	xor	(hl)
	ld	(S), a
	ld	hl, XX16
	ld	a, (XX16 + 4)
	xor	(hl)
	call	ADD
	ld	(T), a
	ld	d, a
	inc	d
	dec	d
	jp	p, pl42
	xor	0x7F
	ld	d, a
	ld	a, b
	cpl
	add	a, 1
	ld	b, a
	ld	a, d
	adc	a, 0
	ld	d, a
	ld	(T), a
pl42:
	ld	hl, K3			; перенос на входе — как на BBC
	ld	a, b
	adc	a, (hl)
	ld	(K6), a
	inc	hl
	ld	a, d
	adc	a, (hl)
	ld	(K6 + 1), a
	ld	a, (K)			; y
	ld	(R_), a
	ld	hl, XX16 + 3
	ld	a, (XX16 + 5)
	xor	(hl)
	ld	(S), a
	ld	a, (K + 2)
	ld	(P_), a
	ld	hl, XX16 + 1
	ld	a, (XX16 + 4)
	xor	(hl)
	call	ADD
	ld	d, a
	ld	a, 0
	adc	a, 0
	ld	e, a			; перенос из сложения
	ld	a, d
	xor	0x80
	ld	d, a
	ld	(T), a
	jp	m, pl43_n
	ld	a, e
	rra
	jp	pl43
pl43_n:
	xor	0x7F
	ld	d, a
	ld	a, b
	cpl
	add	a, 1
	ld	b, a
	ld	a, d
	adc	a, 0
	ld	(T), a
pl43:
	call	BLINE
	ld	hl, TGT
	cp	(hl)
	jp	z, pl43_c
	ret	nc
pl43_c:
	ld	hl, STP
	ld	a, (CNT2)
	add	a, (hl)
	and	63
	ld	(CNT2), a
	jp	pll4
pl_sin:					; A = Q = синус угла A
	and	0x1F
	ld	e, a
	ld	d, 0
	ld	hl, SNE
	add	hl, de
	ld	a, (hl)
	ld	(Q), a
	ret

	endif

; Солнце в полёте — вторым цветом (на карте звёзды рисует та же SUN, но белым).
sun_red:
	call	col_red
	call	SUN
	jp	col_white
wpls_red:
	call	col_red
	call	WPLS
	jp	col_white

; WPLS2: стереть окружность планеты по списку LSX2, LSY2. WP1: список пуст.
; HL → LSY2, DE → LSX2: без пересчёта адреса на каждую точку.
WPLS2:
	ifdef	PCIRC
	call	pc_erase
	endif
	ld	a, (LSX2)
	or	a
	jp	nz, WP1
	ld	c, a
	ld	hl, LSY2
	ld	de, LSX2
wpl1:
	ld	a, (LSP)
	ld	b, a
	ld	a, c
	cp	b
	jp	nc, WP1
	ld	a, (hl)
	cp	0xFF
	jp	z, wp2
	ld	(Y2), a
	ld	a, (de)
	ld	(X2), a
	push	hl
	push	de
	call	LOIN
	pop	de
	pop	hl
	ld	a, (de)			; следующий отрезок — от этой точки (на BBC — по признаку SWAP)
	ld	(X1), a
	ld	a, (hl)
	ld	(Y1), a
	inc	c
	inc	hl
	inc	de
	jp	wpl1
wp2:
	inc	c
	inc	hl
	inc	de
	ld	a, (de)
	ld	(X1), a
	ld	a, (hl)
	ld	(Y1), a
	inc	c
	inc	hl
	inc	de
	jp	wpl1
WP1:
	ld	a, 1
	ld	(LSP), a
	ld	a, 0xFF
	ld	(LSX2), a
	ret

; Планета без мерцания. На BBC прежняя окружность стирается целиком (WPLS2), потом рисуется новая — между ними
; планеты на экране нет. Здесь прежний список отрезков копируется в сторону (wp_begin), новая окружность
; рисуется как обычно, а после каждого её отрезка стирается один прежний (wp_step из BLINE); остаток — wp_finish.
; Рисование — исключающее ИЛИ, от порядка итог не зависит: экран и рабочие области в конце — как на BBC.
; Ячейки X1, Y1, X2, Y2 после стирания возвращаются к тому, что оставила новая окружность (wp_touch).
wp_begin:
	xor	a
	ld	(wp_touch), a
	ld	(wp_i), a
	ld	(wp_n), a
	ld	hl, (X1)
	ld	(wp_x1), hl
	ld	a, (LSX2)
	or	a
	jp	nz, WP1			; списка нет
	ld	a, (LSP)
	ld	(wp_n), a
	or	a
	jp	z, WP1
	inc	a			; на запись больше: после разрыва в конце списка WPLS2 читает и её
	ld	b, a
	push	bc
	ld	hl, LSX2
	ld	de, wp_sx
	call	ll9_cp
	pop	bc
	ld	hl, LSY2
	ld	de, wp_sy
	call	ll9_cp
	jp	WP1
wp_finish:
	ld	a, (wp_i)
	ld	c, a
	ld	a, (wp_n)
	cp	c
	jp	z, wf_end
	jp	c, wf_end
	call	wp_step
	jp	wp_finish
wf_end:
	xor	a
	ld	(wp_n), a
	ret
; wp_step: стереть один прежний отрезок (если остались). Портит A, BC, DE, HL.
wp_step:
	ld	a, (wp_i)
	ld	c, a
ws_l:
	ld	a, c
	ld	hl, wp_n
	cp	(hl)
	ret	nc			; i >= n — всё стёрто (и когда списка нет: n = 0)
	ld	b, 0
	ld	hl, wp_sy
	add	hl, bc
	ld	a, (hl)
	cp	0xFF
	jp	z, ws_brk
	ld	e, a			; конец отрезка: y
	ld	hl, wp_sx
	add	hl, bc
	ld	d, (hl)			; x
	inc	c
	ld	a, c
	ld	(wp_i), a
	ld	hl, (X1)		; X1, Y1 и X2, Y2 — на стек
	push	hl
	ld	hl, (X2)
	push	hl
	ld	hl, (wp_x1)
	ld	(X1), hl
	ld	a, d
	ld	(X2), a
	ld	(wp_x1), a
	ld	a, e
	ld	(Y2), a
	ld	(wp_x1 + 1), a
	call	LOIN
	pop	hl
	pop	de
	ld	a, (wp_touch)
	or	a
	jp	nz, ws_back
	ld	hl, (wp_x1)		; новая окружность X1..Y2 не трогала: оставить как после WPLS2 —
	ld	(X1), hl		; начало следующего отрезка
	ret
ws_back:
	ld	(X2), hl
	ex	de, hl
	ld	(X1), hl
	ret
ws_brk:					; разрыв: следующая запись — начало нового куска
	inc	c
	ld	hl, wp_sx
	add	hl, bc
	ld	a, (hl)
	ld	(wp_x1), a
	ld	hl, wp_sy
	add	hl, bc
	ld	a, (hl)
	ld	(wp_x1 + 1), a
	inc	c
	ld	a, c
	ld	(wp_i), a
	ld	a, (wp_touch)
	or	a
	jp	nz, ws_l
	ld	hl, (wp_x1)
	ld	(X1), hl
	jp	ws_l
	ifdef	PCIRC
; Окружность планеты точками (обычный образ; в образе стенда и с меридианами — отрезками, как на BBC).
; Алгоритм средней точки с восьмикратной симметрией и отсечением по обзору, без списка отрезков. На экране такая
; окружность отмечена LSX2 = 1, её данные — pc_s (x центра — слово, младший байт y, радиус); стирание — повтор.
; Та же окружность, что уже на экране, не перерисовывается. Радиус от 128 или строки дальше 64 за краем —
; прежний путь (CIRCLE). pc_try: Z — сделано; NZ — рисовать прежним путём (быстрая, если была, уже стёрта).
pc_try:
	ld	a, (K + 1)
	or	a
	jp	nz, pc_old
	ld	a, (K)
	cp	3
	jp	c, pc_old
	dec	a			; как у окружности BBC: наибольший размах — K · 255 / 256
	jp	m, pc_old
	ld	b, a			; B = радиус
	push	bc
	call	CHKON
	pop	bc
	jp	c, pc_old
	ld	hl, (K4)
	ld	e, b
	ld	d, 0
	add	hl, de
	ld	a, h
	or	a
	jp	nz, pc_old		; нижний край дальше строки 255
	ld	hl, (K4)
	ld	a, l
	sub	b
	ld	l, a
	ld	a, h
	sbc	a, d
	ld	h, a
	ld	e, 64
	add	hl, de
	ld	a, h
	or	a
	jp	m, pc_old		; верхний край выше строки -64
	ld	hl, (K3)
	ld	(pc_n), hl
	ld	a, (K4)
	ld	l, a
	ld	h, b
	ld	(pc_n + 2), hl
	ld	a, (LSX2)
	dec	a
	jp	nz, pc_new		; на экране не быстрая окружность
	ld	hl, pc_n
	ld	de, pc_s
	ld	c, 4
pc_cmp:
	ld	a, (de)
	cp	(hl)
	jp	nz, pc_chg
	inc	hl
	inc	de
	dec	c
	jp	nz, pc_cmp
	ret				; та же окружность
pc_chg:
	ld	hl, pc_n
	call	pcirc			; новая, затем стереть прежнюю — без мерцания
	ld	hl, pc_s
	call	pcirc
pc_keep:
	ld	hl, (pc_n)
	ld	(pc_s), hl
	ld	hl, (pc_n + 2)
	ld	(pc_s + 2), hl
	xor	a
	ret
pc_new:
	ld	hl, pc_n
	call	pcirc
	call	WPLS2			; прежняя — по списку отрезков, если была
	ld	a, 1
	ld	(LSX2), a
	jp	pc_keep
pc_old:
	call	pc_erase
	or	1
	ret
; pc_erase: стереть быструю окружность, если она на экране.
pc_erase:
	ld	a, (LSX2)
	dec	a
	ret	nz
	ld	hl, pc_s
	call	pcirc
	jp	WP1
; pc_col: HL = x (со знаком) -> D = старший байт адреса столбца, A = маска точки. Портит E, HL.
pc_col:
	ld	a, l
	and	7
	add	a, low TWOS
	ld	e, a
	ld	d, high TWOS
	ld	a, (de)
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	ld	e, a
	ld	a, h
	add	a, high SCR_VIEW
	ld	d, a
	ld	a, e
	ret
; pc_pt: точка HL с маской A, если она в обзоре. Портит A, E.
pc_pt:
	ld	e, a
	ld	a, h
	sub	high SCR_VIEW
	cp	32
	ret	nc
	ld	a, l
	cp	64
	ret	c
	ld	a, e
	xor	(hl)
	ld	(hl), a
	ret
; Две точки одного столбца: HL и на dlt байт дальше; msk — откуда взять маску.
	macro	PCPAIR msk, dlt
	ld	a, h
	sub	high SCR_VIEW
	cp	32
	jp	nc, .e			; столбец за краем
	ld	a, l
	cp	64
	jp	c, .a			; строка за краем
	ld	a, msk
	xor	(hl)
	ld	(hl), a
.a:
	ld	a, l
	add	a, dlt
	ld	l, a
	cp	64
	jp	c, .e
	ld	a, msk
	xor	(hl)
	ld	(hl), a
.e:
	endm
; pcirc: окружность исключающим ИЛИ. HL -> x центра (слово), y центра (байт), радиус (2..127).
; В цикле: B = 2y, C = 2x, D и E — маски точек в столбцах X + x и X - x; адреса — в командах. Строка y — байт
; адреса 255 - y; строки вне 0..191 дают байт меньше 64. Портит всё.
pcirc:
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	inc	hl
	ld	c, (hl)
	inc	hl
	ld	b, (hl)			; DE = X, C = Y, B = r
	push	de
	ld	l, b
	ld	h, 0
	add	hl, de
	call	pc_col			; столбец X + r
	ld	(pc_m3), a
	ld	a, d
	ld	(pc_p3 + 2), a
	pop	de
	push	de
	ld	a, e
	sub	b
	ld	l, a
	ld	a, d
	sbc	a, 0
	ld	h, a
	call	pc_col			; столбец X - r
	ld	(pc_m4), a
	ld	a, d
	ld	(pc_h4 + 1), a
	ld	a, c
	cpl
	ld	(pc_p3 + 1), a		; строка Y
	sub	b
	ld	(pc_p1 + 1), a		; строка Y + r
	ld	hl, (pc_p3 + 1)
	ld	a, (pc_m3)
	call	pc_pt			; (X + r, Y)
	ld	hl, (pc_p3 + 1)
	ld	a, (pc_h4 + 1)
	ld	h, a
	ld	a, (pc_m4)
	call	pc_pt			; (X - r, Y)
	pop	hl
	call	pc_col			; столбец X
	ld	e, a
	ld	a, d
	ld	(pc_p1 + 2), a
	ld	(pc_h2 + 1), a
	ld	d, e
	ld	a, b
	cpl
	ld	l, a
	ld	h, 0xFF
	inc	hl
	inc	hl
	ld	(pc_d), hl		; d = 1 - r
	ld	a, b
	add	a, a
	ld	b, a			; B = 2y
	ld	c, 0			; C = 2x
	call	pc_pair1		; (X, Y + r), (X, Y - r)
pc_loop:
	inc	c
	inc	c			; x + 1: столбец X + x вправо, X - x влево, строка Y + x дальше
	ld	a, d
	rrca
	ld	d, a
	jp	nc, pc_1
	ld	hl, pc_p1 + 2
	inc	(hl)
pc_1:
	ld	a, e
	rlca
	ld	e, a
	jp	nc, pc_2
	ld	hl, pc_h2 + 1
	dec	(hl)
pc_2:
	ld	hl, pc_p3 + 1
	dec	(hl)
	ld	hl, (pc_d)
	ld	a, h
	or	a
	jp	m, pc_noy
	dec	b			; y - 1: d -= 2y
	dec	b
	ld	a, l
	sub	b
	ld	l, a
	jp	nc, $ + 4
	dec	h
	push	hl
	ld	hl, pc_p1 + 1		; строка Y + y ближе к центру
	inc	(hl)
	ld	hl, pc_m3		; столбец X + y влево
	ld	a, (hl)
	rlca
	ld	(hl), a
	jp	nc, pc_3
	ld	hl, pc_p3 + 2
	dec	(hl)
pc_3:
	ld	hl, pc_m4		; столбец X - y вправо
	ld	a, (hl)
	rrca
	ld	(hl), a
	jp	nc, pc_4
	ld	hl, pc_h4 + 1
	inc	(hl)
pc_4:
	pop	hl
pc_noy:
	ld	a, c			; d += 2x + 1
	inc	a
	add	a, l
	ld	l, a
	jp	nc, $ + 4
	inc	h
	ld	(pc_d), hl
	ld	a, b
	cp	c
	ret	c			; x > y — конец
	call	pc_pair1		; (X + x, Y ± y)
	ld	hl, (pc_p1 + 1)
pc_h2:
	ld	h, 0			; (X - x, Y ± y)
	PCPAIR	e, b
	ld	a, b
	cp	c
	ret	z			; x = y: вторая четвёрка совпала бы с первой
pc_p3:
	ld	hl, 0			; (X + y, Y ± x)
	PCPAIR	(pc_m3), c
	ld	hl, (pc_p3 + 1)
pc_h4:
	ld	h, 0			; (X - y, Y ± x)
	PCPAIR	(pc_m4), c
	jp	pc_loop
pc_pair1:
pc_p1:
	ld	hl, 0
	PCPAIR	d, b
	ret
pc_s:	ds	4			; быстрая окружность на экране: x (слово), y, радиус
pc_n:	ds	4			; новая
pc_d:	dw	0
pc_m3:	db	0
pc_m4:	db	0
	endif
wp_n:	db	0			; длина прежнего списка (0 — стирать нечего)
wp_i:	db	0			; сколько записей уже разобрано
wp_touch:	db	0		; новая окружность уже писала X1..Y2
wp_x1:	dw	0			; начало очередного прежнего отрезка: x, y

; EDGES: строка солнца: X1, X2 = YY(1 0) ∓ A, обрезанные по экрану; перенос 1 — строка не видна (LSO+Y = 0).
EDGES:
	ld	(T), a
	ld	e, a
	ld	hl, (YY)
	ld	a, l
	add	a, e
	ld	(X2), a
	ld	a, h
	adc	a, 0
	jp	m, ed1
	jp	z, ed_l
	ld	a, 254
	ld	(X2), a
ed_l:
	ld	a, l
	sub	e
	ld	(X1), a
	ld	a, h
	sbc	a, 0
	jp	nz, ed3
	or	a
	ret
ed3:
	jp	p, ed1
	ld	a, 2
	ld	(X1), a
	or	a
	ret
ed1:
	ld	hl, LSO
	ld	b, 0
	add	hl, bc
	ld	(hl), 0
	xor	a
	scf
	ret
; HLOIN2: строка солнца полушириной A в строке Y вокруг YY; LSO+Y обнуляется.
HLOIN2:
	call	EDGES
	ld	a, c
	ld	(Y1), a
	ld	hl, LSO
	ld	b, 0
	add	hl, bc
	ld	(hl), 0
	jp	HLOIN

; WPLS: стереть солнце по списку строк LSO.
WPLS:
	ld	a, (LSX)
	or	a
	ret	m
	ld	hl, (SUNX)
	ld	(YY), hl
	ld	c, DASH_Y - 1
wpl2:
	call	sun_lso
	call	nz, HLOIN2
	dec	c
	jp	nz, wpl2
	dec	c
	ld	a, c
	ld	(LSX), a
	ret
sun_lso:				; A = LSO+Y, Z — ноль
	ld	hl, LSO
	ld	b, 0
	add	hl, bc
	ld	a, (hl)
	or	a
	ret

; sun_sqrt: Q = целый корень из (R Q), как LL5, но не побитовым счётом: соседние строки круга отличаются мало,
; поэтому корень подправляется от корня предыдущей строки (sun_q) по таблице квадратов SQLO (q² лежит в ней по
; номеру 2q). Перенос на выходе — как у LL5: 1, если остаток не меньше 256 (проверено перебором всех 65 536
; значений на модели); S = T = 0. Регистры на выходе другие — в SUN они не нужны.
sun_sqrt:
	ld	hl, (Q)			; L = Q, H = R — соседние ячейки
	ld	b, h
	ld	c, l
	ld	a, (sun_q)
ss_dn:					; пока q² больше числа — q убывает
	ld	d, a
	add	a, a
	ld	l, a
	ld	a, high SQLO
	adc	a, 0
	ld	h, a
	ld	e, (hl)
	inc	h
	inc	h
	ld	h, (hl)
	ld	l, e
	ld	a, c
	sub	l
	ld	l, a
	ld	a, b
	sbc	a, h
	ld	h, a
	ld	a, d
	jp	nc, ss_ok
	dec	a
	jp	ss_dn
ss_ok:
	ld	c, a			; C = q, HL = остаток
ss_up:					; пока остаток не меньше 2q + 1 — q растёт
	ld	a, c
	add	a, a
	ld	e, a
	ld	a, 0
	rla
	ld	d, a
	inc	de
	ld	a, l
	sub	e
	ld	b, a
	ld	a, h
	sbc	a, d
	jp	c, ss_end
	ld	h, a
	ld	l, b
	inc	c
	jp	ss_up
ss_end:
	ld	a, c
	ld	(Q), a
	ld	(sun_q), a
	xor	a
	ld	(S), a
	ld	(T), a
	ld	a, h
	add	a, 0xFF
	ret

; SUN: солнце — круг радиуса K из горизонтальных строк с рваным краем; прежние строки (LSO) стираются
; и рисуются новые за один проход сверху вниз.
SUN:
	ld	a, 1
	ld	(LSX), a
	call	CHKON
	jp	c, WPLS
	ld	a, (K)			; бахрома: чем больше солнце, тем длиннее
	ld	b, a
	xor	a
	ld	d, a
	ld	a, b
	cp	96
	ccf
	ld	a, d
	rla
	ld	d, a
	ld	a, b
	cp	40
	ccf
	ld	a, d
	rla
	ld	d, a
	ld	a, b
	cp	16
	ccf
	ld	a, d
	rla
	ld	(CNT), a
	ld	a, (P_ + 2)		; TGT — нижняя строка солнца на экране
	or	a
	ld	a, DASH_Y - 1
	jp	nz, sun_f2
	ld	hl, P_ + 1
	cp	(hl)
	jp	c, sun_f2
	ld	a, (hl)
	or	a
	jp	nz, sun_f2
	ld	a, 1
sun_f2:
	ld	(TGT), a
	ld	hl, (K4)		; V — расстояние по вертикали от нижней строки экрана до центра
	ld	a, DASH_Y - 1
	sub	l
	ld	b, a
	ld	a, 0
	sbc	a, h
	jp	m, plf3
	jp	nz, plf4
	inc	b
	dec	b
	jp	z, plf17
	ld	a, (K)
	ld	d, a
	ld	a, b
	cp	d
	ld	a, 0
	jp	c, plf5
plf4:
	ld	a, (K)
	ld	b, a
	xor	a
	jp	plf5
plf3:
	ld	a, b
	cpl
	inc	a
	ld	b, a
plf17:
	ld	a, 0xFF
plf5:
	ld	(V + 1), a
	ld	a, b
	ld	(V), a
	ld	a, (K)
	call	SQUA2
	ld	(K2 + 1), a
	ld	a, (P_)
	ld	(K2), a
	ld	c, DASH_Y - 1
	ld	hl, (SUNX)
	ld	(YY), hl
plfl2:					; стереть прежние строки ниже нового солнца
	ld	a, (TGT)
	cp	c
	jp	z, plfl
	call	sun_lso
	call	nz, HLOIN2
	dec	c
	jp	nz, plfl2
plfl:
	ld	a, (V)			; полуширина строки: корень из K^2 - V^2 плюс случайная бахрома
	call	SQUA2
	ld	(T), a
	ld	e, a
	ld	hl, P_
	ld	a, (K2)
	sub	(hl)
	ld	(Q), a
	ld	a, (K2 + 1)
	sbc	a, e
	ld	(R_), a
	ld	a, c
	ld	(Y1), a
	call	sun_sqrt		; на BBC здесь LL5; результат и перенос те же
	ld	a, (Y1)
	ld	c, a
	call	DORND
	ld	hl, CNT
	and	(hl)
	ld	hl, Q
	add	a, (hl)
	jp	nc, plf44
	ld	a, 255
plf44:
	ld	e, a
	ld	hl, LSO
	ld	b, 0
	add	hl, bc
	ld	d, (hl)			; прежняя полуширина
	ld	(hl), e
	inc	d
	dec	d
	jp	z, plf11
	ld	hl, (SUNX)
	ld	(YY), hl
	ld	a, d
	call	EDGES
	ld	hl, (X1)
	ld	a, l
	ld	(XX), a
	ld	a, (X2)
	ld	(XX + 1), a
	ld	hl, (K3)
	ld	(YY), hl
	call	sun_lso
	call	EDGES
	jp	c, plf23
	ld	a, (XX)			; две строки: стереть и нарисовать только разницу по краям
	ld	d, a
	ld	a, (X2)
	ld	(XX), a
	ld	a, d
	ld	(X2), a
	call	HLOIN
plf23:
	ld	a, (XX)
	ld	(X1), a
	ld	a, (XX + 1)
	ld	(X2), a
plf16:
	call	HLOIN
plf6:
	dec	c
	jp	z, plf8
	ld	a, (V + 1)
	or	a
	jp	nz, plf10
	ld	hl, V
	dec	(hl)
	jp	nz, plfl
	ld	hl, V + 1
	dec	(hl)
	jp	plfl
plf11:
	ld	hl, (K3)
	ld	(YY), hl
	ld	a, e
	call	EDGES
	jp	nc, plf16
	ld	hl, LSO
	ld	b, 0
	add	hl, bc
	ld	(hl), 0
	jp	plf6
plf10:
	ld	hl, V
	inc	(hl)
	ld	a, (K)
	cp	(hl)
	jp	nc, plfl
	ld	hl, (SUNX)
	ld	(YY), hl
plfl3:					; стереть прежние строки выше нового солнца
	call	sun_lso
	call	nz, HLOIN2
	dec	c
	jp	nz, plfl3
plf8:
	ld	hl, (K3)
	ld	(SUNX), hl
	or	a
	ret
