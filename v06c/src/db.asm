; Двойной буфер (сборка -DDBUF, чёрно-белая). Вид из корабля рисуется в скрытую плоскость (C000h или E000h);
; палитра показывает одну плоскость: цвет — у точек с её битом, у остальных — фон. Панель приборов одинакова в
; обеих плоскостях. Проход главного цикла (M%) начинается с db_begin: дождаться показа прошлого кадра, сменить
; плоскость, очистить её и вернуть в неё всё, что по состоянию игры уже на экране и стирается повторной печатью
; (солнце, пыль, луч, прицел, название вида, сообщение, отсчёт); корабли и планета считаются стёртыми.
; Конец прохода — db_show: палитра для плоскости рисования; прерывание кадра запишет её первой (db_sph).
; db_ph — плоскость рисования: 0 — C000h, 20h — E000h; db_vph — какую показать; db_sph — какая показана.

; db_tog: сменить плоскость рисования: в командах рисования обзора старший байт адреса — исключающим ИЛИ 20h.
db_tog:
	ld	a, (db_ph)
	xor	0x20
	ld	(db_ph), a
	ld	hl, db_sites
	ld	b, DB_NS
dt_l:
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	inc	hl
	ld	a, (de)
	xor	0x20
	ld	(de), a
	dec	b
	jp	nz, dt_l
	ret
db_sites:
	dw	col_p1 + 1, col_p2 + 1, col_p3 + 1, col_p4 + 1, tt_col + 1
	ifdef	PCIRC
	dw	pc_cs + 1, pc_ps + 1, pc_s1 + 1, pc_s2 + 1, pc_s3 + 1, pc_s4 + 1
	endif
DB_NS		equ	($ - db_sites) / 2

; db_c0: рисовать в C000h и показать её (экран очищается, TTX66).
db_c0:
	ld	a, (db_ph)
	or	a
	call	nz, db_tog
	xor	a
	ld	(db_off), a
; db_show: показать плоскость A (0 — C000h, 20h — E000h): палитра для неё — в pal_regs, запишет прерывание кадра.
; Сначала pal_dirty = 0: прерывание посреди расчёта не запишет наполовину готовую палитру.
db_show:
	ld	hl, pal_dirty
	ld	(hl), 0
	ld	(db_vph), a
	jp	db_pal

; Название вида (строка 1, столбцы 11–22) печатается только при смене экрана (BOX) и запоминается: печать
; знаков словаря — около 45 тыс. тактов, перенос — около 3 тыс. db_tsave: экран -> db_ttl, db_tput: обратно.
DB_TC		equ	11
db_tsave:
	call	db_tadr
ts_c:
	ld	l, 255 - 8
	ld	b, 8
ts_r:
	ld	a, (hl)
	ld	(de), a
	inc	de
	dec	l
	dec	b
	jp	nz, ts_r
	inc	h
	dec	c
	jp	nz, ts_c
	ret
db_tput:
	call	db_tadr
tp_c:
	ld	l, 255 - 8
	ld	b, 8
tp_r:
	ld	a, (de)
	ld	(hl), a
	inc	de
	dec	l
	dec	b
	jp	nz, tp_r
	inc	h
	dec	c
	jp	nz, tp_c
	ret
db_tadr:
	ld	a, (db_ph)
	or	high SCR_VIEW + DB_TC
	ld	h, a
	ld	de, db_ttl
	ld	c, 12
	ret
db_ttl:	ds	12 * 8

; db_begin: начало прохода в виде из корабля (см. выше). Портит всё.
db_begin:
	ld	a, (QQ11)
	ld	hl, db_off		; гибель: экран без буфера (рамки нет, надпись)
	or	(hl)
	ret	nz
	ld	hl, db_vph
dbw:
	ld	a, (db_sph)		; прошлый кадр ещё не показан — в его плоскости рисовать нельзя
	cp	(hl)
	jp	nz, dbw
	call	db_tog
	call	db_cls
	call	db_tput			; до всего прочего: переносится не исключающим ИЛИ
	ld	hl, FRIN		; корабли: «на экране» (бит 3) и «облако на экране» (бит 6) снять
	ld	de, K_ + 31
	ld	b, NOSH + 1
db_s:
	ld	a, (hl)
	dec	a
	cp	0x7F
	jp	nc, db_s2		; пусто, планета, солнце
	ld	a, (de)
	and	0xB7
	ld	(de), a
db_s2:
	inc	hl
	ld	a, e
	add	a, NI
	ld	e, a
	jp	nc, $ + 4
	inc	d
	dec	b
	jp	nz, db_s
	call	WP1			; окружности планеты нет
	ld	a, (LSX)		; солнце — те же строки LSO
	inc	a
	call	nz, db_sun
	ld	a, (NOSTM)		; пыль — на прежних местах
	ld	b, a
	ld	e, 0
	call	da_l
	ld	a, (st_fx)
	or	a
	call	nz, st_dots
	ld	a, (LAS2)
	or	a
	call	nz, LASLI2
	call	SIGHT
	ld	hl, (XC)		; XC, YC и QQ17 — как были
	push	hl
	ld	a, (QQ17)
	push	af
	ld	a, (DLY)
	or	a
	jp	z, db_nm
	ld	a, 9
	ld	(XC), a
	ld	a, 22
	ld	(YC), a
	xor	a
	ld	(QQ17), a
	ld	a, (de_)		; приписка « DESTROYED» — как на экране, счётчик не трогать
	push	af
	ld	a, (MCH)
	call	mes9
	pop	af
	ld	(de_), a
db_nm:
	ld	a, (QQ22 + 1)
	or	a
	ld	b, a
	call	nz, ee3
	pop	af
	ld	(QQ17), a
	pop	hl
	ld	(XC), hl
	ret

; db_sun: строки солнца по LSO — в плоскость рисования (sr_wps без обнуления LSO).
db_sun:
	ld	hl, 0x0077		; sw_w: ld (hl),0 -> ld (hl),a; nop
	ld	(sw_w), hl
	ld	c, DASH_Y - 1
	ld	d, 0
	call	sr_wps
	ld	hl, 0x0036
	ld	(sw_w), hl
	ret

; db_cls: обзор плоскости рисования (строки 0–191) — нули; рамка как у BOX: строка 0 и точки x = 0, 1, 254, 255.
; Столбец пишется стеком сверху вниз до байта 5Eh, остаток — по одному байту при обычном стеке: прерывание кадра
; (до 20 байт стека) попадает только в ещё не очищенные байты того же столбца.
db_cls:
	ld	a, (db_ph)
	or	high SCR_VIEW
	ld	bc, 0xFFC0
	ld	de, 0xC0C0
	call	dc_col
	ld	bc, 0xFF00
	ld	de, 0
dc_m:
	call	dc_col
	ld	h, a
	and	0x1F
	cp	31
	ld	a, h
	jp	nz, dc_m
	ld	bc, 0xFF03
	ld	de, 0x0303
; dc_col: столбец A: строки 0 и 1 — B и C, остальные — E. На выходе A + 1. Портит HL.
dc_col:
	ld	hl, 0
	add	hl, sp
	ld	(db_sp), hl
	ld	h, a
	inc	h
	ld	l, 0
	ld	sp, hl
	push	bc
	ld	l, 10
dc_p:
	dup	8
	push	de
	edup
	dec	l
	jp	nz, dc_p
	ld	hl, (db_sp)
	ld	sp, hl
	ld	h, a
	ld	l, 0x5D
	dup	30
	ld	(hl), e
	dec	l
	edup
	inc	a
	ret

; db_pal: палитра по db_vph: регистр с битом показываемой плоскости — pal_fg, прочие — pal_bg.
db_pal:
	ld	a, (db_vph)
	or	a
	ld	c, 2			; C000h — бит 1 номера регистра
	jp	z, dp_c
	ld	c, 1
dp_c:
	ld	hl, pal_regs + 15
	ld	b, 15
dp_l:
	ld	a, b
	and	c
	ld	a, (pal_bg)
	jp	z, dp_s
	ld	a, (pal_fg)
dp_s:
	ld	(hl), a
	dec	hl
	dec	b
	jp	p, dp_l
	ld	a, 1
	ld	(pal_dirty), a
	ret
