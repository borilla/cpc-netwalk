;; render a sprite
;; entry:
;;	DE: screen address (of top-left of sprite)
;;	HL: sprite data
;; modifies:
;;	AF,BC,DE,HL
render_sprite	ld bc,&800 + &3d + 24		;; we want C to equal &3d after 24 LDI instructions
		call _render_half_sprite
		ld b,&c8			;; add de,&c83d (-2048 * 7 + 64 - 3)
		ex hl,de
		add hl,bc
		ex hl,de
		ld b,8
_render_half_sprite
repeat 7
		ldi:ldi:ldi			;; [15] copy three bytes
		ld a,(hl):ld (de),a: inc l	;; [5] copy byte
		dec e:dec e:dec e		;; [3] reset to left of sprite
		ld a,d:add a,b:ld d,a		;; [3] add de,&800
rend
		ldi:ldi:ldi			;; [15] copy three bytes
		ld a,(hl):ld (de),a: inc l	;; [5] copy byte
		ret

;; get screen address of grid cell (origin + 4x + 128y)
;; entry:
;;	A: cell index [yyyyxxxx] (x + y * 16)
;; exit:
;;	A: same as D
;;	DE: screen address corresponding to cell index
cell_screen_addr
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

;; get sprite address from its index (i * 64 + base)
;; entry:
;;	A: sprite index (0..79)
;; exit:
;;	A: same as H
;;	HL: sprite address
sprite_from_index
		rrca
		rrca
		ld l,a
		and %00111111
		ld h,a
		ld a,l
		and %11000000
		add sprite_data and &ff	;; note: if sprite data is aligned to 256 byte page boundary then could skip this
		ld l,a
		ld a,sprite_data / 256
		adc h
		ld h,a
		ret

;; ----------------------------------------------------------------
;; sprite data
;; ----------------------------------------------------------------

align 64
sprite_data
read "maze/sprite-data.asm"
