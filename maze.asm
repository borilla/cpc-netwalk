;; ----------------------------------------------------------------
;; macros
;; ----------------------------------------------------------------

read "inc/macros.asm"

;; ----------------------------------------------------------------
;; constants
;; ----------------------------------------------------------------

program_addr	equ &8000
maze_width	equ 8
maze_width	equ 8

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

maze_edges	;; top edge
		ld hl,maze_data
		ld b,#10
_maze_edges_1	ld (hl),#0f
		inc l
		djnz _maze_edges_1
		;; left edge
		ld b,#0f
		ld a,l
_maze_edges_2	ld (hl),#0f
		add a,#10
		ld l,a
		djnz _maze_edges_2
		ret

;; ----------------------------------------------------------------
;; data
;; ----------------------------------------------------------------

		align #100,#11
maze_data	defs #100,#00
end
