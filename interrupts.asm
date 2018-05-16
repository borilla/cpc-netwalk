setup_interrupts	di
			im 1
			ld hl,_interrupt_handler
			ld (&0039),hl
			ld hl,interrupt_11
			ld (current_interrupt),hl
			wait_for_vsync
			ei
			ret

_interrupt_handler	ex af,af'			;; [1]
			exx				;; [1]
current_interrupt	equ $+1
			ld hl,interrupt_11		;; [3]
			ld a,l				;; [1]
			cp interrupt_11 and &ff		;; [2]
			jr nz,_interrupt_skip_reset	;; [2/3]
			ld hl,interrupt_0		;; [3]
			db 1				;; [3] "01 nn nn = ld bc,nnnn" ie skip next two bytes
_interrupt_skip_reset	inc hl				;; [2] "23 = inc hl"
			inc hl				;; [2] "23 = inc hl"
			ld (current_interrupt),hl	;; [5]
			ld a,(hl)			;; [2] ld hl,(hl)
			inc hl				;; [2]
			ld h,(hl)			;; [2]
			ld l,a				;; [1]
			call jump_to_hl			;; [6]
			exx				;; [1]
			ex af,af'			;; [1]
			ei				;; [1]
noop			ret				;; [3]
							;; [total 39/40]

jump_to_hl		jp (hl)				;; [1]

interrupt_0		defw noop
interrupt_1		defw noop
interrupt_2		defw noop
interrupt_3		defw noop
interrupt_4		defw noop
interrupt_5		defw noop
interrupt_6		defw noop
interrupt_7		defw noop
interrupt_8		defw noop
interrupt_9		defw noop
interrupt_10		defw noop
interrupt_11		defw noop
