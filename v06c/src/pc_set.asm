; Набор адресов и масок одной окружности (planet.asm: module pa — первая, module pb — вторая окружность пары).
; xs/ys — сдвиг на шаг по x и по y, pl — точки шага, pr1 — пара (X, Y ± y), init — начало (только у первого набора:
; второй получает адреса копией, pc_pr2). Во втором наборе пары точек — подпрограммой (pc_ppb, pc_ppc).
xs:					; x + 1: столбец X + x вправо, X - x влево, строка Y + x дальше
	ifdef	PCREG
	ld	a, d
	rrca
	ld	d, a
	else
	ld	hl, m1
	ld	a, (hl)
	rrca
	ld	(hl), a
	endif
	jp	nc, .a
	ld	hl, p1 + 2
	inc	(hl)
.a:
	ifdef	PCREG
	ld	a, e
	rlca
	ld	e, a
	else
	ld	hl, m2
	ld	a, (hl)
	rlca
	ld	(hl), a
	endif
	jp	nc, .b
	ld	hl, h2 + 1
	dec	(hl)
.b:
	ld	hl, p3 + 1
	dec	(hl)
	ret
ys:					; y - 1: строка Y + y ближе к центру, столбец X + y влево, X - y вправо
	ld	hl, p1 + 1
	inc	(hl)
	ld	hl, m3
	ld	a, (hl)
	rlca
	ld	(hl), a
	jp	nc, .c
	ld	hl, p3 + 2
	dec	(hl)
.c:
	ld	hl, m4
	ld	a, (hl)
	rrca
	ld	(hl), a
	ret	nc
	ld	hl, h4 + 1
	inc	(hl)
	ret
pl:
	call	pr1			; (X + x, Y ± y)
	ld	hl, (p1 + 1)
h2:
	ld	h, 0			; (X - x, Y ± y)
	ifdef	PCREG
	PCPAIR	e, b, x1, x2
	else
	ld	a, (m2)
	call	@pc_ppb
	endif
	ld	a, b
	cp	c
	ret	z			; x = y: вторая четвёрка совпала бы с первой
p3:
	ld	hl, 0			; (X + y, Y ± x)
	ifdef	PCREG
	PCPAIR	(m3), c, x3, x4
	else
	ld	a, (m3)
	call	@pc_ppc
	endif
	ld	hl, (p3 + 1)
h4:
	ld	h, 0			; (X - y, Y ± x)
	ifdef	PCREG
	PCPAIR	(m4), c, x5, x6
	ret
	else
	ld	a, (m4)
	jp	@pc_ppc
	endif
pr1:
p1:
	ld	hl, 0
	ifdef	PCREG
	PCPAIR	d, b, x7, x8
	ret
	else
	ld	a, (m1)
	jp	@pc_ppb
	endif
	ifdef	PCREG
; in: HL -> x центра (слово), y центра (байт), радиус (2..127): адреса и маски набора; точки (X ± r, Y), (X, Y ± r).
; На выходе B = 2r, C = 0, pc_d = 1 - r. Портит всё.
init:
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
	call	@pc_col			; столбец X + r
	ld	(m3), a
	ld	a, d
	ld	(p3 + 2), a
	pop	de
	push	de
	ld	a, e
	sub	b
	ld	l, a
	ld	a, d
	sbc	a, 0
	ld	h, a
	call	@pc_col			; столбец X - r
	ld	(m4), a
	ld	a, d
	ld	(h4 + 1), a
	ld	a, c
	cpl
	ld	(p3 + 1), a		; строка Y
	sub	b
	ld	(p1 + 1), a		; строка Y + r
	ld	hl, (p3 + 1)
	ld	a, (m3)
	call	@pc_pt			; (X + r, Y)
	ld	hl, (p3 + 1)
	ld	a, (h4 + 1)
	ld	h, a
	ld	a, (m4)
	call	@pc_pt			; (X - r, Y)
	pop	hl
	call	@pc_col			; столбец X
	ld	e, a			; маски X ± x — в D и E (второй набор их не трогает)
	ld	a, d
	ld	(p1 + 2), a
	ld	(h2 + 1), a
	ld	d, e
	ld	a, b
	cpl
	ld	l, a
	ld	h, 0xFF
	inc	hl
	inc	hl
	ld	(@pc_d), hl		; d = 1 - r
	ld	a, b
	add	a, a
	ld	b, a			; B = 2y
	ld	c, 0			; C = 2x
	jp	pr1			; (X, Y + r), (X, Y - r)
	endif
	ifndef	PCREG
m1:	db	0			; маски точек: X + x, X - x (в первом наборе — в D, E), X + y, X - y
m2:	db	0
	endif
m3:	db	0
m4:	db	0
