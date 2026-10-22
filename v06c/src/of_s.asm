; of_s: полосы рамки (x = 0, 1 и 254, 255) — B строк вниз от L (столбец 0) и E (столбец 31). Портит A, B, E, L. В пустоте
; выравнивания scan.asm (ov_fix.asm).
of_s:
	ld	a, (hl)
	or	0xC0
	ld	(hl), a
	ld	a, (de)
	or	0x03
	ld	(de), a
	dec	l
	dec	e
	dec	b
	jp	nz, of_s
	ret
