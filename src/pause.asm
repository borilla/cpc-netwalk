pause_toggle
		ld a,(.is_paused)
		xor #ff
		ld (.is_paused),a
		jr z,.unpause
.pause
		ld hl,PLY_AKG_Stop		; stop any playing music tones
		call music_play.call_subroutine
		ld hl,%0000000000000010		; only allow 'p' action
		ld (actions_mask),hl
		ld hl,.interrupt_table_pause
		call assign_interrupts
		ret
.unpause
		ld hl,%1111111111111111		; allow all actions
		ld (actions_mask),hl
		; todo: re-render entire grid
		ld hl,.interrupt_table_play
		call assign_interrupts
		ret

.is_paused	defb 0

.interrupt_table_pause
		defw set_palette_text		; 0
		defw set_palette_grid		; 1
		defw scan_keyboard		; 2
		defw read_actions		; 3
		defw process_other_actions	; 4
		defw noop			; 5

		defw set_palette_text		; 6
		defw set_palette_grid		; 7
		defw noop			; 8
		defw noop			; 9
		defw noop			; 10
		defw noop			; 11

.interrupt_table_play
		defw get_actions		; 0
		defw render_clock		; 1
		defw moves_render		; 2
		defw noop			; 3
		defw music_play			; 4
		defw noop			; 5

		defw render_important_tiles	; 6
		defw render_clock		; 7
		defw rotations_render		; 8
		defw connections_render		; 9
		defw music_play			; 10
		defw noop			; 11
