; (the Test Ground's code and its texts: bank 6, paged in by bank6_call, D-051)
; ---------------------------------------------------------------- the Test Ground (GROUND-01)
; A page of the Desk (state 1, phase 3; H, or GROUND in the MASK drawer): the current frame (or the
; flip-book's) at true size three times over the chosen Ground: COPY (the box replaces the ground),
; MIX (the ink added on top) and MASK+MIX (the ground cleared where the mask covers, then the ink).
; Each panel is 6 x 6 cells (48 x 48 dots), the figure centred on whole bytes. A panel's every byte
; is composed and written once, one panel an update (gn_need): the whole panel when the ground
; changed, else only the figure's rows (D-044).

GN_Y    equ 32                      ; panels' top dot row (row 4)
GN_H    equ 48
GN_W    equ 6                       ; bytes across
GN_FIRST equ 2                      ; panel columns: 2, 12, 22
GN_STEP equ 10
GN_CAP  equ 12                      ; dot rows an update

ST_ROW  equ 11                      ; the colour strip (CLASH-01, MOVE-01): rows 11-16, all 32 columns
ST_Y    equ ST_ROW*8
ST_H    equ 48
ST_BUDGET equ 72                    ; strip bytes an update (the pointer's Arrow, as GN_CAP)
ST_BCAP equ 8                       ; figure rows shifted an update (then the cells: an update of their own)
GT_ROW  equ 17                      ; readouts: rows 17-20
GT_W    equ 32
GT_H    equ 5                       ; (row 21: a lesson's caption)
gt_want equ grid_want               ; (the Grid's tables are free while this page shows, as the Library's)
gn_want equ grid_want+GT_W*GT_H     ; the Ground's name, row 0 cols 26-31
gl_want equ gn_want+6               ; the key line, row 22 (G:PLAY or G:STOP, m5-r2 F-50)
GA_MODE equ 0                       ; the page's actions, from keys or clicks (gn_keys)
GA_INK  equ 1
GA_WALK equ 2
GA_STEP equ 3
GA_GROUND equ 4
GA_PLAY equ 5
GA_BACK equ 6
GA_FLICK equ 7                      ; R: the flicker demonstration (FLICK-01)
FL_Y    equ 32                      ; the RUB OUT, DRAW copy: rows 4-9, where the panels are

gn_panels:
        dw gt_want, grid_have
        db 0,GT_ROW,GT_W,GT_H
        dw gn_want, grid_have+GT_W*GT_H
        db 26,0,6,1
        dw gl_want, grid_have+GT_W*GT_H+6
        db 0,22,32,1
N_GN_PANELS equ 3

g6_enter:
        ld a,1
        ld (gn_open),a
        ld (sfx_req),a
        ld a,3
        ld (phase),a
        call lock_buttons
        call new_screen
        xor a
        ld (fl_state),a
        ld (fl_valid),a
        ld a,(fl_on)                ; the demonstration: both copies in Keep (only the order differs)
        or a
        jr z,.nk
        xor a
        ld (cmode),a
.nk:    ld hl,gn_panels
        ld (pd_table),hl
        ld a,N_GN_PANELS
        ld (pd_count),a
        ld hl,grid_want             ; wanted and shown text blank, as the screen is
        ld de,grid_want+1
        ld bc,1023
        ld (hl),' '
        ldir
        xor a
        ld (txt_pend),a
        ld (pend_n),a
        ld a,(fl_on)
        or a
        ld hl,gn_text
        jr z,.tx
        ld hl,fl_text
.tx:    call print_list
        ld a,AT_DEFAULT
        call set_attrs
        ld de,$0001
        ld bc,$0f01
        ld a,AT_HEAD
        call fill_attr
        ld a,(fl_on)
        or a
        jr z,.pw
        call fl_ground              ; the RUB OUT, DRAW copy's Ground
        jr .pd
.pw:    ld de,GN_Y/8*256+GN_FIRST   ; the three panels, white
        call .white
        ld de,GN_Y/8*256+GN_FIRST+GN_STEP
        call .white
        ld de,GN_Y/8*256+GN_FIRST+2*GN_STEP
        call .white
.pd:
        xor a
        ld (gn_busy),a
        ld (st_busy),a
        ld (st_bld),a
        ld (st_go),a
        ld (st_dvalid),a
        ld (st_ast),a
        inc a
        ld (st_full),a
        ld (st_dirty),a
        ld a,(play_on)              ; the frame shown
        or a
        ld a,(cur_frame)
        jr z,.fr
        ld a,(play_frame)
.fr:    ld (gn_frame),a
        call st_home
        call gt_compose
        ld a,(fl_on)
        or a
        ret nz                      ; (no panels in the demonstration)
        jp gn_all
.white: ld bc,GN_W*256+GN_H/8
        ld a,AT_CANVAS
        jp fill_attr

; the figure at the Ground's left edge, on the cell grid, facing right (MOVE-01, Walk off)
st_home:
        xor a
        ld (st_tx),a
        ld (st_tdir),a
        ld a,(box_h)
        ld b,a
        ld a,ST_H
        sub b
        srl a
        and $f8
        ld (st_ty),a
        ret

ground_close:
        xor a
        ld (les_tg),a
        ld a,(wk_play)              ; the flip-book Walk started stops with the page
        or a
        jr z,.k
        xor a
        ld (play_on),a
        ld (play_frame),a
        ld (wk_play),a
.k:     xor a
        ld (gn_open),a
        inc a
        ld (phase),a
        ld (sfx_req),a
        call lock_buttons
        call drawer_dirty           ; (PLAY or STOP: the flip-book may have changed here)
        jp draw_desk

g6_logic:
        ld a,(gn_open)              ; (2: the Sheet page, 3: the Lessons)
        cp 2
        jp z,sh_logic
        cp 3
        jp z,les_logic
        call mask_tick              ; masks still to work out (the panels wait for them)
        call gn_keys
        ld (gn_act),a
        bit GA_BACK,a               ; T: back to the Desk
        jp nz,ground_close
        bit GA_FLICK,a              ; R: the flicker demonstration on or off: the page again
        jr z,.nf
        ld a,(fl_on)
        xor 1
        ld (fl_on),a
        jp g6_enter
.nf:    ld a,(gn_act)
        bit GA_GROUND,a             ; H: the next Ground
        jr z,.p
        ld a,(gn_ground)
        inc a
        and 3
        ld (gn_ground),a
        ld a,1
        ld (st_full),a
        ld (st_dirty),a
        call fig_check              ; (hard to see: the Ground's paper)
        ld a,(fl_on)                ; (the demonstration: the page again, both copies on the Ground)
        or a
        jp nz,g6_enter
        call gn_all
        call .chg
.p:     ld a,(gn_act)               ; G: the flip-book on or off (here too)
        bit GA_PLAY,a
        jr z,.m
        xor a                       ; (now the reader's own)
        ld (wk_play),a
        ld a,(play_on)
        xor 1
        ld (play_on),a
        jr nz,.pg
        ld a,(wk_on)                ; stopped: a walk stops with it, and says so (m5-r2 F-46)
        or a
        jr z,.pg
        xor a
        ld (wk_on),a
        call st_home
.pg:    xor a
        ld (play_frame),a
        ld a,(play_lvl)
        call play_reload
        call .chg
.m:     ld a,(gn_act)               ; C: the colour mode, Keep, Ink, Box
        bit GA_MODE,a
        jr z,.i
        ld a,(cmode)
        inc a
        cp 3
        jr c,.m1
        xor a
.m1:    ld (cmode),a
        ld a,1
        ld (st_dirty),a
        call .chg
.i:     ld a,(gn_act)               ; I: the figure's ink colour
        bit GA_INK,a
        jr z,.w
        ld a,(fig_ink)
        inc a
        and 7
        ld (fig_ink),a
        ld a,1
        ld (st_dirty),a
        call fig_check
        call .chg
.w:     ld a,(gn_act)               ; W: Walk on or off
        bit GA_WALK,a
        jr z,.s
        ld a,(wk_on)
        xor 1
        ld (wk_on),a
        jr z,.woff
        ld a,(play_on)              ; walking needs the flip-book turning
        or a
        jr nz,.wc
        inc a
        ld (play_on),a
        ld (wk_play),a              ; (Walk started it: it stops again on leaving, m5-r1 F-42)
        xor a
        ld (play_frame),a
        ld a,(play_lvl)
        call play_reload
        jr .wc
.woff:  call st_home
        ld a,(wk_play)              ; the flip-book Walk started stops with it
        or a
        jr z,.wc
        xor a
        ld (play_on),a
        ld (play_frame),a
        ld (wk_play),a
.wc:    call .chg
.s:     ld a,(gn_act)               ; S: the step size
        bit GA_STEP,a
        jr z,.n
        ld a,(wk_step)
        inc a
        and 3
        ld (wk_step),a
        call fig_check
        call .chg
.n:     ld a,(wk_on)                ; Walk off: QAOP (or the stick) move the figure a dot
        or a
        call z,st_nudge
        ld a,(input_dev)
        cp DEV_MOUSE
        call z,move_cursor          ; the Arrow
        ld a,(play_on)              ; the flip-book turns a page this update: a step
        or a
        jr z,.nt
        ld a,(play_t)
        dec a
.nt:    ld (gn_turn),a              ; (0: a turn)
        call play_tick
        ld a,(gn_turn)
        or a
        jr nz,.nw
        ld a,(play_on)
        or a
        jr z,.nw
        ld a,(wk_on)
        or a
        call nz,st_walk
.nw:    ld a,(play_on)              ; the frame shown: the flip-book's, else the current one
        or a
        ld a,(cur_frame)
        jr z,.f
        ld a,(play_frame)
.f:     ld hl,gn_frame
        cp (hl)
        jr z,.same
        ld (hl),a
        ld a,(gn_need)
        or 7
        ld (gn_need),a
.same:  call st_logic
        ld a,(txt_pend)
        or a
        ret z
        jp panel_diff
.chg:   ld a,1
        ld (sfx_req),a
        jp gt_compose

; the page's actions this update: keys (C, I, W, S, H, G, T) or a click on their words -> A
gn_keys:
        ld c,0
        ld a,(FRESH3)
        bit A_NEW,a                 ; C
        jr z,.k1
        set GA_MODE,c
.k1:    bit A_PLAY,a                ; G
        jr z,.k1a
        set GA_PLAY,c
.k1a:   bit A_CLR,a                 ; R
        jr z,.k2
        set GA_FLICK,c
.k2:    ld a,(FRESH4)
        bit 1,a                     ; I
        jr z,.k3
        set GA_INK,c
.k3:    bit 7,a                     ; W
        jr z,.k4
        set GA_WALK,c
.k4:    ld a,(FRESH2)
        bit K_SMALLER,a             ; S
        jr z,.k5
        set GA_STEP,c
.k5:    ld a,(FRESH5)
        bit K_GROUND,a              ; H
        jr z,.k6
        set GA_GROUND,c
.k6:    ld a,(FRESH1)
        bit K_TITLE,a               ; T
        jr z,.k7
        set GA_BACK,c
.k7:    ld a,(input_dev)            ; the pointer: a click on a control's words
        cp DEV_MOUSE
        jr nz,.done
        ld a,(FRESH1)
        bit K_PRIM,a
        jr z,.done
        ld a,(cur_y)
        rrca
        rrca
        rrca
        and $1f
        ld d,a                      ; D = row
        ld a,(cur_x)
        rrca
        rrca
        rrca
        and $1f
        ld e,a                      ; E = column
        ld hl,gn_clicks
.cl:    ld a,(hl)
        cp $ff
        jr z,.done
        cp d
        jr nz,.cn
        inc hl
        ld a,e
        cp (hl)
        jr c,.cn1
        inc hl
        ld a,(hl)
        cp e
        jr c,.cn2
        inc hl
        ld a,(hl)
        or c
        ld c,a
        jr .done
.cn:    inc hl
.cn1:   inc hl
.cn2:   inc hl
        inc hl
        jr .cl
.done:  ld a,c
        ret

; the words a click uses: row, first column, last column, the action's bit
gn_clicks:
        db GT_ROW+1,0,15,1<<GA_MODE
        db GT_ROW+1,17,31,1<<GA_INK
        db GT_ROW+2,0,10,1<<GA_WALK
        db GT_ROW+2,12,20,1<<GA_STEP
        db 22,0,7,1<<GA_GROUND
        db 22,9,14,1<<GA_PLAY
        db 22,16,24,1<<GA_FLICK
        db 22,26,31,1<<GA_BACK
        db $ff

; this update's caps: with the pointer, smaller the higher its Arrow, so the draw phase ends before
; the beam reaches it (m5-click-colour: the Arrow near the top while walking): panel rows y / 8
; y / 16 (1 to GN_CAP), strip bytes y / 2 (32, one whole row, to ST_BUDGET) and rows y / 12,
; colours y / 4 (4 to 40)
gn_caps:
        ld a,(input_dev)
        cp DEV_MOUSE
        ld a,255
        jr nz,.c
        ld a,(cur_y)
.c:     ld b,a
        srl a
        srl a
        srl a
        srl a
        cp 1
        jr nc,.r1
        ld a,1
.r1:    cp GN_CAP
        jr c,.r2
        ld a,GN_CAP
.r2:    ld (gn_rows),a
        ld a,b
        srl a
        cp 32
        jr nc,.s1
        ld a,32
.s1:    cp ST_BUDGET
        jr c,.s2
        ld a,ST_BUDGET
.s2:    ld (st_bud),a
        ld a,b                      ; strip rows: y / 12 (1 to 48), about 600 T each
        ld c,0
.d12:   sub 12
        jr c,.d0
        inc c
        jr .d12
.d0:    ld a,c
        or a
        jr nz,.d1
        inc a
.d1:    ld (st_rbud),a
        ld a,b
        srl a
        srl a
        cp 4
        jr nc,.a1
        ld a,4
.a1:    cp 40
        jr c,.a2
        ld a,40
.a2:    ld (st_abud),a
        ld a,(input_dev)            ; no Arrow: a whole step, dots and colours, in one turn (m5-r2
        cp DEV_MOUSE                ; F-48, F-49: a block's colour or the old rows a moment late)
        ret z
        ld a,255
        ld (st_bud),a
        ld (st_abud),a
        ld a,ST_H
        ld (st_rbud),a
        ret

; Walk off: a fresh Q, A, O or P moves the figure one dot, within the Ground
st_nudge:
        ld a,(FRESH1)
        ld c,a
        bit K_RIGHT,c
        jr z,.l
        ld a,(box_w)
        neg                         ; 256 - width: the right-most place
        ld b,a
        ld a,(st_tx)
        cp b
        jr nc,.l
        inc a
        ld (st_tx),a
.l:     bit K_LEFT,c
        jr z,.d
        ld a,(st_tx)
        or a
        jr z,.d
        dec a
        ld (st_tx),a
.d:     bit K_DOWN,c
        jr z,.u
        ld a,(box_h)
        ld b,a
        ld a,ST_H
        sub b
        ld b,a
        ld a,(st_ty)
        cp b
        jr nc,.u
        inc a
        ld (st_ty),a
.u:     bit K_UP,c
        ret z
        ld a,(st_ty)
        or a
        ret z
        dec a
        ld (st_ty),a
        ret

; Walk on, a page turned: a step (T-STEPS) the way it faces, turning at either edge
st_walk:
        ld a,(wk_step)
        ld e,a
        ld d,0
        ld hl,wk_steps
        add hl,de
        ld c,(hl)                   ; C = dots
        ld a,(box_w)
        neg
        ld b,a                      ; B = the right-most place
        ld a,(st_tdir)
        or a
        jr nz,.left
        ld a,(st_tx)
        add a,c
        jr c,.turn
        cp b
        jr c,.ok
.turn:  ld a,1
        ld (st_tdir),a
        ld a,b
        jr .ok
.left:  ld a,(st_tx)
        sub c
        jr c,.home
        jr nz,.ok
.home:  xor a
        ld (st_tdir),a
.ok:    ld (st_tx),a
        ret

; the draw phase: one panel
g6_draw:
        ld a,(gn_open)
        cp 2
        jp z,sh_draw
        cp 3
        jp z,les_draw
        call gn_caps
        ld a,(gn_txt)               ; turns: 0 the text, 1 the panels, 2 the strip; a turn with
        inc a                       ; nothing to do passes to the next (none is starved while
        cp 3                        ; the flip-book plays)
        jr c,.t
        xor a
.t:     ld (gn_txt),a
        or a
        jr nz,.nt
        ld a,(pend_n)
        or a
        jp nz,print_pending
.nt:    ld a,(mk_need)              ; masks not ready: the panels wait (late, never wrong)
        ld hl,mk_st
        or (hl)
        jp nz,print_pending
        ld a,(gn_txt)
        cp 2
        jr nz,.pan
        ld a,(st_busy)
        ld hl,st_go
        or (hl)
        jp nz,st_draw
.pan:   ld a,(fl_on)                ; the demonstration has the panels' turn
        or a
        jr z,.pn
        xor a
        ld (gn_need),a
        ld a,(fl_state)
        or a
        jp nz,fl_draw
        jp st_draw
.pn:    ld a,(gn_rows)              ; at most gn_rows dot rows an update (the pointer's Arrow)
        ld (gn_cap),a
        ld a,(gn_busy)              ; a panel half drawn: on with it
        or a
        jp nz,.row
        ld a,(gn_need)
        or a
        jp z,st_draw                ; the panels done: the strip
        ld a,(gn_p)                 ; round robin from the panel after the last (m4-r1 F-27: the
        ld c,a                      ; third panel was starved while the flip-book played)
.f:     inc c
        ld a,c
        cp 3
        jr c,.fc
        ld c,0
.fc:    ld b,1
        ld a,c
        or a
        jp z,.fbit
.fs:    sla b
        dec a
        jr nz,.fs
.fbit:  ld a,(gn_need)
        and b
        jr z,.f
.got:   ld a,b
        cpl
        ld hl,gn_need
        and (hl)
        ld (hl),a
        ld a,c
        ld (gn_p),a
        ld a,(gn_full)              ; whole, or the figure's rows only
        and b
        ld (gn_whole),a
        ld a,b
        cpl
        ld hl,gn_full
        and (hl)
        ld (hl),a
        ld a,(gn_frame)
        call frame_ptr
        ld (gn_src),hl
        ld a,(gn_frame)
        add a,MAX_FRAMES
        call frame_ptr
        ld (gn_msk),hl
        ld a,(bpr)                  ; the figure's place: whole bytes, centred
        ld b,a
        ld a,GN_W
        sub b
        srl a
        ld (gn_ox),a
        ld a,(box_h)
        ld b,a
        ld a,GN_H
        sub b
        srl a
        ld (gn_oy),a
        ld a,(gn_p)                 ; the panel's column
        ld b,a
        ld a,GN_FIRST
        inc b
.c:     dec b
        jr z,.cd
        add a,GN_STEP
        jr .c
.cd:    ld (gn_col),a
        ld a,(gn_whole)
        or a
        ld a,0
        ld b,GN_H
        jr nz,.rows
        ld a,(gn_oy)                ; only the figure's rows
        ld hl,box_h
        ld b,(hl)
.rows:  ld (gn_y),a
        ld a,b
        ld (gn_n),a
        ld a,1
        ld (gn_busy),a
.row:   ld a,(gn_y)                 ; the ground's byte for this dot row
        and 7
        ld e,a
        ld d,0
        ld a,(gn_ground)
        add a,a
        add a,a
        add a,a
        add a,e
        ld e,a
        ld hl,gn_pats
        add hl,de
        ld a,(hl)
        ld (gn_g),a
        ld hl,gn_buf                ; the row's six bytes: the ground
        ld b,GN_W
.g:     ld (hl),a
        inc hl
        djnz .g
        ld a,(gn_y)                 ; the figure's row, if this dot row has one
        ld hl,gn_oy
        sub (hl)
        jr c,.put
        ld hl,box_h
        cp (hl)
        jr nc,.put
        ld c,a                      ; C = figure row
        call mk_off                 ; DE = row * bpr
        ld hl,(gn_src)
        add hl,de
        push hl
        ld hl,(gn_msk)
        add hl,de
        ex de,hl                    ; DE = mask row
        pop hl                      ; HL = picture row
        ld a,(gn_ox)
        ld c,a
        ld b,0
        ld ix,gn_buf
        add ix,bc
        ld a,(bpr)
        ld b,a
.fb:    ld a,(gn_p)
        or a
        jr nz,.mx
        ld a,(hl)                   ; COPY: the figure's byte
        jr .st
.mx:    dec a
        jr nz,.mm
        ld a,(gn_g)                 ; MIX: ground | ink
        or (hl)
        jr .st
.mm:    ld a,(de)                   ; MASK+MIX: (ground & ~mask) | ink
        cpl
        push hl
        ld hl,gn_g
        and (hl)
        pop hl
        or (hl)
.st:    ld (ix+0),a
        inc ix
        inc hl
        inc de
        djnz .fb
.put:   ld a,(gn_y)
        add a,GN_Y
        call row_addr
        ld a,(gn_col)
        add a,l
        ld e,a
        ld d,h
        ld hl,gn_buf
        ld bc,GN_W
        ldir
        ld hl,gn_y
        inc (hl)
        ld hl,gn_n
        dec (hl)
        jr z,.done
        ld hl,gn_cap
        dec (hl)
        jp nz,.row
        ret                         ; the rest of this panel next update
.done:  xor a
        ld (gn_busy),a
        ret

; ---------------------------------------------------------------- the colour strip
; The figure MASK+MIX over the Ground in Colour Blocks, at any dot (st_tx, st_ty), mirrored when it
; walks left. Logic shifts the figure's rows into st_ink/st_msk (st_bld, ST_BCAP rows an update),
; works out its cells' colours and clashes (st_cells), then the draw phase writes the columns it
; left and entered, each byte once with its final value, then their colours (st_draw). Nothing is
; rebuilt while a draw is under way, so what is drawn is always one whole snapshot (st_b*).
st_logic:
        ld a,(st_busy)
        or a
        ret nz                      ; being drawn: the snapshot holds
        ld a,(mk_need)              ; masks still to work out: wait for them
        ld hl,mk_st
        or (hl)
        ret nz
        ld a,(st_bld)               ; a snapshot being built is finished first, even if the
        or a                        ; target has moved on (else a tall figure on a fast flip-book
        jr z,.idle                  ; never finished: m5-r1 F-40); the newest target comes next
        cp 2
        jp z,.cells
        jr .more
.idle:  ld a,(st_go)                 ; built and not yet drawn: it is drawn first (m5-r2 F-40:
        or a                        ; a new page threw each tall snapshot away before its turn)
        ret nz
        call st_same
        ret z                       ; built and drawn
.new:   ld hl,st_tx                 ; the snapshot: place, facing, frame, Ground, mode, ink
        ld de,st_bx
        ld bc,3
        ldir
        ld a,(gn_frame)
        ld (st_bf),a
        ld a,(gn_ground)
        ld (st_bg),a
        ld a,(cmode)
        ld (st_bmode),a
        ld a,(fig_ink)
        ld (st_bink),a
        ld a,(st_full)              ; a whole strip belongs to the snapshot that brings the new
        ld (st_bfull),a             ; Ground (m5-r3 F-51: an older one used it up)
        xor a
        ld (st_full),a
        ld (st_dirty),a
        ld (st_go),a
        ld (st_brow),a
        inc a
        ld (st_bld),a
        ld a,(st_bf)                ; the picture's and the mask's first rows
        call frame_ptr
        ld (st_sp),hl
        ld a,(st_bf)
        add a,MAX_FRAMES
        call frame_ptr
        ld (st_mp),hl
.more:  ld a,ST_BCAP
        ld (st_cap),a
.row:   ld a,(st_brow)
        ld hl,box_h
        cp (hl)
        jr nc,.fin
        ld hl,(st_sp)               ; the picture's row
        ld a,(st_brow)
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,high st_ink
        call st_shift
        ld (st_sp),hl
        ld hl,(st_mp)               ; the mask's row
        ld a,(st_brow)
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,high st_msk
        call st_shift
        ld (st_mp),hl
        ld hl,st_brow
        inc (hl)
        ld hl,st_cap
        dec (hl)
        jr nz,.row
        ret
.fin:   ld a,2                      ; the rows shifted: the cells next update
        ld (st_bld),a
        ret
.cells: xor a
        ld (st_bld),a
        call fl_take
        call st_cells
        ld a,1
        ld (st_go),a
        jp gt_compose

; Z: the snapshot is the target's
st_same:
        ld a,(st_dirty)
        or a
        ret nz
        ld hl,st_tx
        ld de,st_bx
        ld b,3
.c:     ld a,(de)
        cp (hl)
        ret nz
        inc hl
        inc de
        djnz .c
        ld a,(gn_frame)
        ld hl,st_bf
        cp (hl)
        ret

; HL = a row of the figure (bpr bytes), DE = its place (bpr + 1 bytes): mirrored if it faces left,
; then shifted right by st_bx's dots within a byte (by 5 to 7: a byte along, then left by 3 to 1).
; -> HL = the figure's next row
st_shift:
        ld a,(bpr)
        ld b,a
        ld a,(st_bx)
        and 7
        ld c,a                      ; C = the shift
        cp 5
        jr c,.at
        xor a                       ; a byte along: a blank byte first
        ld (de),a
        inc de
.at:    push de
        ld a,(st_bdir)
        or a
        jr nz,.mir
.cp:    ld a,(hl)
        ld (de),a
        inc hl
        inc de
        djnz .cp
        jr .z
.mir:   push hl                     ; from the row's last byte back, each byte's dots reversed
        ld a,(bpr)
        dec a
        add a,l
        ld l,a
        jr nc,.m1
        inc h
.m1:    push hl
        ld l,(hl)
        ld h,high rev_tab
        ld a,(hl)
        pop hl
        ld (de),a
        dec hl
        inc de
        djnz .m1
        pop hl
        ld a,(bpr)
        add a,l
        ld l,a
        jr nc,.z
        inc h
.z:     ld a,c
        cp 5
        jr nc,.left
        xor a                       ; the blank byte last
        ld (de),a
        pop de                      ; DE = the row's first byte
        or c
        ret z
.sh:    push de
        ld a,(bpr)
        inc a
        ld b,a
        or a
        ex de,hl
.rr:    rr (hl)
        inc hl
        djnz .rr
        ex de,hl
        pop de
        dec c
        jr nz,.sh
        ret
.left:  pop af                      ; (the row's start, after the blank byte)
        dec de                      ; DE = the last byte
        ld a,8
        sub c
        ld c,a                      ; left by 8 - shift
.sl:    push de
        ld a,(bpr)
        inc a
        ld b,a
        or a
        ex de,hl
.rl:    rl (hl)
        dec hl
        djnz .rl
        ex de,hl
        pop de
        dec c
        jr nz,.sl
        ret

; the snapshot's cells: how many the box touches (st_ncx x st_ncy), their colour (st_mattr; the
; others st_gattr) and which clash (st_cl, 5 a row): the figure changed the cell's colour and the
; cell holds scenery ink the mask does not cover (CLASH-01)
st_cells:
        ld a,(st_bx)
        and 7
        ld hl,box_w
        add a,(hl)
        add a,7
        rrca
        rrca
        rrca
        and $1f
        ld (st_ncx),a
        ld a,(st_by)
        and 7
        ld hl,box_h
        add a,(hl)
        add a,7
        rrca
        rrca
        rrca
        and $1f
        ld (st_ncy),a
        ld a,(st_bg)
        ld e,a
        ld d,0
        ld hl,gn_attrs
        add hl,de
        ld a,(hl)
        ld (st_gattr),a
        ld c,a
        ld a,(st_bmode)
        or a
        jr z,.k
        dec a
        jr nz,.box
        ld a,c                      ; Ink: the figure's ink, the cell's paper
        and $f8
        ld b,a
        ld a,(st_bink)
        or b
        jr .m
.box:   ld a,(st_bink)              ; Box: the figure's ink on black
        or $40
        jr .m
.k:     ld a,c                      ; Keep: the cell's own colours
.m:     ld (st_mattr),a
        sub c
        ld (st_chg),a
        ld a,(st_bink)              ; hard to see (T-HARD-PAIRS): the box's cells marked, not bright
        cp 5
        jr c,.nh
        ld a,c
        rrca
        rrca
        rrca
        and 7
        cp 5
        jr c,.nh
        ld hl,st_mattr
        res 6,(hl)
.nh:
        ld hl,st_cl
        ld b,25
.z:     ld (hl),0
        inc hl
        djnz .z
        xor a
        ld (st_clash),a
        ld a,(st_chg)
        or a
        ret z                       ; colours unchanged: no clash
        xor a
        ld (st_j),a
.cj:    xor a
        ld (st_i),a
.ci:    call st_clash1
        jr z,.nx
        ld a,(st_j)
        ld b,a
        add a,a
        add a,a
        add a,b
        ld hl,st_i
        add a,(hl)
        ld e,a
        ld d,0
        ld hl,st_cl
        add hl,de
        ld (hl),1
        ld hl,st_clash
        inc (hl)
.nx:    ld hl,st_i
        inc (hl)
        ld a,(st_ncx)
        cp (hl)
        jr nz,.ci
        ld hl,st_j
        inc (hl)
        ld a,(st_ncy)
        cp (hl)
        jr nz,.cj
        ret

; NZ: cell (st_i, st_j) of the box's cells holds scenery ink outside the mask
st_clash1:
        ld a,(st_bg)
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld hl,gn_pats
        add hl,de
        ex de,hl                    ; DE = the Ground's 8 rows
        ld a,(st_by)
        and 7
        ld b,a
        ld a,(st_j)
        add a,a
        add a,a
        add a,a
        sub b
        ld c,a                      ; C = the figure's row at the cell's first dot row (may be < 0)
        ld b,8
.r:     ld a,c
        bit 7,a
        jr nz,.no
        ld hl,box_h
        cp (hl)
        jr nc,.no
        add a,a
        add a,a
        add a,a
        ld hl,st_i
        add a,(hl)
        ld l,a
        ld h,high st_msk
        ld a,(hl)
        cpl
        jr .g
.no:    ld a,$ff
.g:     ex de,hl
        and (hl)
        ex de,hl
        ret nz
        inc de
        inc c
        djnz .r
        xor a
        ret

; the draw phase: the strip's columns the figure left and entered (all of it after a new Ground),
; ST_BUDGET bytes an update, then their colours; with nothing to draw, the text
st_draw:
        ld a,(st_busy)
        or a
        jp nz,.go
        ld a,(st_go)
        or a
        jp z,print_pending
        xor a
        ld (st_go),a
        inc a
        ld (st_busy),a
        ld a,(st_bfull)
        or a
        jr nz,.all
        ld a,(st_dvalid)
        or a
        jr z,.all
        ld a,(st_dy)                ; rows: from the higher top to the lower bottom
        ld b,a
        ld a,(st_by)
        cp b
        jr c,.r0
        ld a,b
.r0:    ld (st_r0),a
        ld a,(st_dy)
        ld b,a
        ld a,(st_by)
        cp b
        jr nc,.r1
        ld a,b
.r1:    ld hl,box_h
        add a,(hl)
        ld (st_r1),a
        ld a,(st_dx)                ; columns: the left-most byte to the right-most
        ld b,a
        ld a,(st_bx)
        cp b
        jr c,.c0
        ld a,b
.c0:    rrca
        rrca
        rrca
        and $1f
        ld (st_c0),a
        ld a,(st_dx)
        ld b,a
        ld a,(st_bx)
        cp b
        jr nc,.c1
        ld a,b
.c1:    ld hl,box_w
        add a,(hl)
        dec a
        rrca
        rrca
        rrca
        and $1f
        ld hl,st_c0
        sub (hl)
        inc a
        ld (st_nc),a
        jr .top
.all:   xor a
        ld (st_bfull),a
        ld (st_r0),a
        ld (st_c0),a
        ld a,ST_H
        ld (st_r1),a
        ld a,32
        ld (st_nc),a
.top:   ld a,(st_r0)
        ld (st_rt),a
.go:    ld a,(st_bud)
        ld (st_cap),a
        ld a,(st_rbud)
        ld (st_rcap),a
.row:   ld a,(st_r0)
        ld hl,st_r1
        cp (hl)
        jr nc,.attrs
        ld hl,st_nc
        ld a,(st_cap)
        sub (hl)
        ret c                       ; the rest next update
        ld (st_cap),a
        call st_line
        ld hl,st_r0
        inc (hl)
        ld hl,st_rcap
        dec (hl)
        ret z                       ; (rows too: the rest next update)
        jr .row
.attrs: ld a,(st_ast)                ; the cells' colours, once each: about 40 cells an update
        or a
        jr nz,.a0
        inc a
        ld (st_ast),a
        ld a,(st_rt)
        rrca
        rrca
        rrca
        and $1f
        ld (st_cy),a
.a0:    ld a,(st_abud)
        ld (st_acap),a
.ay:    ld a,(st_cy)
        add a,ST_ROW
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld a,(st_c0)
        ld (st_cx),a
        ld e,a
        ld d,$58
        add hl,de
        ld a,(st_nc)
        ld b,a
.ax:    push bc
        push hl
        call st_cattr
        pop hl
        ld (hl),a
        inc hl
        push hl
        ld hl,st_cx
        inc (hl)
        pop hl
        pop bc
        djnz .ax
        ld hl,st_cy
        inc (hl)
        ld a,(hl)
        add a,a
        add a,a
        add a,a
        ld hl,st_r1
        cp (hl)
        jr nc,.adone
        ld hl,st_nc
        ld a,(st_acap)
        sub (hl)
        ret c                       ; the next row of cells next update
        ld (st_acap),a
        cp (hl)
        ret c
        jp .ay
.adone: xor a
        ld (st_ast),a
        ld hl,st_bx                 ; drawn: the snapshot (x, y, facing, frame, Ground, mode, ink)
        ld de,st_dx
        ld bc,7
        ldir
        ld a,1
        ld (st_dvalid),a
        xor a
        ld (st_busy),a
        ret

; strip cell (st_cx, st_cy) -> A = its colour
st_cattr:
        ld a,(st_bx)
        rrca
        rrca
        rrca
        and $1f
        ld b,a
        ld a,(st_cx)
        sub b
        jr c,.g
        ld hl,st_ncx
        cp (hl)
        jr nc,.g
        ld e,a                      ; E = i
        ld a,(st_by)
        rrca
        rrca
        rrca
        and $1f
        ld b,a
        ld a,(st_cy)
        sub b
        jr c,.g
        ld hl,st_ncy
        cp (hl)
        jr nc,.g
        ld b,a
        add a,a
        add a,a
        add a,b
        add a,e
        ld e,a
        ld d,0
        ld hl,st_cl
        add hl,de
        ld a,(hl)
        rrca                        ; a clash: FLASH (D-052)
        ld hl,st_mattr
        or (hl)
        ret
.g:     ld a,(st_gattr)
        ret

; the strip's dot row st_r0, columns st_c0 on for st_nc
st_line:
        ld a,(st_bg)
        add a,a
        add a,a
        add a,a
        ld e,a
        ld a,(st_r0)
        and 7
        add a,e
        ld e,a
        ld d,0
        ld hl,gn_pats
        add hl,de
        ld a,(hl)
        ld (st_g),a
        ld hl,st_lbuf
        ld a,(st_nc)
        ld b,a
        ld a,(st_g)
.f:     ld (hl),a
        inc hl
        djnz .f
        ld a,(st_r0)                ; the figure's row, if this dot row has one
        ld hl,st_by
        sub (hl)
        jr c,.put
        ld hl,box_h
        cp (hl)
        jr nc,.put
        add a,a
        add a,a
        add a,a
        ld c,a                      ; C = the row in st_ink, st_msk
        ld a,(st_bx)
        rrca
        rrca
        rrca
        and $1f
        ld hl,st_c0
        sub (hl)
        ld e,a
        ld d,0
        ld ix,st_lbuf
        add ix,de
        ld a,(bpr)
        inc a
        ld b,a
.b:     ld l,c
        ld h,high st_msk
        ld a,(hl)
        cpl
        ld e,a
        ld a,(st_g)
        and e
        ld h,high st_ink
        or (hl)
        ld (ix+0),a
        inc ix
        inc c
        djnz .b
.put:   ld a,(st_r0)
        add a,ST_Y
        call row_addr
        ld a,(st_c0)
        add a,l
        ld e,a
        ld d,h
        ld hl,st_lbuf
        ld a,(st_nc)
        ld c,a
        ld b,0
        ldir
        ret

; ---------------------------------------------------------------- the page's text
; the readouts (rows 17-20) and the Ground's name, into their panels (drawn by panel_diff)
gt_compose:
        ld hl,gt_want
        ld de,gt_want+1
        ld bc,GT_W*GT_H-1
        ld (hl),' '
        ldir
        ld de,gt_want
        ld a,(mk_need)              ; the masks still to work out: say so (m5-r2 F-47)
        ld hl,mk_st
        or (hl)
        jr z,.cl
        ld hl,s_gt_wait
        call put_str
        jr .row1
.cl:    ld hl,s_gt_cells
        call put_str
        ld a,(st_ncx)
        ld b,a
        ld a,(st_ncy)
        call st_mul
        call put_num
        ld de,gt_want+13
        ld hl,s_gt_most
        call put_str
        ld a,(box_w)
        call st_most1
        ld b,a
        ld a,(box_h)
        call st_most1
        call st_mul
        call put_num
        ld de,gt_want+21
        ld hl,s_gt_clash
        call put_str
        ld a,(st_clash)
        call put_num
.row1:  ld de,gt_want+GT_W          ; C:COLOUR mode   I:INK colour
        ld hl,s_gt_mode
        call put_str
        ld a,(cmode)
        ld hl,s_modes
        call st_pick
        call put_str
        ld de,gt_want+GT_W+17
        ld hl,s_gt_ink
        call put_str
        ld a,(fig_ink)
        ld hl,s_colours
        call st_pick
        call put_str
        ld de,gt_want+2*GT_W        ; W:WALK on/off  S:STEP n  QAOP:MOVE
        ld hl,s_gt_walk
        call put_str
        ld a,(wk_on)
        ld hl,s_onoff
        call st_pick
        call put_str
        ld de,gt_want+2*GT_W+12
        ld hl,s_gt_step
        call put_str
        ld a,(wk_step)
        ld c,a
        ld b,0
        ld hl,wk_steps
        add hl,bc
        ld a,(hl)
        call put_num
        ld a,(wk_on)
        or a
        jr nz,.ck
        ld de,gt_want+2*GT_W+22
        ld hl,s_gt_move
        call put_str
.ck:    ld de,gt_want+3*GT_W        ; the figure's checks
        ld a,(fig_flags)
        or a
        jr nz,.c1
        ld hl,s_gt_none
        call put_str
        jr .name
.c1:    bit 0,a
        jr z,.c2
        ld hl,s_gt_hard
        call put_str
        inc de
        inc de
.c2:    ld a,(fig_flags)
        bit 1,a
        jr z,.name
        ld hl,s_far
        call put_str
.name:  ld de,gl_want                ; the key line
        ld hl,s_gleg_keys
        call put_str
        ld a,(play_on)
        or a
        jr z,.nm
        ld de,gl_want+11
        ld hl,s_gleg_stop
        call put_str
.nm:    ld a,(gn_ground)            ; the Ground's name
        ld hl,gn_names
        call st_pick
        ld de,gn_want
        call put_str
        ld a,(les_tg)               ; a lesson's caption (DEMO-01)
        or a
        jr z,.nc
        ld de,gt_want+4*GT_W
        ld hl,les_cap
        call put_str
.nc:    ld a,(txt_pend)
        or 7
        ld (txt_pend),a
        ret

; A = index, HL = a table of string addresses -> HL = the string
st_pick:
        add a,a
        add a,l
        ld l,a
        jr nc,.n
        inc h
.n:     ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ret

; A x B -> A (small numbers)
st_mul:
        ld c,a
        xor a
        inc b
.m:     dec b
        ret z
        add a,c
        jr .m

; A = a box side in dots -> the most cells it can touch: (side + 6) / 8 + 1
st_most1:
        add a,6
        rrca
        rrca
        rrca
        and $1f
        inc a
        ret

gn_text:
        db 0,1,"THE TEST GROUND",0
        db 0,19,"GROUND:",0
        db 3,GN_FIRST,"COPY",0
        db 3,GN_FIRST+GN_STEP,"MIX",0
        db 3,GN_FIRST+2*GN_STEP,"MASK+MIX",0
        db 10,0,"MASK+MIX IN COLOUR BLOCKS:",0
        db $ff
s_gleg_keys: db "H:GROUND G:PLAY R:RUB OUT T:BACK",0
fl_text:
        db 0,1,"THE TEST GROUND",0
        db 0,19,"GROUND:",0
        db 3,0,"RUB OUT, DRAW",0
        db 10,0,"DRAW ONCE",0
        db $ff
s_gleg_stop: db "STOP",0
s_gt_cells: db "CELLS NOW ",0
s_gt_wait:  db "WORKING OUT THE MASKS...",0
s_gt_most:  db "MOST ",0
s_gt_clash: db "CLASHES ",0
s_gt_mode:  db "C:COLOUR ",0
s_gt_ink:   db "I:INK ",0
s_gt_walk:  db "W:WALK ",0
s_gt_step:  db "S:STEP ",0
s_gt_move:  db "QAOP:1 DOT",0
s_gt_none:  db "CHECKS: NONE",0
s_gt_hard:  db "HARD TO SEE",0
s_modes:    dw s_m0,s_m1,s_m2
s_m0:       db "KEEP",0
s_m1:       db "INK",0
s_m2:       db "BOX",0
s_onoff:    dw s_off,s_on
s_off:      db "OFF",0
s_on:       db "ON",0
s_colours:  dw s_c0,s_c1,s_c2,s_c3,s_c4,s_c5,s_c6,s_c7
s_c0:       db "BLACK",0
s_c1:       db "BLUE",0
s_c2:       db "RED",0
s_c3:       db "MAGENTA",0
s_c4:       db "GREEN",0
s_c5:       db "CYAN",0
s_c6:       db "YELLOW",0
s_c7:       db "WHITE",0
st_lbuf:    ds 34
        ALIGN 256
st_ink:     ds 256                  ; the shifted figure: row r at r * 8, bpr + 1 bytes
st_msk:     ds 256

; ---------------------------------------------------------------- RUB OUT, DRAW (FLICK-01, D-071)
; With R the panels give way to a second copy of the walk drawn the naive way: when the figure moves, its old
; place is put back to scenery and shown for a frame, then the figure is drawn in its new place. It copies
; each new snapshot's shifted rows (fl_ink, fl_msk) when it is free, so it never holds the DRAW ONCE strip up
; (it skips the places it is busy for). Both copies are in Keep, so the order of drawing is the only difference.
fl_take:
        ld a,(fl_on)
        or a
        ret z
        ld a,(fl_state)
        or a
        ret nz                      ; still showing the last one: this place is skipped
        ld a,(box_h)
        add a,a
        add a,a
        add a,a
        ld c,a
        ld b,0
        ld a,c
        or a
        jr nz,.n
        inc b                       ; (32 rows: 256 bytes)
.n:     push bc
        ld hl,st_ink
        ld de,fl_ink
        ldir
        pop bc
        ld hl,st_msk
        ld de,fl_msk
        ldir
        ld a,(st_bx)
        ld (fl_nx),a
        ld a,(st_by)
        ld (fl_ny),a
        ld a,(st_bdir)
        ld (fl_ndir),a
        ld a,(st_bf)
        ld (fl_nf),a
        ld a,1
        ld (fl_state),a
        ret

; the copy's strip all Ground (on entering the page), its colours the Ground's
fl_ground:
        ld a,(gn_ground)
        ld e,a
        ld d,0
        ld hl,gn_attrs
        add hl,de
        ld a,(hl)
        ld de,FL_Y/8*256
        ld bc,32*256+6
        call fill_attr
        xor a
        ld (fl_r),a
.r:     call fl_grow                ; A = the Ground's byte for the row
        ld b,32
.c:     ld (hl),a
        inc l
        djnz .c
        ld hl,fl_r
        inc (hl)
        ld a,(hl)
        cp ST_H
        jr c,.r
        ret

; fl_r = a row of the copy's strip -> HL = its screen address, A = the Ground's byte for it
fl_grow:
        ld a,(gn_ground)
        add a,a
        add a,a
        add a,a
        ld e,a
        ld a,(fl_r)
        and 7
        add a,e
        ld e,a
        ld d,0
        ld hl,gn_pats
        add hl,de
        ld c,(hl)
        ld a,(fl_r)
        add a,FL_Y
        call row_addr
        ld a,c
        ret

; the draw phase: 1, the old place back to scenery (shown); 2, the next update, the figure in its new place
fl_draw:
        ld a,(fl_state)
        cp 1
        jr nz,.draw
        ld a,2
        ld (fl_state),a
        ld a,(fl_valid)
        or a
        ret z                       ; nothing drawn yet: nothing to rub out
        ld a,(fl_oy)                ; rub out: the old box's bytes, scenery
        ld (fl_r),a
        ld a,(box_h)
        ld (fl_n),a
.er:    call fl_grow
        ld b,a
        ld a,(fl_ox)
        rrca
        rrca
        rrca
        and $1f
        add a,l
        ld l,a
        ld a,(bpr)
        inc a
        ld c,a
        ld a,(fl_ox)                ; (bpr + 1 bytes, but not past the right edge)
        and 7
        jr nz,.e1
        dec c
.e1:    ld a,b
.e2:    ld (hl),a
        inc l
        dec c
        jr nz,.e2
        ld hl,fl_r
        inc (hl)
        ld hl,fl_n
        dec (hl)
        jr nz,.er
        ret
.draw:  ld a,(fl_ny)                ; draw: the figure's rows, MASK+MIX over the scenery
        ld (fl_r),a
        xor a
        ld (fl_k),a
.dr:    call fl_grow
        ld (st_g),a
        ld a,(fl_nx)
        rrca
        rrca
        rrca
        and $1f
        add a,l
        ld l,a
        ex de,hl                    ; DE = the screen
        ld a,(fl_k)
        add a,a
        add a,a
        add a,a
        ld c,a
        ld a,(bpr)
        inc a
        ld b,a
        ld a,(fl_nx)
        and 7
        jr nz,.d1
        dec b
.d1:    ld l,c
        ld h,high fl_msk
        ld a,(hl)
        cpl
        ld l,a
        ld a,(st_g)
        and l
        ld l,c
        ld h,high fl_ink
        or (hl)
        ld (de),a
        inc e
        inc c
        djnz .d1
        ld hl,fl_r
        inc (hl)
        ld hl,fl_k
        inc (hl)
        ld a,(box_h)
        cp (hl)
        jr nz,.dr
        ld a,(fl_nx)                ; drawn: this is the place to rub out next time
        ld (fl_ox),a
        ld a,(fl_ny)
        ld (fl_oy),a
        ld a,(fl_ndir)
        ld (fl_odir),a
        ld a,(fl_nf)
        ld (fl_of),a
        ld a,1
        ld (fl_valid),a
        xor a
        ld (fl_state),a
        ret

fl_r:       db 0
fl_n:       db 0
fl_k:       db 0
fl_nx:      db 0
fl_ny:      db 0
fl_ndir:    db 0
fl_nf:      db 0
        ALIGN 256
fl_ink:     ds 256
fl_msk:     ds 256
