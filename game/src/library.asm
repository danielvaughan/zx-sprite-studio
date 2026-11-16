; ---------------------------------------------------------------- the Library (LIB-01)
; The studio's own figures, by game (src/gen: tools/build_library.py, from the games' .spr files).
; Bank 1 holds a 32-byte record for each line of the list (a game, a character, a figure), then
; the frames. The Library is a page of the Desk (state 1, phase 2): the list on the left, the
; chosen figure flipping at true size on the right. Its text uses the Desk's panel drawing, its
; want/have kept in the Grid's tables (free while the Library shows: the Desk redraws them all).

LIB_INDEX_BANK  equ 1
LIB_ROWS        equ 20              ; list lines shown, rows 2-21
LIB_W           equ 16              ; list width, cols 1-16
LI_W            equ 14              ; about the chosen figure: cols 18-31, rows 9-12
LI_H            equ 4
LIB_ANIM        equ 8               ; the preview turns a page every 0.16 s
ll_want         equ grid_want
li_want         equ ll_want+LIB_W*LIB_ROWS
LIB_TEXT        equ LIB_W*LIB_ROWS+LI_W*LI_H
        ASSERT LIB_TEXT <= 512
        ASSERT LIB_LINES < 256

lib_panels:
        dw ll_want, grid_have
        db 1,2,LIB_W,LIB_ROWS
        dw li_want, grid_have+LIB_W*LIB_ROWS
        db 18,9,LI_W,LI_H
N_LIB_PANELS equ 2

; A = bank at $C000 (keeps BC, DE, HL)
page_bank:
        or ROM48
        ld (bank_shadow),a
        push bc
        ld bc,BANK_PORT
        out (c),a
        pop bc
        ret
page_home:
        ld a,(cur_bank)         ; (0, or 6 while the Test Ground's code runs)
        jr page_bank

; A = line -> HL = its record in the index bank (not paged in)
lib_rec:
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,$c000
        add hl,de
        ret

; A = line -> A = its kind (0 game, 1 character, 2 figure)
lib_kind:
        call lib_rec
        ld a,LIB_INDEX_BANK
        call page_bank
        ld b,(hl)
        call page_home
        ld a,b
        ret

; the Desk's L, or LIBRARY in the FIGURE drawer: the Library page
act_lib:
lib_enter:
        ld a,1
        ld (lib_open),a
        inc a
        ld (phase),a
        ld a,1
        ld (sfx_req),a
        call lock_buttons
        call new_screen
        ld hl,lib_text
        call print_list
        ld hl,s_lleg_keys
        ld de,s_lleg_ms
        call draw_legend
        ld a,AT_DEFAULT
        call set_attrs
        ld de,$0001
        ld bc,$0b01
        ld a,AT_HEAD
        call fill_attr
        ld de,$0316             ; the preview card, white
        ld bc,$0404
        ld a,AT_CANVAS
        call fill_attr
        ld hl,lib_panels
        ld (pd_table),hl
        ld a,N_LIB_PANELS
        ld (pd_count),a
        ld hl,grid_have
        ld de,grid_have+1
        ld bc,LIB_TEXT-1
        ld (hl),' '
        ldir
        xor a
        ld (txt_pend),a
        ld (pend_n),a
        ld a,$ff
        ld (lib_bar_have),a
        ld a,(lib_sel)          ; the line last chosen, else the Mower
        call lib_kind
        cp 2
        jr z,lib_chosen
        ld a,LIB_MOWER
        ld (lib_sel),a
; the chosen line changed: keep it in view, read it, start its preview
lib_chosen:
        ld a,(lib_sel)
        ld hl,lib_top
        sub (hl)
        jr c,.up
        cp LIB_ROWS-2
        jr c,.read
        ld a,(lib_sel)          ; below the window: it shows third from the bottom
        sub LIB_ROWS-3
        cp LIB_LINES-LIB_ROWS+1
        jr c,.top
        ld a,LIB_LINES-LIB_ROWS
        jr .top
.up:    ld a,(lib_sel)          ; above: second from the top
        sub 1
        jr nc,.top
        xor a
.top:   ld (lib_top),a
.read:  ld a,(lib_sel)
        call lib_rec
        ld a,LIB_INDEX_BANK
        call page_bank
        ld de,lib_now
        ld bc,32
        ldir
        call page_home
        xor a
        ld (lib_frame),a
        ld a,LIB_ANIM
        ld (lib_t),a
        ld a,1
        ld (lib_prev),a
        ld a,(txt_dirty)
        or 3
        ld (txt_dirty),a
        ret

lib_close:
        xor a
        ld (lib_open),a
        inc a
        ld (phase),a
        ld (sfx_req),a
        call lock_buttons
        jp draw_desk

; ---- the Library page's update
lib_logic:
        ld a,(FRESH1)
        bit K_TITLE,a           ; T: back to the Desk, nothing changed
        jr nz,lib_close
        ld a,(FRESH2)
        bit K_LIB,a
        jr nz,lib_close
        ld a,(input_dev)
        cp DEV_MOUSE
        jr nz,.keys
        call move_cursor        ; the Arrow
        call lib_keys           ; (the keys choose too, whatever the input: m4-settle-open)
        ld a,(FRESH1)
        bit K_PRIM,a
        call nz,lib_click
        jr .anim0
.keys:  call lib_keys
        ld a,(FRESH1)
        bit K_PRIM,a
        jp nz,lib_open_fig
.anim0: ld a,(FRESH1)           ; ENTER opens the chosen figure, keys or pointer
        bit K_SEC,a
        jp nz,lib_open_fig
.anim:  ld a,(lib_open)         ; (a click may have opened a figure)
        or a
        ret z
        ld hl,lib_t             ; the preview flips through the figure's frames
        dec (hl)
        jr nz,.text
        ld (hl),LIB_ANIM
        ld a,(lib_now+25)
        ld b,a
        ld a,(lib_frame)
        inc a
        cp b
        jr c,.f
        xor a
.f:     ld hl,lib_frame
        cp (hl)
        jr z,.text
        ld (hl),a
        ld a,1
        ld (lib_prev),a
.text:  ld a,(txt_dirty)
        or a
        jr z,.pend
        rra
        push af
        call c,compose_lib_list
        pop af
        rra
        call c,compose_lib_info
        ld a,(txt_dirty)
        ld hl,txt_pend
        or (hl)
        ld (hl),a
        xor a
        ld (txt_dirty),a
.pend:  ld a,(txt_pend)
        or a
        ret z
        jp panel_diff

; Q A: the figure before or after; O P: the first figure of the game before or after (with repeat)
lib_keys:
        ld a,(EFF1)
        and $0f
        ld c,a
        or a
        jr nz,.held
        ld (rep_dirs),a
        ret
.held:  ld hl,rep_dirs
        cp (hl)
        jr z,.same
        ld (hl),a
        ld a,REP_DELAY
        ld (rep_t),a
        jr .go
.same:  ld hl,rep_t
        dec (hl)
        ret nz
        ld (hl),REP_TIME
.go:    ld hl,steer_n
        inc (hl)
        ld b,1
        bit K_DOWN,c
        jr nz,lib_step
        ld b,-1
        bit K_UP,c
        jr nz,lib_step
        bit K_LEFT,c
        jr nz,lib_game_back
        bit K_RIGHT,c
        ret z
; the first figure of the next game
lib_game_next:
        ld a,(lib_sel)
.l:     inc a
        cp LIB_LINES
        ret nc
        push af
        call lib_kind
        or a
        pop bc
        ld a,b
        jr nz,.l
        ld b,1                  ; the game's heading: its first figure is next
        jr lib_step_from
; the first figure of this game (or, there already, of the game before)
lib_game_back:
        ld a,(lib_sel)
        call lib_game_head
        ld (lib_head),a
        inc a
        ld b,1
        call lib_find           ; this game's first figure
        ld hl,lib_sel
        cp (hl)
        jr nz,.set
        ld a,(lib_head)         ; already there: the game before
        or a
        ret z
        dec a
        call lib_game_head
        inc a
        ld b,1
        call lib_find
.set:   ld (lib_sel),a
        jp lib_chosen

; A = line -> A = the heading line of its game
lib_game_head:
.l:     push af
        call lib_kind
        or a
        pop bc
        ld a,b
        ret z
        dec a
        jr .l

; B = +1 or -1: the next figure that way (none: stay)
lib_step:
        ld a,(lib_sel)
lib_step_from:
        add a,b
        cp LIB_LINES
        ret nc
        call lib_find
        ret c
        ld (lib_sel),a
        jp lib_chosen

; A = line, B = +1 or -1 -> A = the first figure line from it that way; carry if none
lib_find:
.l:     cp LIB_LINES
        ccf
        ret c
        push af
        push bc
        call lib_kind
        pop bc
        cp 2
        jr z,.f
        pop af
        add a,b
        jr .l
.f:     pop af
        or a
        ret

; the pointer: a press on a list line chooses it; on the chosen line, opens it
lib_click:
        ld a,(cur_x)
        cp 8
        ret c
        cp 8+LIB_W*8
        ret nc
        ld a,(cur_y)
        sub 16
        ret c
        cp LIB_ROWS*8
        ret nc
        rrca
        rrca
        rrca
        and 31
        ld hl,lib_top
        add a,(hl)
        cp LIB_LINES
        ret nc
        ld hl,lib_sel
        cp (hl)
        jr z,lib_open_fig
        ld c,a
        call lib_kind
        cp 2
        ret nz
        ld a,c
        ld (lib_sel),a
        jp lib_chosen

; open the chosen figure: a copy into the sheet, one Undo step
lib_open_fig:
        ld a,(lib_now)
        cp 2
        ret nz
        call snapshot
        ld a,(lib_now+25)
        ld (nframes),a
        xor a
        ld (cur_frame),a
        ld (play_frame),a
        ld (onion_on),a
        ld a,(lib_now+23)
        ld (box_w),a
        ld a,(lib_now+24)
        ld (box_h),a
        call box_derive
        ld hl,lib_now+15
        ld de,fig_name
        ld bc,8
        ldir
        xor a
        ld (de),a
        ld a,(nframes)
        call frames_bytes
        ld hl,(lib_now+27)
        ld de,frames_data
        ld a,(lib_now+26)
        call page_bank
        ldir
        ld a,(lib_now+31)       ; the game's own masks follow the frames: to frames 8 on
        or a
        jr z,.nm
        push hl
        ld a,(nframes)
        call frames_bytes
        push bc
        ld a,MAX_FRAMES
        call frame_ptr
        ex de,hl
        pop bc
        pop hl
        ldir
.nm:    call page_home
        ld a,(lib_now+29)
        ld (fig_game),a
        ld a,(lib_now+31)
        or a
        ld a,MS_RING            ; its masks worked out afresh (D-044) ...
        jr z,.st
        xor a                   ; ... or its game's own, as Hand (M5): nothing to work out
        ld (mk_need),a
        ld (mk_st),a
        ld a,MS_HAND
.st:    ld (mstyle),a
        ld a,(lib_now+30)       ; its ink colour (CLASH-01)
        ld (fig_ink),a
        call fig_check
        xor a
        ld (lib_open),a
        ld (check_on),a
        inc a
        ld (phase),a
        call lock_buttons
        call fix_play
        ld a,EV_OPENED
        ld (last_event),a
        ld a,1
        ld (sfx_req),a
        call draw_desk
        jp drawer_dirty

; the list: games at the left, their characters one in, figures two in
compose_lib_list:
        ld hl,ll_want
        ld de,ll_want+1
        ld bc,LIB_W*LIB_ROWS-1
        ld (hl),' '
        ldir
        ld a,LIB_INDEX_BANK
        call page_bank
        ld a,(lib_top)
        ld c,a
        ld de,ll_want
        ld b,LIB_ROWS
.l:     push bc
        push de
        ld a,c
        cp LIB_LINES
        jr nc,.n
        call lib_rec            ; (corrupts DE)
        pop de
        push de
        ld a,(hl)               ; kind = indent
        add a,e
        ld e,a
        jr nc,.i
        inc d
.i:     inc hl
        ld a,(hl)
        cp ' '                  ; (the text, until its trailing spaces)
        jr c,.n
        ld bc,14
        ldir
.n:     pop de
        ld hl,LIB_W
        add hl,de
        ex de,hl
        pop bc
        inc c
        djnz .l
        jp page_home

; about the chosen figure: its game, character, name, box and frames
compose_lib_info:
        ld hl,li_want
        ld de,li_want+1
        ld bc,LI_W*LI_H-1
        ld (hl),' '
        ldir
        ld a,(lib_now+29)
        call lib_game_name
        ld de,li_want
        call put_str
        ld hl,lib_now+15
        ld de,li_want+LI_W
        ld b,8
.c:     ld a,(hl)
        or a
        jr z,.cn
        ld (de),a
        inc hl
        inc de
        djnz .c
.cn:    ld hl,lib_now+1
        ld de,li_want+2*LI_W
        ld bc,8
        ldir
        ld de,li_want+3*LI_W
        ld a,(lib_now+23)
        call put_num
        ld a,'X'
        ld (de),a
        inc de
        ld a,(lib_now+24)
        call put_num
        inc de
        ld a,(lib_now+25)
        call put_num
        ld a,(lib_now+25)
        dec a
        ld hl,s_frames
        jp nz,put_str
        ld hl,s_frame1
        jp put_str

; A = game -> HL = its name
lib_game_name:
        ld hl,lib_games
        or a
        ret z
        ld b,a
.l:     ld a,(hl)
        inc hl
        or a
        jr nz,.l
        djnz .l
        ret

; ---- the Library page's draw: the chosen line's bar, the preview, the text
lib_draw:
        ld a,(lib_sel)
        ld hl,lib_top
        sub (hl)
        ld hl,lib_bar_have
        cp (hl)
        jr z,.prev
        ld c,(hl)
        ld (hl),a
        ld b,a
        ld a,c
        cp $ff
        jr z,.new
        add a,2
        ld d,a
        ld e,1
        push bc
        ld bc,LIB_W*256+1       ; 16 wide, 1 high
        ld a,AT_DEFAULT
        call fill_attr
        pop bc
.new:   ld a,b
        cp LIB_ROWS
        jr nc,.prev
        add a,2
        ld d,a
        ld e,1
        ld bc,LIB_W*256+1
        ld a,AT_MARK
        call fill_attr
.prev:  ld a,(lib_prev)
        or a
        jp z,print_pending
        call lib_preview
        ld a,(input_dev)        ; with the pointer the text waits (kept queued) when the preview was
        cp DEV_MOUSE            ; drawn, so the Arrow is back before the beam (as img_heavy)
        ret z
        jp print_pending

; the chosen figure's frame lib_frame at true size, centred in the card (cols 22-25, rows 3-6)
lib_preview:
        xor a
        ld (lib_prev),a
        ld a,(lib_now+23)       ; bytes a row
        rrca
        rrca
        rrca
        and $1f
        ld (lib_bpr),a
        ld b,a
        ld a,(lib_now+24)
        ld c,a
        xor a
.m:     add a,c
        djnz .m
        ld (lib_fb),a           ; bytes a frame
        ld e,a                  ; this frame's bytes into lib_fbuf
        ld d,0
        ld hl,(lib_now+27)
        ld a,(lib_frame)
        or a
        jr z,.cp
        ld b,a
.f:     add hl,de
        djnz .f
.cp:    ld b,d
        ld c,e
        ld de,lib_fbuf
        ld a,(lib_now+26)
        call page_bank
        ldir
        call page_home
        ld a,(lib_bpr)          ; across: (4 - bytes) / 2 cells in
        ld b,a
        ld a,4
        sub b
        srl a
        ld (lib_ox),a
        ld a,(lib_now+24)       ; down: (32 - rows) / 2 dots in
        ld b,a
        ld a,32
        sub b
        srl a
        ld (lib_oy),a
        ld c,0                  ; card row
.row:   ld hl,im_buf
        xor a
        ld (hl),a
        inc hl
        ld (hl),a
        inc hl
        ld (hl),a
        inc hl
        ld (hl),a
        ld a,c
        ld hl,lib_oy
        sub (hl)
        jr c,.put
        ld hl,lib_now+24
        cp (hl)
        jr nc,.put
        ld e,a                  ; figure row -> its bytes
        ld d,0
        ld hl,lib_fbuf
        ld a,(lib_bpr)
        ld b,a
.r:     add hl,de
        djnz .r
        ld a,(lib_ox)
        ld e,a
        push hl
        ld hl,im_buf
        add hl,de
        ex de,hl
        pop hl
        push bc
        ld a,(lib_bpr)
        ld c,a
        ld b,0
        ldir
        pop bc
.put:   ld a,c
        add a,24                ; card top: pixel row 24
        push bc
        call row_addr
        ld a,l
        add a,22
        ld l,a
        ld de,im_buf
        ex de,hl
        ldi
        ldi
        ldi
        ldi
        pop bc
        inc c
        ld a,c
        cp 32
        jr nz,.row
        ret

lib_text:
        db 0,1,"THE LIBRARY",0
        db 0,14,"FIGURES BY GAME",0
        db 1,18,"TRUE SIZE",0
        db 23,0,"T,L:BACK  OPEN REPLACES THE DESK",0
        db $ff
s_frames:   db " FRAMES",0
s_frame1:   db " FRAME",0
s_opened:   db "OPENED: ",0
