; Взрыв корабля: DOEXP (облако растёт, потом гаснет), PTCLS (точки облака), EXS1, EX2.
; Перенесено близко к тексту BBC. Данные облака лежат в списке отрезков корабля (адрес XX19):
; байт 0 — размер, 1 — счётчик, 2 — длина записи, 3–6 — затравки случайных чисел, дальше вершины по 4 байта.
; Сверка — сценарий fight (v06c/test/t27.mjs fight).

EX2:					; облако погасло: корабль убрать
	ld	hl, INWK + 31
	ld	a, (hl)
	or	0xA0
	ld	(hl), a
	ret
DOEXP:
	ld	a, (INWK + 31)
	and	0x40
	call	nz, PTCLS		; стереть прежнее облако
	ld	a, (INWK + 6)
	ld	(T), a
	ld	e, a
	ld	a, (INWK + 7)
	cp	32
	jp	c, dx_near
	ld	a, 0xFE
	ld	d, 5			; на BBC счётчик растёт на 4 + перенос
	jp	dx_yy
dx_near:
	ld	h, a
	ld	l, e
	add	hl, hl
	add	hl, hl
	ld	a, l
	ld	(T), a
	ld	a, h
	scf
	rla
	ld	d, 4
dx_yy:
	ld	(Q), a
	ld	hl, (XX19)
	inc	hl
	ld	a, (hl)
	add	a, d
	jp	c, EX2
	ld	(hl), a
	call	DVID4
	ld	a, (P_)
	cp	0x1C
	jp	c, dx_s
	ld	a, 0xFE
	jp	dx_l1
dx_s:
	ld	h, a
	ld	a, (R_)
	ld	l, a
	add	hl, hl
	add	hl, hl
	add	hl, hl
	ld	a, l
	ld	(R_), a
	ld	a, h
dx_l1:
	ld	hl, (XX19)
	ld	(hl), a
	ld	hl, INWK + 31
	ld	a, (hl)
	and	0xBF
	ld	(hl), a
	and	8
	ret	z
	ld	hl, (XX19)
	inc	hl
	inc	hl
	ld	c, (hl)
	ld	b, 0
	dec	hl
	dec	hl
	add	hl, bc
	ex	de, hl
	ld	hl, XX3 - 7
	add	hl, bc
exl1:
	ld	a, (hl)
	ld	(de), a
	dec	hl
	dec	de
	dec	c
	ld	a, c
	cp	6
	jp	nz, exl1
	ld	hl, INWK + 31
	ld	a, (hl)
	or	0x40
	ld	(hl), a
; PTCLS: нарисовать (или стереть) облако: у каждой вершины U точек, разброс — по размеру облака.
PTCLS:
	ld	hl, (XX19)
	ld	a, (hl)
	ld	(Q), a
	inc	hl
	ld	a, (hl)
	or	a
	jp	p, pt_1
	cpl
pt_1:
	or	a
	rra
	or	a
	rra
	or	a
	rra
	or	1
	ld	(U), a
	inc	hl
	ld	a, (hl)
	ld	(TGT), a
	ld	a, (RAND + 1)
	push	af
	ld	c, 6
exl5:
	ld	hl, (XX19)
	ld	b, 0
	add	hl, bc
	inc	hl
	ld	a, (hl)
	ld	(K3 + 3), a
	inc	hl
	ld	a, (hl)
	ld	(K3 + 2), a
	inc	hl
	ld	a, (hl)
	ld	(K3 + 1), a
	inc	hl
	ld	a, (hl)
	ld	(K3), a
	ld	a, c
	add	a, 4
	ld	c, a
	ld	(CNT), a
	ld	hl, (XX19)
	inc	hl
	inc	hl
	inc	hl
	ld	de, RAND
	ld	b, 4
exl2:
	ld	a, (hl)
	xor	c
	ld	(de), a
	inc	hl
	inc	de
	dec	b
	jp	nz, exl2
	ld	a, (U)
	ld	c, a
exl4:
	call	DORND2
	ld	(ZZ), a
	ld	a, (K3 + 1)
	ld	(R_), a
	ld	a, (K3)
	call	EXS1
	jp	nz, ex11
	ld	a, b
	cp	191
	jp	nc, ex11
	ld	(Y1), a
	ld	a, (K3 + 3)
	ld	(R_), a
	ld	a, (K3 + 2)
	call	EXS1
	jp	nz, ex4
	ld	a, (Y1)
	call	PIXEL
ex4:
	dec	c
	jp	p, exl4
	ld	a, (CNT)
	ld	c, a
	ld	hl, TGT
	cp	(hl)
	jp	c, exl5
	pop	af
	ld	(RAND + 1), a
	ld	a, (K_ + 6)
	ld	(RAND + 3), a
	ret
ex11:
	call	DORND2
	jp	ex4
; EXS1: (A X) = (A R) ± случайное · Q / 256; Z — старший байт равен нулю. Y сохраняется.
EXS1:
	ld	(S), a
	call	DORND2
	rla
	jp	c, ex5
	push	bc
	call	FMLTU
	pop	bc
	ld	hl, R_
	scf				; перенос после FMLTU на BBC равен 1
	adc	a, (hl)
	ld	b, a
	ld	a, (S)
	adc	a, 0
	ret
ex5:
	push	bc
	call	FMLTU
	pop	bc
	ld	(T), a
	ld	e, a
	ld	a, (R_)
	sub	e
	ld	b, a
	ld	a, (S)
	sbc	a, 0
	ret
