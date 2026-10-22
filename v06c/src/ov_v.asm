; Часть ov_fix (ship.asm): в пустоте выравнивания (dials.asm). of_v — столбец x = 128 прицела, 10 строк вниз от L.
of_v:
	ld	b, 10
of_vl:
	ld	a, (hl)
	or	0x80
	ld	(hl), a
	dec	l
	dec	b
	jp	nz, of_vl
	ret
of_tab:					; горизонтальные плечи прицела: столбец, маска
	db	high SCR_VIEW + 13, 0x0F, high SCR_VIEW + 14, 0xFC, high SCR_VIEW + 17, 0x3F, high SCR_VIEW + 18, 0xF0
