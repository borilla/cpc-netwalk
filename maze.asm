;; ----------------------------------------------------------------
;; macros
;; ----------------------------------------------------------------

read "inc/macros.asm"

;; ----------------------------------------------------------------
;; constants
;; ----------------------------------------------------------------

program_addr	equ &8000
maze_width	equ 8
maze_height	equ 13
exits_top	equ 1
exits_right	equ 2
exits_bottom	equ 4
exits_left	equ 8
exits_all	equ 15

;; ----------------------------------------------------------------
;; init
;; ----------------------------------------------------------------

		nolist
		org program_addr

;; ----------------------------------------------------------------
;; subroutines
;; ----------------------------------------------------------------

maze_generate	call maze_clear
		call maze_edges
		ret

maze_clear	ld hl,maze_data
		ld de,maze_data+1
		ld bc,#00ff
		ld (hl),#00
		ldir
		ret

maze_edges	;; top and bottom edges
		ld hl,maze_data + maze_width
		ld de,maze_height * 16 - 16 + maze_data + maze_width
		ld a,#0f
_maze_edges_1	dec e
		dec l
		ld (hl),a
		ld (de),a
		jr nz,_maze_edges_1
		;; left and right edges
		ld c,a
		inc a
		ld b,maze_height-2
_maze_edges_2	ld l,a
		ld (hl),c
		add a,maze_width-1
		ld l,a
		ld (hl),c
		add a,16-maze_width+1
		djnz _maze_edges_2
		ret

;; ----------------------------------------------------------------
;; data
;; ----------------------------------------------------------------

		align #100,#11
maze_data	defs #100,#00
end
