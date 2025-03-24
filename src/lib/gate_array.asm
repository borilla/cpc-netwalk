macro ga_select_pen pen
		ld bc,#7f00 + %00000000 | pen
		out (c),c
mend

macro ga_select_border
		ld bc,#7f00 + %00010000
		out (c),c
mend

macro ga_select_colour ink
		ld bc,#7f00 + %01000000 | ink
		out (c),c
mend

macro ga_set_pen pen,ink
		ld bc,#7f00 + %00000000 | {pen}
		out (c),c
		ld c,%01000000 | {ink}
		out (c),c
mend

macro ga_set_all_pens ink
		ld bc,#7f00 + %01000000 | {ink}
		ld a,16		;; (pen 16 is border)
@loop		out (c),a	;; select pen
		out (c),c	;; set ink
		dec a
		jp p,@loop
mend

macro ga_select_mode mode	;; this will also disable (upper and lower) rom
		ld bc,#7f00 + %10001100 | {mode}
		out (c),c
mend
