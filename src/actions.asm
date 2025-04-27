; movement actions
action_up_bit		equ 0
action_right_bit	equ 1
action_down_bit		equ 2
action_left_bit		equ 3

; other actions
action_select_bit	equ 0
action_escape_bit	equ 1
action_m_bit		equ 2
action_q_bit		equ 3
action_a_bit		equ 4
action_r_bit		equ 5

; ----------------------------------------------------------------

; update actions based on pressed keys and current mask values
read_actions
		call scan_keyboard		; scan keyboard and store results in keyboard_lines
		ld de,0				; E = current movement actions, D = current other actions

		ld a,(keyboard_lines + 0)	; keyboard line 0
		cpl				; remember that keyboard bits are inverted
		and %00000111			; bits for up/right/down cursor keys happen to map directly onto actions
		ld e,a

		ld a,(keyboard_lines + 1)	; keyboard line 1
		bit 0,a				; left cursor key
		jr nz,$+4
		set action_left_bit,e

		ld a,(keyboard_lines + 2)	; keyboard line 2
		bit 2,a				; return key
		jr nz,$+4
		set action_select_bit,d

		ld a,(keyboard_lines + 3)	; keyboard line 3
		bit 3,a				; p key
		jr nz,$+4
		set action_escape_bit,d

		ld a,(keyboard_lines + 4)	; keyboard line 4
		bit 6,a				; m key
		jr nz,$+4
		set action_m_bit,d

		ld a,(keyboard_lines + 5)	; keyboard line 5
		bit 7,a				; space bar
		jr nz,$+4
		set action_select_bit,d

		ld a,(keyboard_lines + 6)	; keyboard line 6
		bit 2,a				; r key
		jr nz,$+4
		set action_r_bit,d

		ld a,(keyboard_lines + 8)	; keyboard line 8
		bit 2,a				; esc key
		jr nz,$+4
		set action_escape_bit,d
		bit 3,a				; q key
		jr nz,$+4
		set action_q_bit,d
		bit 5,a				; a key
		jr nz,$+4
		set action_a_bit,d

		ld a,(keyboard_lines + 9)	; keyboard line 9
		bit 0,a				; joystick up
		jr nz,$+4
		set action_up_bit,d
		bit 1,a				; joystick down
		jr nz,$+4
		set action_down_bit,d
		bit 2,a				; joystick left
		jr nz,$+4
		set action_left_bit,d
		bit 3,a				; joystick right
		jr nz,$+4
		set action_right_bit,d
		bit 4,a				; joystick fire
		jr nz,$+4
		set action_select_bit,d

		ld hl,movement_actions_mask	; filter movement actions
		ld a,e
		and (hl)
		ld e,a
		inc hl				; filter other actions
		ld a,d
		and (hl)
		ld d,a

		ld hl,(movement_actions_cur)	; L = prev movement actions, H = prev other actions
		ld (movement_actions_cur),de	; store current actions

		; calculate new other actions
		ld a,h
		xor d
		and d
		ld (other_actions_new),a

		; calculate new movement actions
		xor a
		ld (movement_actions_new),a	; initially set to zero

		ld a,e				; if there are no movement actions then just return
		or a
		ret z

		ld a,l				; A = prev movement actions
		or a

		ld hl,.countdown
		ld a,6				; load A with long countdown timer
		jr z,.set_countdown		; if weren't previously moving then set new actions (setting long timer)

		dec (hl)			; otherwise, decrement movement countdown
		ret nz				; if not counted down yet then return

		ld a,3				; otherwise, next countdown will use short timer
.set_countdown
		ld (hl),a			; reset countdown (to long or short timer)
		ld a,e				; load A with current movement actions
		ld (movement_actions_new),a	; copy current movement actions to new actions
		ret
.countdown	defb 0

; ----------------------------------------------------------------

movement_actions_cur	defb 0			; currently pressed keys (filtered by current mask)
other_actions_cur	defb 0

movement_actions_new	defb 0			; new actions, ie those on which we need to act
other_actions_new	defb 0

movement_actions_mask	defb 0			; masks to filter currently allowed actions
other_actions_mask	defb 0
