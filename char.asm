;; render a character to screen
;; entry:
;;	DE: screen address (of top-left of char)
;;	HL: sprite data
;; modifies:
;;	AF,BC,DE,HL
char_render
		ld b,8
repeat 7
		ldi				;; [5] copy one byte
		ld a,(hl):ld (de),a: inc l	;; [5] copy byte
		dec e				;; [1] reset to left of char
		ld a,d:add a,b:ld d,a		;; [3] add de,&800
rend
		ldi				;; [5] copy one byte
		ld a,(hl):ld (de),a: inc l	;; [5] copy byte

		ld bc,-2048 * 7 + 64 - 1	;; move to next line
		ex hl,de
		add hl,bc
		ex hl,de
		ld b,8
repeat 3
		ldi				;; [5] copy one byte
		ld a,(hl):ld (de),a: inc l	;; [5] copy byte
		dec e				;; [1] reset to left of char
		ld a,d:add a,b:ld d,a		;; [3] add de,&800
rend
		ldi				;; [5] copy one byte
		ld a,(hl):ld (de),a: inc l	;; [5] copy byte

		ret

align &100
read "maze/char-data.asm"
