; Elite / Вектор-06Ц (i8080, 48 КБ + две плоскости). Основа — кассетная версия BBC Micro.
; Карта памяти — docs/spec/v06c-memory.md. Имена переменных и процедур игры — как в исходнике BBC.
	device	noslot64k
	org	0x0100

WS		equ	0xB000		; рабочие области: адрес BBC &0000–&0F3F + WS
VARS		equ	WS + 0x0200	; переменные слоя Вектора (на BBC здесь векторы системы)
SQLO		equ	WS + 0x0400	; таблица четвертей квадратов для умножения: 4 страницы
STACK		equ	WS + 0x0900	; стек растёт вниз от K%, до таблицы — 256 байт
SCR_VIEW	equ	0xC000		; плоскость обзора: бит 1 цвета
SCR_2		equ	0xE000		; вторая плоскость: бит 0 цвета (панель)
DASH_Y		equ	192		; первая строка панели
DASH_H		equ	56

	include	"bbc_vars.inc"

entry:
	di
	ld	sp, STACK
	ld	a, 0xC3			; JP isr в векторе RST 7
	ld	(0x0038), a
	ld	hl, isr
	ld	(0x0039), hl
	ld	hl, WS			; обнулить рабочие области (стек лежит внутри них — поэтому не подпрограммой)
	ld	bc, 0x0F60
ws_clr:
	ld	(hl), 0
	inc	hl
	dec	bc
	ld	a, b
	or	c
	jp	nz, ws_clr
	call	sq_init
	call	cls_all
	ld	hl, pal_flight
	call	pal_set
	call	dash_show
	ld	hl, 0x94C7		; генератор случайных чисел: игра его не засевает, на BBC в нём след загрузчика
	ld	(RAND), hl
	ld	hl, 0x1D27
	ld	(RAND + 2), hl
	call	joy_init		; состояние покоя джойстиков
	ei
	jp	TT170

	include	"sys.asm"
	include	"text.asm"
	include	"tokens.asm"
	include	"numbers.asm"
	include	"screen.asm"
	include	"dials.asm"
	include	"reset.asm"
	include	"universe.asm"
	include	"stars.asm"
	include	"circle.asm"
	include	"planet.asm"
	include	"flight.asm"
	include	"mainflight.asm"
	include	"dash.asm"
	include	"line.asm"
	include	"arith.asm"
	include	"arith2.asm"
	include	"arith3.asm"
	include	"geom.asm"
	include	"move.asm"
	include	"scan.asm"
	include	"clip.asm"
	include	"ship.asm"
	include	"stubs.asm"
	include	"title.asm"
	include	"start.asm"
	include	"mainloop.asm"
	include	"status.asm"
	include	"charts.asm"
	include	"market.asm"
	include	"equip.asm"
	include	"tactics.asm"
	include	"combat.asm"
	include	"explode.asm"
	include	"death.asm"
	include	"hyper.asm"
	include	"snd.asm"
	include	"save.asm"
	include	"tape.asm"
	include	"missions.asm"
	include	"find.asm"
	include	"pdesc.asm"

	include	"ships.asm"		; модели кораблей: XX21 — таблица адресов
	include	"python.asm"
	include	"ships_zx.asm"		; корабли версии ZX: Krait, Asp Mk II, Fer-de-Lance; XX21X
	include	"words.asm"		; словарь QQ18
	include	"tkn1.asm"		; словарь описаний планет; кончается парами букв, продолжение которых — QQ16
	include	"qq16.asm"
	assert	QQ16 == pd_tkn2 + 26
	include	"na.asm"		; командир по умолчанию
	include	"qq23.asm"		; товары рынка
	ifdef	FAST
	align	256
LOG:	incbin	"logs.bin"		; log, logL, antilog, antilogODD — по странице (tools/convert/logs.py)
LOGL	equ	LOG + 0x100
ALOG	equ	LOG + 0x200
ALOGODD	equ	LOG + 0x300
	endif
	align	256
divtab:	incbin	"divtab.bin"		; наклоны коротких отрезков (tools/convert/divtab.py)
	include	"keys.asm"		; сразу за таблицей наклонов: её конец — на границе страницы
font:
	incbin	"font.bin"		; знаки 32–127, 8 байт сверху вниз, бит 7 слева
dials:
	incbin	"dials.rle"		; панель, сжатая (tools/convert/dials_rle.py): плоскость бита 0, затем бита 1;
					; по столбцам, 56 байт сверху вниз. Нужна один раз, при запуске
rom_end:

; --- переменные слоя Вектора ---
	org	VARS
v_frames:	ds	2		; счётчик кадров
kb_rows:	ds	8		; матрица клавиатуры, 1 — нажата; строка 0 — стрелки, 7 — пробел
kb_mod:		ds	1		; бит 5 — СС, 6 — УС, 7 — РУС/ЛАТ
pal_dirty:	ds	1		; <> 0: прерывание запишет pal_regs в палитру
pal_regs:	ds	16
ds_n:		ds	1		; распаковка панели: осталось байт в группе, признак повтора, повторяемый байт
ds_rep:		ds	1
ds_v:		ds	1
snd_v0:		ds	8		; голоса звука (snd.asm)
snd_v1:		ds	8
snd_v2:		ds	8
m3_keep:	ds	6		; семена QQ15 на время работы с системой-целью миссии
hm_buf:		ds	10		; название системы при поиске
pd_w6:		ds	1		; описание планеты (pdesc.asm): 80h — буквы строчные
pd_w2:		ds	1		; FFh — не внутри слова
pd_w8:		ds	1		; DFh — следующая буква прописная
pd_n:		ds	1		; знаков в буфере
pd_lc:		ds	1		; 20h — буква названия строчная
ll_sh:		ds	156		; копия прежнего списка отрезков корабля (самый длинный — 153 байта + длина + запас)
tp_buf		equ	ll_sh		; блок с ленты: читается не во время рисования
vars_end:
	assert	vars_end <= WS + 0x0300
; свободные байты рабочих областей: за переменными пилота и за настройками
	org	WS + 0x0372
save_used:	ds	1		; в памяти есть сохранение этого сеанса
save_slot:	ds	NT + 2		; файл командира
	assert	$ <= WS + 0x0400
	org	WS + 0x0F51
wp_sx:		ds	80		; копия прежней окружности планеты
wp_sy:		ds	80
	assert	$ <= WS + 0x1000
	assert	rom_end <= WS

	ifdef	FAST
	ifdef	SCHED
	savebin	"v06c/build/elite_fast_t.rom", 0x0100, rom_end - 0x0100
	else
	savebin	"v06c/build/elite_fast.rom", 0x0100, rom_end - 0x0100
	endif
	else
	ifdef	MERID
	ifdef	SCHED
	savebin	"v06c/build/elite_merid_t.rom", 0x0100, rom_end - 0x0100
	else
	savebin	"v06c/build/elite_merid.rom", 0x0100, rom_end - 0x0100
	endif
	else
	ifdef	SCHED
	savebin	"v06c/build/elite_t.rom", 0x0100, rom_end - 0x0100
	else
	savebin	"v06c/build/elite.rom", 0x0100, rom_end - 0x0100
	endif
	endif
	endif
