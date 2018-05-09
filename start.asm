;; ----------------------------------------------------------------
;; include macros
;; ----------------------------------------------------------------

read "inc/macros.asm"

;; ----------------------------------------------------------------
;; main
;; ----------------------------------------------------------------

main		setup_minimal_interrupt_handler
		call setup_screen
generate_maze	ld a,r				;; set random seed for maze
		ld (choose_random_index + 1),a
		ld a,(grid_size)
		call maze_generate
		call render_grid
		ld a,(tile_index_selected)
		call render_selected
		ld a,r
		ld (tile_index_supply),a
		call render_supply

game_loop	call scan_keyboard
		call read_actions
		call do_movement_actions
		call redraw_selected_tile
		halt

		ld hl,actions
		bit 7,(hl)
		jr nz,generate_maze

		jr game_loop

;; ----------------------------------------------------------------
;; data
;; ----------------------------------------------------------------

grid_size		defb 0	;; TODO: fix stuff so we can have different grid sizes
tile_index_prev		defb 0
tile_index_selected	defb 0
tile_index_supply	defb 0
movement_countdown	defb 0

actions			defb 0
actions_prev		defb 0

;; ----------------------------------------------------------------
;; subroutines
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

;; render entire grid
render_grid	ld lx,0			;; use LX as grid index
_render_grid_1	ld a,lx
		call render_grid_tile
		inc lx
		jr nz,_render_grid_1
		ret

;; render a single grid tile
;; entry:
;;	A: index of grid tile to render
;; modifies:
;;	AF,BC,DE,HL
render_grid_tile
		ld h,maze_data / 256
		ld l,a
		call tile_screen_addr	;; DE = screen address for tile
		ld a,(hl)
		and %01111111
		call tile_data_addr	;; HL = sprite data for tile
		call tile_render
		ret

;; overlay power supply on top of tile
;; entry
;;	A: index of tile
;; modifies:
;;	AF,BC,DE,HL,LX
render_supply
		ld bc,tile_mask_lookup	;; BC points at mask
		call tile_screen_addr	;; DE points at screen
		ld hl,tile_supply	;; HL points at sprite
		call tile_render_mask
		ret

;; overlay transparent "selected" border on top of tile
;; entry
;;	A: index of tile
;; modifies:
;;	AF,BC,DE,HL,LX
render_selected
		ld bc,tile_mask_lookup	;; BC points at mask
		call tile_screen_addr	;; DE points at screen
		ld hl,tile_selected	;; HL points at sprite
		call tile_render_mask
		ret

;; render grid tile and (possibly) overlay power supply
;; entry:
;;	A: index of grid tile
;; modifies:
;;	AF,BC,DE,HL,IXL
render_tile_plus_supply
		ld ixl,a
		call render_grid_tile
		ld a,ixl
		ld hl,tile_index_supply
		cp (hl)
		ret nz
		jp render_supply

;; if selected tile has changed then redraw both it and previously selected
;; modifies:
;;	Af,BC,DE,HL,IXL
redraw_selected_tile
		ld a,(tile_index_selected)
		ld hl,tile_index_prev
		cp (hl)				;; compare current and prev selected tiles
		ret z				;; if unchanged then return

		ld a,(hl)			;; render prev tile
		call render_tile_plus_supply

		ld a,(tile_index_selected)
		ld (tile_index_prev),a		;; set prev tile index to current
		jp render_selected		;; draw "selected" border around current tile

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

		check_key key_r
		jr nz,$+4
		set 7,b			;; bit 7 = regenerate maze

		ld hl,actions
		ld a,(hl)
		ld (actions_prev),a	;; store previous actions
		ld (hl),b		;; update current actions
		ret

;; update currently selected tile based on current `actions`
do_movement_actions
		ld a,(actions)
		and %00001111			;; isolate "movement" actions
		ret z

		ld b,a				;; store current actions in B
		ld a,(actions_prev)		;; check if we've just started moving
		and %00001111

		ld hl,movement_countdown
		ld a,90				;; load A with long countdown timer
		jr z,_do_move			;; if weren't previously moving, act immediately (setting long timer)

		dec (hl)			;; otherwise, decrement movement countdown
		ret nz				;; if not counted down yet then return
		ld a,30				;; next countdown will use short timer

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

_do_move_end	ld (hl),a			;; write (possibly) new tile index
		ret

;; ----------------------------------------------------------------
;; include subroutines
;; ----------------------------------------------------------------

read "inc/scan_keyboard.asm"
read "maze/tiles.asm"
read "maze/maze.asm"
