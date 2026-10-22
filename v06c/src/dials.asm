; Панель приборов: DIALS и её части (полоски DIL, DIL2, цвет PZW, компас COMPAS, полоски ракет MSBAR).
; В SC, SCH держится адрес экрана BBC (&7800–&7EFF). Полоски DIL и DIL2 написаны по смыслу — сразу в две
; плоскости Вектора; полоски ракет и лампы пишут байт режима 5 через dash_put. Сверка с эталоном — v06c/test/t17.mjs (панель и рабочие области).
dials_start:

; dash_put: байт A режима 5 BBC (четыре точки, цвет — старшая и младшая тетрады) по адресу BBC HL — в панель
; Вектора (восемь точек, две плоскости). Сохраняет все регистры.
dash_put:
	push	af
	push	bc
	push	de
	push	hl
	ld	c, a
	ld	a, h
	sub	0x78
	add	a, a
	add	a, a
	add	a, a
	ld	b, a			; ряд знакомест · 8
	ld	a, l
	and	7
	add	a, b
	add	a, DASH_Y
	cpl
	ld	e, a			; 255 - y
	ld	a, l
	rrca
	rrca
	rrca
	and	31
	or	high SCR_VIEW
	ld	d, a
	ld	h, high dp_nib
	ld	a, c
	rrca
	rrca
	rrca
	rrca
	and	15
	add	a, low dp_nib
	ld	l, a
	ld	a, (hl)
	ld	(de), a			; бит 1 цвета
	ld	a, d
	add	a, high (SCR_2 - SCR_VIEW)
	ld	d, a
	ld	a, c
	and	15
	add	a, low dp_nib
	ld	l, a
	ld	a, (hl)
	ld	(de), a			; бит 0 цвета
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret

; dash_eor: то же исключающим ИЛИ.
dash_eor:
	push	af
	push	bc
	push	de
	push	hl
	ld	c, a
	ld	a, h
	sub	0x78
	add	a, a
	add	a, a
	add	a, a
	ld	b, a			; ряд знакомест · 8
	ld	a, l
	and	7
	add	a, b
	add	a, DASH_Y
	cpl
	ld	e, a			; 255 - y
	ld	a, l
	rrca
	rrca
	rrca
	and	31
	or	high SCR_VIEW
	ld	d, a
	ld	h, high dp_nib
	ld	a, c
	rrca
	rrca
	rrca
	rrca
	and	15
	add	a, low dp_nib
	ld	l, a
	ex	de, hl
	ld	a, (de)
	xor	(hl)
	ld	(hl), a
	ex	de, hl
	ld	a, d
	add	a, high (SCR_2 - SCR_VIEW)
	ld	d, a
	ld	a, c
	and	15
	add	a, low dp_nib
	ld	l, a
	ex	de, hl
	ld	a, (de)
	xor	(hl)
	ld	(hl), a
	ex	de, hl
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret

; PZW: цвета полоски: X = F0h (цвет 2), A = 0Fh (цвет 1) или F0h — когда включено мигание (FLH) и идёт его фаза.
PZW:
	ld	b, 0xF0
	ld	a, (MCNT)
	and	8
	ld	hl, FLH
	and	(hl)
	ld	a, 0x0F
	ret	z
	ld	a, b
	ret

; DILX: полоска по значению A / 16. DILX_2 (на BBC — DILX+2): A / 4. DIL_1 (DIL-1): A / 2. DIL: A.
; Полоска — 16 точек режима 5 в строках 2–4 знакоместа по адресу SC; цвет K при A >= T1, иначе K+1.
; После полоски SC переходит на ряд ниже.
DILX:
	rrca
	rrca
	and	0x3F
DILX_2:
	rrca
	and	0x7F
DIL_1:
	or	a
	rra
DIL:
	ld	(Q), a
	ld	d, a
	ld	e, 0xFF
	ld	hl, T1
	cp	(hl)
	jp	nc, dl30
	ld	a, (K + 1)
	jp	dl31
dl30:
	ld	a, (K)
dl31:
	ld	(COL), a
	ld	c, a
	ld	h, high dp_nib		; цвет — в маски двух плоскостей (в команды AND ниже)
	and	15
	add	a, low dp_nib
	ld	l, a
	ld	a, (hl)
	ld	(dl_e0 + 1), a
	ld	a, c
	rrca
	rrca
	rrca
	rrca
	and	15
	add	a, low dp_nib
	ld	l, a
	ld	a, (hl)
	ld	(dl_e1 + 1), a
	ld	b, 4
	ld	hl, (SC)
	inc	l
	inc	l
	call	dash_scr		; HL — адрес первой строки полоски в плоскости SCR_VIEW
dl1:
	ld	a, d
	cp	4
	jp	c, dl2
	sub	4
	ld	d, a
	ld	a, e
dl5:
	ld	c, a			; C — какие точки знакоместа горят
dl_e1:
	and	0
	ld	(hl), a
	dec	l
	ld	(hl), a
	dec	l
	ld	(hl), a
	ld	a, h
	add	a, high (SCR_2 - SCR_VIEW)
	ld	h, a
	ld	a, c
dl_e0:
	and	0
	ld	(hl), a
	inc	l
	ld	(hl), a
	inc	l
	ld	(hl), a
	ld	a, h
	sub	high (SCR_2 - SCR_VIEW) - 1
	ld	h, a			; следующий столбец, плоскость SCR_VIEW
	dec	b
	jp	nz, dl1
	ld	a, d
	ld	(Q), a
	ld	a, e
	ld	(R_), a
	ld	hl, SCH
	inc	(hl)
	ret
dl2:
	add	a, low dl_cap		; конец полоски: A левых точек режима 5 из четырёх
	ld	e, a
	ld	d, high dl_cap
	ld	a, (de)
	ld	e, 0
	ld	d, 99
	jp	dl5

; DIL2: вертикальная чёрточка цвета 2 в положении A (0–15) в строках 1–4; остальное в полосе гасится.
DIL2:
	ld	d, a
	ld	hl, (SC)
	inc	l
	call	dash_scr
	ld	c, 4
dll10:
	ld	a, d
	sub	4
	jp	nc, dll11
	ld	a, d
	add	a, low dil2_m
	ld	e, a
	ld	d, high dil2_m
	ld	a, (de)
	ld	d, 0xFF
	jp	dll12
dll11:
	ld	d, a
	xor	a
dll12:
	ld	(hl), a			; четыре строки: чёрточка в плоскости SCR_VIEW, вторая плоскость гасится
	dec	l
	ld	(hl), a
	dec	l
	ld	(hl), a
	dec	l
	ld	(hl), a
	ld	a, h
	add	a, high (SCR_2 - SCR_VIEW)
	ld	h, a
	xor	a
	ld	(hl), a
	inc	l
	ld	(hl), a
	inc	l
	ld	(hl), a
	inc	l
	ld	(hl), a
	ld	a, h
	sub	high (SCR_2 - SCR_VIEW) - 1
	ld	h, a
	dec	c
	jp	nz, dll10
	ld	a, d
	ld	(Q), a
	ld	hl, SCH
	inc	(hl)
	ret

; dash_scr: адрес BBC HL (&7800–&7EFF) -> HL = адрес в плоскости SCR_VIEW. Портит A.
dash_scr:
	push	de
	ld	a, h
	sub	0x78
	add	a, a
	add	a, a
	add	a, a
	ld	e, a
	ld	a, l
	and	7
	add	a, e
	add	a, DASH_Y
	cpl
	ld	e, a
	ld	a, l
	rrca
	rrca
	rrca
	and	31
	or	high SCR_VIEW
	ld	h, a
	ld	l, e
	pop	de
	ret
; DIALS: обновить панель: скорость, крен, тангаж; раз в четыре прохода — энергию, щиты, топливо, температуры,
; высоту и компас.
DIALS:
	ld	hl, 0x78D0
	ld	(SC), hl
	call	PZW
	ld	(K), a
	ld	a, b
	ld	(K + 1), a
	ld	a, 14
	ld	(T1), a
	ld	a, (DELTA)
	call	DIL_1
	xor	a
	ld	(R_), a
	ld	(P_), a
	ld	a, 8
	ld	(S), a
	ld	a, (ALP1)
	rrca
	rrca
	and	0x3F
	ld	hl, ALP2
	or	(hl)
	xor	0x80
	call	ADD
	call	DIL2
	ld	a, (BET1)
	or	a
	ld	a, (BETA)
	jp	z, dls_b
	dec	a
dls_b:
	call	ADD
	call	DIL2
	ld	a, (MCNT)
	and	3
	ret	nz
	call	PZW
	ld	(K + 1), a
	ld	a, b
	ld	(K), a
	ld	a, 3
	ld	(T1), a
	ld	hl, 0
	ld	(XX12), hl
	ld	(XX12 + 2), hl
	ld	b, 3			; энергия: четыре банка по 16
	ld	a, (ENERGY)
	rrca
	rrca
	and	0x3F
	ld	(Q), a
dll24:
	sub	16
	jp	c, dll26
	ld	(Q), a
	ld	e, a
	ld	a, 16
	call	dls_put
	ld	a, e
	dec	b
	jp	p, dll24
	jp	dll9
dll26:
	ld	a, (Q)
	call	dls_put
dll9:
	ld	c, 0
dll9_l:
	ld	hl, XX12
	ld	b, 0
	add	hl, bc
	ld	a, c
	ld	(P_), a
	ld	a, (hl)
	call	DIL
	ld	a, (P_)
	inc	a
	ld	c, a
	cp	4
	jp	nz, dll9_l
	ld	hl, 0x7810
	ld	(SC), hl
	ld	a, (FSH)
	call	DILX
	ld	a, (ASH)
	call	DILX
	ld	a, (QQ14)
	call	DILX_2
	call	PZW
	ld	(K), a
	ld	a, b
	ld	(K + 1), a
	ld	a, 11
	ld	(T1), a
	ld	a, (CABTMP)
	call	DILX
	ld	a, (GNTMP)
	call	DILX
	ld	a, 240
	ld	(T1), a
	ld	(K + 1), a
	ld	a, (ALTIT)
	call	DILX
	jp	COMPAS
dls_put:				; XX12[B] = A
	ld	hl, XX12
	ld	d, a
	ld	a, b
	add	a, l
	ld	l, a
	ld	(hl), d
	ret

; COMPAS: стереть точку компаса и поставить новую — направление на планету (у станции — на станцию, этап P4).
COMPAS:
	call	DOT
	ld	a, (SSPR)
	or	a
	jp	nz, SP1
	call	SPS1
	jp	SP2
; SPS1: K3 = положение планеты (блок K%), затем TAS2. SPS3: одна координата, X = 0, 3, 6.
SPS1:
	ld	b, 0
	call	SPS3
	ld	b, 3
	call	SPS3
	ld	b, 6
	call	SPS3
; TAS2: вектор K3(8..0) растянуть до предела и нормировать в XX15 (дальше NORM).
TAS2:
	ld	a, (K3)
	ld	hl, K3 + 3
	or	(hl)
	ld	hl, K3 + 6
	or	(hl)
	or	1
	ld	(K3 + 9), a
	ld	a, (K3 + 1)
	ld	hl, K3 + 4
	or	(hl)
	ld	hl, K3 + 7
	or	(hl)
	ld	d, a
tal2:
	ld	hl, K3 + 9
	ld	a, (hl)
	add	a, a
	ld	(hl), a
	ld	a, d
	rla
	ld	d, a
	jp	c, ta2
	ld	hl, K3
	call	tas2_sh
	ld	hl, K3 + 3
	call	tas2_sh
	ld	hl, K3 + 6
	call	tas2_sh
	jp	nc, tal2
ta2:
	ld	hl, K3 + 1
	ld	de, XX15
	ld	b, 3
ta2_l:
	ld	a, (hl)
	or	a
	rra
	inc	hl
	or	(hl)
	ld	(de), a
	inc	hl
	inc	hl
	inc	de
	dec	b
	jp	nz, ta2_l
	jp	NORM
tas2_sh:
	ld	a, (hl)
	add	a, a
	ld	(hl), a
	inc	hl
	ld	a, (hl)
	rla
	ld	(hl), a
	ret
SPS3:
	ld	hl, K_ + 1
	ld	de, K3
	ld	a, b
	add	a, l
	ld	l, a
	ld	a, b
	add	a, e
	ld	e, a
	ld	a, (hl)
	ld	(de), a
	inc	hl
	inc	de
	ld	a, (hl)
	ld	c, a
	and	0x7F
	ld	(de), a
	inc	de
	ld	a, c
	and	0x80
	ld	(de), a
	ret
; SPS2: (Y X) = A / 10 со знаком: A — число со знаком в бите 7.
SPS2:
	add	a, a
	ld	b, a
	ld	a, 0
	rra
	ld	c, a
	ld	a, 20
	ld	(Q), a
	ld	a, b
	push	bc
	call	DVID4
	pop	bc
	ld	a, (P_)
	ld	b, a
	ld	a, c
	or	a
	jp	m, ll163
	ld	c, 0
	ret
ll163:
	ld	c, 0xFF
	ld	a, b
	cpl
	inc	a
	ld	b, a
	or	a
	ret
; SP2: точка компаса по вектору XX15: COMX = 195 + x / 10, COMY = 203 - y / 10, цвет по знаку z; затем DOT.
SP2:
	ld	a, (XX15)
	call	SPS2
	ld	a, b
	add	a, 195
	ld	(COMX), a
	ld	a, (XX15 + 1)
	call	SPS2
	ld	a, b
	ld	(T), a
	ld	a, 203
	sub	b
	ld	(COMY), a
	ld	a, (XX15 + 2)
	or	a
	ld	a, 0xF0
	jp	p, sp2_c
	ld	a, 0xFF
sp2_c:
	ld	(COMC), a
; DOT: точка компаса (COMX, COMY) цветом COMC: цвет 2 — двойной высоты, иначе одна строка.
DOT:
	ld	a, (COMY)
	ld	(Y1), a
	ld	a, (COMX)
	ld	(X1), a
	ld	a, (COMC)
	ld	(COL), a
	cp	0xF0
	jp	nz, CPIX2
	jp	CPIX4

; MSBAR: полоска ракеты X (1–4) цветом Y (байт режима 5). msblob: все четыре: имеющиеся — EEh, остальные гасятся.
MSBAR:
	ld	a, b
	add	a, a
	add	a, a
	add	a, a
	ld	(T), a
	ld	e, a
	ld	a, 48
	sub	e
	ld	l, a
	ld	h, 0x7E
	ld	(SC), hl
	ld	a, l
	add	a, 5
	ld	l, a
	ld	a, c
	ld	e, 5
mbl1:
	call	dash_put
	dec	l
	dec	e
	jp	nz, mbl1
	ld	c, 0
	ret
msblob:
	ld	b, 4
ss_l:
	ld	a, (NOMSL)
	cp	b
	jp	z, sal8
	ld	c, 0
	call	MSBAR
	dec	b
	jp	nz, ss_l
	ret
sal8:
	ld	c, 0xEE
	call	MSBAR
	dec	b
	jp	nz, sal8
	ret
	ifdef	PCIRC
	ifndef	RUS
	include	"pc_col.asm"		; окружность планеты (planet.asm), в пустоту выравнивания; в русской сборке — перед sfx_tab
	endif
	endif
	ifdef	ORAND
	include	"ov_v.asm"		; в пустоту выравнивания (дорисовка прицела, ov_fix.asm)
	ifndef	AUTO			; см. flight.asm
	include	"px_o.asm"		; в пустоту выравнивания (точки пыли: наложение)
	endif
	endif

	ifdef	ORAND
	PAGEFIT	24			; dp_nib, dil2_m, dl_cap
	else
	align	32
	endif
dp_nib:	db	0x00, 0x03, 0x0C, 0x0F, 0x30, 0x33, 0x3C, 0x3F, 0xC0, 0xC3, 0xCC, 0xCF, 0xF0, 0xF3, 0xFC, 0xFF
dil2_m:	db	0xC0, 0x30, 0x0C, 0x03	; чёрточка шириной в точку режима 5 в четырёх положениях
dl_cap:	db	0x00, 0xC0, 0xF0, 0xFC	; 0–3 левые точки режима 5
dials_end:
