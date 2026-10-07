; Арифметика кассетной версии BBC, вторая партия (задача Q4). Правила — docs/spec/porting.md.
; Регистры: A — как на BBC, X -> B, Y -> C, перенос — как на 6502. После вызова нулевая страница, A, X, Y и
; перенос равны эталону (v06c/test/q4.mjs); отступления названы в заголовке процедуры.

; MU5: K(3 2 1 0) = (A A A A), перенос 0. X, Y не меняются.
MU5:
	ld	(K), a
	ld	(K + 1), a
	ld	(K + 2), a
	ld	(K + 3), a
	or	a			; перенос 0
	ret

; TIS1: A = (-X * A + (S R)) / 96, знак — бит 7.
TIS1:
	ld	l, a			; i8080: в (nn) пишет только A — бережём A в L
	ld	a, b
	ld	(Q), a			; STX Q
	ld	a, l
	xor	0x80			; EOR #%10000000
	call	MAD			; JSR MAD
	; дальше исполнение проваливается в DVID96

; DVID96: A = A / 96, знак — бит 7. На выходе X = FEh, перенос 0, T — знак, T1 — частное. Y не меняется.
DVID96:
	ld	b, a			; TAX
	and	0x80
	ld	(T), a			; T = знак
	ld	a, b			; TXA
	and	0x7F			; A = |A| — остаток, 8-битный, как на 6502
	ld	hl, 0			; частное (на 6502 — биты, заходящие в T1)
	ld	e, 8			; сторож 254 на 6502 — восемь шагов
dvid96_1:
	add	a, a			; ASL A
	cp	96
	jp	c, dvid96_2		; CMP #96 : BCC DV4 — на i8080 CY=1 значит «меньше»
	sub	96			; SBC #96 (перенос 6502 здесь 1 — заёма нет)
	add	hl, hl		; ROL T1: частное *2…
	inc	l			; …и бит 1 (перенос вычитания)
	jp	dvid96_3
				; не вычитали — ROL T1 с битом 0
dvid96_2:
	add	hl, hl
dvid96_3:
	dec	e
	jp	nz, dvid96_1
	ld	a, l			; LDA T1
	ld	(T1), a
	ld	b, 254			; LDX #254: на выходе X = FEh
	ld	hl, T
	or	(hl)			; ORA T (перенос и так 0)
	ret

; MUT3: P = ALP1. MUT2: S = XX+1. MUT1: R = XX. Дальше MULT1 (jp — провал в конце). A, Y не меняются.
MUT3:
	ld	e, a			; i8080: в (nn) пишет только A — бережём A в E
	ld	hl, ALP1
	ld	b, (hl)			; LDX ALP1
	ld	a, b
	ld	(P_), a			; STX P
	ld	a, e
MUT2:
	ld	e, a
	ld	hl, XX + 1
	ld	b, (hl)			; LDX XX+1
	ld	a, b
	ld	(S), a			; STX S
	ld	a, e
MUT1:
	ld	e, a
	ld	hl, XX
	ld	b, (hl)			; LDX XX
	ld	a, b
	ld	(R_), a			; STX R
	ld	a, e
	jp	MULT1

; DV42: A = SZ,Y. DV41: Q = A, A = DELTA. Дальше DVID4. Y не меняется (индекс — через DE).
DV42:
	ld	hl, SZ
	ld	e, c
	ld	d, 0
	add	hl, de
	ld	a, (hl)			; LDA SZ,Y
DV41:
	ld	(Q), a			; STA Q
	ld	a, (DELTA)		; LDA DELTA
	jp	DVID4			; провал в DVID4
