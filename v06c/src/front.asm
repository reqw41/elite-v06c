; Данные в начале образа: между переходом на entry (0100h) и таблицей наклонов, которой нужна граница страницы
; (0200h). Собраны так, чтобы занять страницу почти целиком: иначе перед таблицей остаётся пустота.
	include	"na.asm"		; командир по умолчанию
	include	"qq23.asm"		; товары рынка
; появление кораблей по правилам дисковой версии (ds_lone, ds_trade, ds_pack, ds_junk — mainflight.asm)
ds_tl:	db	5, 15, 4, 16		; одиночный охотник: Cobra (пират), Asp, Python, Fer-de-Lance
ds_tt:	db	7, 4, 27, 28		; торговец: Cobra, Python, Boa, Anaconda
ds_tp:	db	1, 3, 14, 22, 23, 24, 25, 5	; стая: Sidewinder, Mamba, Krait, Adder, Gecko, Cobra Mk I, Worm, Cobra (пират)
ds_tj:	db	11, 21, 10		; мусор: контейнер, валун, астероид
; управляющие коды текстов описаний и миссий (pd_jump, pdesc.asm)
pd_jt:	dw	pd_mt1, pd_mt2, TT27, pd_cmn, pd_dasc, pd_dasc, pd_dasc, pd_mt8, pd_mt9, mz_nl
	dw	mz_name, pd_dasc, pd_mt13, pd_mt14, pd_mt15, pd_dasc, pd_mt17, pd_mt18, pd_mt19, pd_dasc
	dw	pd_dasc, dm_pause, pd_mt23, dm_pause2, dm_bris, pd_dasc, pd_mt27, pd_mt28, pd_mt29
