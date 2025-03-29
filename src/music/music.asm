music_state_stopped	equ %00
music_state_starting	equ %01
music_state_stopping	equ %10
music_state_playing	equ %11

; current music state
music_state		db music_state_stopped

; toggle playing state of music for next call to music_play
; stopped -> starting	%00 -> %01
; starting -> stopped	%01 -> %00
; stopping -> playing	%10 -> %11
; playing -> stopping	%11 -> %10
music_toggle
		ld a,(music_state)	; we actually simply need to toggle bit 0 of music_state - see above table
		xor 1
		ld (music_state),a
		ret

; call appropriate subroutine of music player [This needs to be called every screen frame!]
music_play
		ld a,(music_state)
		or a
		ret z
		cp music_state_playing
		jr z,.playing
		cp music_state_stopping
		jr z,.stopping
.starting
		ld a,music_state_playing
		ld (music_state),a
		ld hl,.initialise	; (a bit funky because we have to leave hl intact for PLY_AKG_Init subroutine!)
		jr .call_subroutine
.stopping
		xor a				
		ld (music_state),a
		ld hl,PLY_AKG_Stop
		jr .call_subroutine
.playing
		ld hl,PLY_AKG_Play
		; fall through to .call_subroutine
.call_subroutine
		ex af,af'		; player subroutines may modify alt registers so push them to stack before calling
		exx
		push af,bc,de,hl,ix,iy
		exx
		ex af,af'
		call jump_to_hl		; call the subroutine pointed to by hl
		ex af,af'
		exx
		pop iy,ix,hl,de,bc,af
		exx
		ex af,af'
		ret
.initialise
		ld hl,lop_ears_track	; address of the music track
		xor a			; song to play (0)
		jp PLY_AKG_Init		; call init subroutine of the player

lop_ears_track
include "music/lop_ears_track.asm"
include "music/lop_ears_playerconfig.asm"
include "lib/PlayerAkg.asm"
