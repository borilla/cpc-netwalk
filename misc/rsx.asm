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

name_table	defb "MAZEGE","N"+&80
		defb "MAZERO","T"+&80
		defb 0			;; marker for end of name table

work_space	defs 4			;; space for kernel to use

jump_table	defw name_table		;; pointer to name-table
		jp rsx_maze_gen
		jp rsx_maze_rot

;;-------------------------------------------------------------------------------
;; RSX routines

;; |MAZEGEN,width%,height%,@addr%
rsx_maze_gen	cp 3				;; check we have expected number of params
		ret nz
		ld h,(ix+1)			;; load HL with third parameter (address of integer return var)
		ld l,(ix+0)
		ld (hl),maze_data mod 256	;; write maze address (low byte)
		inc hl
		ld (hl),maze_data / 256		;; write maze address (high byte)
						;; A = height * 16 + width
		ld a,(ix+2)			;; load (low byte of) second parameter (ie height)
		rlca:rlca:rlca:rlca		;; shift height to top 4 bits of A
		or (ix+4)			;; add (low byte of) first parameter (ie width)
		di				;; disable interrupts (just so we can get accurate timing)
		call maze_generate		;; generate the maze
		ei
		ret

;; |MAZEROT,x%,y%
rsx_maze_rot	cp 2
		ret nz
		ld a,(ix+0)			;; read (low byte of) second parameter - ie y-index
		rlca:rlca:rlca:rlca		;; multiply by 16
		or (ix+2)			;; add (low byte of) first parameter - is x-index
		jp maze_rotate		;; rotate exits in room indexed by A
