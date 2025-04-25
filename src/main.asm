;; ----------------------------------------------------------------
;; include macros
;; ----------------------------------------------------------------

include "lib/macros.asm"

;; ----------------------------------------------------------------

main
		call clear_screen
		call setup_screen
		call music_toggle
		call setup_interrupts
		ld hl,game_state_new_game
		call set_game_state
.loop
main_loop	equ $+1
		call #0000			; call (main_loop)
		jr .loop

;; ----------------------------------------------------------------

; set currently allowed actions, interrupts and main-loop
; entry:
;	HL: points to game-state
set_game_state
		ld de,movement_actions_mask
		ldi
		ldi
		call assign_interrupts		; will advance hl by 24 bytes
		ld de,main_loop
		ldi
		ldi
		ret

;; ----------------------------------------------------------------

game_state_new_game
		; movement_actions_mask
		defb %11111111
		; other_actions_mask
		defb %11111111
		; interrupt_table 1
		defw noop			; 0
		defw noop			; 1
		defw read_actions		; 2
		defw noop			; 3
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
		call time_init
		call connections_init
		call moves_init
		call rotations_init

		ld hl,rand16+2			;; update (high byte of) random number generator
		ld a,r
		add (hl)
		ld (hl),a

		ld a,(grid_size)
		call tile_calculate_origin
		call maze_generate
		ld a,(grid_size)
		call maze_random_cell		;; choose random cell for power supply
		ld (tile_index_supply),a
		ld (tile_index_selected),a
		call recalc_connected_tiles	;; all tiles are initially connected so this will return total number of terminals (in A)
		ld (maze_terms_total),a
		call maze_shuffle
		ld a,(tile_index_supply)
		call recalc_connected_tiles	;; maze has been shuffled so this will correctly calculate initial connected terminals (in A)
		call connections_render
		call render_all_tiles

.wait_for_key_release
		ld hl,(movement_actions_cur)
		ld a,h
		or l
		jr nz,.wait_for_key_release

		ld hl,game_state_playing
		call set_game_state

;; ----------------------------------------------------------------

set_palette_black
		ga_set_pen 1,ink_black
		ga_set_pen 2,ink_black
		ga_set_pen 3,ink_black
		ret

;; ----------------------------------------------------------------

;; set mode, screen size, colours etc
;; disable firmware interrupts before calling
setup_screen	;; set screen mode
		ga_select_mode 1		;; mode 1
		;; set screen origin
		crtc_set_screen_address #c000,0	;; page &c000, offset 0
		;; set screen size
		crtc_write_register crtc_horizontal_displayed,32	;; 32 characters, 64 bytes, 256 mode 1 pixels
		crtc_write_register crtc_horizontal_sync_position,42
		crtc_write_register crtc_vertical_displayed,32		;; 32 characters, 256 pixels
		crtc_write_register crtc_vertical_sync_position,34
		;; set pen colors
		ga_set_pen 16,ink_black		;; border
		ga_set_pen 0,ink_black		;; background and outlines
		ga_set_pen 1,ink_pastel_blue	;; tile background
		ga_set_pen 2,ink_sky_blue	;; tile outline/text shadows
		ga_set_pen 3,ink_lime		;; power flow/text colour
		ret

;; ----------------------------------------------------------------

clear_screen	ld hl,#c000
		ld de,#c001
		ld bc,#3fff
		ld (hl),l
		ldir
		ret

;; ----------------------------------------------------------------

process_other_actions
		ld a,(other_actions_new)	; get (high byte of) new actions
		bit action_m_bit,a		; is 'm' key pressed
		jp nz,music_toggle
		bit action_p_bit,a		; is 'p' key pressed
		jp nz,pause_toggle
		bit action_q_bit,a		; is 'q' key pressed
		jp nz,enlarge_grid
		bit action_a_bit,a		; is 'a' key pressed
		jp nz,shrink_grid
		bit action_r_bit,a		; is 'r' key pressed
		jp nz,new_game
		ret

;; ----------------------------------------------------------------

new_game
		ld hl,game_state_new_game
		jp set_game_state

;; ----------------------------------------------------------------

enlarge_grid
		ld a,(grid_size)
		cp #ff			;; check if already max size (15x15)
		jr z,new_game
		add #11			;; add 16+1
		ld (grid_size),a
		jr new_game

;; ----------------------------------------------------------------

shrink_grid
		ld hl,grid_size
		ld a,(hl)
		cp #33			;; check if already min size (3x3)
		jp z,new_game
		sub #11			;; subtract 16+1
		ld (grid_size),a
		jr new_game

;; ----------------------------------------------------------------
;; includes
;; ----------------------------------------------------------------

include "lib/interrupts.asm"
include "lib/scan_keyboard.asm"
include "lib/rand16.asm"
include "actions.asm"
include "tile.asm"
include "char.asm"
include "time.asm"
include "moves.asm"
include "maze.asm"
include "pause.asm"
include "play.asm"
include "music/music.asm"

;; ----------------------------------------------------------------
;; data
;; ----------------------------------------------------------------

grid_size		defb #aa	; initial size (10x10)
