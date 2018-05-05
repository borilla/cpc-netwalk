read "inc/macros.asm"

		org &8000

		di			;; disable interrupts (helps when measuring timings)
		call setup_screen

		xor a			;; ld a,0 (so maze will be 16 x 16)
		call maze_generate

		ld hl,maze_data

loop		ld a,l
		call cell_screen_addr	;; DE = screen address for cell
		ld a,(hl)
		and %01111111
		push hl
		call sprite_from_index	;; HL = sprite address
		call render_sprite
		pop hl
		inc l
		jr z,wait_forever
		jr loop

wait_forever	halt
		jr wait_forever

read "maze/render-sprite.asm"
read "maze/maze.asm"
