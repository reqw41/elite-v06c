; Мелодия заставки с Сатурном лежит в её области в обход переменных, которые трогают во время заставки: ноты —
; сразу за кодом Сатурна (там переменные полёта LSX2…NOSTM, до полёта не нужны), настройки COMC…JSTK (DNOIZ
; читается) — нули, проигрыватель — на месте копии окружности планеты (wp_sx, только полёт).
	include	"danube.asm"
	assert	high mus_len == high (mus_len + 15)
	assert	$ <= COMC
	org	WS + 0x0F51
; Мелодия заставки с Сатурном (лежит в её области; mus_tick, mus_start, mus_stop в snd.asm ведут сюда) — главная
; тема «Голубого Дуная» в три голоса (v06c/data/danube.asm, tools/convert/danube.py):
; голоса записи C64 1, 2, 3 — snd_v0, snd_v1, snd_v2. mus_tick — раз в кадр из прерывания; mus_p = 0 — молчит.
; Заголовок: биты 0–2 — какие голоса берут новую ноту, 3–6 — задержка до следующего (mus_len); за ним высоты BBC.
; Новая нота звучит до 64 кадров; голосам, которые возьмут ноту в следующем заголовке, — на 2 кадра меньше
; задержки (раздельно: огибающей у ВИ53 нет). Звук выключен (DNOIZ) — ноты пропускаются молча.
mt_go:
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
ms_go:
	ld	hl, (mus_p)
	ld	a, h
	or	l
	ret	nz
	ld	hl, mus_dat
	ld	(mus_p), hl
	ld	a, 1
	ld	(mus_t), a
	ret
mp_go:
	ld	hl, 0
	ld	(mus_p), hl
	ld	a, 1			; голоса замолкнут в следующем кадре
	ld	(snd_v0), a
	ld	(snd_v1), a
	ld	(snd_v2), a
	ret
