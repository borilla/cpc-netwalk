connections_screen_addr	equ #c000
moves_screen_addr	equ #c010
rotations_screen_addr	equ #c020

; ----------------------------------------------------------

;; initialise connected terminals info
connections_init
		xor a
		ld (terms_total_rendered),a
		ld (terms_conn_rendered),a

		ld de,connections_screen_addr
		ld hl,.message
		jp render_string
.message	str '00/00'

; ----------------------------------------------------------

;; initialise moves count
moves_init
		ld hl,0
		ld (moves_data_count),hl
		ld (moves_data_rendered),hl

		ld de,moves_screen_addr
		ld hl,.message
		jp render_string
.message	str 'M:0000'

; ----------------------------------------------------------

;; initialise rotations count
rotations_init
		ld hl,0
		ld (rotations_data_count),hl
		ld (rotations_data_rendered),hl

		ld de,rotations_screen_addr
		ld hl,.message
		jp render_string
.message	str 'R:0000'

; ----------------------------------------------------------

;; increment moves count
moves_inc
		ld hl,moves_data_count
		jp inc_decimal_word

; ----------------------------------------------------------

;; increment rotations count
rotations_inc
		ld hl,rotations_data_count
		;; fall through...

; ----------------------------------------------------------

;; increment binary-coded-decimal word in memory
;; note: will roll around from 9999 to 0000
;; entry:
;;		HL: address of word
;; modifies:
;;		A,HL
inc_decimal_word
		or a			;; clear carry flag (before DAA)
		ld a,(hl)		;; inc low byte
		inc a
		daa
		ld (hl),a

		ret nc			;; no carry, so don't need to update high byte

		or a			;; clear carry
		inc hl
		ld a,(hl)		;; inc high byte
		inc a
		daa
		ld (hl),a

		ret

; ----------------------------------------------------------

connections_render
		ld a,(maze_terms_connected)
		ld hl,terms_conn_rendered
		ld de,connections_screen_addr
		call render_digit_pair
		ld a,(maze_terms_total)
		ld hl,terms_total_rendered
		ld de,connections_screen_addr + 6
		jp render_digit_pair

; ----------------------------------------------------------

moves_render
		ld a,(moves_data_count+1)
		ld hl,moves_data_rendered+1
		ld de,moves_screen_addr + 4
		call render_digit_pair
		ld a,(moves_data_count)
		ld hl,moves_data_rendered
		ld de,moves_screen_addr + 8
		jp render_digit_pair

; ----------------------------------------------------------

rotations_render
		ld a,(rotations_data_count+1)
		ld hl,rotations_data_rendered+1
		ld de,rotations_screen_addr + 4
		call render_digit_pair
		ld a,(rotations_data_count)
		ld hl,rotations_data_rendered
		ld de,rotations_screen_addr + 8
		;; fall through...

; ----------------------------------------------------------

;; render a (bcd or hex) byte value as two digits
;; compares each digit against rendered value to decide whether to render
;; entry:
;;		A: current value
;;		HL: address of rendered value
;;		DE: screen location (of high/left digit)
;; modifies:
;;		A,BC,DE,HL
render_digit_pair
		ld c,a			;; C = current value
		xor (hl)		;; A = xored difference between rendered and current
		ret z			;; rendered = current, no need to render

		ld (hl),c		;; update rendered value
		ld b,a			;; B = xored difference
.high_digit
		and %11110000		;; has high digit changed?
		jr z,.low_digit		;; no, check low digit

		ld a,c			;; yes, render high digit
		and %11110000
		rrca
		rrca
		rrca
		rrca
		push bc
		push de
		call char_render_digit
		pop de
		pop bc
.low_digit
		ld a,b			;; has low digit changed?
		and %00001111
		ret z			;; no, return

		ld a,c			;; yes, render low digit
		and %00001111
		inc de
		inc de
		jp char_render_digit

; ----------------------------------------------------------

moves_data_count	defw 0
moves_data_rendered	defw 0
rotations_data_count	defw 0
rotations_data_rendered	defw 0
terms_total_rendered	defb 0
terms_conn_rendered	defb 0
