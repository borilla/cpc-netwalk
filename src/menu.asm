
game_state_menu
		; movement_actions_mask
		defb %00000101			; up + down
		; other_actions_mask
		defb %00000001			; select
		; interrupt_table 1
		defw noop			; 0 (will be set to set_palette_logo later)
		defw read_actions		; 1
		defw noop			; 2 (will be set to set_palette_text later)
		defw noop			; 3
		defw music_play			; 4
		defw process_option_actions	; 5
		; interrupt_table 2
		defw noop			; 6 (will be set to set_palette_logo later)
		defw noop			; 7
		defw noop			; 8 (will be set to set_palette_text later)
		defw noop			; 9
		defw music_play			; 10
		defw noop			; 11
		; main loop
		defw .main_loop
.main_loop
		call set_palette_black
		call clear_screen
		call show_logo

		ld hl,options_menu
		xor a
		call options_show

		assign_interrupt 0,set_palette_logo
		assign_interrupt 2,set_palette_text
		assign_interrupt 6,set_palette_logo
		assign_interrupt 8,set_palette_text

		ld hl,noop
		ld (main_loop),hl
		ret

; ----------------------------------------------------------

show_logo
		ld de,logo_data
		ld hl,#C000
		ld ixh,64
		jr .render_line
.next_line
		ex hl,de
		ld bc,#0800 - #40
		add hl,bc
		jr nc,.render_line
		ld bc,#c000 + #40
		add hl,bc
.render_line
		ex hl,de
		ld bc,#0040
		ldir
		dec ixh
		jr nz,.next_line
		ret

; ----------------------------------------------------------

select_level
		ld hl,game_state_level
		jp set_game_state

; ----------------------------------------------------------

set_palette_logo
		ga_set_pen 1,ink_bright_white
		ga_set_pen 2,ink_bright_magenta
		ga_set_pen 3,ink_magenta
		ret

; ----------------------------------------------------------

options_menu
		defb 4				; count of options
		defw .intro,.level_medium,.options,.play
.intro
		defw noop			; subroutine
		centre_text,14,7		; screen position
		str 'INTRO'			; option text
.level_easy
		defw select_level		; subroutine
		centre_text 16,12		; screen position
		str 'LEVEL:EASY'		; option text
.level_medium
		defw select_level		; subroutine
		centre_text 16,13		; screen position
		str 'LEVEL:MEDIUM'		; option text
.level_hard
		defw select_level		; subroutine
		centre_text 16,12		; screen position
		str 'LEVEL:HARD'		; option text
.level_expert
		defw select_level		; subroutine
		centre_text 16,14		; screen position
		str 'LEVEL:EXPERT'		; option text
.options
		defw noop			; subroutine
		centre_text 18,9		; screen position
		str 'OPTIONS'			; option text
.play
		defw start_game			; subroutine
		centre_text 20,6		; screen position
		str 'PLAY'			; option text

; ----------------------------------------------------------

include "sprites/logo_data.asm"
