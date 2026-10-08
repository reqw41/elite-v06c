; Звёздная пыль: NWSTARS, nWq, STARS, STARS1 (вперёд), STARS6 (назад), STARS2 (влево/вправо), PIX1, PIXEL2.
; STARS6/STARS2 — близко к тексту BBC; в STARS1 перенос из сдвигов в вычитания и из сравнений в DORND.
; Сверка — v06c/test/t23.mjs.

; PIX1: (YY+1 SYL+Y) = (A P) + (S R), затем PIXEL2.
PIX1:
	call	ADD
	ld	(YY + 1), a
	ld	hl, SYL
	ld	d, 0
	ld	e, c
	add	hl, de
	ld	(hl), b
; PIXEL2: точка пыли по смещению от центра экрана: X1, Y1 — модуль и знак в бите 7; расстояние ZZ.
; За пределами |Y1| >= 96 не рисуется.
PIXEL2:
	ld	a, (X1)
	or	a
	jp	p, px1
	xor	0x7F
	inc	a
px1:
	xor	0x80
	ld	b, a
	ld	a, (Y1)
	ld	d, a
	and	0x7F
	cp	96
	jp	nc, px_c1		; за экраном: перенос 1, как на BBC
	ld	a, d
	or	a
	jp	p, px2_p
	xor	0x7F
	add	a, 1
	ld	(T), a
	ld	e, a
	ld	a, 97			; у BBC при Y1 = 80h («минус ноль») выходит строка 97
	jp	c, px2_s
	dec	a
px2_s:
	sub	e
	jp	PIXEL
px2_p:
	ld	(T), a
	ld	e, a
	ld	a, 96
	sub	e
	jp	PIXEL

; NWSTARS: новая пыль (только в виде из корабля), затем WPSHPS. nWq: то же без проверки вида.
NWSTARS:
	ld	hl, QQ11		; проверка без сброса переноса: он идёт в генератор случайных чисел
	inc	(hl)
	dec	(hl)
	jp	nz, WPSHPS
nWq:
	ld	a, (NOSTM)
	ld	c, a
sal4:
	call	DORND
	push	af
	or	8
	call	st_sz
	ld	(hl), a
	ld	(ZZ), a
	pop	af
	call	DORND
	push	af
	call	st_sx
	ld	(hl), a
	ld	(X1), a
	pop	af
	call	DORND
	call	st_sy
	ld	(hl), a
	ld	(Y1), a
	call	PIXEL2			; перенос после неё идёт в следующий DORND
	dec	c
	jp	nz, sal4
	jp	WPSHPS
; HL = таблица + Y; сохраняет AF
st_sz:
	ld	hl, SZ
	jp	st_idx
st_sx:
	ld	hl, SX
	jp	st_idx
st_sy:
	ld	hl, SY
st_idx:
	push	af
	ld	d, 0
	ld	e, c
	add	hl, de
	pop	af
	ret

; STARS: шаг пыли по виду: 0 — STARS1, 1 — STARS6, 2/3 — STARS2 (B = VIEW−1: 1 влево, 2 вправо).
STARS:
	ld	a, (VIEW)
	ld	b, a
	or	a
	jp	z, STARS1
	dec	b
	jp	z, STARS6
	jp	STARS2

; STARS1: пыль в виде вперёд: каждая пылинка приближается на скорость, смещается на крен и тангаж,
; стирается и рисуется заново; ушедшая за край или подошедшая вплотную заменяется новой.
; |x|·Q и |y|·Q — через mul8 (без MLU1/MLU2); адреса таблиц без st_idx.
STARS1:
	ld	a, (NOSTM)
	ld	c, a
stl1:
	call	DV42			; (P R) = DELTA · 256 / z
	ld	hl, SZL
	ld	b, 0
	add	hl, bc
	push	hl
	ld	a, (P_)
	ld	d, a
	ld	a, (R_)
	ld	e, a
	ld	a, d
	or	a
	rra
	ld	d, a
	ld	a, e
	rra
	ld	e, a
	ld	a, d
	or	a
	rra
	ld	d, a
	ld	a, e
	rra
	ld	e, a			; CY — бит, вышедший из младшего байта
	ld	a, d
	ld	(P_), a
	ld	a, e
	push	af
	or	1
	ld	(Q), a
	pop	af
	ccf				; у 6502 SBC вычитает ещё (1 - C)
	pop	hl
	ld	a, (DELT4)
	ld	d, a
	ld	a, (hl)
	sbc	a, d
	ld	(hl), a
	push	af
	ld	de, SZ - SZL
	add	hl, de
	pop	af
	ld	a, (DELT4 + 1)
	ld	d, a
	ld	a, (hl)
	ld	(ZZ), a
	sbc	a, d
	ld	(hl), a
	ld	hl, SY			; y += |y| · Q (mul8 вместо MLU1)
	ld	b, 0
	add	hl, bc
	ld	a, (hl)
	ld	(Y1), a
	and	0x7F
	ld	e, a
	ld	a, (Q)
	or	a
	ld	d, a
	jp	z, st_y0
	dec	a
	ld	(T), a
	ld	a, d
	call	mul8
	ld	a, l
	ld	(P_), a
	ld	a, h
	jp	st_y1
st_y0:
	ld	(P_), a
st_y1:
	ld	(YY + 1), a
	ld	hl, SYL
	ld	b, 0
	add	hl, bc
	ld	a, (P_)
	add	a, (hl)
	ld	(YY), a
	ld	(R_), a
	ld	hl, YY + 1
	ld	a, (Y1)
	adc	a, (hl)
	ld	(hl), a
	ld	(S), a
	ld	hl, SX			; x += |x| · Q (mul8 вместо MLU2)
	ld	b, 0
	add	hl, bc
	ld	a, (hl)
	ld	(X1), a
	and	0x7F
	ld	e, a
	ld	a, (Q)
	or	a
	ld	d, a
	jp	z, st_x0
	dec	a
	ld	(T), a
	ld	a, d
	call	mul8
	ld	a, l
	ld	(P_), a
	ld	a, h
	jp	st_x1
st_x0:
	ld	(P_), a
st_x1:
	ld	(XX + 1), a
	ld	hl, SXL
	ld	b, 0
	add	hl, bc
	ld	a, (P_)
	add	a, (hl)
	ld	(XX), a
	ld	hl, XX + 1
	ld	a, (X1)
	adc	a, (hl)
	ld	(hl), a
	ifndef	SCHED
	ld	a, (ALP1)		; полёт прямо (ни крена, ни тангажа): все слагаемые ниже — нули
	ld	hl, BET1
	or	(hl)
	jp	nz, st_rot
	ld	b, a
	ld	hl, SXL
	add	hl, bc
	ld	a, (XX)
	ld	(hl), a
	ld	hl, SYL
	add	hl, bc
	ld	a, (YY)
	ld	(hl), a
	call	PIXEL2			; стереть пылинку на прежнем месте
	jp	st_norot
st_rot:
	ld	a, (XX + 1)
	endif
	ld	hl, ALP2 + 1		; y += alpha · x / 256 (mul8 вместо MLS1)
	xor	(hl)
	ld	d, a
	ld	a, (ALP1)
	ld	(P_), a
	ld	a, d
	call	st_mults
	call	ADD
	ld	(YY + 1), a
	ld	d, a
	ld	a, b
	ld	(YY), a
	ld	a, d
	ld	hl, ALP2		; x += alpha · y / 256 (mul8 вместо MLS2)
	xor	(hl)
	ld	hl, (XX)
	ld	(R_), hl
	ld	d, a
	ld	a, (ALP1)
	ld	(P_), a
	ld	a, d
	call	st_mults
	call	ADD
	ld	(XX + 1), a
	ld	a, b
	ld	(XX), a
	ld	a, (BET1)		; x += 2 · (beta · y / 256)^2
	ld	(P_), a
	ld	a, (YY + 1)
	ld	hl, BET2 + 1
	xor	(hl)
	call	st_mults
	ld	(Q), a
	ld	hl, (XX)
	ld	(R_), hl
	call	MULT1
	ld	d, a
	ld	a, (P_)
	add	a, a
	ld	(P_), a
	ld	a, d
	rla
	ld	(T), a
	ld	d, a
	ld	a, 0
	rra
	or	d
	call	ADD
	ld	(XX + 1), a
	ld	hl, SXL
	ld	d, 0
	ld	e, c
	add	hl, de
	ld	(hl), b
	ld	hl, (YY)		; y -= beta · 256
	ld	a, l
	ld	(R_), a
	ld	a, h
	ld	(S), a
	xor	a
	ld	(P_), a
	ld	a, (BETA)
	xor	0x80
	call	PIX1			; и стереть пылинку на прежнем месте
st_norot:
	ld	a, (XX + 1)
	ld	(X1), a
	ld	hl, SX
	ld	b, 0
	add	hl, bc
	ld	(hl), a
	and	0x7F
	cp	120
	jp	nc, kill1_c1
	ld	a, (YY + 1)
	ld	hl, SY
	ld	b, 0
	add	hl, bc
	ld	(hl), a
	ld	(Y1), a
	and	0x7F
	cp	120
	jp	nc, kill1_c1
	ld	hl, SZ
	ld	b, 0
	add	hl, bc
	ld	a, (hl)
	cp	16
	jp	c, kill1_c0
	ld	(ZZ), a
stc1:
	call	PIXEL2
	dec	c
	jp	nz, stl1
	ret
; новая пылинка; перенос на входе в генератор — как на BBC (после сравнения)
kill1_c1:
	scf
	jp	kill1
kill1_c0:
	or	a
kill1:
	call	DORND
	push	af
	or	4
	ld	(Y1), a
	ld	hl, SY
	ld	b, 0
	add	hl, bc
	ld	(hl), a
	pop	af
	call	DORND
	push	af
	or	8
	ld	(X1), a
	ld	hl, SX
	ld	b, 0
	add	hl, bc
	ld	(hl), a
	pop	af
	call	DORND
	or	144
	ld	hl, SZ
	ld	b, 0
	add	hl, bc
	ld	(hl), a
	ld	(ZZ), a
	jp	stc1

; Как MULTS: (A P) = |A| · (P & 31) со знаком A. При |A| = 0: P(1 0) = 0, перенос как на входе.
st_mults:
	ld	b, a
	push	af
	and	0x80
	ld	(T), a
	ld	a, b
	and	0x7F
	jp	z, st_ms0
	pop	de
	ld	e, a
	dec	a
	ld	(T1), a
	ld	b, a
	ld	a, (P_)
	and	31
	call	mul8
	ld	a, l
	ld	(P_), a
	ld	a, (T)
	or	h
	ret
st_ms0:
	pop	af
	ld	a, 0
	ld	(P_ + 1), a
	ld	(P_), a
	ret

; STARS6: пыль в виде назад — близко к тексту BBC (знаки и порядок слагаемых иные, чем в STARS1).
STARS6:
	ld	a, (NOSTM)
	ld	c, a
stl6:
	call	DV42			; (P R) = DELTA · 256 / z
	ld	a, (P_)
	ld	d, a
	ld	a, (R_)
	ld	e, a
	ld	a, d
	or	a
	rra
	ld	d, a
	ld	a, e
	rra
	ld	e, a
	ld	a, d
	or	a
	rra
	ld	d, a
	ld	a, e
	rra
	or	1
	ld	(Q), a			; Q = 64 · speed / z
	ld	hl, SX
	ld	b, 0
	add	hl, bc
	ld	a, (hl)
	ld	(X1), a
	call	MLU2			; (A P) = |x| · Q; на BBC C=0 после MULTU
	ld	(XX + 1), a
	ld	hl, SXL
	ld	b, 0
	add	hl, bc
	ld	a, (hl)
	ld	hl, P_
	scf				; 6502 SBC при C=0 = i8080 sbc при CY=1
	sbc	a, (hl)
	ld	(XX), a
	ld	a, (X1)
	ld	hl, XX + 1
	sbc	a, (hl)
	ld	(hl), a			; XX = x − |x| · Q
	call	MLU1
	ld	(YY + 1), a
	ld	hl, SYL
	ld	b, 0
	add	hl, bc
	ld	a, (hl)
	ld	hl, P_
	scf
	sbc	a, (hl)
	ld	(YY), a
	ld	(R_), a
	ld	a, (Y1)
	ld	hl, YY + 1
	sbc	a, (hl)
	ld	(hl), a
	ld	(S), a			; (S R) = YY = y − |y| · Q
	ccf				; i8080 CY после sbc = заём; 6502 C = !заём
	push	af			; CY через add hl,bc (портит перенос)
	ld	hl, SZL
	ld	b, 0
	add	hl, bc
	pop	af
	ld	a, (hl)
	ld	d, a
	ld	a, (DELT4)
	adc	a, d
	ld	(hl), a
	push	af
	ld	hl, SZ
	ld	b, 0
	add	hl, bc
	pop	af
	ld	a, (hl)
	ld	(ZZ), a
	ld	d, a
	ld	a, (DELT4 + 1)
	adc	a, d
	ld	(hl), a			; z += DELT4
	ld	a, (XX + 1)
	ld	hl, ALP2
	xor	(hl)
	call	MLS1
	call	ADD
	ld	(YY + 1), a
	ld	d, a
	ld	a, b
	ld	(YY), a
	ld	a, d
	ld	hl, ALP2 + 1
	xor	(hl)
	call	MLS2
	call	ADD
	ld	(XX + 1), a
	ld	a, b
	ld	(XX), a
	ld	a, (YY + 1)
	ld	hl, BET2 + 1
	xor	(hl)
	ld	hl, BET1
	ld	b, (hl)
	call	MULTS_2
	ld	(Q), a
	ld	a, (XX + 1)
	ld	(S), a
	xor	0x80
	call	MUT1
	ld	d, a
	ld	a, (P_)
	add	a, a
	ld	(P_), a
	ld	a, d
	rla
	ld	(T), a
	ld	a, 0
	rra
	ld	hl, T
	or	(hl)
	call	ADD
	ld	(XX + 1), a
	ld	hl, SXL
	ld	d, 0
	ld	e, c
	add	hl, de
	ld	(hl), b
	ld	hl, (YY)
	ld	a, l
	ld	(R_), a
	ld	a, h
	ld	(S), a
	xor	a
	ld	(P_), a
	ld	a, (BETA)
	call	PIX1
	ld	a, (XX + 1)
	ld	(X1), a
	ld	hl, SX
	ld	b, 0
	add	hl, bc
	ld	(hl), a
	ld	a, (YY + 1)
	ld	hl, SY
	ld	b, 0
	add	hl, bc
	ld	(hl), a
	ld	(Y1), a
	and	0x7F
	cp	110
	jp	nc, kill6		; |y| >= 110; на BBC BCS → C=1
	ld	hl, SZ
	ld	b, 0
	add	hl, bc
	ld	a, (hl)
	cp	160
	jp	nc, kill6		; z >= 160; на BBC BCS → C=1
	ld	(ZZ), a
stc6:
	call	PIXEL2
	dec	c
	ret	z
	jp	stl6
kill6:
	scf				; как C после BCS на BBC (у jp nc перенос обратный)
	call	DORND			; входящий CY влияет на RAND
	push	af			; AND на i8080 сбрасывает CY — бережём флаги DORND
	and	0x7F
	pop	de			; E = флаги (бит 0 = CY)
	ld	d, a
	ld	a, e
	rra
	ld	a, d
	adc	a, 10
	ld	hl, SZ
	ld	b, 0
	add	hl, bc
	ld	(hl), a
	ld	(ZZ), a
	rra				; LSR A
	jp	c, st6_edge
	rra
	ld	a, 252
	rra				; ±126
	ld	(X1), a
	ld	hl, SX
	ld	b, 0
	add	hl, bc
	ld	(hl), a
	call	DORND
	ld	(Y1), a
	ld	hl, SY
	ld	b, 0
	add	hl, bc
	ld	(hl), a
	jp	stc6
st6_edge:
	call	DORND
	ld	(X1), a
	ld	hl, SX
	ld	b, 0
	add	hl, bc
	ld	(hl), a
	rra
	ld	a, 230
	rra				; ±115
	ld	(Y1), a
	ld	hl, SY
	ld	b, 0
	add	hl, bc
	ld	(hl), a
	jp	stc6

; STARS2: пыль в видах влево (B=1) и вправо (B=2). RAT/RAT2 — край и направление по x.
STARS2:
	xor	a
	ld	e, a
	ld	a, b
	cp	2
	ccf				; CY = (B >= 2), как CPX #2 на 6502
	ld	a, e
	rra
	ld	(RAT), a
	xor	0x80
	ld	(RAT2), a
	call	ST2
	ld	a, (NOSTM)
	ld	c, a
stl2:
	ld	hl, SZ
	ld	b, 0
	add	hl, bc
	ld	a, (hl)
	ld	(ZZ), a
	or	a
	rra
	or	a
	rra
	or	a
	rra				; z_hi / 8
	call	DV41
	ld	a, (P_)
	ld	hl, RAT2
	xor	(hl)
	ld	(S), a			; (S R) = ± delta_x; R уже из DV41
	ld	hl, SXL
	ld	b, 0
	add	hl, bc
	ld	a, (hl)
	ld	(P_), a
	ld	hl, SX
	ld	b, 0
	add	hl, bc
	ld	a, (hl)
	ld	(X1), a
	call	ADD			; x + delta_x → (S R)
	ld	(S), a
	ld	a, b
	ld	(R_), a
	ld	hl, SY
	ld	b, 0
	add	hl, bc
	ld	a, (hl)
	ld	(Y1), a
	ld	hl, BET2
	call	st_eor			; EOR без сброса CY (MULTS при |A|=0 его хранит)
	ld	hl, BET1
	ld	b, (hl)
	call	MULTS_2
	call	ADD
	ld	(XX + 1), a
	ld	a, b
	ld	(XX), a			; x = x + delta_x + beta · y
	ld	hl, SYL
	ld	b, 0
	add	hl, bc
	ld	a, (hl)
	ld	(R_), a
	ld	a, (Y1)
	ld	(S), a			; (S R) = y
	ld	a, (XX + 1)
	ld	hl, BET2 + 1
	call	st_eor
	ld	hl, BET1
	ld	b, (hl)
	call	MULTS_2
	call	ADD
	ld	(YY + 1), a
	ld	a, b
	ld	(YY), a			; y = y − beta · x
	ld	hl, ALP1
	ld	b, (hl)
	ld	a, (YY + 1)
	ld	hl, ALP2
	call	st_eor
	call	MULTS_2
	ld	(Q), a
	ld	hl, (XX)
	ld	(R_), hl			; (S R) = x
	ld	a, (XX + 1)
	ld	hl, st_sgn		; EOR #80h без сброса CY
	call	st_eor
	call	MAD			; x − alpha · x · y
	ld	(XX + 1), a
	push	af			; CY → второй MAD при Q=0 (MULT1)
	ld	hl, SXL
	ld	d, 0
	ld	e, c
	add	hl, de			; add hl портит CY
	ld	(hl), b
	pop	af
	ld	hl, (YY)
	ld	(R_), hl
	ld	a, (YY + 1)
	call	MAD			; y + alpha · y · y
	ld	(S), a
	ld	a, b
	ld	(R_), a
	push	af			; LDA #0 / STA P на BBC не трогает C
	xor	a
	ld	(P_), a
	pop	af
	ld	a, (ALPHA)
	call	PIX1
	ld	a, (XX + 1)
	ld	hl, SX
	ld	b, 0
	add	hl, bc
	ld	(hl), a
	ld	(X1), a
	and	0x7F
	cp	116
	jp	nc, kill2
	ld	a, (YY + 1)
	ld	hl, SY
	ld	b, 0
	add	hl, bc
	ld	(hl), a
	ld	(Y1), a
	and	0x7F
	cp	116
	jp	nc, st2_y
stc2:
	call	PIXEL2
	dec	c
	jp	z, ST2
	jp	stl2
; ST2: для правого вида вернуть знаки ALPHA/ALP2/BET2 (и на входе STARS2 — перевернуть).
; На BBC EOR не трогает C; на i8080 xor сбрасывает — бережём перенос (от PIXEL2 / ROR).
ST2:
	push	af
	ld	a, (ALPHA)
	ld	hl, RAT
	xor	(hl)
	ld	(ALPHA), a
	ld	a, (ALP2)
	xor	(hl)
	ld	(ALP2), a
	xor	0x80
	ld	(ALP2 + 1), a
	ld	a, (BET2)
	xor	(hl)
	ld	(BET2), a
	xor	0x80
	ld	(BET2 + 1), a
	pop	af
	ret
kill2:
	scf				; как C после BCS
	call	DORND
	push	af			; сразу: add hl портит CY; ORA на BBC C не трогает
	ld	(Y1), a
	ld	hl, SY
	ld	b, 0
	add	hl, bc
	ld	(hl), a
	ld	a, 115
	ld	hl, RAT
	or	(hl)
	ld	(X1), a
	ld	hl, SX
	ld	b, 0
	add	hl, bc
	ld	(hl), a
	pop	af
	jp	stf1
st2_y:
	scf
	call	DORND
	push	af			; сразу: add hl портит CY
	ld	(X1), a
	ld	hl, SX
	ld	b, 0
	add	hl, bc
	ld	(hl), a
	ld	a, 110
	ld	hl, ALP2 + 1
	or	(hl)
	ld	(Y1), a
	ld	hl, SY
	ld	b, 0
	add	hl, bc
	ld	(hl), a
	pop	af
stf1:
	call	DORND
	or	8
	ld	(ZZ), a
	ld	hl, SZ
	ld	b, 0
	add	hl, bc
	ld	(hl), a
	jp	stc2

; A ^= (HL), перенос как на входе (на BBC EOR не трогает C).
st_eor:
	ld	d, a
	ld	a, 0
	rla
	ld	e, a			; E = старый CY
	ld	a, d
	xor	(hl)
	ld	d, a
	ld	a, e
	rra
	ld	a, d
	ret
st_sgn:	db	0x80
