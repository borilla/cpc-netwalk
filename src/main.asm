;; ----------------------------------------------------------------
;; include macros
;; ----------------------------------------------------------------

include "lib/macros.asm"

;; ----------------------------------------------------------------
;; main
;; ----------------------------------------------------------------

main
		call clear_screen
		call setup_screen
		call music_toggle
		call setup_interrupts

generate_maze
		assign_interrupt 0,set_palette_text
		assign_interrupt 1,set_palette_grid
		assign_interrupt 2,noop
		assign_interrupt 4,music_play
		assign_interrupt 6,set_palette_text
		assign_interrupt 7,set_palette_grid
		assign_interrupt 8,noop
		assign_interrupt 10,music_play
		call clear_grid
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

.wait_for_key_release
		call read_actions
		ld hl,(movement_actions_cur)
		ld a,h
		or l
		jr nz,.wait_for_key_release

		ld hl,game_state_playing
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

enlarge_grid	ld a,(grid_size)
		cp #ff			;; check if already max size (15x15)
		jp z,generate_maze
		add #11			;; add 16+1
_eg_end		ld (grid_size),a
		jp generate_maze

shrink_grid	ld a,(grid_size)
		cp #33			;; check if already min size (3x3)
		jp z,generate_maze
		sub #11			;; subtract 16+1
_sg_end		ld (grid_size),a
		jp generate_maze

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
		ga_set_pen 2,ink_sky_blue	;; tile outline
		ga_set_pen 3,ink_lime		;; power flow
		ret

;; ----------------------------------------------------------------

clear_screen	ld hl,#c000
		ld de,#c001
		ld bc,#3fff
		ld (hl),l
		ldir
		ret

;; ----------------------------------------------------------------

clear_grid	ld a,%11111111		;; largest grid possible (15x15 tiles)
		call tile_calculate_origin
		xor a
		call tile_data_addr	;; HL = tile data address
		xor a
.loop
		ld c,a			;; go to next (pseudo-random) index
		add a,a
		add a,a
		add a,c
		inc a

		ld c,a
		ld b,%00001111		;; don't render column 15
		and b
		cp b
		ld a,c
		jr z,.skip

		ld b,%11110000		;; don't render row 15
		and b
		cp b
		ld a,c
		jr z,.skip

		push hl
		push af
		call tile_screen_addr	;; DE = tile screen address
		call tile_render_blank
		pop af
		ld h,rendered_tiles / 256
		ld l,a
		ld (hl),0
		pop hl
.skip
		or a
		jr nz,.loop
		ret

;; ----------------------------------------------------------------

process_other_actions
		ld a,(other_actions_new)	; get (high byte of) new actions
		bit action_m_bit,a		; is 'm' key pressed
		jp nz,music_toggle
		bit action_p_bit,a		; is 'p' key pressed
		jp nz,pause_toggle
		ret

;; ----------------------------------------------------------------
;; include subroutines
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
