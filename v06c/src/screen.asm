; Экран: очистка обзора и рамка (TT66, TTX66), очистка трёх нижних строк текста (CLYNS).
; Написано по смыслу под столбцовый экран; сверка с эталоном — v06c/test/t15.mjs (обзор и рабочие области).

; TT66: очистить обзор и задать вид экрана QQ11 = A. TTX66: то же без смены QQ11.
; Обнуляет LAS2, DLY, de; курсор в строку 1; для вида из корабля (QQ11 = 0) печатает его название;
; рисует рамку: линия сверху и по две вертикали по краям. На выходе QQ17 = 0.
TT66:
	ld	(QQ11), a
TTX66:
	ld	a, 0x80
	ld	(QQ17), a
	xor	a
	ld	(LAS2), a
	ld	(DLY), a
	ld	(de_), a
	ld	h, high SCR_VIEW	; строки 0..191 всех 32 столбцов
tx_col:
	ld	l, 255
	ld	b, DASH_Y / 8
tx_b:
	dup	8
	ld	(hl), a
	dec	l
	edup
	dec	b
	jp	nz, tx_b
	inc	h
	ld	a, h
	cp	high SCR_VIEW + 32
	ld	a, 0
	jp	nz, tx_col
	ld	a, (QQ22 + 1)
	or	a
	call	nz, ee3			; идёт отсчёт перед прыжком — показать его
BOX:					; рамка (и название вида); второй вызов стирает рамку
	ld	a, 1
	ld	(YC), a
	ld	a, (QQ11)
	or	a
	jp	nz, tt66
	ld	a, 11
	ld	(XC), a
	ld	a, (VIEW)
	or	0x60
	call	TT27
	call	TT162
	ld	a, 175
	call	TT27
tt66:
	xor	a
	ld	(X1), a
	ld	(Y1), a
	ld	(QQ17), a
	dec	a
	ld	(X2), a
	call	HLOIN
	ld	a, 2
	ld	(X1), a
	ld	(X2), a
	call	BOS2
BOS2:
	call	BOS1
BOS1:
	xor	a
	ld	(Y1), a
	ld	a, DASH_Y - 1
	ld	(Y2), a
	ld	hl, X1
	dec	(hl)
	ld	hl, X2
	dec	(hl)
	jp	LOIN

; CLYNS: очистить текстовые строки 21–23 (столбцы 1–29 целиком и верхнюю линию столбца 30 — как на BBC),
; курсор в строку 21, столбец 1. На выходе A = 0, Y = 0.
CLYNS:
	ld	a, 20
	ld	(YC), a
	call	TT67
	ld	h, high SCR_VIEW + 1
	xor	a
cl_col:
	ld	l, 255 - 21 * 8
	ld	b, 24
cl_b:
	ld	(hl), a
	dec	l
	dec	b
	jp	nz, cl_b
	inc	h
	ld	a, h
	cp	high SCR_VIEW + 30
	ld	a, 0
	jp	nz, cl_col
	ld	l, 255 - 21 * 8
	ld	(hl), a
	ld	l, 255 - 22 * 8
	ld	(hl), a
	ld	l, 255 - 23 * 8
	ld	(hl), a
	inc	a
	ld	(XC), a
	xor	a
	ld	c, a
	ret
