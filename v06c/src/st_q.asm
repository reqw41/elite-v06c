; st_q: A — координата пыли (модуль и знак в бите 7) -> три четверти модуля, знак тот же. Портит HL.
st_q:
	ld	l, a
	and	0x80
	ld	h, a
	ld	a, l
	and	0x7F
	ld	l, a
	rrca
	rrca
	and	0x3F
	cpl
	inc	a
	add	a, l
	or	h
	ret
