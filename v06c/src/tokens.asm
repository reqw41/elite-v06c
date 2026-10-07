; Текст из словаря: TT27 кассетной версии BBC и её ветви. Сверка с эталоном — v06c/test/t14.mjs (экран, XC, YC,
; QQ17). Регистры на выходе не определены. Словарь QQ18 лежит в образе, обход идёт указателем в HL
; (на BBC — ячейки V, V+1 и стек).
RE		equ	0x23		; знаки словаря лежат под исключающим ИЛИ с этим числом

; plf: знак или слово A, затем перевод строки. TT67: перевод строки. TT162: пробел. TT73: двоеточие.
plf:
	call	TT27
TT67:
	ld	a, 13
	jp	TT27
TT162:
	ld	a, ' '
	jp	TT27
crlf:
	ld	a, 21
	ld	(XC), a
TT73:
	ld	a, ':'

; TT27: напечатать знак или слово A.
;   0–5 — деньги, номер галактики, название системы, выбранная система, имя, топливо и деньги (этап P5);
;   6 — дальше «Как в предложении», 8 — дальше ПРОПИСНЫМИ, 9 — табуляция к столбцу 21 и двоеточие;
;   7, 10–13, 32–95 — знак с учётом режима QQ17; 14–31 — слово 128–145; 96–127 — слово с этим номером;
;   128–159 — слог из двух букв (QQ16); 160–255 — слово 0–95.
; QQ17: 0 — прописные; бит 7 — как в предложении, бит 6 — следующая буква строчная; 255 — не печатать.
TT27:
	or	a
	jp	z, csh
	jp	m, tt43
	cp	1
	jp	z, tal
	cp	2
	jp	z, ypl
	cp	3
	jp	z, cpl_
	cp	4
	jp	z, cmn
	cp	5
	jp	z, fwl
	cp	6
	jp	nz, tt27_8
	ld	a, 0x80
	ld	(QQ17), a
	ret
tt27_8:
	cp	8
	jp	nz, tt27_9
	xor	a
	ld	(QQ17), a
	ret
tt27_9:
	cp	9
	jp	z, crlf
	cp	96
	jp	nc, ex
	cp	14
	jp	c, tt27_ch
	cp	32
	jp	c, qw
tt27_ch:
	ld	e, a
	ld	a, (QQ17)
	ld	d, a
	or	a
	ld	a, e
	jp	z, TT26
	jp	m, tt41
	ld	a, d
	and	0x40
	ld	a, e
	jp	nz, tt46
tt42:					; букву — строчной
	cp	'A'
	jp	c, TT26
	cp	'Z' + 1
	jp	nc, TT26
	add	a, 32
	jp	TT26
tt41:					; как в предложении
	ld	a, d
	and	0x40
	ld	a, e
	jp	nz, tt45
	cp	'A'
	jp	c, TT26
	ld	a, d			; первая буква — прописная, дальше строчные
	or	0x40
	ld	(QQ17), a
	ld	a, e
	jp	TT26
tt45:
	inc	d
	ret	z			; QQ17 = 255: печать выключена
	dec	d
	cp	'A'
	jp	nc, tt42
tt46:					; не буква: следующая буква снова прописная
	ld	a, d
	and	0xBF
	ld	(QQ17), a
	ld	a, e
	jp	TT26
qw:
	add	a, 114
	jp	ex
tt43:
	cp	160
	jp	nc, tt47
	and	127			; слог
	add	a, a
	ld	e, a
	ld	d, 0
	ld	hl, QQ16
	add	hl, de
	ld	a, (hl)
	push	hl
	call	TT27
	pop	hl
	inc	hl
	ld	a, (hl)
	cp	'?'
	ret	z
	jp	TT27
tt47:
	sub	160
; ex: слово номер A из словаря (слова разделены нулём).
ex:
	ld	hl, QQ18
	or	a
	jp	z, tt50
	ld	b, a
tt51:
	ld	a, (hl)
	inc	hl
	or	a
	jp	nz, tt51
	dec	b
	jp	nz, tt51
tt50:
	ld	a, (hl)
	xor	RE
	push	hl
	call	TT27
	pop	hl
	inc	hl
	ld	a, (hl)
	or	a
	jp	nz, tt50
	ret
