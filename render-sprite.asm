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
render_sprite	call _render_half_sprite
		ld bc,&c83d				;; add de,&c840 (-2048 * 7 + 64 - 3)
		ex hl,de
		add hl,bc
		ex hl,de
_render_half_sprite
		ld b,8					;; [2]
repeat 7
		ld a,(hl):ld (de),a: inc l: inc e	;; [6] copy byte
		ld a,(hl):ld (de),a: inc l: inc e	;; [6] copy byte
		ld a,(hl):ld (de),a: inc l: inc e	;; [6] copy byte
		ld a,(hl):ld (de),a: inc l		;; [5] copy byte
		dec e:dec e:dec e			;; [3] reset to left of sprite
		ld a,d:add a,b:ld d,a			;; [3] add de,&800
rend
		ld a,(hl):ld (de),a: inc l: inc e	;; [6] copy byte
		ld a,(hl):ld (de),a: inc l: inc e	;; [6] copy byte
		ld a,(hl):ld (de),a: inc l: inc e	;; [6] copy byte
		ld a,(hl):ld (de),a: inc l		;; [5] copy byte
		ret

;; ----------------------------------------------------------------
;; sprite data
;; ----------------------------------------------------------------

read "maze/sprite-data.asm"