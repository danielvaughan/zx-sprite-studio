; zx-assets AY shared state (original code). Included by ayplay.asm and aypat.asm, and safe to include more
; than once: the guard defines ay_shadow (the 13-byte copy of AY registers 0-12 that sfxplay.asm restores
; channel C from) and ay_reset exactly once. Works with sjasmplus and z88dk-z80asm.
;
; ay_reset: write all 14 sound registers (tones 0, noise 0, mixer all off with AY_MIXER_PORTS, volumes 0,
; envelope period and shape 0) and set ay_shadow to match, so the players' write-only-what-changed path
; starts from what the chip really holds. ayp_init calls it; a game that plays only effects (sfxplay.asm)
; should call it once at boot. An emulator, replica or warm-started program need not leave the AY at 0.
; ay_shadow starts with ay_reset's values (mixer all off), never an all-on mixer of zeros.
; Uses AF, BC, HL.
        IFNDEF AYCOMMON_INCLUDED
        DEFINE AYCOMMON_INCLUDED
AY_MIXER_PORTS equ 64           ; R7 bits 6-7: I/O port A output, as the 128K ROM sets it (RS232/keypad)
ay_shadow: defb 0,0,0,0,0,0,0,$3f + AY_MIXER_PORTS,0,0,0,0,0   ; = ay_reset's values, so a game that
                                ; forgets ay_reset never merges an effect into an all-on mixer
ay_reset:
        ld hl,ay_shadow
        xor a                   ; A = register
ay_rs1: ld bc,$fffd
        out (c),a
        ld b,$bf
        ld (hl),0
        cp 7
        jr nz,ay_rs2
        ld (hl),$3f + AY_MIXER_PORTS
ay_rs2: push af
        ld a,(hl)
        out (c),a
        pop af
        inc hl
        inc a
        cp 13
        jr c,ay_rs1
        ld b,$ff                ; R13 envelope shape = 0 (volumes are 0 and never use the envelope)
        out (c),a
        ld b,$bf
        xor a
        out (c),a
        ret
        ENDIF
