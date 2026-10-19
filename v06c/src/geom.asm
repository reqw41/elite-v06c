; Арифметика и геометрия заставки (T07): деление на расстояние, проекция, поворот, нормировка.
; Правила — docs/spec/porting.md. Сравнение с эталоном — v06c/test/t07.mjs: A, X, Y, перенос, рабочие области.
geom_start:

; DVID3B2: K(3 2 1 0) = (A P+1 P) / (INWK+8 INWK+7 INWK+6) — деление на расстояние z; знак — бит 7 старших
; байтов. DVID3B: то же, делимое — (P+2 P+1 P), делитель — (S R Q). Делитель не должен быть нулевым
; (на BBC — вечный цикл). Y на выходе 0, X не меняется, перенос — как на BBC.
DVID3B2:
	ld	(P_ + 2), a
	ld	hl, (INWK + 6)
	ld	(Q), hl			; Q, R — соседние ячейки
	ld	a, (INWK + 8)
	ld	(S), a
DVID3B:
	ld	hl, (P_)
	ld	a, l
	or	1
	ld	l, a
	ld	a, (S)
	ld	d, a
	ld	a, (P_ + 2)
	ld	e, a
	xor	d
	and	0x80
	ld	(T), a
	ld	c, 0
	ld	a, e
	and	0x7F
dvl9:
	cp	64			; делимое влево, пока старший байт меньше 64
	jp	nc, dv14
	add	hl, hl
	rla
	inc	c
	jp	nz, dvl9
dv14:
	ld	(P_ + 2), a
	ld	(P_), hl
	ld	hl, (Q)
	ld	a, d
	and	0x7F
dvl6:
	dec	c			; делитель влево, пока не займёт бит 7
	add	hl, hl
	rla
	or	a
	jp	p, dvl6
	ld	(Q), a
	ld	a, 254
	ld	(R_), a
	ld	a, (P_ + 2)
	call	LL31			; R = 256 · A / Q
	ld	hl, 0
	ld	(K + 1), hl
	xor	a
	ld	(K + 3), a
	ld	a, c
	or	a
	jp	p, dv12
	ld	a, (R_)			; Y < 0: частное влево на -Y
	ld	l, a
	ld	d, h
	ld	e, h
dvl8:
	add	hl, hl
	ld	a, e
	rla
	ld	e, a
	ld	a, d
	rla
	ld	d, a
	inc	c
	jp	nz, dvl8
	ld	(K), hl
	ld	a, e
	ld	(K + 2), a
	ld	a, (T)
	or	d
	ld	(K + 3), a
	ret
dv12:
	jp	z, dv13
	ld	a, (R_)			; Y > 0: частное вправо на Y
dvl10:
	or	a
	rra
	dec	c
	jp	nz, dvl10
	jp	dv13_k
dv13:
	ld	a, (R_)
dv13_k:
	ld	(K), a
	ld	a, (T)
	ld	(K + 3), a
	ret

; PLS6: (X K) = (A P+1 P) / z с проверкой: перенос 1 — результат не помещается в ±1024.
PLS6:
	call	DVID3B2
	ld	a, (K + 3)
	and	0x7F
	ld	hl, K + 2
	or	(hl)
	jp	nz, pls6_big
	ld	a, (K + 1)
	ld	b, a
	cp	4
	jp	nc, pls6_far
	ld	a, (K + 3)
	or	a
	ret	p
	ld	a, (K)
	cpl
	add	a, 1
	ld	(K), a
	ld	a, b
	cpl
	adc	a, 0
	ld	b, a
	or	a
	ret
pls6_far:
	ld	a, 0
pls6_big:
	scf
	ret

; PROJ: проекция центра объекта на экран: K3(1 0) = 128 + x / z, K4(1 0) = 96 - y / z.
; Перенос 1 — не помещается.
PROJ:
	ld	hl, (INWK)
	ld	(P_), hl
	ld	a, (INWK + 2)
	call	PLS6
	ret	c
	ld	a, (K)
	add	a, 128
	ld	(K3), a
	ld	a, b
	adc	a, 0
	ld	(K3 + 1), a
	ld	hl, (INWK + 3)
	ld	(P_), hl
	ld	a, (INWK + 5)
	xor	0x80
	call	PLS6
	ret	c
	ld	a, (K)
	add	a, 96
	ld	(K4), a
	ld	a, b
	adc	a, 0
	ld	(K4 + 1), a
	or	a
	ret

; LL51: XX12 = XX15 · XX16 — три скалярных произведения (вектор на строки матрицы); числа — модуль и знак
; в отдельных байтах. Написано по смыслу: слагаемое — старший байт произведения модулей, сумма — как LL38
; (сложение модулей по модулю 256; при разных знаках вычитание и, если ушли за ноль, смена знака).
; В отличие от BBC, не пишет рабочие ячейки P, Q, R, S, T (по трассировке эталона их после LL51 никто не читает:
; docs/research/liveness_launch.txt). На выходе X = 18, Y = 6, A = 18, перенос 1.
	macro	LL51TERM vec, mat
	ld	a, (XX15 + vec)
	ld	e, a
	ld	a, (XX16 + mat)
	MULHI
	ld	d, a
	ld	a, (XX15 + vec + 1)
	ld	hl, XX16 + mat + 1
	xor	(hl)
	endm
	macro	LL51ROW row
	LL51TERM 0, row * 6
	ld	b, d			; B — модуль суммы, C — её знак
	ld	c, a
	LL51TERM 2, row * 6 + 2
	call	ll51_add
	LL51TERM 4, row * 6 + 4
	call	ll51_add
	ld	a, b
	ld	(XX12 + row * 2), a
	ld	a, c
	ld	(XX12 + row * 2 + 1), a
	endm
LL51:
	LL51ROW 0
	LL51ROW 1
	LL51ROW 2
	ld	bc, 0x1206
	ld	a, 18
	scf
	ret
; (C B) += (A D): модуль в B и D, знак — бит 7 у C и A
ll51_add:
	xor	c
	jp	m, ll51_sub
	ld	a, b
	add	a, d
	ld	b, a
	ret
ll51_sub:
	ld	a, b
	sub	d
	ld	b, a
	ret	nc
	cpl
	inc	a
	ld	b, a
	ld	a, c
	xor	0x80
	ld	c, a
	ret

; LL120, LL123: для отсечения отрезка — (Y X) = (S x1_lo) · наклон или (S R) / наклон, со знаком.
; LL120: R = XX15, затем как LL123, но при T = 0 умножение, иначе деление; у LL123 наоборот.
LL120:
	ld	a, (XX15)
	ld	(R_), a
	call	LL129
	ld	e, a
	ld	a, (T)
	or	a
	jp	nz, ll121
ll122:
	ld	bc, 0			; (Y X) = (S R) · Q / 256
	ld	hl, (R_)		; L = R, H = S
	ld	a, (Q)
	ld	d, a
	ld	a, h
	or	a
	rra
	ld	h, a
	ld	a, l
	rra
	ld	l, a
	ld	a, d
	add	a, a
	ld	d, a
	jp	nc, ll126
ll125:
	ld	a, b
	add	a, l
	ld	b, a
	ld	a, c
	adc	a, h
	ld	c, a
ll126:
	ld	a, h
	or	a
	rra
	ld	h, a
	ld	a, l
	rra
	ld	l, a
	ld	a, d
	add	a, a
	ld	d, a
	jp	c, ll125
	jp	nz, ll126
	ld	(R_), hl
	ld	(Q), a
	ld	a, e
	or	a
	jp	p, ll133
	ret
LL123:
	call	LL129
	ld	e, a
	ld	a, (T)
	or	a
	jp	nz, ll122
ll121:
	ld	bc, 0xFEFF		; (Y X) = (S R) / Q
	ld	hl, (R_)
	ld	a, (Q)
	ld	d, a
ll130:
	add	hl, hl
	ld	a, h
	jp	c, ll131
	cp	d
	jp	c, ll132_0
ll131:
	sub	d
	ld	h, a
	ld	a, l
	sbc	a, 0
	ld	l, a
	scf
	jp	ll132
ll132_0:
	or	a
ll132:
	ld	a, b
	rla
	ld	b, a
	ld	a, c
	rla
	ld	c, a
	jp	c, ll130
	ld	(R_), hl
	ld	a, e
	or	a
	ret	m
ll133:
	ld	a, b			; сменить знак (Y X)
	cpl
	add	a, 1
	ld	b, a
	ld	a, c
	cpl
	adc	a, 0
	ld	c, a
	ret

; NORM: нормировать вектор XX15(2 1 0) до длины 96.
NORM:
	ld	a, (XX15)
	call	SQUA
	ld	(R_), a
	ld	a, (P_)
	ld	(Q), a
	ld	a, (XX15 + 1)
	call	norm_sq
	ld	a, (XX15 + 2)
	call	norm_sq
	call	LL5
	ld	a, (XX15)
	call	TIS2
	ld	(XX15), a
	ld	a, (XX15 + 1)
	call	TIS2
	ld	(XX15 + 1), a
	ld	a, (XX15 + 2)
	call	TIS2
	ld	(XX15 + 2), a
	ret
norm_sq:
	call	SQUA			; (R Q) += A · A
	ld	(T), a
	ld	hl, Q
	ld	a, (P_)
	add	a, (hl)
	ld	(hl), a
	ld	hl, R_
	ld	a, (T)
	adc	a, (hl)
	ld	(hl), a
	ret

; TIS3: A = -(INWK+10,X · INWK+16,X + INWK+10,Y · INWK+16,Y) / INWK+10,A — третья координата вектора из
; условия перпендикулярности. Конец — DVIDT.
TIS3:
	ld	(P_ + 2), a
	ld	e, b
	ld	d, 0
	ld	hl, INWK + 10
	add	hl, de
	ld	a, (hl)
	ld	(Q), a
	ld	hl, INWK + 16
	add	hl, de
	ld	a, (hl)
	call	MULT12
	ld	e, c
	ld	d, 0
	ld	hl, INWK + 10
	add	hl, de
	ld	a, (hl)
	ld	(Q), a
	ld	hl, INWK + 16
	add	hl, de
	ld	a, (hl)
	call	MAD
	push	af
	ld	a, b
	ld	(P_), a
	ld	a, (P_ + 2)
	ld	c, a
	ld	e, a
	ld	d, 0
	ld	hl, INWK + 10
	add	hl, de
	ld	a, (hl)
	ld	(Q), a
	ld	b, a
	pop	af
	xor	0x80
	jp	DVIDT

; TIDY: выправить матрицу ориентации корабля: нормировать nosev и roofv, сделать их перпендикулярными,
; sidev = nosev × roofv.
TIDY:
	ld	hl, INWK + 10
	call	tidy_norm
	ld	c, 4
	ld	a, (XX15)
	and	0x60
	jp	z, ti1
	ld	b, 2
	xor	a
	call	TIS3
	ld	(INWK + 16), a
	jp	ti3
ti1:
	ld	b, a
	ld	a, (XX15 + 1)
	and	0x60
	jp	z, ti2
	ld	a, 2
	call	TIS3
	ld	(INWK + 18), a
	jp	ti3
ti2:
	ld	a, c
	ld	c, 2
	call	TIS3
	ld	(INWK + 20), a
ti3:
	ld	hl, INWK + 16
	call	tidy_norm
	ld	a, (INWK + 12)
	ld	(Q), a
	ld	a, (INWK + 20)
	call	MULT12
	ld	a, (INWK + 14)
	ld	b, a
	ld	a, (INWK + 18)
	call	TIS1
	xor	0x80
	ld	(INWK + 22), a
	ld	a, (INWK + 16)
	call	MULT12
	ld	a, (INWK + 10)
	ld	b, a
	ld	a, (INWK + 20)
	call	TIS1
	xor	0x80
	ld	(INWK + 24), a
	ld	a, (INWK + 18)
	call	MULT12
	ld	a, (INWK + 12)
	ld	b, a
	ld	a, (INWK + 16)
	call	TIS1
	xor	0x80
	ld	(INWK + 26), a
	ld	hl, INWK + 9
	ld	b, 8
	xor	a
tidy_z:
	ld	(hl), a			; младшие байты матрицы — в ноль
	inc	hl
	inc	hl
	dec	b
	jp	nz, tidy_z
	ld	b, 0xFE
	ret
; три старших байта вектора по адресу HL (через один) → XX15, NORM, обратно
tidy_norm:
	push	hl
	ld	de, XX15
	ld	b, 3
tn_in:
	ld	a, (hl)
	ld	(de), a
	inc	hl
	inc	hl
	inc	de
	dec	b
	jp	nz, tn_in
	call	NORM
	pop	hl
	ld	de, XX15
	ld	b, 3
tn_out:
	ld	a, (de)
	ld	(hl), a
	inc	hl
	inc	hl
	inc	de
	dec	b
	jp	nz, tn_out
	ret
geom_end:
