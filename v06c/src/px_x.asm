; Точка пыли: px_or — наложением, px_and — очисткой, px_xor — исключающим ИЛИ (как на BBC; так рисуют все, кроме
; пыли в полёте: STARS возвращает этот режим). Портят только HL, флаги не трогают. px_and и px_or — в px_a.asm
; и px_o.asm (другие пустоты выравнивания). Здесь — в пустоте выравнивания line.asm.
px_xor:
	ld	hl, 0xAE00		; nop; xor (hl)
px_set:
	ld	(px_c1), hl
	ld	(px_c2), hl
	ld	(px_c3), hl
	ret
