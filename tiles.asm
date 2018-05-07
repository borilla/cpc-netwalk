;; render a tile
;; entry:
;;	DE: screen address (of top-left of sprite)
;;	HL: sprite data
;; modifies:
;;	AF,BC,DE,HL
render_tile	ld bc,&800 + &3d + 24		;; we want C to equal &3d after 24 LDI instructions
		call _render_half_tile
		ld b,&c8			;; add de,&c83d (-2048 * 7 + 64 - 3)
		ex hl,de
		add hl,bc
		ex hl,de
		ld b,8
_render_half_tile
repeat 7
		ldi:ldi:ldi			;; [15] copy three bytes
		ld a,(hl):ld (de),a: inc l	;; [5] copy byte
		dec e:dec e:dec e		;; [3] reset to left of tile
		ld a,d:add a,b:ld d,a		;; [3] add de,&800
rend
		ldi:ldi:ldi			;; [15] copy three bytes
		ld a,(hl):ld (de),a: inc l	;; [5] copy byte
		ret

;; get screen address of tile (origin + 4x + 128y)
;; entry:
;;	A: tile index [yyyyxxxx] (x + y * 16)
;; exit:
;;	A: same as D
;;	DE: screen address corresponding to tile index
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
		or &c0			;; screen origin / 256
		ld d,a			;; D = (y * 128) / 256
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
		add tile_data and &ff	;; note: if tile data is aligned to 256 byte page boundary then could skip this
		ld l,a
		ld a,tile_data / 256
		adc h
		ld h,a
		ret

;; ----------------------------------------------------------------
;; tile data
;; ----------------------------------------------------------------

align 64
tile_data
read "maze/sprite-data.asm"
