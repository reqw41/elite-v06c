; Гибель: DEATH — взрыв, обломки (контейнеры) разлетаются, надпись «GAME OVER», затем сброс и заставка.
; Перенесено близко к тексту BBC. Сверка — сценарий fight (v06c/test/t27.mjs fight).

; DET1: на BBC — число строк экрана (X = 24 — панель скрыта, 31 — видна). На Векторе панель пока остаётся.
DET1:
	ret
DEATH:
	call	EXNO3
	call	RES2
	ld	hl, DELTA
	ld	a, (hl)
	add	a, a
	add	a, a
	ld	(hl), a
	ld	b, 24
	call	DET1
	ld	a, 6
	call	TT66
	call	BOX			; рамка рисуется второй раз — исчезает
	or	a
	call	nWq
	ld	a, 12
	ld	(YC), a
	ld	(XC), a
	ld	a, 146
	call	ex
	or	a			; перенос 6502 здесь и на каждом круге — 0
d1:
	call	Ze
	or	a
	rra
	or	a
	rra
	push	af
	ld	(INWK), a
	xor	a
	ld	(QQ11), a
	ld	(INWK + 1), a
	ld	(INWK + 4), a
	ld	(INWK + 7), a
	ld	(INWK + 32), a
	dec	a
	ld	(MCNT), a
	ld	(LASCT), a
	pop	af
	push	af
	xor	0x2A
	ld	(INWK + 3), a
	or	0x50
	ld	(INWK + 6), a
	ld	a, b
	and	0x8F
	ld	(INWK + 29), a
	ld	d, a
	pop	af
	ld	a, d
	rra
	push	af
	and	0x87
	ld	(INWK + 30), a
	pop	af
	push	af
	ld	b, 11
	call	fq1
	pop	af
	ld	a, 0
	rra
	ld	hl, (INF)
	ld	de, 31
	add	hl, de
	ld	(hl), a
	ld	a, (FRIN + 3)
	or	a
	jp	z, d1
	call	U_
	ld	(DELTA), a
death_d2:
	call	M_
	ld	a, (LASCT)
	or	a
	jp	nz, death_d2
	ld	b, 31
	call	DET1
DEATH2:
	call	RES2
	jp	TT170
