		org &8000
		call setup_screen
loop		ld de,&c000
		ld hl,S_0_00_0001
		call render_sprite	;; timer_start(1) and 0
		nop			;; timer_stop(1) and 0
		halt
 		jr loop

read "inc/macros.asm"
read "maze/render-sprite.asm"
