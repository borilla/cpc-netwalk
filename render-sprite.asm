;; ----------------------------------------------------------------
;; main
;; ----------------------------------------------------------------

setup_screen	wait_for_vsync
		setup_minimal_interrupt_handler
		;; set screen mode
		ga_select_mode 1		;; mode 1
		;; reset screen origin
		crtc_set_screen_address &c000,0	;; page &c000, offset 0
		;; setup screen resolution
		crtc_write_register 1,32	;; horizontal displayed: 32 characters, 64 bytes, 256 mode 1 pixels
		crtc_write_register 2,42	;; horizontal sync position
		crtc_write_register 6,32	;; vertical displayed: 32 characters, 256 pixels
		crtc_write_register 7,34	;; vertical sync position
		;; setup pen colors
		ga_set_pen 0,ink_bright_white	;; background
		ga_set_pen 1,ink_white
		ga_set_pen 2,ink_bright_cyan
		ga_set_pen 3,ink_pastel_blue
		ga_set_pen 16,ink_black		;; border
		ret

;; render a sprite
;; entry:
;;	DE: screen address (of top-left of sprite)
;;	HL: sprite data
render_sprite	ld bc,&800 + &3d + 24			;; we want C to equal &3d after 24 LDI instructions
		call _render_half_sprite
		ld b,&c8				;; add de,&c83d (-2048 * 7 + 64 - 3)
		ex hl,de
		add hl,bc
		ex hl,de
		ld b,8
_render_half_sprite
repeat 7
		ldi:ldi:ldi				;; [15] copy three bytes
		ld a,(hl):ld (de),a: inc l		;; [5] copy byte
		dec e:dec e:dec e			;; [3] reset to left of sprite
		ld a,d:add a,b:ld d,a			;; [3] add de,&800
rend
		ldi:ldi:ldi				;; [15] copy three bytes
		ld a,(hl):ld (de),a: inc l		;; [5] copy byte
		ret

;; ----------------------------------------------------------------
;; sprite data
;; ----------------------------------------------------------------

read "maze/sprite-data.asm"
