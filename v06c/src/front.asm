; Данные в начале образа: между переходом на entry (0100h) и таблицей наклонов, которой нужна граница страницы
; (0200h). Собраны так, чтобы занять страницу почти целиком: иначе перед таблицей остаётся пустота.
	include	"na.asm"		; командир по умолчанию
	include	"qq23.asm"		; товары рынка
; замена кораблей при появлении (zx_pick, mainflight.asm): строка по типу и четыре варианта
zp_map:	db	0, 0xFF, 4, 8, 12, 0xFF, 16
zp_tab:	db	14, 22, 23, 25		; Sidewinder: Krait, Adder, Gecko, Worm
	db	14, 24, 26, 23		; Mamba: Krait, Cobra Mk I, Moray, Gecko
	db	15, 15, 4, 4		; Python: Asp Mk II
	db	16, 16, 5, 15		; Cobra: Fer-de-Lance, Asp Mk II
	db	27, 28, 4, 7		; торговец: Boa, Anaconda, Python
; управляющие коды текстов описаний и миссий (pd_jump, pdesc.asm)
pd_jt:	dw	pd_mt1, pd_mt2, TT27, pd_cmn, pd_dasc, pd_dasc, pd_dasc, pd_mt8, pd_mt9, mz_nl
	dw	mz_name, pd_dasc, pd_mt13, pd_mt14, pd_mt15, pd_dasc, pd_mt17, pd_mt18, pd_mt19, pd_dasc
	dw	pd_dasc, dm_pause, pd_mt23, dm_pause2, dm_bris, pd_dasc, pd_mt27, pd_mt28, pd_mt29
