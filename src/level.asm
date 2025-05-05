
game_state_level
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

		ld hl,options_level
		ld a,(game_level)		; set selected option to current game level
		ld (hl),a
		call options_show

		assign_interrupt 0,set_palette_logo
		assign_interrupt 2,set_palette_text
		assign_interrupt 6,set_palette_logo
		assign_interrupt 8,set_palette_text

		ld hl,noop
		ld (main_loop),hl
		ret

; ----------------------------------------------------------

set_game_level
.easy
		ld hl,options_menu.level_easy
		ld (options_menu + 4),hl
		xor a
		jr .set_level
.medium
		ld hl,options_menu.level_medium
		ld (options_menu + 4),hl
		ld a,1
		jr .set_level
.hard
		ld hl,options_menu.level_hard
		ld (options_menu + 4),hl
		ld a,2
		jr .set_level
.expert
		ld hl,options_menu.level_expert
		ld (options_menu + 4),hl
		ld a,3
.set_level
		ld (game_level),a
		ld hl,game_state_menu
		jp set_game_state

; ----------------------------------------------------------

options_level
		defb 0				; selected option
		defb 4				; count of options
		defw .easy,.medium,.hard,.expert
.easy
		defw set_game_level.easy	; subroutine
		centre_text,14,6		; screen position
		str 'EASY'			; option text
.medium
		defw set_game_level.medium	; subroutine
		centre_text 16,8		; screen position
		str 'MEDIUM'			; option text
.hard
		defw set_game_level.hard	; subroutine
		centre_text 18,6		; screen position
		str 'HARD'			; option text
.expert
		defw set_game_level.expert	; subroutine
		centre_text 20,8		; screen position
		str 'EXPERT'			; option text

; ----------------------------------------------------------

game_level	defb 1				; current game level
grid_sizes	defb #66,#99,#cc,#ff		; grid sizes corresponding to game levels
