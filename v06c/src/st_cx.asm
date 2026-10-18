; st_cx: координата x пыли -> столбец экрана 128 + x. Нижняя память.
st_cx:
	call	st_cv
	xor	0x80
	ret
