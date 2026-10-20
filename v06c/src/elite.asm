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

	ifdef	SCHED
	define	WPTOUCH			; BLINE отмечает, что новая окружность писала X1..Y2 (wp_touch): равенство с BBC
	endif
	ifdef	MERID
	ifndef	WPTOUCH
	define	WPTOUCH
	endif
	endif
	ifdef	MERID
	define	NOMUS			; без мелодии заставки: не хватает места
	endif
	ifdef	SCENE
	define	NOMUS
	endif
	ifndef	SCHED
	ifndef	MERID
	define	PCIRC			; окружность планеты точками (pcirc в planet.asm)
	endif
	endif

	include	"bbc_vars.inc"

	jp	entry
	include	"front.asm"		; командир по умолчанию, товары, мелкие таблицы — до границы страницы
	assert	$ <= 0x0200
	ifndef	SCHED
	include	"st_ends.asm"		; в пустоту выравнивания
	assert	$ <= 0x0200
	endif
	align	256
	include	"keys.asm"		; таблицы клавиш: им нужна граница в 128 байт
entry:
	di
	ld	sp, STACK
	ifdef	SCHED
	ld	a, 0xC3			; JP isr в векторе RST 7
	ld	(0x0038), a
	ld	hl, isr
	ld	(0x0039), hl
	else
	call	low_init		; JP isr в 0038h и код для нижней памяти — на место, пока источник цел
	endif
	ld	hl, WS			; обнулить рабочие области (стек лежит внутри них — поэтому не подпрограммой):
	ifdef	SCHED
	ld	bc, 0x0900		; сначала до блоков кораблей — в них в образе лежит заставка с Сатурном
	else
	ld	bc, 0x0800		; обычный образ: и до страницы стека — в ней лежит код запуска (init_*.asm)
	endif
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
	ifndef	SCHED
	call	joy_init
	ld	a, (sat_skip)		; заставка загрузчика BBC: надписи и Сатурн (saturn.asm); стенд её пропускает
	or	a
	call	z, sat_show
	endif
	call	dash_show
	call	div_init		; таблица наклонов строится на месте уже распакованной картинки панели
	ifndef	SCHED
	ld	a, (sat_skip)
	or	a
	jp	nz, sat_done
	dec	a
	ld	(ENERGY), a		; чтобы обработчик кадра не включил цвет тревоги
	ei
	call	sat_wait		; до клавиши
	di
sat_done:
	endif
	ld	hl, WS + 0x0900		; остаток рабочих областей — вместе с кодом заставки и второй плоскостью панели
	ld	bc, 0x0700
ws_clr2:
	ld	(hl), 0
	inc	hl
	dec	bc
	ld	a, b
	or	c
	jp	nz, ws_clr2
	ld	hl, 0x94C7		; генератор случайных чисел: игра его не засевает, на BBC в нём след загрузчика
	ld	(RAND), hl
	ld	hl, 0x1D27
	ld	(RAND + 2), hl
	call	joy_init		; состояние покоя джойстиков
	ld	a, 0xFF		; печать описаний и текстов миссий: не внутри слова, без «одной прописной»
	ld	(pd_w2), a
	ld	(pd_w8), a
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
	ifdef	SCHED
	include	"dash.asm"
	endif
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
	include	"dockit.asm"
	include	"hangar.asm"
	include	"discmis.asm"
	include	"newb.asm"
	ifdef	SCENE
	include	"scene.asm"		; тестовая сцена (elite_sun.rom)
	endif

	ifndef	SCHED
	define	NOXX21			; обычный образ: таблица моделей — XX21X (ships_zx.asm)
	endif
	include	"ships.asm"		; модели кораблей: XX21 — таблица адресов
	include	"python.asm"
	include	"ships_zx.asm"		; корабли версии ZX: Krait, Asp Mk II, Fer-de-Lance; XX21X
	ifdef	RUS
	include	"words_ru.asm"		; русский словарь QQ18 и пары QQ16R (tools/convert/words_ru.py)
	else
	include	"words.asm"		; словарь QQ18
	endif
	ifdef	RUS
	include	"tkn1_ru.asm"		; русские описания и миссии (tools/convert/tkn1_ru.py)
	else
	include	"tkn1.asm"		; словарь описаний планет; кончается парами букв, продолжение которых — QQ16
	endif
	include	"qq16.asm"
	ifndef	RUS
	assert	QQ16 == pd_tkn2 + 26
	endif
font:
	ifdef	RUS
	incbin	"font_ru.bin"		; на месте строчных — русские прописные (КОИ-7)
	else
	incbin	"font.bin"		; знаки 32–127, 8 байт сверху вниз, бит 7 слева
	endif
; Панель, сжатая (tools/convert/dials_rle.py): по столбцам, 56 байт сверху вниз; нужна один раз, при запуске.
; Таблица наклонов коротких отрезков (1024 байта с границы страницы) в образе не лежит: div_init строит её после
; распаковки панели. В образе стенда картинка (обе плоскости подряд) лежит в конце игры, таблица — поверх неё.
; В обычном образе таблица — последние 1024 байта перед рабочими областями, код и данные игры кончаются до неё;
; на её месте в образе лежит первая плоскость картинки, вторая — в рабочих областях за заставкой загрузчика.
	ifdef	SCHED
dials:
	incbin	"dials.rle"
rom_end:
divtab		equ	(dials + 255) & 0xFF00
	assert	divtab + 1024 <= rom_end
	else
rom_end:
divtab		equ	WS - 0x0400
	assert	rom_end <= divtab
	org	divtab
dials:
	incbin	"dials0.rle"		; плоскость бита 0
	include	"dash.asm"		; распаковка панели — тоже здесь: нужна до постройки таблицы
	assert	$ <= WS
	endif

; --- переменные слоя Вектора ---
	org	VARS
kb_rows:	ds	8		; матрица клавиатуры, 1 — нажата; строка 0 — стрелки, 7 — пробел (с границы страницы: fk_bit)
	ifndef	SCHED
fly_raw:	ds	8		; матрица с клавиатуры (isr); kb_rows — она же после перевода полёта и джойстика
kb_chg:		ds	1		; <> 0 — матрица или джойстик изменились с прошлого перевода (сразу за fly_raw)
	endif
kb_mod:		ds	1		; бит 5 — СС, 6 — УС, 7 — РУС/ЛАТ (в стенде — сразу за kb_rows)
v_frames:	ds	2		; счётчик кадров
	ifdef	RUS
lat:		ds	1		; <> 0 — буквы латиницей (название системы, имя, «_» в словаре)
	endif
	ifndef	SCHED
mus_p:		ds	2		; мелодия заставки: следующая нота (0 — молчит)
mus_t:		ds	1		; кадров до следующей ноты
txt_g:		ds	1		; FFh — текст зелёным (шапка рынка)
tt_mask:	ds	1		; маска знака во второй плоскости: FFh — зелёный, 0 — бежевый
joy_bits:	ds	1		; нажатое на джойстике (isr)
fly_on:		ds	1		; <> 0 — главный цикл в полёте (DOKEY), не пауза: fly_keys переводит клавиши
kb_md:		ds	1		; FFh — kb_rows переведена для полёта, 0 — как есть
	assert	high kb_rows == high (kb_rows + 8)
	assert	low kb_rows == 0 && high fly_raw == high kb_rows && high (fly_raw + 7) == high kb_rows
	assert	kb_chg == fly_raw + 8 && kb_mod == kb_chg + 1
	endif
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
pd_w1:		ds	1		; 20h — буквы строчные, 0 — прописные
pd_cap:		ds	1		; <> 0 — знаки идут в буфер выравнивания
pd_zz:		ds	1		; 256 - номер системы, найденной TT111
sun_q:		ds	1		; корень предыдущей строки солнца (planet.asm)
auto:		ds	1		; <> 0 — автопилот стыковки ведёт корабль (dockit.asm)
ll_sh:		ds	156		; копия прежнего списка отрезков корабля (самый длинный — 153 байта + длина + запас)
tp_buf		equ	ll_sh		; блок с ленты: читается не во время рисования
vars_end:
	assert	vars_end <= WS + 0x0300
; свободные байты рабочих областей: за переменными пилота и за настройками
	org	WS + 0x0372
save_used:	ds	1		; в памяти есть сохранение этого сеанса
save_slot:	ds	NT + 2		; файл командира
newb:		ds	NOSH + 1	; флаги поведения кораблей по местам (newb.asm)
nb_pre:		ds	1		; добавка к флагам следующего нового корабля
	ifndef	SCHED
; переменные игры, которым не нужно место в образе (нулевые при запуске; в образе стенда — в коде, как раньше)
ex_t:		ds	1		; тип цели, сбитой ракетой (для счёта очков)
ex_s:		ds	1		; место цели ракеты · 2
mch_x:		ds	1		; номер своего сообщения на экране (0 — на экране слово игры MCH)
mf_cnt:		ds	1
leak_say:	ds	1
cloak_on:	ds	1		; скрывающее устройство включено
cloak_key:	ds	1
asp_out:	ds	1		; Asp со скрывающим устройством уже выходил в этой системе
nova_t:		ds	2
ll_on:		ds	1		; прежних отрезков осталось стереть
ll_nn:		ds	1		; новых отрезков осталось нарисовать
ll_edge:	ds	1		; рёбра уже писали XX15
ll_lp:		ds	1		; луч: записан только x (1) или x и y (2)
ll_lx:		ds	1
ll_np:		ds	2
ll_op:		ds	2
ll9_cy:		ds	1		; перенос 6502 на входе LL9 из главного цикла полёта (бит 0)
tp_inv:		ds	1
sn_x:		ds	2
sn_y:		ds	2
sp_last:	ds	2		; кадр последней проверки появления
pc_s:		ds	4		; быстрая окружность на экране: x (слово), y, радиус
pc_n:		ds	4		; новая
pc_d:		ds	2
pc_m3:		ds	1
pc_m4:		ds	1
st_j:		ds	1		; штрихи пыли: нарисовать след в конце ближайшего STARS (ставит wa_zx)
st_fx:		ds	1		; след прыжка на экране (сразу за st_j)
sun_r:		ds	2		; солнце (planet.asm): остаток K² - V² - q² для полуширины q
sun_rp:		ds	2		; солнце: указатель на «случайные» байты бахромы
pc_kv:		ds	1		; планета (planet.asm, pc_two): сдвиг строк прежней окружности
sun_t:		ds	1		; солнце (sun_red): кадр (младший байт v_frames), когда рисовалось
	endif
	assert	$ <= WS + 0x0400
	org	WS + 0x0F51
wp_sx:		ds	80		; копия прежней окружности планеты
wp_sy:		ds	80
	ifndef	SCHED
	endif
	assert	$ <= WS + 0x1000
	assert	rom_end <= WS
	ifndef	SCHED
; Нижняя память (0000h–00FFh) в образ не входит и игрой не занята (кроме JP isr в 0038h; 0006h — возврат вызовов
; стенда тестов). Сюда при запуске (low_init, первым делом в entry) копируются JP isr и код, которому нет места в игре.
; Источник лежит на месте таблицы умножения SQLO: она строится позже, после обнуления рабочих областей.
	org	SQLO
low_a:
	disp	0x0038
	jp	isr			; вектор RST 7 — прерывание кадра
	include	"wp_a.asm"
	include	"fk_bit.asm"
	ifndef	SCHED
sun_ck:	ds	5			; солнце на экране (sun_red): x, y по слову, радиус
	endif
	assert	$ <= 0x0100
	ent
low_b:
	disp	0x0007
	include	"wp_b.asm"
	include	"wp_v.asm"
	include	"st_cx.asm"
	assert	$ <= 0x0038
	ent
low_c:
	disp	0x0000
	include	"st_cv.asm"
	assert	$ <= 0x0006
	ent
low_end:
; low_init: код для нижней памяти — на место; зовётся один раз из entry, до обнуления рабочих областей.
low_init:
	ld	hl, low_a
	ld	de, 0x0038
	ld	bc, low_b - low_a
	call	li_cp
	ld	hl, low_c
	ld	de, 0x0000
	ld	bc, low_end - low_c
	call	li_cp
	ld	hl, low_b
	ld	de, 0x0007
	ld	bc, low_c - low_b
li_cp:
	ld	a, (hl)
	ld	(de), a
	inc	hl
	inc	de
	dec	bc
	ld	a, b
	or	c
	jp	nz, li_cp
	ret
	assert	$ <= SQLO + 0x0400
	org	WS + 0x0800		; код, нужный один раз при запуске, — в низу страницы стека (стек идёт сверху)
	include	"init_div.asm"
	include	"init_sq.asm"
	include	"init_cls.asm"
	assert	$ <= WS + 0x08A0
	org	WS + 0x0900		; заставка загрузчика: в образе есть, после показа обнуляется
	include	"saturn.asm"
dials2:
	incbin	"dials1.rle"		; плоскость бита 1 панели: после распаковки обнуляется вместе с заставкой
	assert	$ <= WS + 0x1000
IMG_END		equ	$
	else
IMG_END		equ	rom_end
	endif

	ifdef	RUS
	savebin	"v06c/build/elite_ru.rom", 0x0100, IMG_END - 0x0100
	else
	ifdef	MERID
	ifdef	SCHED
	savebin	"v06c/build/elite_merid_t.rom", 0x0100, IMG_END - 0x0100
	else
	savebin	"v06c/build/elite_merid.rom", 0x0100, IMG_END - 0x0100
	endif
	else
	ifdef	SCHED
	savebin	"v06c/build/elite_t.rom", 0x0100, IMG_END - 0x0100
	else
	ifdef	SCENE
	savebin	"v06c/build/elite_sun.rom", 0x0100, IMG_END - 0x0100
	else
	savebin	"v06c/build/elite.rom", 0x0100, IMG_END - 0x0100
	endif
	endif
	endif
	endif
