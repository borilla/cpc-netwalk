;; render a tile
;; note: assumes tile data all sits in same 256 byte page
;; entry:
;;	DE: screen address (of top-left of sprite)
;;	HL: sprite data
;; modifies:
;;	AF,BC,DE,HL
;; flags:
;;	Z: reset
tile_render	ld bc,#800 + #3d + 24		;; we want C to equal #3d after 24 LDI instructions
		call .render_char_row		;; render first character row (8 pixel rows)
		inc l				;; render second character row
		ld b,#c8			;; add de,#c83d (-2048 * 7 + 64 - 3)
		ex hl,de
		add hl,bc
		ex hl,de
		ld b,8
.render_char_row
repeat 7
		ldi:ldi:ldi			;; [15] copy three bytes
		ld a,(hl):ld (de),a: inc l	;; [5] copy byte
		dec e:dec e:dec e		;; [3] reset to left of tile
		ld a,d:add a,b:ld d,a		;; [3] add de,#800
rend
		ldi:ldi:ldi			;; [15] copy three bytes
		ld a,(hl):ld (de),a		;; [4] copy byte
						;; =[201]
		ret

;; render a transparent tile, containing inline mask data
;; note: assumes tile data all sits in same 256 byte page
;; entry:
;;	DE: screen address (of top-left of sprite)
;;	HL: sprite data
;; modifies:
;;	AF,BC,DE,HL
;; flags:
;;	Z: set
tile_render_trans
		call .render_char_row		;; render first character row (8 pixel rows)
		ld bc,#c83d			;; add de,#c83d (-2048 * 7 + 64 - 3)
		ex hl,de
		add hl,bc
		ex hl,de
.render_char_row
		ld b,8				;; LD B,8 (row count)
		ld c,b				;; LD C,8 (constant 8)
.render_pixel_row
		ld a,(de)			;; [2] read screen data
		and (hl)			;; [2] AND with pixel mask
		inc l				;; [1]
		or (hl)				;; [2] OR with sprite data
		inc l				;; [1]
		ld (de),a			;; [2] write result to screem
		inc e				;; [1]

		ld a,(de)
		and (hl)
		inc l
		or (hl)
		inc l
		ld (de),a
		inc e

		ld a,(de)
		and (hl)
		inc l
		or (hl)
		inc l
		ld (de),a
		inc e

		ld a,(de)
		and (hl)
		inc l
		or (hl)
		inc l
		ld (de),a

		dec b				;; if last row then return
		ret z

		dec e				;; reset to left of tile
		dec e
		dec e

		ld a,d				;; go to next row
		add c
		ld d,a

		jr .render_pixel_row

;; render a transparent tile, using a table to lookup mask
;; note: assumes tile data all sits in same 256 byte page
;; entry:
;;	BC: mask lookup table [note: we only really need B to point at high-byte]
;;	DE: screen address
;;	HL: sprite data
;; modifies:
;;	AF,BC,DE,HL,LX
;; flags:
;;	Z: set
; todo: currently unused
tile_render_mask
		ex de,hl			;; swap, so that DE points at sprite, HL points at screen
		call .render_char_row		;; render first eight rows
		ld a,b				;; temporarily store high byte of mask table
		ld bc,#c83d			;; move to next character row (-2048 * 7 + 64 - 3)
		add hl,bc
		ld b,a				;; restore BC to point at mask table
.render_char_row
		ld ixl,8			;; use IXL as row count
.render_pixel_row
		ld a,(de)			;; [2] read sprite byte
		ld c,a				;; [1] point BC at mask byte
		ld a,(bc)			;; [2] read pixel mask
		and (hl)			;; [2] AND with screen
		or c				;; [1] OR with sprite
		ld (hl),a			;; [2] write result to screen
		inc e				;; [1] move to next sprite byte
		inc l				;; [1] move to next screen byte

		ld a,(de)
		ld c,a
		ld a,(bc)
		and (hl)
		or c
		ld (hl),a
		inc e
		inc l

		ld a,(de)
		ld c,a
		ld a,(bc)
		and (hl)
		or c
		ld (hl),a
		inc e
		inc l

		ld a,(de)
		ld c,a
		ld a,(bc)
		and (hl)
		or c
		ld (hl),a
		inc e

		dec ixl				;; if last row then return
		ret z

		dec l				;; reset to left of tile
		dec l
		dec l

		ld a,h				;; go to next row
		add a,8
		ld h,a

		jr .render_pixel_row

;; render a blank tile (ie all ink 0)
;; entry:
;;	DE: screen address (of top-left of sprite)
;; modifies:
;;	AF,BC,DE,HL
tile_render_blank
		ex de,hl			;; use HL as screen address
		call .render_char_row
		ld bc,#c83d			;; add de,#c83d (-2048 * 7 + 64 - 3) (#c040 - 3)
		add hl,bc
.render_char_row
		ld bc,#800			;; B = 8, C = 0
		ld a,h
repeat 7
		ld (hl),c			;; [2]
		inc l				;; [1]
		ld (hl),c			;; [2]
		inc l				;; [1]
		ld (hl),c			;; [2]
		inc l				;; [1]
		ld (hl),c			;; [2]
		dec l				;; [1]
		dec l				;; [1]
		dec l				;; [1]
		add a,b				;; [1]
		ld h,a				;; [1]
rend
		ld (hl),c			;; [2]
		inc l				;; [1]
		ld (hl),c			;; [2]
		inc l				;; [1]
		ld (hl),c			;; [2]
		inc l				;; [1]
		ld (hl),c			;; [2]
						;; =[109]
		ret

;; render a half-blank tile (ie every other pixel is ink 0)
;; entry:
;;	DE: screen address (of top-left of sprite)
;; modifies:
;;	AF,BC,DE,HL
tile_render_shaded
		ex de,hl			;; use HL as screen address
		ld de,%1010101001010101		;; D = %10101010, E = %01010101
		call .render_char_row
		ld bc,#c83d			;; add de,#c83d (-2048 * 7 + 64 - 3) (#c040 - 3)
		add hl,bc
.render_char_row
		ld b,8				;; B = 8
		ld a,h
repeat 3
		ld a,(hl):and d:ld (hl),a:inc l	;; [6]
		ld a,(hl):and d:ld (hl),a:inc l	;; [6]
		ld a,(hl):and d:ld (hl),a:inc l	;; [6]
		ld a,(hl):and d:ld (hl),a	;; [5]
		dec l:dec l:dec l		;; [3]
		ld a,h:add b:ld h,a		;; [3]

		ld a,(hl):and e:ld (hl),a:inc l	;; [6]
		ld a,(hl):and e:ld (hl),a:inc l	;; [6]
		ld a,(hl):and e:ld (hl),a:inc l	;; [6]
		ld a,(hl):and e:ld (hl),a	;; [5]
		dec l:dec l:dec l		;; [3]
		ld a,h:add b:ld h,a		;; [3]
rend
		ld a,(hl):and d:ld (hl),a:inc l	;; [6]
		ld a,(hl):and d:ld (hl),a:inc l	;; [6]
		ld a,(hl):and d:ld (hl),a:inc l	;; [6]
		ld a,(hl):and d:ld (hl),a	;; [5]
		dec l:dec l:dec l		;; [3]
		ld a,h:add b:ld h,a		;; [3]

		ld a,(hl):and e:ld (hl),a:inc l	;; [6]
		ld a,(hl):and e:ld (hl),a:inc l	;; [6]
		ld a,(hl):and e:ld (hl),a:inc l	;; [6]
		ld a,(hl):and e:ld (hl),a	;; [5]

		ret

;; get screen address of tile based on current tile_origin (origin + 4x + 128y)
;; entry:
;;	A: tile index [yyyyxxxx] (x + y * 16)
;; exit:
;;	DE: screen address corresponding to tile index
;; modifies:
;;	A,HL
tile_screen_addr
		rlca
		rlca
		ld d,a			;; use D for temporary storage
		and %00111100
		ld e,a			;; E = x * 4
		ld a,d
		rlca
		ld d,a
		and %10000000
		or e
		ld e,a			;; E = x * 4 + (y * 128) % 256
		ld a,d
		and %00000111
		ld d,a			;; D = (y * 128) / 256
		ld hl,(tile_origin)
		add hl,de
		ex de,hl
		ret

;; get tile data address from its index (i * 64 + base)
;; entry:
;;	A: tile index (0..79)
;; exit:
;;	A: same as H
;;	HL: tile address
tile_data_addr	rrca
		rrca
		ld l,a
		and %00111111
		ld h,a
		ld a,l
		and %11000000
		add tile_data and #ff	;; note: if tile data is aligned to 256 byte page boundary then could skip this
		ld l,a
		ld a,tile_data / 256
		adc h
		ld h,a
		ret

;; calculate and set tile origin based on grid size
;; entry:
;;	A: grid size (%hhhhwwww)
;; exit:
;;	A: unmodified
;;	HL: new tile origin
;; modifies:
;;	C,DE
tile_calculate_origin
		ld hl,#c800
		ld c,a			;; C = copy of grid size

		and %00001111		;; isolate width
		jr z,.calc_y
		rlca			;; A = 2 * width
		neg			;; A = -2 * width
		add #20			;; A = 32 - 2 * width
		ld l,a
.calc_y
		ld a,c
		and %11110000		;; A = height * 16
		jr z,.end
		ld d,0			;; LD DE,height * #40
		sla a
		rl d
		sla a
		rl d
		ld e,a
		or a			;; clear carry
		ld h,#c4
		sbc hl,de
		ld de,#0040		;; shift down one row (for game-data at top of screen)
		adc hl,de
.end
		ld (tile_origin),hl
		ld a,c
		ret

;; ----------------------------------------------------------------
;; tile data
;; ----------------------------------------------------------------

tile_origin	defw #c000

		align #100

;; lookup table for masking out ink 0 pixels. AND with screen data, then OR with pixel data.
; todo: currently unused
tile_mask_lookup
		defb #ff,#ee,#dd,#cc,#bb,#aa,#99,#88,#77,#66,#55,#44,#33,#22,#11,#00,#ee,#ee,#cc,#cc,#aa,#aa,#88,#88,#66,#66,#44,#44,#22,#22,#00,#00
		defb #dd,#cc,#dd,#cc,#99,#88,#99,#88,#55,#44,#55,#44,#11,#00,#11,#00,#cc,#cc,#cc,#cc,#88,#88,#88,#88,#44,#44,#44,#44,#00,#00,#00,#00
		defb #bb,#aa,#99,#88,#bb,#aa,#99,#88,#33,#22,#11,#00,#33,#22,#11,#00,#aa,#aa,#88,#88,#aa,#aa,#88,#88,#22,#22,#00,#00,#22,#22,#00,#00
		defb #99,#88,#99,#88,#99,#88,#99,#88,#11,#00,#11,#00,#11,#00,#11,#00,#88,#88,#88,#88,#88,#88,#88,#88,#00,#00,#00,#00,#00,#00,#00,#00
		defb #77,#66,#55,#44,#33,#22,#11,#00,#77,#66,#55,#44,#33,#22,#11,#00,#66,#66,#44,#44,#22,#22,#00,#00,#66,#66,#44,#44,#22,#22,#00,#00
		defb #55,#44,#55,#44,#11,#00,#11,#00,#55,#44,#55,#44,#11,#00,#11,#00,#44,#44,#44,#44,#00,#00,#00,#00,#44,#44,#44,#44,#00,#00,#00,#00
		defb #33,#22,#11,#00,#33,#22,#11,#00,#33,#22,#11,#00,#33,#22,#11,#00,#22,#22,#00,#00,#22,#22,#00,#00,#22,#22,#00,#00,#22,#22,#00,#00
		defb #11,#00,#11,#00,#11,#00,#11,#00,#11,#00,#11,#00,#11,#00,#11,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00

tile_data
		include "sprites/tile_data.asm"
