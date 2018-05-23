;; http://www.cpcwiki.eu/index.php/Programming:Random_Number_Generator#16-bit_random_number_generator
;; exit:
;;	A: a pseudo random number, period 65536
;; modifies
;;	A,DE,HL
rand16	ld	de,0		;; [3] ld de,seed
	ld	a,d		;; [1]
	ld	h,e		;; [1]
	ld	l,253		;; [2]
	or	a		;; [1]
	sbc	hl,de		;; [4]
	sbc	a,0		;; [2]
	sbc	hl,de		;; [4]
	ld	d,0		;; [2]
	sbc	a,d		;; [1]
	ld	e,a		;; [1]
	sbc	hl,de		;; [4]
	jr	nc,$+3		;; [2/3]
	inc	hl		;; [2]
	ld	(rand16+1),hl	;; [5] update seed
	ret			;; [3]

				;; [37/38]
