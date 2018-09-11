time_screen_addr	equ &c030

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

		ld de,time_screen_addr		;; min hi
		ld hl,char_data_0
		call char_render
		ld de,time_screen_addr + 2	;; min lo
		ld hl,char_data_0
		call char_render
		ld de,time_screen_addr + 4
		ld hl,char_data_colon
		call char_render
		ld de,time_screen_addr + 6	;; sec hi
		ld hl,char_data_0
		call char_render
		ld de,time_screen_addr + 8	;; sec lo
		ld hl,char_data_0
		call char_render
		ld de,time_screen_addr + 10
		ld hl,char_data_colon
		call char_render
		ld de,time_screen_addr + 12	;; ms hi
		ld hl,char_data_0
		call char_render
		ld de,time_screen_addr + 14	;; ms lo
		ld hl,char_data_0
		call char_render
		ret

time_inc_ms_lo
		ld a,(time_data_ms_lo)
		cp 8
		jr nz,_tims_lo
		call time_inc_ms_hi
		ld a,&fe
_tims_lo	add a,2
		ld (time_data_ms_lo),a
		ld de,time_screen_addr + 14
		call char_render_digit
		ret

;; --------

time_inc_ms_hi
		ld a,(time_data_ms_hi)
		cp 9
		jr nz,_tims_hi
		call time_inc_sec_lo
		ld a,&ff
_tims_hi	inc a
		ld (time_data_ms_hi),a
		ld de,time_screen_addr + 12
		call char_render_digit
		ret

;; --------

time_inc_sec_lo
		ld a,(time_data_sec_lo)
		cp 9
		jr nz,_tis_lo
		call time_inc_sec_hi
		ld a,&ff
_tis_lo		inc a
		ld (time_data_sec_lo),a
		ld de,time_screen_addr + 8
		call char_render_digit
		ret

;; --------

time_inc_sec_hi
		ld a,(time_data_sec_hi)
		cp 5
		jr nz,_tis_hi
		call time_inc_min_lo
		ld a,&ff
_tis_hi		inc a
		ld (time_data_sec_hi),a
		ld de,time_screen_addr + 6
		call char_render_digit
		ret

;; --------

time_inc_min_lo
		ld a,(time_data_min_lo)
		cp 9
		jr nz,_tim_lo
		call time_inc_min_hi
		ld a,&ff
_tim_lo		inc a
		ld (time_data_min_lo),a
		ld de,time_screen_addr + 2
		call char_render_digit
		ret

;; --------

time_inc_min_hi
		ld a,(time_data_min_hi)
		cp 5
		jr nz,_tim_hi
;;		call time_inc_hour
		ld a,&ff
_tim_hi		inc a
		ld (time_data_min_hi),a
		ld de,time_screen_addr
		call char_render_digit
		ret

;; --------

time_data_ms_lo		defb 0
time_data_ms_hi		defb 0
time_data_sec_lo	defb 0
time_data_sec_hi	defb 0
time_data_min_lo	defb 0
time_data_min_hi	defb 0
