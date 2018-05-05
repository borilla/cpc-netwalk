		org &8000
		call setup_screen

		di			;; disable interrupts (helps when measuring timings)
		ld lx,0
loop_0
		ld ly,80
		ld hl,sprite_data
loop_2
		ld a,lx			;; A = index of grid cell
		call cell_screen_addr	;; DE = screen address for cell
		push hl
		call render_sprite
		pop hl
		inc lx
		jr nz,loop_2
		dec ly
		jr z,loop_0
		ld a,80
		sub ly
		call sprite_from_index	;; HL = sprite address
		jr loop_2

read "inc/macros.asm"
read "maze/render-sprite.asm"
