; Слой Вектора: прерывание кадра, клавиатура, палитра, очистка.

; Прерывание кадра (RST 7, 50 Гц). Клавиатура и палитра — сразу, пока луч в гашении кадра: порт B ВВ55 на время
; опроса стоит на вводе, машина видит на нём FFh (бордюр, режим 512) — позже гашения это попало бы в кадр.
isr:
	push	af
	push	bc
	push	de
	push	hl
	ld	a, 0x8A			; порт A — выход (выбор строки), порт B и старшая половина C — вход
	out	(0), a
	ld	hl, kb_rows
	ld	c, 0xFE
isr_row:
	ld	a, c
	out	(3), a
	in	a, (2)
	cpl
	ld	(hl), a
	inc	hl
	ld	a, c
	rlca
	ld	c, a
	jp	c, isr_row		; восемь строк: ноль выходит из бита 7 последним
	in	a, (1)
	cpl
	and	0xE0
	ld	(hl), a			; kb_mod
	ld	a, 0x88			; все порты на выход
	out	(0), a
	ld	a, 0xFF
	out	(3), a			; прокрутка FFh: верхняя строка экрана — младший байт адреса FFh
	xor	a
	out	(2), a			; бордюр — цвет 0
	out	(1), a
	ld	a, (pal_dirty)
	or	a
	jp	z, isr_cnt
	xor	a
	ld	(pal_dirty), a
	call	pal_write
isr_cnt:
	ld	hl, (v_frames)
	inc	hl
	ld	(v_frames), hl
	ifndef	SCHED
	; всё, что обработчик кадра BBC делает с состоянием игры (в сборке SCHED это делает стенд на границе прохода)
	ld	a, 30
	ld	(DL), a
	ld	hl, LASCT
	ld	a, (hl)
	or	a
	jp	z, isr_end
	dec	(hl)
isr_end:
	endif
	pop	hl
	pop	de
	pop	bc
	pop	af
	ei
	ret

; Ждать следующего кадра.
wait_frame:
	ld	hl, v_frames
	ld	a, (hl)
wf_lp:
	cp	(hl)
	jp	z, wf_lp
	ret

; Клавиша нажата? A = строка·8 + бит матрицы. Выход: NZ — нажата. Портит BC, DE, HL.
kb_test:
	ld	c, a
	rrca
	rrca
	rrca
	and	7
	ld	e, a
	ld	d, 0
	ld	hl, kb_rows
	add	hl, de
	ld	a, c
	and	7
	ld	b, a
	ld	a, 1
	inc	b
kt_sh:
	dec	b
	jp	z, kt_ok
	add	a, a
	jp	kt_sh
kt_ok:
	and	(hl)
	ret

; Палитра из четырёх цветов: HL -> 4 байта (цвета 0..3, формат порта 0Ch: BBGGGRRR).
; Номер регистра = биты плоскостей 8000h, A000h, C000h, E000h; в двух старших лежит программа, поэтому
; регистр i получает цвет i & 3. Запись — в ближайшем прерывании кадра.
pal_set:
	ex	de, hl			; DE -> 4 цвета
	ld	hl, pal_regs
	ld	b, 4
ps_grp:
	push	de
	ld	c, 4
ps_one:
	ld	a, (de)
	ld	(hl), a
	inc	de
	inc	hl
	dec	c
	jp	nz, ps_one
	pop	de
	dec	b
	jp	nz, ps_grp
	ld	a, 1
	ld	(pal_dirty), a
	ret

; Запись 16 регистров палитры. Регистр выбирается цветом под лучом; в гашении это номер бордюра (порт 02h).
pal_write:
	ld	b, 15			; от 15 к 0: вторая запись в порт 0Ch доходит уже при следующем номере,
	ld	hl, pal_regs + 15	; при обходе вниз последним остаётся верный цвет номера 0
pw_lp:
	ld	a, b
	out	(2), a
	ld	a, (hl)
	out	(0x0C), a
	out	(0x0C), a
	dec	hl
	dec	b
	jp	p, pw_lp
	xor	a
	out	(2), a
	ret

pal_flight:
	ifdef	VIEW_YELLOW
	db	0x00, 0x07, 0x3F, 0x38	; чёрный, красный, жёлтый (обзор и рамки панели), зелёный — цвета панели BBC
	else
	db	0x00, 0x07, 0xFF, 0x38	; чёрный, красный, белый (обзор и рамки панели), зелёный
	endif

; Очистить обе плоскости целиком.
cls_all:
	ld	hl, SCR_VIEW
ca_lp:
	ld	(hl), 0
	inc	hl
	ld	a, h
	or	l
	jp	nz, ca_lp
	ret
