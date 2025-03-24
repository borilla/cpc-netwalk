;; scan all keyboard lines and store results
;; see http://www.cpcwiki.eu/index.php/Programming:Keyboard_scanning
;; and http://www.cpcwiki.eu/index.php/8255
scan_keyboard	ld hl,scan_keyboard_lines
		ld bc,#f782
		out (c),c
		ld bc,#f40e
		ld e,b
		out (c),c
		ld bc,#f6c0
		ld d,b
		out (c),c
		ld c,0
		out (c),c
		ld bc,#f792
		out (c),c
		ld a,#40
		ld c,#4a
scan_keyboard_1	ld b,d
		out (c),a
		ld b,e
		ini
		inc a
		cp c
		jr c,scan_keyboard_1
		ld bc,#f782
		out (c),c
		ret

scan_keyboard_lines
		defs 10,#ff
