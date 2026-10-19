; Звук на ВИ53 (порты 08h–0Bh): три голоса, обновление раз в кадр из обработчика прерывания.
; Звуки игры — блоки BBC (канал, громкость или огибающая, высота, длительность) из sfx_tab; у BBC три тона и шум
; с четырьмя огибающими, у ВИ53 — три меандра без громкости. Соответствие: шум (канал 0) — счётчик 0 (случайный
; делитель каждый кадр), каналы 1 и 2 (взрыв, лазер, попадание) — счётчик 1, канал 3 (гудки, ECM) — счётчик 2.
; Огибающие высоты повторены (шаг BBC — 1/100 с, здесь два шага за кадр), огибающие громкости — нет.
; На состояние игры звук не влияет: свои ячейки и свой генератор случайных чисел.

; голос: +0 кадров осталось (0 — молчит, FFh — до отмены), +1 маска шума (0 — тон), +2 высота BBC (у шума —
; старший байт делителя), +3 секция огибающей, +4 шагов в секции, +5 адрес огибающей (0 — нет),
; +7 исходная высота: на новом круге огибающей высота начинается с неё, как на BBC
snd_rnd:	dw	0xACE1
; огибающие высоты BBC 1–4: три приращения и три числа шагов
snd_env:
	db	0, 111, -8, 4, 1, 8		; 1: лазер
	db	14, -18, -1, 44, 32, 50		; 2: попадание в нас, прыжок
	db	1, -1, -3, 17, 32, 128		; 3: взрыв
	db	4, -8, 44, 4, 6, 8		; 4: ECM
; делители ВИ53 (1,5 МГц) для высот BBC 0–47 (четверти полутона; высота 53 — до первой октавы); октава выше — сдвиг
snd_div:
	dw	12325, 12149, 11974, 11803, 11634, 11467, 11302, 11140
	dw	10981, 10823, 10668, 10515, 10364, 10216, 10069, 9925
	dw	9783, 9642, 9504, 9368, 9234, 9101, 8971, 8842
	dw	8715, 8590, 8467, 8346, 8226, 8108, 7992, 7877
	dw	7764, 7653, 7543, 7435, 7329, 7224, 7120, 7018
	dw	6917, 6818, 6720, 6624, 6529, 6436, 6343, 6252

; snd_tick: кадр звука (из обработчика прерывания; регистры сохранены там).
snd_tick:
	ld	hl, snd_v0
	ld	a, 0x0B
	ld	b, 0x36
	call	snd_voice
	ld	hl, snd_v1
	ld	a, 0x0A
	ld	b, 0x76
	call	snd_voice
	ld	hl, snd_v2
	ld	a, 0x09
	ld	b, 0xB6
snd_voice:				; HL — голос, A — порт счётчика, B — слово режима (останавливает счётчик)
	ld	(sv_o1 + 1), a
	ld	(sv_o2 + 1), a
	ld	a, (hl)
	or	a
	ret	z
	cp	0xFF
	jp	z, sv_play
	dec	a
	ld	(hl), a
	jp	nz, sv_play
	ld	a, b
	out	(0x08), a
	ret
sv_play:
	inc	hl
	ld	a, (hl)
	or	a
	jp	nz, sv_noise
	inc	hl
	ld	a, (hl)
	ld	b, 0
sv_oct:
	cp	48
	jp	c, sv_n
	sub	48
	inc	b
	jp	sv_oct
sv_n:
	add	a, a
	ld	e, a
	ld	d, 0
	push	hl
	ld	hl, snd_div
	add	hl, de
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	pop	hl
	inc	b
sv_sh:
	dec	b
	jp	z, sv_out
	ld	a, d
	or	a
	rra
	ld	d, a
	ld	a, e
	rra
	ld	e, a
	jp	sv_sh
sv_noise:				; A — маска, HL — на маске
	ld	c, a
	push	hl
	ld	hl, (snd_rnd)
	add	hl, hl
	jp	nc, sv_r1
	ld	a, l
	xor	0x2D
	ld	l, a
sv_r1:
	ld	(snd_rnd), hl
	ex	de, hl
	pop	hl
	inc	hl
	ld	a, d
	and	c
	add	a, (hl)
	ld	d, a
sv_out:					; DE — делитель, HL — на высоте
	ld	a, e
sv_o1:
	out	(0), a
	ld	a, d
sv_o2:
	out	(0), a
	inc	hl
	inc	hl
	inc	hl
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ld	a, d
	or	e
	ret	z
	dec	hl
	dec	hl
	dec	hl
	dec	hl
	call	sv_step			; два шага огибающей за кадр
sv_step:				; HL — на высоте, DE — огибающая
	push	hl
	inc	hl
	inc	hl
	ld	a, (hl)
	or	a
	jp	nz, sv_have
	dec	hl
	ld	a, (hl)
	inc	a
	cp	3
	jp	c, sv_s1
	push	hl			; новый круг: высота — исходная
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ld	a, (hl)
	pop	hl
	dec	hl
	ld	(hl), a
	inc	hl
	xor	a
sv_s1:
	ld	(hl), a
	push	de
	add	a, 3
	add	a, e
	ld	e, a
	ld	a, d
	adc	a, 0
	ld	d, a
	ld	a, (de)
	pop	de
	inc	hl
	ld	(hl), a
sv_have:
	dec	(hl)
	dec	hl
	ld	a, (hl)
	push	de
	add	a, e
	ld	e, a
	ld	a, d
	adc	a, 0
	ld	d, a
	ld	a, (de)
	pop	de
	dec	hl
	add	a, (hl)
	ld	(hl), a
	pop	hl
	ret

; snd_start: начать звук по блоку BBC (HL — четыре байта из sfx_tab). Голос сначала глушится, счётчик кадров
; пишется последним — прерывание не увидит голос наполовину заполненным. Портит A, BC, DE, HL.
snd_start:
	ld	a, (hl)
	and	3
	ld	de, snd_v0
	ld	b, 0x36
	jp	z, ss_v
	cp	3
	ld	de, snd_v2
	ld	b, 0xB6
	jp	z, ss_v
	ld	de, snd_v1
	ld	b, 0x76
ss_v:
	xor	a
	ld	(de), a
	ld	a, b
	out	(0x08), a
	ld	a, (hl)
	and	3
	ld	c, a
	inc	hl
	ld	a, (hl)
	or	a
	ret	z			; громкость 0 — тишина (ECM выключен)
	push	de
	inc	de
	jp	m, ss_amp
	dec	a			; огибающая 1–4: BC — её адрес
	ld	b, a
	add	a, a
	add	a, b
	add	a, a
	add	a, low snd_env
	ld	c, a
	ld	a, high snd_env
	adc	a, 0
	ld	b, a
	xor	a
	ld	(de), a
	inc	de
	inc	hl
	ld	a, (hl)
	ld	(de), a
	inc	de
	xor	a
	ld	(de), a
	inc	de
	push	hl
	ld	hl, 3
	add	hl, bc
	ld	a, (hl)
	pop	hl
	ld	(de), a
	inc	de
	ld	a, c
	ld	(de), a
	inc	de
	ld	a, b
	ld	(de), a
	inc	de
	ld	a, (hl)
	ld	(de), a			; исходная высота
	jp	ss_dur
ss_amp:
	inc	hl
	ld	b, (hl)
	ld	a, c
	or	a
	jp	nz, ss_tone
	ld	a, b
	cp	8
	jp	nc, ss_tone
	cp	6			; шум: 6 — шипение (пуск), иначе гул (взрыв)
	ld	a, 0x0F
	ld	b, 0x04
	jp	z, ss_nz
	ld	a, 0x3F
	ld	b, 0x10
ss_nz:
	ld	(de), a
	inc	de
	ld	a, b
	ld	(de), a
	inc	de
	jp	ss_noenv
ss_tone:
	xor	a
	ld	(de), a
	inc	de
	ld	a, b
	ld	(de), a
	inc	de
ss_noenv:
	xor	a
	ld	(de), a
	inc	de
	ld	(de), a
	inc	de
	ld	(de), a
	inc	de
	ld	(de), a
ss_dur:
	inc	hl
	ld	a, (hl)			; длительность в 1/20 с — в кадры: ×2,5
	pop	de
	cp	0xFF
	jp	z, ss_set
	cp	100
	jp	c, ss_d1
	ld	a, 100
ss_d1:
	ld	b, a
	add	a, a
	ld	c, a
	ld	a, b
	or	a
	rra
	add	a, c
	jp	nz, ss_set
	inc	a
ss_set:
	ld	(de), a
	ret

	ifndef	SCHED
	ifdef	NOMUS			; сборке с меридианами не хватает места, тестовой сцене не нужна: без мелодии
mus_tick:
mus_start:
mus_stop:
	ret
	endif
	endif
	ifndef	SCHED
	ifndef	NOMUS
; Мелодия заставки — главная тема «Голубого Дуная» в три голоса (v06c/data/danube.asm, tools/convert/danube.py):
; голоса записи C64 1, 2, 3 — snd_v0, snd_v1, snd_v2. mus_tick — раз в кадр из прерывания; mus_p = 0 — молчит.
; Заголовок: биты 0–2 — какие голоса берут новую ноту, 3–6 — задержка до следующего (mus_len); за ним высоты BBC.
; Новая нота звучит до 64 кадров; голосам, которые возьмут ноту в следующем заголовке, — на 2 кадра меньше
; задержки (раздельно: огибающей у ВИ53 нет). Звук выключен (DNOIZ) — ноты пропускаются молча.
mus_tick:
	ld	hl, (mus_p)
	ld	a, h
	or	l
	ret	z
	ld	a, (mus_t)
	dec	a
	ld	(mus_t), a
	ret	nz
	ld	a, (hl)
	or	a
	jp	nz, mt_h
	ld	hl, mus_dat		; конец — сначала
	ld	a, (hl)
mt_h:
	inc	hl
	ld	c, a
	rrca
	rrca
	rrca
	and	15
	add	a, low mus_len		; таблица не пересекает границу страницы (assert ниже)
	ld	e, a
	ld	d, high mus_len
	ld	a, (de)
	ld	(mus_t), a
	sub	2
	ld	b, a			; B — кадров звучать голосам, которые возьмут ноту следующими
	ld	de, snd_v0
mt_v:
	ld	a, c
	rrca
	ld	c, a
	jp	nc, mt_nx
	ld	a, (DNOIZ)
	or	a
	ld	a, (hl)
	inc	hl
	jp	nz, mt_nx
	push	hl
	ld	h, d
	ld	l, e
	ld	(hl), 64		; кадров звучать
	inc	hl
	ld	(hl), 0			; тон
	inc	hl
	ld	(hl), a			; высота
	inc	hl
	inc	hl
	inc	hl
	ld	(hl), 0			; без огибающей
	inc	hl
	ld	(hl), 0
	pop	hl
mt_nx:
	ld	a, e
	add	a, 8
	ld	e, a
	cp	low (snd_v0 + 24)
	jp	nz, mt_v
	ld	(mus_p), hl
	ld	a, (hl)			; следующий заголовок (после конца — первый): его голоса замолкают заранее
	or	a
	jp	nz, mt_pk
	ld	a, (mus_dat)
mt_pk:
	ld	c, a
	ld	de, snd_v0
mt_c:
	ld	a, c
	rrca
	ld	c, a
	jp	nc, mt_cn
	ld	a, (de)
	or	a
	jp	z, mt_cn		; молчит — не будить
	cp	b
	jp	c, mt_cn
	ld	a, b
	ld	(de), a
mt_cn:
	ld	a, e
	add	a, 8
	ld	e, a
	cp	low (snd_v0 + 24)
	jp	nz, mt_c
	ret
mus_start:
	ld	hl, (mus_p)
	ld	a, h
	or	l
	ret	nz
	ld	hl, mus_dat
	ld	(mus_p), hl
	ld	a, 1
	ld	(mus_t), a
	ret
mus_stop:
	ld	hl, 0
	ld	(mus_p), hl
	ld	a, 1			; голоса замолкнут в следующем кадре
	ld	(snd_v0), a
	ld	(snd_v1), a
	ld	(snd_v2), a
	ret
	include	"danube.asm"
	assert	high mus_len == high (mus_len + 15)
	endif
	endif
