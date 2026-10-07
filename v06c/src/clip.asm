; Отсечение отрезка по краям обзора: LL145 (LL147), LL118. Перенесено близко к тексту BBC;
; сравнение с эталоном — v06c/test/t09.mjs.
clip_start:

; LL118: точку (x1, y1) = (XX15(1 0), XX15(3 2)) довести вдоль отрезка до края экрана.
; Наклон — XX12+2, XX12+3, T (их готовит LL145). Регистры на выходе не определены.
LL118:
	ld	a, (XX15 + 1)
	or	a
	jp	p, ll119
	ld	(S), a			; x1 < 0: на левый край
	call	LL120
	call	ll118_y
	xor	a
	ld	(XX15), a
	ld	(XX15 + 1), a
	jp	ll134
ll119:
	jp	z, ll134
	dec	a			; x1 > 255: на правый край
	ld	(S), a
	call	LL120
	call	ll118_y
	ld	a, 255
	ld	(XX15), a
	xor	a
	ld	(XX15 + 1), a
ll134:
	ld	a, (XX15 + 3)
	or	a
	jp	p, ll135
	ld	(S), a			; y1 < 0: на верхний край
	ld	a, (XX15 + 2)
	ld	(R_), a
	call	LL123
	call	ll118_x
	xor	a
	ld	(XX15 + 2), a
	ld	(XX15 + 3), a
ll135:
	ld	a, (XX15 + 2)
	sub	192
	ld	(R_), a
	ld	a, (XX15 + 3)
	sbc	a, 0
	ld	(S), a
	ret	c
	call	LL123			; y1 > 191: на нижний край
	call	ll118_x
	ld	a, 191
	ld	(XX15 + 2), a
	xor	a
	ld	(XX15 + 3), a
	ret
ll118_y:
	ld	hl, XX15 + 2
	jp	ll118_add
ll118_x:
	ld	hl, XX15
ll118_add:
	ld	a, b
	add	a, (hl)
	ld	(hl), a
	inc	hl
	ld	a, c
	adc	a, (hl)
	ld	(hl), a
	ret

; LL145: отсечь отрезок (XX15(1 0), XX15(3 2)) – (XX15(5 4), XX12(1 0)) по экрану 256×192.
; Перенос 0 — виден: XX15, XX15+1, XX15+2, XX15+3 = x1, y1, x2, y2. Перенос 1 — не виден.
; SWAP = FFh, если концы поменяны. Y сохраняется; A и X на выходе не определены.
; LL147 — вход без обнуления SWAP, в A должен быть XX15+5.
LL145:
	xor	a
	ld	(SWAP), a
	ld	a, (XX15 + 5)
LL147:
	ld	b, 191
	ld	hl, XX12 + 1
	or	(hl)
	jp	nz, ll107
	ld	a, (XX12)
	ld	d, a
	ld	a, 191
	cp	d
	jp	c, ll107
	ld	b, 0			; второй конец на экране
ll107:
	ld	a, b
	ld	(XX13), a
	ld	a, (XX15 + 1)
	ld	hl, XX15 + 3
	or	(hl)
	jp	nz, ll83
	ld	a, (XX15 + 2)
	ld	d, a
	ld	a, 191
	cp	d
	jp	c, ll83
	ld	a, (XX13)		; первый конец на экране
	or	a
	jp	nz, ll108
ll146:
	ld	a, (XX15 + 2)
	ld	(XX15 + 1), a
	ld	a, (XX15 + 4)
	ld	(XX15 + 2), a
	ld	a, (XX12)
	ld	(XX15 + 3), a
	or	a
	ret
ll109:
	scf
	ret
ll108:
	ld	a, (XX13)
	or	a
	rra
	ld	(XX13), a
ll83:
	ld	a, (XX13)
	or	a
	jp	p, ll115
	ld	a, (XX15 + 1)		; оба конца вне экрана: быстрые отказы
	ld	hl, XX15 + 5
	and	(hl)
	jp	m, ll109
	ld	a, (XX15 + 3)
	ld	hl, XX12 + 1
	and	(hl)
	jp	m, ll109
	ld	a, (XX15 + 5)
	dec	a
	ld	(XX12 + 2), a
	ld	d, a
	ld	a, (XX15 + 1)
	dec	a
	or	d
	jp	p, ll109
	ld	a, (XX15 + 2)
	cp	192
	ld	a, (XX15 + 3)
	sbc	a, 0
	ld	(XX12 + 2), a
	ld	d, a
	ld	a, (XX12)
	cp	192
	ld	a, (XX12 + 1)
	sbc	a, 0
	or	d
	jp	p, ll109
ll115:
	push	bc
	ld	hl, (XX15)		; dx = x2 - x1
	ex	de, hl
	ld	hl, (XX15 + 4)
	ld	a, l
	sub	e
	ld	(XX12 + 2), a
	ld	a, h
	sbc	a, d
	ld	(XX12 + 3), a
	ld	hl, (XX15 + 2)		; dy = y2 - y1
	ex	de, hl
	ld	hl, (XX12)
	ld	a, l
	sub	e
	ld	l, a
	ld	a, h
	sbc	a, d
	ld	h, a
	ld	(XX12 + 4), hl
	ld	a, (XX12 + 3)
	xor	h
	ld	(S), a			; знак наклона
	ld	a, h
	or	a
	jp	p, ll110
	xor	a
	sub	l
	ld	l, a
	ld	a, 0
	sbc	a, h
	ld	h, a
ll110:
	ld	a, (XX12 + 2)
	ld	e, a
	ld	a, (XX12 + 3)
	ld	d, a
	or	a
	jp	p, ll111
	xor	a
	sub	e
	ld	e, a
	ld	a, 0
	sbc	a, d
	ld	d, a
ll111:
	ld	a, d			; |dx| и |dy| вправо, пока не станут байтами
	or	a
	jp	nz, ll112
	ld	a, h
	or	a
	jp	z, ll113
ll112:
	ld	a, d
	or	a
	rra
	ld	d, a
	ld	a, e
	rra
	ld	e, a
	ld	a, h
	or	a
	rra
	ld	h, a
	ld	a, l
	rra
	ld	l, a
	jp	ll111
ll113:
	ld	(XX12 + 4), hl
	ld	a, e
	ld	(XX12 + 2), a
	xor	a
	ld	(T), a
	ld	a, e
	cp	l
	jp	c, ll114
	ld	(Q), a			; пологий: наклон = dy / dx, T = 0
	ld	a, l
	call	LL28
	jp	ll116
ll114:
	ld	a, l			; крутой: наклон = dx / dy, T = FFh
	ld	(Q), a
	ld	a, e
	call	LL28
	ld	hl, T
	dec	(hl)
ll116:
	ld	a, (R_)
	ld	(XX12 + 2), a
	ld	a, (S)
	ld	(XX12 + 3), a
	ld	a, (XX13)
	or	a
	jp	z, ll138
	jp	p, llx117
ll138:
	call	LL118
	ld	a, (XX13)
	or	a
	jp	p, ll124
	ld	a, (XX15 + 1)
	ld	hl, XX15 + 3
	or	(hl)
	jp	nz, ll137
	ld	a, (XX15 + 2)
	cp	192
	jp	nc, ll137
llx117:
	ld	hl, (XX15)		; поменять концы и отсечь второй
	ex	de, hl
	ld	hl, (XX15 + 4)
	ld	(XX15), hl
	ex	de, hl
	ld	(XX15 + 4), hl
	ld	hl, (XX15 + 2)
	ex	de, hl
	ld	hl, (XX12)
	ld	(XX15 + 2), hl
	ex	de, hl
	ld	(XX12), hl
	call	LL118
	ld	hl, SWAP
	dec	(hl)
ll124:
	pop	bc
	jp	ll146
ll137:
	pop	bc
	scf
	ret
clip_end:
