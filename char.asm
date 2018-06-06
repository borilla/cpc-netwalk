;; render a digit to screen
;; entry:
;;	A: digit to render (0-9)
;;	DE: screen address (of top-left of char)
;; modifies:
;;	AF,BC,DE,HL
char_render_digit
		ld b,a
		add a			;; a = a * 22 (bytes per char)
		add a
		add a
		ld c,a
		add c
		add c
		sub b
		sub b
		ld hl,char_data_0	;; HL = character data
		add_hl_a
		;; fall through to char_render...

;; render a character to screen (2x11 bytes)
;; entry:
;;	DE: screen address (of top-left of char)
;;	HL: character data
;; modifies:
;;	AF,BC,DE,HL
char_render
		ld bc,&800 + &3f + 8		;; we want C to equal &3d after 8 LDI instructions
repeat 7
		ldi				;; [5] copy left byte
		ld a,(hl):ld (de),a:inc l	;; [5] copy right byte
		dec e				;; [1] reset to left of char
		ld a,d:add a,b:ld d,a		;; [3] move to next row (add de,&800)
rend
		ldi				;; [5] copy left byte
		ld a,(hl):ld (de),a:inc l	;; [5] copy right byte

		ld b,&c8			;; move to next line
		ex hl,de			;; add de,&c83f (-2048 * 7 + 64 - 1)
		add hl,bc
		ex hl,de
		ld b,8
repeat 2
		ldi				;; [5] copy left byte
		ld a,(hl):ld (de),a:inc l	;; [5] copy right byte
		dec e				;; [1] reset to left of char
		ld a,d:add a,b:ld d,a		;; [3] move to next row (add de,&800)
rend
		ldi				;; [5] copy left byte
		ld a,(hl):ld (de),a:inc l	;; [5] copy right byte

		ret

align &100
read "maze/char-data.asm"
