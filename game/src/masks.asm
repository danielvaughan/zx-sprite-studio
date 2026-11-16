; ---------------------------------------------------------------- masks (MASK-01)
; Each frame n has a mask, kept as frame n + 8 (frame_ptr). A mask dot is cover (1) or keep (0).
; Styles: Ring (ink, the paper it encloses, and a ring T-RING = 1 dot side by side round the ink),
; Shape (ink and enclosed paper), Box (every dot), Hand (as painted: never recomputed).
;
; Ring, Shape and Box follow the picture: mask_again marks every frame to do and mask_tick works
; them out one at a time, MK_CAP rows an update, in its own workspace, writing the mask frame only
; when it is finished (all rows in one update), so nothing half-made is ever read (D-044).
;
; "Enclosed" paper cannot be reached from the box's edge through paper dots side by side. mk_o
; holds the paper reached so far, seeded with the edge's paper; sweeps down and up let each row
; take the reached paper of the row before, then fill along its runs of paper (to the left by a
; multi-byte add: p + x carries up a run from each seed; to the right the same on the row with
; its bits reversed). The sweeps repeat until a pair changes nothing.
;
; Row workspace (MAX_BPR bytes each): mk_x the row worked on, mk_p its paper, mk_s a sum or a
; shift, mk_i its ink. IX walks them together.
MK_CAP  equ 3                   ; rows an update (seeding, sweeping, finishing)
mk_p    equ mk_x+MAX_BPR
mk_s    equ mk_x+2*MAX_BPR
mk_i    equ mk_x+3*MAX_BPR

; the picture changed: every mask is to be worked out again (not for Hand)
mask_again:
        ld a,(mstyle)
        cp MS_HAND
        ret z
mask_all:
        ld a,(mstyle)           ; (the style they are worked out in: they finish in it even if the
        ld (mk_style),a         ; style turns Hand meanwhile)
        ld a,$ff
        ld (mk_need),a
        xor a
        ld (mk_st),a
        ret

; work every pending mask out now (CHECK, the Test Ground, a change to Hand)
mask_finish:
.l:     ld a,(mk_need)
        ld hl,mk_st
        or (hl)
        ret z
        call mask_tick
        jr .l

; C = row -> DE = row * bpr. Keeps BC, HL.
mk_off: push hl
        push bc
        ld e,c
        ld d,0
        ld hl,0
        ld a,(bpr)
        ld b,a
.m:     add hl,de
        djnz .m
        ex de,hl
        pop bc
        pop hl
        ret

; C = row -> mk_i its ink, mk_p its paper (from the picture frame at mk_src). Keeps BC.
mk_load:
        call mk_off
        ld hl,(mk_src)
        add hl,de
        ld ix,mk_x
        ld a,(bpr)
        ld b,a
.l:     ld a,(hl)
        ld (ix+3*MAX_BPR),a
        cpl
        ld (ix+MAX_BPR),a
        inc hl
        inc ix
        djnz .l
        ld a,c                  ; (B was the count: C is the row, kept)
        ret

; C = row -> HL = its bytes in mk_o. Keeps BC.
mk_orow:
        call mk_off
        ld hl,mk_o
        add hl,de
        ret

mask_tick:
        ld a,(mk_st)
        or a
        jp nz,.go
        ld a,(mk_need)          ; the next frame to do: the current frame first, else the lowest
        or a
        ret z
        ld a,(cur_frame)
        ld c,a
        ld b,1
        or a
        jr z,.cb
.cbs:   rlc b
        dec a
        jr nz,.cbs
.cb:    ld a,(mk_need)
        and b
        jr nz,.got
        ld a,(mk_need)
        ld c,0
        ld b,1
.f:     and b
        jr nz,.got
        ld a,(mk_need)
        inc c
        rlc b
        jr nz,.f
        ret
.got:   ld a,b
        cpl
        ld hl,mk_need
        and (hl)
        ld (hl),a
        ld a,c
        ld hl,nframes
        cp (hl)
        ret nc                  ; no such frame
        ld (mk_k),a
        call frame_ptr
        ld (mk_src),hl
        ld a,(mk_style)
        cp MS_BOX
        jp z,mk_box
        ld hl,mk_o              ; seed: the edge's paper (state 4, a few rows an update)
        ld de,mk_o+1
        ld bc,MAX_FBYTES-1
        ld (hl),0
        ldir
        xor a
        ld (mk_r),a
        ld a,4
        ld (mk_st),a
        ret
.go:    ld a,MK_CAP
        ld (mk_n),a
.row:   ld a,(mk_st)
        cp 4
        jr nz,.ns
        call mk_seed
        jp .more
.ns:    cp 5
        jp z,mk_commit
        cp 3
        jp z,mk_final
        ld a,(mk_r)
        ld c,a
        call mk_load            ; this row's paper
        ld a,(mk_st)            ; the neighbour: the row above sweeping down, below sweeping up
        cp 1
        ld a,c
        jr nz,.up
        dec a
        jr .nb
.up:    inc a
.nb:    push bc
        ld c,a
        call mk_orow
        pop bc
        ld ix,mk_x              ; x = neighbour's reached & paper
        ld a,(bpr)
        ld b,a
.x:     ld a,(hl)
        and (ix+MAX_BPR)
        ld (ix+0),a
        inc hl
        inc ix
        djnz .x
        call mk_orow            ; x |= this row's reached
        ld ix,mk_x
        ld a,(bpr)
        ld b,a
.o:     ld a,(hl)
        or (ix+0)
        ld (ix+0),a
        inc hl
        inc ix
        djnz .o
        push bc
        call mk_fill            ; along the runs of paper
        pop bc
        call mk_orow            ; store; changed?
        ld ix,mk_x
        ld a,(bpr)
        ld b,a
.c:     ld a,(ix+0)
        cp (hl)
        jr z,.cs
        ld (hl),a
        ld a,1
        ld (mk_chg),a
.cs:    inc hl
        inc ix
        djnz .c
        ld a,(mk_st)            ; the next row
        cp 1
        ld hl,mk_r
        jr nz,.dn
        inc (hl)
        ld a,(box_h)
        cp (hl)
        jr nz,.more
        sub 2
        ld (hl),a               ; then up from the second last row
        ld a,2
        ld (mk_st),a
        jr .more
.dn:    ld a,(hl)
        or a
        jr z,.top
        dec (hl)
        jr .more
.top:   ld a,(mk_chg)           ; up at row 0: again if anything changed, else finish
        or a
        ld a,3
        jr z,.st                ; (mk_r is 0: the finish starts at row 0)
        xor a
        ld (mk_chg),a
        inc a
        ld (hl),a               ; mk_r = 1
.st:    ld (mk_st),a
.more:  ld hl,mk_n
        dec (hl)
        jp nz,.row
        ret

; one row of the seed: the edge's paper (the whole top and bottom rows, the end dots of the others)
mk_seed:
        ld a,(mk_r)
        ld c,a
        call mk_load
        call mk_orow            ; HL = this row in mk_o
        ld a,c
        or a
        jr z,.whole
        inc a
        push hl
        ld hl,box_h
        cp (hl)
        pop hl
        jr z,.whole
        ld a,(mk_p)             ; a middle row: its leftmost and rightmost dots
        and $80
        ld (hl),a
        ld a,(bpr)
        dec a
        ld e,a
        ld d,0
        add hl,de
        push hl
        ld hl,mk_p
        add hl,de
        ld a,(hl)
        pop hl
        and 1
        or (hl)
        ld (hl),a
        jr .sn
.whole: ex de,hl                ; the top and bottom rows: all their paper
        ld hl,mk_p
        push bc
        ld a,(bpr)
        ld c,a
        ld b,0
        ldir
        pop bc
.sn:    inc c
        ld a,c
        ld (mk_r),a
        ld a,(box_h)
        cp c
        ret nz
        xor a
        ld (mk_chg),a
        inc a
        ld (mk_r),a
        ld (mk_st),a            ; 1: sweep down from row 1
        ret

mk_stop:
        xor a
        ld (mk_st),a
        ret

; mk_x := mk_x filled along the runs of mk_p, both ways
mk_fill:
        call mk_left
        call mk_rev             ; reversed, a fill to the left is a fill to the right
        call mk_left
        jp mk_rev

; x := ((p + x) ^ p) & p | x, bytes big-endian (the left dot is the first byte's top bit)
mk_left:
        ld a,(bpr)
        ld b,a
        dec a
        ld e,a
        ld d,0
        ld ix,mk_x
        add ix,de               ; the last byte
        or a
.s:     ld a,(ix+0)
        adc a,(ix+MAX_BPR)
        ld (ix+2*MAX_BPR),a     ; s = p + x, carrying up from the last byte
        dec ix
        djnz .s
        ld ix,mk_x
        ld a,(bpr)
        ld b,a
.b:     ld a,(ix+2*MAX_BPR)
        xor (ix+MAX_BPR)
        and (ix+MAX_BPR)
        or (ix+0)
        ld (ix+0),a
        inc ix
        djnz .b
        ret

; reverse mk_x and mk_p: bytes end for end, each byte's bits reversed (rev_tab)
mk_rev: ld hl,mk_x
        call .one
        ld hl,mk_p
.one:   ld a,(bpr)
        ld b,a
        ld e,a
        ld d,0
        push hl
        add hl,de
        ex de,hl                ; DE = past the row
        pop hl
        srl b                   ; swap the pairs from both ends inwards
        jr z,.mid
.s:     dec de
        push bc
        ld c,(hl)
        ld a,(de)
        push hl
        ld l,a
        ld h,high rev_tab
        ld a,(hl)
        pop hl
        ld (hl),a               ; left := rev(right)
        push hl
        ld l,c
        ld h,high rev_tab
        ld a,(hl)
        pop hl
        ld (de),a               ; right := rev(left)
        inc hl
        pop bc
        djnz .s
.mid:   ld a,(bpr)              ; an odd middle byte reverses in place
        and 1
        ret z
        ld a,(hl)
        push hl
        ld l,a
        ld h,high rev_tab
        ld a,(hl)
        pop hl
        ld (hl),a
        ret

; Box: every dot covers
mk_box: ld a,(mk_k)
        add a,MAX_FRAMES
        call frame_ptr
        ld a,(fbytes)
        ld b,a
.l:     ld (hl),$ff
        inc hl
        djnz .l
        jr mk_done

; the mask: ink, enclosed paper (paper not reached) and, for Ring, the ink's ring; a few rows an
; update into mk_res, then (state 5) copied into the mask frame in one go
mk_final:
        ld a,(mk_r)
        ld c,a
        call mk_load            ; mk_i ink, mk_p paper
        call mk_orow            ; HL = reached
        ld ix,mk_x
        ld a,(bpr)
        ld b,a
.e:     ld a,(hl)               ; x = ink | (paper & ~reached)
        cpl
        and (ix+MAX_BPR)
        or (ix+3*MAX_BPR)
        ld (ix+0),a
        inc hl
        inc ix
        djnz .e
        ld a,(mk_style)
        cp MS_RING
        call z,mk_ring
        call mk_off             ; into mk_res
        ld hl,mk_res
        add hl,de
        ex de,hl
        ld hl,mk_x
        ld a,(bpr)
        ld c,a
        ld b,0
        ldir
        ld hl,mk_r
        inc (hl)
        ld a,(box_h)
        cp (hl)
        jr nz,.more
        ld a,5
        ld (mk_st),a
.more:  ld hl,mk_n
        dec (hl)
        jp nz,mask_tick.row
        ret

mk_commit:
        ld a,(mk_k)
        add a,MAX_FRAMES
        call frame_ptr
        ex de,hl
        ld hl,mk_res
        ld a,(fbytes)
        ld c,a
        ld b,0
        ldir
mk_done:
        xor a
        ld (mk_st),a
        jp mask_shown

; C = row: mk_x |= this row's ink one dot left and one dot right, and the rows above and below
; (a ring of T-RING = 1 dot side by side). Keeps C.
mk_ring:
        ld a,(bpr)              ; s = ink << 1 (towards the first byte's top bit), from the last byte
        ld b,a
        dec a
        ld e,a
        ld d,0
        ld ix,mk_x
        add ix,de
        or a
.sl:    ld a,(ix+3*MAX_BPR)
        rla
        ld (ix+2*MAX_BPR),a
        dec ix
        djnz .sl
        call .or_s
        ld a,(bpr)              ; s = ink >> 1, from the first byte
        ld b,a
        ld ix,mk_x
        or a
.sr:    ld a,(ix+3*MAX_BPR)
        rra
        ld (ix+2*MAX_BPR),a
        inc ix
        djnz .sr
        call .or_s
        ld a,c                  ; the row above
        or a
        jr z,.nb
        dec c
        call .or_row
        inc c
.nb:    ld a,c                  ; the row below
        inc a
        ld hl,box_h
        cp (hl)
        ret z
        inc c
        call .or_row
        dec c
        ret
.or_s:  ld ix,mk_x
        ld a,(bpr)
        ld b,a
.o:     ld a,(ix+2*MAX_BPR)
        or (ix+0)
        ld (ix+0),a
        inc ix
        djnz .o
        ret
.or_row:
        call mk_off             ; C = a row: mk_x |= its ink
        ld hl,(mk_src)
        add hl,de
        ld ix,mk_x
        ld a,(bpr)
        ld b,a
.or:    ld a,(hl)
        or (ix+0)
        ld (ix+0),a
        inc hl
        inc ix
        djnz .or
        ret

; the reverse table: each byte's bits in reverse order (built once at start)
build_rev:
        ld hl,rev_tab
.l:     ld a,l
        call rev8
        ld (hl),a
        inc l
        jr nz,.l
        ret
