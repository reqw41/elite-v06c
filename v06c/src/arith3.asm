; Арифметика кассетной версии BBC, третья партия (задача Q5). Правила — docs/spec/porting.md.
; Регистры: A — как на BBC, X -> B, Y -> C, перенос — как на 6502. После вызова нулевая страница, A, X, Y и
; перенос равны эталону (v06c/test/q5.mjs); отступления названы в заголовке процедуры.

; LL38: (S A) = (S R) + (A Q), знак — бит 7 у S и у A. X, Y не меняются.
; Знаки совпали: A = Q + R (перенос — из сложения), S не меняется.
; Разные знаки: R >= Q → A = R - Q, перенос 0; R < Q → A = Q - R, перенос 0, знак S перевёрнут.
LL38:
	ld	hl, S
	xor	(hl)			; EOR S
	jp	p, ll38_same		; BMI LL39 — бит 7 сброшен, знаки совпали
	ld	a, (R_)			; LDA R
	ld	hl, Q
	sub	(hl)			; SEC : SBC Q (C=1 → заёма нет) — CY=1 ровно при R < Q
	jp	c, ll38_lt		; BCC P%+4 — через две команды: на PHA
	or	a			; CLC
	ret
ll38_same:
	ld	a, (Q)			; LDA Q
	or	a			; CLC
	ld	hl, R_
	adc	a, (hl)			; ADC R — перенос из сложения идёт на выход
	ret
ll38_lt:
	ld	d, a			; PHA — A в регистре: pop af вернул бы старый перенос
	ld	a, (S)			; LDA S
	xor	0x80			; EOR #%10000000
	ld	(S), a			; STA S
	ld	a, d			; PLA
	cpl				; EOR #%11111111 (cpl флаги не меняет)
	or	a			; перенос на входе ADC #1 на BBC равен 0 (BCC ушёл с C=0)
	add	a, 1			; ADC #1 — перенос на выход: 255-x+1, как на 6502
	ret

; TIS2: A = A * 96 / Q, знак — бит 7 у A. Y не меняется.
; |A| >= Q: A = знак | 96, перенос 1, X и T не меняются.
; Иначе: T = частное, X = FEh, перенос 0.
TIS2:
	ld	c, a			; TAY
	and	0x7F			; AND #%01111111
	ld	hl, Q
	cp	(hl)			; CMP Q — CY=1 (i8080) ровно при |A| < Q
	jp	nc, tis2_ti4		; BCS TI4
	ld	e, (hl)			; E = Q
	ld	b, 0xFE			; LDX #%11111110
	ld	a, 0xFE
	ld	(T), a			; STX T (в (nn) пишет только A)
	ld	a, c			; A — исходное: ASL сдвигает бит 7 в перенос, как на BBC
	; цикл: 8 шагов (сторож FEh); в ROL T попадает перенос 6502: 1 при вычитании, 0 при отказе
tis2_loop:
	add	a, a			; ASL A
	cp	e			; CMP Q
	jp	c, tis2_nosub		; BCC P%+4 — через одну команду: на ROL T
	sub	e			; SBC Q (перенос 6502 здесь 1 — заёма нет)
	ld	d, a			; сохранить остаток: ROL T идёт через A
	scf				; ROL T с единицей
	ld	a, (T)
	rla
	ld	(T), a			; CY = бит 7 старого T — его смотрит BCS TIL2
	ld	a, d			; восстановить остаток (ld флаги не меняет)
	jp	tis2_next
tis2_nosub:
	ld	d, a
	ld	a, (T)
	or	a			; ROL T с нулём (на BBC перенос CMP при отказе равен 0)
	rla
	ld	(T), a
	ld	a, d
tis2_next:
	jp	c, tis2_loop		; BCS TIL2 — перенос из ROL T
	; LDA T : LSR A : LSR A : STA T : LSR A : ADC T : STA T
	; LSR A = rrca + and 0x7F (rrca даёт перенос = бит 0, но бит 7 мусорный — маскируем).
	; Перенос от последнего сдвига = бит 2 старого T = бит 0 нового T.
	ld	hl, T
	ld	a, (hl)			; LDA T
	rrca				; LSR A: CY = бит 0 (дальше не нужен)
	and	0x7F
	rrca				; LSR A: CY = бит 1 (не нужен)
	and	0x7F			; A = T >> 2
	ld	(hl), a			; STA T
	rrca				; LSR A: CY = бит 2 — перенос от последнего сдвига
	and	0x7F			; A = T >> 3
	ld	e, a			; E = T >> 3
	add	a, (hl)			; A = T >> 3 + T >> 2 (не переполняется)
	ld	d, a
	ld	a, (hl)
	and	1			; бит 0 нового T = перенос от последнего LSR
	add	a, d			; ADC T: частное <= 95, перенос 0 — как на BBC
	ld	(hl), a			; STA T
	ld	a, c			; TYA
	and	0x80			; AND #%10000000
	or	(hl)			; ORA T — перенос 0, как после ADC на BBC
	ld	b, 0xFE			; LDX #%11111110: на выходе X = FEh
	ret
tis2_ti4:
	ld	a, c			; TYA
	and	0x80			; AND #%10000000
	or	0x60			; ORA #96
	scf				; на BBC BCS ушёл при переноса 1 — он и выходит с RTS
	ret

; DVIDT: (P+1 A) = (A P) / Q, знак — бит 7 у A. X = 0, T = знак, Y не меняется,
; Q на выходе = Q & 01111111b (ASL Q : LSR Q), перенос — из последнего ROL P+1.
DVIDT:
	ld	(P_ + 1), a		; STA P+1
	ld	hl, Q
	xor	(hl)			; EOR Q
	and	0x80			; AND #%10000000
	ld	(T), a			; STA T
	ld	b, 16			; LDA #0 : LDX #16 — обнуление A ниже, перед первым ROL A
	; ASL P : ROL P+1 — переносы ASL/ROL совпадают на обоих процессорах
	ld	hl, P_
	ld	a, (hl)
	add	a, a			; ASL P — CY = бит 7 у P
	ld	(hl), a			; STA (ld флаги не меняет)
	ld	a, (P_ + 1)
	rla				; ROL P+1 — значение P+1, перенос из ASL P
	ld	(P_ + 1), a
	; ASL Q : LSR Q — Q = Q & 01111111b; перенос от LSR Q = 0 (удвоенное Q чётно,
	; бит 0 в LSR Q всегда ноль) — с ним входит в первый ROL A
	ld	a, (Q)
	and	0x7F			; CY = 0 — перенос LSR Q
	ld	(Q), a			; STA Q
	ld	e, a			; E = делитель
	ld	a, 0			; LDA #0 (ld флаги не меняет — CY = 0)
dvidt_loop:
	rla				; ROL A — перенос предыдущего шага (LSR Q или ROL P+1)
	cp	e			; CMP Q
	jp	c, dvidt_nosub		; BCC P%+4 — через одну команду: на ROL P
	sub	e			; SBC Q (перенос 6502 здесь 1 — заёма нет)
	ld	d, a			; сохранить остаток: ROL P и ROL P+1 идут через A
	scf				; ROL P с единицей
	ld	a, (P_)
	rla
	ld	(P_), a			; CY = бит 7 старого P — он входит в ROL P+1
	ld	a, (P_ + 1)
	rla
	ld	(P_ + 1), a		; CY = бит 7 старого P+1 — он входит в ROL A следующего шага
	ld	a, d			; восстановить остаток
	jp	dvidt_dex
dvidt_nosub:
	ld	d, a
	ld	a, (P_)
	or	a			; ROL P с нулём (на BBC перенос CMP при отказе равен 0)
	rla
	ld	(P_), a
	ld	a, (P_ + 1)
	rla
	ld	(P_ + 1), a
	ld	a, d
dvidt_dex:
	dec	b			; DEX — перенос не трогает
	jp	nz, dvidt_loop
	; LDA P : ORA T : RTS — ORA на BBC перенос не трогает, на i8080 or сбрасывает: два выхода
	jp	c, dvidt_c1
	ld	a, (P_)			; LDA P
	ld	e, a
	ld	a, (T)
	or	e			; ORA T — перенос 0
	ret
dvidt_c1:
	ld	a, (P_)			; LDA P
	ld	e, a
	ld	a, (T)
	or	e			; ORA T
	scf				; вернуть перенос последнего ROL P+1
	ret

; LL129: X = XX12+2 (не меняется), Q = XX12+2. При S >= 0: A = S ^ XX12+3, перенос входной.
; При S < 0: R = 0 - R, S = ~S + (R <> 0), A = S ^ XX12+3 (S — входной), перенос = (S = 0 и R <> 0).
; Y не меняется.
LL129:
	ld	l, 0			; перенос входа — в бит 7 L (нужен пути BPL)
	jp	nc, ll129_sv
	ld	l, 0x80
ll129_sv:
	ld	a, (XX12 + 2)
	ld	b, a			; LDX XX12+2 — на выходе X именно таков
	ld	(Q), a			; STX Q
	ld	a, (S)
	or	a			; флаги для BPL (ld флаги не ставит; CY сброс — перенос в L)
	ld	e, a			; сохранить S (вместо PHA — pop af вернул бы старые флаги)
	jp	p, ll129_norm		; BPL LL127
	; LDA #0 : SEC : SBC R : STA R → R = 0 - R; перенос = (R = 0) — он войдёт в ADC #0
	ld	a, (R_)
	cpl
	add	a, 1			; 0 - R: CY = (R = 0), как перенос SBC на BBC
	ld	(R_), a			; STA R
	; LDA S : PHA : EOR #%11111111 : ADC #0 : STA S : PLA
	ld	a, e			; LDA S (ld флаги не меняет — перенос SBC жив)
	cpl				; EOR #%11111111 (cpl флаги не меняет)
	adc	a, 0			; ADC #0 → новое S; перенос на выход = (S = 0 и R <> 0)
	ld	(S), a			; STA S
	; PLA: A = входное S; EOR XX12+3 — ORA на BBC перенос не трогает: два хвоста
	ld	a, e
	ld	hl, XX12 + 3		; L на отрицательном пути уже не нужен
	jp	c, ll129_sc
	xor	(hl)			; EOR XX12+3 — перенос 0
	ret
ll129_sc:
	xor	(hl)			; EOR XX12+3
	scf				; вернуть перенос ADC #0 (pop af вернул бы старые флаги)
	ret
ll129_norm:
	; BPL: перенос входа — в L; A = S, E = S
	ld	a, l
	rlca				; CY = бит 7 L = перенос входа
	ld	a, (XX12 + 3)		; A = XX12+3 (ld флаги не меняет — CY жив)
	ld	d, a
	ld	a, e			; A = S
	jp	c, ll129_nc1
	xor	d			; EOR XX12+3 — перенос 0, как на входе
	ret
ll129_nc1:
	xor	d			; EOR XX12+3
	scf				; вернуть перенос входа
	ret

; LL61: (U R) = 256 * A / Q. Счётчик цикла — X (INX), Y не меняется.
; На выходе: S = число сдвигов LSR до A < Q, X = S, R = 256*A/Q, U — сдвинутое,
; перенос — из последнего ROL U; при BMI (бит 7 у результата ROL U) R = U = A = 50.
; Q = 0: R = U = A = 50, X = 0 (LDX Q уже выполнен), перенос входной.
LL61:
	ld	d, a			; сохранить входное A
	ld	l, 0			; перенос входа — в бит 7 L (нужен пути Q = 0)
	jp	nc, ll61_sv
	ld	l, 0x80
ll61_sv:
	ld	a, (Q)
	ld	b, a			; LDX Q — при Q = 0 на выходе X = 0
	or	a			; флаги для BEQ (ld флаги не ставит)
	jp	z, ll61_50
	ld	e, a			; E = Q
	ld	a, d			; A = входное A (ld флаги не меняет)
	ld	b, 0			; LDX #0
ll61_cnt:
	rrca				; LSR A: CY = бит 0 (не нужен: INX его не трогает, CMP перепишет)
	and	0x7F			; бит 7 мусорный от rrca — чистим
	inc	b			; INX — перенос не трогает
	cp	e			; CMP Q
	jp	nc, ll61_cnt		; BCS LL63 — цикл, пока A >= Q (перенос 6502 = NOT CY i8080)
	ld	e, a			; сохранить A: в (nn) пишет только A
	ld	a, b
	ld	(S), a			; STX S
	ld	a, e			; A = сдвинутое A (ld флаги не меняет)
	call	LL28_4			; A < Q: R = 256 * A / Q, A = остаток, X = FEh, перенос 0
	ld	hl, S
	ld	b, (hl)			; LDX S — X = число сдвигов
	ld	a, (R_)			; LDA R
	ld	hl, U			; ROL U идёт через A
ll61_loop:
	add	a, a			; ASL A — CY = бит 7 у A (перенос в ROL U)
	ld	d, a			; сохранить A: ROL U идёт через A
	ld	a, (hl)
	rla				; ROL U — CY = бит 7 старого U (перенос на выход), A = сдвинутое U
	ld	(hl), a			; STA U (ld флаги не меняет)
	; эмулятор Вектора в ral не выставляет SF — перенос ROL U сохраняем в бите 7 E
	ld	e, 0
	jp	nc, ll61_sv2
	ld	e, 0x80
ll61_sv2:
	rlca				; CY = бит 7 у сдвинутого U — флаги для BMI LL84 (A восстановим)
	jp	c, ll61_84		; BMI LL84 — на 6502 ROL ставит N от результата: бит 7 у U!
	ld	a, d			; восстановить A (ld флаги не меняет)
	dec	b			; DEX — перенос не трогает
	jp	nz, ll61_loop		; BNE LL64
	ld	(R_), a			; STA R
	; перенос на выходе = перенос последнего ROL U = бит 7 у E
	ld	a, e
	rlca				; CY = бит 7 E = перенос ROL U
	ld	a, d			; восстановить A (ld флаги не меняет)
	ret
ll61_84:
	; LL84: LDA #50 : STA R : STA U : RTS — перенос не менялся с ROL U (бит 7 у E)
	ld	a, e
	rlca				; CY = перенос ROL U
	ld	a, 50			; LDA #50 (ld флаги не меняет)
	ld	(R_), a
	ld	(U), a
	ret
ll61_50:
	; LDA #50 : STA R : STA U : RTS — перенос не менялся с входа
	ld	a, l
	rlca				; CY = бит 7 L = перенос входа
	ld	a, 50			; LDA #50 (ld флаги не меняет)
	ld	(R_), a
	ld	(U), a
	ret
