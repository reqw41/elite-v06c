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
	ifdef	SCHED
	ld	hl, kb_rows
	else
	ld	hl, fly_raw		; обычный образ: строки — в fly_raw, B — изменившиеся биты; kb_rows переводится
	ld	b, 0			; заново только при перемене (в конце обработчика)
	endif
	ld	c, 0xFE
isr_row:
	ld	a, c
	out	(3), a
	in	a, (2)
	cpl
	ifndef	SCHED
	ld	e, a
	xor	(hl)
	or	b
	ld	b, a
	ld	a, e
	endif
	ld	(hl), a
	inc	hl
	ld	a, c
	rlca
	ld	c, a
	jp	c, isr_row		; восемь строк: ноль выходит из бита 7 последним
	ifndef	SCHED
	ld	(hl), b			; kb_chg
	inc	hl
	endif
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
	ifdef	SCHED
	call	nz, joy_keys
	else
	ld	hl, joy_bits		; применяется в конце, после перевода клавиш полёта (fly_keys); перемена — в kb_chg
	ld	b, a
	xor	(hl)
	ld	(hl), b
	ld	hl, kb_chg
	or	(hl)
	ld	(hl), a
	endif
	ld	a, 0x88			; все порты на выход
	out	(0), a
	ifdef	SCHED
	ld	a, 0xFF
	else
	ld	a, (flash_cnt)		; встряска: пока идёт вспышка (попадание по нам, бомба), экран через кадр
	and	1			; сдвигается на две строки аппаратной прокруткой
	add	a, a
	cpl
	endif
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
	ld	hl, pal_flight
	call	pal_set
isr_nf:
	ifndef	SCHED
	ld	a, (v_frames)		; тревога: в полёте при энергии ниже четверти зелёное на панели раз в
	and	0x1F			; 32 кадра становится жёлтым и обратно
	jp	nz, isr_na
	ld	a, (flash_cnt)	; не во время вспышки и не при включённом скрывающем устройстве (своя палитра)
	ld	hl, cloak_on
	or	(hl)
	jp	nz, isr_na
	ld	hl, pal_flight
	ld	a, (QQ12)
	or	a
	jp	nz, isr_ps
	ld	a, (ENERGY)
	cp	64
	jp	nc, isr_ps
	ld	a, (v_frames)
	and	0x20
	jp	z, isr_ps
	ld	hl, pal_alert
isr_ps:
	call	pal_set
isr_na:
	endif
	ld	a, (pal_dirty)
	or	a
	jp	z, isr_cnt
	xor	a
	ld	(pal_dirty), a
	call	pal_write
isr_cnt:
	ifndef	SCHED
	call	mus_tick		; мелодия заставки
	endif
	call	snd_tick		; звук ВИ53
	ld	hl, (v_frames)
	inc	hl
	ld	(v_frames), hl
	ifndef	SCHED
	; всё, что обработчик кадра BBC делает с состоянием игры (в сборке SCHED это делает стенд на границе прохода)
	ld	a, (fly_on)		; полёт (главный цикл в полёте, не пауза) — клавиши под русскую клавиатуру
	or	a
	jp	z, isr_md
	ld	a, (QQ11)
	cp	1
	sbc	a, a			; FFh — вид из корабля
isr_md:
	ld	hl, kb_md		; kb_rows пересчитывается, только если сменились матрица, джойстик или режим
	ld	b, a
	xor	(hl)
	ld	(hl), b
	ld	hl, kb_chg
	or	(hl)
	jp	z, isr_nk
	ld	(hl), 0
	ld	hl, fly_raw
	ld	de, kb_rows
	call	fk_cp
	ld	a, (kb_md)
	or	a
	call	nz, fly_keys
	ld	a, (joy_bits)
	or	a
	call	nz, joy_keys
isr_nk:
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

	ifdef	SCHED			; в игре не вызывается — только из тестов (образ стенда)
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
	endif

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

	ifndef	SCHED
; fly_keys: полёт под русскую клавиатуру Вектора (обычный образ). Таблицы — v06c/data/keys.asm (tools/convert/keys.py):
; клавиши из fly_map нажимают другие (стрелки — крен и тангаж, пробел — огонь, Я, ТАБ — разгон, тормоз, Б — бомба,
; К — капсула, А, О — автопилот, Ц, Р, С — ракета, П, Г — прыжки, М — маскировка), всё, чего нет в fly_keep, гаснет.
; На входе kb_rows и fly_raw — матрица с клавиатуры; нажатия берутся из fly_raw: замены не цепляются друг за друга.
; Зовётся из прерывания кадра только при перемене матрицы (isr_kb), поэтому своей памяти о прошлом переводе нет.
fly_keys:
	ld	hl, kb_rows		; строка И fly_keep
	ld	de, fly_keep
fk_k:
	ld	a, (de)
	and	(hl)
	ld	(hl), a
	inc	hl
	inc	de
	ld	a, l
	cp	low (kb_rows + 8)
	jp	nz, fk_k
	ld	de, fly_map
	ld	b, FLY_N
fk_l:
	ld	a, (de)			; откуда: нажата ли клавиша Вектора (в fly_raw — матрица до перевода)
	inc	de
	call	fk_bit
	ld	a, l
	add	a, low (fly_raw - kb_rows)
	ld	l, a
	ld	a, (hl)
	and	c
	jp	z, fk_n
	ld	a, (de)			; куда: её бит — в kb_rows
	call	fk_bit
	ld	a, c
	or	(hl)
	ld	(hl), a
fk_n:
	inc	de
	dec	b
	jp	nz, fk_l
	ret
fk_cp:					; 8 байт из HL в DE
	ld	b, 8
fk_c:
	ld	a, (hl)
	ld	(de), a
	inc	hl
	inc	de
	dec	b
	jp	nz, fk_c
	ret
; fk_bit — в нижней памяти (fk_bit.asm, elite.asm).
	assert	high TWOS == high (TWOS + 7)
	endif

; Смена цвета всего экрана на несколько кадров, как на ZX Spectrum (там — атрибут окна обзора):
; flash — взрыв энергетической бомбы: фон жёлтый; tint_hit — по нам попали: белое становится красным.
; Палитра возвращается к обычной в прерывании кадра, когда счётчик flash_cnt дойдёт до нуля.
flash:
	ld	hl, pal_bomb
	ld	a, 2
	jp	pal_fx
tint_hit:				; сохраняет все регистры и флаги: зовётся из OOPS
	push	af
	push	bc
	push	de
	push	hl
	ld	hl, pal_hit
	ld	a, 4
	call	pal_fx
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret
pal_fx:
	ld	(flash_cnt), a
	jp	pal_set
; Цвета (байт BBGGGRRR, решение владельца 17.10.2026): бордовый, тёмно-зелёный как в терминалах, светло-бежевый.
	ifdef	RUS
K_YES		equ	'd'		; «да» — Д (клавиша D Вектора; Д/Н — как на клавиатуре)
	else
K_YES		equ	'y'
	endif
C_RED		equ	0x04
C_GREEN		equ	0x28
C_WHITE		equ	0xB7
pal_bomb:
	db	0x3F, C_RED, C_WHITE, C_GREEN
pal_hit:
	db	0x00, C_RED, C_RED, C_GREEN
pal_alert:
	db	0x00, C_RED, C_WHITE, 0x3F	; тревога: зелёное — жёлтым
flash_cnt:
	db	0
sat_skip:
	db	0			; <> 0 — не показывать заставку с Сатурном (ставит стенд тестов)

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
	db	0x00, C_RED, 0x3F, C_GREEN	; чёрный, красный, жёлтый (обзор и рамки панели), зелёный — цвета панели BBC
	else
	db	0x00, C_RED, C_WHITE, C_GREEN	; чёрный, красный, белый (обзор и рамки панели), зелёный
	endif

	ifdef	SCHED
	include	"init_cls.asm"
	endif
