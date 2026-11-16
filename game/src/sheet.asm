; (the Sheet page's code and texts: bank 6, paged in by bank6_call, D-061)
; ---------------------------------------------------------------- the Sheet (SHEET-01)
; A page of the Desk (state 1, phase 4; 9, or SHEET in the FIGURE drawer): the sheet's figures, one a
; line, and "NEW FIGURE" while there is room (T-FIGURES 8). QA (or the stick) moves the bar; ENTER or
; SPACE opens the figure under it (the current one is marked *), or adds a new one. The figures' heads
; are in sh_heads, their frames and masks in sh_bank (resident: sh_store, sh_fetch, sh_add). The text is
; two panels (the Grid's tables are free while this page shows); the bar is drawn in the draw phase.

SH_ROW  equ 2                       ; the list: rows 2-9
SI_ROW  equ 11                      ; about the current figure and the sheet: rows 11-18
SI_H    equ 8
sl_want equ grid_want               ; the list, 8 x 32
si_want equ grid_want+8*32          ; the rest, SI_H x 32
SA_OPEN equ 0                       ; the page's actions (sh_keys)
SA_NEW  equ 1
SA_BACK equ 2
SA_SAVE equ 3
SA_LOAD equ 4
SA_EXPORT equ 5
SA_FACE equ 6
SA_POS  equ 7

sh_panels:
        dw sl_want, grid_have
        db 0,SH_ROW,32,8
        dw si_want, grid_have+8*32
        db 0,SI_ROW,32,SI_H
N_SH_PANELS equ 2

g6_sheet:
        ld a,2                      ; (gn_open 2: the Sheet page in bank 6)
        ld (gn_open),a
        ld a,1
        ld (sfx_req),a
        ld a,4
        ld (phase),a
        call lock_buttons
        call new_screen
        ld hl,sh_panels
        ld (pd_table),hl
        ld a,N_SH_PANELS
        ld (pd_count),a
        ld hl,grid_want
        ld de,grid_want+1
        ld bc,1023
        ld (hl),' '
        ldir
        xor a
        ld (txt_pend),a
        ld (pend_n),a
        ld hl,sh_text
        call print_list
        ld a,AT_DEFAULT
        call set_attrs
        ld de,$0001
        ld bc,$0901
        ld a,AT_HEAD
        call fill_attr
        ld a,$ff
        ld (sh_bar_have),a
        ld a,(sh_cur)
        ld (sh_sel),a
        ld hl,s_sh_hello
        ld (sh_msg),hl
        jp sh_compose

sh_close:
        xor a
        ld (gn_open),a
        inc a
        ld (phase),a
        ld (sfx_req),a
        call lock_buttons
        call drawer_dirty
        jp draw_desk

; the page's update
sh_logic:
        call mask_tick              ; (the current figure's masks go on being worked out)
        call sh_keys
        ld (sh_act),a
        bit SA_BACK,a
        jr nz,sh_close
        ld a,(FRESH1)               ; Q, A (or the stick): the bar
        ld c,a
        bit K_UP,c
        jr z,.d
        ld a,(sh_sel)
        or a
        jr z,.d
        dec a
        ld (sh_sel),a
.d:     bit K_DOWN,c
        jr z,.a
        call sh_lines
        ld b,a
        ld a,(sh_sel)
        inc a
        cp b
        jr nc,.a
        ld (sh_sel),a
.a:     ld a,(sh_act)
        bit SA_NEW,a
        jr nz,.new
        bit SA_OPEN,a
        jr z,.f
        ld a,(sh_sel)               ; open: the "NEW FIGURE" line, the current figure, another
        ld hl,sh_count
        cp (hl)
        jr z,.new
        ld hl,sh_cur
        cp (hl)
        jr z,sh_close
        call sh_switch
        jr sh_close
.new:   call sh_add
        jr nc,sh_close              ; added: it is current, on the Desk
        ld hl,s_sh_full             ; refused: the sheet is full
        ld (sh_msg),hl
        call sh_refuse
        jp .t
.f:     ld a,(sh_act)
        bit SA_SAVE,a               ; S: the sheet to tape
        jr z,.ld
        ld hl,s_sh_saving
        call sh_now
        call sh_save
        ld hl,s_sh_saved
        jr c,.sv
        ld hl,s_sh_stopped
.sv:    ld (sh_msg),hl
        call sh_chime
        jr .t
.ld:    bit SA_LOAD,a               ; L: a sheet from tape
        jr z,.ff
        ld hl,s_sh_loading
        call sh_now
        call sh_load
        ld hl,s_sh_loaded
        or a
        jr z,.lv
        ld hl,s_sh_stopped
        dec a
        jr z,.lv
        ld hl,s_sh_notsheet
.lv:    ld (sh_msg),hl
        ld a,(sh_cur)
        ld (sh_sel),a
        call sh_chime
        jr .t
.ff:    ld a,(sh_act)
        bit SA_EXPORT,a             ; X: the current figure as DEFB lines, to tape
        jr z,.fa
        ld hl,s_sh_exporting
        call sh_now
        call sh_export
        ld hl,s_sh_exported
        jr c,.xv
        ld hl,s_sh_stopped
.xv:    ld (sh_msg),hl
        call sh_chime
        jp .t
.fa:    ld a,(sh_act)
        bit SA_FACE,a               ; F: facings for the data size, 1 or 2
        jr z,.p
        ld a,(sh_face)
        xor 3
        ld (sh_face),a
        call .chg
.p:     ld a,(sh_act)
        bit SA_POS,a                ; P: positions, 1, 2, 4 or 8
        jr z,.t
        ld a,(sh_pos)
        add a,a
        cp 16
        jr c,.p1
        ld a,1
.p1:    ld (sh_pos),a
        call .chg
.t:     ld a,(input_dev)
        cp DEV_MOUSE
        call z,move_cursor
        ld a,(sh_act)               ; the text changes only with an action (the bar is drawn apart):
        or a                        ; composed then, not every update (m6-r2 F-70)
        call nz,sh_compose
        ld a,(txt_pend)
        or a
        ret z
        jp panel_diff
.chg:   ld a,1
        ld (sfx_req),a
        ret

; HL = a message: shown now, before the tape takes the machine
sh_now:
        ld (sh_msg),hl
        call sh_compose
.l:     call panel_diff
        call print_pending
        ld a,(txt_pend)
        or a
        jr nz,.l
        ret

sh_chime:
        ld a,3
        ld (sfx_req),a
        ret

sh_refuse:
        ld a,2
        ld (sfx_req),a
        ret

; -> A = the list's lines: the figures, and "NEW FIGURE" while there is room
sh_lines:
        ld a,(sh_count)
        cp SH_MAX
        ret nc
        inc a
        ret

; the page's actions this update: keys, or a click on a line or a word -> A
sh_keys:
        ld c,0
        ld a,(FRESH1)
        bit K_SEC,a                 ; ENTER
        jr z,.k0
        set SA_OPEN,c
.k0:    bit K_PRIM,a                ; SPACE (keys); a click is below
        jr z,.k1
        ld a,(input_dev)
        cp DEV_MOUSE
        jr z,.k1
        set SA_OPEN,c
.k1:    ld a,(FRESH1)
        bit K_TITLE,a               ; T
        jr z,.k2
        set SA_BACK,c
.k2:    ld a,(FRESH5)
        bit K_SHEET,a               ; 9 again
        jr z,.k3
        set SA_BACK,c
.k3:    bit K_STYLE,a               ; F
        jr z,.k4
        set SA_FACE,c
.k4:    ld a,(FRESH4)
        bit 0,a                     ; N
        jr z,.k5
        set SA_NEW,c
.k5:    ld a,(FRESH2)
        bit K_SMALLER,a             ; S
        jr z,.k6
        set SA_SAVE,c
.k6:    bit K_LIB,a                 ; L
        jr z,.k7
        set SA_LOAD,c
.k7:    ld a,(FRESH3)
        bit A_NEXT,a                ; X
        jr z,.k8
        set SA_EXPORT,c
.k8:    ld a,(FRESH1)
        bit K_RIGHT,a               ; P
        jr z,.k9
        set SA_POS,c
.k9:    ld a,(input_dev)            ; the pointer
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
        ld d,a
        ld a,(cur_x)
        rrca
        rrca
        rrca
        and $1f
        ld e,a
        ld a,d                      ; a list line: choose it, or open it if already chosen
        sub SH_ROW
        jr c,.w
        cp 8
        jr nc,.w
        ld b,a
        push bc
        call sh_lines
        pop bc
        cp b
        jr c,.done
        jr z,.done
        ld a,(sh_sel)
        cp b
        jr z,.op
        ld a,b
        ld (sh_sel),a
        jr .done
.op:    set SA_OPEN,c
        jr .done
.w:     ld hl,sh_clicks             ; a word
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

sh_clicks:
        db SI_ROW+4,11,16,1<<SA_SAVE
        db SI_ROW+4,22,27,1<<SA_LOAD
        db SI_ROW+4,0,8,1<<SA_NEW
        db SI_ROW+5,0,7,1<<SA_EXPORT
        db SI_ROW+5,10,20,1<<SA_FACE
        db SI_ROW+5,23,29,1<<SA_POS
        db 22,23,28,1<<SA_BACK
        db $ff

; the text: the list, the current figure's data size and the page's controls
sh_compose:
        ld hl,grid_want
        ld de,grid_want+1
        ld bc,8*32+SI_H*32-1
        ld (hl),' '
        ldir
        ld c,0                      ; the list
.l:     ld a,(sh_count)
        cp c
        jr z,.nf
        push bc
        ld a,c
        call sh_line
        pop bc
        inc c
        jr .l
.nf:    cp SH_MAX                   ; "NEW FIGURE" while there is room
        jr nc,.info
        ld l,c
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,sl_want+2
        add hl,de
        ex de,hl
        ld hl,s_sh_newl
        call put_str
.info:  ld de,si_want               ; the sheet: n OF 8
        ld hl,s_sh_count
        call put_str
        ld a,(sh_count)
        call put_num
        ld hl,s_sh_of8
        call put_str
        call sh_size                ; the data size of the current figure
        ld de,si_want+3*32          ; the message
        ld hl,(sh_msg)
        call put_str
        ld de,si_want+4*32          ; the controls
        ld hl,s_sh_ctl1
        call put_str
        ld de,si_want+5*32
        ld hl,s_sh_ctl2
        call put_str
        ld de,si_want+5*32+20
        ld a,(sh_face)
        add a,'0'
        ld (de),a
        ld de,si_want+5*32+29
        ld a,(sh_pos)
        add a,'0'
        ld (de),a
        ld de,si_want+7*32
        ld hl,s_sh_leg
        call put_str
        ld a,(txt_pend)
        or 3
        ld (txt_pend),a
        ret

; A = a figure -> its line in the list: mark, number, name, box, frames
sh_line:
        ld c,a
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,sl_want
        add hl,de
        ex de,hl                    ; DE = the line
        ld a,(sh_cur)
        cp c
        ld a,' '
        jr nz,.m
        ld a,'*'
.m:     ld (de),a
        inc de
        ld a,c
        add a,'1'
        ld (de),a
        inc de
        inc de
        push de
        ld a,c
        call sh_head                ; HL = its head
        pop de
        push hl
        ld bc,6                     ; the name
        add hl,bc
        push de
        call put_str
        pop de
        ld hl,9
        add hl,de
        ex de,hl
        pop hl
        push hl
        inc hl
        inc hl
        ld a,(hl)                   ; box
        call put_num
        ld a,'X'
        ld (de),a
        inc de
        pop hl
        push hl
        inc hl
        inc hl
        inc hl
        ld a,(hl)
        call put_num
        inc de
        inc de
        pop hl
        ld a,(hl)                   ; frames
        call put_num
        ld hl,s_sh_fr
        jp put_str

; the data size (SHEET-01) of the current figure (*): frames x facings x positions x rows x groups (one
; more group a row when shifted), the picture's codes and as many again for the mask. Rows 1 and 2 of
; the information panel (m6-r1 F-60, F-61, F-66: named parts, no leading zeros)
sh_size:
        ld a,(bpr)
        ld b,a
        ld a,(sh_pos)
        cp 2
        ld a,b
        jr c,.g
        inc a
.g:     ld (sh_grp),a
        ld a,(nframes)              ; the product, 16 bits
        ld l,a
        ld h,0
        ld a,(sh_face)
        call .mul
        ld a,(sh_pos)
        call .mul
        ld a,(box_h)
        call .mul
        ld a,(sh_grp)
        call .mul
        ld (sh_codes),hl
        ld de,si_want+32            ; DATA *: n CODES +n MASK
        ld hl,s_sh_data
        call put_str
        call .num
        ld hl,s_sh_codes
        call put_str
        call .num
        ld hl,s_sh_mask
        call put_str
        ld de,si_want+64            ; nFRxnFACExnPOSxnROWxn
        ld a,(nframes)
        ld hl,s_sh_pfr
        call .part
        ld a,(sh_face)
        ld hl,s_sh_pface
        call .part
        ld a,(sh_pos)
        ld hl,s_sh_ppos
        call .part
        ld a,(box_h)
        ld hl,s_sh_prow
        call .part
        ld a,(sh_grp)
        call put_num
        ld hl,s_sh_pgrp
        jp put_str
.part:  push hl
        call put_num
        pop hl
        jp put_str
.num:   ld hl,(sh_codes)
        ld a,h
        or a
        ld a,l
        jp z,put_num
        jp put_dec16
.mul:   ld b,a                      ; HL x A -> HL
        ld d,h
        ld e,l
        dec b
        ret z
.ml:    add hl,de
        djnz .ml
        ret

sh_text:
        db 0,1,"THE SHEET",0
        db 22,0,"QA:CHOOSE ENTER:OPEN    T:BACK",0
        db $ff
s_sh_newl:  db "NEW FIGURE",0
s_sh_count: db "FIGURES ",0
s_sh_of8:   db " OF 8",0
s_sh_data:  db "DATA *: ",0
s_sh_codes: db " CODES +",0
s_sh_mask:  db " MASK",0
s_sh_pfr:   db "FRX",0
s_sh_pface: db "FACEX",0
s_sh_ppos:  db "POSX",0
s_sh_prow:  db "ROWX",0
s_sh_pgrp:  db "GROUPS",0
s_sh_fr:    db " FR",0
s_sh_ctl1:  db "N:NEW FIG  S:SAVE     L:LOAD",0
s_sh_ctl2:  db "X:EXPORT  F:FACINGS    P:POS",0
s_sh_leg:   db "CURRENT FIGURE: *",0
s_sh_hello: db "ENTER: OPEN THE BARRED FIGURE",0
s_sh_saving: db "SAVE: RECORD. SPACE 5 S: STOP",0
s_sh_loading: db "LOAD: PLAY THE TAPE. SPACE: STOP",0
s_sh_saved: db "SHEET SAVED",0
s_sh_exporting: db "EXPORT: RECORD. SPACE 5 S: STOP",0
s_sh_exported: db "EXPORTED *: FRAMES, THEN MASKS",0
s_sh_loaded: db "SHEET LOADED (U: UNDO)",0
s_sh_stopped: db "STOPPED: THE SHEET IS AS IT WAS",0
s_sh_notsheet: db "NOT A SHEET: SHEET AS IT WAS",0
s_sh_full:  db "CAN'T: THE SHEET HOLDS 8",0

; the draw phase: the bar, then the text
sh_draw:
        ld a,(sh_sel)
        ld hl,sh_bar_have
        cp (hl)
        jp z,print_pending
        ld c,(hl)
        ld (hl),a
        ld b,a
        ld a,c
        cp $ff
        jr z,.new
        add a,SH_ROW
        ld d,a
        ld e,0
        push bc
        ld bc,32*256+1
        ld a,AT_DEFAULT
        call fill_attr
        pop bc
.new:   ld a,b
        add a,SH_ROW
        ld d,a
        ld e,0
        ld bc,32*256+1
        ld a,AT_MARK
        jp fill_attr

; (called by the resident sh_save and sh_load while this bank is paged in)
; block A: magic, version, figures, current, the heads
sh_filea:
        ld hl,sh_fbuf
        ld (hl),'S'
        inc hl
        ld (hl),'S'
        inc hl
        ld (hl),SH_VERSION
        inc hl
        ld a,(sh_count)
        ld (hl),a
        inc hl
        ld a,(sh_cur)
        ld (hl),a
        inc hl
        ex de,hl
        ld hl,sh_heads
        ld bc,SH_MAX*SHEET_HEAD
        ldir
        ret

; NZ if block A (sh_fbuf) is not a sheet this Studio can open
sh_valid:
        ld hl,sh_fbuf
        ld a,(hl)
        cp 'S'
        ret nz
        inc hl
        cp (hl)
        ret nz
        inc hl
        ld a,(hl)
        cp SH_VERSION
        ret nz
        inc hl
        ld a,(hl)               ; figures 1 to 8
        dec a
        cp SH_MAX
        jr nc,.bad
        ld b,(hl)
        inc hl
        ld a,(hl)               ; current < figures
        cp b
        jr nc,.bad
        inc hl                  ; each head: frames 1-8, a box from the list, a style, an ink
.f:     push bc
        push hl
        ld a,(hl)
        dec a
        cp MAX_FRAMES
        jr nc,.bh
        inc hl
        inc hl
        ld d,(hl)               ; box across, down
        inc hl
        ld e,(hl)
        ld hl,box_list
        ld b,N_BOXES
.bx:    ld a,(hl)
        inc hl
        cp d
        jr nz,.bn
        ld a,(hl)
        cp e
        jr z,.bok
.bn:    inc hl
        djnz .bx
        jr .bh
.bok:   pop hl
        push hl
        ld bc,SHEET_HEAD-2
        add hl,bc
        ld a,(hl)               ; style
        cp 4
        jr nc,.bh
        inc hl
        ld a,(hl)               ; ink
        cp 8
        jr nc,.bh
        pop hl
        ld bc,SHEET_HEAD
        add hl,bc
        pop bc
        djnz .f
        xor a
        ret
.bh:    pop hl
        pop bc
.bad:   or 1
        ret

sh_fbuf:    ds 5+SH_MAX*SHEET_HEAD  ; block A, saved or loaded (here: every use has this bank paged)
