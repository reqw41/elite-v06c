; Арифметика кассетной версии BBC, первая партия (T06). Правила переноса — docs/spec/porting.md.
; Регистры: A — как на BBC, X -> B, Y -> C, перенос — как на 6502. После вызова нулевая страница, A, X, Y и
; перенос равны эталону (v06c/test/t06.mjs); отступления названы в заголовке процедуры.
arith_start:

; MULHI: A = старший байт E · A (mul8h).
	macro	MULHI
	call	mul8h
	endm

; mul8: HL = E · A, без знака. Общее ядро умножений: a·b = f(a + b) - f(|a - b|), f(x) = x·x / 4 нацело.
; Таблица f — SQLO (младшие байты, 512 значений) и на две страницы выше старшие; строит sq_init при запуске.
; Портит A, DE. Сохраняет BC.
mul8:
	ld	d, a
	add	a, e
	ld	l, a
	ld	a, high SQLO
	adc	a, 0
	ld	h, a			; HL -> f(a + b), младший байт
	ld	a, d
	sub	e
	jp	nc, m8_p
	cpl
	inc	a
m8_p:
	ld	e, (hl)
	inc	h
	inc	h
	ld	d, (hl)			; DE = f(a + b)
	ld	l, a
	ld	h, high SQLO		; HL -> f(|a - b|)
	ld	a, e
	sub	(hl)
	ld	e, a
	inc	h
	inc	h
	ld	a, d
	sbc	a, (hl)
	ld	h, a
	ld	l, e
	ret
; mul8h: A = старший байт E · A — как mul8, но младший байт не собирается. Портит DE, HL, флаги. Сохраняет BC.
; A = 0 (в полёте больше трети вызовов: нулевые координаты нормалей и вершин) — сразу 0 с теми же S, Z, C.
mul8h:
	or	a
	ret	z
	ld	d, a
	add	a, e
	ld	l, a
	ld	a, high SQLO
	adc	a, 0
	ld	h, a
	ld	a, d
	sub	e
	jp	nc, m8h_p
	cpl
	inc	a
m8h_p:
	ld	e, (hl)
	inc	h
	inc	h
	ld	d, (hl)
	ld	l, a
	ld	h, high SQLO
	ld	a, e
	sub	(hl)
	inc	h
	inc	h
	ld	a, d
	sbc	a, (hl)
	ret

	ifdef	SCHED
	include	"init_sq.asm"
	endif

; SQUA: (A P) = A·A, бит 7 у A отбрасывается. SQUA2: то же без отбрасывания.
SQUA:
	and	0x7F
SQUA2:
	ld	(P_), a
	ld	b, a
	or	a
	jp	nz, MU11
; MU1: P = X, A = X, перенос 0.
MU1:
	ld	a, b
	ld	(P_), a
	or	a
	ret

; MLU1: Y1 = SY+Y, (A P) = |Y1| · Q. MLU2: (A P) = |A| · Q.
MLU1:
	ld	hl, SY
	ld	b, 0
	add	hl, bc
	ld	a, (hl)
	ld	(Y1), a
MLU2:
	and	0x7F
	ld	(P_), a
; MULTU: (A P) = P · Q без знака. На выходе X = 0, перенос 0, T = Q - 1 (при Q = 0 T не меняется).
MULTU:
	ld	a, (Q)
	ld	b, a
	or	a
	jp	z, MU1
; MU11: (A P) = P · X, X <> 0.
MU11:
	ld	a, b
	dec	a
	ld	(T), a
	ld	a, (P_)
	ld	e, a
	ld	a, b
	call	mul8
	ld	a, l
	ld	(P_), a
	ld	a, h
	ld	b, 0
	or	a			; перенос 0
	ret

; MU6: P(1 0) = (A A).
MU6:
	ld	(P_ + 1), a
	ld	(P_), a
	ret

; FMLTU: A = A · Q / 256 без знака. На выходе P = 0, перенос 1, X не меняется.
FMLTU:
	ld	e, a
	ld	a, (Q)
	MULHI
	ld	d, a
	xor	a
	ld	(P_), a
	ld	a, d
	scf
	ret

; MULT1: (A P) = Q · A, оба со знаком в бите 7. T = знак, T1 = |Q| - 1, X = 0, перенос 0.
; При |Q| = 0: (A P) = 0, X = A на входе, перенос = бит 0 у A, T1 не меняется.
MULT1:
	ld	d, a
	and	0x7F
	ld	e, a			; |A|
	ld	a, (Q)
	ld	h, a
	xor	d
	and	0x80
	ld	(T), a
	ld	a, h
	and	0x7F
	jp	z, mu10
	ld	h, a
	dec	a
	ld	(T1), a
	ld	a, h
	call	mul8
	ld	a, l
	ld	(P_), a
	ld	a, (T)
	or	h			; перенос 0
	ld	b, 0
	ret
mu10:
	ld	(P_), a
	ld	b, d
	ld	a, e
	rrca				; перенос = бит 0 у |A|
	ld	a, 0
	ret

; MLS2: (S R) = XX(1 0), затем MLS1. MLS1: P = ALP1, затем MULTS.
; MULTS: (A P) = |A| · (P & 31) со знаком A в бите 7. T = знак, T1 = X = |A| - 1, перенос 0.
; При |A| = 0: P(1 0) = 0, A = 0, X = A на входе, перенос не меняется, T1 не меняется.
MULTS_2:				; на BBC — MULTS-2: сначала P = X
	ld	d, a
	ld	a, b
	ld	(P_), a
	ld	a, d
	jp	MULTS
MLS2:
	ld	hl, (XX)
	ld	(R_), hl		; R и S — соседние ячейки
MLS1:
	ld	d, a
	ld	a, (ALP1)
	ld	(P_), a
	ld	a, d
MULTS:
	ld	b, a
	push	af
	and	0x80
	ld	(T), a
	ld	a, b
	and	0x7F
	jp	z, ms_zero
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
	or	h			; перенос 0
	ret
ms_zero:
	pop	af			; перенос — как на входе
	ld	a, 0
	ld	(P_ + 1), a
	ld	(P_), a
	ret

; MLTU2: (A P+1 P) = (A ~P) · Q без знака: старший байт множимого в A, младший лежит в P перевёрнутым.
; X = 0, перенос 0.
MLTU2_2:				; на BBC — MLTU2-2: сначала Q = X
	ld	d, a
	ld	a, b
	ld	(Q), a
	ld	a, d
MLTU2:
	push	bc
	ld	c, a
	ld	a, (Q)
	ld	b, a
	ld	e, a
	ld	a, (P_)
	cpl
	call	mul8			; младший байт · Q
	ld	a, l
	ld	(P_), a
	push	hl
	ld	e, b
	ld	a, c
	call	mul8			; старший байт · Q
	pop	de
	ld	e, d
	ld	d, 0
	add	hl, de
	ld	a, l
	ld	(P_ + 1), a
	ld	a, h
	pop	bc
	ld	b, 0
	or	a
	ret

; MULT12: (S R) = Q · A со знаком.
MULT12:
	call	MULT1
	ld	(S), a
	ld	a, (P_)
	ld	(R_), a
	ret

; MAD: (A X) = Q · A + (S R). ADD: (A X) = (A P) + (S R). Числа со знаком в бите 7 старшего байта.
; В отличие от BBC, не пишет T1 и T (трассировка сценариев: после ADD чужих читателей нет). U пишется:
; его читает BPRNT на экране сохранения.
MAD:
	call	MULT1
ADD:
	ld	d, a
	and	0x80
	ld	e, a
	ld	hl, (R_)		; L = R, H = S — соседние ячейки
	xor	h
	jp	m, MU8
	ld	a, (P_)
	add	a, l
	ld	b, a
	ld	a, h
	adc	a, d
	or	e
	inc	e			; перенос 6502 здесь равен знаку слагаемых
	dec	e
	ret	z
	scf
	ret
MU8:
	ld	a, h
	and	0x7F
	ld	h, a
	ld	(U), a			; как на BBC: U читает BPRNT на экране сохранения
	ld	a, d
	and	0x7F
	ld	d, a			; |A|
	ld	a, (P_)
	sub	l
	ld	b, a
	ld	a, d
	sbc	a, h
	jp	c, mu8_neg
	xor	e
	scf
	ret
mu8_neg:
	ld	h, a
	ld	a, b
	cpl
	inc	a			; Z: младший байт нулевой
	ld	b, a
	ld	a, h
	cpl
	jp	nz, mu8_e
	inc	a
mu8_e:
	or	0x80
	xor	e			; перенос 0
	ret

; DVID4: P = A / Q (целая часть), R = 256 · остаток / Q. X = FEh, перенос 0, A — остаток второго деления.
; Первый этап — циклом (B — счётчик: дальше LL28_4 всё равно ставит в B FEh); зовётся редко, меньше раза за
; проход (пыль в боковых видах, панель, взрывы), развёрнутым он был на 85 байт длиннее.
DVID4:
	ld	l, a
	ld	h, 0
	ld	a, (Q)
	ld	e, a
	ld	b, 8
dv4_l:
	add	hl, hl
	jp	c, dv4_s
	ld	a, h
	cp	e
	jp	c, dv4_n
dv4_s:
	ld	a, h
	sub	e
	ld	h, a
	inc	l
dv4_n:
	dec	b
	jp	nz, dv4_l
	ld	a, l
	ld	(P_), a
	ld	a, h
	jp	LL28_4

; LL28: R = 256 · A / Q. При A >= Q: R = 255, A = 255, перенос 1, X не меняется.
; Иначе X = FEh, перенос 0, A — остаток. LL28_4 — вход без проверки (на BBC — LL28+4).
LL28:
	ld	hl, Q
	cp	(hl)
	jp	nc, LL2
LL28_4:
	ld	b, 0xFE
; LL31: вход с готовым R (его ставит вызывающий), X не меняется.
LL31:
	ld	h, a
	ld	l, 0
	ld	a, (Q)
	ld	e, a
	dup	8			; развёрнуто: остаток в H, частное в L
	add	hl, hl
	ld	a, h
	jp	c, $ + 7		; вышло за байт — вычитать
	cp	e
	jp	c, $ + 6
	sub	e
	ld	h, a
	inc	l
	edup
	ld	a, l
	ld	(R_), a
	ld	a, h
	or	a
	ret
LL2:
	ld	a, 255
	ld	(R_), a
	scf
	ret

; LL5: Q = корень из (R Q). Тот же побитовый счёт, что на BBC, но в регистрах: остаток — B и H, под ним S — L
; (сдвиг пары HL одной командой), результат — D, счётчик — E. На выходе Q, S = 0, T = 0, A, X (B), Y (C) и
; перенос — как на BBC. DE сохраняются.
LL5:
	push	de
	ld	a, (R_)
	ld	h, a
	ld	a, (Q)
	ld	l, a
	ld	b, 0
	ld	d, b
	ld	e, 8
ll6:
	ld	a, b
	cp	d
	jp	c, ll7_0
	jp	nz, ll8
	ld	a, h
	cp	64
	jp	c, ll7_0
ll8:
	ld	a, h
	sub	64
	ld	h, a
	ld	a, b
	sbc	a, d
	ld	b, a
	scf
	jp	ll7
ll7_0:
	or	a
ll7:
	ld	a, d
	rla
	ld	d, a
	dup	2
	add	hl, hl
	ld	a, b
	rla
	ld	b, a
	edup
	dec	e
	jp	nz, ll6
	ld	c, h			; дальше флаги не меняются: перенос — от последнего сдвига
	ld	hl, Q
	ld	(hl), d
	ld	hl, S
	ld	(hl), 0
	ld	hl, T
	ld	(hl), 0
	pop	de
	ret

; DORND: случайное число в A и X, перенос — как на BBC. DORND2 — то же с переносом 0 на входе.
; Флаг переполнения 6502 (им пользуется один вызов) не возвращается.
DORND2:
	or	a
DORND:
	ld	hl, RAND
	ld	a, (hl)
	rla
	ld	b, a
	inc	hl
	inc	hl
	adc	a, (hl)
	ld	(hl), b
	dec	hl
	dec	hl
	ld	(hl), a
	inc	hl
	ld	a, (hl)
	ld	b, a
	inc	hl
	inc	hl
	adc	a, (hl)
	ld	(hl), b
	dec	hl
	dec	hl
	ld	(hl), a
	ret
arith_end:
