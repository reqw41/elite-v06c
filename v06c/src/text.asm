; Печать знака — TT26 кассетной версии BBC.

; TT26: знак A в текстовую позицию (XC, YC), исключающим ИЛИ в плоскость обзора; знакоместо 8×8, 32 в строке.
; 7 — гудок, 10 — вниз на строку, прочие ниже 32 — новая строка (XC = 1), 127 — стереть знак слева.
; QQ17 = 255 — печать выключена. YC >= 24 — очистка экрана (TTX66) вместо печати.
; Сохраняет все регистры, на выходе C = 0 (как на BBC). Рабочие ячейки BBC (P+1, P+2, SC, XSAV2, YSAV2)
; здесь не трогаются; K3 = знак, как на BBC.
TT26:
	ifndef	SCHED
	push	hl			; идёт текст с выравниванием (pdesc.asm): знак — в его буфер
	ld	hl, pd_cap
	inc	(hl)
	dec	(hl)
	pop	hl
	jp	nz, pd_hook
	endif
TT26R:
	ld	(K3), a
	push	bc
	push	de
	push	hl
	ld	c, a
	ld	a, (QQ17)
	inc	a
	jp	z, tt_ret
	ld	a, c
	cp	7
	jp	z, tt_beep
	cp	32
	jp	nc, tt_chr
	cp	10
	jp	z, tt_lf
	ld	a, 1
	ld	(XC), a
tt_lf:
	ld	hl, YC
	inc	(hl)
	jp	tt_ret
tt_chr:
	ld	l, c
	ld	h, 0
	add	hl, hl
	add	hl, hl
	add	hl, hl
	ld	de, font - 32 * 8
	add	hl, de
	ex	de, hl			; DE -> 8 байт знака
	ld	a, (XC)
	ld	b, a
	and	31			; на BBC XC·8 берётся по модулю 256
	or	high SCR_VIEW
	ld	h, a			; столбец экрана
	ld	a, c
	cp	127
	jp	z, tt_del
	ld	a, b
	inc	a
	ld	(XC), a
	ld	a, (YC)
	cp	24
	jp	nc, tt_cls
	add	a, a
	add	a, a
	add	a, a
	cpl
	ld	l, a			; 255 - YC·8: верхняя строка знакоместа
	ld	b, 8
tt_row:
	ld	a, (de)
	xor	(hl)
	ld	(hl), a
	inc	de
	dec	l
	dec	b
	jp	nz, tt_row
tt_ret:
	pop	hl
	pop	de
	pop	bc
	ld	a, (K3)
	or	a			; C = 0
	ret
tt_beep:
	call	BEEP
	jp	tt_ret
tt_cls:
	call	TTX66
	jp	tt_ret
; 127: обнулить знакоместо слева от курсора и сдвинуть курсор влево. При XC, кратном 32, BBC обнуляет
; последнее знакоместо предыдущей строки.
tt_del:
	ld	a, b
	dec	a
	ld	(XC), a
	ld	a, (YC)
	ld	c, a
	ld	a, h
	and	31
	jp	nz, td_col
	dec	c			; строка выше
	ld	a, 32
td_col:
	dec	a
	or	high SCR_VIEW
	ld	h, a
	ld	a, c
	cp	24
	jp	nc, tt_ret		; вне обзора (на BBC — запись мимо экрана)
	add	a, a
	add	a, a
	add	a, a
	cpl
	ld	l, a
	ld	b, 8
td_row:
	ld	(hl), 0
	ld	a, h			; и во второй плоскости
	xor	0x20
	ld	h, a
	ld	(hl), 0
	xor	0x20
	ld	h, a
	dec	l
	dec	b
	jp	nz, td_row
	jp	tt_ret

; BEEP: короткий высокий гудок (звук номер 32; само звучание — этап P6).
BEEP:
	ld	a, 32
	jp	NOISE

; Строка: HL -> знаки, конец — 0.
prstr:
	ld	a, (hl)
	or	a
	ret	z
	call	TT26
	inc	hl
	jp	prstr

	ifdef	SCHED			; в игре не вызывается — только из тестов (образ стенда)
; A двумя шестнадцатеричными знаками.
prhex:
	push	af
	rrca
	rrca
	rrca
	rrca
	call	ph_dig
	pop	af
ph_dig:
	and	15
	add	a, '0'
	cp	'9' + 1
	jp	c, TT26
	add	a, 'A' - '9' - 1
	jp	TT26
	endif
