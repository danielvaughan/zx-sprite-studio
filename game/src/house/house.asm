; Dalex Software house style for zx-game games (original code, sjasmplus).
; Owner decision 2026-10-19: lockup A for every game. The files beside this one are copies
; recorded with their sha256 in SOURCE.json (logo bytes from zx-assets house/dalex, where they are
; sha-locked; the sting from house-style/sting; the zx-assets pattern player); never edit or
; regenerate them per game. The template carries this folder as src/house/: INCLUDE
; "house/house.asm" once, in resident memory below $C000.
;
; Always assembled:
;   house_footer   A = high byte of the screen to stamp ($40: the screen at $4000; $C0: a shadow
;                  screen paged at $C000). Writes footer-row.bin into character row 23: its 8
;                  bitmap lines, then its 32 attributes (the mark, then (C) 2026 DALEX SOFTWARE).
;                  Uses AF, BC, DE, HL.
;   house_txt_*    the standard wording (house-style README section 5), zero-terminated:
;                  music on/off (the ON form padded to 13 characters so each overwrites the
;                  other), PRESS SPACE, the pause card lines.
;
; With the boot ident switched on in the game source (before the INCLUDE):
;     DEFINE ZXG_IDENT
;     DEFINE ZXG_STING 1      ; 1 AY (128K), 2 beeper (48K), 0 silent
;   house_ident    the boot ident, once per power-on before the title. In: A = 0 for a silent
;                  ident (the game already stores MUSIC OFF), else the sting plays. Clears the
;                  screen at $4000 (bitmap 0, attributes $47, border 0), stamps ident-core at
;                  row 3, col 8, plays the sting (ZXG_STING 1: AY, ayp_init + ayp_play each
;                  frame; 2: beeper, blocking with interrupts off, about 80 frames; 0: none),
;                  holds the picture to IDENT_HOLD_FRAMES frames or until any key, then
;                  silences the AY (ay_reset), waits until no key is held and returns. Needs
;                  interrupts on (it HALTs once per frame) and screen bank 5 shown. The game's
;                  ISR must not drive the AY meanwhile (the templates' sound tick returns while
;                  HARNESS_state is ST_IDENT). Uses AF, AF', BC, DE, HL, IX.
;   AY sting: a game that already has the zx-assets pattern player resident puts
;                  DEFINE HOUSE_HAVE_AYPAT before INCLUDE "house.asm"; otherwise this file
;                  includes aypat.asm and aypat_tables.asm (copies) with a stub sfx_active.

IDENT_HOLD_FRAMES      equ 100         ; at most 2 s of picture (the sting lasts 80 frames)

house_footer:
        push af
        or $10                  ; row 23 = character row 7 of the bottom third
        ld d,a
        ld e,$e0
        ld hl,house_footer_row
        ld a,8
.line:  push de
        ld bc,32
        ldir
        pop de
        inc d
        dec a
        jr nz,.line
        pop af
        add a,$1a               ; attributes of row 23: base + $1AE0
        ld d,a
        ld e,$e0
        ld bc,32
        ldir
        ret

house_footer_row:       INCBIN "footer-row.bin"         ; 256 bitmap bytes, then 32 attributes

house_txt_music_on:     db "MUSIC ON (M) ",0
house_txt_music_off:    db "MUSIC OFF (M)",0
house_txt_press:        db "PRESS SPACE",0
house_txt_paused:       db "PAUSED",0
house_txt_resume:       db "H: RESUME",0
house_txt_restart:      db "R: RESTART",0

        IFDEF ZXG_IDENT
house_ident:
        ld (house_sound),a
        xor a
        out ($fe),a             ; BORDER 0
        ld hl,$4000
        ld de,$4001
        ld bc,6143
        ld (hl),a
        ldir
        ld hl,$5800
        ld de,$5801
        ld bc,767
        ld (hl),$47             ; BRIGHT white on black
        ldir
        ld hl,house_ident_core  ; 17 x 8 pixel lines of 15 bytes from pixel row 24, column 8
        ld a,24
.px:    push af
        call house_line_addr
        ld a,e
        add a,8
        ld e,a
        ld bc,15
        ldir
        pop af
        inc a
        cp 24+17*8
        jr nz,.px
        ld de,$5800+3*32+8      ; then the 17 x 15 attributes
        ld a,17
.at:    ld bc,15
        ldir
        ex de,hl
        ld bc,32-15
        add hl,bc
        ex de,hl
        dec a
        jr nz,.at
        IF ZXG_STING=2
        ld a,(house_sound)
        or a
        jr z,.quiet
        call house_beeper.sting_play    ; NZ: a key skipped it
        jr nz,.exit
        ld b,IDENT_HOLD_FRAMES-80
        jr .hold
.quiet:
        ENDIF
        IF ZXG_STING=1
        ld a,(house_sound)
        or a
        jr z,.quiet
        ld hl,dalex_sting_song
        call ayp_init
.quiet:
        ENDIF
        ld b,IDENT_HOLD_FRAMES
.hold:  halt
        IF ZXG_STING=1
        ld a,(house_sound)
        or a
        jr z,.key
        push bc
        call ayp_play
        pop bc
.key:
        ENDIF
        xor a                   ; any key: all half-rows
        in a,($fe)
        cpl
        and $1f
        jr nz,.exit
        djnz .hold
.exit:
        IF ZXG_STING=1
        call ay_reset           ; silence the AY before the title's own sound starts
        ENDIF
.release:
        halt                    ; the press that skipped must not reach the title
        xor a
        in a,($fe)
        cpl
        and $1f
        jr nz,.release
        ret

; A = pixel row (0-191) -> DE = screen address of column 0 at $4000. Corrupts A.
house_line_addr:
        ld e,a
        and 7
        or $40
        ld d,a
        ld a,e
        rra
        rra
        rra
        and $18
        or d
        ld d,a
        ld a,e
        rla
        rla
        and $e0
        ld e,a
        ret

house_ident_core:       INCBIN "ident-core.bin"         ; 15 x 17 cells: 2,040 bitmap + 255 attributes
house_sound:            db 0

        IF ZXG_STING=1
        IFNDEF HOUSE_HAVE_AYPAT
sfx_active:     db 0            ; no effects player in this build: channel C belongs to the music
sfx_mixer:      db %00100100
        INCLUDE "aypat.asm"
        INCLUDE "aypat_tables.asm"
        ENDIF
        INCLUDE "dalex_sting.asm"
        ENDIF
        IF ZXG_STING=2
        MODULE house_beeper     ; the beeper sting's labels stay out of the game's namespace
        INCLUDE "dalex_sting_beeper.asm"
        ENDMODULE
        ENDIF
        ENDIF
