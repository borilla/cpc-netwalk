;; ----------------------------------------------------------------
;; include macros
;; ----------------------------------------------------------------

include "inc/macros.asm"

;; ----------------------------------------------------------------
;; main
;; ----------------------------------------------------------------

org #4000

main
		call clear_screen
		call setup_screen
		call setup_interrupts

generate_maze
		assign_interrupt 0,set_palette_text
		assign_interrupt 1,set_palette_grid
		assign_interrupt 2,noop
		assign_interrupt 6,set_palette_text
		assign_interrupt 7,set_palette_grid
		assign_interrupt 8,noop
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
		call recalc_connected_tiles	;; all tiles are initially connected so this will return number of terminals (in A)
		ld (maze_terms_total),a
		call maze_shuffle
		ld a,(tile_index_supply)
		call recalc_connected_tiles

wait_for_key_release
		call read_actions
		ld a,(actions)
		jr nz,wait_for_key_release

		assign_interrupt 0,get_actions
		assign_interrupt 1,render_clock
		assign_interrupt 2,moves_render		;; count of moves in info bar
		assign_interrupt 6,render_important_tiles
		assign_interrupt 7,render_clock
		assign_interrupt 8,rotations_render	;; count of rotations in info bar
		assign_interrupt 9,connections_render	;; connected tiles in info bar

game_loop
		ld hl,actions_new		;; special actions (regenerate/resize grid)
		bit 5,(hl)
		jr nz,enlarge_grid
		bit 6,(hl)
		jr nz,shrink_grid
		bit 7,(hl)
		jp nz,generate_maze
_ignore_special_actions
		call render_next_tile
		ld a,(recalc_required)
		or a
		jr z,_check_for_completion
		xor a
		ld (recalc_required),a
		call recalc_connected_tiles
		jr game_loop
_check_for_completion
		ld a,(maze_terms_total)		;; check if all terminals are connected
		ld hl,maze_terms_connected
		cp (hl)
		jr nz,game_loop
		ld a,(rotation_queue_cur)	;; check if any pending rotations
		ld hl,rotation_queue_next
		cp (hl)
		jr nz,game_loop
game_complete
		assign_interrupt 0,get_actions
		assign_interrupt 1,set_palette_grid
		assign_interrupt 2,noop
		assign_interrupt 6,set_palette_text
		assign_interrupt 7,set_palette_grid
		assign_interrupt 8,noop
		jr game_loop

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

set_palette_text
		ga_set_pen 3,ink_bright_white
		ret

set_palette_grid
		ga_set_pen 3,ink_lime
		ret

render_clock
		call set_palette_grid
		call time_inc_ms_lo
		ret

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
		ga_set_pen 0,ink_black		;; background (and outlines)
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
_cs_loop
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
		jr z,_cs_end

		ld b,%11110000		;; don't render row 15
		and b
		cp b
		ld a,c
		jr z,_cs_end

		push hl
		push af
		call tile_screen_addr	;; DE = tile screen address
		call tile_render_blank
		pop af
		ld h,rendered_tiles / 256
		ld l,a
		ld (hl),0
		pop hl

_cs_end		or a
		jr nz,_cs_loop
		ret

;; ----------------------------------------------------------------

;; scan keyboard, process movement and rotation
get_actions	call set_palette_text
		call scan_keyboard
		call read_actions
		call do_movement_action
		call do_rotate_action
		jp update_rotating_tile

;; ----------------------------------------------------------------

;; render prev, current and rotating tiles (as necessary)
render_important_tiles
		call set_palette_text
		call render_selected_tile
		jp render_rotating_tile

;; ----------------------------------------------------------------

;; if prev selected tile not equal to currently selected tile then render both
render_selected_tile
		ld a,(tile_index_selected)
		ld hl,tile_index_prev
		cp (hl)
		ret z
		ld c,a
		ld a,(hl)
		ld (hl),c
		call render_grid_tile
		ld a,(tile_index_selected)
		jp render_grid_tile

;; ----------------------------------------------------------------

;; render rotating tile if it is different from rendered state
render_rotating_tile
		ld hl,rotation_queue
		ld a,(rotation_queue_cur)
		add_hl_a
		ld a,(hl)
		jp render_if_modified

;; ----------------------------------------------------------------

;; render next tile that needs rendering (if any)
;; modifies:
;;	A,BC,DE,HL,IX
;; flags:
;;	Z: if no tile was rendered
;;	NZ: if tile was rendered
render_next_tile
next_tile_index	equ $+1
		ld a,0			;; LD A,(next_tile_index)
		ld b,0			;; max number of loops
_rnt_loop
		ld c,a			;; go to next (pseudo-random) index
		add a,a
		add a,a
		add a,c
		inc a

		call render_if_modified
		jr nz,_rnt_end		;; if tile was rendered then end loop

		djnz _rnt_loop
		ld c,a
		xor a			;; no tile to render this time; set Z flag
		ld a,c
_rnt_end
		ld (next_tile_index),a	;; store starting index for next call
		ret

;; ----------------------------------------------------------------

;; render a grid tile if it has been modified from rendered state
;; entry:
;;	A: index of grid tile to render
;; exit:
;;	A: unmodified
;; modifies:
;;	BC,DE,HL,IX
;; flags:
;;	Z: set if no tile is rendered, NZ if tile is rendered
render_if_modified
		ld h,maze_data / 256
		ld l,a
		ld a,(hl)
		ld h,rendered_tiles / 256
		cp (hl)
		ld a,l
		ret z
		;; otherwise, fall through to render_grid_tile

;; ----------------------------------------------------------------

;; render a grid tile (and power supply and selected overlay if appropriate)
;; entry:
;;	A: index of grid tile to render
;; exit:
;;	A: unmodified
;; modifies:
;;	BC,DE,HL,IX
;; flags:
;;	Z: always reset
render_grid_tile
		ld ixh,a			;; keep original index
		ld h,maze_data / 256
		ld l,a
		call tile_screen_addr		;; DE = screen address for tile
		ld a,(hl)
		ld h,rendered_tiles / 256	;; update rendered tile
		ld (hl),a
		call tile_data_addr		;; HL = sprite data for tile
		call tile_render		;; render the tile

		ld a,ixh
		ld c,a
		ld a,(tile_index_supply)
		cp c
		call z,render_power_supply

		ld a,ixh
		ld c,a
		ld a,(tile_index_selected)
		cp c
		call z,render_reticle

		or 1				;; reset Z flag
		ld a,ixh			;; restore A
		ret

;; ----------------------------------------------------------------

;; render power supply overlay
;; entry:
;;	A: index tile
;; modifies:
;;	AF,BC,DE,HL,IXL
render_power_supply
		call tile_screen_addr		;; DE points at screen
		ld hl,tile_supply_trans		;; HL points at tile data
		jp tile_render_trans

;; ----------------------------------------------------------------

;; render reticle overlay indicating selected tile
;; entry
;;	A: index of tile
;; modifies:
;;	AF,BC,DE,HL,LX
render_reticle
		call tile_screen_addr		;; DE points at screen
		ld hl,tile_selected_trans	;; HL points at tile data
		jp tile_render_trans

;; ----------------------------------------------------------------

;; update `actions` based on pressed keys
;; modifies:
;;	A,B,HL
read_actions
		ld b,0			;; store actions in B
		check_key key_up	;; TODO: just read each keyboard row into A once (instead of using macro)
		jr nz,$+4
		set 0,b			;; bit 0 = move up
		check_key key_right
		jr nz,$+4
		set 1,b			;; bit 1 = move right
		check_key key_down
		jr nz,$+4
		set 2,b			;; bit 2 = move down
		check_key key_left
		jr nz,$+4
		set 3,b			;; bit 3 = move left
		check_key key_space
		jr nz,$+4
		set 4,b			;; bit 4 = rotate tile
		check_key key_q
		jr nz,$+4
		set 5,b			;; bit 5 = enlarge grid
		check_key key_a
		jr nz,$+4
		set 6,b			;; bit 6 = shrink grid
		check_key key_r
		jr nz,$+4
		set 7,b			;; bit 7 = regenerate maze

		ld hl,actions
		ld a,(hl)
		ld (actions_prev),a	;; store previous actions
 		ld (hl),b		;; store current actions
		xor b
		and b
		ld (actions_new),a	;; store new actions

		ret

;; ----------------------------------------------------------------

;; update currently selected tile based on current `actions`
do_movement_action
		ld a,(actions)
		and %00001111			;; isolate "movement" actions
		ret z

		ld b,a				;; store current actions in B
		ld a,(actions_prev)		;; check if we've just started moving
		and %00001111

		ld hl,movement_countdown
		ld a,6				;; load A with long countdown timer
		jr z,_do_move			;; if weren't previously moving, act immediately (setting long timer)

		ld a,(actions_new)		;; if a new direction key has been pressed
		and %00001111			;; then move immediately
		ld a,(hl)
		jr nz,_do_move

		dec (hl)			;; otherwise, decrement movement countdown
		ret nz				;; if not counted down yet then return
		ld a,3				;; next countdown will use short timer

_do_move	ld (hl),a			;; reset countdown (to long or short timer)

		ld a,(maze_index_limits)
		ld e,a
		and %00001111
		ld d,a				;; D is maximum x-value
		ld a,e
		and %11110000
		ld e,a				;; E is maximum y-value

		ld hl,tile_index_selected	;; HL points at tile index
		ld a,(hl)			;; A is tile index

_do_move_up	bit 0,b
		jr z,_do_move_down		;; not moving up
		ld c,a				;; check that can move up
		and %11110000
		ld a,c
		jr z,_do_move_right		;; can't move up
		sub 16				;; move up
;;		jr _do_move_right		;; we've moved up, so can't also move down

_do_move_down	bit 2,b
		jr z,_do_move_right		;; not moving down
		ld c,a				;; check that can move down
		and %11110000
		cp e				;; cp max-y-value
		ld a,c
		jr z,_do_move_right		;; can't move down
		add 16				;; move down

_do_move_right	bit 1,b
		jr z,_do_move_left		;; not moving right
		ld c,a				;; check that can move right
		and %00001111
		cp d				;; cp max-x-value
		ld a,c
		jr z,_do_move_end		;; can't move right
		inc a				;; move right
;;		jr _do_move_end			;; we've moved right, so can't also move left

_do_move_left	bit 3,b
		jr z,_do_move_end		;; not moving left
		ld c,a				;; check that can move left
		and %00001111
		ld a,c
		jr z,_do_move_end		;; can't move left
		dec a				;; move left

_do_move_end	cp (hl)				;; is index changed?
		ret z

		push af
		push hl
		call moves_inc
		pop hl
		pop af

		ld c,a
		ld a,(hl)
		ld (tile_index_prev),a
		ld (hl),c
		ret

;; ----------------------------------------------------------------

;; if `rotate` key is pressed then add current cell to rotate queue
do_rotate_action
		ld a,(actions_new)		;; get "new" actions in A

		bit 4,a				;; check for rotate action
		ret z

		ld hl,rotation_queue		;; insert currently selected index into queue
		ld a,(rotation_queue_next)
		ld b,a
		add_hl_a
		ld a,(tile_index_selected)
		ld (hl),a

		ld a,b				;; update "next" index
		inc a
		and %00001111			;; A = A mod 16
		ld (rotation_queue_next),a

		ret

;; ----------------------------------------------------------------

update_rotating_tile
		ld bc,rotation_queue_cur
		ld hl,rotation_queue_next
		ld a,(bc)			;; index of current item in queue
		cp (hl)
		ret z				;; no rotating tile

		ld hl,rotation_queue		;; get tile index from queue
		add_hl_a
		ld a,(hl)

		ld h,maze_data / 256		;; HL points at rotating tile
		ld l,a
		ld a,(hl)			;; A = grid tile value

		add 16				;; increment rotation value
		and %00111111			;; (isolate rotation bits)

		ld e,a				;; store rotated value in E
		and %00110000			;; check if rotation has returned to 0
		jr nz,_write_rotated_value	;; if not returned to zero yet then write new value

		ld d,rot_nibble_data / 256	;; if returned to zero then rotate exits
		ld a,(de)			;; read rotated value from DE
		ld e,a

		ld a,1				;; flag that we need to recalculate connected tiles
		ld (recalc_required),a

		ld a,(bc)			;; update queue index
		inc a
		and %00001111
		ld (bc),a

		push hl				;; TODO: could probably save this push/pop by switching HL and DE
		call rotations_inc		;; update rotations-count
		pop hl

_write_rotated_value
		ld (hl),e			;; store new (rotated) tile value
		ld a,l
		jp render_grid_tile		;; render the tile

;; ----------------------------------------------------------------

recalc_connected_tiles
		;; reset connected bits for all maze cells
		ld hl,maze_data
_uct_loop_1	ld a,(hl)
		and %00111111
		ld (hl),a
		inc l
		jr nz,_uct_loop_1

		ld a,(tile_index_supply)
		jp maze_mark_connected

;; ----------------------------------------------------------------
;; include subroutines
;; ----------------------------------------------------------------

include "interrupts.asm"
include "inc/scan_keyboard.asm"
include "rand16.asm"
include "tile.asm"
include "char.asm"
include "time.asm"
include "moves.asm"
include "maze.asm"
include "music/music_playerconfig.asm"
include "music/music.asm"

;; ----------------------------------------------------------------
;; data
;; ----------------------------------------------------------------

grid_size		defb #aa	;; initial size (10x10)

tile_index_prev		defb 0	;; previous position of cursor
tile_index_selected	defb 0	;; current position of cursor
tile_index_supply	defb 0	;; position of power supply

actions			defb 0
actions_prev		defb 0
actions_new		defb 0
movement_countdown	defb 0

rotation_queue		defs 16	;; circular FIFO queue of pending tiles to rotate
rotation_queue_cur	defb 0	;; index of currently rotating tile
rotation_queue_next	defb 0	;; index to insert next item in queue

recalc_required		defb 0	;; flag that we need to recalculate connected tiles

			align #100

rendered_tiles		defs #100,0
