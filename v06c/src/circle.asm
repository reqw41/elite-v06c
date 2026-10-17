; Окружности, взлётный туннель, прицел, луч лазера: CHKON, CIRCLE, CIRCLE2, BLINE, HFS1, HFS2, LAUN, TT15, SIGHT,
; LASLI2. Перенесено близко к тексту BBC; сверка — v06c/test/t24.mjs.

; Синус: SNE+n = 256 · |sin(n · 180° / 32)|, не больше 255, n = 0..31.
SNE:
	db	0, 25, 50, 74, 98, 121, 142, 162, 181, 198, 213, 226, 237, 245, 251, 255
	db	255, 255, 251, 245, 237, 226, 213, 198, 181, 162, 142, 121, 98, 74, 50, 25

	ifdef	SCHED			; в игре не вызывается — только из тестов (образ стенда)
; FMLTU2: A = K · sin(A): угол A в 64-х долях круга (берётся по модулю 32), X = угол.
; Синус и произведение — через mul8 (старший байт), как FMLTU, без второго прохода через ячейки.
FMLTU2:
	and	0x1F
	ld	b, a
	ld	e, a
	ld	d, 0
	ld	hl, SNE
	add	hl, de
	ld	a, (hl)
	ld	(Q), a
	ld	e, a
	ld	a, (K)
	call	mul8
	ld	a, h
	ld	d, a
	xor	a
	ld	(P_), a
	ld	a, d
	scf
	ret
	endif

; CHKON: помещается ли окружность (центр K3(1 0), K4(1 0), радиус K) на экран хотя бы частью.
; Перенос 1 — нет. При переносе 0: P(2 1) = нижний край, X = верхний край.
CHKON:
	ld	a, (K)
	ld	e, a
	ld	d, 0
	ld	hl, (K3)
	add	hl, de
	ld	a, h
	or	a
	jp	m, pl21
	ld	hl, (K3)
	ld	a, l
	sub	e
	ld	a, h
	sbc	a, 0
	jp	m, pl31
	jp	nz, pl21
pl31:
	ld	hl, (K4)
	add	hl, de
	ld	a, l
	ld	(P_ + 1), a
	ld	a, h
	or	a
	jp	m, pl21
	ld	(P_ + 2), a
	ld	hl, (K4)
	ld	a, l
	sub	e
	ld	b, a
	ld	a, h
	sbc	a, 0
	jp	m, pl44
	jp	nz, pl21
	ld	a, b
	cp	DASH_Y - 1
	ccf
	ld	a, 0
	ret
pl21:
	scf
	ret
pl44:
	or	a
	ret

; CIRCLE: окружность с проверкой CHKON; шаг по углу STP — по радиусу (8, 4 или 2). CIRCLE2: без проверки, шаг STP.
; Точки идут в список LSX2, LSY2 (BLINE), отрезки рисуются через отсечение LL145.
CIRCLE:
	call	CHKON
	ret	c
	xor	a
	ld	(LSX2), a
	ld	a, (K)
	ld	b, a
	cp	8
	ld	a, 8
	jp	c, pl89
	ld	a, b
	cp	60
	ld	a, 4
	jp	c, pl89
	ld	a, 2
pl89:
	ld	(STP), a
CIRCLE2:
	ld	a, 0xFF
	ld	(FLAG), a
	xor	a
	ld	(CNT), a
pll3:
	ld	a, (CNT)		; x = центр ± K · sin (mul8, без FMLTU2)
	and	0x1F
	ld	e, a
	ld	d, 0
	ld	hl, SNE
	add	hl, de
	ld	e, (hl)
	ld	a, (K)
	call	mul8
	ld	a, h
	ld	d, a
	xor	a
	ld	(T), a
	ld	a, (CNT)
	cp	33
	ld	a, d
	jp	c, pl37
	cpl
	add	a, 1
	ld	d, a
	ld	a, 0xFF
	adc	a, 0
	ld	(T), a
	ld	a, d
pl37:
	ld	hl, K3
	add	a, (hl)
	ld	(K6), a
	inc	hl
	ld	a, (T)
	adc	a, (hl)
	ld	(K6 + 1), a
	ld	a, (CNT)		; y = центр ± K · cos
	add	a, 16
	and	0x1F
	ld	e, a
	ld	d, 0
	ld	hl, SNE
	add	hl, de
	ld	e, (hl)
	ld	a, (K)
	call	mul8
	ld	a, h
	ld	b, a
	xor	a
	ld	(T), a
	ld	a, (CNT)
	add	a, 16
	and	63
	cp	33
	jp	c, pl38
	ld	a, b
	cpl
	add	a, 1
	ld	b, a
	ld	a, 0xFF
	adc	a, 0
	ld	(T), a
pl38:
	or	a			; перенос 0
	call	BLINE
	cp	65
	jp	c, pll3
	or	a
	ret

; BLINE: очередная точка окружности: X, T — смещение по y (младший и старший байты) и перенос; x уже в K6(1 0).
; Отрезок от прошлой точки K5 до новой K6 отсекается и рисуется, концы пишутся в LSX2, LSY2 (FFh в LSY2 —
; разрыв). Затем K5 = K6, CNT += STP. A = CNT.
BLINE:
	ld	hl, (K4)
	ld	a, b
	adc	a, l			; с переносом на входе, как на BBC (у планеты он бывает 1)
	ld	(K6 + 2), a
	ld	a, (T)
	adc	a, h
	ld	(K6 + 3), a
	ld	hl, FLAG
	ld	a, (hl)
	or	a
	jp	z, bl1
	inc	(hl)
bl5:
	ld	a, (LSP)		; разрыв, если его там ещё нет
	ld	e, a
	ld	d, 0
	ld	hl, LSY2 - 1
	add	hl, de
	ld	a, (hl)
	cp	0xFF
	jp	z, bl7
	inc	hl
	ld	(hl), 0xFF
	ld	hl, LSP
	inc	(hl)
	jp	bl7
bl1:
	ifdef	WPON
	ld	a, 1
	ld	(wp_touch), a		; дальше BLINE пишет X1..Y2 (см. wp_step в planet.asm)
	endif
	; быстрый путь: оба конца на экране (старшие байты 0, y < 192) — LL145 только переставляет байты
	ld	a, (K5 + 1)
	ld	hl, K5 + 3
	or	(hl)
	ld	hl, K6 + 1
	or	(hl)
	ld	hl, K6 + 3
	or	(hl)
	jp	nz, bl_clip
	ld	a, (K5 + 2)
	cp	192
	jp	nc, bl_clip
	ld	a, (K6 + 2)
	cp	192
	jp	nc, bl_clip
	xor	a
	ld	(SWAP), a
	ld	(XX13), a
	ld	a, (K5)
	ld	(X1), a
	ld	a, (K5 + 2)
	ld	(Y1), a
	ld	a, (K6)
	ld	(X2), a
	ld	a, (K6 + 2)
	ld	(Y2), a
	ld	hl, (K6)		; как после LL145: XX15+4 = x2, XX12 = y2 (16 бит)
	ld	(XX15 + 4), hl
	ld	hl, (K6 + 2)
	ld	(XX12), hl
	jp	bl9
bl_clip:
	ld	hl, (K5)
	ld	(XX15), hl
	ld	hl, (K5 + 2)
	ld	(XX15 + 2), hl
	ld	hl, (K6)
	ld	(XX15 + 4), hl
	ld	hl, (K6 + 2)
	ld	(XX12), hl
	call	LL145
	jp	c, bl5
	ld	a, (SWAP)
	or	a
	jp	z, bl9
	ld	hl, (X1)
	ex	de, hl
	ld	hl, (X2)
	ld	(X1), hl
	ex	de, hl
	ld	(X2), hl
bl9:
	ld	a, (LSP)
	ld	e, a
	ld	d, 0
	ld	hl, LSY2 - 1
	add	hl, de
	ld	a, (hl)
	inc	hl
	ld	bc, LSX2 - LSY2
	cp	0xFF
	jp	nz, bl8
	ld	a, (Y1)			; после разрыва — начало отрезка
	ld	(hl), a
	push	hl
	add	hl, bc
	ld	a, (X1)
	ld	(hl), a
	pop	hl
	inc	hl
	inc	e
bl8:
	ld	a, (Y2)
	ld	(hl), a
	add	hl, bc
	ld	a, (X2)
	ld	(hl), a
	inc	e
	ld	a, e
	ld	(LSP), a
	call	LOIN
	ld	a, (XX13)
	or	a
	jp	nz, bl5
bl7:
	ifdef	WPON
	call	wp_step			; планета: стереть один отрезок прежней окружности
	endif
	ld	hl, (K6)
	ld	(K5), hl
	ld	hl, (K6 + 2)
	ld	(K5 + 2), hl
	ld	hl, CNT
	ld	a, (STP)
	add	a, (hl)
	ld	(hl), a
	ret

; LAUN: взлётный туннель (звук — этап P6). HFS2: туннель из окружностей с шагом по углу A: очистка экрана и
; HFS1 дважды. HFS1: восемь серий окружностей с центром в середине экрана, радиус K = 8..15, удвоением до 160.
LAUN:
	ld	a, 48
	call	NOISE
	ld	a, 8
HFS2:
	ld	(STP), a
	call	TTX66
	call	HFS1
HFS1:
	ld	hl, 128
	ld	(K3), hl
	ld	hl, DASH_Y / 2
	ld	(K4), hl
	xor	a
	ld	(XX4), a
hfl5:
	call	hfl1
	ld	hl, XX4
	inc	(hl)
	ld	a, (hl)
	cp	8
	jp	nz, hfl5
	ld	b, a
	ret
hfl1:
	ld	a, (XX4)
	and	7
	add	a, 8
	ld	(K), a
hfl2:
	ld	a, 1
	ld	(LSP), a
	call	CIRCLE2
	ld	hl, K
	ld	a, (hl)
	add	a, a
	ld	(hl), a
	ret	c
	cp	160
	jp	c, hfl2
	ret

; TT15: перекрестие с центром (QQ19, QQ19+1) и полуразмером QQ19+2. На экранах карт (бит 7 QQ11) — без сдвига
; на 24 строки и без обрезки по нижнему краю.
TT15:
	ld	a, (QQ11)
	or	a
	ld	a, 24
	jp	p, tt15_a
	xor	a
tt15_a:
	ld	(QQ19 + 5), a
	ld	hl, QQ19 + 2
	ld	a, (QQ19)
	sub	(hl)
	jp	nc, tt84
	xor	a
tt84:
	ld	(XX15), a
	ld	a, (QQ19)
	add	a, (hl)
	jp	nc, tt85
	ld	a, 255
tt85:
	ld	(XX15 + 2), a
	ld	hl, QQ19 + 5
	ld	a, (QQ19 + 1)
	add	a, (hl)
	ld	(XX15 + 1), a
	call	HLOIN
	ld	hl, QQ19 + 2
	ld	a, (QQ19 + 1)
	sub	(hl)
	jp	nc, tt86
	xor	a
tt86:
	ld	hl, QQ19 + 5
	add	a, (hl)
	ld	(XX15 + 1), a
	ld	hl, QQ19 + 2
	ld	a, (QQ19 + 1)
	add	a, (hl)
	ld	hl, QQ19 + 5
	adc	a, (hl)
	cp	152
	jp	c, tt87
	ld	d, a
	ld	a, (QQ11)
	or	a
	ld	a, d
	jp	m, tt87
	ld	a, 151
tt87:
	ld	(XX15 + 3), a
	ld	a, (QQ19)
	ld	(XX15), a
	ld	(XX15 + 2), a
	jp	LOIN

; SIGHT: прицел лазера в текущем виде (если лазер есть): два перекрестия, полуразмеры 20 и 10.
SIGHT:
	ld	a, (VIEW)
	ld	e, a
	ld	d, 0
	ld	hl, LASER
	add	hl, de
	ld	a, (hl)
	or	a
	ret	z
	ld	a, 128
	ld	(QQ19), a
	ld	a, DASH_Y / 2 - 24
	ld	(QQ19 + 1), a
	ld	a, 20
	ld	(QQ19 + 2), a
	call	TT15
	ld	a, 10
	ld	(QQ19 + 2), a
	jp	TT15

; LASLI2: луч лазера — четыре отрезка от точки (LASX, LASY) к нижнему краю (x = 32, 224, 48, 208).
LASLI2:
	ld	a, (QQ11)
	or	a
	ret	nz
	call	col_red			; луч — вторым цветом
	ld	a, 32
	ld	c, 224
	call	las
	ld	a, 48
	ld	c, 208
	call	las
	jp	col_white
las:
	ld	(X2), a
	call	las_p
	call	LOIN
	ld	a, c
	ld	(X2), a
	call	las_p
	jp	LOIN
las_p:
	ld	hl, (LASX)		; LASX, LASY — соседние ячейки
	ld	(X1), hl
	ld	a, DASH_Y - 1
	ld	(Y2), a
	ret
