include "lib/inks.asm"
include "lib/keys.asm"
include "lib/gate_array.asm"
include "lib/crtc.asm"

;; could use "IN F,(C)" [#ED70] undocumented opcode, which reads direct from port to F register
;; unfortunately, this works in ACE emulator but not in WinAPE!
;; see https://cpcrulez.fr/coding_antoine_05c-Z80-les_codes_speciaux.htm
macro wait_for_vsync
		ld b,#f5	;; B = I/O address of PPI port B
		;; if vsync is currently active then wait for it to finish
@loop_1		in a,(c)	;; read PPI port B input into A
		rra		;; rotate bit 0 (vsync) into carry
		jr nc,@loop_1	;; if carry=1 then vsync is active
		;; wait for next vsync to start
@loop_2		in a,(c)	;; read PPI port B input into A
		rra		;; rotate bit 0 (vsync) into carry
		jr c,@loop_2	;; if carry=1 then vsync is active
mend

;; index 0-5, 6-11, from top to bottom of screen
macro assign_interrupt index,handler
		ld hl,{handler}
		ld (interrupt_{index}),hl
mend

macro wait_for_interrupt,index
@loop		halt
		ld a,(interrupt_index)	;; [4]
		cp 6 - index		;; [2]
		jr nz,@loop
mend

;; call address in hl, ie "call (hl)" (3 bytes, 6 nops [total including jump])
macro call_hl
		call jump_to_hl	;; (defined in interrupts.asm)
mend

;; set all bits of a to same as carry
macro ld_a_carry
		sbc a,a
mend

;; add a to hl (5 bytes, 5 nops)
macro add_hl_a
		add a,l		;; [1] 85
		ld l,a		;; [1] 6f
		adc h		;; [1] 8c
		sub l		;; [1] 95
		ld h,a		;; [1] 67
mend

;; add a to de (5 bytes, 5 nops)
macro add_de_a
		add a,e		;; [1] 85
		ld e,a		;; [1] 6f
		adc d		;; [1] 8c
		sub e		;; [1] 95
		ld d,a		;; [1] 67
mend

;; z will be set if key was pressed at last call to scan_keyboard
macro check_key key
@line		equ {key} >> 3
@bit		equ {key} & 7
		ld a,(scan_keyboard_lines + @line)
		bit @bit,a
mend

;; colour table contains 17 colours (16 pens plus border)
macro set_pen_colours colour_table
		;; start at border and count down
		ld hl, colour_table + 17
		ld a,17
		ld b,#7f
@loop		dec hl
		dec a
		ld c,(hl)
		out (c),a
		out (c),c
		jr nz,@loop
mend

;; define symbol to value of a mode 0 byte with specified pens for left and
;; right pixels e.g. "equ_mode_0_byte background_byte,1,2"
;; (syntax is a bit awkward but function is very handy)
macro equ_mode_0_byte symbol,pen_left,pen_right
@bit_0		equ pen_right and %1000 / %1000 * %00000001
@bit_2		equ pen_right and %0010 / %0010 * %00000100
@bit_4		equ pen_right and %0100 / %0100 * %00010000
@bit_6		equ pen_right and %0001 / %0001 * %01000000
@right_pixel	equ @bit_0 + @bit_2 + @bit_4 + @bit_6

@bit_1		equ pen_left and %1000 / %1000 * %00000010
@bit_3		equ pen_left and %0010 / %0010 * %00001000
@bit_5		equ pen_left and %0100 / %0100 * %00100000
@bit_7		equ pen_left and %0001 / %0001 * %10000000
@left_pixel	equ @bit_1 + @bit_3 + @bit_5 + @bit_7

symbol		equ @right_pixel + @left_pixel
mend
