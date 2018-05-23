;; ----------------------------------------------------------------
;; include macros
;; ----------------------------------------------------------------

read "inc/macros.asm"

;; ----------------------------------------------------------------
;; main
;; ----------------------------------------------------------------

main		call setup_screen
generate_maze	di
		ld a,r				;; set random seed for maze
		ld (choose_random_index + 1),a
		ld a,(grid_size)
		call maze_generate

		xor a				;; reset actions
		ld (actions_prev),a
		ld (actions),a
		ld (actions_new),a

		call setup_interrupts
		assign_interrupt 0,do_rendering
		assign_interrupt 6,get_actions

game_loop	ld hl,actions_new
		bit 7,(hl)
		jr nz,generate_maze

		call render_next_tile

		ld a,(recalc_required)
		or a
		jr z,game_loop
		call recalc_connected_tiles
		xor a
		ld (recalc_required),a

		jr game_loop

;; ----------------------------------------------------------------
;; data
;; ----------------------------------------------------------------

grid_size		defb 0
tile_index_supply	defb 0

tile_index_prev		defb 0
tile_index_selected	defb 0

actions			defb 0
actions_prev		defb 0
actions_new		defb 0
movement_countdown	defb 0

rotation_queue		defs 16	;; circular FIFO queue of pending tiles to rotate
rotation_queue_cur	defb 0	;; index of current position in queue
rotation_queue_next	defb 0	;; index to insert next item in queue

recalc_required		defb 0	;; flag that we need to recalculate connected tiles

align &100
rendered_tiles	defs &100,0

;; ----------------------------------------------------------------
;; subroutines
;; ----------------------------------------------------------------

do_rendering	call update_rotating_tile
		call render_selected_overlay
		jp render_supply_overlay

;; ----------------------------------------------------------------

get_actions	call scan_keyboard
		call read_actions
		call do_movement_action
		call do_rotate_action
		call render_selected_overlay
		jp render_supply_overlay

;; ----------------------------------------------------------------

;; set mode, screen size, colours etc
;; disable firmware interrupts before calling
setup_screen	;; set screen mode
		ga_select_mode 1		;; mode 1
		;; set screen origin
		crtc_set_screen_address &c000,0	;; page &c000, offset 0
		;; set screen size
		crtc_write_register 1,32	;; horizontal displayed: 32 characters, 64 bytes, 256 mode 1 pixels
		crtc_write_register 2,42	;; horizontal sync position
		crtc_write_register 6,32	;; vertical displayed: 32 characters, 256 pixels
		crtc_write_register 7,34	;; vertical sync position
		;; set pen colors
		ga_set_pen 0,ink_pastel_blue	;; background
		ga_set_pen 1,ink_black		;; outlines
		ga_set_pen 2,ink_lime		;; power flow
		ga_set_pen 3,ink_sky_blue	;; tile edges
		ga_set_pen 16,ink_black		;; border
		ret

;; ----------------------------------------------------------------

;; render next tile that needs rendering (if any)
render_next_tile
next_tile_index	equ $+1
		ld a,0			;; LD A,(next_tile_index)
		ld b,0			;; max number of loops
		ld d,maze_data / 256
		ld h,rendered_tiles / 256
_rnt_loop
		ld e,a			;; point DE at tile state
		ld l,a			;; point HL at rendered state

		ld a,(de)		;; is tile state same as rendered state?
		cp (hl)
		jr nz,_rnt_render	;; if not then render

		ld a,e			;; go to next (pseudo-random) index
		add a,a
		add a,a
		add a,e
		inc a

		djnz _rnt_loop
		ld (next_tile_index),a
		ret			;; no tile to render this time
_rnt_render
		;; at this point, A = tile state, DE points to tile state, HL points to rendered state
		ld (hl),a		;; update rendered state
		ld a,l
		ld (next_tile_index),a

		ld a,(de)
		and %01111111
		call tile_data_addr	;; HL = sprite data for tile
		ld a,e
		call tile_screen_addr	;; DE = screen address for tile
		jp tile_render	;; render the tile

;; ----------------------------------------------------------------

;; render a single grid tile
;; entry:
;;	A: index of grid tile to render
;; modifies:
;;	AF,BC,DE,HL
render_grid_tile
		ld h,maze_data / 256
		ld l,a
		call tile_screen_addr		;; DE = screen address for tile
		ld a,(hl)
		ld h,rendered_tiles / 256	;; update rendered tile
		ld (hl),a
		and %01111111
		call tile_data_addr		;; HL = sprite data for tile
		jp tile_render

;; ----------------------------------------------------------------

;; overlay power supply on top of tile
;; entry
;;	A: index of tile
;; modifies:
;;	AF,BC,DE,HL,LX
render_supply_overlay
		ld a,(tile_index_supply)
		ld bc,tile_mask_lookup	;; BC points at mask
		call tile_screen_addr	;; DE points at screen
		ld hl,tile_supply	;; HL points at sprite
		jp tile_render_mask

;; ----------------------------------------------------------------

;; overlay "selected" border on top of tile
;; entry
;;	A: index of tile
;; modifies:
;;	AF,BC,DE,HL,LX
render_selected_overlay
		ld a,(tile_index_selected)
		ld bc,tile_mask_lookup	;; BC points at mask
		call tile_screen_addr	;; DE points at screen
		ld hl,tile_selected	;; HL points at sprite
		jp tile_render_mask

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
		ld a,10				;; load A with long countdown timer
		jr z,_do_move			;; if weren't previously moving, act immediately (setting long timer)

		ld a,(actions_new)		;; if a new direction key has been pressed
		and %00001111			;; then move immediately
		ld a,(hl)
		jr nz,_do_move

		dec (hl)			;; otherwise, decrement movement countdown
		ret nz				;; if not counted down yet then return
		ld a,4				;; next countdown will use short timer

_do_move	ld (hl),a			;; reset countdown (to long or short timer)
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
		cp %11110000			;; TODO: cp grid-height
		ld a,c
		jr z,_do_move_right		;; can't move down
		add 16				;; move down

_do_move_right	bit 1,b
		jr z,_do_move_left		;; not moving right
		ld c,a				;; check that can move right
		and %00001111
		cp %00001111			;; TODO: cp grid-width
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

		ld c,a
		ld a,(hl)
		ld (hl),c
		jp render_grid_tile		;; render prev tile

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

_write_rotated_value
		ld (hl),e			;; store new (rotated) tile value
		ld a,l
		jp render_grid_tile		;; render the tile

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

recalc_connected_tiles
		;; reset connected bits for all maze cells
		ld hl,maze_data
_uct_loop_1	ld a,(hl)
		and %00111111
		ld (hl),a
		inc l
		jr nz,_uct_loop_1

		ld a,(tile_index_supply)
		call connected_cells

		ret

;; ----------------------------------------------------------------
;; include subroutines
;; ----------------------------------------------------------------

read "inc/scan_keyboard.asm"
read "maze/interrupts.asm"
read "maze/tiles.asm"
read "maze/maze.asm"
