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

	include	"ships.asm"		; модели кораблей: XX21 — таблица адресов
	include	"python.asm"
	include	"words.asm"		; словарь QQ18
	include	"qq16.asm"
	include	"na.asm"		; командир по умолчанию
	include	"keys.asm"
	ifdef	FAST
	align	256
LOG:	incbin	"logs.bin"		; log, logL, antilog, antilogODD — по странице (tools/convert/logs.py)
LOGL	equ	LOG + 0x100
ALOG	equ	LOG + 0x200
ALOGODD	equ	LOG + 0x300
	endif
	align	256
divtab:	incbin	"divtab.bin"		; наклоны коротких отрезков (tools/convert/divtab.py)
font:
	incbin	"font.bin"		; знаки 32–127, 8 байт сверху вниз, бит 7 слева
dials:
	incbin	"dials.bin"		; панель: плоскость бита 0, затем бита 1; по столбцам, 56 байт сверху вниз
rom_end:

; --- переменные слоя Вектора ---
	org	VARS
v_frames:	ds	2		; счётчик кадров
kb_rows:	ds	8		; матрица клавиатуры, 1 — нажата; строка 0 — стрелки, 7 — пробел
kb_mod:		ds	1		; бит 5 — СС, 6 — УС, 7 — РУС/ЛАТ
pal_dirty:	ds	1		; <> 0: прерывание запишет pal_regs в палитру
pal_regs:	ds	16
vars_end:
	assert	vars_end <= WS + 0x0300
	assert	rom_end <= WS

	ifdef	FAST
	ifdef	SCHED
	savebin	"v06c/build/elite_fast_t.rom", 0x0100, rom_end - 0x0100
	else
	savebin	"v06c/build/elite_fast.rom", 0x0100, rom_end - 0x0100
	endif
	else
	ifdef	SCHED
	savebin	"v06c/build/elite_t.rom", 0x0100, rom_end - 0x0100
	else
	savebin	"v06c/build/elite.rom", 0x0100, rom_end - 0x0100
	endif
	endif
