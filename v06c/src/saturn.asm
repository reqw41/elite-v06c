; Заставка загрузчика кассетной BBC: Сатурн из случайных точек и три надписи. Нужна один раз, при запуске,
; поэтому лежит не в памяти игры, а в рабочих областях (блоки кораблей, с WS + 0900h): образ на ленте доходит
; до конца этого кода, а после показа область обнуляется, как и положено рабочим областям.
; Рисование — перенос PLL1, PLL2, PLL3 загрузчика (elite-loader.asm) с его же генератором случайных чисел;
; перенос 6502 между шагами хранится в sat_c. Сверка — v06c/test/saturn.mjs: экран равен экрану настоящего кода
; загрузчика при том же «таймере». На BBC затравка берётся от таймера VIA; здесь — счётчик sat_t с шагом 2Fh.
; Только обычный образ.
	ifndef	SCHED
sat_show:
	ld	hl, 0x5349		; затравка генератора — как в загрузчике BBC: 49 53 78 6C
	ld	(RAND), hl
	ld	hl, 0x6C78
	ld	(RAND + 2), hl
	ld	de, sat_asoft		; надписи: ACORNSOFT — строка 1, ELITE — строка 3, права — строка 22
	ld	a, 255 - 8
	call	sat_row
	ld	a, 255 - 24
	call	sat_row
	ld	a, 255 - 176
	call	sat_row
sat_draw:
	ld	bc, 0x0500		; --- шар: 1280 попыток
sat_p1:
	push	bc
	ld	hl, sat_t
	ld	a, (hl)
	ld	(RAND + 1), a
	add	a, 0x2F
	ld	(hl), a
	ld	a, (sat_c)
	rra
	call	sat_rnd
	call	sat_sq
	push	de
	or	a
	call	sat_rnd
	ld	(sat_yy), a
	call	sat_sq
	pop	hl
	add	hl, de			; x^2 + y^2
	jp	c, sat_c1
	xor	a			; 4000h - (x^2 + y^2)
	sub	l
	ld	l, a
	ld	a, 0x40
	sbc	a, h
	jp	c, sat_c0
	ld	(R_), a
	ld	a, l
	ld	(Q), a
	call	LL5
	ld	a, (Q)
	or	a
	rra
	ld	d, a
	ld	a, (sat_yy)
	ld	e, a
	add	a, a
	ld	a, e
	rra
	call	sat_pix
	jp	sat_n1
sat_c1:
	ld	a, 1
	db	0x01			; LD BC, nn — пропустить XOR A
sat_c0:
	xor	a
	nop
	ld	(sat_c), a
sat_n1:
	pop	bc
	dec	c
	jp	nz, sat_p1
	dec	b
	jp	nz, sat_p1
	ld	bc, 0x01DD		; --- звёзды: 221 попытка
sat_p2:
	push	bc
	ld	a, (sat_c)
	rra
	call	sat_rnd
	ld	(sat_x), a
	call	sat_sq
	ld	a, d
	ld	(sat_h), a
	or	a
	call	sat_rnd
	ld	(sat_yy), a
	call	sat_sq
	ld	a, (sat_h)
	add	a, d
	cp	0x11
	jp	c, sat_s2		; близко к центру — не звезда
	ld	a, (sat_x)
	ld	d, a
	ld	a, (sat_yy)
	call	sat_pix
	jp	sat_n2
sat_s2:
	xor	a
	ld	(sat_c), a
sat_n2:
	pop	bc
	dec	c
	jp	nz, sat_p2
	dec	b
	jp	nz, sat_p2
	ld	bc, 0x0500		; --- кольца: 1280 попыток
sat_p3:
	push	bc
	ld	a, (sat_c)
	rra
	call	sat_rnd
	ld	(sat_zp), a
	call	sat_sq
	ld	a, d
	ld	(sat_h), a
	or	a
	call	sat_rnd
	ld	(sat_yy), a
	call	sat_sq
	ld	a, d
	ld	(sat_t2), a
	ld	hl, sat_h
	add	a, (hl)
	ld	(hl), a
	ld	a, (sat_zp)		; наклон колец: x / 4 со знаком + y
	ld	e, a
	add	a, a
	ld	a, e
	rra
	ld	e, a
	add	a, a
	ld	a, e
	rra
	ld	hl, sat_yy
	adc	a, (hl)
	ld	(sat_x), a
	call	sat_sq
	ld	a, (sat_h)
	add	a, d
	jp	c, sat_k1
	cp	80
	jp	nc, sat_k1
	cp	32
	jp	c, sat_k0
	ld	a, (sat_t2)
	scf
	adc	a, d
	cp	16
	jp	nc, sat_pl
	ld	a, (sat_zp)
	or	a
	jp	p, sat_k0
sat_pl:
	ld	a, (sat_x)
	ld	d, a
	ld	a, (sat_yy)
	call	sat_pix
	jp	sat_n3
sat_k1:
	ld	a, 1
	db	0x01
sat_k0:
	xor	a
	nop
	ld	(sat_c), a
sat_n3:
	pop	bc
	dec	c
	jp	nz, sat_p3
	dec	b
	jp	nz, sat_p3
	ret
; sat_rnd: генератор загрузчика (DORND из elite-loader.asm): перенос на входе и на выходе — как на BBC.
sat_rnd:
	ld	hl, RAND + 1
	ld	a, (hl)
	ld	b, a
	inc	hl
	inc	hl
	adc	a, (hl)
	ld	(hl), b
	dec	hl
	dec	hl
	ld	(hl), a
	dec	hl
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
; sat_sq: DE = квадрат числа A со знаком (по таблице квадратов); перенос на выходе 0, как у SQUA2 загрузчика.
sat_sq:
	or	a
	jp	p, sat_q1
	cpl
	inc	a
sat_q1:
	ld	l, a
	ld	h, 0
	add	hl, hl
	ld	de, SQLO
	add	hl, de
	ld	e, (hl)
	inc	h
	inc	h
	ld	d, (hl)
	or	a
	ret
; sat_pix (PIX): точка (D xor 80h, A xor 80h) — ИЛИ в плоскость обзора; в sat_c — бит 2 числа A (перенос BBC).
sat_pix:
	ld	e, a
	rra
	rra
	and	1
	ld	(sat_c), a
	ld	a, e
	xor	0x80
	cpl
	ld	l, a
	ld	a, d
	xor	0x80
	ld	d, a
	rrca
	rrca
	rrca
	and	0x1F
	or	high SCR_VIEW
	ld	h, a
	ld	a, d
	and	7
	add	a, low TWOS
	ld	e, a
	ld	d, high TWOS
	ld	a, (de)
	or	(hl)
	ld	(hl), a
	ret
; sat_row: строка надписи: 256 байт с адреса DE в раскладке BBC (32 знакоместа по 8 байт) — в строки экрана,
; верхняя из которых задана A = 255 - y. DE на выходе — за строкой.
sat_row:
	ld	c, a
	ld	h, high SCR_VIEW
sat_r1:
	ld	l, c
	ld	b, 8
sat_r2:
	ld	a, (de)
	ld	(hl), a

	ld	a, h			; надписи — зелёным: и во второй плоскости
	xor	0x20
	ld	h, a
	ld	a, (de)
	ld	(hl), a
	ld	a, h
	xor	0x20
	ld	h, a
	inc	de
	dec	l
	dec	b
	jp	nz, sat_r2
	inc	h
	ld	a, h
	cp	high SCR_VIEW + 32
	jp	nz, sat_r1
	ret
; sat_wait: ждать нажатия клавиши (прерывания уже идут). Считается только новое нажатие: всё, что нажато с
; самого начала (клавиша, которой запускали загрузку; ложное «нажатие» джойстика, чьё состояние покоя снято
; раньше, чем установился порт), лежит в «базе» hm_buf и выходит из неё, когда отпущено.
sat_wait:
	call	mus_start		; «Голубой Дунай»
	call	joy_init		; покой джойстиков — заново
	ld	hl, hm_buf
	ld	b, 8
sat_w0:
	ld	(hl), 0xFF
	inc	hl
	dec	b
	jp	nz, sat_w0
sat_w1:
	ld	c, 1
	call	DELAY
	ld	hl, kb_rows
	ld	de, hm_buf
	ld	b, 8
sat_w2:
	ld	a, (de)
	cpl
	and	(hl)
	ret	nz			; нажато то, чего в базе нет
	ld	a, (de)
	and	(hl)
	ld	(de), a
	inc	hl
	inc	de
	dec	b
	jp	nz, sat_w2
	jp	sat_w1
sat_t:	db	0			; «таймер»: затравка очередной точки шара
sat_c:	db	0			; перенос 6502 между шагами
sat_x:	db	0
sat_yy:	db	0
sat_h:	db	0
sat_t2:	db	0
sat_zp:	db	0
sat_asoft:
	incbin	"sat_asoft.bin"		; надписи загрузчика BBC (tools/convert/saturn.py)
	incbin	"sat_elite.bin"
	incbin	"sat_casft.bin"
sat_end:
	endif
