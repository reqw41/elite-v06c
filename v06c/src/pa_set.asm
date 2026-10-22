; pa_or, pa_and (обычный образ, planet.asm): как первый набор окружности планеты (pcirc; новая в pc_pr2) меняет
; точки — наложением или очисткой (места x1..x8 набора pa и pc_px). Второй набор (прежняя в pc_pr2) всегда стирает
; очисткой. Лежит в пустоте выравнивания (line.asm). Портит DE, HL.
pa_and:
	ld	hl, 0xAEA6		; and (hl); xor (hl)
	ld	(of_dirt), hl		; стирание планеты могло задеть полосы рамки (ov_fix); старший байт — в пустой H
	db	0x11			; ld de, nn: съедает «ld hl» и младший байт; старший (00h) — nop
pa_or:
	ld	hl, 0x00B6		; or (hl); nop
	ld	(pa.x1), hl
	ld	(pa.x2), hl
	ld	(pa.x3), hl
	ld	(pa.x4), hl
	ld	(pa.x5), hl
	ld	(pa.x6), hl
	ld	(pa.x7), hl
	ld	(pa.x8), hl
	ld	(pc_px), hl
	ret
