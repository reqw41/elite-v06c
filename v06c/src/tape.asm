; Магнитофон: запись и чтение файла командира. Выход — бит 0 порта 01h, вход — бит 4 порта 01h.
; Код двухфазный, как в мониторах РК-86 и Вектора: в середине каждого бита — перепад, вторая половина бита
; равна самому биту; старший бит первым; 1200 бит/с (полбита — 1250 тактов).
; Блок: пилот — 768 нулевых байт (5 с, чтобы успеть включить запись), синхробайт E6h, «EL», данные, сумма
; данных по модулю 256, нулевой байт. Чтение понимает и перевёрнутую полярность (синхробайт читается как 19h).
; Прерывания на время работы закрыты, звук заглушён. Ожидание сигнала при чтении прерывается пробелом или СС. Сверка — v06c/test/tape.mjs (запись → чтение, порча, инверсия).

TP_HALF	equ	60			; кругов по 20 тактов в полубите
TP_EDGE	equ	80			; ожидание перепада: кругов по 68 тактов — около двух битов
TP_TRY	equ	8000			; битов на поиск синхробайта: 13 с тишины или 6,6 с сигнала

; tp_save: записать B байт с адреса HL.
tp_save:
	di
	call	tp_quiet
	push	hl
	push	bc
	ld	bc, 768
tps_p:
	xor	a
	call	tp_wbyte
	dec	bc
	ld	a, b
	or	c
	jp	nz, tps_p
	ld	a, 0xE6
	call	tp_wbyte
	ld	a, 'E'
	call	tp_wbyte
	ld	a, 'L'
	call	tp_wbyte
	pop	bc
	pop	hl
	ld	c, 0
tps_d:
	ld	a, (hl)
	add	a, c
	ld	c, a
	ld	a, (hl)
	call	tp_wbyte
	inc	hl
	dec	b
	jp	nz, tps_d
	ld	a, c
	call	tp_wbyte
	xor	a
	call	tp_wbyte
	xor	a
	out	(1), a
	ei
	ret
tp_wbyte:				; байт A на ленту. Сохраняет BC, HL
	ld	d, a
	ld	e, 8
tw_l:
	ld	a, d
	rlca
	ld	d, a
	ld	a, 0
	adc	a, 0
	xor	1			; первая половина — обратный бит
	out	(1), a
	call	tp_half
	xor	1
	out	(1), a
	call	tp_half
	dec	e
	jp	nz, tw_l
	ret
tp_half:
	push	bc
	ld	b, TP_HALF
th_l:
	dec	b
	jp	nz, th_l
	pop	bc
	ret

; tp_load: прочитать B байт по адресу HL. Перенос 1 — не прочитано (нет сигнала, не тот блок, сумма не сошлась).
tp_load:
	di
	call	tp_quiet
	push	hl
	push	bc
	xor	a
	ld	(tp_inv), a
	ld	e, a
	ld	bc, TP_TRY
tpl_s:
	call	tp_rbit
	ld	a, e
	rla
	ld	e, a
	cp	0xE6
	jp	z, tpl_ok
	cp	0x19
	jp	z, tpl_inv
	ld	a, c			; раз в 32 бита (37 раз в секунду) — не нажат ли пробел или СС: прервать ожидание
	and	0x1F
	jp	nz, tpl_n
	call	tp_key
	jp	nz, tpl_fail
tpl_n:
	dec	bc
	ld	a, b
	or	c
	jp	nz, tpl_s
	jp	tpl_fail
tpl_inv:
	ld	a, 0xFF
	ld	(tp_inv), a
tpl_ok:
	call	tp_rbyte
	cp	'E'
	jp	nz, tpl_fail
	call	tp_rbyte
	cp	'L'
	jp	nz, tpl_fail
	pop	bc
	pop	hl
	ld	c, 0
tpl_d:
	call	tp_rbyte
	ld	(hl), a
	add	a, c
	ld	c, a
	inc	hl
	dec	b
	jp	nz, tpl_d
	call	tp_rbyte
	cp	c
	jp	nz, tpl_bad
	or	a
	ei
	ret
tpl_fail:
	pop	bc
	pop	hl
tpl_bad:
	scf
	ei
	ret
tp_rbyte:				; байт с ленты в A. Сохраняет BC, HL
	push	bc
	ld	b, 8
trb_l:
	call	tp_rbit
	ld	a, e
	rla
	ld	e, a
	dec	b
	jp	nz, trb_l
	pop	bc
	ld	a, (tp_inv)
	xor	e
	ret
tp_rbit:				; ждать перепада в середине бита: перенос = бит (уровень после перепада). Тишина — 0
	push	hl
	in	a, (1)			; уровень сейчас (после возможного перепада на границе битов)
	and	0x10
	ld	d, a
	ld	hl, TP_EDGE
tr_w:
	in	a, (1)
	and	0x10
	cp	d
	jp	nz, tr_got
	dec	hl
	ld	a, h
	or	l
	jp	nz, tr_w
	pop	hl
	or	a
	ret
tr_got:
	ld	d, a
	pop	hl
	push	bc			; три четверти бита — мимо перепада на границе битов
	ld	b, 80
tr_d:
	dec	b
	jp	nz, tr_d
	pop	bc
	ld	a, d
	add	a, 0xF0
	ret
; tp_key: NZ — нажат пробел или СС. Прерывания закрыты, клавиатуру читаем сами: порт B на ввод, строка 7
; (пробел — бит 7), затем порты обратно на вывод, как это делает обработчик кадра. СС читается с порта C без
; переключения. Пока порт B на вводе (несколько десятков тактов), бордюр и режим экрана не наши — на экране
; возможна короткая чёрточка.
tp_key:
	ld	a, 0x8A
	out	(0), a
	ld	a, 0x7F
	out	(3), a
	in	a, (2)
	cpl
	and	0x80
	ld	d, a
	in	a, (1)
	cpl
	and	0x20
	or	d
	ld	d, a
	ld	a, 0x88
	out	(0), a
	ld	a, 0xFF
	out	(3), a
	xor	a
	out	(2), a
	out	(1), a
	ld	a, d
	or	a
	ret
tp_quiet:				; остановить счётчики ВИ53: при закрытых прерываниях звук иначе тянулся бы
	ld	a, 0x36
	out	(0x08), a
	ld	a, 0x76
	out	(0x08), a
	ld	a, 0xB6
	out	(0x08), a
	ret
	ifdef	SCHED			; в обычном образе — в рабочих областях (elite.asm, WS + 03CEh)
tp_inv:	db	0
	endif
