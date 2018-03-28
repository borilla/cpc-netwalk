;; http://www.cpcwiki.eu/index.php/Programming:An_example_to_define_a_RSX

kl_log_ext	equ &bcd1

;;-------------------------------------------------------------------------------
;; install RSX

init_rsx	ld hl,work_space	;; address of 4 byte workspace needed by kernel
		ld bc,jump_table	;; address of command name table and routine jump-block
		ld a,&c9		;; RET
		ld (init_rsx),a		;; prevent init being called multiple times
		jp kl_log_ext		;; install RSXs

;;-------------------------------------------------------------------------------
;; RSX definition

name_table	defb "COMMAND","1"+&80
		defb "COMMAND","2"+&80
		defb "MAZEGE","N"+&80
		defb 0			;; marker for end of name table

work_space	defs 4			;; space for kernel to use

jump_table	defw name_table		;; pointer to names
		jp RSX_1_routine	;; jump block
		jp RSX_2_routine
		jp rsx_maze_gen

;;-------------------------------------------------------------------------------
;; RSX routines

RSX_1_routine	ret

;; |COMMAND2,a,b,@c%
RSX_2_routine	cp 3		;; check we have expected number of params
		ret nz
		ld a,(ix+4)	;; load first parameter into A
		add a,(ix+2)	;; add second parameter
		ld h,(ix+1)	;; load HL with third parameter (address of integer var)
		ld l,(ix+0)
		ld (hl),a	;; put result into third parameter
		ret

;; |MAZEGEN,width%,height%,@addr%
rsx_maze_gen	cp 3				;; check we have expected number of params
		ret nz
		ld a,(ix+4)			;; load (low byte of) first parameter into A
		ld (maze_width),a		;; set maze width
		ld a,(ix+2)			;; load (low byte of) second parameter into A
		ld (maze_height),a		;; set maze height
		ld h,(ix+1)			;; load HL with third parameter (address of integer return var)
		ld l,(ix+0)
		ld (hl),maze_data mod 256	;; write maze address (high byte)
		inc hl
		ld (hl),maze_data / 256		;; write maze address (low byte)
		jp maze_generate		;; generate the maze
