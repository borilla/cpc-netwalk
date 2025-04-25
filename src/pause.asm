game_state_paused
		; movement_actions_mask
		defb %00000000
		; other_actions_mask
		defb %00000010			; can only unpause from this state
		; interrupt_table 1
		defw set_palette_paused		; 0
		defw noop			; 1 (will be set to set_palette_text later)
		defw read_actions		; 2
		defw process_other_actions	; 3
		defw noop			; 4
		defw noop			; 5
		; interrupt_table 2
		defw set_palette_paused		; 6
		defw noop			; 7 (will be set to set_palette_text later)
		defw noop			; 8
		defw noop			; 9
		defw noop			; 10
		defw noop			; 11
		; main loop
		defw $+2

.main_loop
		call hide_next_tile
		jr z,.show_message		; if all tiles are hidden then show paused message
		ld b,#88			; delay before hiding next tile
.wait
		djnz .wait
		ret
.show_message
		ld hl,.message			; show "paused" message
		ld de,#C41A
		call render_string
		ld hl,set_palette_text		; set palette for message
		ld (interrupt_1),hl
		ld (interrupt_7),hl
		ld hl,noop			; do nothing except wait for 'p' key
		ld (main_loop),hl
		ret
.message	str 'PAUSED'

pause_toggle
		ld hl,hide_next_tile.tile_index	; randomise showing/hiding tiles
		ld a,r
		add (hl)
		ld (hl),a
.is_paused	equ $+1
		ld a,0				; LD A,(.is_paused)
		xor 1
		ld (.is_paused),a
		jr z,.unpause
.pause
		ld hl,PLY_AKG_Stop		; stop any playing music tones
		call music_play.call_subroutine
		ld hl,game_state_paused
		call set_game_state
		ret
.unpause
		ld hl,game_state_playing
		call set_game_state
		ret

; set colours of top info bar when paused
set_palette_paused
		ga_set_pen 2,ink_blue
		ga_set_pen 3,ink_white
		ret

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
