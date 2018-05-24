;; ----------------------------------------------------------------
;; macros
;; ----------------------------------------------------------------

;; read "inc/macros.asm"

;; ----------------------------------------------------------------
;; constants
;; ----------------------------------------------------------------

exits_top_bit		equ 0
exits_right_bit		equ 1
exits_bottom_bit	equ 2
exits_left_bit		equ 3
is_connected_bit	equ 6
is_visited_bit		equ 7

exits_top		equ 1
exits_right		equ 2
exits_bottom		equ 4
exits_left		equ 8
is_connected		equ 64
is_visited		equ 128

;; ----------------------------------------------------------------
;; subroutines
;; ----------------------------------------------------------------

;; generate maze
;; entry:
;;	A: maze dimensions - height*16 + width (%hhhhwwww)
;; modifies:
;;	A,BC.DE,HL
maze_generate	ld (maze_dimensions),a
		call maze_reset			;; clear all maze data
		call modify_index_limits	;; modify max width and height index values in subroutines
		call random_cell		;; choose random starter cell
		ld (maze_start_cell),a
		ld l,a				;; HL points to current cell (starting at starter cell)
		ld h,maze_data / 256
		ld bc,maze_stack		;; BC points to stack of pending cells
_mg_loop_0	set is_connected_bit,(hl)	;; mark current cell as visited
_mg_loop_1	call find_unvisited_neighbours	;; get array of unvisited neighbours (in DE)
		rr e				;; E = count of neighbours
		jr nz,_mg_choose		;; if there are unvisited neighbours then choose one
		inc c				;; otherwise, check if pending stack is empty
		dec c
		ret z				;; if stack is empty then we've finished(!!!!)
		dec c				;; otherwise, pop last cell from stack
		ld a,(bc)
		ld l,a				;; and point HL at that cell
		jr _mg_loop_1			;; cells on stack are already visited so no need to set bit
_mg_choose	dec e				;; E = number of neighbours - 1 (ie max index)
		jr z,_mg_join			;; if only one neighbour then join to that one
		ld a,l				;; otherwise, push current cell onto stack
		ld (bc),a
		inc c
		ld b,c				;; temporarily store value of C (in B)
		call choose_random_index	;; choose random index (0 <= A <= E)
		ld c,b				;; restore value of C
		ld b,maze_stack / 256		;; restore value of B
		add a,a				;; double value of random index
		ld e,a				;; copy (doubled) value into E
_mg_join	;; join current cell to neighbour (from neighbour entry pointed to by DE)
		ld a,(de)			;; read direction of neighbour into A
		or (hl)				;; add exit to current cell
		ld (hl),a
		;; join neighbour to current cell and make neighbour current cell
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

;; set constants for index-limits in "find-neighbour" subroutines
;; entry:
;;	A: maze dimensions - height*16 + width (%hhhhwwww)
;; exit:
;;	A: unmodified
;; modifies:
;;	C
modify_index_limits
		ld c,a
		dec a
		and %00001111
		ld (_fun_right + 3),a
		ld a,c
		sub 16
		and %11110000
		ld (_fun_bottom + 3),a
		ld a,c
		ret

;; zero maze data table
;; modifies:
;;	BC,DE,HL
maze_reset	ld hl,maze_data
		ld (hl),l
		ld de,maze_data+1
		ld bc,&00ff
		ldir
		ret

;; apply random rotation to all maze cells
maze_shuffle	call rand16
		ld hl,maze_data
		ld d,rot_nibble_data / 256
_ms_loop_1
		ld b,a
		add a,a
		add a,a
		add a,b
		inc a
		ld b,a
		and %00000011
		jr z,_ms_loop_end

		ld b,a
		ld e,(hl)
_ms_loop_2
		ld a,(de)
		ld e,a
		djnz _ms_loop_2
		ld (hl),a
_ms_loop_end
		inc l
		jr nz,_ms_loop_1
		ret

;; choose a random cell (within maze limits)
;; entry
;;	A: maze limits (%hhhhwwww)
;; exit
;;	A: index of cell
;; modifies:
;;	A,BC,HL
random_cell	ld b,a
		call rand16		;; A is random number
		ld c,a

		ld a,b			;; get low nibble (x-coord)
		and &0f
		ld h,a
		ld a,c
		jr z,_rc_skip1		;; if width is zero then skip subtraction, return random nibble
		and &0f
		sub h
		jr nc,$-1
		add h
_rc_skip1	and &0f			;; extra AND here is just for skipped case
		ld l,a			;; store x-coord in low nibble of L

		ld a,b			;; get high nibble (y-coord)
		and &f0
		ld h,a
		ld a,c
		jr z,_rc_skip2		;; if height is zero then skip subtraction, return random nibble
		and &f0
		sub h
		jr nc,$-1
		add h
_rc_skip2	and &f0			;; extra AND here is just for skipped case
		or l			;; merge y-coord with x-coord

		ret

;; find unvisited neighbours of a cell
;; entry:
;;	HL: address of current cell in maze_data
;; exit:
;;	HL: unmodified
;;	BC: unmodified
;;	DE: top of maze_neighbours_list (2 bytes each, so E = number of neighbours * 2)
;;	A: index of current cell (same as L)
;; flags:
;;	C: reset
find_unvisited_neighbours
		ld de,maze_neighbours_list
_fun_top	ld a,l			;; A is index of current cell
		and &f0			;; extract row part of index
		ld a,l
		jr z,_fun_right		;; if there is no top neighbour then check right neighbour
		sub a,16		;; point HL at top neighbour
		ld l,a
		bit is_connected_bit,(hl)	;; check if "connected" bit is set
		jr nz,_fun_top_end	;; if bit is not set then check next neighbour
		ex de,hl
		ld (hl),exits_top	;; push direction
		inc l
		ld (hl),a		;; push cell index
		inc l
		ex de,hl
_fun_top_end	add a,16		;; reset to current cell
		ld l,a
_fun_right	and &0f			;; extract column part of index
		cp &0f			;; (maze-width - 1)
		ld a,l
		jr z,_fun_bottom	;; if there is no right neighbour then check bottom neighbour
		inc a			;; point HL at right neighbour
		ld l,a
		bit is_connected_bit,(hl)	;; check if "connected" bit is set
		jr nz,_fun_right_end	;; if bit is not set then check next neighbour
		ex de,hl
		ld (hl),exits_right	;; push direction
		inc l
		ld (hl),a		;; push cell index
		inc l
		ex de,hl
_fun_right_end	dec a			;; reset to current cell
		ld l,a
_fun_bottom	and &f0			;; extract row part of index
		cp &f0			;; (maze-height - 1)
		ld a,l
		jr z,_fun_left		;; if there is no bottom neighbour then check left neighbour
		add a,16		;; point HL at bottom neighbour
		ld l,a
		bit is_connected_bit,(hl)	;; check if "connected" bit is set
		jr nz,_fun_bottom_end	;; if bit is not set then check next neighbour
		ex de,hl
		ld (hl),exits_bottom	;; push direction
		inc l
		ld (hl),a		;; push cell index
		inc l
		ex de,hl
_fun_bottom_end	sub a,16		;; reset to current cell
		ld l,a
_fun_left	and &0f			;; extract column part of index
		ld a,l
		ret z			;; if there is no left neighbour then return
		dec a			;; point HL at left neighbour
		ld l,a
		bit is_connected_bit,(hl)	;; check if "connected" bit is set
		jr nz,_fun_left_end	;; if bit is not set then check next neighbour
		ex de,hl
		ld (hl),exits_left	;; push direction
		inc l
		ld (hl),a		;; push cell index
		inc l
		ex de,hl
_fun_left_end	inc a			;; reset A to current cell (will also clear carry before ret)
		ld l,a			;; restore HL to original cell
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
;;	Z: modified
choose_random_index
		;; A = random number
		ld a,0			;; 0 is initial seed value, which will be overwritten each call
		ld c,a
		add a,a
		add a,a
		add a,c
		inc a			;; another possibility is ADD A,7
		ld (choose_random_index+1),a
		;; A = A mod (E + 1)
		ld c,a			;; copy random number into C
		ld a,e			;; copy max index to A
		cp 2			;; if max index is 2 (ie three options)
		jr z,mod_3		;; then get C mod 3
		and c			;; otherwise (max index is 1 or 3)
		ret			;; return random AND max-index

;; https://www.cemetech.net/forum/viewtopic.php?t=12784
;; entry:
;;	C: unsigned integer
;; exit:
;;	A: C mod 3
;; 	C: modified
;; flags:
;;	C: modified
;;	Z: set if divisible by 3
mod_3		ld a,c			;; add nibbles
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

;; find all cells connected to initial cell
;; after this call, all connected cells will have "connected" bit set
;; entry:
;;	A: index of initial cell
;; exit:
;;	DE: top of stack of (indexes of) connected cells
connected_cells
		ld de,maze_stack	;; DE points at top of stack
		ld (de),a		;; add initial stack item
		ld iyl,e		;; IXL is index of current item in stack

		ld h,maze_data / 256	;; HL points at current cell in maze-data
		ld l,a
		set is_connected_bit,(hl)	;; mark initial cell as connected
		ld b,h			;; BC is used to point at neighbours in maze-data
_cc_loop
		ld c,e			;; temporarily store E
		ld e,iyl		;; DE points at current stack item
		ld a,(de)		;; A is index of current cell
		ld e,c			;; restore E

		ld l,a			;; HL points at current item
		ld a,(hl)		;; A contains current cell data
		and %00110000		;; if cell is currently rotating then can't be connected to neighbours
		jr nz,_cc_end

_cc_top		bit exits_top_bit,(hl)	;; is cell connected to neighbour?
		jr z,_cc_right
		ld a,l
		and %11110000
		jr z,_cc_right
		ld a,l			;; point BC at neighbour
		sub 16
		ld c,a
		ld a,(bc)		;; is neighbour unvisted, not rotating, and connected to this cell?
		and is_connected + %00110000 + exits_bottom
		cp exits_bottom
		jr nz,_cc_right
		ld a,(bc)		;; mark neighbour as "connected"
		or is_connected
		ld (bc),a
		inc e			;; push (index of) neighbour onto stack
		ld a,c
		ld (de),a

_cc_right	bit exits_right_bit,(hl)	;; is cell connected to neighbour?
		jr z,_cc_bottom
		ld a,l
		and %00001111
		cp %00001111		;; maze-width - 1
		jr z,_cc_bottom
		ld a,l			;; point BC at neighbour
		inc a
		ld c,a
		ld a,(bc)		;; is neighbour unvisted, not rotating, and connected to this cell?
		and is_connected + %00110000 + exits_left
		cp exits_left
		jr nz,_cc_bottom
		ld a,(bc)		;; mark neighbour as "connected"
		or is_connected
		ld (bc),a
		inc e			;; push (index of) neighbour onto stack
		ld a,c
		ld (de),a

_cc_bottom	bit exits_bottom_bit,(hl)	;; is cell connected to neighbour?
		jr z,_cc_left
		ld a,l
		and %11110000
		cp %11110000
		jr z,_cc_left
		ld a,l			;; point BC at neighbour
		add 16
		ld c,a
		ld a,(bc)		;; is neighbour unvisted, not rotating, and connected to this cell?
		and is_connected + %00110000 + exits_top
		cp exits_top
		jr nz,_cc_left
		ld a,(bc)		;; mark neighbour as "connected"
		or is_connected
		ld (bc),a
		inc e			;; push (index of) neighbour onto stack
		ld a,c
		ld (de),a

_cc_left	bit exits_left_bit,(hl)	;; is cell connected to neighbour?
		jr z,_cc_end
		ld a,l
		and %00001111
		jr z,_cc_end
		ld a,l			;; point BC at neighbour
		dec a
		ld c,a
		ld a,(bc)		;; is neighbour unvisted, not rotating, and connected to this cell?
		and is_connected + %00110000 + exits_right
		cp exits_right
		jr nz,_cc_end
		ld a,(bc)		;; mark neighbour as "connected"
		or is_connected
		ld (bc),a
		inc e			;; push (index of) neighbour onto stack
		ld a,c
		ld (de),a

_cc_end		ld a,iyl		;; is current item same as top item on stack?
		cp e
		ret z

		inc iyl			;; go to next stack item
		jp _cc_loop

;; ----------------------------------------------------------------
;; data
;; ----------------------------------------------------------------

		align &100

maze_data	defs &100,&00

maze_stack	defs &100,&00

rot_nibble_data	defb &00,&02,&04,&06,&08,&0a,&0c,&0e,&01,&03,&05,&07,&09,&0b,&0d,&0f
		defb &10,&12,&14,&16,&18,&1a,&1c,&1e,&11,&13,&15,&17,&19,&1b,&1d,&1f
		defb &20,&22,&24,&26,&28,&2a,&2c,&2e,&21,&23,&25,&27,&29,&2b,&2d,&2f
		defb &30,&32,&34,&36,&38,&3a,&3c,&3e,&31,&33,&35,&37,&39,&3b,&3d,&3f
		defb &40,&42,&44,&46,&48,&4a,&4c,&4e,&41,&43,&45,&47,&49,&4b,&4d,&4f
		defb &50,&52,&54,&56,&58,&5a,&5c,&5e,&51,&53,&55,&57,&59,&5b,&5d,&5f
		defb &60,&62,&64,&66,&68,&6a,&6c,&6e,&61,&63,&65,&67,&69,&6b,&6d,&6f
		defb &70,&72,&74,&76,&78,&7a,&7c,&7e,&71,&73,&75,&77,&79,&7b,&7d,&7f
		defb &80,&82,&84,&86,&88,&8a,&8c,&8e,&81,&83,&85,&87,&89,&8b,&8d,&8f
		defb &90,&92,&94,&96,&98,&9a,&9c,&9e,&91,&93,&95,&97,&99,&9b,&9d,&9f
		defb &a0,&a2,&a4,&a6,&a8,&aa,&ac,&ae,&a1,&a3,&a5,&a7,&a9,&ab,&ad,&af
		defb &b0,&b2,&b4,&b6,&b8,&ba,&bc,&be,&b1,&b3,&b5,&b7,&b9,&bb,&bd,&bf
		defb &c0,&c2,&c4,&c6,&c8,&ca,&cc,&ce,&c1,&c3,&c5,&c7,&c9,&cb,&cd,&cf
		defb &d0,&d2,&d4,&d6,&d8,&da,&dc,&de,&d1,&d3,&d5,&d7,&d9,&db,&dd,&df
		defb &e0,&e2,&e4,&e6,&e8,&ea,&ec,&ee,&e1,&e3,&e5,&e7,&e9,&eb,&ed,&ef
		defb &f0,&f2,&f4,&f6,&f8,&fa,&fc,&fe,&f1,&f3,&f5,&f7,&f9,&fb,&fd,&ff

maze_neighbours_list
		defs 4*2,&00

maze_dimensions	defb 0
maze_start_cell	defb 0

maze_end
