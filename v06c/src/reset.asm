; Сброс и запуск корабля: ZERO, RESET, RES2, ZINF, GINF, NWSHP, WPSHPS, FLFLLS. Перенесено близко к тексту BBC;
; сверка с эталоном — v06c/test/t16.mjs.
NI		equ	36		; байт в блоке корабля
NOSH		equ	12		; мест под корабли
NOST		equ	18		; пылинок

; ZERO: обнулить страницы &9–&D BBC — блоки кораблей, кучу отрезков и начало WP (места кораблей, счётчики).
; A = 0, X = 9, Y = 0, перенос 1, SC = &0900 — как на BBC.
ZERO:
	ld	hl, WS + 0x0900
	ld	bc, 0x0500
zero_l:
	ld	(hl), 0
	inc	hl
	dec	bc
	ld	a, b
	or	c
	jp	nz, zero_l
	ld	hl, 0x0900
	ld	(SC), hl
	ld	bc, 0x0900
	scf
	ret

; RESET: сброс перед заставкой: углы, щиты, энергия; дальше RES2.
RESET:
	call	ZERO
	ld	hl, BETA
	ld	b, 7
rs_b:
	ld	(hl), a
	inc	hl
	dec	b
	jp	nz, rs_b
	ld	a, 0xFF
	ld	(QQ12), a
	ld	(FSH), a
	ld	(ASH), a
	ld	(ENERGY), a
; RES2: сброс полёта: пыль, ракета, углы, скорость; стереть корабли со сканера, очистить блоки и кучу отрезков,
; обновить панель; дальше ZINF.
RES2:
	ld	a, NOST
	ld	(NOSTM), a
	ld	a, 0xFF
	ld	(LSX2), a
	ld	(LSY2), a
	ld	(MSTG), a
	ld	a, 128
	ld	(JSTY), a
	ld	(ALP2), a
	ld	(BET2), a
	xor	a
	ld	(ALP2 + 1), a
	ld	(BET2 + 1), a
	ld	(MCNT), a
	ld	a, 3
	ld	(DELTA), a
	ld	(ALPHA), a
	ld	(ALP1), a
	ld	a, (SSPR)
	or	a
	call	nz, SPBLB
	ld	a, (ECMA)
	or	a
	call	nz, ECMOF
	call	WPSHPS
	call	ZERO
	ld	hl, WP - 1
	ld	(SLSP), hl
	call	DIALS
; ZINF: блок INWK — в ноль; ориентация — единичная, носом к нам. A = E0h, Y = FFh.
ZINF:
	ld	hl, INWK
	ld	b, NI
zi1:
	ld	(hl), 0
	inc	hl
	dec	b
	jp	nz, zi1
	ld	a, 96
	ld	(INWK + 18), a
	ld	(INWK + 22), a
	or	0x80
	ld	(INWK + 14), a
	ld	c, 0xFF
	ret

; GINF: INF = адрес блока корабля в месте X. Сохраняет BC.
GINF:
	ld	e, b
	ld	d, 0
	ld	hl, UNIV
	add	hl, de
	add	hl, de
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a
	ld	(INF), hl
	ret
UNIV:
	dw	K_, K_ + NI, K_ + NI * 2, K_ + NI * 3, K_ + NI * 4, K_ + NI * 5, K_ + NI * 6
	dw	K_ + NI * 7, K_ + NI * 8, K_ + NI * 9, K_ + NI * 10, K_ + NI * 11, K_ + NI * 12

; NWSHP: завести корабль типа A из блока INWK: место в FRIN, блок в K%, список отрезков в куче (растёт вниз
; от SLSP). Перенос 1 — заведён (X = тип); перенос 0 — нет места.
NWSHP:
	ld	(T), a
	ld	b, 0
	ld	hl, FRIN
nwl1:
	ld	a, (hl)
	or	a
	jp	z, nw1
	inc	hl
	inc	b
	ld	a, b
	cp	NOSH
	jp	c, nwl1
	or	a
	ret
nw1:
	call	GINF
	ld	a, (T)
	or	a
	jp	m, nw2
	add	a, a
	ld	e, a
	ld	d, 0
	ld	hl, XX21 - 2
	add	hl, de
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a
	ld	(XX0), hl
	ld	a, e
	cp	2 * 8			; станция: список отрезков не нужен
	jp	z, nw6
	ld	de, 5
	add	hl, de
	ld	a, (hl)
	ld	(T1), a
	ld	e, a
	ld	hl, (SLSP)
	ld	a, l
	sub	e
	ld	l, a
	ld	a, h
	sbc	a, 0
	ld	h, a
	ld	(INWK + 33), hl
	ex	de, hl
	ld	hl, (INF)
	ld	a, e
	sub	l
	ld	c, a
	ld	a, d
	sbc	a, h
	jp	c, nw_fail		; куча дошла до блоков
	jp	nz, nw4
	ld	a, c
	cp	NI
	jp	c, nw_fail
nw4:
	ld	hl, (INWK + 33)
	ld	(SLSP), hl
nw6:
	ld	hl, (XX0)
	ld	de, 14
	add	hl, de
	ld	a, (hl)
	ld	(INWK + 35), a
	ld	de, 5
	add	hl, de
	ld	a, (hl)
	and	7
	ld	(INWK + 31), a
	ld	a, (T)
nw2:
	ld	e, b
	ld	d, 0
	ld	hl, FRIN
	add	hl, de
	ld	(hl), a
	ld	b, a
	or	a
	jp	m, nw_cp
	ld	e, a
	ld	hl, MANY
	add	hl, de
	inc	(hl)
nw_cp:
	ld	hl, (INF)
	ex	de, hl
	ld	hl, INWK
	ld	c, NI
nwl3:
	ld	a, (hl)
	ld	(de), a
	inc	hl
	inc	de
	dec	c
	jp	nz, nwl3
	ld	c, 0xFF
	scf
	ret
nw_fail:
	or	a
	ret

; WPSHPS: стереть все корабли со сканера и снять у них признаки «на сканере», «на экране», «стреляет»;
; дальше FLFLLS.
WPSHPS:
	ld	b, 0
wsl1:
	ld	hl, FRIN
	ld	e, b
	ld	d, 0
	add	hl, de
	ld	a, (hl)
	or	a
	jp	z, ws2
	jp	m, ws1
	ld	(TYPE), a
	call	GINF
	ex	de, hl
	ld	hl, (INF)
	ld	de, INWK
	ld	c, 32
wsl2:
	ld	a, (hl)
	ld	(de), a
	inc	hl
	inc	de
	dec	c
	jp	nz, wsl2
	ld	a, b
	ld	(XSAV), a
	call	SCAN
	ld	a, (XSAV)
	ld	b, a
	ld	hl, (INF)
	ld	de, 31
	add	hl, de
	ld	a, (hl)
	and	0xA7
	ld	(hl), a
ws1:
	inc	b
	jp	nz, wsl1
ws2:
	ld	a, 0xFF
	ld	(LSX2), a
	ld	(LSY2), a
; FLFLLS: обнулить список строк солнца LSO (191 байт), LSX = FFh. A = 0, Y = FFh.
FLFLLS:
	ld	hl, LSO + 1
	ld	b, 191
sal6:
	ld	(hl), 0
	inc	hl
	dec	b
	jp	nz, sal6
	ld	a, 0xFF
	ld	(LSX), a
	xor	a
	ld	c, 0xFF
	ret
