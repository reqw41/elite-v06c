; Миссии версии для ZX Spectrum: «Сверхновая», «Скрывающее устройство», «Захват станции».
; Логика выписана из исходников Elite Legend (наследник движка ZX), тексты — из снимка памяти ZX 48K
; (docs/research/zx48_texts.md). На BBC этих миссий нет — эталона нет, сверка своими сценариями: v06c/test/mis.mjs.
; Состояние лежит в свободных байтах файла командира (сохраняется и считается в контрольной сумме):
;   MISF (TP)      бит 7 — пора выдавать миссию (ставит mis_count по счётчику прибытий), бит 0, 1, 2 — миссии 1, 2, 3 уже
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

TFR	equ	ESCP + 4	; младший байт счёта очков
MJC	equ	ESCP + 3	; счётчик прибытий после прыжка (вне первой галактики)

; mis_count: выдача миссий как в ZX 48K и Elite Legend — по счётчику прибытий: «Сверхновая» — с 32-го прибытия,
; «Скрывающее устройство» — со 128-го, «Захват станции» — с 254-го (сравнивается байт счётчика); в первой
; галактике миссий нет. Пока идёт охота на «Констриктора» или на борту планы таргоидов, счёт стоит: «Сверхновая»
; унесла бы в другую галактику. Только обычный образ; ставит бит 7 MISF — «пора выдавать».
	ifndef	SCHED
mis_count:
	ld	a, (GCNT)
	or	a
	ret	z
	ld	a, (DTP)
	ld	c, a
	and	3
	dec	a
	ret	z
	ld	a, c
	and	0x0C
	cp	8
	ret	z
	ld	hl, MJC
	inc	(hl)
	ld	c, (hl)
	ld	hl, MISF
	ld	a, (hl)
	ld	b, 32
	rra
	jp	nc, mc_t
	ld	b, 128
	rra
	jp	nc, mc_t
	ld	b, 254
	rra
	ret	c
mc_t:
	ld	a, c
	cp	b
	ret	c
	ld	a, (hl)
	or	0x80
	ld	(hl), a
	ret
; Отладочный вход (на паузе): M — выдать очередную миссию версии ZX при следующем прибытии, где бы мы ни были;
; K — добавить 256 побед (условие миссий дисковой версии). Гудок и короткая задержка. A сохраняется.
mis_dbg_m:
	ld	hl, MISF
	ld	a, (hl)
	or	0x80
	ld	(hl), a
	jp	mis_dbg
mis_dbg_k:
	ld	hl, MISF		; условие «Планов таргоидов»: «Сверхновая» уже выдавалась
	ld	a, (hl)
	or	1
	ld	(hl), a
	ld	hl, TALLY + 1
	inc	(hl)
mis_dbg:
	push	bc
	ld	a, 7
	call	TT26
	ld	c, 25
	call	DELAY
	pop	bc
	ld	a, b
	ret
	endif

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
	ifndef	SCHED
	call	mis_count
	endif
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
	call	mis_rnd			; цель — случайная система галактики (в ZX 48K — система 0)
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
	ifndef	SCHED
	ld	(FIST), a		; как в ZX 48K: галактический прыжок обнуляет правовой статус
	endif
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

	ifdef	SCHED			; в обычном образе Asp выходит по правилу ZX 48K — в zx_spawn
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
	endif
; mis_cloakgot: подобран контейнер со скрывающим устройством.
mis_256:				; награда рейтингом: 256 побед
	ld	hl, TALLY + 1
	inc	(hl)
	ret
mis_cloakgot:
	call	mis_256
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
; zx_plate: при гибели корабля в половине случаев остаётся пластина обшивки (тип 19). Случайное число — своё.
; Блок гибнущего корабля — в INWK, как для SFS1. Сохраняет A и флаги.
zx_plate:
	push	af
	call	mis_rnd
	rra
	jp	nc, zpl_x
	ld	b, 19
	xor	a
	call	SFS1
zpl_x:
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
	ld	a, MZ_NOVA		; в системе сверхновой: возьмём беженцев?
	call	mz_scr
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
	ld	a, 100			; награда, как в ZX 48K: 100 г драгоценных камней, большой трюм
	ld	(QQ20 + 15), a		; и 256 побед
	ld	a, 37
	ld	(CRGO), a
	call	mis_256
	ld	a, MZ_SAVED
	call	mz_scr
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
	call	mis_256
	ld	a, MZ_AWARD
	call	mz_scr
	jp	TT217
md_offer:
	ld	a, MZ_WANTED
	call	mz_scr
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
	ld	a, MZ_BRIEF
	call	mz_scr
	jp	TT217

; mis_pod: спасательная капсула: беженцы остались на корабле.
mis_pod:
	ld	hl, M1ST
	ld	a, (hl)
	and	0x7F
	ld	(hl), a
	ret

; mz_scr: чистый экран и текст номер A второй таблицы словаря (tkn1.asm). mz_str: текст номер A с текущего места.
mz_scr:
	push	af
	ld	a, 1
	call	TT66
	ld	a, 8
	ld	(YC), a
	ld	a, 2
	ld	(XC), a
	pop	af
mz_str:
	ld	hl, mz_tkn
	jp	pd_tok_hl
mz_nl:					; управляющий код 10: новая строка текста миссии — через строку, со столбца 2
	ld	hl, YC
	inc	(hl)
	inc	(hl)
	ld	a, 2
	ld	(XC), a
	ret
mz_name:				; управляющий код 11: название системы-цели миссии 3
	call	m3_seeds
	xor	a
	ld	(QQ17), a
	call	cpl_
	jp	m3_back
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
	add	a, MZ_MAYDAY - 1
	jp	mz_str
; Очки за объект, делённые на 4 (половина числа из заголовка модели ZX 48K; для типов, которых там нет, — из
; Elite Legend). Камни (астероид, осколок, валун) и станция — 0. Таргоид: 1020 вместо 1024.
ex_pts:	db	0
	db	32, 10, 112, 112, 112, 255, 64		; Sidewinder, Viper, Mamba, Python, Cobra, Thargoid, Cobra-торговец
	db	0, 56, 0, 4, 12, 6			; станция, ракета, астероид, контейнер, таргон, капсула
	db	32, 104, 96, 104, 4, 4, 0, 0		; Krait, Asp, Fer-de-Lance, Asp с устройством, контейнер, пластина, осколок, валун
	db	34, 72, 96, 48, 112, 124, 144		; Adder, Gecko, Cobra Mk I, Worm, Moray, Boa, Anaconda
	db	48, 32, 74				; Shuttle, Transporter, Constrictor
ex_t:	db	0			; тип цели, сбитой ракетой (для счёта очков)
ex_s:	db	0			; место цели ракеты · 2
mch_x:	db	0			; номер своего сообщения на экране (0 — на экране слово игры MCH)
mf_cnt:	db	0
leak_say:	db	0
cloak_on:	db	0		; скрывающее устройство включено
cloak_key:	db	0
asp_out:	db	0			; Asp со скрывающим устройством уже выходил в этой системе
mis_seed:	dw	0x3C91
pal_cloak:
	db	0x00, 0x07, 0xF8, 0x38	; белое — голубым
nova_t:	dw	0
