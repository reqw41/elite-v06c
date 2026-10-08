; Оборудование (f3): EQSHP, eq, prx, qv и таблица цен PRXS. Перенесено близко к тексту BBC;
; сверка — сценарий equip: sh v06c/build.sh -DSCHED && node v06c/test/t27.mjs equip

POW	equ	15

; EQSHP: экран покупки оборудования. Номер предмета на BBC живёт в A; вызовы qv/prx/MCASH/prq/spc/TT27
; его портят, и в каждом блоке et* номер известен наперёд (сравнивается с константой) — поэтому
; после каждого порчи A грузим константу блока, как в исходнике BBC (LDA #4 / LDA #5).
; Метки pres/et0..et9/err/qv* — внутренние; dn, dn2 — из market.asm, BAY — из mainloop.asm.
EQSHP:
	call	DIALS
	ld	a, 32
	call	TT66
	ld	a, 12
	ld	(XC), a
	ld	a, 207
	call	spc
	ld	a, 185
	call	NLIN3
	ld	a, 0x80
	ld	(QQ17), a
	ld	hl, YC
	inc	(hl)
	ld	a, (tek)
	or	a				; CLC
	adc	a, 3
	cp	14				; 12 предметов кассетной BBC и два лазера дисковой и ZX: военный
	jp	c, eqshp1			; (техника от 10) и добывающий (от 11)
	ld	a, 14
eqshp1:
	ld	(Q), a
	ld	(QQ25), a
	ld	hl, Q
	inc	(hl)
	ld	a, (QQ14)			; LDA #70 : SEC : SBC QQ14 (при C=1 это A - QQ14)
	ld	e, a
	ld	a, 70
	sub	e
	add	a, a				; ASL A
	ld	(PRXS), a
	ld	b, 1
eql1:
	ld	hl, XX13
	ld	(hl), b
	call	TT67
	ld	a, (XX13)
	ld	b, a
	or	a				; CLC: без десятичной точки
	call	pr2
	call	TT162
	ld	a, (XX13)
	cp	13
	jp	nc, eq_xname			; для двух новых лазеров слов в словаре BBC нет
	or	a				; CLC
	adc	a, 104
	call	TT27
eq_named:
	ld	a, (XX13)
	call	prx_m1			; JSR prx-3
	scf					; SEC: цена с десятичной точкой
	ld	a, 25
	ld	(XC), a
	ld	a, 6
	call	TT11				; ld флаги не меняют — scf дожил до вызова
	ld	a, (XX13)
	inc	a
	ld	b, a
	ld	hl, Q
	cp	(hl)
	jp	c, eql1
	call	CLYNS
	ld	a, 127
	call	prq
	call	gnum
	jp	c, BAY				; перенос 1 — слишком много
	or	a
	jp	z, BAY				; 0 — выход
	dec	a				; C=0, SBC #0 вычитает 1: A = номер предмета (0..11)
	ld	b, 2
	ld	hl, XC
	ld	(hl), b
	ld	hl, YC
	inc	(hl)
	push	af				; PHA
	call	eq
	pop	af
	or a
	jp	nz, et0
	ld	(MCNT), a			; куплено топливо: счётчик ракет обнуляется,
	ld	b, 70				; и бак заполняется — как на BBC
	ld	hl, QQ14
	ld	(hl), b
et0:
	cp	1
	jp	nz, et1
	ld	a, (NOMSL)
	ld	b, a
	inc	b
	ld	c, 117
	ld	a, b
	cp	5
	ld	a, 1				; ld флаги не меняет: результат cp жив
	jp	nc, pres
	ld	hl, NOMSL
	ld	(hl), b
	call	msblob				; A = то, что оставил msblob, — как на BBC
et1:
	ld	c, 107
	cp	2
	jp	nz, et2
	ld	b, 37
	ld	a, b
	ld	hl, CRGO
	cp	(hl)
	ld	a, 2
	jp	z, pres
	ld	(hl), b
et2:
	cp	3
	jp	nz, et3
	inc	c
	ld	a, (ECM)
	ld	b, a
	or	a
	ld	a, 3
	jp	nz, pres
	ld	hl, ECM
	dec	(hl)
et3:
	cp	4
	jp	nz, et4
	call	qv
	ld	a, 4				; LDA #4 после qv
	ld	hl, LASER
	ld	a, b
	add	a, l
	ld	l, a
	ld	a, (hl)
	ld	c, a
	or	a
	ld	a, 4
	jp	z, ed4
ed7:
	ld	c, 187				; LDY #187 : BNE pres — переход всегда;
	jp	pres				; A = 4 (сверху) или 5 (из et4), как на BBC
ed4:
	ld	hl, LASER
	ld	a, b
	add	a, l
	ld	l, a
	ld	a, POW
	ld	(hl), a
	ld	a, 4
et4:
	cp	5
	jp	nz, et5
	call	qv
	ld	hl, T1
	ld	(hl), b				; STX T1 — номер вида
	ld	hl, LASER
	ld	a, b
	add	a, l
	ld	l, a
	ld	a, (hl)
	ld	c, a
	or	a
	ld	a, 5
	jp	z, ed5
	jp	m, ed7
	ld	a, 4
	call	prx
	call	MCASH
ed5:
	ld	a, POW + 128
	ld	d, a
	ld	a, (T1)
	ld	b, a
	ld	hl, LASER
	ld	a, b
	add	a, l
	ld	l, a
	ld	a, d
	ld	(hl), a				; A = 143 на выходе, как на BBC после STA LASER,X
et5:
	ld	c, 111
	cp	6
	jp	nz, et6
	ld	a, (BST)
	ld	b, a
	or	a
	ld	a, 6
	jp	z, ed9
pres:
	ld	hl, K
	ld	(hl), c				; A = номер предмета уже выставлен на каждом входе
	call	prx
	call	MCASH
	ld	a, (K)
	call	spc
	ld	a, 31
	call	TT27
err:
	call	dn2
	jp	BAY
ed9:
	ld	hl, BST
	dec	(hl)
et6:
	inc	c
	cp	7
	jp	nz, et7
	ld	a, (ESCP)
	ld	b, a
	or	a
	ld	a, 7
	jp	nz, pres
	ld	hl, ESCP
	dec	(hl)
et7:
	inc	c
	cp	8
	jp	nz, et8
	ld	a, (BOMB)
	ld	b, a
	or	a
	ld	a, 8
	jp	nz, pres
	ld	b, 0x7F
	ld	hl, BOMB
	ld	(hl), b
et8:
	inc	c
	cp	9
	jp	nz, etA
	ld	a, (ENGY)
	ld	b, a
	or	a
	ld	a, 9
	jp	nz, pres
	ld	hl, ENGY
	inc	(hl)
etA:
	inc	c
	cp	10
	jp	nz, etB
	ld	a, (DKCMP)
	ld	b, a
	or	a
	ld	a, 10
	jp	nz, pres
	ld	hl, DKCMP
	dec	(hl)
etB:
	inc	c
	cp	11
	jp	nz, et_ml
	ld	a, (GHYP)
	ld	b, a
	or	a
	ld	a, 11
	jp	nz, pres
	ld	hl, GHYP
	dec	(hl)
	jp	et9
et_ml:					; военный лазер (12) и добывающий (13)
	ld	d, 0x97
	ld	e, 12
	cp	12
	jp	z, eq_las
	ld	d, 50
	inc	e
	cp	13
	jp	nz, et9
eq_las:					; поставить лазер D (предмет E) на выбранный вид; прежний лазер — в зачёт
	push	de
	call	qv
	pop	de
	ld	hl, LASER
	ld	a, b
	add	a, l
	ld	l, a
	ld	a, (hl)
	cp	d
	jp	nz, el_1
	ld	c, 187			; такой уже стоит: «Laser Present», деньги назад
	ld	a, e
	jp	pres
el_1:
	or	a
	jp	z, el_fit
	push	hl
	push	de
	ld	c, 4			; цена прежнего: импульсный 4, лучевой 5, военный 12, добывающий 13
	cp	15
	jp	z, el_r
	inc	c
	cp	0x8F
	jp	z, el_r
	ld	c, 12
	cp	0x97
	jp	z, el_r
	inc	c
el_r:
	ld	a, c
	call	prx
	call	MCASH
	pop	de
	pop	hl
el_fit:
	ld	(hl), d
et9:
	call	dn
	jp	EQSHP
eq_xname:
	ld	a, MZ_MIL
	jp	z, eq_xn
	ld	a, MZ_MINL
eq_xn:
	call	mz_str
	jp	eq_named

; eq: купить предмет A. Хватает денег — возврат с A = номер предмета (BCS c, а c — просто ret);
; не хватает — печать «Cash?» и уход в err, не возвращаясь (стек правит MLOOP, как на BBC).
eq:
	call	prx
	call	LCASH
	ret	c
	ld	a, 197
	call	prq
	jp	err

; prx-3: вход в prx на три байта раньше (SEC : SBC #1 при C=1 — это A - 1).
prx_m1:
	dec	a
prx:
	add	a, a				; ASL A
	ld	c, a				; TAY
	ld	b, 0
	ld	hl, PRXS
	add	hl, bc
	ld	b, (hl)				; LDX PRXS,Y
	inc	hl
	ld	c, (hl)				; LDA PRXS+1,Y : TAY
	ret

; qv: «Which laser, 0-9?» и ожидание цифры вида 0..3.
qv:
	ld	c, 16
	ld	hl, YC
	ld	(hl), c
qv1:
	ld	b, 12
	ld	hl, XC
	ld	(hl), b
	ld	a, c
	or	a				; CLC
	adc	a, '0' - 16
	call	spc
	ld	a, (YC)
	or	a				; CLC
	adc	a, 80
	call	TT27
	ld	hl, YC
	inc	(hl)
	ld	a, (YC)
	ld	c, a
	cp	20
	jp	c, qv1
qv3:
	call	CLYNS
qv2:
	ld	a, 175
	call	prq
	call	TT217				; A = знак клавиши (и B = он же)
	sub	'0'				; SEC : SBC #'0' — цифра клавиши
	cp	4
	jp	nc, qv3				; CMP #4 : BCS qv3 — не 0..3, спросить снова
	ld	b, a				; TAX: X = номер вида 0..3
	ret

; PRXS: цены оборудования, по слову на предмет, в десятых долях кредита. Цену топлива (слово 0) EQSHP считает
; сама и записывает сюда — как на BBC.
PRXS:
	dw	1			; 0  топливо
	dw	300			; 1  ракета
	dw	4000			; 2  большой грузовой отсек
	dw	6000			; 3  система ECM
	dw	4000			; 4  импульсный лазер
	dw	10000			; 5  лучевой лазер
	dw	5250			; 6  топливозаборник
	dw	10000			; 7  спасательная капсула
	dw	9000			; 8  энергетическая бомба
	dw	15000			; 9  блок энергии
	dw	10000			; 10 стыковочный компьютер
	dw	50000			; 11 галактический прыжок
	dw	60000			; 12 военный лазер
	dw	8000			; 13 добывающий лазер
