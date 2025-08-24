game_state_intro
		; movement_actions_mask
		defb %00000000
		; other_actions_mask
		defb %00000011				; select + escape
		; interrupt_table 1
		defw set_palette_logo			; 0
		defw read_actions			; 1
		defw noop				; 2 (will be set to set_palette_text later)
		defw noop				; 3 (will be set to intro_next_char later)
		defw music_play				; 4
		defw intro_process_actions		; 5
		; interrupt_table 2
		defw set_palette_logo			; 6
		defw noop				; 7
		defw noop				; 8 (will be set to set_palette_text later)
		defw noop				; 9 (will be set to intro_next_char later)
		defw music_play				; 10
		defw noop				; 11
		; main loop
		defw .main_loop
.main_loop
		xor a					; reset current page
		ld (.current_page),a
.next_page
		assign_interrupt 3,noop			; pause character animation
		assign_interrupt 9,noop
		assign_interrupt 2,set_palette_black
		assign_interrupt 8,set_palette_black
		call clear_under_logo
		assign_interrupt 2,set_palette_text
		assign_interrupt 8,set_palette_text

		ld hl,.current_page
		ld a,(hl)				; a = current page
		cp intro_page_count			; if we've shown all pages then return to menu
		jp z,intro_exit
		inc (hl)				; update current page

		ld hl,intro_pages			; hl points at address of data for next page
		add a
		add_hl_a
		ld e,(hl)				; ld de,(hl)
		inc hl
		ld d,(hl)
		ld (intro_next_char.current_char),de
.next_row
		ld hl,(intro_next_char.current_char)	; .current_char points to screen pos for next row
		ld e,(hl)				; ld de,(hl)
		inc hl
		ld d,(hl)

		ld a,d					; if de is zero then end of page
		or e
		ret z					; return without resuming animation

		ld (intro_next_char.screen_pos),de
		inc hl
		ld (intro_next_char.current_char),hl
		assign_interrupt 3,intro_next_char	; resume animation
		assign_interrupt 9,intro_next_char	; resume animation

		ld hl,noop				; wait while animating row
		ld (main_loop),hl
		ret
.current_page
		defb 0

; show next character of animated text
intro_next_char
.screen_pos	equ $+1
		ld de,#0000			; ld de,(.screen_pos)
.current_char	equ $+1
		ld hl,#0000			; ld hl,(.current_char)

		ld a,d				; return if screen pos is zero, ie end of text
		or e
		ret z

		ld a,(hl)			; render the character
		res 7,a
		call render_char

		ld hl,(.current_char)
		ld a,(hl)
		inc hl				; point at next char (or position of next row)
		ld (.current_char),hl

		cpl				; if last character of row, then go to next row
		bit 7,a
		jr z,.next_row

		ld hl,(.screen_pos)		; update screen_pos for next char
		inc hl
		inc hl
		ld (.screen_pos),hl
		ret
.next_row
		assign_interrupt 3,noop		; pause animation
		assign_interrupt 9,noop
		ld hl,game_state_intro.next_row
		ld (main_loop),hl
		ret

intro_process_actions
		ld a,(other_actions_new)
		bit action_select_bit,a
		jp nz,intro_next_page
		bit action_escape_bit,a
		jp nz,intro_exit
		ret

intro_next_page
		ld hl,game_state_intro.next_page
		ld (main_loop),hl
		ret

intro_exit
		ld hl,game_state_menu
		jp set_game_state

intro_page_count equ 3

intro_pages
		defw .page_1,.page_2,.page_3
.page_1
		position_text 11,0		; row,column
		str '01 APRIL 2026:'
		position_text 14,0
		str 'THE WORLDWIDE ELITES FOUNDATION'
		position_text 16,0
		str '(WEF) FINALLY ACHIEVES ITS DREAM'
		position_text 19,0
		str 'THE PLANET IS NOW POWERED'
		position_text 21,0
		str 'ENTIRELY BY NET-ZERO RENEWABLE'
		position_text 23,0
		str 'ENERGY AND UNITED UNDER A SINGLE'
		position_text 25,0
		str 'CENTRALIZED GLOBAL DIGITAL'
		position_text 27,0
		str 'CURRENCY'
		defw 0				; end of page
.page_2
		position_text 11,0
		str '06 MAY 2026:'
		position_text 14,0
		str 'AN UNEXPECTEDLY CLOUDY DAY'
		position_text 16,0
		str 'CAUSES A CASCADING LOSS OF POWER'
		position_text 18,0
		str 'ACROSS THE GLOBE. DIGITAL'
		position_text 20,0
		str 'CURRENCY NETWORKS BEGIN TO FAIL'
		position_text 23,0
		str 'FINANCIAL MARKETS COLLAPSE.'
		position_text 25,0
		str 'SUPPLY CHAINS ARE BROKEN. RIOTS'
		position_text 27,0
		str 'IGNITE IN MAJOR CITIES'
		defw 0
.page_3
		position_text 11,0
		str '11 MAY 2026:'
		position_text 14,0
		str 'YOU ARE THE LAST REMANING WEF'
		position_text 16,0
		str 'ENGINEER. YOU MUST RESTORE THESE'
		position_text 18,0
		str 'CRITICAL NETWORKS AS QUICKLY AS'
		position_text 20,0
		str 'POSSIBLE'
		position_text 23,0
		str 'FAILURE IS NOT AN OPTION. CHAOS'
		position_text 25,0
		str 'CANNOT BE TOLERATED. THE NEW'
		position_text 27,0
		str 'WORLD ORDER MUST BE RESTORED!'
		defw 0
