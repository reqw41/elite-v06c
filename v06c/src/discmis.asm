; Миссии дисковой версии BBC: «Констриктор» (миссия 1) и «Планы таргоидов» (миссия 2). Логика — DOENTRY, BRIEF,
; BRIEF2, BRIEF3, DEBRIEF, DEBRIEF2, PAUSE, BRIS стоянки и вставки полётной части (появление и гибель
; «Констриктора», таргоиды при миссии 2). Тексты — словарь tkn1.asm, печать — pdesc.asm.
; Состояние — байт DTP в свободном месте файла командира; биты — как у TP дисковой версии:
;   биты 0–1: миссия 1 — 00 не начата, 01 идёт, 11 «Констриктор» убит, 10 закончена;
;   биты 2–3: миссия 2 — бит 2: вызваны на Ceerdi, биты 3 и 1: планы получены, 1110 — закончена.
; Пока DTP = 0 и побед меньше 256, вставки молчат. Сверка — v06c/test/discmis.mjs.
DTP	equ	ESCP + 2
; Побочные миссии между основными (ZX), по ходу галактик: «Констриктор» — с ранга Competent (33 024 очка, 008100h),
; в первых двух галактиках; «Планы таргоидов» — после «Констриктора» и «Сверхновой» (она и уносит в третью
; галактику, где их выдают). На BBC — 256 и 1280 побед. Основная линия (по счётчику прибытий) побочных не ждёт.

; dm_dock (DOENTRY): при стыковке — задание или награда, если пора. Пока идёт миссия версии ZX — ничего.
dm_dock:
	ld	a, (M1ST)
	ld	hl, M3ST
	or	(hl)
	ret	nz
	ld	a, (DTP)
	and	3
	jp	nz, dm_en1
	ld	a, (TALLY + 1)
	or	a
	jp	nz, dm_rk
	ld	a, (TALLY)
	cp	0x81
	ret	c
dm_rk:
	ld	a, (GCNT)
	cp	2
	ret	nc
; BRIEF: миссия 1 — «входящее сообщение», «Констриктор» на экране, задание.
	ld	hl, DTP
	inc	(hl)
	call	dm_bris
	call	ZINF
	xor	a
	ld	(DELTA), a
	ld	(ALPHA), a
	ld	(ALP1), a
	ld	(BETA), a		; на диске тангаж не обнуляется; оставшийся от стыковки, он уводит корабль
	ld	(BET1), a		; показа по z, и показ может не кончиться
	ld	a, 31
	ld	(TYPE), a
	call	NWSHP
	ld	a, 1
	ld	(XC), a
	ld	(INWK + 7), a
	call	pd_tt66
	ld	a, 64
	ld	(MCNT), a
dm_brl1:
	ld	a, 0x7F
	ld	(INWK + 29), a
	ld	(INWK + 30), a
	call	LL9
	call	MVEIT
	ld	hl, MCNT
	dec	(hl)
	jp	nz, dm_brl1
dm_brl2:
	ld	hl, INWK
	ld	a, (hl)
	or	a
	rra
	ld	(hl), a
	ld	hl, INWK + 6
	inc	(hl)
	jp	z, dm_br2
	inc	(hl)
	jp	z, dm_br2
	ld	a, (INWK + 3)
	inc	a
	cp	112
	jp	c, dm_brl3
	ld	a, 112
dm_brl3:
	ld	(INWK + 3), a
	call	LL9
	call	MVEIT
	jp	dm_brl2
dm_br2:
	ld	hl, INWK + 7
	inc	(hl)
	ld	a, PD_BRIEF1
dm_text:				; текст номер A; буфер выравнивания после него выключен
	call	pd_tok
	xor	a
	ld	(pd_cap), a
	ret
dm_en1:
	cp	3
	jp	nz, dm_en2
	ld	hl, DTP			; DEBRIEF: «Констриктор» убит — победы + 256, 5000 Cr
	dec	(hl)
	ld	hl, TALLY + 1
	inc	(hl)
	ld	bc, 0x50C3		; B — младший байт, C — старший: 50000 (5000,0 Cr)
	call	MCASH
	ld	a, PD_DEBRIEF1
	jp	dm_text
dm_en2:
	ld	a, (GCNT)
	cp	2
	ret	nz
	ld	hl, DTP
	ld	a, (hl)
	and	0x0F
	cp	2
	jp	nz, dm_en3
	ld	a, (MISF)
	rra
	ret	nc
	ld	a, (hl)			; BRIEF2: вызов на Ceerdi
	or	4
	ld	(hl), a
	ld	a, PD_BRIEF2
	jp	dm_text
dm_en3:
	ex	de, hl
	ld	hl, (QQ0)
	ex	de, hl		; E = QQ0, D = QQ1
	cp	6
	jp	nz, dm_en5
	ld	a, e			; BRIEF3: на Ceerdi (215, 84) — планы на борту
	cp	215
	ret	nz
	ld	a, d
	cp	84
	ret	nz
	ld	a, (hl)
	and	0xF0
	or	0x0A
	ld	(hl), a
	ld	a, PD_BRIEF3
	jp	dm_text
dm_en5:
	cp	10
	ret	nz
	ld	a, e			; DEBRIEF2: на Birera (63, 72) — флотский блок энергии, победы + 256
	cp	63
	ret	nz
	ld	a, d
	cp	72
	ret	nz
	ld	a, (hl)
	or	4
	ld	(hl), a
	ld	a, 2
	ld	(ENGY), a
	ld	hl, TALLY + 1
	inc	(hl)
	ld	a, PD_DEBRIEF2
	jp	dm_text

; dm_bris (BRIS): «INCOMING MESSAGE» и две секунды.
dm_bris:
	ld	a, PD_INCOMING
	call	pd_tok
	ld	c, 100
	jp	DELAY
; dm_pause (PAUSE): корабль крутится, пока не нажмут клавишу; затем чистый экран и корабль.
dm_pause:
	call	dm_pas1
	jp	nz, dm_pause
dm_pal1:
	call	dm_pas1
	jp	z, dm_pal1
	xor	a
	ld	(INWK + 31), a
	call	pd_tt66
	jp	LL9
dm_pas1:
	ld	a, 112
	ld	(INWK + 3), a
	xor	a
	ld	(INWK), a
	ld	(INWK + 6), a
	ld	a, 2
	ld	(INWK + 7), a
	call	LL9
	call	MVEIT
	jp	RDKEY
dm_pause2	equ	TT217		; PAUSE2: ждать клавишу

; dm_pick: одинокий охотник в системе «Констриктора» (галактика 1, Orarra — 144, 33): тактика F9h; пока идёт
; миссия 1 и «Констриктора» рядом нет — выходит он. A — тип, сохраняется или заменяется на 31.
dm_pick:
	ld	c, a
	ld	a, (GCNT)
	dec	a
	jp	nz, dm_pk
	ld	hl, (QQ0)
	ld	a, l
	cp	144
	jp	nz, dm_pk
	ld	a, h
	cp	33
	jp	nz, dm_pk
	ld	a, 0xF9
	ld	(INWK + 32), a
	ld	a, (DTP)
	and	3
	dec	a
	jp	nz, dm_pk
	ld	hl, FRIN
	ld	b, NOSH
dm_pk1:
	ld	a, (hl)
	cp	31
	jp	z, dm_pk
	inc	hl
	dec	b
	jp	nz, dm_pk1
	ld	c, 31
dm_pk:
	ld	a, c
	ret
; dm_thg: планы таргоидов на борту — таргоиды нападают чаще. Сохраняет DE; случайное число своё.
dm_thg:
	ld	a, (DTP)
	and	0x0C
	cp	8
	ret	nz
	call	mis_rnd
	cp	200
	ret	c
	push	de
	scf
	call	GTHG
	pop	de
	ret
