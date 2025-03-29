include "lib/keys.asm"

;; scan all keyboard lines and store results
;; see http://www.cpcwiki.eu/index.php/Programming:Keyboard_scanning
;; and http://www.cpcwiki.eu/index.php/8255
scan_keyboard
		ld hl,keyboard_lines	; [3]
		ld bc,#f782		; [3]
		out (c),c		; [4]
		ld bc,#f40e		; [3]
		ld e,b			; [1]
		out (c),c		; [4]
		ld bc,#f6c0		; [3]
		ld d,b			; [1] ld d,#f6
		out (c),c		; [4]
		xor a			; [1] ld a,0
		out (c),a		; [4]
		ld bc,#f792		; [3]
		out (c),c		; [4]
					; [=38]

		ld a,#40		; [2] a is current keyboard line (#40-#4a)
		ld c,d			; [1] ld c,#f6
.loop1
		ld b,d			; [1] ld b,#f6
		out (c),a		; [4] select keyboard line
		ld b,e			; [1] ld b,#f4
		ini			; [5] input line, write to (HL), increment HL (and decrement B)
		inc a			; [1] move to next line
		inc c			; [1] increment count [#f6 + 10 = 0]
		jr nz,.loop1		; [2/3]
					; [=16 * 9 + 15 + 3 = 162]

		ld bc,#f782		; [3]
		out (c),c		; [4]
		ret			; [3]
					; [=38 + 162 + 10 = 210]

; bits are inverted so all keyboard lines start as %11111111
keyboard_lines	defs 10,#ff

;; z will be set if key was pressed at last call to scan_keyboard
macro check_key key
@line		equ {key} >> 3
@bit		equ {key} & 7
		ld a,(keyboard_lines + @line)	; [4]
		bit @bit,a			; [2]
mend
