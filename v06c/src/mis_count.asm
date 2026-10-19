; mis_count (missions.asm): описание там.
mis_count:
	ld	a, (GCNT)
	or	a
	ret	z
	ld	a, (DTP)
	ld	c, a
	and	3
	dec	a
	ret	z
	ld	a, c
	and	0x0C
	cp	8
	ret	z
	ld	hl, MJC
	inc	(hl)
	ld	c, (hl)
	ld	hl, MISF
	ld	a, (hl)
	ld	b, 32
	rra
	jp	nc, mc_t
	ld	b, 128
	rra
	jp	nc, mc_t
	ld	b, 254
	rra
	ret	c
mc_t:
	ld	a, c
	cp	b
	ret	c
	ld	a, (hl)
	or	0x80
	ld	(hl), a
	ret
