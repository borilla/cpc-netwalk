crtc_horizontal_total		equ 0	;; value -1 (63)
crtc_horizontal_displayed	equ 1	;; (40)
crtc_horizontal_sync_position	equ 2	;; (46)
crtc_sync_width			equ 3	;; vvvvhhhh (142 = &8e = 8x16 + 14)
crtc_vertical_total		equ 4	;; value -1 (38)
crtc_vertical_total_adjust	equ 5	;; (0)
crtc_vertical_displayed		equ 6	;; (25)
crtc_vertical_sync_position	equ 7	;; (30) 
;; crtc_interlace_and_skew	equ 8	;; (0)
crtc_maximum_raster_addr	equ 9	;; lines per char, 0-7 (7)
;; crtc_cursor_start_raster	equ 10	;; (0)
;; crtc_cursor_end_raster	equ 11	;; (0)
crtc_screen_start_address_high	equ 12	;; (32)
crtc_screen_start_address_low	equ 13	;; (0)
;; crtc_cursor_register_high	equ 14	;; (0)
;; crtc_cursor_register_low	equ 15	;; (0)
;; crtc_light_pen_high		equ 16	;; (0)
;; crtc_light_pen_low		equ 17	;; (0)

macro crtc_write_register register,value
		ld bc,#bc00 + {register}
		out (c),c
		ld bc,#bd00 + {value}
		out (c),c
mend

macro crtc_set_screen_address page,offset
		crtc_set_screen_address_high {page},{offset},0
		crtc_set_screen_address_low {page},{offset}
mend

;; page = &0000|&4000|&8000|&c0000, offset = 0..1024, overflow = 0|1 (16k or 32k screen)
macro crtc_set_screen_address_high page,offset,overflow
@value1		equ {page} >> 10	;; shift page right by 10 bits
@value2		equ {offset} >> 8	;; shift offset right by 8 bits
@value3		equ {overflow} * 12	;; convert to %00 or %11 and shift left by 2 bits
		crtc_write_register crtc_screen_start_address_high,{eval}(@value1 + @value2 + @value3)
mend

macro crtc_set_screen_address_low page,offset
@value		equ lo({offset})		;; lower 8 bits of offset
		crtc_write_register crtc_screen_start_address_low,{eval}@value
mend
