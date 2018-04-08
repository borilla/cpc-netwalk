;; ----------------------------------------------------------------
;; macros
;; ----------------------------------------------------------------

read "inc/macros.asm"

;; ----------------------------------------------------------------
;; constants
;; ----------------------------------------------------------------

exits_top	equ 1
exits_right	equ 2
exits_bottom	equ 4
exits_left	equ 8
exits_all	equ 15
room_visited	equ 16

;; ----------------------------------------------------------------
;; subroutines
;; ----------------------------------------------------------------

;; generate maze. Before calling this, set 
;; modifies:
;;	A,BC.DE,HL
maze_generate	call maze_reset
		call maze_edges
		ld hl,maze_data			;; HL points to current room (starting at top-left)
		ld bc,maze_stack		;; BC points to stack of pending rooms
_mg_loop_0	set 4,(hl)			;; mark current room as visited
_mg_loop_1	call find_unvisited_neighbours	;; get array of unvisited neighbours (in DE)
		rr e				;; E = count of neighbours
		jr nz,_mg_choose		;; if there are unvisited neighbours then choose one
		inc c				;; otherwise, check if pending stack is empty
		dec c
		ret z				;; if stack is empty then we've finished(!!!!)
		dec c				;; otherwise, pop last room from stack
		ld a,(bc)
		ld l,a				;; and put it into HL
		jr _mg_loop_1			;; rooms on stack are already visited so go to next instruction
_mg_choose	dec e				;; E = number of neighbours - 1 (ie max index)
		jr z,_mg_join			;; if only one neighbour then join to that one
		ld a,l				;; otherwise, push current room onto stack
		ld (bc),a
		inc c
		push bc
		call choose_random_index	;; choose random index (0 <= A <= E)
		pop bc
		add a,a				;; double value of random index
		ld e,a				;; copy (doubled) value into E
_mg_join	;; join current room to neighbour (from neighbour entry pointed to by DE)
		ld a,(de)			;; read direction of neighbour into A
		or (hl)				;; add exit to current room
		ld (hl),a
		;; join neighbour to current room and make neighbour current room
		ld h,rot_nibble_data / 256	;; get opposite of neighbour direction
		ld a,(de)			;; point HL at entry in rotation table
		ld l,a
		ld l,(hl)			;; rotate once
		ld h,(hl)			;; rotate twice, keeping result in H for now
		inc e				;; read index of neighbour
		ld a,(de)
		ld l,a				;; put index into L
		ld a,h				;; put opposite direction into A
		ld h,maze_data / 256		;; HL now points at neighbour
		or (hl)				;; add exit to neighbour
		ld (hl),a
		jr _mg_loop_0			;; and loop again

;; zero maze data table
;; exit:
;;	BC: &0000
;;	DE: maze_data + &ff
;;	HL: maze_data + &fe
maze_reset	ld hl,maze_data
		ld de,maze_data+1
		ld bc,&00ff
		ld (hl),b			;; ld (hl),0
		ldir
		ret

;; mark rooms to right and bottom of maze as "visited"
;; modifies:
;;	A,BC,D,HL
maze_edges	ld hl,maze_data
		ld c,exits_all + room_visited
		ld d,16
		;; if maze width is less than 16 then mark right edge
maze_width equ $+1
		ld a,16			;; default maze width is 16. value will be overwritten!
		and 15
		jr z,_me_bottom
		ld b,d
_me_right_loop	ld l,a
		ld (hl),c
		add a,d
		djnz _me_right_loop
_me_bottom	;; if maze height is less than 16 then mark bottom edge
maze_height equ $+1
		ld a,16			;; default maze height is 16. value will be overwritten!
		and 15
		ret z
		rlca:rlca:rlca:rlca	;; multiply A by 16
		ld l,a
		ld b,d
_me_bottom_loop	ld (hl),c
		inc l
		djnz _me_bottom_loop
		ret

;; find unvisited neighbours of a room
;; entry:
;;	HL: address of current room in maze_data
;; exit:
;;	HL: address of current room in maze data (not modified)
;;	DE: top of neighbours_list (2 bytes each so E = number of neighbours * 2)
;;	A: index of current room (same as L)
;; flags:
;;	C: reset
find_unvisited_neighbours
		ld de,neighbours_list
_fun_top	ld a,l			;; A is index of current room
		and &f0			;; extract row part of index
		ld a,l
		jr z,_fun_right		;; if there is no top neighbour then check right neighbour
		sub a,16		;; point HL at top neighbour
		ld l,a
		bit 4,(hl)		;; check if "visited" bit is set
		jr nz,_fun_top_end	;; if bit is not set then check next neighbour
		ex de,hl
		ld (hl),exits_top	;; push direction
		inc l
		ld (hl),a		;; push room index
		inc l
		ex de,hl
_fun_top_end	add a,16		;; reset to current room
		ld l,a
_fun_right	and &0f			;; extract column part of index
		cp &0f
		ld a,l
		jr z,_fun_bottom	;; if there is no right neighbour then check bottom neighbour
		inc a			;; point HL at right neighbour
		ld l,a
		bit 4,(hl)		;; check if "visited" bit is set
		jr nz,_fun_right_end	;; if bit is not set then check next neighbour
		ex de,hl
		ld (hl),exits_right	;; push direction
		inc l
		ld (hl),a		;; push room index
		inc l
		ex de,hl
_fun_right_end	dec a			;; reset to current room
		ld l,a
_fun_bottom	and &f0			;; extract row part of index
		cp &f0
		ld a,l
		jr z,_fun_left		;; if there is no bottom neighbour then check left neighbour
		add a,16		;; point HL at bottom neighbour
		ld l,a
		bit 4,(hl)		;; check if "visited" bit is set
		jr nz,_fun_bottom_end	;; if bit is not set then check next neighbour
		ex de,hl
		ld (hl),exits_bottom	;; push direction
		inc l
		ld (hl),a		;; push room index
		inc l
		ex de,hl
_fun_bottom_end	sub a,16		;; reset to current room
		ld l,a
_fun_left	and &0f			;; extract column part of index
		ld a,l
		ret z			;; if there is no left neighbour then return
		dec a			;; point HL at left neighbour
		ld l,a
		bit 4,(hl)		;; check if "visited" bit is set
		jr nz,_fun_left_end	;; if bit is not set then check next neighbour
		ex de,hl
		ld (hl),exits_left	;; push direction
		inc l
		ld (hl),a		;; push room index
		inc l
		ex de,hl
_fun_left_end	inc a			;; reset A to current room (will also clear carry before ret)
		ld l,a			;; restore HL to original room
_fun_ret	ret

;; get a random number between 0 and E
;; entry:
;;	E: max index to return (1 <= E <= 3)
;; exit:
;;	A: random number between 0 and max index (0 <= A <= E)
;;	C: modified
;;	E: unmodified
;; flags:
;;	C: modified
choose_random_index
		call get_random		;; NOTE: could inline this(?)
		ld c,a			;; copy random number into C
		ld a,e			;; copy max index to A
		cp 2			;; if max index is 2 (ie three options)
		jr z,mod_3		;; then get C mod 3
		and c			;; otherwise (max index is 1 or 3)
		ret			;; return random AND max-index

;; get a random number (1 byte - 0..255)
;; exit:
;;	A: the random number
get_random	ld a,(_random_seed)
		rrca			;; multiply by 32
		rrca
		rrca
		xor &1f
_random_seed equ $+1
		add a,0			;; 0 will be replaced with seed
		sbc a,&ff		;; carry
		ld (_random_seed),a
		ret

;; https://www.cemetech.net/forum/viewtopic.php?t=12784
;; entry:
;;	C: unsigned integer
;; exit:
;;	A: C mod 3
;; 	C: modified
;; flags:
;;	Z: set if divisible by 3
;;	C: modified
mod_3:		ld a,c			;; add nibbles
		rrca:rrca:rrca:rrca
		add a,c
		adc a,0			;; n mod 15 (+1) in both nibbles
		ld c,a			;; add half nibbles
		rrca:rrca
		add a,c
		adc a,1
		ret z
		and 3
		dec a
		ret

;; ----------------------------------------------------------------
;; data
;; ----------------------------------------------------------------

		align &100,&11
maze_data	defs &100,&00

maze_stack	defs &100,&00

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

neighbours_list	defs 4*2,&00
end
