; Elite / Вектор-06Ц (i8080, 48 КБ + две плоскости). Основа — кассетная версия BBC Micro.
; Карта памяти — docs/spec/v06c-memory.md. Имена переменных и процедур игры — как в исходнике BBC.
	device	noslot64k
	org	0x0100

WS		equ	0xB000		; рабочие области: адрес BBC &0000–&0F3F + WS
VARS		equ	WS + 0x0200	; переменные слоя Вектора (на BBC здесь векторы системы)
STACK		equ	WS + 0x0900	; стек растёт вниз от K%
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
	ld	bc, 0x0F40
ws_clr:
	ld	(hl), 0
	inc	hl
	dec	bc
	ld	a, b
	or	c
	jp	nz, ws_clr
	call	cls_all
	ld	hl, pal_flight
	call	pal_set
	call	dash_show
	call	demo_text
	ei
main:
	call	wait_frame
	call	demo_keys
	jp	main

	include	"sys.asm"
	include	"text.asm"
	include	"dash.asm"
	include	"line.asm"
	include	"demo.asm"

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
demo_old:	ds	9
vars_end:
	assert	vars_end <= WS + 0x0300
	assert	rom_end <= WS

	savebin	"v06c/build/elite.rom", 0x0100, rom_end - 0x0100
