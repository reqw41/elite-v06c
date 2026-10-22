; px_and (см. px_x.asm) и px_edg (PIXEL: точка у края — рамку дорисует ov_fix). В пустоте выравнивания flight.asm.
px_and:
	ld	hl, 0xA62F		; cpl; and (hl)
	jp	px_set
px_edg:
	ld	a, h
	ld	(of_dirt), a		; не 0
	ret
