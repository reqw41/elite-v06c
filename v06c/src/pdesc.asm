; Расширенные описания планет — из дисковой версии BBC (в кассетной их нет): PDESC, DETOK, DETOK2, DTS, DASC
; с выравниванием строк по ширине, MT17, MT18. Эталон — код дисковой версии в tools/oracle/pdesc.js, сверка —
; v06c/test/pdesc.mjs (знаки, приходящие в TT26, равны знакам, приходящим в CHPR на BBC).
; Отличия от BBC: генератор случайных чисел после описания возвращается к прежнему значению (на диске BBC в нём
; остаются семена системы), — так ход игры остаётся как в кассетной версии. Слова основного словаря (название
; системы, имя командира) идут через TT27: пока включён буфер (pd_cap), TT26 отдаёт знаки сюда.
; Этим же кодом печатаются тексты миссий дисковой версии (discmis.asm). Словарь — v06c/data/tkn1.asm.
PD_LL		equ	30		; ширина строки описания
pd_buf		equ	ll_sh		; буфер выравнивания (на BBC — BUF): в описании не больше 140 знаков

; PDESC: описание системы с семенами QQ15, с текущей строки. Для текущей системы (QQ8 = 0) из таблицы pd_rupla —
; особое описание (часть — только пока идёт миссия 1 дисковой версии, прописными).
PDESC:
	ld	hl, (RAND)
	push	hl
	ld	hl, (RAND + 2)
	push	hl
	ld	a, 0xFF
	ld	(pd_w2), a
	ld	hl, (QQ8)
	ld	a, l
	or	h
	jp	nz, pd_pd1
	ld	a, (pd_zz)		; номер системы: TT111 оставила 256 - номер
	cpl
	inc	a
	ld	b, a
	ld	c, PD_NRU
	ld	hl, pd_rupla + PD_NRU - 1
pd_pdl1:
	ld	a, (hl)
	cp	b
	jp	nz, pd_pd2
	push	hl
	ld	de, PD_NRU
	add	hl, de
	ld	d, (hl)
	pop	hl
	ld	a, (GCNT)
	xor	d
	and	0x7F
	jp	nz, pd_pd2
	ld	a, d
	or	a
	ld	a, PD_OPEN
	jp	m, pd_pd3
	ld	a, (DTP)
	rra
	jp	nc, pd_pd1
	push	bc
	call	pd_mt14
	pop	bc
	ld	a, 1
pd_pd3:
	push	bc
	call	pd_byte
	pop	bc
	ld	a, c
	add	a, PD_RU - 1
	call	pd_tok
	ld	a, PD_CLOSE
	jp	pd_pd4
pd_pd2:
	dec	hl
	dec	c
	jp	nz, pd_pdl1
pd_pd1:
	ld	hl, (QQ15 + 2)
	ld	(RAND), hl
	ld	hl, (QQ15 + 4)
	ld	(RAND + 2), hl
	xor	a
pd_pd4:
	call	pd_tok
	pop	hl
	ld	(RAND + 2), hl
	pop	hl
	ld	(RAND), hl
	ret

; pd_tok (DETOK): напечатать слово номер A.
pd_tok:
	ld	hl, pd_tkn
pd_tok_hl:				; вход для второй таблицы: HL — её начало
	or	a
	jp	z, pd_t2
	ld	b, a
pd_t1:
	ld	a, (hl)
	inc	hl
	or	a
	jp	nz, pd_t1
	dec	b
	jp	nz, pd_t1
pd_t2:
	ld	a, (hl)
	or	a
	ret	z
	push	hl
	call	pd_byte
	pop	hl
	inc	hl
	jp	pd_t2

; pd_byte (DETOK2): байт слова — управляющий код, знак, случайное слово группы, слово или пара букв.
pd_byte:
	cp	32
	jp	c, pd_jump
	ifdef	RUS			; русский словарь (tkn1_ru.asm): свои границы — буквы до 95, пары — QQ16R
	cp	PD_G0
	jp	c, pd_dts
	cp	PD_W0
	jp	c, pd_rnd
	cp	PD_Q0
	jp	c, pd_rec
	cp	PD_P0
	jp	c, pd_pr3
	sub	PD_P0
	else
	cp	91
	jp	c, pd_dts
	cp	129
	jp	c, pd_rnd
	cp	215
	jp	c, pd_rec
	sub	215
	endif
	add	a, a
	ld	e, a
	ld	d, 0
	ld	hl, pd_tkn2
	add	hl, de
pd_pair:				; две буквы по адресу HL
	ld	a, (hl)
	push	hl
	call	pd_dts
	pop	hl
	inc	hl
	ld	a, (hl)
; pd_dts (DTS): знак A с учётом режима букв. В русской сборке — всё прописными: буква 64–94 — кириллица (+32),
; если не включена латиница; «_» включает и выключает латиницу.
pd_dts:
	ifdef	RUS
	cp	95
	jp	z, ru_lat
	cp	64
	jp	c, pd_dasc
	ld	c, a
	ld	a, (lat)
	or	a
	ld	a, c
	jp	nz, pd_dasc
	add	a, 32
	jp	pd_dasc
	endif
	cp	'A'
	jp	c, pd_dasc
	ld	c, a
	ld	a, (pd_w6)
	or	a
	jp	m, pd_d10		; всё строчными
	ld	a, (pd_w2)
	or	a
	jp	m, pd_d5		; начало слова — прописная
pd_d10:
	ld	a, (pd_w1)
	or	c
	ld	c, a
pd_d5:
	ld	a, (pd_w8)		; DFh — одна прописная
	and	c
; pd_dasc (DASC): знак A в буфер; 12 — напечатать буфер строками, выровненными по ширине.
pd_dasc:
	ld	c, a
	ld	a, 0xFF
	ld	(pd_w8), a
	ld	b, a
	ld	a, c
	cp	'.'
	jp	z, pd_da8
	cp	':'
	jp	z, pd_da8
	cp	10
	jp	z, pd_da8
	cp	12
	jp	z, pd_da8
	cp	' '
	jp	z, pd_da8
	inc	b
pd_da8:
	ld	a, b
	ld	(pd_w2), a		; FFh — не внутри слова
	ld	a, (pd_cap)
	or	a
	ld	a, c
	jp	z, TT26R		; буфера нет: знак сразу на экран
	cp	12
	jp	z, pd_flush
	ld	a, (pd_n)
	ld	e, a
	inc	a
	ld	(pd_n), a
	call	pd_ptr
	ld	(hl), c
	ret
pd_hook:				; знак из TT26: регистры сохраняются, перенос 0 — как у TT26
	push	bc
	push	de
	push	hl
	call	pd_dasc
	pop	hl
	pop	de
	pop	bc
	or	a
	ret
pd_ptr:					; HL = pd_buf + E
	ld	hl, pd_buf
	ld	a, l
	add	a, e
	ld	l, a
	ret	nc
	inc	h
	ret

	ifdef	RUS
pd_pr3:					; пара из второй таблицы (pd_tkn3, только русские описания и миссии)
	sub	PD_Q0
	add	a, a
	ld	e, a
	ld	d, 0
	ld	hl, pd_tkn3
	add	hl, de
	jp	pd_pair
	endif
pd_rec:
	ifdef	RUS
	sub	PD_W0
	else
	sub	129
	endif
	jp	pd_tok
pd_rnd:					; DT6: одно из пяти слов группы
	ifdef	RUS
	sub	PD_G0
	else
	sub	91
	endif
	ld	c, a
	add	a, a
	add	a, a
	add	a, c
	add	a, PD_NG
	push	af
	call	DORND2			; на BBC перенос на входе 0
	pop	bc			; B — первое слово группы
	ld	e, 4			; + сколько порогов 51, 102, 153, 204 не больше числа
pd_rn1:
	sub	51
	jp	c, pd_rn2
	inc	b
	dec	e
	jp	nz, pd_rn1
pd_rn2:
	ld	a, b
	jp	pd_tok

pd_jump:				; управляющий код A: процедура из таблицы, A — код
	cp	30
	jp	nc, pd_dasc
	ld	c, a
	add	a, a
	ld	e, a
	ld	d, 0
	ld	hl, pd_jt - 2
	add	hl, de
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a
	ld	a, c
	jp	(hl)
pd_mt19:				; следующая буква прописная
	ld	a, 0xDF
	ld	(pd_w8), a
	ret
pd_mt1:					; прописными
	xor	a
	ld	(pd_w1), a
	jp	pd_mt6
pd_mt29:				; строка 6, строчными
	ld	a, 6
	db	0x01			; LD BC, nn — пропустить следующую команду
pd_mt23:				; строка 10, строчными
	ld	a, 10
	ld	(YC), a
pd_mt13:				; строчными
	ld	a, 0x80
	db	0x01
pd_mt2:					; как в предложении
	ld	a, 0
	ld	(pd_w6), a
	ld	a, 0x20
	ld	(pd_w1), a
	ret
pd_mt6:
	ld	(pd_w6), a
	ret
pd_mt8:					; столбец 6, следующая буква прописная
	ld	a, 6
	ld	(XC), a
	ld	a, 0xFF
	ld	(pd_w2), a
	ret
pd_mt9:					; чистый экран
	ld	a, 1
	ld	(XC), a
pd_tt66:				; TT66 дисковой версии: очистка, «как в предложении», «не внутри слова»
	ld	a, 1
	call	TT66
	ld	a, 0x80
	ld	(pd_w2), a
	jp	pd_mt2
pd_mt14:				; выравнивание по ширине: знаки идут в буфер
	ld	a, 0x80
	db	0x01
pd_mt15:				; без выравнивания
	ld	a, 0
	ld	(pd_cap), a
	xor	a
	ld	(pd_n), a
	ret
pd_cmn:					; имя командира — как записано, прописными
	ld	hl, NA_
pd_cmn1:
	ld	a, (hl)
	cp	13
	ret	z
	push	hl
	call	pd_dasc
	pop	hl
	inc	hl
	jp	pd_cmn1
pd_mt27:				; имя капитана — по номеру галактики
	ld	a, PD_CAPT
	db	0x01
pd_mt28:				; где видели «Констриктор» — по номеру галактики
	ld	a, PD_M28
	ld	hl, GCNT
	add	a, (hl)
	jp	pd_tok

; pd_mt17 (MT17): название системы как прилагательное — без последней гласной, с «ian».
pd_mt17:
	ld	hl, QQ17
	ld	a, (hl)
	and	0xBF
	ld	(hl), a
	ld	a, 3
	call	TT27
	ld	a, (pd_n)
	ld	e, a
	call	pd_ptr
	dec	hl
	ld	a, (hl)
	or	0x20
	cp	'a'
	jp	z, pd_vow
	cp	'e'
	jp	z, pd_vow
	cp	'i'
	jp	z, pd_vow
	cp	'o'
	jp	z, pd_vow
	cp	'u'
	jp	nz, pd_m171
pd_vow:
	ld	hl, pd_n
	dec	(hl)
pd_m171:
	ld	a, PD_IAN
	jp	pd_tok

; pd_mt18 (MT18): случайное слово из 1–4 пар букв, с прописной. Перенос перед DORND — как на BBC: в первый
; раз 0, перед первой парой — от предыдущего DORND, дальше 0 (DASC кончается CLC).
pd_mt18:
	call	pd_mt19
	call	DORND2
	push	af
	and	3
	ld	c, a
	pop	af
pd_m18l:
	push	bc
	call	DORND
	and	62
	ld	e, a
	ld	d, 0
	ld	hl, pd_tkn2 + 2
	add	hl, de
	call	pd_pair
	pop	bc
	or	a
	dec	c
	jp	p, pd_m18l
	ret

; pd_flush (DA1): напечатать буфер. Пока в нём больше PD_LL знаков — в первые PD_LL знаков добавляются пробелы
; (справа налево, через один промежуток), пока строка не кончится на границе слова; затем строка печатается.
pd_flush:
	ld	a, (pd_n)
	or	a
	jp	z, pd_fin
	cp	PD_LL + 1
	jp	c, pd_da6
	ld	d, 0			; D — SC+1 на BBC: какой по счёту промежуток пропустить
pd_da11:
	ld	a, d
	or	a
	jp	m, pd_da11a
	ld	d, 0x40
pd_da11a:
	ld	e, PD_LL - 1
pd_dal1:
	ld	a, (pd_buf + PD_LL)
	cp	' '
	jp	z, pd_da2
pd_dal2:
	dec	e
	jp	m, pd_da11
	jp	z, pd_da11
	call	pd_ptr
	ld	a, (hl)
	cp	' '
	jp	nz, pd_dal2
	ld	a, d
	add	a, a
	ld	d, a
	jp	m, pd_dal2
	ld	a, (pd_n)		; вставить пробел: знаки с E-го по конец — на место правее
	sub	e
	inc	a
	ld	b, a
	push	de
	ld	a, (pd_n)
	ld	e, a
	call	pd_ptr
	pop	de
pd_dal6:
	ld	a, (hl)
	inc	hl
	ld	(hl), a
	dec	hl
	dec	hl
	dec	b
	jp	nz, pd_dal6
	ld	hl, pd_n
	inc	(hl)
pd_dal3:				; пропустить пробелы левее вставленного
	dec	e
	jp	m, pd_da11
	call	pd_ptr
	ld	a, (hl)
	cp	' '
	jp	nz, pd_dal1
	jp	pd_dal3
pd_da2:					; строка готова
	ld	b, PD_LL
	call	pd_das1
	ld	a, 12
	call	TT26R
	ld	a, (pd_n)
	sub	PD_LL + 1
	ld	(pd_n), a
	jp	z, pd_fin
	ld	b, a
	inc	b
	ld	hl, pd_buf + PD_LL + 1
	ld	de, pd_buf
	call	ll9_cp
	jp	pd_flush
pd_da6:					; последняя строка
	ld	b, a
	call	pd_das1
pd_fin:
	xor	a
	ld	(pd_n), a
	ld	a, 12
	jp	TT26R
pd_das1:				; B знаков буфера на экран
	ld	hl, pd_buf
pd_dal5:
	ld	a, (hl)
	call	TT26R
	inc	hl
	dec	b
	jp	nz, pd_dal5
	ret
