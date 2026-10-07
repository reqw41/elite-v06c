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
	in	a, (0x06)		; джойстик П (порт ПУ) и джойстик порта 0Eh: нажатое — биты, отличные от покоя
	ld	hl, joy_rest
	xor	(hl)
	ld	b, a
	in	a, (0x0E)
	inc	hl
	xor	(hl)
	or	b
	and	0xCF
	call	nz, joy_keys
	ld	a, 0x88			; все порты на выход
	out	(0), a
	ld	a, 0xFF
	out	(3), a			; прокрутка FFh: верхняя строка экрана — младший байт адреса FFh
	xor	a
	out	(2), a			; бордюр — цвет 0
	out	(1), a
	ld	hl, flash_cnt		; вспышка кончилась — фон снова чёрный
	ld	a, (hl)
	or	a
	jp	z, isr_nf
	dec	(hl)
	jp	nz, isr_nf
	xor	a
	call	pal_bg
isr_nf:
	ld	a, (pal_dirty)
	or	a
	jp	z, isr_cnt
	xor	a
	ld	(pal_dirty), a
	call	pal_write
isr_cnt:
	call	snd_tick		; звук ВИ53
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

; WSCAN: ждать начала следующего кадра (на BBC — по флагу DL, который ставит обработчик кадра).
; В сборке SCHED кадры считает стенд: возврат сразу, DL = 30 — как в эталоне по расписанию.
WSCAN:
	ifdef	SCHED
	ld	a, 30
	ld	(DL), a
	ret
	else
	xor	a
	ld	(DL), a
ws_lp:
	ld	a, (DL)
	or	a
	jp	z, ws_lp
	ret
	endif
; DEL8: ждать 8 кадров. DELAY: ждать Y кадров (Y — регистр C).
DEL8:
	ld	c, 8
DELAY:
	call	WSCAN
	dec	c
	jp	nz, DELAY
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

; Джойстик. «Джойстик П» — на разъёме ПУ: порт 06h после настройки (83h в порт 04h, 9Fh в порт 05h); джойстик
; порта 0Eh (ядро MiSTer) — та же раскладка: бит 0 вправо, 1 влево, 2 вверх, 3 вниз, 6 огонь, 7 вторая кнопка.
; Нажатое — биты, отличные от состояния покоя, снятого при запуске (joy_init), так что полярность не важна.
; joy_keys: нажатия джойстика становятся нажатиями клавиш в kb_rows: в полёте (QQ11 = 0) — крен, тангаж, лазер
; и разгон, на остальных экранах — стрелки, пробел и ВК. Игра о джойстике не знает.
joy_init:
	ld	a, 0x83
	out	(0x04), a
	ld	a, 0x9F
	out	(0x05), a
	in	a, (0x06)
	ld	(joy_rest), a
	in	a, (0x0E)
	ld	(joy_rest + 1), a
	ret
joy_keys:
	ld	c, a
	ld	hl, joy_fly
	ld	a, (QQ11)
	or	a
	jp	z, jk_tab
	ld	hl, joy_scr
jk_tab:
	ld	b, 6
jk_l:
	ld	a, (hl)
	inc	hl
	and	c
	jp	z, jk_n
	ld	e, (hl)
	inc	hl
	ld	a, (hl)
	push	hl
	ld	d, 0
	ld	hl, kb_rows
	add	hl, de
	or	(hl)
	ld	(hl), a
	pop	hl
	inc	hl
	jp	jk_c
jk_n:
	inc	hl
	inc	hl
jk_c:
	dec	b
	jp	nz, jk_l
	ret
joy_rest:
	db	0, 0

; flash: вспышка энергетической бомбы — фон обзора и панели на два кадра жёлтый (на BBC — запись в палитру
; до следующего кадра). pal_bg: цвет фона A — в регистры палитры с номером цвета 0.
flash:
	ld	a, 2
	ld	(flash_cnt), a
	ld	a, 0x3F
pal_bg:
	ld	(pal_regs), a
	ld	(pal_regs + 4), a
	ld	(pal_regs + 8), a
	ld	(pal_regs + 12), a
	ld	a, 1
	ld	(pal_dirty), a
	ret
flash_cnt:
	db	0

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
