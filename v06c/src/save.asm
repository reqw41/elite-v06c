; Сохранение и загрузка командира: SVE, LOD, GTNME, TRNME, TR1, QUS1, ввод строки rline; пауза с настройками
; FREEZE, DKS3 — в mainloop.asm. Перенесено близко к тексту BBC; сверка — сценарий save (v06c/test/t27.mjs save).
; Носитель — магнитофон (решение владельца 08.10.2026) и память: файл командира — 256 байт по адресу BBC
; &0B00 — QUS1 кладёт в save_slot и пишет на ленту (tape.asm).

; TRNME: имя из INWK — в командира. TR1: имя командира — в INWK.
TRNME:
	ld	hl, INWK
	ld	de, NA_
	ld	b, 8
	call	ll9_cp
TR1:
	ld	hl, NA_
	ld	de, INWK
	ld	b, 8
	jp	ll9_cp

; GTNME: спросить имя командира (до 7 знаков) в INWK; пустая строка или отказ (АР2) — прежнее имя.
GTNME:
	ld	a, 1
	call	TT66
	ld	a, 123
	call	TT27
	call	DEL8
	call	rline
	jp	c, TR1
	ld	a, c
	or	a
	jp	z, TR1
	jp	TT67

; rline: ввод строки в INWK, как OSWORD 0 на BBC: знаки от «!» до «z», не больше 7, ЗБ стирает, ВК — конец
; (в строке — код 13). На выходе Y (регистр C) — длина, перенос 1 — отказ (АР2). Буквы — прописные.
rline:
	ld	c, 0
rl_key:
	call	TT217
	cp	13
	jp	z, rl_end
	cp	27
	scf
	ret	z
	cp	127
	jp	z, rl_del
	cp	'a'
	jp	c, rl_up
	cp	'z' + 1
	jp	nc, rl_key
	sub	0x20
rl_up:
	cp	'!'
	jp	c, rl_key
	cp	'z' + 1
	jp	nc, rl_key
	ld	d, a
	ld	a, c
	cp	7
	jp	nc, rl_key
	ld	hl, INWK
	ld	b, 0
	add	hl, bc
	ld	(hl), d
	inc	c
	ld	a, d
	call	TT26
	jp	rl_key
rl_del:
	ld	a, c
	or	a
	jp	z, rl_key
	dec	c
	ld	a, 127
	call	TT26
	jp	rl_key
rl_end:
	ld	hl, INWK
	ld	b, 0
	add	hl, bc
	ld	(hl), 13
	ld	a, 10			; перевод строки, как OSNEWL
	call	TT26
	ld	a, 13
	call	TT26
	or	a
	ret

; SVE: сохранить командира: имя, контрольные суммы, номер для конкурса на экране, запись файла.
SVE:
	call	GTNME
	call	TRNME
	call	ZERO
	ld	hl, SVC
	ld	a, (hl)
	or	a
	rra
	ld	(hl), a
	ld	hl, TP
	ld	de, WS + 0x0B00
	ld	b, NT + 1
	call	ll9_cp
	ld	hl, TP
	ld	de, NA_ + 8
	ld	b, NT + 1
	call	ll9_cp
	call	CHECK
	ld	(CHK), a
	push	af			; сумма и перенос — он идёт в BPRNT (точка перед последней цифрой)
	or	0x80
	ld	(K), a
	ld	hl, COK
	xor	(hl)
	ld	(K + 2), a
	ld	hl, CASH + 2
	xor	(hl)
	ld	(K + 1), a
	xor	0x5A
	ld	hl, TALLY + 1
	xor	(hl)
	ld	(K + 3), a
	pop	af
	push	af
	call	BPRNT
	call	TT67
	call	TT67
	pop	af
	ld	(WS + 0x0B00 + NT), a
	xor	0xA9
	ld	(CHK2), a
	ld	(WS + 0x0AFF + NT), a
	ld	a, 0x0B
	ld	(WS + 0x0C0B), a
	inc	a
	ld	(WS + 0x0C0F), a
	xor	a
	call	QUS1
	jp	BAY

; LOD: загрузить командира: файл — в &0B00; годный (бит 7 первого байта сброшен) — в командира.
LOD:
	call	ZERO
	ld	a, 0x0B
	ld	(WS + 0x0C03), a
	ld	hl, WS + 0x0C0B
	inc	(hl)
	ld	a, 0xFF
	call	QUS1
	ld	a, (WS + 0x0B00)
	or	a
	ret	m
	ld	hl, WS + 0x0B00
	ld	de, NA_ + 8
	ld	b, NT + 1
	jp	ll9_cp

; QUS1: файл командира: A = 0 — записать 256 байт с &0B00, A = FFh — прочитать их туда. Имя файла — в INWK.
; Файл хранится в памяти (save_slot) и на ленте (tape.asm): запись — в память и на ленту; чтение — с ленты,
; а если блок не прочитан — из памяти (последнее сохранение этого сеанса). Пусто и там — &0B00 не меняется.
; В сборке стенда (SCHED) ленты нет: только память.
QUS1:
	ld	c, a
	ld	a, low (INWK - WS)
	ld	(WS + 0x0C00), a
	ld	a, c
	or	a
	jp	nz, qus_load
	ld	hl, WS + 0x0B00
	ld	de, save_slot
	ld	b, NT + 2
	call	ll9_cp
	ld	a, 1
	ld	(save_used), a
	ifndef	SCHED
	ld	hl, save_slot
	ld	b, NT + 2
	call	tp_save
	endif
	ret
qus_load:
	ifndef	SCHED
	ld	hl, tp_buf
	ld	b, NT + 2
	call	tp_load
	jp	c, qus_mem
	ld	hl, tp_buf
	ld	de, save_slot
	ld	b, NT + 2
	call	ll9_cp
	ld	a, 1
	ld	(save_used), a
qus_mem:
	endif
	ld	a, (save_used)
	or	a
	ret	z
	ld	hl, save_slot
	ld	de, WS + 0x0B00
	ld	b, NT + 2
	jp	ll9_cp
save_used:
	db	0
save_slot:
	ds	NT + 2
