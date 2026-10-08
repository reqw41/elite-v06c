; Расширенные описания планет — из дисковой версии BBC (в кассетной их нет): PDESC, DETOK, DETOK2, DTS, DASC
; с выравниванием строк по ширине, MT17, MT18. Эталон — код дисковой версии в tools/oracle/pdesc.js, сверка —
; v06c/test/pdesc.mjs (знаки, приходящие в TT26, равны знакам, приходящим в CHPR на BBC).
; Отличия от BBC: генератор случайных чисел после описания возвращается к прежнему значению (на диске BBC в нём
; остаются семена системы), — так ход игры остаётся как в кассетной версии; особых описаний (RUPLA) нет;
; название системы печатается своим кодом, QQ17 не меняется. Словарь — v06c/data/tkn1.asm.
PD_LL		equ	30		; ширина строки описания
pd_buf		equ	ll_sh		; буфер выравнивания (на BBC — BUF): в описании не больше 140 знаков

; PDESC: описание системы с семенами QQ15, с текущей строки.
PDESC:
	ld	hl, (RAND)
	push	hl
	ld	hl, (RAND + 2)
	push	hl
	ld	hl, (QQ15 + 2)
	ld	(RAND), hl
	ld	hl, (QQ15 + 4)
	ld	(RAND + 2), hl
	ld	a, 0xFF
	ld	(pd_w2), a
	xor	a
	call	pd_tok
	pop	hl
	ld	(RAND + 2), hl
	pop	hl
	ld	(RAND), hl
	ret

; pd_tok (DETOK): напечатать слово номер A.
pd_tok:
	ld	hl, pd_tkn
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
	cp	91
	jp	c, pd_dts
	cp	129
	jp	c, pd_rnd
	cp	215
	jp	c, pd_rec
	sub	215
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
; pd_dts (DTS): знак A с учётом режима букв.
pd_dts:
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
	ld	a, c
	or	0x20
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
	ld	a, c
	cp	12
	jp	z, pd_flush
	ld	a, (pd_n)
	ld	e, a
	inc	a
	ld	(pd_n), a
	call	pd_ptr
	ld	(hl), c
	ret
pd_ptr:					; HL = pd_buf + E
	ld	hl, pd_buf
	ld	a, l
	add	a, e
	ld	l, a
	ret	nc
	inc	h
	ret

pd_rec:
	sub	129
	jp	pd_tok
pd_rnd:					; DT6: одно из пяти слов группы
	sub	91
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

pd_jump:
	cp	12
	jp	z, pd_dasc
	cp	2
	jp	z, pd_mt2
	cp	3
	jp	z, pd_name
	cp	13
	jp	z, pd_mt13
	cp	14
	jp	z, pd_mt14
	cp	15
	ret	z			; MT15: буфер уже пуст
	cp	17
	jp	z, pd_mt17
	cp	18
	jp	z, pd_mt18
pd_mt19:				; следующая буква прописная
	ld	a, 0xDF
	ld	(pd_w8), a
	ret
pd_mt2:					; как в предложении
	xor	a
	jp	pd_mt6
pd_mt13:				; строчными
	ld	a, 0x80
pd_mt6:
	ld	(pd_w6), a
	ret
pd_mt14:				; начать буфер
	xor	a
	ld	(pd_n), a
	ret

; pd_mt17 (MT17): название системы как прилагательное — без последней гласной, с «ian».
pd_mt17:
	call	pd_name
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

; pd_name: название системы QQ15 (как cpl): первая буква прописная, остальные строчные.
pd_name:
	ld	hl, QQ15
	ld	de, QQ19
	call	ll9_cp6
	ld	a, (QQ15)
	and	0x40
	ld	a, 3
	jp	nz, pd_nm1
	dec	a
pd_nm1:
	ld	(T), a
	xor	a
	ld	(pd_lc), a
pd_nm2:
	ld	a, (QQ15 + 5)
	and	0x1F
	jp	z, pd_nm3
	add	a, a
	ld	e, a
	ld	d, 0
	ld	hl, QQ16
	add	hl, de
	call	pd_nml
	inc	hl
	call	pd_nml
pd_nm3:
	call	TT54
	ld	hl, T
	dec	(hl)
	jp	p, pd_nm2
	ld	hl, QQ19
	ld	de, QQ15
	jp	ll9_cp6
pd_nml:
	ld	a, (hl)
	cp	'?'
	ret	z
	push	hl
	ld	hl, pd_lc
	or	(hl)
	ld	(hl), 0x20
	call	pd_dasc
	pop	hl
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
	call	TT26
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
	jp	TT26
pd_das1:				; B знаков буфера на экран
	ld	hl, pd_buf
pd_dal5:
	ld	a, (hl)
	call	TT26
	inc	hl
	dec	b
	jp	nz, pd_dal5
	ret
