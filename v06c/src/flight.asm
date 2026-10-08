; Части полёта (T26): MULT3, MVT3, MV40, MAS2–MAS4, FAROF, SPS4, SP1, лампы панели, cntr, BAD, HITCH, DENGY, SHD,
; PLUT, LOOK1, FLIP, TT110, NWSPS, NwS1, SOS1, LASLI, NOISE. Перенесено близко к тексту BBC; сверка — t26.mjs.

; MULT3: K(3 2 1 0) = (A P+1 P) · Q: множимое 24 бита со знаком в бите 7 у A, множитель со знаком в бите 7.
; Произведение точное. R = A. При |Q| = 0: K = 0, X не меняется; иначе X = 0. Перенос 0.
MULT3:
	ld	(R_), a
	ld	a, (Q)
	and	0x7F
	jp	z, MU5
	ld	a, (P_)
	call	m3_q
	ld	a, l
	ld	(K), a
	ld	b, h
	ld	a, (P_ + 1)
	call	m3_q
	ld	e, b
	ld	d, 0
	add	hl, de
	ld	a, l
	ld	(K + 1), a
	ld	b, h
	ld	a, (R_)
	and	0x7F
	call	m3_q
	ld	e, b
	ld	d, 0
	add	hl, de
	ld	a, l
	ld	(K + 2), a
	ld	a, h
	ld	(T), a
	ld	d, a
	ld	hl, Q
	ld	a, (R_)
	xor	(hl)
	and	0x80
	or	d
	ld	(K + 3), a
	ld	b, 0
	ret
m3_q:					; HL = A · |Q|
	ld	e, a
	ld	a, (Q)
	and	0x7F
	jp	mul8

; MVT3: K(3 2 1) = K(3 2 1) + координата INWK+X.. (X = 0, 3, 6); числа со знаком в бите 7 старшего байта.
; A = K+3, перенос — как на BBC (от него в TACTICS зависит случайное число). S, T — рабочие.
MVT3:
	ld	a, (K + 3)
	ld	(S), a
	ld	d, a
	and	0x80
	ld	(T), a
	ld	e, a
	ld	hl, INWK + 2
	ld	a, b
	add	a, l
	ld	l, a
	ld	a, e
	xor	(hl)
	jp	m, mv13
	dec	hl
	dec	hl
	ld	a, (K + 1)
	add	a, (hl)
	ld	(K + 1), a
	inc	hl
	ld	a, (K + 2)
	adc	a, (hl)
	ld	(K + 2), a
	inc	hl
	ld	a, d
	adc	a, (hl)
	push	af
	and	0x7F
	or	e
	ld	(K + 3), a
	ld	e, a
	pop	af
	ld	a, e
	ret
mv13:
	ld	a, d
	and	0x7F
	ld	(S), a
	ld	d, a
	dec	hl
	dec	hl
	ld	a, (K + 1)
	ld	e, a
	ld	a, (hl)
	sub	e
	ld	(K + 1), a
	inc	hl
	ld	a, (K + 2)
	ld	e, a
	ld	a, (hl)
	sbc	a, e
	ld	(K + 2), a
	ld	a, 0
	adc	a, d
	ld	d, a			; |K+3| + заём
	inc	hl
	ld	a, (hl)
	and	0x7F
	sub	d
	jp	c, mv13_n
	or	0x80
	ld	e, a
	ld	a, (T)
	xor	e
	ld	(K + 3), a
	scf
	ret
mv13_n:
	or	0x80			; ушли за ноль: сменить знак
	ld	e, a
	ld	a, (T)
	xor	e
	ld	(K + 3), a
	ld	hl, K + 1
	xor	a
	sub	(hl)
	ld	(hl), a
	inc	hl
	ld	a, 0
	sbc	a, (hl)
	ld	(hl), a
	inc	hl
	ld	a, 0
	sbc	a, (hl)
	ccf
	push	af
	and	0x7F
	ld	e, a
	ld	a, (T)
	or	e
	ld	(hl), a
	ld	e, a
	pop	af
	ld	a, e
	ret

; MV40: движение планеты и солнца: поворот положения на крен и тангаж игрока в 24 битах, дальше — MV45
; (сдвиг на скорость и поворот ориентации).
MV40:
	ld	a, (ALPHA)		; K2 = y - alpha · x
	xor	0x80
	ld	(Q), a
	ld	hl, (INWK)
	ld	(P_), hl
	ld	a, (INWK + 2)
	call	MULT3
	ld	b, 3
	call	MVT3
	ld	hl, (K + 1)
	ld	(K2 + 1), hl
	ld	(P_), hl
	ld	a, (BETA)		; z = z + beta · K2
	ld	(Q), a
	ld	a, (K + 3)
	ld	(K2 + 3), a
	call	MULT3
	ld	b, 6
	call	MVT3
	ld	hl, (K + 1)
	ld	(P_), hl
	ld	(INWK + 6), hl
	ld	a, (K + 3)
	ld	(INWK + 8), a
	xor	0x80
	call	MULT3			; y = K2 - beta · z
	ld	a, (K + 3)
	and	0x80
	ld	(T), a
	ld	hl, K2 + 3
	xor	(hl)
	jp	m, mv1
	ld	hl, K2			; на BBC сложение идёт с переносом, оставшимся от MULT3 (ноль)
	ld	a, (K)
	add	a, (hl)
	inc	hl
	ld	a, (K + 1)
	adc	a, (hl)
	ld	(INWK + 3), a
	inc	hl
	ld	a, (K + 2)
	adc	a, (hl)
	ld	(INWK + 4), a
	inc	hl
	ld	a, (K + 3)
	adc	a, (hl)
	jp	mv2
mv1:
	ld	hl, K2
	ld	a, (K)
	sub	(hl)
	inc	hl
	ld	a, (K + 1)
	sbc	a, (hl)
	ld	(INWK + 3), a
	inc	hl
	ld	a, (K + 2)
	sbc	a, (hl)
	ld	(INWK + 4), a
	inc	hl
	ld	a, 0
	rla
	ld	e, a			; E — заём
	ld	a, (hl)
	and	0x7F
	add	a, e
	ld	(P_), a
	ld	e, a
	ld	a, (K + 3)
	and	0x7F
	sub	e
	ld	(P_), a
	jp	nc, mv2
	ld	hl, INWK + 3
	xor	a
	sub	(hl)
	ld	(hl), a
	inc	hl
	ld	a, 0
	sbc	a, (hl)
	ld	(hl), a
	ld	hl, P_
	ld	a, 0
	sbc	a, (hl)
	or	0x80
mv2:
	ld	hl, T
	xor	(hl)
	ld	(INWK + 5), a
	ld	a, (ALPHA)		; x = x + alpha · y
	ld	(Q), a
	ld	hl, (INWK + 3)
	ld	(P_), hl
	ld	a, (INWK + 5)
	call	MULT3
	ld	b, 0
	call	MVT3
	ld	hl, (K + 1)
	ld	(INWK), hl
	ld	a, (K + 3)
	ld	(INWK + 2), a
	jp	mv45

; MAS2: A |= старшие биты координат блока K%+Y (без знака) — «насколько далеко». MAS4: то же для INWK.
MAS2:
	ld	hl, K_ + 2
	ld	b, 0
	add	hl, bc
	or	(hl)
	inc	hl
	inc	hl
	inc	hl
	or	(hl)
	inc	hl
	inc	hl
	inc	hl
	or	(hl)
	and	0x7F
	ret
MAS4:
	ld	hl, INWK + 1
	or	(hl)
	ld	hl, INWK + 4
	or	(hl)
	ld	hl, INWK + 7
	or	(hl)
	ret
; MAS3: A = квадрат расстояния до тела K%+Y по старшим байтам; FFh при переполнении.
MAS3:
	ld	hl, K_ + 1
	ld	b, 0
	add	hl, bc
	push	hl
	ld	a, (hl)
	call	SQUA2
	ld	(R_), a
	pop	hl
	inc	hl
	inc	hl
	inc	hl
	push	hl
	ld	a, (hl)
	call	SQUA2
	ld	hl, R_
	add	a, (hl)
	pop	hl
	jp	c, ma30
	ld	(R_), a
	inc	hl
	inc	hl
	inc	hl
	ld	a, (hl)
	call	SQUA2
	ld	hl, R_
	add	a, (hl)
	ret	nc
ma30:
	ld	a, 0xFF
	ret
; FAROF: перенос 1, если корабль не дальше 224 по каждой оси. FAROF2: то же с порогом A.
FAROF:
	ld	a, 224
FAROF2:
	ld	hl, INWK + 1
	cp	(hl)
	jp	c, far_no
	ld	hl, INWK + 4
	cp	(hl)
	jp	c, far_no
	ld	hl, INWK + 7
	cp	(hl)
	ccf
	ret
far_no:
	or	a
	ret
; SPS4: вектор на станцию (второй блок K%) в K3, дальше TAS2. SP1: компас на станцию.
SPS4:
	ld	hl, K_ + NI
	ld	de, K3
	ld	b, 9
	call	ll9_cp
	jp	TAS2
SP1:
	call	SPS4
	jp	SP2

; Лампы панели: SPBLB — «станция рядом» (буква S), ECBLB — «ECM» (буква E); рисуются исключающим ИЛИ.
; ECBLB2: включить ECM: счётчик ECMA = 32, звук, лампа.
ECBLB2:
	ld	a, 32
	ld	(ECMA), a
	add	a, a
	call	NOISE
ECBLB:
	ld	hl, 0x7D00 + 7 * 8
	ld	de, ECBT
	jp	BULB
SPBLB:
	ld	hl, 0x7D00 + 24 * 8
	ld	de, SPBT
; BULB: восемь байт режима 5 по адресу DE — исключающим ИЛИ в знакоместо панели по адресу BBC HL.
BULB:
	ld	b, 8
bulb_l:
	ld	a, (de)
	call	dash_eor
	inc	de
	inc	l
	dec	b
	jp	nz, bulb_l
	ret
ECBT:
	db	0xE0, 0xE0, 0x80
SPBT:
	db	0xE0, 0xE0, 0x80, 0xE0, 0xE0, 0x20, 0xE0, 0xE0

; cntr: вернуть X к середине (128) на единицу, если включено затухание (DAMP = 0). BUMP: X + 1 без перехода
; через 255. REDU: X - 1 без перехода через 0.
cntr:
	ld	a, (DAMP)
	or	a
	ret	nz
	ld	a, b
	or	a
	jp	p, BUMP
	dec	b
	ret	m
BUMP:
	inc	b
	ret	nz
REDU:
	dec	b
	jp	z, BUMP
	ret

; BAD: A = сколько запрещённого груза: (рабы + наркотики) · 2 + оружие.
BAD:
	ld	hl, QQ20 + 6
	ld	a, (QQ20 + 3)
	add	a, (hl)
	add	a, a
	ld	hl, QQ20 + 10
	adc	a, (hl)
	ret

; HITCH: корабль из INWK в перекрестии? Перенос 1 — да.
HITCH:
	ld	a, (INWK + 8)
	or	a
	jp	nz, hi_no
	ld	a, (TYPE)
	or	a
	jp	m, hi_no
	ld	a, (INWK + 31)
	and	0x20
	ld	hl, INWK + 1
	or	(hl)
	ld	hl, INWK + 4
	or	(hl)
	jp	nz, hi_no
	ld	a, (INWK)
	call	SQUA2
	ld	(S), a
	ld	a, (P_)
	ld	(R_), a
	ld	a, (INWK + 3)
	call	SQUA2
	ld	b, a
	ld	hl, R_
	ld	a, (P_)
	add	a, (hl)
	ld	(hl), a
	ld	hl, S
	ld	a, b
	adc	a, (hl)
	jp	c, hi_no
	ld	(hl), a
	ld	e, a
	ld	hl, (XX0)
	inc	hl
	inc	hl
	ld	c, 2
	ld	a, (hl)
	cp	e
	jp	nz, hi_c
	dec	hl
	dec	c
	ld	e, a
	ld	a, (R_)
	ld	d, a
	ld	a, (hl)
	cp	d
hi_c:
	ccf
	ret
hi_no:
	or	a
	ret

; SHD: щит X + 1 (не выше 255) ценой единицы энергии. DENGY: энергия - 1, но не ниже 1; Z — упёрлись.
SHD:
	inc	b
	jp	nz, DENGY
	dec	b
	ret
DENGY:
	ld	hl, ENERGY
	dec	(hl)
	ret	nz
	inc	(hl)
	cp	a
	ret

; PLUT: развернуть блок INWK под текущий вид: назад — сменить знаки x и z; влево и вправо — поменять x и z.
PLUT:
	ld	a, (VIEW)
	or	a
	ret	z
	dec	a
	jp	nz, pu2
	ld	hl, pu1_tab
	ld	b, 8
pu1_l:
	ld	e, (hl)
	inc	hl
	push	hl
	ld	d, 0
	ld	hl, INWK
	add	hl, de
	ld	a, (hl)
	xor	0x80
	ld	(hl), a
	pop	hl
	dec	b
	jp	nz, pu1_l
	ret
pu1_tab:
	db	2, 8, 10, 14, 16, 20, 22, 26
pu2:
	ld	b, a			; X = 1 — влево, 2 — вправо
	cp	2
	ccf
	ld	a, 0
	rra
	ld	(RAT2), a
	xor	0x80
	ld	(RAT), a
	ld	hl, (INWK)		; x <-> z
	ex	de, hl
	ld	hl, (INWK + 6)
	ld	(INWK), hl
	ex	de, hl
	ld	(INWK + 6), hl
	ld	hl, RAT
	ld	a, (INWK + 2)
	xor	(hl)
	ld	d, a
	ld	hl, RAT2
	ld	a, (INWK + 8)
	xor	(hl)
	ld	(INWK + 2), a
	ld	a, d
	ld	(INWK + 8), a
	ld	c, 9
	call	pus1
	ld	c, 15
	call	pus1
	ld	c, 21
pus1:
	ld	hl, INWK
	ld	b, 0
	add	hl, bc
	ld	d, h
	ld	e, l
	inc	de
	inc	de
	inc	de
	inc	de			; DE -> +4
	ld	a, (de)
	ld	b, (hl)
	ld	(hl), a
	ld	a, b
	ld	(de), a
	inc	hl
	inc	de			; HL -> +1, DE -> +5
	push	hl
	ld	hl, RAT
	ld	a, (hl)
	pop	hl
	xor	(hl)
	ld	b, a
	push	hl
	ld	hl, RAT2
	ld	a, (de)
	xor	(hl)
	pop	hl
	ld	(hl), a
	ld	a, b
	ld	(de), a
	ret

; FLIP: поменять x и y у пылинок (при смене вида) и перерисовать их.
FLIP:
	ld	a, (NOSTM)
	ld	c, a
fll1:
	call	st_sy
	ld	b, (hl)			; прежний y
	call	st_sx
	ld	a, (hl)
	ld	(Y1), a
	ld	(hl), b
	ld	a, b
	ld	(X1), a
	call	st_sy
	ld	a, (Y1)
	ld	(hl), a
	call	st_sz
	ld	a, (hl)
	ld	(ZZ), a
	call	PIXEL2
	dec	c
	jp	nz, fll1
	ret

; LOOK1: сменить вид на X (0 — вперёд, 1 — назад, 2 — влево, 3 — вправо).
lq:
	ld	a, b
	ld	(VIEW), a
	xor	a
	call	TT66
	call	SIGHT
	jp	NWSTARS
LOOK1:
	ld	a, (QQ11)
	or	a
	jp	nz, lq
	ld	a, (VIEW)
	cp	b
	ret	z
	ld	a, b
	ld	(VIEW), a
	xor	a
	call	TT66
	call	FLIP
	call	WPSHPS
	jp	SIGHT

; TT110: взлёт со станции (если стоим) и вид вперёд.
TT110:
	ld	a, (QQ12)
	or	a
	jp	z, nlunch
	call	mis_launch
	call	LAUN
	call	RES2
	call	TT111
	ld	hl, INWK + 8
	inc	(hl)
	call	SOS1			; планета
	ld	a, 128
	ld	(INWK + 8), a
	ld	hl, INWK + 7
	inc	(hl)
	call	NWSPS			; станция позади
	ld	a, 12
	ld	(DELTA), a
	call	BAD
	ld	hl, FIST
	or	(hl)
	ld	(hl), a
nlunch:
	xor	a
	ld	(QQ12), a
	ld	b, a
	jp	LOOK1

; SOS1: завести планету из INWK (тип 128 или 130 — по технике системы). NwS1: сменить знак INWK+X, X += 2.
SOS1:
	call	msblob
	ld	a, 127
	ld	(INWK + 29), a
	ld	(INWK + 30), a
	ld	a, (tek)
	and	2
	or	0x80
	jp	NWSHP
NwS1:
	ld	hl, INWK
	ld	e, b
	ld	d, 0
	add	hl, de
	ld	a, (hl)
	xor	0x80
	ld	(hl), a
	inc	b
	inc	b
	ret
; NWSPS: завести станцию из INWK: лампа, ИИ, развернуть носом к планете, список отрезков — в области LSO.
NWSPS:
	ifndef	SCHED
	ld	hl, (XX21 + 14)		; станция: при технике от 10 — Dodo, как в дисковой версии
	ld	a, (tek)
	cp	10
	jp	c, nws_cor
	ld	hl, ship_dodo
nws_cor:
	ld	(XX21X + 14), hl
	endif
	call	SPBLB
	ld	a, 1
	ld	(INWK + 32), a
	xor	a
	ld	(INWK + 30), a
	ld	(FRIN + 1), a
	dec	a
	ld	(INWK + 29), a
	ld	b, 10
	call	NwS1
	call	NwS1
	call	NwS1
	ld	hl, LSO
	ld	(INWK + 33), hl
	ld	a, 8
	jp	NWSHP

; LASLI: выстрел: точка прицеливания со случайным разбросом, нагрев лазера, расход энергии, луч.
LASLI:
	call	DORND
	push	af
	and	7
	ld	d, a
	pop	af
	ld	a, d
	adc	a, DASH_Y / 2 - 4
	ld	(LASY), a
	call	DORND
	push	af
	and	7
	ld	d, a
	pop	af
	ld	a, d
	adc	a, 128 - 4
	ld	(LASX), a
	ld	a, (GNTMP)
	adc	a, 8
	ld	(GNTMP), a
	call	DENGY
	jp	LASLI2

; NOISE: звук номер A (0, 8, 16 … 72): блок звука — в XX16 (как на BBC) и в звуковой движок ВИ53 (snd.asm).
NOISE:
	or	a
	rra
	add	a, low sfx_tab
	ld	l, a
	ld	h, high sfx_tab
	push	hl
	ld	de, XX16
	ld	b, 4
nol1:
	ld	a, (hl)
	ld	(de), a
	inc	hl
	inc	de
	xor	a
	ld	(de), a
	inc	de
	dec	b
	jp	nz, nol1
	pop	hl
	ld	a, (DNOIZ)		; звук выключен настройкой
	or	a
	ret	nz
	push	bc
	call	snd_start
	pop	bc
	ret
	align	64
sfx_tab:
	db	0x12, 0x01, 0x00, 0x10	; 0: наш лазер
	db	0x12, 0x02, 0x2C, 0x08	; 8: по нам попали
	db	0x11, 0x03, 0xF0, 0x18	; 16: взрыв 1
	db	0x10, 0xF1, 0x07, 0x1A	; 24: взрыв 2
	db	0x03, 0xF1, 0xBC, 0x01	; 32: короткий высокий гудок
	db	0x13, 0xF4, 0x0C, 0x08	; 40: длинный низкий гудок
	db	0x10, 0xF1, 0x06, 0x0C	; 48: пуск ракеты, взлёт
	db	0x10, 0x02, 0x60, 0x10	; 56: прыжок
	db	0x13, 0x04, 0xC2, 0xFF	; 64: ECM включён
	db	0x13, 0x00, 0x00, 0x00	; 72: ECM выключен
