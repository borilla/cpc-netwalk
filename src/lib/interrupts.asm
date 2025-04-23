;; Interrupts happen six times per frame, frame happens 50 times per second so interrupts
;; are every 1/300 sec. We allow for 12 interrupts so each is called once every two frames.
;; Interrupts are aligned such that interrupts 0 and 6 occur at vsync. Interrupts are always
;; called but are initially set to `noop` (no operation), which simply returns directly
;; 
;; There are ~3300 nops between interrupts so any routines need to be a bit less than this.
;; Our handler below also takes exactly 45 nops per interrupt and there are some additional
;; overheads such as the rst and jp call at #0038

setup_interrupts	di
			im 1
			ld hl,_handle_interrupt
			ld (#0039),hl
			ld a,11
			ld (interrupt_index),a
			wait_for_vsync
			ei
noop			ret				;; [3]

_handle_interrupt
			ex af,af'			;; [1]
			exx				;; [1]
			call _handle_next_interrupt	;; [5]
			exx				;; [1]
			ex af,af'			;; [1]
			ei				;; [1]
			ret				;; [3]
							;; [45 nops, including ret from subroutine/noop]

_handle_next_interrupt
			;; increment interrupt index
			ld hl,interrupt_index		;; [3]
			ld a,(hl)			;; [2]
			inc a				;; [1]
			cp 12				;; [2]
			jr nz,$+3			;; [2/3]
			xor a				;; [1]
			ld (hl),a			;; [2] store new index

			;; point hl at current interrupt
			inc hl				;; [2] hl = interrupt_0
			add a,a				;; [1] hl = hl + 2 * a
			add a,l				;; [1]
			ld l,a				;; [1]
			adc h				;; [1]
			sub l				;; [1]
			ld h,a				;; [1]

			;; read low byte into l, high byte into h
			ld a,(hl)			;; [2]
			inc hl				;; [2]
			ld h,(hl)			;; [2]
			ld l,a				;; [1]

			;; jump to subroutine at address in hl
jump_to_hl		jp (hl)				;; [1]
							;; [total 29 nops]

interrupt_index		defb 0
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

;; assign all 12 interrupts from table
;; entry:
;;	HL: pointer to table of 12 addresses for interrupts 0-11
;; exit:
;;	HL: byte after interrupt table
;;	BC: 0
;; modifies:
;;	HL,BC,DE
assign_interrupts
			ld de,interrupt_0
			ld bc,24		; 12 * 2 bytes
			ldir
			ret
