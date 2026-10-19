; Тестовая сцена (сборка -DSCENE, elite_sun.rom): на паузе клавиша M — солнце впереди слева вверху, планета далеко
; позади, станция убрана, четыре враждебных Sidewinder перед игроком. Для проверки скорости движка на железе
; (та же сцена, что SUN=1 в tools/analysis/speed3.mjs). Вызывать можно сколько угодно раз; A на выходе — клавиша (B).
scn_go:
	push	bc
	call	wpls_red		; прежнее солнце — стереть (если было)
	call	ks4_g			; станцию (или солнце) на месте 1 — новое солнце
	ld	hl, scn_sun
	ld	de, K_ + 36
	ld	b, 9
	call	ll9_cp
	ld	hl, scn_pl
	ld	de, K_
	ld	b, 9
	call	ll9_cp
	ld	hl, scn_pos
	ld	c, 4
scn_l:
	push	bc
	push	hl
	call	ZINF
	pop	hl
	ld	de, INWK
	ld	b, 9
	call	ll9_cp
	push	hl
	ld	a, 0xBF			; с тактикой, нападает
	ld	(INWK + 32), a
	ld	a, 1			; Sidewinder
	call	NWSHP
	pop	hl
	pop	bc
	dec	c
	jp	nz, scn_l
	ld	a, 7			; гудок и ждать, пока M отпустят (иначе сцена повторится)
	call	TT26
scn_w:
	call	RDKEY
	ld	a, b
	cp	0x65
	jp	z, scn_w
	pop	bc
	ld	a, b
	ret
; координаты: x, y, z — по три байта (младший, старший, знак)
scn_sun:	db	0x00, 0x80, 0x80,  0x00, 0x40, 0x00,  0x00, 0x00, 0x03
scn_pl:		db	0x00, 0x00, 0x00,  0x00, 0x00, 0x00,  0x00, 0x00, 0x90
scn_pos:	db	0x00, 0x01, 0x80,  0x00, 0x00, 0x00,  0x00, 0x05, 0x00
		db	0x00, 0x01, 0x00,  0x80, 0x00, 0x00,  0x00, 0x06, 0x00
		db	0x00, 0x00, 0x00,  0x80, 0x00, 0x80,  0x00, 0x07, 0x00
		db	0x80, 0x01, 0x80,  0xC0, 0x00, 0x00,  0x00, 0x08, 0x00
