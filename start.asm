;; ----------------------------------------------------------------
;; include macros
;; ----------------------------------------------------------------

read "inc/macros.asm"

;; ----------------------------------------------------------------
;; main
;; ----------------------------------------------------------------

main		setup_minimal_interrupt_handler
		call setup_screen
		ld a,(grid_size)
		call maze_generate
		call render_grid
		ld a,(tile_index_selected)
		call render_selected
		ld a,r
		ld (tile_index_supply),a
		call render_supply

game_loop	call scan_keyboard
		call check_direction_keys
		call redraw_selected
		halt
		jr game_loop

;; ----------------------------------------------------------------
;; data
;; ----------------------------------------------------------------

grid_size		defb 0
tile_index_prev		defb 0
tile_index_selected	defb 0
tile_index_supply	defb 0
movement_countdown	defb 0

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

;; if selected tile has changed then redraw both it and previously selected
;; modifies:
;;	Af,BC,DE,HL,IXL
redraw_selected
		ld a,(tile_index_selected)
		ld hl,tile_index_prev
		cp (hl)				;; compare current and prev selected tiles
		ret z				;; if unchanged then return

		ld b,a				;; B = current tile index
		ld a,(hl)			;; A = prev tile index
		ld (hl),b			;; prev tile = current tile

		ld ixl,a			;; IXL = prev tile index
		call render_grid_tile		;; draw prev tile
		
		ld hl,tile_index_supply		;; is prev tile same as supply
		ld a,ixl
		cp (hl)
		call z,render_supply

		ld a,(tile_index_selected)	;; draw selected border around current tile
		jp render_selected		;; return directly from render_selected
		;; ret

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

;; check if direction key(s) pressed and update selected tile appropriately
;; modifies:
;;	A,BC,HL
check_direction_keys
		xor a			;; B stores direction in bits:
		ld b,a			;; 1 = up, 2 = right, 3 = down, 4 = left
		check_key key_up	;; TODO: just read keyboard row into A once (instead of using macro)
		jr nz,$+4
		set 0,b
		check_key key_right
		jr nz,$+4
		set 1,b
		check_key key_down
		jr nz,$+4
		set 2,b
		check_key key_left
		jr nz,$+4
		set 3,b

		ld hl,movement_countdown
		inc b				;; check if B is zero
		dec b
		jr nz,_do_move			;; if not zero then do movement
		ld (hl),1			;; no movement, reset movement countdown
		ret

_do_move	dec (hl)			;; decrement movement countdown
		ret nz				;; if countdown not reached zero then don't do movement yet
		ld (hl),40			;; otherwise, reset countdown
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
