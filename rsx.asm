;; http://www.cpcwiki.eu/index.php/Programming:An_example_to_define_a_RSX

kl_log_ext	equ &bcd1

;; this can be any address in the range &0040-&a7ff.
		org &8000

;;-------------------------------------------------------------------------------
;; install RSX

		ld hl,work_space	;; address of a 4 byte workspace useable by Kernel
		ld bc,jump_table	;; address of command name table and routine handlers
		jp kl_log_ext		;; install RSXs


;;-------------------------------------------------------------------------------
;; RSX definition

name_table	defb "COMMAND","1"+&80
		defb "COMMAND","2"+&80
		defb "COMMAND","3"+&80
		defb 0			;; marker for end of name table

work_space	defs 4			;; space for kernel to use

jump_table	defw name_table		;; pointer to names
		jp RSX_1_routine	;; jump block
		jp RSX_2_routine
		jp RSX_3_routine

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

RSX_3_routine	ret
