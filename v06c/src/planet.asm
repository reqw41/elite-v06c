; Планета и солнце: PLANET, PL2, PLS1–PLS5, PLS2, PLS22, ARCTAN, WPLS2, WP1, SUN, WPLS, EDGES, HLOIN2.
; Перенесено близко к тексту BBC, с его особенностями (перенос из сложения в координату точки меридиана).
; Сверка — v06c/test/t25.mjs. По умолчанию планета — простая окружность (как на ZX Spectrum); меридианы и
; кратер BBC собираются с -DMERID.

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
	call	pc_try			; окружность рисуется точками (pcirc)
	ret	z
	ifdef	DBUF
	call	wp_begin		; не подошла (радиус от 128): отрезками
	call	CIRCLE
	jp	wp_finish
	else
	jp	pl_circ			; не подошла (радиус от 128): отрезками, прежняя стирается по углу (wp_ang)
	endif
	else
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
	endif			; PCIRC

	ifdef	PCIRC
	ifndef	DBUF
; pl_circ: окружность планеты отрезками (CIRCLE); прежняя (копия списка, wp_begin) стирается не после всей новой,
; а по ходу: после каждого шага угла новой — до того же угла прежней (wp_ang). Шаг угла (STP) у большой планеты
; один и тот же, поэтому записи прежнего списка по углам известны: WP_ANG[k] — длина списка после шага k (пишется
; в том же проходе для следующего). Остаток — wp_finish; от порядка итог не зависит (исключающее ИЛИ).
; Быстрая окружность (точками), если была на экране, стирается после новой: на миг две, но не ни одной.
pl_circ:
	ld	a, (LSX2)
	dec	a
	push	af			; Z — на экране быстрая окружность pc_s
	call	wp_begin		; (списка отрезков тогда нет)
	xor	a
	ld	(wp_k), a
	inc	a
	ld	(wp_on), a
	call	CIRCLE
	xor	a
	ld	(wp_on), a
	call	wp_finish
	pop	af
	ret	nz
	ld	hl, pc_s
	jp	pcirc
; wp_ang: из CIRCLE2 после каждого BLINE (A = CNT — сохраняется). Портит BC, DE, HL.
wp_ang:
	push	af
	ld	a, (wp_on)
	or	a
	jp	z, wa_x
	ld	a, (wp_k)
	cp	WP_NA
	jp	nc, wa_x
	ld	e, a
	inc	a
	ld	(wp_k), a
	ld	d, 0
	ld	hl, WP_ANG
	add	hl, de
	push	hl
	ld	b, (hl)			; B — длина прежнего списка после этого шага
wa_l:
	ld	a, (wp_n)
	ld	c, a
	ld	a, (wp_i)
	cp	c
	jp	nc, wa_r		; прежний список кончился
	cp	b
	jp	nc, wa_r		; прежняя стёрта до этого угла
	push	bc
	call	wp_step
	pop	bc
	jp	wa_l
wa_r:
	pop	hl
	ld	a, (LSP)
	ld	(hl), a
wa_x:
	pop	af
	ret
wp_k:	db	0			; шаг угла новой окружности
wp_on:	db	0			; <> 0 — идёт pl_circ
	endif
	endif

; Солнце в полёте — вторым цветом (на карте звёзды рисует та же SUN, но белым).
sun_red:
	ifndef	SCHED
	ifdef	DBUF
SUN_FR		equ	50		; проход дольше: иначе солнце рисовалось бы заново каждый проход
	else
SUN_FR		equ	16		; бахрома неподвижного солнца — раз в столько кадров
	endif
; Обычный образ: солнце с тем же x, y и радиусом, что на экране, не перерисовывается; бахрома при этом
; обновляется раз в SUN_FR кадров. sun_ck — x, y (по слову) и радиус прошлого рисования.
	ld	hl, sun_ck
	ld	de, K3
	ld	bc, 0x0200		; B — байт, C — накопленная разница
	call	sk_cmp
	ld	de, K4
	ld	b, 2
	call	sk_cmp
	ld	de, K
	inc	b
	call	sk_cmp
	ld	hl, sun_t
	ld	a, (LSX)		; FFh — солнца на экране нет (стёрто, очищено)
	inc	a
	jp	z, sk_go
	ld	a, c
	or	a
	jp	nz, sk_go
	ld	a, (v_frames)
	sub	(hl)
	cp	SUN_FR
	ret	c
sk_go:
	ld	a, (v_frames)
	ld	(hl), a
	endif
	call	col_red
	call	SUN
	jp	col_white
wpls_red:
	call	col_red
	call	WPLS
	jp	col_white
	ifndef	SCHED
sk_cmp:					; B байт из DE в HL; C |= разница
	ld	a, (de)
	xor	(hl)
	or	c
	ld	c, a
	ld	a, (de)
	ld	(hl), a
	inc	hl
	inc	de
	dec	b
	jp	nz, sk_cmp
	ret
	endif

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

	ifdef	SCHED
	include	"wp_a.asm"		; в обычном образе — в нижней памяти (elite.asm)
	include	"wp_b.asm"
	endif
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
	ifdef	DBUF			; чёрно-белая сборка: плоскость каждый проход чистая (db_begin) — только новая
	ld	hl, pc_n
	call	pcirc
	ld	a, 1
	ld	(LSX2), a
	jp	pc_keep
	else
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
	ld	a, (pc_n + 3)		; тот же радиус (крен, тангаж, рыскание) — новая и прежняя одним ходом: точки
	ld	hl, pc_s + 3		; меняются вперемешку, без мига двух окружностей сразу (pc_pr2)
	cp	(hl)
	jp	nz, pc_chg2
	call	pc_pr2
	jp	pc_keep
pc_chg2:
	ld	hl, pc_n
	call	pcirc			; новая, затем стереть прежнюю — без мерцания
	ld	hl, pc_s
	call	pcirc
	endif
pc_keep:
	ld	hl, (pc_n)
	ld	(pc_s), hl
	ld	hl, (pc_n + 2)
	ld	(pc_s + 2), hl
	xor	a
	ret
	ifndef	DBUF
pc_new:
	ld	hl, pc_n
	call	pcirc
	call	WPLS2			; прежняя — по списку отрезков, если была
	ld	a, 1
	ld	(LSX2), a
	jp	pc_keep
	endif
pc_old:
	ifdef	DBUF
	call	pc_erase
	endif
	or	1			; обычный образ: быструю окружность сотрёт pl_circ — после новой
	ret
; pc_erase: стереть быструю окружность, если она на экране.
pc_erase:
	ld	a, (LSX2)
	dec	a
	ret	nz
	ld	hl, pc_s
	call	pcirc
	jp	WP1
; pc_col и pc_pt лежат в пустотах выравнивания (dials.asm, flight.asm, scan.asm).
; Две точки одного столбца: HL и на dlt байт дальше (строки Y - k и Y + k), маска — msk.
	macro	PCPAIR msk, dlt, sv
	ld	a, h
sv:	sub	high SCR_VIEW			; DBUF: плоскость рисования (db_tog)
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
; Окружность — одна (pcirc) или пара одного радиуса (pc_pr2: новая и стирание прежней одним ходом). Шаги алгоритма
; (x, y, d) у пары общие, у каждой окружности свои адреса и маски точек — в командах набора pa (первая) и pb
; (вторая) — pc_set.asm.
; Строка y — байт адреса 255 - y; строки вне 0..191 дают байт меньше 64.
	define	PCREG			; первый набор: маски X ± x — в регистрах D и E
	module	pa
	include	"pc_set.asm"
	endmodule
	undefine PCREG
	ifndef	DBUF			; чёрно-белой сборке пара не нужна: плоскость каждый проход чистая
	module	pb
	include	"pc_set.asm"
	endmodule
; pc_pr2: новая окружность pc_n и стирание прежней pc_s (радиус тот же) — одним ходом.
pc_pr2:
	ld	hl, pc_s
	call	pb.init
	ld	hl, pc_n
	call	pa.init
	ld	a, 0xCD			; call — шаги и точки второго набора
	jp	pc_go
	endif
; pcirc: окружность исключающим ИЛИ. HL -> x центра (слово), y центра (байт), радиус (2..127). Портит всё.
pcirc:
	call	pa.init
	ifndef	DBUF
	ld	a, 0x21			; ld hl,nn вместо call: второго набора нет
pc_go:
	ld	(pc_c1), a
	ld	(pc_c2), a
	ld	(pc_c3), a
	endif
pc_loop:
	inc	c
	inc	c
	call	pa.xs
	ifndef	DBUF
pc_c1:	call	pb.xs
	endif
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
	call	pa.ys
	ifndef	DBUF
pc_c2:	call	pb.ys
	endif
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
	call	pa.pl
	ifndef	DBUF
pc_c3:	call	pb.pl
	endif
	jp	pc_loop
pc_end:
; переменные — в рабочих областях (elite.asm, WS + 03CEh)
	endif
	ifdef	SCHED
	include	"wp_v.asm"
	endif

	ifdef	SCHED
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

	else
; sr_wps: стереть строки прежнего солнца (LSO, SUNX) от C вниз до D (её — нет), LSO = 0; пустые строки — в коротком
; цикле (их за проход больше сотни). На выходе C = D. Портит A, B, HL.
sr_wps:
	ld	hl, LSO
	ld	b, 0
	add	hl, bc
sw_l:
	ld	a, c
	cp	d
	ret	z
	ld	a, (hl)
	or	a
	jp	nz, sw_w
sw_n:
	dec	hl
	dec	c
	jp	sw_l
sw_w:
	ld	(hl), 0
	ld	b, a
	push	hl
	push	de
	ld	hl, (SUNX)
	ex	de, hl
	call	sun_e
	jp	c, sw_p
	ld	a, h
	ld	(X2), a
	ld	h, c
	ld	(X1), hl
	call	HLOIN
sw_p:
	pop	de
	pop	hl
	jp	sw_n
	endif
; строка C прежнего солнца — стереть (стенд)
	macro	SUNWIPE
	call	sun_lso
	call	nz, HLOIN2
	endm

; WPLS: стереть солнце по списку строк LSO.
WPLS:
	ld	a, (LSX)
	or	a
	ret	m
	ifdef	SCHED
	ld	hl, (SUNX)
	ld	(YY), hl
	endif
	ld	c, DASH_Y - 1
	ifdef	SCHED
wpl2:
	SUNWIPE
	dec	c
	jp	nz, wpl2
	else
	ld	d, 0
	call	sr_wps
	endif
	dec	c
	ld	a, c
	ld	(LSX), a
	ret
	ifdef	SCHED
sun_lso:				; A = LSO+Y, Z — ноль
	ld	hl, LSO
	ld	b, 0
	add	hl, bc
	ld	a, (hl)
	or	a
	ret
	endif

	ifdef	SCHED
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

	endif

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
	ifdef	SCHED
	ld	hl, (SUNX)
	ld	(YY), hl
	endif
plfl2:					; стереть прежние строки ниже нового солнца
	ld	a, (TGT)
	ifdef	SCHED
	cp	c
	jp	z, plfl
	SUNWIPE
	dec	c
	jp	nz, plfl2
	else
	ld	d, a
	call	sr_wps			; дальше — plfl
	endif
	ifdef	SCHED
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
	else
; Обычный образ: строка за строкой без умножений и корней. Полуширина q = целый корень из K² - V² ведётся
; шагами: V меняется на 1 за строку, остаток sun_r = K² - V² - q² держится в пределах 0..2q. Бахрома — байты
; кода игры подряд со случайного места (на BBC — DORND в каждой строке). Края — в регистрах (sun_e); рисуется
; только разница прежней и новой строк: HLOIN исключающим ИЛИ (oL..nL) и (oR..nR) — верно при любом их положении.
plfl:
	ld	a, (V + 1)
	or	a
	jp	z, sr_i
	ld	a, (K)			; центр ниже экрана дальше радиуса — строк нет
	ld	hl, V
	cp	(hl)
	jp	c, sr_end
sr_i:
	push	bc
	ld	a, (V)
	call	sr_sq			; HL = V²
	ex	de, hl
	ld	hl, (K2)		; K2 — младший байт K², K2 + 1 — старший
	ld	a, l
	sub	e
	ld	l, a
	ld	a, h
	sbc	a, d
	ld	h, a			; HL = K² - V²
	push	hl
	ld	(Q), hl			; (R Q)
	call	LL5
	ld	a, (Q)
	ld	(sun_q), a
	call	sr_sq			; HL = q²
	ex	de, hl
	pop	hl
	ld	a, l
	sub	e
	ld	l, a
	ld	a, h
	sbc	a, d
	ld	h, a
	ld	(sun_r), hl
	call	DORND			; A, B — случайные: место в коде игры
	and	0x3F
	add	a, 0x10
	ld	h, a
	ld	l, b
	ld	(sun_rp), hl
	pop	bc
sr_row:
	ld	hl, (sun_rp)
	ld	a, (hl)
	inc	hl
	ld	(sun_rp), hl
	ld	hl, CNT
	and	(hl)
	ld	hl, sun_q
	add	a, (hl)
	jp	nc, sr_f
	ld	a, 255
sr_f:
	ld	b, a
	ld	hl, (K3)
	ex	de, hl
	call	sun_e			; HL — края новой строки
	jp	nc, sr_v
	ld	b, 0			; строки нет на экране
sr_v:
	push	hl
	ld	d, b			; D — новая полуширина
	ld	hl, LSO
	ld	b, 0
	add	hl, bc
	ld	a, (hl)			; прежняя полуширина
	ld	(hl), d
	or	a
	jp	z, sr_o0
	ld	b, a
	push	de
	ld	hl, (SUNX)
	ex	de, hl
	call	sun_e			; края прежней строки (она была на экране)
	pop	af			; A — новая полуширина
	ex	de, hl			; DE — прежние края
	pop	hl			; HL — новые
	or	a
	jp	nz, sr_x
	ld	l, e			; новой нет: пустая в точке oL
	ld	h, e
	jp	sr_x
sr_o0:
	pop	hl
	inc	d
	dec	d
	jp	z, sr_next		; ни прежней, ни новой
	ld	e, l			; прежней нет: пустая в точке nL
	ld	d, l
sr_x:					; E, D — прежние левый и правый края; L, H — новые
	ld	a, l
	cp	e
	jp	nz, sr_d
	ld	a, h
	cp	d
	jp	z, sr_next		; строка та же
sr_d:
	push	hl
	ld	a, l
	ld	(X2), a
	ld	l, e
	ld	h, c
	ld	(X1), hl		; X1, Y1
	ld	e, d
	push	de
	call	HLOIN
	pop	de
	pop	hl
	ld	a, h
	ld	(X2), a
	ld	l, e
	ld	h, c
	ld	(X1), hl
	call	HLOIN
sr_next:
	dec	c
	jp	z, plf8
	ld	a, (sun_q)
	ld	b, a
	ld	hl, (sun_r)
	ld	a, (V + 1)
	or	a
	jp	nz, sr_up
	ld	a, (V)			; к центру: r += 2V - 1, V -= 1
	ld	e, a
	dec	a
	ld	(V), a
	jp	nz, sr_dn
	dec	a
	ld	(V + 1), a
sr_dn:
	ld	d, 0
	add	hl, de
	add	hl, de
	dec	hl
sr_dn2:					; пока r >= 2q + 1: r -= 2q + 1, q += 1
	call	sr_2q1
	ld	a, l
	sub	e
	ld	e, a
	ld	a, h
	sbc	a, d
	jp	c, sr_st
	ld	h, a
	ld	l, e
	inc	b
	jp	sr_dn2
sr_up:					; от центра: r -= 2V + 1, V += 1; V > K — солнце кончилось
	ld	a, (V)
	ld	e, a
	inc	a
	ld	(V), a
	ld	d, a
	ld	a, (K)
	cp	d
	jp	c, sr_end
	push	bc
	ld	b, e
	call	sr_2q1
	pop	bc
	ld	a, l
	sub	e
	ld	l, a
	ld	a, h
	sbc	a, d
	ld	h, a
sr_up2:					; пока r < 0: q -= 1, r += 2q + 1
	or	a
	jp	p, sr_st
	dec	b
	call	sr_2q1
	add	hl, de
	ld	a, h
	jp	sr_up2
sr_st:
	ld	(sun_r), hl
	ld	a, b
	ld	(sun_q), a
	jp	sr_row
sr_2q1:					; DE = 2B + 1
	ld	a, b
	add	a, a
	ld	e, a
	ld	a, 0
	rla
	ld	d, a
	inc	de
	ret
sr_sq:					; HL = A² — по таблице f(x) = x² / 4 под номером 2A
	ld	l, a
	ld	h, 0
	add	hl, hl
	ld	de, SQLO
	add	hl, de
	ld	e, (hl)
	inc	h
	inc	h
	ld	d, (hl)
	ex	de, hl
	ret
; sun_e: края строки полуширины B вокруг x = DE, как EDGES: L — левый (не меньше 2), H — правый (не больше 254);
; перенос 1 — строки на экране нет.
sun_e:
	ld	a, e
	add	a, b
	ld	h, a
	ld	a, d
	adc	a, 0
	jp	m, se_no
	jp	z, se_l
	ld	h, 254
se_l:
	ld	a, e
	sub	b
	ld	l, a
	ld	a, d
	sbc	a, 0
	ret	z
	jp	p, se_no
	ld	l, 2
	or	a
	ret
se_no:
	scf
	ret
sr_end:
	endif
plfl3:					; стереть прежние строки выше нового солнца
	ifdef	SCHED
	SUNWIPE
	dec	c
	jp	nz, plfl3
	else
	ld	d, 0
	call	sr_wps
	endif
plf8:
	ld	hl, (K3)
	ld	(SUNX), hl
	or	a
	ret
