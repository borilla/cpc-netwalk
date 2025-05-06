;; ----------------------------------------------------------------
;; include macros
;; ----------------------------------------------------------------

include "lib/macros.asm"

;; ----------------------------------------------------------------

main
		call clear_screen
		call setup_screen
		; call music_toggle
		call setup_interrupts

		ld hl,rand16.seed		; update random seed
		ld a,r
		add (hl)
		ld (hl),a

		ld hl,game_state_menu
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
		xor a				; reset actions
		ld (movement_actions_new),a
		ld (other_actions_new),a

		ld de,movement_actions_mask
		ldi				; copy actions mask
		ldi
		call assign_interrupts		; will advance hl by 24 bytes
		ld de,main_loop
		ldi				; copy main loop address
		ldi
		ret

;; ----------------------------------------------------------------

game_state_start_game
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

		ld hl,(rand16.seed)		; store pseudo-random seeds used to generate maze (so we can restart)
		ld (maze_generate_seed),hl
		ld a,(choose_random_index.seed)
		ld (maze_index_seed),a

		ld a,(game_level)		; set grid size according to current game level
		ld hl,grid_sizes
		add_hl_a
		ld a,(hl)			; A = grid size
		ld (grid_size),a

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
		ld a,(other_actions_new)
		bit action_m_bit,a		; is 'm' key pressed
		jp nz,music_toggle
		bit action_escape_bit,a		; is 'p' key pressed
		jp nz,pause_game
		ret

; ----------------------------------------------------------

start_game
		ld hl,game_state_start_game
		jp set_game_state

; ----------------------------------------------------------

pause_game
		ld hl,game_state_paused
		jp set_game_state

; ----------------------------------------------------------

unpause_game
		ld hl,game_state_playing
		jp set_game_state

; ----------------------------------------------------------

quit_game
		ld hl,game_state_menu
		jp set_game_state

;; ----------------------------------------------------------------

restart_game
		ld hl,(maze_generate_seed)	; restore pseudo-random seeds used to generate maze
		ld (rand16.seed),hl
		ld a,(maze_index_seed)
		ld (choose_random_index.seed),a
		jr start_game

;; ----------------------------------------------------------------
;; includes
;; ----------------------------------------------------------------

include "lib/interrupts.asm"
include "lib/scan_keyboard.asm"
include "lib/rand16.asm"
include "char.asm"			; needs to be included before any 'str' definitions!
include "menu.asm"
include "actions.asm"
include "tile.asm"
include "time.asm"
include "infobar.asm"
include "maze.asm"
include "pause.asm"
include "play.asm"
include "options.asm"
include "level.asm"
include "music/music.asm"

;; ----------------------------------------------------------------
;; data
;; ----------------------------------------------------------------

grid_size		defb 0		; current grid size (set based on current level when starting game)

maze_generate_seed	defw 0		; rand16 seed value used to generate maze
maze_index_seed		defb 0		; seed value used when selecting random neighbours
