; set indexes for our charset
charset '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ:./ ',0

;; render a digit to screen
;; entry:
;;	A: digit to render (0-9)
;;	DE: screen address (of top-left of char)
;; modifies:
;;	AF,BC,DE,HL
char_render_digit
		cp ' '		; if space character then render nothing
		ret z

		ld h,0		; HL = 22 x A
		ld l,a
		ld b,h
		ld c,l
		add hl,hl
		add hl,hl
		add hl,hl
		add hl,bc
		add hl,bc
		add hl,bc
		add hl,hl
		ld bc,char_data_0
		add hl,bc
		;; fall through to char_render...

;; render a character to screen (2x11 bytes)
;; entry:
;;	DE: screen address (of top-left of char)
;;	HL: character data
;; modifies:
;;	AF,BC,DE,HL
char_render
		ld bc,#800 + #3e + 16		;; [3] we want C to equal #3e after 16 LDI instructions
repeat 7
		ldi:ldi				;; [10] copy two bytes
		dec de:dec de			;; [4] reset to left of char
		ld a,d:add a,b:ld d,a		;; [3] move to next row (add de,#800)
rend
		ldi:ldi				;; [10] copy two bytes

		ld b,#c8			;; [2] move to next character line
		ex hl,de			;; [1] add de,#c83e (-2048 * 7 + 64 - 2)
		add hl,bc			;; [3]
		ex hl,de			;; [1]
		ld b,8				;; [2]
repeat 2
		ldi:ldi				;; [10] copy two bytes
		dec de:dec de			;; [4] reset to left of char
		ld a,d:add a,b:ld d,a		;; [3] move to next row (add de,#800)
rend
		ldi:ldi				;; [10] copy two bytes

		ret				;; [3]

; render a string of characters to screen
; entry:
;	DE: screen address (of top-left of first char)
;	HL: points to string (terminated by last char having MSB set - http://rasm.wikidot.com/syntax:data-structures#toc4)
; modifies:
;	pretty much everything!
render_string
		ld a,(hl)
		bit 7,a
		jp nz,.render_last_char

		push de,hl
		call char_render_digit
		pop hl,de
		inc hl
		inc e
		inc e
		jr render_string
.render_last_char
		res 7,a
		jp char_render_digit

include "sprites/char-data.asm"
