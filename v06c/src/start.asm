; Запуск игры: TT170, BR1, QU5, TITLE, CHECK, RDKEY кассетной версии BBC. Сверка с эталоном — v06c/test/t18.mjs:
; от первой команды до заставок, проход за проходом.
NT		equ	75		; байт в данных командира

; TT170: начало игры. BR1: первая заставка с вопросом о загрузке командира.
TT170:
	ld	sp, STACK
BR1:
	ld	a, 3
	ld	(XC), a
	ld	b, 7			; Кобра Mk III
	ld	a, 128			; «Load New Commander (Y/N)?»
	call	TITLE
	; на BBC при ответе Y — ввод имени и загрузка с ленты (GTNME, LOD, TRNME); этап P6. Пока — как при N.
; QU5: взять командира по умолчанию, проверить контрольную сумму, вторая заставка.
QU5:
	ld	hl, NA_ + 8
	ld	de, TP
	ld	b, NT
qul1:
	ld	a, (hl)
	ld	(de), a
	inc	hl
	inc	de
	dec	b
	jp	nz, qul1
	xor	a
	ld	(QQ11), a
	call	CHECK
	ld	hl, CHK
	cp	(hl)
qu5_bad:
	jp	nz, qu5_bad		; сумма не сошлась — на BBC тоже вечный цикл
	xor	0xA9
	ld	hl, CHK2
	cp	(hl)
	ld	a, (COK)
	jp	z, qu5_tz
	or	0x80
qu5_tz:
	or	0x02
	ld	(COK), a
	call	msblob
	ld	a, 147			; «Press Fire Or Space,Commander.»
	ld	b, 3
	call	TITLE
	call	ping
	call	hyp1
	jp	BAY

; TITLE: заставка с вращающимся кораблём типа X и строкой A внизу; ждёт клавишу, возвращает её номер BBC.
TITLE:
	push	af
	ld	a, b
	ld	(TYPE), a
	call	RESET
	ld	a, 1
	call	TT66
	ld	hl, QQ11
	dec	(hl)
	ld	a, 96
	ld	(INWK + 14), a
	ld	(INWK + 7), a
	ld	a, 127
	ld	(INWK + 29), a
	ld	(INWK + 30), a
	ld	a, 128
	ld	(QQ17), a
	ld	a, (TYPE)
	call	NWSHP
	ld	a, 6
	ld	(XC), a
	ld	c, 6
	call	DELAY
	ld	a, 30			; «---- E L I T E ----»
	call	plf
	ld	a, 6
	ld	(XC), a
	ld	hl, YC
	inc	(hl)
	ld	a, (PATG)
	or	a
	jp	z, awe
	ld	a, 254			; авторы
	call	TT27
awe:
	call	CLYNS
	xor	a
	ld	(DELTA), a
	ld	(JSTK), a
	pop	af
	call	ex
	ld	a, 7
	ld	(XC), a
	ld	a, 148			; «(C) Acornsoft 1984»
	call	ex
TLL2:
	call	title_pass
	call	RDKEY
	jp	z, TLL2
	ret

; CHECK: контрольная сумма командира по умолчанию. A — сумма.
CHECK:
	ld	hl, NA_ + 7 + NT - 2
	ld	b, NT - 2
	ld	a, b
	ld	e, 0			; перенос 6502 между шагами (у i8080 XOR его сбрасывает)
chk_l:
	ld	d, a
	ld	a, e
	rra
	ld	a, d
	adc	a, (hl)
	ld	d, a
	sbc	a, a
	ld	e, a
	ld	a, d
	inc	hl
	xor	(hl)
	dec	hl
	dec	hl
	dec	b
	jp	nz, chk_l
	ret

; RDKEY: нажатая клавиша: A = X = внутренний номер клавиши BBC (16–127), Z и A = 0 — ничего не нажато.
; Матрица Вектора (kb_rows из прерывания кадра) переводится таблицей kb_bbc (v06c/data/keys.asm); из нескольких нажатых берётся
; клавиша с наименьшим номером BBC — как при опросе на BBC.
RDKEY:
	ld	hl, kb_rows
	ld	de, kb_bbc
	ld	c, 0			; лучшая: 0 — нет
	ld	b, 8
rk_row:
	push	bc
	ld	b, (hl)
	ld	c, 8
rk_bit:
	ld	a, b
	rrca
	ld	b, a
	jp	nc, rk_next
	ld	a, (de)
	or	a
	jp	z, rk_next
	ex	(sp), hl		; L — лучшая на стеке
	inc	l
	dec	l
	jp	z, rk_take
	cp	l
	jp	nc, rk_keep
rk_take:
	ld	l, a
rk_keep:
	ex	(sp), hl
rk_next:
	inc	de
	dec	c
	jp	nz, rk_bit
	pop	bc
	inc	hl
	dec	b
	jp	nz, rk_row
	ld	a, c
	ld	b, a
	or	a
	ret
