;; ----------------------------------------------------------------
;; macros
;; ----------------------------------------------------------------

read "inc/macros.asm"

;; ----------------------------------------------------------------
;; constants
;; ----------------------------------------------------------------

program_addr	equ &8000
maze_width	equ 8
maze_height	equ 13
exits_top	equ 1
exits_right	equ 2
exits_bottom	equ 4
exits_left	equ 8
exits_all	equ 15

;; ----------------------------------------------------------------
;; init
;; ----------------------------------------------------------------

		nolist
		org program_addr

;; ----------------------------------------------------------------
;; subroutines
;; ----------------------------------------------------------------

maze_generate	call maze_clear
		call maze_edges
		call check_rot_nibble
		ret

maze_clear	ld hl,maze_data
		ld de,maze_data+1
		ld bc,#00ff
		ld (hl),#00
		ldir
		ret

maze_edges	;; top and bottom edges
		ld hl,maze_data + maze_width
		ld de,maze_height * 16 - 16 + maze_data + maze_width
		ld a,#0f
_maze_edges_1	dec e
		dec l
		ld (hl),a
		ld (de),a
		jr nz,_maze_edges_1
		;; left and right edges
		ld c,a
		inc a
		ld b,maze_height-2
_maze_edges_2	ld l,a
		ld (hl),c
		add a,maze_width-1
		ld l,a
		ld (hl),c
		add a,16-maze_width+1
		djnz _maze_edges_2
		ret

;; rotate lower nibble of L right (ie bits go 7654-3210 -> 7654-0321)
;; return result in A
rot_nibble_1	ld a,l			;; [1]
		and &f0			;; [2]
		ld c,a			;; [1] store top nibble in c
		ld a,l			;; [1]
		and &0f			;; [2] carry flag will also be cleared
		rra			;; [1] bit 0 goes into carry
		jr nc,_rot_nibble_1_1	;; [2/3]
		set 3,a			;; [2] (or ADD A,4 or OR 4)
_rot_nibble_1_1	or c			;; [1] restore top nibble
		ret			;; [3]
					;; 15/16 nops (including ret)

;; use lookup table to rotate lower nibble of L right
rot_nibble	ld h,rot_nibble_data / 256	;; [2]
		ld l,(hl)			;; [2]
		ret				;; [3]

;; rotate lower nibble of L two places
flip_nibble	ld h,rot_nibble_data / 256	;; [2]
		ld l,(hl)			;; [2]
		ld l,(hl)			;; [2]
		ret				;; [3]

check_rot_nibble
		;; find some clear space to store results
		ld h,rot_nibble_data / 256 + 1
		ld l,0
_check_rot_1	call rot_nibble_1	;; get the result in A
		ld (hl),a		;; store the result
		inc l
		jr nz,_check_rot_1
		ret

;; ----------------------------------------------------------------
;; data
;; ----------------------------------------------------------------

		align &100,&11
maze_data	defs &100,&00

		align &100,&11
rot_nibble_data	defb &00,&08,&01,&09,&02,&0a,&03,&0b,&04,&0c,&05,&0d,&06,&0e,&07,&0f
		defb &10,&18,&11,&19,&12,&1a,&13,&1b,&14,&1c,&15,&1d,&16,&1e,&17,&1f
		defb &20,&28,&21,&29,&22,&2a,&23,&2b,&24,&2c,&25,&2d,&26,&2e,&27,&2f
		defb &30,&38,&31,&39,&32,&3a,&33,&3b,&34,&3c,&35,&3d,&36,&3e,&37,&3f
		defb &40,&48,&41,&49,&42,&4a,&43,&4b,&44,&4c,&45,&4d,&46,&4e,&47,&4f
		defb &50,&58,&51,&59,&52,&5a,&53,&5b,&54,&5c,&55,&5d,&56,&5e,&57,&5f
		defb &60,&68,&61,&69,&62,&6a,&63,&6b,&64,&6c,&65,&6d,&66,&6e,&67,&6f
		defb &70,&78,&71,&79,&72,&7a,&73,&7b,&74,&7c,&75,&7d,&76,&7e,&77,&7f
		defb &80,&88,&81,&89,&82,&8a,&83,&8b,&84,&8c,&85,&8d,&86,&8e,&87,&8f
		defb &90,&98,&91,&99,&92,&9a,&93,&9b,&94,&9c,&95,&9d,&96,&9e,&97,&9f
		defb &a0,&a8,&a1,&a9,&a2,&aa,&a3,&ab,&a4,&ac,&a5,&ad,&a6,&ae,&a7,&af
		defb &b0,&b8,&b1,&b9,&b2,&ba,&b3,&bb,&b4,&bc,&b5,&bd,&b6,&be,&b7,&bf
		defb &c0,&c8,&c1,&c9,&c2,&ca,&c3,&cb,&c4,&cc,&c5,&cd,&c6,&ce,&c7,&cf
		defb &d0,&d8,&d1,&d9,&d2,&da,&d3,&db,&d4,&dc,&d5,&dd,&d6,&de,&d7,&df
		defb &e0,&e8,&e1,&e9,&e2,&ea,&e3,&eb,&e4,&ec,&e5,&ed,&e6,&ee,&e7,&ef
		defb &f0,&f8,&f1,&f9,&f2,&fa,&f3,&fb,&f4,&fc,&f5,&fd,&f6,&fe,&f7,&ff
end
