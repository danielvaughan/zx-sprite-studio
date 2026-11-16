; zx-assets AY pattern player (original code for the zx-assets plugin)
;
; Plays songs written by aypattern.py: a header (speed, loop position, pattern table), an order list
; of 3 pattern numbers per position ($FF ends it) and 16-row pattern streams per channel. Channel A
; is the lead (delayed vibrato), B the bass (drum bursts mix noise in for one frame), C the chord
; arpeggio (ornaments). Volumes come from instrument envelopes. Tables: aypat_tables.asm (generated).
;
; ayp_init: HL = song; resets the AY (ay_reset in aycommon.asm: all 14 registers written, ay_shadow
; seeded) and the vibrato to the defaults (AYP_VIB_DEPTH, AYP_VIB_DELAY; a song's $F0 command overrides
; them). Every channel pointer is set to a real table entry (ornament 0, instrument 0): the player never
; reads through a zero pointer, which on a Spectrum reads the ROM; ayp_play returns at once until ayp_init.
; ayp_play: call once per frame (from the IM2 interrupt); tempo, vibrato and envelopes count
; interrupts, so 50 Hz is the intended rate. Only registers that changed are written, holding channel C
; while a sound effect owns it (sfxplay.asm, which restores C from ay_shadow).
; Uses AF, AF', BC, DE, HL, IX: an interrupt handler calling ayp_play must save AF' too.
;
; Song position for the game: ayp_order (a word) holds the address of the current order-list entry, 3 bytes
; per bar, so during bar k (1-based) it equals <song>_order + 3*(k-1); it moves at the first frame of each
; bar and goes back to the loop position after the last bar. Compare it with the equates aypattern.py
; --marker NAME=FIRST-LAST writes (<SONG>_<NAME>_START / _END): a section plays while START <= (ayp_order)
; <= END. Read it with interrupts off or from the ISR. verify_ay_player.py checks it frame by frame.

AYP_NOTE   equ 3
AYP_INST   equ 4
AYP_ORN    equ 5
AYP_DRUM   equ 7
AYP_ENV    equ 8
AYP_ORNPOS equ 9
AYP_VIBCNT equ 10
AYP_OLEN   equ 11
AYP_ENVP   equ 12
AYP_ORNP   equ 14
AYP_SIZE   equ 16

ayp_init:
        push hl
        call ay_reset
        pop hl
        ld a,AYP_VIB_DEPTH
        ld (ayp_vdepth),a
        ld a,AYP_VIB_DELAY
        ld (ayp_vdelay),a
        ld a,(hl)
        ld (ayp_speed),a
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld (ayp_loop),de
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld (ayp_pats),de
        ld (ayp_order),hl
        ld hl,ayp_ch            ; clear all channel state, then mark no note and no drum
        ld b,3 * AYP_SIZE
ayp_clr:
        ld (hl),0
        inc hl
        djnz ayp_clr
        ld ix,ayp_ch
        ld b,3
ayp_cl2:
        ld (ix+AYP_NOTE),$ff
        ld (ix+AYP_DRUM),$ff
        ld de,(ayp_orns)        ; ornament 0 ("none", aypattern.py guarantees 1,0) until a song sets one:
        ld (ix+AYP_ORNP),e      ; a zero pointer reads the ROM at $0001 ($AF) as a note offset, the note
        ld (ix+AYP_ORNP+1),d    ; clamps to 95 and A/B whine (0.11.0 bug, hidden by an all-zero simulator)
        ld a,(de)
        ld (ix+AYP_OLEN),a
        ld de,(ayp_envs)        ; instrument 0 until a song sets one: never a volume read from the ROM
        ld (ix+AYP_ENVP),e
        ld (ix+AYP_ENVP+1),d
        ld de,AYP_SIZE
        add ix,de
        djnz ayp_cl2
        xor a
        ld (ayp_tick),a
        ld (ayp_row),a
        jp ayp_load

; load the three patterns of the current order position (wrapping to the loop position at $FF)
ayp_load:
        ld hl,(ayp_order)
        ld a,(hl)
        cp $ff
        jr nz,ayp_ld
        ld hl,(ayp_loop)
        ld (ayp_order),hl
ayp_ld: ld ix,ayp_ch
        ld b,3
ayp_ldc:
        push bc
        ld a,(hl)               ; pattern number
        inc hl
        push hl
        ld l,a
        ld h,0
        add hl,hl
        ld de,(ayp_pats)
        add hl,de
        ld a,(hl)
        ld (ix+0),a
        inc hl
        ld a,(hl)
        ld (ix+1),a
        ld (ix+2),0             ; wait
        ld de,AYP_SIZE
        add ix,de
        pop hl
        pop bc
        djnz ayp_ldc
        ret

ayp_play:
        ld a,(ayp_speed)        ; not initialised (speed 0): the pattern pointers are still zero and
        or a                    ; would parse the ROM as a song, so play nothing until ayp_init
        ret z
        ld a,(ayp_tick)
        or a
        jr nz,ayp_synth
        ld a,(ayp_row)          ; a new row
        cp 16
        jr nz,ayp_rows
        ld hl,(ayp_order)       ; next order position
        ld de,3
        add hl,de
        ld (ayp_order),hl
        call ayp_load
        xor a
        ld (ayp_row),a
ayp_rows:
        ld ix,ayp_ch
        call ayp_parse
        ld ix,ayp_ch + AYP_SIZE
        call ayp_parse
        ld ix,ayp_ch + 2 * AYP_SIZE
        call ayp_parse
        ld hl,ayp_row
        inc (hl)
ayp_synth:
        ld hl,0                 ; clear the register image (mixer: everything off)
        ld (ayp_out),hl
        ld (ayp_out+2),hl
        ld (ayp_out+4),hl
        ld (ayp_out+8),hl
        ld (ayp_out+10),hl
        ld (ayp_out+12),hl
        ld hl,($3f + AY_MIXER_PORTS) * 256 ; R6 = 0, R7 = all off + port bits
        ld (ayp_out+6),hl
        ld ix,ayp_ch
        ld c,0
        call ayp_voice
        ld ix,ayp_ch + AYP_SIZE
        ld c,1
        call ayp_voice
        ld ix,ayp_ch + 2 * AYP_SIZE
        ld c,2
        call ayp_voice
        ld a,(sfx_active)
        or a
        jr nz,ayp_slow
        ld hl,ayp_out           ; fast path: write changed registers 0-12 directly
        ld de,ay_shadow
        xor a
ayp_fw: ex af,af'               ; A' = register
        ld a,(de)
        cp (hl)
        jr z,ayp_fs
        ld a,(hl)
        ld (de),a               ; shadow = value
        ex af,af'               ; A = register, A' = value
        ld bc,$fffd
        out (c),a
        ex af,af'
        ld b,$bf
        out (c),a
ayp_fs: ex af,af'               ; A = register
        inc hl
        inc de
        inc a
        cp 13
        jr c,ayp_fw
        jr ayp_wd
ayp_slow:
        ld hl,ayp_out           ; an effect owns channel C: hold 4, 5, 6, 10; merge the mixer
        ld de,ay_shadow
        xor a
ayp_sw: ex af,af'               ; A' = register
        ld a,(de)
        cp (hl)
        jr z,ayp_ss
        ld a,(hl)
        ld (de),a               ; shadow = value (restored by sfxplay when the effect ends)
        ex af,af'               ; A = register, A' = value
        cp 4
        jr z,ayp_sn
        cp 5
        jr z,ayp_sn
        cp 6
        jr z,ayp_sn
        cp 10
        jr z,ayp_sn
        ld bc,$fffd
        out (c),a
        cp 7
        jr z,ayp_mix
        ex af,af'               ; A = value
        ld b,$bf
        out (c),a
        ex af,af'               ; A = register
        jr ayp_sn
ayp_mix:
        ex af,af'               ; A = value: music's A/B bits, the effect's C bits
        and %11011011
        ld b,a
        ld a,(sfx_mixer)
        or b
        ld b,$bf
        out (c),a
        ld a,7
        jr ayp_sn
ayp_ss: ex af,af'               ; A = register
ayp_sn: inc hl
        inc de
        inc a
        cp 13
        jr c,ayp_sw
ayp_wd: ld a,(ayp_speed)        ; tick = (tick + 1) mod speed
        ld b,a
        ld a,(ayp_tick)
        inc a
        cp b
        jr c,ayp_tk
        xor a
ayp_tk: ld (ayp_tick),a
        ret

; read one row of the pattern for the channel at IX
ayp_parse:
        ld (ix+AYP_DRUM),$ff
        ld a,(ix+2)
        or a
        jr z,ayp_pa
        dec (ix+2)
        ret
ayp_pa: ld l,(ix+0)
        ld h,(ix+1)
ayp_pl: ld a,(hl)
        inc hl
        cp $60
        jr c,ayp_note
        jr z,ayp_rest
        cp $c0
        jr c,ayp_wait
        cp $d0
        jr c,ayp_inst
        cp $e0
        jr c,ayp_orn
        cp $f0
        jr nc,ayp_vset
        sub $e0                 ; drum burst
        ld (ix+AYP_DRUM),a
        jr ayp_pl
ayp_vset:                       ; $F0 depth delay: the song's vibrato settings
        ld a,(hl)
        inc hl
        ld (ayp_vdepth),a
        ld a,(hl)
        inc hl
        ld (ayp_vdelay),a
        jr ayp_pl
ayp_inst:
        sub $c0
        ld (ix+AYP_INST),a
        push hl
        ld l,a                  ; cache the envelope pointer
        ld h,0
        add hl,hl
        ld de,ayp_envs
        add hl,de
        ld a,(hl)
        ld (ix+AYP_ENVP),a
        inc hl
        ld a,(hl)
        ld (ix+AYP_ENVP+1),a
        pop hl
        jr ayp_pl
ayp_orn:
        sub $d0
        ld (ix+AYP_ORN),a
        push hl
        ld l,a                  ; cache the ornament pointer and length
        ld h,0
        add hl,hl
        ld de,ayp_orns
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld (ix+AYP_ORNP),e
        ld (ix+AYP_ORNP+1),d
        ld a,(de)
        ld (ix+AYP_OLEN),a
        pop hl
        jr ayp_pl
ayp_note:
        ld (ix+AYP_NOTE),a
        xor a
        ld (ix+AYP_ENV),a
        ld (ix+AYP_ORNPOS),a
        ld (ix+AYP_VIBCNT),a
        jr ayp_pd
ayp_rest:
        ld (ix+AYP_NOTE),$ff
        jr ayp_pd
ayp_wait:
        sub $80
        ld (ix+2),a
ayp_pd: ld (ix+0),l
        ld (ix+1),h
        ret

; build channel C (0-2) at IX into ayp_out
ayp_voice:
        xor a
        ld (ayp_vol),a
        ld a,(ix+AYP_NOTE)
        cp $ff
        jp z,ayp_drum
        ld b,a                  ; B = note
        ld e,(ix+AYP_ORNP)      ; DE = ornament (length, offsets...)
        ld d,(ix+AYP_ORNP+1)
        ld l,(ix+AYP_ORNPOS)
        ld h,0
        inc hl
        add hl,de
        ld a,(hl)
        add a,b                 ; note + ornament offset
        cp 96
        jr c,ayp_n1
        ld a,95
ayp_n1: ld l,a                  ; period = ayp_periods[note]
        ld h,0
        add hl,hl
        ld de,ayp_periods
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)               ; DE = period
        ld a,c
        or a
        jr nz,ayp_nov           ; vibrato on the lead only
        ld a,(ayp_vdelay)
        ld l,a
        ld a,(ix+AYP_VIBCNT)
        sub l
        jr c,ayp_nov
        ld l,a                  ; vibrato step: -2..2 (peak / half peak)
        ld h,0
        push de
        ld de,ayp_vib
        add hl,de
        ld a,(hl)
        pop de
        or a
        jr z,ayp_nov
        push af                 ; step
        ld a,(ayp_vdepth)
        or a
        jr z,ayp_vz
        push bc                 ; C = channel
        ld hl,0                 ; C:HL = period x depth (24 bits; under 2^20)
        ld c,l
        ld b,8
ayp_vm: add hl,hl
        rl c
        add a,a
        jr nc,ayp_vm1
        add hl,de
        jr nc,ayp_vm1
        inc c
ayp_vm1:
        djnz ayp_vm
        ld a,h                  ; + 2048, then >> 12: peak = (C << 4) | (H >> 4)
        add a,8
        jr nc,ayp_vr
        inc c
ayp_vr: and $f0
        or c
        rrca
        rrca
        rrca
        rrca
        pop bc
        or a
        jr nz,ayp_vp
        inc a                   ; at least one period step, so high notes keep their vibrato
ayp_vp: ld l,a                  ; L = peak
        pop af                  ; A = step
        cp 2
        jr z,ayp_vf
        cp $fe
        jr z,ayp_vf
        srl l                   ; half peak
ayp_vf: ex de,hl                ; HL = period, E = delta
        ld d,0
        bit 7,a
        jr nz,ayp_vneg
        add hl,de
        ex de,hl                ; DE = period
        jr ayp_nov
ayp_vneg:
        or a
        sbc hl,de
        ex de,hl
        jr ayp_nov
ayp_vz: pop af
ayp_nov:
        ld hl,ayp_out           ; registers 2C, 2C+1 = period
        ld a,c
        add a,a
        add a,l
        ld l,a
        jr nc,ayp_p1
        inc h
ayp_p1: ld (hl),e
        inc hl
        ld (hl),d
        ld hl,ayp_tonem         ; mixer: tone on for this channel
        ld a,l
        add a,c
        ld l,a
        jr nc,ayp_m1
        inc h
ayp_m1: ld a,(ayp_out+7)
        and (hl)
        ld (ayp_out+7),a
        ld e,(ix+AYP_ENVP)      ; DE = envelope (length, values...)
        ld d,(ix+AYP_ENVP+1)
        ld a,(de)
        dec a
        ld b,a                  ; B = last index
        ld l,(ix+AYP_ENV)
        ld h,0
        inc hl
        add hl,de
        ld a,(hl)
        ld (ayp_vol),a
        ld a,(ix+AYP_ENV)       ; advance: envelope holds, ornament cycles, vibrato loops
        cp b
        jr nc,ayp_e1
        inc (ix+AYP_ENV)
ayp_e1: ld a,(ix+AYP_ORNPOS)
        inc a
        ld b,a
        ld a,(ix+AYP_OLEN)
        cp b
        ld a,b
        jr nz,ayp_o1
        xor a
ayp_o1: ld (ix+AYP_ORNPOS),a
        ld a,(ayp_vdelay)
        add a,8
        ld b,a
        ld a,(ix+AYP_VIBCNT)
        inc a
        cp b
        jr nz,ayp_v1
        sub 8
ayp_v1: ld (ix+AYP_VIBCNT),a
ayp_drum:
        ld a,(ix+AYP_DRUM)      ; drum burst on the first frame of its row
        cp $ff
        jr z,ayp_vo
        ld b,a
        ld a,(ayp_tick)
        or a
        jr nz,ayp_vo
        ld l,b
        ld h,0
        add hl,hl
        ld de,ayp_drums
        add hl,de
        ld a,(hl)               ; noise period
        ld (ayp_out+6),a
        inc hl
        ld b,(hl)               ; drum volume
        ld a,(ayp_vol)
        cp b
        jr nc,ayp_d1
        ld a,b
        ld (ayp_vol),a
ayp_d1: ld hl,ayp_noisem        ; mixer: noise on for this channel
        ld a,l
        add a,c
        ld l,a
        jr nc,ayp_d3
        inc h
ayp_d3: ld a,(ayp_out+7)
        and (hl)
        ld (ayp_out+7),a
ayp_vo: ld hl,ayp_out+8         ; volume register 8+C
        ld a,l
        add a,c
        ld l,a
        jr nc,ayp_v2
        inc h
ayp_v2: ld a,(ayp_vol)
        ld (hl),a
        ret

ayp_speed: defb 0
ayp_tick:  defb 0
ayp_row:   defb 0
ayp_vol:   defb 0
ayp_vdepth: defb AYP_VIB_DEPTH
ayp_vdelay: defb AYP_VIB_DELAY
ayp_tonem:  defb %11111110,%11111101,%11111011
ayp_noisem: defb %11110111,%11101111,%11011111
ayp_loop:  defw 0
ayp_pats:  defw 0
ayp_order: defw 0
ayp_out:   defs 14
ayp_ch:    defs 3 * AYP_SIZE
        include "aycommon.asm"         ; ay_shadow, if ayplay.asm was not included first
