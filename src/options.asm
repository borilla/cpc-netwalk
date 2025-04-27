; ----------------------------------------------------------

; show table of options
; entry:
;	HL: points to options table
;	A: index of currently selected option
options_show
		ld (options_table),hl
		ld (options_selected),a
		ld b,(hl)			; B = count of options
		dec hl
.show_next_option
		inc hl				; HL = address of option
		inc hl
		push hl
		push bc

		ld e,(hl)			; HL = (HL), ie option definition
		inc hl
		ld d,(hl)
		ex de,hl

		inc hl
		inc hl
		ld a,2				; DE = screen position + 2 (leave space for 'selected' chevron)
		add (hl)
		inc hl
		ld d,(hl)
		ld e,a

		inc hl				; HL = points to option text

		call render_string

		pop bc
		pop hl
		djnz .show_next_option

		ld a,(options_selected)		; add chevron to selected option
		ld bc,char_data_gt
		jp options_mark

; ----------------------------------------------------------

; increment selected option
options_inc_selected
		ld de,options_selected
		ld hl,(options_table)
		ld a,(de)
		inc a
		cp (hl)
		ret z				; already at max

		ld (de),a			; update selected value
		dec a

		ld bc,char_data_space		; remove chevron from previously selected option
		call options_mark
		ld a,(options_selected)		; add chevron to newly selected option
		ld bc,char_data_gt
		jp options_mark

; ----------------------------------------------------------

; decrement selected option
options_dec_selected
		ld hl,options_selected
		ld a,(hl)
		or a
		ret z				; already at zero

		dec (hl)			; update selected value

		ld bc,char_data_space		; remove chevron from previously selected option
		call options_mark
		ld a,(options_selected)		; add chevron to newly selected option
		ld bc,char_data_gt
		jp options_mark

; ----------------------------------------------------------

; jump to subroutine for currently selected option
options_select
		ld a,(options_selected)

		ld hl,(options_table)
		add a				; A = 2 * selected + 1
		inc a
		add_hl_a			; HL = option address

		ld a,(hl)			; HL = (HL), ie option definition
		inc hl
		ld h,(hl)
		ld l,a

		ld a,(hl)			; HL = (HL), ie option subroutine
		inc hl
		ld h,(hl)
		ld l,a

		jp (hl)				; jp hl

; ----------------------------------------------------------

; show (or hide) selected mark for option
; entry:
;	A: index of option
;	BC: character data to show ('char_data_space' or 'char_data_gt')
options_mark
		ld hl,(options_table)
		add a				; A = 2 * selected + 1
		inc a
		add_hl_a			; HL = option address

		ld a,(hl)			; HL = (HL), ie option definition
		inc hl
		ld h,(hl)
		ld l,a

		inc hl				; DE = (HL + 2), ie screen position of option
		inc hl
		ld e,(hl)
		inc hl
		ld d,(hl)

		ld h,b				; HL = BC
		ld l,c
		jp char_render

; ----------------------------------------------------------

process_option_actions
		ld a,(movement_actions_new)
		bit action_up_bit,a
		jp nz,options_dec_selected
		bit action_down_bit,a
		jp nz,options_inc_selected
		ld a,(other_actions_new)
		bit action_space_bit,a
		jp nz,options_select
		ret

; ----------------------------------------------------------

options_table		defw 0
options_selected	defb 0

; ----------------------------------------------------------
