pause_toggle
.is_paused	equ $+1
		ld a,0				; LD A,(.is_paused)
		xor 1
		ld (.is_paused),a
		jr z,.unpause
.pause
		ld hl,PLY_AKG_Stop		; stop any playing music tones
		call music_play.call_subroutine
		ld hl,%0000000000000010		; only allow 'p' action
		ld (actions_mask),hl
		ld hl,interrupt_table_pause
		call assign_interrupts
		ld hl,pause_loop
		ld (main_loop),hl
		ret
.unpause
		ld hl,%1111111111111111		; allow all actions
		ld (actions_mask),hl
		ld hl,interrupt_table_play
		call assign_interrupts
		ld hl,main_loop_game
		ld (main_loop),hl
		ret

interrupt_table_pause
		defw set_palette_paused		; 0
		defw noop			; 1
		defw scan_keyboard		; 2
		defw read_actions		; 3
		defw process_other_actions	; 4
		defw noop			; 5

		defw set_palette_paused		; 6
		defw noop			; 7
		defw noop			; 8
		defw noop			; 9
		defw noop			; 10
		defw noop			; 11

pause_loop
		call hide_next_tile
		jr z,.show_message		; if all tiles are hidden then show paused message
		ld b,#88
.wait
		djnz .wait
		ret
.show_message
		ld hl,string_paused		; show "paused" message
		ld de,#C41A
		call render_string
		ld hl,set_palette_text		; set palette for message
		ld (interrupt_1),hl
		ld (interrupt_7),hl
		ld hl,empty_loop		; do nothing except wait for 'p' key
		ld (main_loop),hl
empty_loop
		ret

string_paused	str 'PAUSED'

interrupt_table_play
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

;; render next tile that needs hiding (if any)
;; modifies:
;;	A,BC,DE,HL,IX
;; flags:
;;	Z: if no tile was rendered
;;	NZ: if tile was rendered
hide_next_tile
.tile_index	equ $+1
		ld a,0				; LD A,(.tile_index)
		ld b,0				; loop 256 times
		ld h,rendered_tiles / 256
.loop
		ld c,a				; go to next (pseudo-random) index
		add a,a
		add a,a
		add a,c
		inc a

		ld l,a
		ld a,(hl)
		or a
		jp nz,.render_tile		; if tile is not blank then render it
		ld a,l
		djnz .loop			; if rendered tile is blank then move to next tile
		xor a				; no tile to render this time; set Z flag and return
		ret
.render_tile
		bit 7,a				; check if tile is already shaded (use bit 7 to mark this)
		ld a,l				; A = tile index
		ld (.tile_index),a
		jr nz,.render_blank
.render_shaded
		set 7,(hl)			; mark tile as shaded
		call tile_screen_addr		; render shaded tile
		call tile_render_shaded
		or 1				; reset Z flag and return
		ret
.render_blank
		ld (hl),0			; mark tile as blank
		call tile_screen_addr		; render blank tile
		call tile_render_blank
		or 1				; reset Z flag and return
		ret
