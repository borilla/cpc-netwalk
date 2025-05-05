time_screen_addr	equ #c030

time_init
		xor a
		ld hl,time_data_ms_lo
		ld (hl),a
		inc hl
		ld (hl),a
		inc hl
		ld (hl),a
		inc hl
		ld (hl),a
		inc hl
		ld (hl),a
		inc hl
		ld (hl),a

		ld de,time_screen_addr
		ld hl,.message
		jp render_string
.message	str '00:00:00'

time_inc_ms_lo
		ld a,(time_data_ms_lo)
		cp 8
		jr nz,.skip
		call time_inc_ms_hi
		ld a,#fe
.skip
		add a,2
		ld (time_data_ms_lo),a
		ld de,time_screen_addr + 14
		call render_char
		ret

;; --------

time_inc_ms_hi
		ld a,(time_data_ms_hi)
		cp 9
		jr nz,.skip
		call time_inc_sec_lo
		ld a,#ff
.skip
		inc a
		ld (time_data_ms_hi),a
		ld de,time_screen_addr + 12
		call render_char
		ret

;; --------

time_inc_sec_lo
		ld a,(time_data_sec_lo)
		cp 9
		jr nz,.skip
		call time_inc_sec_hi
		ld a,#ff
.skip
		inc a
		ld (time_data_sec_lo),a
		ld de,time_screen_addr + 8
		call render_char
		ret

;; --------

time_inc_sec_hi
		ld a,(time_data_sec_hi)
		cp 5
		jr nz,.skip
		call time_inc_min_lo
		ld a,#ff
.skip
		inc a
		ld (time_data_sec_hi),a
		ld de,time_screen_addr + 6
		call render_char
		ret

;; --------

time_inc_min_lo
		ld a,(time_data_min_lo)
		cp 9
		jr nz,.skip
		call time_inc_min_hi
		ld a,#ff
.skip
		inc a
		ld (time_data_min_lo),a
		ld de,time_screen_addr + 2
		call render_char
		ret

;; --------

time_inc_min_hi
		ld a,(time_data_min_hi)
		cp 5
		jr nz,.skip
;;		call time_inc_hour
		ld a,#ff
.skip
		inc a
		ld (time_data_min_hi),a
		ld de,time_screen_addr
		call render_char
		ret

;; --------

time_data_ms_lo		defb 0
time_data_ms_hi		defb 0
time_data_sec_lo	defb 0
time_data_sec_hi	defb 0
time_data_min_lo	defb 0
time_data_min_hi	defb 0
