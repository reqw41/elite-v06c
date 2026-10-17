; Планета без мерцания, часть 1 (wp_begin … ws_back). В образе стенда — на месте (planet.asm), в обычном образе —
; в нижней памяти (003Bh, см. elite.asm).
; Планета без мерцания. На BBC прежняя окружность стирается целиком (WPLS2), потом рисуется новая — между ними
; планеты на экране нет. Здесь прежний список отрезков копируется в сторону (wp_begin), новая окружность
; рисуется как обычно, а после каждого её отрезка стирается один прежний (wp_step из BLINE); остаток — wp_finish.
; Рисование — исключающее ИЛИ, от порядка итог не зависит: экран и рабочие области в конце — как на BBC.
; Ячейки X1, Y1, X2, Y2 после стирания возвращаются к тому, что оставила новая окружность (wp_touch).
wp_begin:
	ifdef	WPTOUCH
	xor	a
	ld	(wp_touch), a
	else
	ld	a, 1			; обычный образ: BLINE wp_touch не ставит — X1..Y2 после стирания возвращаются
	ld	(wp_touch), a		; к тому, что оставила новая окружность (с BBC здесь не сверяется)
	xor	a
	endif
	ld	(wp_i), a
	ld	(wp_n), a
	ld	hl, (X1)
	ld	(wp_x1), hl
	ld	a, (LSX2)
	or	a
	jp	nz, WP1			; списка нет
	ld	a, (LSP)
	ld	(wp_n), a
	or	a
	jp	z, WP1
	inc	a			; на запись больше: после разрыва в конце списка WPLS2 читает и её
	ld	b, a
	push	bc
	ld	hl, LSX2
	ld	de, wp_sx
	call	ll9_cp
	pop	bc
	ld	hl, LSY2
	ld	de, wp_sy
	call	ll9_cp
	jp	WP1
wp_finish:
	ld	a, (wp_i)
	ld	c, a
	ld	a, (wp_n)
	cp	c
	jp	z, wf_end
	jp	c, wf_end
	call	wp_step
	jp	wp_finish
wf_end:
	xor	a
	ld	(wp_n), a
	ret
; wp_step: стереть один прежний отрезок (если остались). Портит A, BC, DE, HL.
wp_step:
	ld	a, (wp_i)
	ld	c, a
ws_l:
	ld	a, c
	ld	hl, wp_n
	cp	(hl)
	ret	nc			; i >= n — всё стёрто (и когда списка нет: n = 0)
	ld	b, 0
	ld	hl, wp_sy
	add	hl, bc
	ld	a, (hl)
	cp	0xFF
	jp	z, ws_brk
	ld	e, a			; конец отрезка: y
	ld	hl, wp_sx
	add	hl, bc
	ld	d, (hl)			; x
	inc	c
	ld	a, c
	ld	(wp_i), a
	ld	hl, (X1)		; X1, Y1 и X2, Y2 — на стек
	push	hl
	ld	hl, (X2)
	push	hl
	ld	hl, (wp_x1)
	ld	(X1), hl
	ld	a, d
	ld	(X2), a
	ld	(wp_x1), a
	ld	a, e
	ld	(Y2), a
	ld	(wp_x1 + 1), a
	call	LOIN
	pop	hl
	pop	de
	ld	a, (wp_touch)
	or	a
	jp	nz, ws_back
	ld	hl, (wp_x1)		; новая окружность X1..Y2 не трогала: оставить как после WPLS2 —
	ld	(X1), hl		; начало следующего отрезка
	ret
ws_back:
	ld	(X2), hl
	ex	de, hl
	ld	(X1), hl
	ret
