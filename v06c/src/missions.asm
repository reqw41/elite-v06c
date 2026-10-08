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
	xor	a
	ld	(asp_out), a
	ld	a, (M3ST)		; «Захват станции»: 6 — станция взорвана, после прыжка 5 (ждёт награда);
	or	a			; 4 — улетели из системы цели, не выполнив; 3 — прилетели в систему цели?
	jp	z, mar_due
	cp	6
	jp	z, mar_35
	cp	4
	jp	nz, mar_t
	dec	a
	ld	(M3ST), a
mar_t:
	cp	3
	jp	nz, mar_due
	call	m3_seeds		; семена системы-цели — в QQ15 (прежние — на стеке)
	ld	a, (QQ15 + 3)
	ld	hl, QQ0
	cp	(hl)
	jp	nz, mar_r
	ld	a, (QQ15 + 1)
	inc	hl
	cp	(hl)
	jp	nz, mar_r
	ld	a, 4
	ld	(M3ST), a
mar_r:
	call	m3_back
	jp	mar_due
mar_35:
	dec	a
	ld	(M3ST), a
mar_due:
	ld	hl, MISF
	ld	a, (hl)
	or	a
	ret	p
	and	0x7F
	ld	(hl), a
	rra
	jp	nc, mar_1
	rra
	jp	nc, mar_2
	rra
	ret	c
	ld	a, (hl)			; «Захват станции»: цель — случайная система галактики
	or	4
	ld	(hl), a
	ld	a, 1
	ld	(M3ST), a
	call	mis_rnd
	ld	(M3PL), a
	ret
mar_2:					; «Скрывающее устройство»: где-то рядом бродит Asp с ним
	ld	a, (hl)
	or	0x22
	ld	(hl), a
	ret
mar_1:					; «Сверхновая»: топлива нет, со станции просят о помощи
	ld	a, (hl)
	or	1
	ld	(hl), a
	ld	a, 1
	ld	(M1ST), a
	ld	(leak_say), a		; «FUEL LEAK» — на первом проходе полёта
	xor	a
	ld	(QQ14), a
	ret

; mis_gal: прыжок в другую галактику: текущие миссии на этом кончаются (беженцы остаются на борту).
mis_gal:
	ld	hl, M1ST
	ld	a, (hl)
	and	0x80
	ld	(hl), a
	xor	a
	ld	(M3ST), a
	ret

; mis_launch: взлёт со станции: в системе сверхновой с этого момента растёт солнце.
mis_launch:
	xor	a
	ld	(cloak_on), a
	ld	(asp_out), a
	ld	hl, 0
	ld	(nova_t), hl
	ld	hl, M1ST
	ld	a, (hl)
	and	0x7F
	cp	1
	ret	nz
	inc	(hl)
	ret

; mis_fly: проход цикла полёта. Сохраняет все регистры и флаги (перенос дальше идёт в генератор случайных чисел).
mis_fly:
	push	af
	ld	a, (MISF)
	ld	hl, M1ST
	or	(hl)
	inc	hl
	or	(hl)			; M3ST — следом за M1ST
	jp	z, mf_x			; миссий нет и не было: дальше ничего не трогаем
	push	bc
	push	de
	call	mf_nova
	call	mf_m3
	call	mf_cloak
	pop	de
	pop	bc
mf_x:
	pop	af
	ret
; «Сверхновая»
mf_nova:
	ld	hl, leak_say
	ld	a, (hl)
	or	a
	jp	z, mfn_1
	ld	(hl), 0
	ld	a, 6
	call	messx
mfn_1:
	ld	a, (M1ST)
	and	0x7F
	ret	z
	cp	2
	jp	nz, mf_may
	ld	hl, (nova_t)		; около 770 проходов до взрыва, солнце надвигается
	inc	hl
	ld	(nova_t), hl
	ld	a, h
	cp	3
	jp	nc, mf_dead
	ld	a, l
	and	7
	ret	nz
	ld	a, (FRIN + 1)
	cp	129
	ret	nz
	ld	hl, K_ + NI + 8		; расстояние до солнца — 24 бита, знак в бите 7 старшего байта
	ld	a, (hl)
	and	0x7F
	jp	z, mf_near
	dec	(hl)
	ret
mf_near:
	dec	hl
	ld	a, (hl)
	cp	0x30
	ret	c
	sub	8
	ld	(hl), a
	ret
mf_may:					; до взлёта: раз в 256 проходов — призыв о помощи
	ld	a, 1
mf_say:					; сообщение A раз в 256 проходов
	ld	hl, mf_cnt
	inc	(hl)
	ret	nz
	jp	messx
mf_dead:
	pop	hl			; адрес возврата в mis_fly
	pop	de
	pop	bc
	pop	af
	jp	DEATH
; «Захват станции»: до принятия — призыв о помощи; в системе цели станция враждебна
mf_m3:
	ld	a, (M3ST)
	cp	1
	ld	a, 2
	jp	z, mf_say
	ld	a, (M3ST)
	cp	4
	ret	nz
	ld	a, (FRIN + 1)
	cp	8
	ret	nz
	ld	hl, K_ + NI + 32
	ld	a, (hl)
	or	0x80
	ld	(hl), a
	ret
; Скрывающее устройство: клавиша Y включает и выключает; пока включено — энергия убывает на единицу за проход,
; экран голубой, противники не стреляют. Включается при энергии от 160, само выключается ниже 64.
mf_cloak:
	ld	a, (MISF)
	and	8
	ret	z
	ld	b, 0x44			; клавиша Y
	call	DKS4
	ld	hl, cloak_key
	ld	b, (hl)
	ld	(hl), a
	or	a
	jp	p, mc_run		; не нажата
	ld	a, b
	or	a
	jp	m, mc_run		; держат с прошлого прохода
	ld	a, (cloak_on)
	or	a
	jp	nz, mc_off
	ld	a, (ENERGY)
	cp	160
	jp	c, mc_run
	ld	a, 1
	ld	(cloak_on), a
	ld	a, 4
	call	messx
mc_run:
	ld	a, (cloak_on)
	or	a
	ret	z
	ld	hl, ENERGY
	ld	a, (hl)
	cp	64
	jp	c, mc_off
	dec	(hl)
	ld	hl, pal_cloak
	ld	a, 3
	jp	pal_fx
mc_off:
	xor	a
	ld	(cloak_on), a
	ld	a, 5
	jp	messx

; mis_pick: A — тип охотника, выбранный игрой. Пока идёт охота за скрывающим устройством и Asp ещё не выходил
; в этой системе, в одном случае из восьми вместо охотника появляется он (тип 17). Перенос сохраняется.
mis_pick:
	push	af
	ld	a, (MISF)
	and	0x20
	jp	z, mp_keep
	ld	a, (asp_out)
	or	a
	jp	nz, mp_keep
	call	mis_rnd
	and	7
	jp	nz, mp_keep
	inc	a
	ld	(asp_out), a
	pop	af
	ld	a, 17
	ret
mp_keep:
	pop	af
	ret
; mis_cloakgot: подобран контейнер со скрывающим устройством.
mis_cloakgot:
	ld	hl, MISF
	ld	a, (hl)
	or	8
	and	0xDF
	ld	(hl), a
	ld	a, 3
	jp	messx
; zx_leak: утечка топлива, как на ZX Spectrum: при уроне по энергии в одном случае из 64 топливо пропадает целиком.
; Случайное число — своё. Сохраняет все регистры и флаги.
zx_leak:
	push	af
	call	mis_rnd
	and	63
	jp	nz, zl_x
	ld	a, (QQ14)
	or	a
	jp	z, zl_x
	xor	a
	ld	(QQ14), a
	push	bc
	push	de
	push	hl
	ld	a, 6
	call	messx
	pop	hl
	pop	de
	pop	bc
zl_x:
	pop	af
	ret
; mis_rnd: свой генератор случайных чисел (игровой не трогаем): A.
mis_rnd:
	push	hl
	ld	hl, (mis_seed)
	add	hl, hl
	jp	nc, mr_1
	ld	a, l
	xor	0x2D
	ld	l, a
mr_1:
	ld	(mis_seed), hl
	ld	a, h
	pop	hl
	ret
; m3_seeds: QQ15 = семена системы номер M3PL (прежние QQ15 — в m3_keep). m3_back: вернуть QQ15.
m3_seeds:
	ld	hl, QQ15
	ld	de, m3_keep
	ld	b, 6
	call	ll9_cp
	call	TT81
	ld	a, (M3PL)
	or	a
	ret	z
m3s_l:
	push	af
	call	TT20
	pop	af
	dec	a
	jp	nz, m3s_l
	ret
m3_back:
	ld	hl, m3_keep
	ld	de, QQ15
	ld	b, 6
	jp	ll9_cp

; mis_dock: стыковка: вопросы и награды миссий.
mis_dock:
	call	md_m3
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

; «Захват станции» на станции: предложение (состояние 1) и награда (состояние 5).
md_m3:
	ld	a, (M3ST)
	cp	1
	jp	z, md_offer
	cp	5
	ret	nz
	xor	a
	ld	(M3ST), a
	ld	hl, t_award
	call	mis_scr
	jp	TT217
md_offer:
	ld	hl, t_wanted
	call	mis_scr
	call	ask_yn
	jp	c, md_take
	xor	a
	ld	(M3ST), a
	ret
md_take:
	ld	a, 3
	ld	(M3ST), a
	ld	hl, MISF
	ld	a, (hl)
	or	0x10
	ld	(hl), a
	ld	hl, t_brief
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
	cp	1
	jp	z, ms_name
	call	TT26
	jp	mis_str
ms_name:				; название системы-цели миссии 3
	push	hl
	call	m3_seeds
	xor	a
	ld	(QQ17), a
	call	cpl_
	call	m3_back
	pop	hl
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
	dw	t_mayday, t_invaded, t_cloak, t_clon, t_cloff, t_leak, t_dock
mch_x:	db	0			; номер своего сообщения на экране (0 — на экране слово игры MCH)
mf_cnt:	db	0
leak_say:	db	0
cloak_on:	db	0		; скрывающее устройство включено
cloak_key:	db	0
asp_out:	db	0			; Asp со скрывающим устройством уже выходил в этой системе
mis_seed:	dw	0x3C91
m3_keep:	ds	6
pal_cloak:
	db	0x00, 0x07, 0xF8, 0x38	; белое — голубым
nova_t:	dw	0
t_mayday:
	db	"MAYDAY * CORIOLIS IN DANGER *", 0
t_nova:
	db	"THE SUN IS GOING NOVA!", 13, 13, "WILL YOU SAVE US (Y/N)?", 0
t_saved:
	db	"YOU HAVE SAVED OUR LIVES!", 13, 13, "THANK YOU, COMMANDER.", 0
t_invaded:
	db	"MAYDAY * ", 1, " INVADED *", 0
t_cloak:
	db	"CLOAKING DEVICE", 0
t_clon:
	db	"CLOAKING DEVICE ON", 0
t_cloff:
	db	"CLOAKING DEVICE OFF", 0
t_wanted:
	db	"WANTED BY GALCOP:", 13, " A BRAVE COMMANDER", 13, " FOR A SPECIAL MISSION", 13, 13, "ARE YOU INTERESTED (Y/N)?", 0
t_brief:
	db	"THE THARGONS ARE USING THE", 13, "SPACE STATION AT ", 1, 13, "AS A BASE FOR THEIR INVASION.", 13
	db	"YOUR MISSION: TO DESTROY IT.", 13, "TAKE THIS E.C.M. JAMMER", 13, "(YOU WILL NEED IT!) GOOD LUCK!", 0
t_award:
	db	"IN APPRECIATION OF YOUR", 13, "EXCEPTIONAL COURAGE THE", 13, "INHABITANTS OF ", 1, 13, "AWARD YOU THEIR HIGHEST", 13, "HONOUR. LIVE LONG AND PROSPER!", 0
t_leak:
	db	"FUEL LEAK!", 0
t_dock:
	db	"DOCKING COMPUTERS ON", 0
