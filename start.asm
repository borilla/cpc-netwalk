;; ----------------------------------------------------------------
;; include macros
;; ----------------------------------------------------------------

read "inc/macros.asm"

;; ----------------------------------------------------------------
;; constants
;; ----------------------------------------------------------------

key_repeat_speed	equ 50

;; ----------------------------------------------------------------
;; main
;; ----------------------------------------------------------------

main		setup_minimal_interrupt_handler
		call setup_screen
		xor a			;; ld a,0 (so maze will be 16 x 16)
		call maze_generate
		call render_grid
		ld a,(selected_tile_index)
		call render_selected
		ld a,r
		ld (supply_tile_index),a
		call render_supply

game_loop	call scan_keyboard

check_key_down	check_key key_down
		ld hl,key_repeat_vertical
		jr z,move_down
		ld (hl),1
		jr check_key_up
move_down	dec (hl)
		jr nz,check_key_up
		ld (hl),key_repeat_speed	;; reset repeat countdown
		ld a,(selected_tile_index)
		add 16
		ld (selected_tile_index),a

check_key_up	check_key key_up
		ld hl,key_repeat_vertical
		jr z,move_up
		ld (hl),1
		jr check_key_left
move_up		dec (hl)
		jr nz,check_key_left
		ld (hl),key_repeat_speed	;; reset repeat countdown
		ld a,(selected_tile_index)
		sub 16
		ld (selected_tile_index),a

check_key_left	check_key key_left
		ld hl,left_key_repeat
		jr z,move_left
		ld (hl),1
		jr check_key_right
move_left	dec (hl)
		jr nz,check_key_right
		ld (hl),key_repeat_speed	;; reset repeat countdown
		ld a,(selected_tile_index)
		ld b,a
		dec a
		and %00001111
		ld c,a
		ld a,b
		and %11110000
		or c
		ld (selected_tile_index),a

check_key_right	check_key key_right
		ld hl,right_key_repeat
		jr z,move_right
		ld (hl),1
		jr end_check_keys
move_right	dec (hl)
		jr nz,end_check_keys
		ld (hl),key_repeat_speed	;; reset repeat countdown
		ld a,(selected_tile_index)
		ld b,a
		inc a
		and %00001111
		ld c,a
		ld a,b
		and %11110000
		or c
		ld (selected_tile_index),a

end_check_keys	halt

		;; if selected tile has changed then redraw
		ld a,(selected_tile_index)
		ld b,a
		ld a,(prev_tile_index)
		cp b
		jp z,game_loop
		call render_grid_tile		;; over-draw prev tile
		ld a,(selected_tile_index)
		ld (prev_tile_index),a
		call render_selected		;; draw "selected" border around new tile

		jp game_loop

;; ----------------------------------------------------------------
;; data
;; ----------------------------------------------------------------

prev_tile_index		defb 0
selected_tile_index	defb 0
supply_tile_index	defb 0

key_repeat_vertical	defb 1
left_key_repeat		defb 1
right_key_repeat	defb 1

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
;;	AF,BC,DE,HL,IX
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

;; ----------------------------------------------------------------
;; include subroutines
;; ----------------------------------------------------------------

read "inc/scan_keyboard.asm"
read "maze/tiles.asm"
read "maze/maze.asm"
