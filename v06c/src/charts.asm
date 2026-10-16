; Карты галактики и данные о системе: TT22, TT23, TT14, TT126, TT128, TT103, TT105, TT123, TT16, hm, TT114, TT25,
; TT146, TT60, TTX69, TT69. Перенесено близко к тексту BBC; сверка — v06c/test/t30.mjs.

; TT60: слово A, затем TTX69. TTX69: строка ниже, затем TT69. TT69: режим «Как в предложении», перевод строки.
TT60:
	call	TT27
TTX69:
	ld	hl, YC
	inc	(hl)
TT69:
	ld	a, 0x80
	ld	(QQ17), a
	jp	TT67

; TT146: «Distance: n.n Light Years» до выбранной системы (QQ8); при нуле — пустая строка.
TT146:
	ld	hl, (QQ8)
	ld	a, l
	or	h
	jp	nz, tt63
	ld	hl, YC
	inc	(hl)
	ret
tt63:
	ld	a, 191
	call	TT68
	ld	hl, (QQ8)
	ld	b, l
	ld	c, h
	scf
	call	pr5
	ld	a, 195
	ifdef	SCHED
	jp	TT60
	else
	call	TT27			; без пустой строки: экономика на той же строке, что и при нулевом расстоянии
	jp	TT69
	endif

; TT25: экран «Data on система» (f6).
TT25:
	ld	a, 1
	call	TT66
	ld	a, 9
	ld	(XC), a
	ld	a, 163
	call	TT27
	call	NLIN
	call	TTX69
	ifdef	SCHED			; в обычном образе экран на две строки плотнее кассетного: под ним описание
	ld	hl, YC			; планеты, до шести строк (эта пустая строка убрана и в дисковой версии BBC)
	inc	(hl)
	endif
	call	TT146
	ld	a, 194			; экономика
	call	TT68
	ld	a, (QQ3)
	inc	a
	or	a
	rra
	cp	2
	jp	z, tt70
	ld	a, (QQ3)
	jp	c, tt71
	sub	5
tt71:
	add	a, 170
	call	TT27
	jp	tt72
tt70:
	ld	a, 173
	call	TT27
tt72:
	ld	a, (QQ3)
	rrca
	rrca
	and	0x3F
	add	a, 168
	call	TT60
	ld	a, 162			; правление
	call	TT68
	ld	a, (QQ4)
	add	a, 177
	call	TT60
	ld	a, 196			; техника
	call	TT68
	ld	a, (QQ5)
	inc	a
	ld	b, a
	or	a
	call	pr2
	call	TTX69
	ld	a, 192			; население
	call	TT68
	ld	a, (QQ6)
	ld	b, a
	scf
	call	pr2
	ld	a, 198
	ifdef	SCHED
	call	TT60
	else
	call	TT27			; жители — строкой ниже населения, без пустой строки
	call	TT69
	endif
	ld	a, '('
	call	TT27
	ld	a, (QQ15 + 4)
	or	a
	jp	m, tt75
	ld	a, 188			; люди-колонисты
	call	TT27
	jp	tt76
tt75:
	ld	a, (QQ15 + 5)		; вид жителей: три прилагательных и существительное
	rrca
	rrca
	and	0x3F
	push	af
	and	7
	cp	3
	jp	nc, tt205
	add	a, 227
	call	spc
tt205:
	pop	af
	rrca
	rrca
	rrca
	and	0x1F
	cp	6
	jp	nc, tt206
	add	a, 230
	call	spc
tt206:
	ld	hl, QQ15 + 1
	ld	a, (QQ15 + 3)
	xor	(hl)
	and	7
	ld	(QQ19), a
	cp	6
	jp	nc, tt207
	add	a, 236
	call	spc
tt207:
	ld	hl, QQ19
	ld	a, (QQ15 + 5)
	and	3
	add	a, (hl)
	and	7
	add	a, 242
	call	TT27
tt76:
	ifndef	RUS			; по-русски раса уже во множественном числе
	ld	a, 'S'
	call	TT27
	endif
	ld	a, ')'
	call	TT60
	ld	a, 193			; производительность
	call	TT68
	ld	hl, (QQ7)
	ld	b, l
	ld	c, h
	call	pr6
	call	TT162
	xor	a
	ld	(QQ17), a
	ld	a, 'M'
	call	TT27
	ld	a, 226
	call	TT60
	ld	a, 250			; радиус
	call	TT68
	ld	a, (QQ15 + 3)
	ld	b, a
	ld	a, (QQ15 + 5)
	and	15
	add	a, 11
	ld	c, a
	call	pr5
	call	TT162
	ld	a, 'k'
	call	TT26
	ld	a, 'm'
	ifdef	SCHED
	jp	TT26			; образ стенда: экран как в кассетной версии
	else
	call	TT26			; расширенное описание — как в дисковой версии BBC
	call	TTX69
	jp	PDESC
	endif

; TT22: дальняя карта (f4): все 256 систем точками, круг дальности прыжка, перекрестие выбранной системы.
TT22:
	ld	a, 64
	call	TT66
	ld	a, 7
	ld	(XC), a
	call	TT81
	ld	a, 199
	call	TT27
	call	NLIN
	ld	a, 152
	call	NLIN2
	call	TT14
	xor	a
tt83:
	ld	(XSAV), a
	ld	hl, (QQ15 + 3)
	ld	b, l
	ld	a, h
	or	0x50
	ld	(ZZ), a
	ld	a, (QQ15 + 1)
	or	a
	rra
	add	a, 24
	ld	(XX15 + 1), a
	call	PIXEL
	call	TT20
	ld	a, (XSAV)
	inc	a
	jp	nz, tt83
	ld	a, (QQ9)
	ld	(QQ19), a
	ld	a, (QQ10)
	or	a
	rra
	ld	(QQ19 + 1), a
	ld	a, 4
	ld	(QQ19 + 2), a
	jp	TT15

; TT14: круг дальности прыжка вокруг нашей системы и её перекрестие — на дальней или ближней карте.
TT14:
	ld	a, (QQ11)
	or	a
	jp	m, tt126
	ld	a, (QQ14)
	rrca
	rrca
	and	0x3F
	ld	(K), a
	ld	a, (QQ0)
	ld	(QQ19), a
	ld	a, (QQ1)
	or	a
	rra
	ld	(QQ19 + 1), a
	ld	a, 7
	ld	(QQ19 + 2), a
	call	TT15
	ld	a, (QQ19 + 1)
	add	a, 24
	ld	(QQ19 + 1), a
TT128:
	ld	a, (QQ19)
	ld	l, a
	ld	h, 0
	ld	(K3), hl
	ld	a, (QQ19 + 1)
	ld	l, a
	ld	(K4), hl
	ld	a, 1
	ld	(LSP), a
	ld	a, 2
	ld	(STP), a
	jp	CIRCLE2
tt126:
	ld	a, 104
	ld	(QQ19), a
	ld	a, 90
	ld	(QQ19 + 1), a
	ld	a, 16
	ld	(QQ19 + 2), a
	call	TT15
	ld	a, (QQ14)
	ld	(K), a
	jp	TT128

; TT103: малое перекрестие выбранной системы на карте (на дальней — TT22-шкала, на ближней — TT105).
TT103:
	ld	a, (QQ11)
	or	a
	ret	z
	jp	m, TT105
	ld	a, (QQ9)
	ld	(QQ19), a
	ld	a, (QQ10)
	or	a
	rra
	ld	(QQ19 + 1), a
	ld	a, 4
	ld	(QQ19 + 2), a
	jp	TT15
TT105:
	ld	hl, QQ0
	ld	a, (QQ9)
	sub	(hl)
	cp	38
	jp	c, tt179
	cp	230
	ret	c
tt179:
	add	a, a
	add	a, a
	add	a, 104
	ld	(QQ19), a
	ld	hl, QQ1
	ld	a, (QQ10)
	sub	(hl)
	cp	38
	jp	c, tt105_y
	cp	220
	ret	c
tt105_y:
	add	a, a
	add	a, 90
	ld	(QQ19 + 1), a
	ld	a, 8
	ld	(QQ19 + 2), a
	jp	TT15

; TT123: QQ19+4 = A + QQ19+3 (сдвиг со знаком), если не вышли за 0..255; иначе QQ19+4 = A.
TT123:
	ld	(QQ19 + 4), a
	ld	hl, QQ19 + 3
	add	a, (hl)
	ld	d, a
	ld	a, 0
	rla
	ld	e, a			; E — перенос сложения
	ld	a, (hl)
	ld	b, a
	or	a
	ld	a, d
	jp	m, tt124
	dec	e			; сдвиг вправо или вниз: перенос — вышли за 255
	jp	nz, tt125
	scf
	ret
tt124:
	dec	e			; сдвиг влево или вверх: нет переноса — вышли за 0
	jp	z, tt125_c
	or	a
	ret
tt125:
	ld	(QQ19 + 4), a
	or	a
	ret
tt125_c:
	ld	(QQ19 + 4), a
	scf
	ret

; TT16: сдвинуть перекрестие на (X, Y) (−1, 0, 1 по каждой оси).
TT16:
	push	bc
	call	WSCAN
	call	TT103
	pop	bc
	push	bc
	ld	a, c
	dec	a
	cpl
	ld	(QQ19 + 3), a
	ld	a, (QQ10)
	call	TT123
	ld	a, (QQ19 + 4)
	ld	(QQ10), a
	ld	(QQ19 + 1), a
	pop	bc
	ld	a, b
	ld	(QQ19 + 3), a
	ld	a, (QQ9)
	call	TT123
	ld	a, (QQ19 + 4)
	ld	(QQ9), a
	ld	(QQ19), a
	jp	TT103

; hm: перевести перекрестие на ближайшую к нему систему (D на карте); затем очистить нижние строки.
hm:
	call	TT103
	call	TT111
	call	TT103
	ld	a, (QQ11)
	or	a
	ret	z
	jp	CLYNS

; TT114: карта по виду экрана: бит 7 в A — ближняя, иначе дальняя.
TT114:
	jp	m, TT23
	jp	TT22

; TT23: ближняя карта (f5): системы рядом с нами — звёздочкой (маленьким «солнцем») с названием.
TT23:
	ld	a, 128
	call	TT66
	ld	a, 7
	ld	(XC), a
	ld	a, 190
	call	NLIN3
	call	TT14
	call	TT103
	call	TT81
	xor	a
	ld	(XX20), a
	ld	hl, INWK		; какие строки заняты названиями
	ld	b, 25
tt23_z:
	ld	(hl), a
	inc	hl
	dec	b
	jp	nz, tt23_z
tt182:
	ld	hl, QQ0
	ld	a, (QQ15 + 3)
	sub	(hl)
	jp	nc, tt184
	cpl
	inc	a
tt184:
	cp	20
	jp	nc, tt187
	ld	hl, QQ1
	ld	a, (QQ15 + 1)
	sub	(hl)
	jp	nc, tt186
	cpl
	inc	a
tt186:
	cp	38
	jp	nc, tt187
	ld	hl, QQ0
	ld	a, (QQ15 + 3)
	sub	(hl)
	add	a, a
	add	a, a
	adc	a, 104
	ld	(XX12), a
	rrca
	rrca
	rrca
	and	0x1F
	inc	a
	ld	(XC), a
	ld	hl, QQ1
	ld	a, (QQ15 + 1)
	sub	(hl)
	add	a, a
	adc	a, 90
	ld	(K4), a
	or	a
	rra
	or	a
	rra
	or	a
	rra			; CY — бит 2: на BBC он идёт в радиус звезды, если название не печатается
	ld	c, a
	push	af
	ld	hl, INWK
	ld	b, 0
	add	hl, bc
	ld	a, (hl)
	or	a
	jp	z, ee4
	inc	hl
	inc	c
	ld	a, (hl)
	or	a
	jp	z, ee4
	dec	hl
	dec	hl
	dec	c
	dec	c
	ld	a, (hl)
	or	a
	jp	z, ee4
	pop	af
	jp	ee1
ee4:
	pop	af
	ld	a, c
	ld	(YC), a
	cp	3
	jp	c, tt187
	ld	(hl), 0xFF
	ld	a, 0x80
	ld	(QQ17), a
	call	cpl_
ee1:
	push	af			; перенос — в радиус
	xor	a
	ld	(K3 + 1), a
	ld	(K4 + 1), a
	ld	(K + 1), a
	ld	a, (XX12)
	ld	(K3), a
	pop	af
	ld	a, (QQ15 + 5)
	push	af
	and	1
	ld	d, a
	pop	af
	ld	a, d
	adc	a, 2
	ld	(K), a
	call	FLFLLS
	call	SUN
	call	FLFLLS
tt187:
	call	TT20
	ld	hl, XX20
	inc	(hl)
	ret	z
	jp	tt182
