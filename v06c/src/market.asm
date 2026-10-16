; Рынок и груз: цены TT167, груз TT213, покупка TT219, продажа TT208, строка товара TT151, запасы GVL, ввод числа
; gnum, вопрос Y/N TT214, клавиша TT217, деньги LCASH, MCASH, GCASH, GC2, место в трюме tnpr.
; Перенесено близко к тексту BBC; сверка — v06c/test/t31.mjs и сценарий торговли в t32.mjs.

; TT163: заголовок таблицы цен. TT160–TT16a, TT152: единица товара по QQ19+1: «t», «kg» или «g», затем пробел.
TT163:
	ifndef	SCHED			; шапка таблицы — зелёным, как подписи
	ld	a, 0xFF
	ld	(txt_g), a
	call	TT163a
	xor	a
	ld	(txt_g), a
	ret
TT163a:
	endif
	ld	a, 17
	ld	(XC), a
	ld	a, 255
	jp	TT27
TT152:
	ld	a, (QQ19 + 1)
	and	96
	jp	z, tt160
	cp	32
	jp	z, tt161
	call	tt16a
	jp	TT162
tt160:
	ld	a, 't'
	call	TT26
	jp	TT162
tt161:
	ld	a, 'k'
	call	TT26
tt16a:
	ld	a, 'g'
	jp	TT26

; var: QQ19+3 = экономика системы QQ28 · (QQ19+1 & 31) — поправка цены и запаса. AVL+16 = 0.
var:
	ld	a, (QQ19 + 1)
	and	31
	ld	(QQ19 + 2), a
	ld	d, a
	xor	a
	ld	(AVL + 16), a
	ld	a, (QQ28)
	ld	c, a
	xor	a
tt153:
	dec	c
	jp	m, tt154
	adc	a, d
	jp	tt153
tt154:
	ld	(QQ19 + 3), a
	ret

; GVL: запасы товаров на рынке системы: случайное число QQ26 и AVL+0..16.
GVL:
	call	DORND
	ld	(QQ26), a
	xor	a
	ld	(XX4), a
hy9:
	ld	e, a			; товар · 4
	ld	d, 0
	ld	hl, QQ23 + 1
	add	hl, de
	ld	a, (hl)
	ld	(QQ19 + 1), a
	push	hl
	call	var
	pop	hl
	inc	hl
	ld	d, (hl)			; базовый запас
	inc	hl
	ld	a, (QQ26)
	and	(hl)
	add	a, d
	ld	d, a
	ld	hl, QQ19 + 3
	ld	a, (QQ19 + 1)
	or	a
	ld	a, d
	jp	m, tt157
	sub	(hl)
	jp	tt158
tt157:
	add	a, (hl)
tt158:
	or	a
	jp	p, tt159
	xor	a
tt159:
	and	0x3F
	ld	d, a
	ld	a, (XX4)
	ld	c, a
	ld	b, 0
	ld	hl, AVL
	add	hl, bc
	ld	(hl), d
	inc	a
	ld	(XX4), a
	add	a, a
	add	a, a
	cp	63
	jp	c, hy9
	ret

; TT151: строка товара A: название, единица, цена, запас (QQ25) или «-». Цена в QQ24.
TT151:
	ld	(QQ19 + 4), a
	ld	d, a
	add	a, a
	add	a, a
	ld	(QQ19), a
	ld	a, 1
	ld	(XC), a
	ld	a, d
	add	a, 208
	call	TT27
	ld	a, 14
	ld	(XC), a
	ld	a, (QQ19)
	ld	e, a
	ld	d, 0
	ld	hl, QQ23
	add	hl, de
	ld	d, (hl)			; базовая цена
	inc	hl
	ld	a, (hl)
	ld	(QQ19 + 1), a
	inc	hl
	inc	hl
	ld	a, (QQ26)
	and	(hl)
	add	a, d
	ld	(QQ24), a
	call	TT152
	call	var
	ld	hl, QQ19 + 3
	ld	a, (QQ19 + 1)
	inc	a			; проверка знака без изменения переноса (он идёт из var в сложение)
	dec	a
	ld	a, (QQ24)
	jp	m, tt155
	adc	a, (hl)
	jp	tt156
tt155:
	sub	(hl)
tt156:
	ld	(QQ24), a
	ld	(P_), a
	xor	a
	call	GC2
	scf
	call	pr5
	ld	a, (QQ19 + 4)
	ld	e, a
	ld	d, 0
	ld	hl, AVL
	add	hl, de
	ld	a, (hl)
	ld	(QQ25), a
	ld	b, a
	ld	c, e
	or	a
	jp	z, tt172
	ld	c, 0
	ld	a, 5
	call	TT11
	jp	TT152
tt172:
	ld	a, (XC)
	add	a, 4
	ld	(XC), a
	ld	a, '-'
	jp	TT27

; TT167: экран цен (f7).
TT167:
	ld	a, 16
	call	TT66
	ld	a, 5
	ld	(XC), a
	ld	a, 167
	call	NLIN3
	ld	a, 3
	ld	(YC), a
	call	TT163
	xor	a
	ld	(QQ29), a
tt168:
	ld	a, 0x80
	ld	(QQ17), a
	ld	a, (QQ29)
	call	TT151
	ld	hl, YC
	inc	(hl)
	ld	hl, QQ29
	inc	(hl)
	ld	a, (hl)
	cp	17
	jp	c, tt168
	ret

; TT213: экран груза (f9). TT208: экран продажи (f2): то же с вопросом по каждому товару.
TT208:
	ld	a, 4
	call	TT66
	ld	a, 4
	ld	(YC), a
	ld	(XC), a
	ld	a, 205
	call	TT27
	ld	a, 206
	call	TT68
	jp	TT210
TT213:
	ld	a, 8
	call	TT66
	ld	a, 11
	ld	(XC), a
	ld	a, 164
	call	TT60
	call	NLIN4
	call	fwl
	ld	a, (CRGO)
	cp	26
	jp	c, TT210
	ld	a, 107
	call	TT27
; TT210: список груза; на экране продажи (QQ11 = 4) — «Sell (Y/N)?» по каждому товару.
TT210:
	xor	a
tt211:
	ld	(QQ29), a
	ld	e, a
	ld	d, 0
	ld	hl, QQ20
	add	hl, de
	ld	a, (hl)
	or	a
	jp	z, tt212
	push	af
	ld	a, e
	add	a, a
	add	a, a
	ld	e, a
	ld	hl, QQ23 + 1
	add	hl, de
	ld	a, (hl)
	ld	(QQ19 + 1), a
	call	TT69
	ld	a, (QQ29)
	add	a, 208
	call	TT27
	ld	a, 14
	ld	(XC), a
	pop	af
	ld	b, a
	ifndef	SCHED
	ld	(QQ25), a		; сколько можно продать
	endif
	or	a
	call	pr2
	call	TT152
	ld	a, (QQ11)
	cp	4
	jp	nz, tt212
	ifdef	SCHED
	ld	a, 205
	call	TT214
	jp	nc, tt212
	else
	call	TT162			; как в дисковой версии: «Sell(Y/N)?» — Y всё, N ничего, либо число
	ld	a, 205
	call	TT27
	ld	a, 225
	call	TT27
	call	gnum
	jp	c, tt210_e
	or	a
	jp	z, tt212
	endif
	ld	a, 0xFF			; продать: цена — без печати
	ld	(QQ17), a
	ld	a, (QQ29)
	call	TT151
	ld	a, (QQ29)
	ld	e, a
	ld	d, 0
	ld	hl, QQ20
	add	hl, de
	ifdef	SCHED
	ld	a, (hl)
	ld	(P_), a
	ld	(hl), 0
	else
	ld	a, (R_)			; продаётся введённое количество
	ld	(P_), a
	ld	d, a
	ld	a, (hl)
	sub	d
	ld	(hl), a
	endif
	ld	a, (QQ24)
	ld	(Q), a
	call	GCASH
	call	MCASH
	xor	a
	ld	(QQ17), a
tt212:
	ld	a, (QQ29)
	inc	a
	cp	17
	jp	c, tt211
	ld	a, (QQ11)
	cp	4
	ret	nz
	call	dn2
BAY2:
	ld	a, K_F9
	jp	FRCE
	ifndef	SCHED
tt210_e:				; больше, чем есть: «Quantity?» и строка товара заново
	call	TT67
	ld	a, 176
	call	prq
	call	dn2
	ld	a, (QQ29)
	jp	tt211
	endif

; tnpr: поместится ли ещё A единиц товара QQ29? Перенос 1 — нет. A сохраняется.
; Товары 0–12 меряются тоннами (сумма против CRGO), остальные — штуками, до 200.
tnpr:
	ld	d, a
	ld	a, (M1ST)		; беженцы на борту: места в трюме нет
	add	a, a
	ld	a, d
	ret	c
	ld	a, (QQ29)
	cp	13
	jp	nc, tnpr_kg
	ld	hl, QQ20 + 12
	ld	b, 13
	ld	a, d
	scf				; на BBC сюда приходит перенос 1 от сравнения
tml:
	adc	a, (hl)
	dec	hl
	dec	b
	jp	nz, tml
	ld	hl, CRGO
	cp	(hl)
	ccf
	ld	a, d
	ret
tnpr_kg:
	ld	e, a
	ld	hl, QQ20
	ld	b, 0
	ld	c, e
	add	hl, bc
	ld	a, d
	add	a, (hl)
	cp	200
	ccf
	ld	a, d
	ret

; dn: напечатать остаток денег и пауза. dn2: гудок и пауза в секунду.
dn:
	call	TT162
	ld	a, 119
	call	spc
dn2:
	call	BEEP
	ld	c, 50
	jp	DELAY

; TT219: экран покупки (f1): по каждому товару — сколько купить.
TT219:
	ld	a, 1
	call	TT66
	call	TT163
	ld	a, 0x80
	ld	(QQ17), a
	xor	a
	ld	(QQ29), a
tt220:
	ld	a, (QQ29)
	call	TT151
	ld	a, (QQ25)
	or	a
	jp	nz, tt224
	jp	tt222
tq4:
	ld	c, 176			; «Quantity?»
tc_:
	call	TT162
	ld	a, c
	call	prq
	call	dn2
tt224:
	call	CLYNS
	ld	a, 204
	call	TT27
	ld	a, (QQ29)
	add	a, 208
	call	TT27
	ld	a, '/'
	call	TT27
	call	TT152
	ld	a, '?'
	call	TT27
	call	TT67
	call	gnum
	jp	c, tq4
	ld	(P_), a
	call	tnpr
	ld	c, 206			; «Cargo?»
	jp	c, tc_
	ld	a, (QQ24)
	ld	(Q), a
	call	GCASH
	call	LCASH
	ld	c, 197			; «Cash?»
	jp	nc, tc_
	ld	a, (QQ29)
	ld	e, a
	ld	d, 0
	ld	hl, QQ20
	add	hl, de
	ld	a, (R_)
	add	a, (hl)
	ld	(hl), a
	ld	hl, AVL
	add	hl, de
	ld	a, (R_)
	ld	d, a
	ld	a, (hl)
	sub	d
	ld	(hl), a
	ld	a, d
	or	a
	call	nz, dn
tt222:
	ld	a, (QQ29)
	add	a, 5
	ld	(YC), a
	xor	a
	ld	(XC), a
	ld	hl, QQ29
	inc	(hl)
	ld	a, (hl)
	cp	17
	jp	nc, BAY2
	jp	tt220

; gnum: ввести число до QQ25 (не больше двух-трёх цифр): A = R = число; перенос 1 — слишком много.
; Клавиша не цифра и не меньше «0» — выход на экран груза (BAY2).
gnum:
	xor	a
	ld	(R_), a
	ld	a, 12
	ld	(T1), a
tt223:
	call	TT217
	ifndef	SCHED			; как в дисковой версии: первым знаком Y — всё, что можно, N — ничего
	ld	e, a
	ld	a, (R_)
	or	a
	ld	a, e
	jp	nz, gn_dig
	cp	K_YES
	jp	z, gn_all
	cp	'n'
	jp	z, gn_none
gn_dig:
	endif
	ld	(Q), a
	sub	'0'
	jp	c, gn_out0		; знак меньше «0» (ввод окончен): перенос 6502 = 0
	cp	10
	jp	nc, BAY2
	ld	(S), a
	ld	e, a
	ld	a, (R_)
	cp	26
	jp	nc, gn_out1
	add	a, a
	ld	(T), a
	ld	d, a
	add	a, a
	add	a, a
	add	a, d
	add	a, e
	ld	(R_), a
	ld	hl, QQ25
	cp	(hl)
	jp	z, tt226
	jp	nc, gn_out1
tt226:
	push	af
	ld	a, (Q)
	call	TT26
	pop	af
	ld	hl, T1
	dec	(hl)
	jp	nz, tt223
	ccf				; после сравнения: равно — перенос 6502 = 1, меньше — 0
	ld	a, (R_)
	ret
gn_out0:
	ld	a, (R_)
	or	a
	ret
gn_out1:
	ld	a, (R_)
	scf
	ret
	ifndef	SCHED
gn_all:
	call	TT26
	ld	a, (QQ25)
	ld	(R_), a
	or	a
	ret
gn_none:
	call	TT26
	xor	a
	ld	(R_), a
	ret
	endif

; TT214: пробел, слово A, «(Y/N)?»: перенос 1 — ответ Y. TT221: без пробела.
TT214:
	push	af
	call	TT162
	pop	af
TT221:
	call	TT27
	ld	a, 225
	call	TT27
	call	TT217
	or	0x20
	cp	K_YES
	jp	z, tt218
	ld	a, 'n'			; в русском шрифте строчные d и n — это Д и Н
	jp	TT26
tt218:
	call	TT26
	scf
	ret

; TT217: дождаться, пока клавиши отпущены, затем нажатия: A = X = знак клавиши (как на BBC, буквы — строчные).
; Y сохраняется.
TT217:
	push	bc
tt217_t:
	ld	c, 2
	call	DELAY
	call	RDKEY
	jp	nz, tt217_t
tt217_t2:
	call	RDKEY
	jp	z, tt217_t2
	add	a, low kb_ascii
	ld	l, a
	ld	h, high kb_ascii
	ld	a, (hl)
	pop	bc
	ld	b, a
	ret

; LCASH: деньги -= (Y X); перенос 1 — хватило, иначе деньги не меняются, перенос 0. MCASH: деньги += (Y X).
LCASH:
	ld	a, b
	ld	(T1), a
	ld	hl, CASH + 3
	ld	a, (hl)
	sub	b
	ld	(hl), a
	ld	a, c
	ld	(T1), a
	dec	hl
	ld	a, (hl)
	sbc	a, c
	ld	(hl), a
	dec	hl
	ld	a, (hl)
	sbc	a, 0
	ld	(hl), a
	dec	hl
	ld	a, (hl)
	sbc	a, 0
	ld	(hl), a
	ccf
	ret	c
MCASH:
	ld	hl, CASH + 3
	ld	a, b
	add	a, (hl)
	ld	(hl), a
	dec	hl
	ld	a, c
	adc	a, (hl)
	ld	(hl), a
	dec	hl
	ld	a, (hl)
	adc	a, 0
	ld	(hl), a
	dec	hl
	ld	a, (hl)
	adc	a, 0
	ld	(hl), a
	or	a
	ret
; GCASH: (Y X) = P · Q · 4. GC2: (Y X) = (A P) · 4.
GCASH:
	call	MULTU
GC2:
	ld	h, a
	ld	a, (P_)
	ld	l, a
	add	hl, hl
	add	hl, hl
	ld	a, l
	ld	(P_), a
	ld	b, a
	ld	c, h
	ld	a, h
	ret
; prq: слово A и знак вопроса.
prq:
	call	TT27
	ld	a, '?'
	jp	TT27
