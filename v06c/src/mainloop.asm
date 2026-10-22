; Главный цикл (пока — стоянка на станции) и клавиатура: BAY, MLOOP, FRCE, TT102, TT17, DOKEY, DKS1, DKS4, U%.
; Перенесено близко к тексту BBC; сверка — v06c/test/t18.mjs (от включения до проходов главного цикла).
K_F0		equ	0x20
K_F1		equ	0x71
K_F2		equ	0x72
K_F3		equ	0x73
K_F4		equ	0x14
K_F5		equ	0x74
K_F6		equ	0x75
K_F7		equ	0x16
K_F8		equ	0x76
K_F9		equ	0x77

; BAY: мы на станции: QQ12 = FFh, в главный цикл с «нажатой» f8 — экран статуса.
BAY:
	ld	a, 0xFF
	ld	(QQ12), a
	ld	a, K_F8
	jp	FRCE

; MLOOP: проход главного цикла: остывание лазера, панель, пауза на экранах с текстом, клавиши, разбор клавиши.
MLOOP:
	ld	sp, STACK
	ld	hl, GNTMP
	ld	a, (hl)
	or	a
	jp	z, ee20
	dec	(hl)
ee20:
	call	DIALS
	ld	a, (QQ11)
	or	a
	jp	z, ml_keys
	ld	hl, PATG
	and	(hl)
	rra
	jp	c, ml_keys
	ld	c, 2			; на экранах с текстом — пауза в два кадра (на BBC — DELAY-5)
	call	DELAY
ml_keys:
	call	TT17
FRCE:
	call	TT102
	ld	a, (QQ12)
	or	a
	jp	nz, MLOOP
	jp	TT100

; TT102: разбор клавиши A (номер BBC). Экраны и действия, до которых перенос не дошёл, — заглушки.
TT102:
	cp	K_F8
	jp	z, STATUS
	cp	K_F4
	jp	z, TT22
	cp	K_F5
	jp	z, TT23
	cp	K_F6
	jp	nz, tt92
	call	TT111
	jp	TT25
tt92:
	cp	K_F9
	jp	z, TT213
	cp	K_F7
	jp	z, TT167
	cp	K_F0
	jp	z, TT110
	ld	d, a
	ld	a, (QQ12)
	or	a
	ld	a, d
	jp	p, insp
	cp	K_F3
	jp	z, EQSHP
	cp	K_F1
	jp	z, TT219
	cp	0x47
	jp	z, SVE
	cp	K_F2
	jp	z, TT208
	jp	label_3			; на BBC здесь BNE LABEL_3 при несовпадении с f2
insp:
	cp	K_F1
	jp	c, label_3
	cp	K_F3 + 1
	jp	nc, label_3
	and	3
	ld	b, a
	jp	LOOK1
label_3:
	cp	0x54
	jp	z, hyp
	cp	0x32
	jp	z, t95_d
	cp	0x43			; F на картах — поиск системы по названию
	jp	z, hme_key
	ld	(T1), a
	ld	a, (QQ11)
	and	0xC0
	jp	z, tt107
	ld	a, (QQ22 + 1)
	or	a
	jp	nz, tt107
	ld	a, (T1)
	cp	0x36
	jp	nz, ee2
	call	TT103
	call	ping
	call	TT103
ee2:
	call	TT16
tt107:
	ld	a, (QQ22 + 1)
	or	a
	ret	z
	ld	hl, QQ22
	dec	(hl)
	ret	nz
	ld	a, (QQ22 + 1)
	dec	a
	ld	b, a
	ifdef	ORAND
	call	ee3e			; прежнее число стереть — очисткой
	else
	call	ee3
	endif
	ld	a, 5
	ld	(QQ22), a
	ld	a, (QQ22 + 1)
	ld	b, a
	call	ee3
	ld	hl, QQ22 + 1
	dec	(hl)
	ret	nz
	jp	TT18
t95_d:
	ld	a, (QQ11)
	and	0xC0
	ret	z
	call	hm
t95_p:
	ld	(QQ17), a
	call	cpl_
	ld	a, 0x80
	ld	(QQ17), a
	ld	a, 1
	ld	(XC), a
	ld	hl, YC
	inc	(hl)
	jp	TT146

; TT17: клавиши и курсор: A = KL (нажатая клавиша), X, Y = -1, 0, 1 по стрелкам. Джойстик — этап P6.
TT17:
	call	DOKEY
	ld	a, (KL)
	ld	bc, 0
	cp	0x19
	jp	nz, tj_r
	dec	b
tj_r:
	cp	0x79
	jp	nz, tj_u
	inc	b
tj_u:
	cp	0x39
	jp	nz, tj_d
	inc	c
tj_d:
	cp	0x29
	jp	nz, tj_e
	dec	c
tj_e:
	ifndef	SCHED			; как в дисковой версии: с нажатой СС (на BBC — SHIFT) курсор идёт вчетверо быстрее
	ld	d, a
	ld	a, (kb_mod)
	and	0x20
	ld	a, d
	ret	z
	ld	a, b
	add	a, a
	add	a, a
	ld	b, a
	ld	a, c
	add	a, a
	add	a, a
	ld	c, a
	ld	a, d
	endif
	ret

; U%: обнулить журнал клавиш KL+1..KL+15.
U_:
	ld	hl, KL + 1
	ld	b, 15
	xor	a
u_l:
	ld	(hl), a
	inc	hl
	dec	b
	jp	nz, u_l
	ld	c, a
	ret

; DOKEY: опрос клавиш полёта в журнал KL, крен и тангаж JSTX, JSTY по клавишам (js_upd), нажатая клавиша в KL.
; Пауза — в DK4 (FREEZE). Джойстик — этап P6.
DOKEY:
	call	U_
	ld	c, 7
dkl2:
	call	DKS1
	dec	c
	jp	nz, dkl2
	ifdef	SCHED
	call	js_upd			; крен и тангаж по клавишам (dockit.asm)
	else
	ld	a, (auto)		; автопилот стыковки дисковой версии «нажимает» клавиши; dk_auto кончается js_upd.
	or	a			; Без автопилота крен и тангаж ведёт обработчик кадра (js_tick) — каждый кадр
	call	nz, dk_auto
	endif
DK4:
	call	RDKEY
	ld	a, b
	ld	(KL), a
	cp	0x69			; COPY (на Векторе — СТР): пауза
	jp	nz, dk2
FREEZE:					; пауза: S и Q — звук, клавиши настроек, АР2 — начать заново, DELETE (ЗБ) — дальше
	ifndef	SCHED
	xor	a			; на паузе клавиши как на BBC (fly_keys не переводит)
	ld	(fly_on), a
	endif
	call	WSCAN
	call	RDKEY
	ld	a, b
	cp	0x51
	jp	nz, dk6
	xor	a
	ld	(DNOIZ), a
dk6:
	ld	c, 0x40
dkl4:
	call	DKS3
	inc	c
	ld	a, c
	cp	0x47
	jp	nz, dkl4
	ld	a, b
	cp	0x10
	jp	nz, dk7
	ld	(DNOIZ), a
dk7:
	ifndef	SCHED
	cp	0x65			; отладочный вход в миссии: M и K на паузе (missions.asm)
	ifdef	SCENE
	call	z, scn_go		; тестовая сцена: солнце и враги
	else
	call	z, mis_dbg_m
	endif
	cp	0x46
	call	z, mis_dbg_k
	endif
	cp	0x70
	jp	z, DEATH2
	cp	0x59
	jp	nz, FREEZE
dk2:
	ifndef	SCHED
	ld	a, 1
	ld	(fly_on), a
	endif
	ld	a, (QQ11)
	or	a
	ret	nz
	ld	c, 15			; вид из корабля: вторичные клавиши полёта
	ld	a, (KL)
	ld	d, a
dkl1:
	ld	hl, KYTB
	ld	b, 0
	add	hl, bc
	ld	a, (hl)
	cp	d
	jp	nz, dk1
	ld	hl, KL
	add	hl, bc
	ld	(hl), 0xFF
dk1:
	dec	c
	ld	a, c
	cp	7
	jp	nz, dkl1
	ret

; DKS3: настройка номер Y (40h–46h: гашение рулей, центровка, PATG, вспышки, обратный тангаж, обратные оси,
; джойстик): если нажата её клавиша X — переключить, гудок и пауза Y кадров. X, Y сохраняются.
DKS3:
	ld	a, c
	ld	(T), a
	cp	b
	ret	nz
	ld	e, b
	ld	d, 0
	ld	hl, DAMP - 0x40
	add	hl, de
	ld	a, (hl)
	cpl
	ld	(hl), a
	push	bc
	ld	a, 7
	call	TT26
	pop	bc
	push	bc
	call	DELAY
	pop	bc
	ret

; DKS1: клавиша полёта номер Y (KYTB+Y): нажата — KL+Y = FFh.
DKS1:
	ld	hl, KYTB
	ld	b, 0
	add	hl, bc
	ld	b, (hl)
	call	DKS4
	ret	p
	ld	hl, KL
	ld	b, 0
	add	hl, bc
	ld	(hl), 0xFF
	ld	b, 0xFF
	ret

; DKS4: нажата ли клавиша BBC номер X (бит 7 не в счёт): A = X = номер, бит 7 — нажата; флаг знака по A.
; Сохраняет C.
DKS4:
	ld	a, b
	and	0x7F
	ld	b, a
	add	a, low kb_rev
	ld	l, a
	ld	h, high kb_rev
	ld	a, (hl)
	inc	a
	jp	z, dks4_no		; на Векторе такой клавиши нет
	dec	a
	jp	m, dks4_mod
	ld	e, a
	and	0x40
	jp	nz, dks4_ss
	ld	a, e			; F1..F5 без СС — f0..f4; с СС они уже другие клавиши
	sub	11
	cp	5
	jp	nc, dks4_key
	ld	a, (kb_mod)
	and	0x20
	jp	nz, dks4_no
	jp	dks4_key
dks4_ss:
	ld	a, (kb_mod)		; клавиша, которая считается только вместе с СС
	and	0x20
	jp	z, dks4_no
	ld	a, e
	and	0x3F
	ld	e, a
dks4_key:
	ld	a, e
	rrca
	rrca
	rrca
	and	7
	add	a, low kb_rows
	ld	l, a
	ld	h, high kb_rows
	ld	d, (hl)
	ld	a, e
	and	7
	inc	a
	ld	e, a
	ld	a, d
dks4_sh:
	rrca
	dec	e
	jp	nz, dks4_sh
	jp	nc, dks4_no
dks4_yes:
	ld	a, b
	or	0x80
	ld	b, a
	ret
dks4_mod:
	and	7
	inc	a
	ld	e, a
	ld	a, (kb_mod)
dks4_ms:
	rrca
	dec	e
	jp	nz, dks4_ms
	jp	c, dks4_yes
dks4_no:
	ld	a, b
	or	a
	ret

; BUMP2: X = X + A, не больше 255; REDU2: X = X - A, не меньше 1. Если при этом пройдена середина (128) и
; включён возврат к середине (DJD = 0) — X = 128. A сохраняется.
BUMP2:
	ld	(T), a
	add	a, b
	ld	b, a
	jp	nc, re2
	ld	b, 255
re2:
	ld	a, b
	or	a
	jp	p, re3_c
re2_r:
	ld	a, (T)
	ret
REDU2:
	ld	(T), a
	ld	d, a
	ld	a, b
	sub	d
	ld	b, a
	jp	nc, re3
	ld	b, 1
re3:
	ld	a, b
	or	a
	jp	p, re2_r
re3_c:
	ld	a, (DJD)
	or	a
	jp	nz, re2_r
	ld	b, 128
	jp	re2_r

; Клавиши полёта по номерам журнала KL (KYTB кассетной версии): 1 ? 2 пробел 3 < 4 > 5 X 6 S 7 A,
; 8 ТАБ 9 ESCAPE 10 T 11 U 12 M 13 E 14 J 15 C.
KYTB:
	db	0x60, 0xE8, 0xE2, 0xE6, 0xE7, 0xC2, 0xD1, 0xC1, 0x60, 0x70, 0x23, 0x35, 0x65, 0x22, 0x45, 0x52
