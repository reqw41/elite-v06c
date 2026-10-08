; Миссии версии для ZX Spectrum: «Сверхновая», «Скрывающее устройство», «Захват станции».
; Логика выписана из исходников Elite Legend (наследник движка ZX), тексты — из снимка памяти ZX 48K
; (docs/research/zx48_texts.md). На BBC этих миссий нет — эталона нет, сверка своими сценариями: v06c/test/mis.mjs.
; Состояние лежит в свободных байтах файла командира (сохраняется и считается в контрольной сумме):
;   MISF (TP)      бит 7 — пора выдавать миссию (ставится при каждых 256 победах), бит 0, 1, 2 — миссии 1, 2, 3 уже
;                  выдавались, бит 3 — есть скрывающее устройство, бит 4 — есть глушилка ECM, бит 5 — идёт охота
;                  на Asp со скрывающим устройством
;   M1ST (LASER+4) «Сверхновая»: 0 — нет, 1 — мы в системе, 2 — взлетели, солнце растёт; бит 7 — беженцы на борту
;   M3ST (LASER+5) «Захват станции»: см. ниже
;   M3PL           номер системы-цели в галактике
; Пока все эти байты нулевые, ни одна вставка в код игры ничего не меняет — сценарии сверки идут как на BBC.
MISF	equ	TP
M1ST	equ	LASER + 4
M3ST	equ	LASER + 5
M3PL	equ	ESCP + 1

; mis_due: 256 побед — пора выдавать следующую миссию. Сохраняет всё.
mis_due:
	push	af
	push	hl
	ld	hl, MISF
	ld	a, (hl)
	or	0x80
	ld	(hl), a
	pop	hl
	pop	af
	ret

; mis_arrive: прибытие после прыжка в ту же галактику: выдать очередную миссию, если пора.
mis_arrive:
	ld	hl, MISF
	ld	a, (hl)
	or	a
	ret	p
	and	0x7F
	ld	(hl), a
	rra
	jp	nc, mar_1
	ret
mar_1:					; «Сверхновая»: топлива нет, со станции просят о помощи
	ld	a, (hl)
	or	1
	ld	(hl), a
	ld	a, 1
	ld	(M1ST), a
	xor	a
	ld	(QQ14), a
	ret

; mis_gal: прыжок в другую галактику: текущие миссии на этом кончаются (беженцы остаются на борту).
mis_gal:
	ld	hl, M1ST
	ld	a, (hl)
	and	0x80
	ld	(hl), a
	ret

; mis_launch: взлёт со станции: в системе сверхновой с этого момента растёт солнце.
mis_launch:
	ld	hl, 0
	ld	(nova_t), hl
	ld	hl, M1ST
	ld	a, (hl)
	and	0x7F
	cp	1
	ret	nz
	inc	(hl)
	ret

; mis_fly: проход цикла полёта. Сохраняет A и флаги (перенос дальше идёт в генератор случайных чисел).
mis_fly:
	push	af
	ld	a, (M1ST)
	and	0x7F
	jp	z, mf_x
	cp	2
	jp	nz, mf_may
	ld	hl, (nova_t)		; сверхновая: около 770 проходов до взрыва, солнце надвигается
	inc	hl
	ld	(nova_t), hl
	ld	a, h
	cp	3
	jp	nc, mf_dead
	ld	a, l
	and	7
	jp	nz, mf_x
	ld	a, (FRIN + 1)
	cp	129
	jp	nz, mf_x
	ld	hl, K_ + NI + 8		; расстояние до солнца — 24 бита, знак в бите 7 старшего байта
	ld	a, (hl)
	and	0x7F
	jp	z, mf_near
	dec	(hl)
	jp	mf_x
mf_near:
	dec	hl
	ld	a, (hl)
	cp	0x30
	jp	c, mf_x
	sub	8
	ld	(hl), a
	jp	mf_x
mf_may:					; до взлёта: раз в 256 проходов — призыв о помощи
	ld	hl, mf_cnt
	inc	(hl)
	jp	nz, mf_x
	ld	a, 1
	call	messx
mf_x:
	pop	af
	ret
mf_dead:
	pop	af
	jp	DEATH

; mis_dock: стыковка: вопросы и награды миссий.
mis_dock:
	ld	a, (M1ST)
	or	a
	ret	z
	jp	m, md_ref
	ld	hl, t_nova		; в системе сверхновой: возьмём беженцев?
	call	mis_scr
	call	ask_yn
	ret	nc
	ld	hl, M1ST
	ld	a, (hl)
	or	0x80
	ld	(hl), a
	ld	hl, QQ20		; груз — за борт, трюм занят людьми (tnpr больше ничего не пустит)
	ld	b, 17
	xor	a
md_cl:
	ld	(hl), a
	inc	hl
	dec	b
	jp	nz, md_cl
	ret
md_ref:					; беженцы на борту
	and	0x7F
	ret	nz			; всё ещё в системе сверхновой
	ld	(M1ST), a
	ld	a, 100			; награда — 100 г драгоценных камней
	ld	(QQ20 + 15), a
	ld	hl, t_saved
	call	mis_scr
	jp	TT217

; mis_pod: спасательная капсула: беженцы остались на корабле.
mis_pod:
	ld	hl, M1ST
	ld	a, (hl)
	and	0x7F
	ld	(hl), a
	ret

; mis_scr: чистый экран и текст с адреса HL (13 — новая строка, 0 — конец).
mis_scr:
	push	hl
	ld	a, 1
	call	TT66
	ld	a, 8
	ld	(YC), a
	ld	a, 2
	ld	(XC), a
	pop	hl
mis_str:
	ld	a, (hl)
	or	a
	ret	z
	inc	hl
	cp	13
	jp	nz, ms_ch
	push	hl
	ld	hl, YC
	inc	(hl)
	inc	(hl)
	ld	a, 2
	ld	(XC), a
	pop	hl
	jp	mis_str
ms_ch:
	call	TT26
	jp	mis_str
; ask_yn: ждать клавишу; перенос 1 — Y.
ask_yn:
	call	TT217
	or	0x20
	cp	'y'
	scf
	ret	z
	or	a
	ret

; messx: своё сообщение номер A внизу обзора на 22 прохода (как MESS; прежнее сообщение стирается).
messx:
	ld	d, a
	ld	a, (DLY)
	or	a
	jp	z, mx_new
	push	de
	ld	a, (MCH)
	call	mes9
	pop	de
mx_new:
	ld	a, d
	ld	(mch_x), a
	xor	a
	ld	(QQ17), a
	ld	a, 22
	ld	(DLY), a
; mes9x: напечатать (или стереть повторной печатью) своё сообщение mch_x.
mes9x:
	ld	a, 2
	ld	(XC), a
	ld	a, 22
	ld	(YC), a
	ld	a, (mch_x)
	add	a, a
	ld	e, a
	ld	d, 0
	ld	hl, mx_tab - 2
	add	hl, de
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a
	jp	mis_str
mx_tab:
	dw	t_mayday
mch_x:	db	0			; номер своего сообщения на экране (0 — на экране слово игры MCH)
mf_cnt:	db	0
nova_t:	dw	0
t_mayday:
	db	"MAYDAY * CORIOLIS IN DANGER *", 0
t_nova:
	db	"THE SUN IS GOING NOVA!", 13, 13, "WILL YOU SAVE US (Y/N)?", 0
t_saved:
	db	"YOU HAVE SAVED OUR LIVES!", 13, 13, "THANK YOU, COMMANDER.", 0
