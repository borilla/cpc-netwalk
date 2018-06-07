;; initialise moves count and render
moves_init
		ld de,&c000
		ld hl,char_data_M
		call char_render
		ld de,&c002
		ld hl,char_data_O
		call char_render
		ld de,&c004
		ld hl,char_data_V
		call char_render
		ld de,&c006
		ld hl,char_data_colon
		call char_render

		ld hl,0
		ld (moves_data_count),hl
		ld hl,&ffff
		ld (moves_data_rendered),hl
		jp moves_render

;; initialise rotations count and render
rotations_init
		ld de,&c019
		ld hl,char_data_R
		call char_render
		ld de,&c01b
		ld hl,char_data_O
		call char_render
		ld de,&c01d
		ld hl,char_data_T
		call char_render
		ld de,&c01f
		ld hl,char_data_colon
		call char_render

		ld hl,0
		ld (rotations_data_count),hl
		ld hl,&ffff
		ld (rotations_data_rendered),hl
		jp rotations_render

;; increment rotations count
rotations_inc
		ld hl,rotations_data_count
		jp inc_decimal_word

;; increment moves count
moves_inc
		ld hl,moves_data_count
		;; fall through...

;; increment binary-coded-decimal word in memory
;; note: will roll around from 9999 to 0000
;; entry:
;;		HL: address of word
;; modifies:
;;		A,HL
inc_decimal_word
		or a			;; clear flags (before DAA)
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

rotations_render
		ld a,(rotations_data_count+1)
		ld hl,rotations_data_rendered+1
		ld de,&c021
		call moves_render_digit_pair
		ld a,(rotations_data_count)
		ld hl,rotations_data_rendered
		ld de,&c025
		jp moves_render_digit_pair

moves_render
		ld a,(moves_data_count+1)
		ld hl,moves_data_rendered+1
		ld de,&c008
		call moves_render_digit_pair
		ld a,(moves_data_count)
		ld hl,moves_data_rendered
		ld de,&c00c
		;; fall through...

;; render a (bcd or hex) byte value as two digits
;; compares each digit against rendered value to decide whether to render
;; entry:
;;		A: current value
;;		HL: address of rendered value
;;		DE: screen location (of high/left digit)
;; modifies:
;;		A,BC,DE,HL
moves_render_digit_pair
		ld c,a			;; keep current value
		xor (hl)		;; get difference between rendered and current
		ret z			;; rendered = current, no need to render

		ld (hl),c		;; update rendered value
		ld b,a			;; keep xored difference
_mrdp_high_digit
		and %11110000		;; has high digit changed?
		jr z,_mrdp_low_digit		;; no, check low digit

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
_mrdp_low_digit
		ld a,b			;; has low digit changed?
		and %00001111
		ret z			;; no, return

		ld a,c			;; yes, render low digit
		and %00001111
		inc de
		inc de
		jp char_render_digit

moves_data_count		defw 0
rotations_data_count		defw 0
moves_data_rendered	defw 0
rotations_data_rendered	defw 0
