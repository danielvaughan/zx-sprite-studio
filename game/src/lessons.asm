; (the Lessons page and its setups: bank 6, paged in by bank6_call, D-072)
; ---------------------------------------------------------------- the Lessons (DEMO-01)
; A page of the Desk (state 1, phase 5; 0, or LESSONS in the FIGURE drawer): the drawing chapter's lessons,
; one a line. QA moves the bar, ENTER (SPACE with keys, a second click with the pointer) sets the Desk up for
; the lesson: the Library's Mower in the lessons' own figure on the sheet (added the first time, so the
; reader's figure is kept), everything the lessons touch put back as it starts, then the lesson's own
; settings, and its caption on the status line (or the Test Ground's last readout line). T or 0 goes back.

LS_N    equ 6
LS_ROW  equ 3                       ; the list: rows 3-8
ls_want equ grid_want               ; the list, 6 x 32
lsc_want equ grid_want+LS_N*32       ; the lesson under the bar, said in a line (row 11)

les_panels:
        dw ls_want, grid_have
        db 0,LS_ROW,32,LS_N
        dw lsc_want, grid_have+LS_N*32
        db 0,11,32,1
N_LS_PANELS equ 2

g6_lessons:
        ld a,3                      ; (gn_open 3: the Lessons page in bank 6)
        ld (gn_open),a
        ld a,1
        ld (sfx_req),a
        ld a,5
        ld (phase),a
        call lock_buttons
        call new_screen
        ld hl,les_panels
        ld (pd_table),hl
        ld a,N_LS_PANELS
        ld (pd_count),a
        ld hl,grid_want
        ld de,grid_want+1
        ld bc,1023
        ld (hl),' '
        ldir
        xor a
        ld (txt_pend),a
        ld (pend_n),a
        ld hl,les_text
        call print_list
        ld a,AT_DEFAULT
        call set_attrs
        ld de,$0001
        ld bc,$0b01
        ld a,AT_HEAD
        call fill_attr
        ld a,$ff
        ld (sh_bar_have),a
        jp les_compose

les_close:
        xor a
        ld (gn_open),a
        inc a
        ld (phase),a
        ld (sfx_req),a
        call lock_buttons
        call drawer_dirty
        jp draw_desk

les_logic:
        ld a,(FRESH1)
        bit K_TITLE,a               ; T, or 0 again: back
        jr nz,les_close
        ld a,(FRESH5)
        bit K_LESSONS,a
        jr nz,les_close
        ld a,(FRESH1)
        ld c,a
        bit K_UP,c
        jr z,.d
        ld a,(les_sel)
        or a
        jr z,.d
        dec a
        ld (les_sel),a
        call les_compose
.d:     bit K_DOWN,c
        jr z,.o
        ld a,(les_sel)
        cp LS_N-1
        jr nc,.o
        inc a
        ld (les_sel),a
        call les_compose
.o:     bit K_SEC,c                 ; ENTER
        jr nz,.go
        bit K_PRIM,c
        jr z,.t
        ld a,(input_dev)
        cp DEV_MOUSE
        jr nz,.go                   ; SPACE with keys
        ld a,(cur_y)                ; a click: on a line chooses it, on the chosen line opens it
        rrca
        rrca
        rrca
        and $1f
        sub LS_ROW
        jr c,.t
        cp LS_N
        jr nc,.t
        ld hl,les_sel
        cp (hl)
        jr z,.go
        ld (hl),a
        call les_compose
        jr .t
.go:    ld a,(les_sel)
        jp les_open
.t:     ld a,(input_dev)
        cp DEV_MOUSE
        call z,move_cursor
        ld a,(txt_pend)
        or a
        ret z
        jp panel_diff

les_compose:
        ld hl,grid_want
        ld de,grid_want+1
        ld bc,LS_N*32+32-1
        ld (hl),' '
        ldir
        ld de,ls_want
        ld b,0
.l:     push bc
        push de
        ld a,b
        ld hl,les_names
        call st_pick
        call put_str
        pop de
        ld hl,32
        add hl,de
        ex de,hl
        pop bc
        inc b
        ld a,b
        cp LS_N
        jr c,.l
        ld a,(les_sel)
        ld hl,les_caps
        call st_pick
        ld de,lsc_want
        call put_str
        ld a,(txt_pend)
        or 3
        ld (txt_pend),a
        ret

les_draw:
        ld a,(les_sel)
        ld hl,sh_bar_have
        cp (hl)
        jp z,print_pending
        ld c,(hl)
        ld (hl),a
        ld b,a
        ld a,c
        cp $ff
        jr z,.new
        add a,LS_ROW
        ld d,a
        ld e,0
        push bc
        ld bc,32*256+1
        ld a,AT_DEFAULT
        call fill_attr
        pop bc
.new:   ld a,b
        add a,LS_ROW
        ld d,a
        ld e,0
        ld bc,32*256+1
        ld a,AT_MARK
        jp fill_attr

; A = a lesson -> the Desk (or the Test Ground) set up for it
les_open:
        ld (les_k),a
        ld a,(les_slot)             ; the lessons' own figure on the sheet
        cp $ff
        jr z,.new
        ld hl,sh_count
        cp (hl)
        jr nc,.new
        ld hl,sh_cur
        cp (hl)
        jr z,.here
        call sh_switch
        jr .here
.new:   call sh_add                 ; (the sheet full: the current figure is used, Undo keeps it)
        ld a,0
        jr c,.full
.here:  ld a,1
.full:  ld (les_own),a
        xor a                       ; everything the lessons touch, as it starts
        ld (gn_open),a
        ld (layer),a
        ld (onion_on),a
        ld (play_on),a
        ld (play_frame),a
        ld (cmode),a
        ld (wk_on),a
        ld (wk_play),a
        ld (fl_on),a
        ld (chk_wait),a
        ld (gn_ground),a
        inc a
        ld (wk_step),a
        ld a,PLAY_DEFAULT
        ld (play_lvl),a
        call play_reload
        call les_mower              ; the Mower (the Library's own, with its game's mask)
        ld a,(les_own)              ; the lessons' own figure (opening the Mower counts as a change:
        or a                        ; mark it theirs again after)
        jr z,.cap
        ld a,(sh_cur)
        ld (les_slot),a
.cap:
        ld a,(les_k)                ; the caption
        ld hl,les_caps
        call st_pick
        ld de,les_cap
        call put_str
        xor a
        ld (de),a
        ld a,(les_k)
        ld hl,les_sets
        call st_pick
        jp (hl)

les_desk:                           ; the Desk again, with the caption on the status line
        ld a,EV_LESSON
        ld (last_event),a
        call draw_desk
        ld a,(txt_dirty)
        or 15
        ld (txt_dirty),a
        ret

les_1:  ld a,2                      ; rows of dots: the cursor on row 1 (its Row Codes marked)
        ld (gc_col),a
        ld a,1
        ld (gc_row),a
        call gc_pixels
        call calc_square
        jr les_desk
les_2:  ld a,1                      ; a second frame: tracing paper on, the flip-book playing
        ld (onion_on),a
        ld (play_on),a
        jr les_desk
les_3:  ld a,1                      ; three ways to put it down: the Test Ground on grass
        ld (les_tg),a
        jp g6_enter
les_4:  ld a,1                      ; the mask and its ring: the Mask layer, Ring worked out
        ld (layer),a
        xor a
        ld (mstyle),a
        call mask_all
        jr les_desk
les_5:  ld a,1                      ; why drawing flickers: both copies, walking
        ld (fl_on),a
        ld (wk_on),a
        ld (wk_play),a
        ld (play_on),a
        ld (les_tg),a
        jp g6_enter
les_6:  ld a,1                      ; colour belongs to the cell: Ink mode, a dot off the cell grid
        ld (cmode),a
        ld (les_tg),a
        call g6_enter
        ld hl,st_tx
        inc (hl)
        ld hl,st_ty
        inc (hl)
        ret

les_sets:   dw les_1,les_2,les_3,les_4,les_5,les_6
les_names:  dw ln1,ln2,ln3,ln4,ln5,ln6
ln1:        db "1 A FIGURE IS ROWS OF DOTS",0
ln2:        db "2 A SECOND FRAME",0
ln3:        db "3 THREE WAYS TO PUT IT DOWN",0
ln4:        db "4 THE MASK AND ITS RING",0
ln5:        db "5 WHY DRAWING FLICKERS",0
ln6:        db "6 COLOUR BELONGS TO THE CELL",0
les_caps:   dw lc1,lc2,lc3,lc4,lc5,lc6
lc1:        db "1: ROW 1 IS 28 00, TWO BYTES",0
lc2:        db "2: TRACING PAPER ON, PLAYING",0
lc3:        db "3: COPY, MIX, MASK THEN MIX",0
lc4:        db "4: RING MASK. F TWICE: BOX",0
lc5:        db "5: WATCH RUB OUT, DRAW BLINK",0
lc6:        db "6: INK MODE: CLASHES FLASH",0
les_text:
        db 0,1,"THE LESSONS",0
        db 1,0,"FROM THE DRAWING CHAPTER:",0
        db 22,0,"QA:CHOOSE ENTER:SHOW   T:BACK",0
        db $ff
les_k:      db 0
les_own:    db 0                    ; the lesson is in the lessons' own figure
les_tg:     db 0                    ; the Test Ground shows the lesson's caption
