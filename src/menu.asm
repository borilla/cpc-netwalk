
game_state_menu
		; movement_actions_mask
		defb %00000101			; up + down
		; other_actions_mask
		defb %00000001			; select
		; interrupt_table 1
		defw noop			; 0
		defw noop			; 1
		defw read_actions		; 2
		defw process_option_actions	; 3
		defw music_play			; 4
		defw noop			; 5
		; interrupt_table 2
		defw noop			; 6
		defw noop			; 7
		defw noop			; 8
		defw noop			; 9
		defw music_play			; 10
		defw noop			; 11
		; main loop
		defw .main_loop
.main_loop
		call set_palette_black
		call clear_screen

		ld hl,.title
		ld de,#C214
		call render_string

		ld hl,options_menu
		xor a
		call options_show

		call set_palette_text

		ld hl,noop
		ld (main_loop),hl
		ret
.title		str 'CIRCUIT BREAK'

; ----------------------------------------------------------

options_menu
		defb 4				; count of options
		defw .intro,.level,.options,.play
.intro
		defw noop			; subroutine
		defw #C312			; screen position
		str 'INTRO'			; option text
.level
		defw noop			; subroutine
		defw #C392			; screen position
		str 'LEVEL'			; option text
.options
		defw noop			; subroutine
		defw #C412			; screen position
		str 'OPTIONS'			; option text
.play
		defw start_game			; subroutine
		defw #C492			; screen position
		str 'PLAY'			; option text
