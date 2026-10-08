; Поиск системы по названию (клавиша F на картах) — как в дисковой версии BBC (HME2) и в версии ZX.
; Названия всех 256 систем галактики строятся по семенам и сравниваются с набранным; найденная система
; становится целью прыжка, под картой печатаются её название и расстояние. Сверка — v06c/test/mis.mjs (find).
hme_key:
	ld	a, (QQ11)
	and	0xC0
	ret	z			; не карта
HME2:
	call	CLYNS
	ld	a, MZ_PNAME
	call	mz_str
	ld	a, 8
	ld	(rl_max), a
	call	rline
	push	af
	ld	a, 7
	ld	(rl_max), a
	pop	af
	jp	c, CLYNS		; отказ
	ld	a, c
	or	a
	jp	z, CLYNS		; пустая строка
	call	TT103			; убрать перекрестие
	call	TT81
	xor	a
	ld	(XX20), a
hme3:
	ld	hl, QQ15		; название системы с семенами QQ15 — в hm_buf
	ld	de, QQ19
	ld	b, 6
	call	ll9_cp
	ld	de, hm_buf
	ld	a, (QQ15)
	and	0x40
	ld	a, 3
	jp	nz, hme_n
	dec	a
hme_n:
	ld	(T), a
hme_p:
	ld	a, (QQ15 + 5)
	and	0x1F
	jp	z, hme_t
	add	a, a
	ld	l, a
	ld	h, 0
	ld	bc, QQ16
	add	hl, bc
	ld	a, (hl)
	call	hme_put
	inc	hl
	ld	a, (hl)
	call	hme_put
hme_t:
	push	de
	call	TT54
	pop	de
	ld	hl, T
	dec	(hl)
	jp	p, hme_p
	ld	a, 13
	ld	(de), a
	ld	hl, QQ19
	ld	de, QQ15
	ld	b, 6
	call	ll9_cp
	ld	hl, hm_buf		; сравнить с набранным, вместе с концом строки
	ld	de, INWK
hme_c:
	ld	a, (de)
	cp	(hl)
	jp	nz, hme_next
	cp	13
	jp	z, hme5
	inc	hl
	inc	de
	jp	hme_c
hme_next:
	call	TT20
	ld	hl, XX20
	inc	(hl)
	jp	nz, hme3
	call	TT111			; не нашли: цель прежняя
	call	TT103
	ld	a, 40
	call	NOISE
	call	CLYNS
	ld	a, MZ_NFOUND
	jp	mz_str
hme5:
	ld	a, (QQ15 + 3)
	ld	(QQ9), a
	ld	a, (QQ15 + 1)
	ld	(QQ10), a
	call	TT111
	call	TT103
	call	CLYNS
	xor	a
	jp	t95_p			; название и расстояние
hme_put:
	cp	'?'
	ret	z
	ld	(de), a
	inc	de
	ret
