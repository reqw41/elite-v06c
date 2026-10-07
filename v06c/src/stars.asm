; Звёздная пыль: NWSTARS, nWq, STARS, STARS1 (вид вперёд), PIX1, PIXEL2. Перенесено команда в команду: в STARS1
; перенос идёт из сдвигов в вычитания и из сравнений в генератор случайных чисел. Сверка — v06c/test/t23.mjs.

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

; STARS: шаг пыли по виду: вперёд — STARS1; назад и в стороны — этап P4.
STARS:
	ld	a, (VIEW)
	or	a
	jp	z, STARS1
	dec	a
	jp	z, STARS6
	jp	STARS2

; STARS1: пыль в виде вперёд: каждая пылинка приближается на скорость, смещается на крен и тангаж,
; стирается и рисуется заново; ушедшая за край или подошедшая вплотную заменяется новой.
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
	call	MLU1			; y += |y| · Q
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
	call	st_sx			; x += |x| · Q
	ld	a, (hl)
	ld	(X1), a
	call	MLU2
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
	ld	hl, ALP2 + 1		; y -= alpha · x
	xor	(hl)
	call	MLS1
	call	ADD
	ld	(YY + 1), a
	ld	d, a
	ld	a, b
	ld	(YY), a
	ld	a, d
	ld	hl, ALP2		; x += alpha · y
	xor	(hl)
	call	MLS2
	call	ADD
	ld	(XX + 1), a
	ld	a, b
	ld	(XX), a
	ld	a, (BET1)		; x += 2 · (beta · y)^2
	ld	b, a
	ld	a, (YY + 1)
	ld	hl, BET2 + 1
	xor	(hl)
	call	MULTS_2
	ld	(Q), a
	call	MUT2
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
	ld	a, (XX + 1)
	ld	(X1), a
	call	st_sx
	ld	(hl), a
	and	0x7F
	cp	120
	jp	nc, kill1_c1
	ld	a, (YY + 1)
	call	st_sy
	ld	(hl), a
	ld	(Y1), a
	and	0x7F
	cp	120
	jp	nc, kill1_c1
	call	st_sz
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
	call	st_sy
	ld	(hl), a
	pop	af
	call	DORND
	push	af
	or	8
	ld	(X1), a
	call	st_sx
	ld	(hl), a
	pop	af
	call	DORND
	or	144
	call	st_sz
	ld	(hl), a
	ld	(ZZ), a
	jp	stc1
