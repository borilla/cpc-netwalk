read "inc/macros.asm"

main		di			;; disable interrupts
		call setup_screen
		xor a			;; ld a,0 (so maze will be 16 x 16)
		call maze_generate
		call render_maze
wait_forever	halt
		jr wait_forever

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
		ga_set_pen 0,ink_bright_white	;; background
		ga_set_pen 1,ink_black		;; outlines
		ga_set_pen 2,ink_lime		;; power flow
		ga_set_pen 3,ink_white		;; tile edges
		ga_set_pen 16,ink_white		;; border
		ret

render_maze	ld hl,maze_data
_render_maze_1	ld a,l
		call cell_screen_addr	;; DE = screen address for cell
		ld a,(hl)
		and %01111111
		push hl
		call sprite_from_index	;; HL = sprite address
		call render_sprite
		pop hl
		inc l
		jr nz,_render_maze_1
		ret

read "maze/render-sprite.asm"
read "maze/maze.asm"
