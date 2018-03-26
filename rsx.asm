;; http://www.cpcwiki.eu/index.php/Programming:An_example_to_define_a_RSX
;;
;; This program provides the framework for the installation of a Resident System
;; Extension (an RSX).
;;
;; An RSX is a command which is accessed from basic by prexifing the command
;; with the '|' symbol.
;;
;; e.g. An RSX could provide a "MEMEDIT" command, which allows the user
;; to edit the RAM contents. It would be accessed from BASIC by typing:
;;
;; |MEMEDIT
;;
;; This program shows how an RSX is set up. You are free to use this
;; example code to create your own RSX's.
;;
;; Kevin Thacker 1993

.kl_log_ext	equ &bcd1

;; this can be any address in the range &0040-&a7ff.
		org &8000

;;-------------------------------------------------------------------------------
;; install RSX

		ld hl,work_space	;; address of a 4 byte workspace useable by Kernel
		ld bc,jump_table	;; address of command name table and routine handlers
		jp kl_log_ext		;; install RSXs

.work_space	defs 4			;; space for kernel to use

;;-------------------------------------------------------------------------------
;; RSX definition

.jump_table	defw name_table		;; address pointing to RSX commands 

					;; list of jump commands associated with each command

					;; The name (in the name_table) and jump instruction
					;; (in the jump_table), must be in the same
					;; order.
					;; i.e. the first name in the name_table refers to the
					;; first jump in the jump_table, and vice versa.

		jp RSX_1_routine	;; routine for COMMAND1 RSX
		jp RSX_2_routine	;; routine for COMMAND2 RSX
		jp RSX_3_routine	;; routine for COMMAND3 RSX

;; the table of RSX function names
;; the names must be in capitals.

.name_table	defb "COMMAND","1"+&80	;; the last letter of each RSX name must have bit 7 set to 1.
		defb "COMMAND","2"+&80	;; This is used by the Kernel to identify the end of the name.
		defb "COMMAND","3"+&80
		defb 0			;; end of name table marker

;; Code for the example RSXs

.RSX_1_routine
ret

.RSX_2_routine
ret

.RSX_3_routine
ret
