moves_init
		ld de,&c000
		ld hl,char_data_M
		call char_render
		ld de,&c002
		ld hl,char_data_O
		call char_render
		ld de,&c004
		ld hl,char_data_V
		call char_render
		ld de,&c006
		ld hl,char_data_colon
		call char_render
		ld de,&c008
		ld hl,char_data_0
		call char_render
		ld de,&c00a
		ld hl,char_data_0
		call char_render
		ld de,&c00c
		ld hl,char_data_0
		call char_render
		ld de,&c00e
		ld hl,char_data_0
		call char_render
		ret

rotations_init
		ld de,&c019
		ld hl,char_data_R
		call char_render
		ld de,&c01b
		ld hl,char_data_O
		call char_render
		ld de,&c01d
		ld hl,char_data_T
		call char_render
		ld de,&c01f
		ld hl,char_data_colon
		call char_render
		ld de,&c021
		ld hl,char_data_0
		call char_render
		ld de,&c023
		ld hl,char_data_0
		call char_render
		ld de,&c025
		ld hl,char_data_0
		call char_render
		ld de,&c027
		ld hl,char_data_0
		call char_render
		ret

moves_inc
		ld hl,(mov_data_count)
		ld a,l
		or a				;; clear flags before DAA
		inc a
		daa
		ld l,a
		ld (mov_data_count),hl
		and %00001111
		ld de,&c00e
		push hl
		call char_render_digit
		pop hl
		ld a,l
		and %11110000
		rrca
		rrca
		rrca
		rrca
		ld de,&c00c
		push hl
		call char_render_digit
		pop hl

		ld a,l
		or a
		ret nz

		ld a,h
		inc a
		daa
		ld h,a
		ld (mov_data_count),hl
		and %00001111
		ld de,&c00a
		push hl
		call char_render_digit
		pop hl
		ld a,h
		and %11110000
		rrca
		rrca
		rrca
		rrca
		ld de,&c008
		call char_render_digit
		ret

rotations_inc
		ld hl,(rot_data_count)
		ld a,l
		or a				;; clear flags before DAA
		inc a
		daa
		ld l,a
		ld (rot_data_count),hl
		and %00001111
		ld de,&c027
		push hl
		call char_render_digit
		pop hl
		ld a,l
		and %11110000
		rrca
		rrca
		rrca
		rrca
		ld de,&c025
		push hl
		call char_render_digit
		pop hl

		ld a,l
		or a
		ret nz

		ld a,h
		inc a
		daa
		ld h,a
		ld (rot_data_count),hl
		and %00001111
		ld de,&c023
		push hl
		call char_render_digit
		pop hl
		ld a,h
		and %11110000
		rrca
		rrca
		rrca
		rrca
		ld de,&c021
		call char_render_digit
		ret

mov_data_count	defw 0
rot_data_count	defw 0
