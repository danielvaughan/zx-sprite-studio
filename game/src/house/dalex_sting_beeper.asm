; Dalex Software ident sting, 48K beeper version (original code, z88dk-z80asm syntax).
;
; Same motif and timeline as the 128K AY sting (house-style/sting/ay): the step table in
; dalex_sting_steps.asm is generated frame by frame from the AY reference frames by beeper_build.py.
;
; Two voices from 16-bit phase accumulators in one constant-time loop (zx-beeper-engine technique):
;   voice 1 = the lead (AY channel A), voice 2 = the chord arpeggio (AY channel C) or, on drum frames,
;   noise read from bit 4 of successive ROM bytes (the AY's hat and snare bursts on channel B).
; Volume is a pulse width: the voice's bit is high while the top byte of its phase is below its duty
; byte (127 = square, 0 = silent), so the AY decay instrument becomes a narrowing pulse that fades out.
; Every port $FE write is $00 or $10: speaker bit 4 only, border black, MIC off.
;
; Both loop bodies take 176 T (22 x 8), with the two voices' writes 88 T apart either way, so each voice
; holds the speaker for the same time. Interrupts are off while it plays (about 1.6 s) and restored after.
;
; Call: sting_play.   Returns A = 0 and Z when it played to the end, A = 1 and NZ when a key skipped it.
; Preserves IX, IY and HL' (so a BASIC USR call returns safely); the speaker is left low, the border black.
sting_play:
        ld a,i                  ; P/V = IFF2: were interrupts on?
        jp pe,st_iff_read
        ld a,i                  ; read again: an interrupt accepted during the first LD A,I clears P/V
st_iff_read:                    ; (NMOS Z80 quirk; SkoolKit models it)
        push af
        di
        push ix
        exx
        push hl                 ; HL' belongs to BASIC
        exx
        ld hl,sting_steps
        ld (st_ptr),hl
        ld hl,0                 ; voice 1 phase
        exx
        ld hl,0                 ; voice 2 phase (or ROM noise pointer)
        exx

st_next:                        ; load the next step: loops, inc1, duty1, inc2, duty2 / noise flag
        ld (st_v1),hl
        ld hl,(st_ptr)
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld a,d
        or e
        jp z,st_done            ; loops = 0: end of table
        push de
        pop ix                  ; IX = loop count
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl                  ; DE = voice 1 increment
        ld c,(hl)
        inc hl                  ; C = voice 1 duty
        ld a,(hl)
        inc hl
        exx
        ld e,a
        exx
        ld a,(hl)
        inc hl
        exx
        ld d,a                  ; DE' = voice 2 increment
        exx
        ld a,(hl)
        inc hl
        ld (st_ptr),hl
        ld hl,(st_v1)
        bit 7,a
        jr nz,st_noise
        exx
        ld c,a                  ; C' = voice 2 duty
        exx
        jp loop_t
st_noise:
        and $10
        exx
        ld c,a                  ; C' = $10: noise bit mask
        res 6,h                 ; keep the noise pointer inside the ROM
        res 7,h
        exx
        jp loop_n

; ---- tone step: 176 T per pass
loop_t:
        add hl,de               ; 11  voice 1
        ld a,h                  ;  4
        cp c                    ;  4  carry while H < duty
        sbc a,a                 ;  4
        and $10                 ;  7
        out ($fe),a             ; 11
        xor a                   ;  4  any key (all half-rows)
        in a,($fe)              ; 11
        cpl                     ;  4
        and $1f                 ;  7
        jp nz,st_skip           ; 10
        ld b,0                  ;  7  pad: 88 T from write to write
        exx                     ;  4
        add hl,de               ; 11  voice 2
        ld a,h                  ;  4
        cp c                    ;  4
        sbc a,a                 ;  4
        and $10                 ;  7
        out ($fe),a             ; 11
        exx                     ;  4
        ld b,0                  ;  7  pad
        dec ix                  ; 10
        ld a,ixh                ;  8
        or ixl                  ;  8
        jp nz,loop_t            ; 10
        jp st_next

; ---- drum step: voice 2 is noise, 176 T per pass
loop_n:
        add hl,de               ; 11  voice 1 as above
        ld a,h                  ;  4
        cp c                    ;  4
        sbc a,a                 ;  4
        and $10                 ;  7
        out ($fe),a             ; 11
        xor a                   ;  4
        in a,($fe)              ; 11
        cpl                     ;  4
        and $1f                 ;  7
        jp nz,st_skip           ; 10
        nop                     ;  4  pad (the noise path is 5 T shorter)
        nop                     ;  4
        nop                     ;  4
        exx                     ;  4
        ld a,(hl)               ;  7  voice 2: bit 4 of the next ROM byte
        inc hl                  ;  6
        res 6,h                 ;  8
        and c                   ;  4
        out ($fe),a             ; 11
        exx                     ;  4
        ld b,0                  ;  7
        dec ix                  ; 10
        ld a,ixh                ;  8
        or ixl                  ;  8
        jp nz,loop_n            ; 10
        jp st_next

st_skip:
        ld b,1
        jr st_exit
st_done:
        ld b,0
st_exit:
        xor a
        out ($fe),a             ; speaker low, border black
        exx
        pop hl
        exx
        pop ix
        pop af
        jp po,st_keep_di
        ei
st_keep_di:
        ld a,b
        or a
        ret

st_ptr: defw 0
st_v1:  defw 0

        include "dalex_sting_steps.asm"
