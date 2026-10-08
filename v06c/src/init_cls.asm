; Нужно один раз, при запуске: в обычном образе лежит в рабочих областях (см. elite.asm), в образе стенда — в игре.
; Очистить обе плоскости целиком.
cls_all:
	ld	hl, SCR_VIEW
	xor	a
ca_lp:
	dup	4
	ld	(hl), a
	inc	l
	edup
	jp	nz, ca_lp
	inc	h
	jp	nz, ca_lp
	ret
