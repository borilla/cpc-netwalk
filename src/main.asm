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
		ld a,(actions)
		jr nz,.wait_for_key_release

		ld hl,interrupt_table_play
		call assign_interrupts
		ld hl,main_loop_play
		ld (main_loop),hl
.loop
main_loop	equ $+1
		call #0000		; call (main_loop)
		jr .loop

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
;; subroutines
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

; low byte of actions (movements, ie actions that auto-repeat if key is held down)
action_up_bit		equ 0
action_right_bit	equ 1
action_down_bit		equ 2
action_left_bit		equ 3

; high byte of actions
action_space_bit	equ 0
action_p_bit		equ 1
action_m_bit		equ 2
action_q_bit		equ 3
action_a_bit		equ 4
action_r_bit		equ 5

;; update `actions` and `new actions` based on pressed keys
;; modifies:
;;	A,DE,HL
read_actions
		call scan_keyboard		; scan keyboard and store results in keyboard_lines
		ld de,0				; store actions in de

		ld a,(keyboard_lines + 0)	; keyboard line 0
		cpl				; remember that keyboard bits are inverted
		and %00000111			; bits for up/right/down cursor keys happen to map directly onto actions
		ld e,a				; store movement actions in e

		ld a,(keyboard_lines + 1)	; keyboard line 1
		bit 0,a				; left cursor key
		jr nz,$+4
		set action_left_bit,e

		ld a,(keyboard_lines + 3)	; keyboard line 3
		bit 3,a				; p key
		jr nz,$+4
		set action_p_bit,d

		ld a,(keyboard_lines + 4)	; keyboard line 4
		bit 6,a				; m key
		jr nz,$+4
		set action_m_bit,d

		ld a,(keyboard_lines + 5)	; keyboard line 5
		bit 7,a				; space bar
		jr nz,$+4
		set action_space_bit,d

		ld a,(keyboard_lines + 6)	; keyboard line 6
		bit 2,a				; r key
		jr nz,$+4
		set action_r_bit,d

		ld a,(keyboard_lines + 8)	; keyboard line 8
		bit 3,a				; q key
		jr nz,$+4
		set action_q_bit,d
		bit 5,a				; a key
		jr nz,$+4
		set action_a_bit,d

		ld hl,actions_mask		; filter for currently allowed actions
		ld a,d
		and (hl)
		ld d,a
		inc hl
		ld a,e
		and (hl)
		ld e,a

		ld hl,(actions)			; DE = curr actions, HL = prev actions
		ld (actions_prev),hl

		ld a,h				; get high byte of new actions
		xor d
		and d

		ld (actions_new + 1),a		; store high byte of new actions
		ex de,hl
		ld (actions),hl			; store current actions

		; calculate new movement actions (low byte of new actions)
		xor a
		ld (actions_new),a		; initially set to zero

		ld a,l				; get "movement" actions
		or a
		ret z				; no movement actions so just return

		ld d,a				; store current movement actions in D
		ld a,(actions_prev)		; check if we've just started moving
		or a

		ld hl,.countdown
		ld a,6				; load A with long countdown timer
		jr z,.set_countdown		; if weren't previously moving then set new actions (setting long timer)

		dec (hl)			; otherwise, decrement movement countdown
		ret nz				; if not counted down yet then return

		ld a,3				; next countdown will use short timer
.set_countdown
		ld (hl),a			; reset countdown (to long or short timer)
		ld a,d				; load A with current movement actions
		ld (actions_new),a		; copy current movement actions to new actions
		ret
.countdown	defb 0

process_other_actions
		ld a,(actions_new + 1)		; get (high byte of) new actions
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

actions			defw 0
actions_prev		defw 0
actions_new		defw 0
actions_mask		defw #ffff	; mask to filter currently allowed actions
