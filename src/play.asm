
game_state_playing
		; movement_actions_mask
		defb %00001111
		; other_actions_mask
		defb %00000111			; space + pause + toggle-music
		; interrupt_table 1
		defw get_actions		; 0
		defw render_clock		; 1
		defw moves_render		; 2
		defw noop			; 3
		defw music_play			; 4
		defw noop			; 5
		; interrupt_table 2
		defw render_important_tiles	; 6
		defw render_clock		; 7
		defw rotations_render		; 8
		defw connections_render		; 9
		defw music_play			; 10
		defw noop			; 11
		; main_loop
		defw $+2

.main_loop
		ld a,(other_actions_new)
		bit action_q_bit,a		; if 'q' key is pressed then enlarge grid
		jp nz,enlarge_grid									; TODO: These jumps will mess up the stack now that this is a subroutine!
		bit action_a_bit,a		; if 'a' key is pressed then shrink grid
		jp nz,shrink_grid
		bit action_r_bit,a		; if 'r' key is pressed then regenerate grid
		jp nz,generate_maze
		call render_next_tile
		ld a,(recalc_required)
		or a
		jr z,.check_for_completion
		call recalc_connected_tiles
		ret
.check_for_completion
		ld a,(maze_terms_total)		; check if all terminals are connected
		ld hl,maze_terms_connected
		cp (hl)
		ret nz
		ld a,(rotation_queue_cur)	; check if any pending rotations
		ld hl,rotation_queue_next
		cp (hl)
		ret nz
.game_complete
		assign_interrupt 0,get_actions
		assign_interrupt 1,set_palette_grid
		assign_interrupt 2,noop
		assign_interrupt 6,set_palette_text
		assign_interrupt 7,set_palette_grid
		assign_interrupt 8,noop
		ret

; set palette for info panel at top of screen
set_palette_text
		ga_set_pen 2,ink_sky_blue
		ga_set_pen 3,ink_bright_white
		ret

; set palette for main game grid
set_palette_grid
		ga_set_pen 3,ink_lime
		ret

;; scan keyboard, process movement and rotation
get_actions	call set_palette_text
		call read_actions
		call do_movement_action
		call do_rotate_action
		call process_other_actions
		jp update_rotating_tile

; render prev, current and rotating tiles (as necessary)
render_important_tiles
		call set_palette_text
		call render_selected_tile
		jp render_rotating_tile

; increment and re-render time counter
render_clock
		call set_palette_grid
		jp time_inc_ms_lo


; if prev selected tile not equal to currently selected tile then render both
render_selected_tile
		ld a,(tile_index_selected)
		ld hl,tile_index_prev
		cp (hl)
		ret z
		ld c,a
		ld a,(hl)
		ld (hl),c
		call render_grid_tile
		ld a,(tile_index_selected)
		jp render_grid_tile

; render rotating tile if it is different from rendered state
render_rotating_tile
		ld hl,rotation_queue
		ld a,(rotation_queue_cur)
		add_hl_a
		ld a,(hl)
		jp render_if_modified

; render next tile that needs rendering (if any)
; modifies:
;	A,BC,DE,HL,IX
; flags:
;	Z: if no tile was rendered
;	NZ: if tile was rendered
render_next_tile
.tile_index	equ $+1
		ld a,0			; LD A,(.tile_index)
		ld b,0			; loop 256 times
.loop
		ld c,a			; go to next (pseudo-random) index
		add a,a
		add a,a
		add a,c
		inc a

		call render_if_modified
		jr nz,.end		; if tile was rendered then end loop

		djnz .loop
		xor a			; no tile to render this time; set Z flag and return
		ret
.end
		ld (.tile_index),a	; store starting index for next call
		or 1			; reset Z flag and return
		ret

; render a grid tile if it has been modified from rendered state
; entry:
;	A: index of grid tile to render
; exit:
;	A: unmodified
; modifies:
;	BC,DE,HL,IX
; flags:
;	Z: set if no tile is rendered, NZ if tile is rendered
render_if_modified
		ld h,maze_data / 256
		ld l,a
		ld a,(hl)
		ld h,rendered_tiles / 256
		cp (hl)
		ld a,l
		ret z
		; otherwise, fall through to render_grid_tile

; render a grid tile (and power supply and reticle overlays if appropriate)
; entry:
;	A: index of grid tile to render
; exit:
;	A: unmodified
; modifies:
;	BC,DE,HL,IX
; flags:
;	Z: always reset
render_grid_tile
		ld ixh,a			; keep original index
		ld h,maze_data / 256
		ld l,a
		push hl
		call tile_screen_addr		; DE = screen address for tile
		pop hl
		ld a,(hl)
		ld h,rendered_tiles / 256	; update rendered tile
		ld (hl),a
		call tile_data_addr		; HL = sprite data for tile
		call tile_render		; render the tile

		ld a,(tile_index_supply)
		cp ixh
		call z,render_power_supply

		ld a,(tile_index_selected)
		cp ixh
		call z,render_reticle

		or 1				; reset Z flag
		ld a,ixh			; restore A
		ret

; render power supply overlay
; entry:
;	A: index tile
; modifies:
;	AF,BC,DE,HL,IXL
render_power_supply
		call tile_screen_addr		; DE points at screen
		ld hl,tile_supply_trans		; HL points at tile data
		jp tile_render_trans

; render reticle overlay indicating selected tile
; entry
;	A: index of tile
; modifies:
;	AF,BC,DE,HL,LX
render_reticle
		call tile_screen_addr		; DE points at screen
		ld hl,tile_selected_trans	; HL points at tile data
		jp tile_render_trans

;; update currently selected tile based on new movement actions
do_movement_action
		ld a,(maze_index_limits)
		ld e,a
		and %00001111
		ld d,a				;; D is maximum x-value
		ld a,e
		and %11110000
		ld e,a				;; E is maximum y-value

		ld a,(movement_actions_new)	; B = new movement actions
		ld b,a

		ld hl,tile_index_selected	;; HL points at tile index
		ld a,(hl)			;; A is tile index

.do_move_up	bit action_up_bit,b
		jr z,.do_move_down		;; not moving up
		ld c,a				;; check that can move up
		and %11110000
		ld a,c
		jr z,.do_move_right		;; can't move up
		sub 16				;; move up
;;		jr .do_move_right		;; we've moved up, so can't also move down

.do_move_down	bit action_down_bit,b
		jr z,.do_move_right		;; not moving down
		ld c,a				;; check that can move down
		and %11110000
		cp e				;; cp max-y-value
		ld a,c
		jr z,.do_move_right		;; can't move down
		add 16				;; move down

.do_move_right	bit action_right_bit,b
		jr z,.do_move_left		;; not moving right
		ld c,a				;; check that can move right
		and %00001111
		cp d				;; cp max-x-value
		ld a,c
		jr z,.do_move_end		;; can't move right
		inc a				;; move right
;;		jr .do_move_end			;; we've moved right, so can't also move left

.do_move_left	bit action_left_bit,b
		jr z,.do_move_end		;; not moving left
		ld c,a				;; check that can move left
		and %00001111
		ld a,c
		jr z,.do_move_end		;; can't move left
		dec a				;; move left

.do_move_end	cp (hl)				;; is index changed?
		ret z

		push af
		push hl
		call moves_inc			;; increment count of moves
		pop hl
		pop af

		ld c,a				;; store new and previous position (so we can re-render them)
		ld a,(hl)
		ld (tile_index_prev),a
		ld (hl),c
		ret

;; if space bar (ie 'rotate') is pressed then add current cell to rotate queue
do_rotate_action
		ld a,(other_actions_new)
		bit action_space_bit,a		;; check for rotate action
		ret z

		ld hl,rotation_queue		;; insert currently selected index into queue
		ld a,(rotation_queue_next)
		ld b,a
		add_hl_a
		ld a,(tile_index_selected)
		ld (hl),a

		ld a,b				;; update "next" index
		inc a
		and %00001111			;; A = A mod 16
		ld (rotation_queue_next),a
		ret

update_rotating_tile
		ld bc,rotation_queue_cur
		ld hl,rotation_queue_next
		ld a,(bc)			;; index of current item in queue
		cp (hl)
		ret z				;; no rotating tile

		ld hl,rotation_queue		;; get tile index from queue
		add_hl_a
		ld a,(hl)

		ld h,maze_data / 256		;; HL points at rotating tile
		ld l,a
		ld a,(hl)			;; A = grid tile value

		add 16				;; increment rotation value
		and %00111111			;; (isolate rotation bits)

		ld e,a				;; store rotated value in E
		and %00110000			;; check if rotation has returned to 0
		jr nz,.write_rotated_value	;; if not returned to zero yet then write new value

		ld d,rot_nibble_data / 256	;; if returned to zero then rotate exits
		ld a,(de)			;; read rotated value from DE
		ld e,a

		ld a,1				;; flag that we need to recalculate connected tiles
		ld (recalc_required),a

		ld a,(bc)			;; update queue index
		inc a
		and %00001111
		ld (bc),a

		push hl				;; TODO: could probably save this push/pop by switching HL and DE
		call rotations_inc		;; update rotations-count
		pop hl

.write_rotated_value
		ld (hl),e			;; store new (rotated) tile value
		ld a,l
		jp render_grid_tile		;; render the tile

recalc_connected_tiles
		xor a
		ld (recalc_required),a
		;; reset connected bits for all maze cells
		ld hl,maze_data
.loop		res is_connected_bit,(hl)
		inc l
		jr nz,.loop

		ld a,(tile_index_supply)
		jp maze_mark_connected

recalc_required		defb 0		; flag that we need to recalculate connected tiles

tile_index_prev		defb 0		; previous position of cursor
tile_index_selected	defb 0		; current position of cursor
tile_index_supply	defb 0		; position of power supply

rotation_queue		defs 16		; circular FIFO queue of pending tiles to rotate
rotation_queue_cur	defb 0		; index of currently rotating tile
rotation_queue_next	defb 0		; index to insert next item in queue

			align #100

rendered_tiles		defs #100,0
