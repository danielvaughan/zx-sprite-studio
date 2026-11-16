; Sprite Studio (original code). 128K, sjasmplus. Built from the zx-game template, with the
; input stack (IM2 loop, key latching, STATE-03 locks, Kempston mouse and stick) from the
; owner's Kitchen Sink M1. Spec: specs/sprite-studio-spec.md v0.1. Design: game/design.md.
;
; Two screens: Start (choose your input, music) and the Desk. M2 Desk: the Grid on a numbered
; white sheet, the HEX column (each row's two bytes beside it), true-size FRAME and PLAY cards,
; readouts, two drawers of controls (frame controls, drawing controls), the frame strip and a
; status line. HARNESS_state/phase: 0 Start, 1 Desk.
;
; Drawing rule (the drawing chapter): every screen byte is written once an update with its
; final value. The Desk keeps "have" copies of what is on screen and each update redraws only
; what differs, capped per update: late, never wrong (D-008).
; - Grid: each square has a kind (bit 0 ink, 1 onion mark, 2 check mark, 3 cursor). Logic
;   recomputes grid_want for dirty rows, queues squares whose want differs from grid_have (at
;   most SQ_CAP an update) and the draw phase builds each glyph and writes it.
; - Text: four panels (readouts, drawer, HEX column, status line) diffed together, DRAW_CAP
;   characters an update.
; - Images: true-size cards and strip slots (img_have), IMG_CAP an update.
; The XOR arrow is erased first and redrawn last in the draw phase, straight after the HALT.
;
; Memory: $8000-code_end resident (bank 2); stack down from $BDBD; IM2 table $BE00.

        IFNDEF MACHINE
MACHINE         equ 128
        ENDIF
        IF MACHINE=128
        DEVICE ZXSPECTRUM128
        ELSE
        DEVICE ZXSPECTRUM48
        ENDIF

UPDATE_FRAMES   equ 1
MAX_DEBT        equ 24          ; a long screen change is caught up whole (music_parity)

ST_START        equ 0
ST_DESK         equ 1

DEV_NONE        equ 0
DEV_MOUSE       equ 1
DEV_DIR         equ 2

; k1 bits (bits 0-4 in Kempston order)
K_RIGHT         equ 0
K_LEFT          equ 1
K_DOWN          equ 2
K_UP            equ 3
K_PRIM          equ 4           ; SPACE, stick fire, mouse left
K_SEC           equ 5           ; ENTER, mouse right
K_TITLE         equ 6           ; T
K_MUSIC         equ 7           ; M
; k2 bits
K_CH_MOUSE      equ 0           ; 1
K_CH_DIR        equ 1           ; 2
K_FAST          equ 2           ; K
K_BIGGER        equ 3           ; B
K_SMALLER       equ 4           ; S
K_LIB           equ 5           ; L
K_EVERY         equ 6           ; E
; k3 bits = action ids 0-7: Z X C V R U G J
; k4 bits = action ids 10-17: N I 5 6 7 8 Y W

A_PREV          equ 0
A_NEXT          equ 1
A_NEW           equ 2
A_DEL           equ 3
A_CLR           equ 4
A_UNDO          equ 5
A_PLAY          equ 6
A_SLOW          equ 7
A_FAST          equ 8
A_TITLE         equ 9
A_ONION         equ 10
A_MIRROR        equ 11
A_NUDGE_L       equ 12
A_NUDGE_D       equ 13
A_NUDGE_U       equ 14
A_NUDGE_R       equ 15
A_CHECK         equ 16
A_DRAWER        equ 17
A_BIGGER        equ 18          ; SHEET-01 box size, B
A_SMALLER       equ 19          ; S
A_LIB           equ 20          ; LIB-01, L
A_EVERY         equ 21          ; ALL: mirror and nudge every frame, E
A_NONE          equ 22          ; an empty drawer slot
A_LAYER         equ 23          ; MASK-01: picture or mask layer, D
A_STYLE         equ 24          ; mask style, F
A_GROUND        equ 25          ; GROUND-01: the Test Ground, H
A_SHEET         equ 26          ; SHEET-01: the Sheet page, 9
A_LESSONS       equ 27          ; DEMO-01: the Lessons, 0
N_ACT           equ 26

; tuning (spec section 12 at 50 updates a second, D-004)
REP_DELAY       equ 15          ; T-REPEAT-DELAY 0.3 s
REP_TIME        equ 4           ; T-REPEAT-TIME 0.08 s
LIGHT_TIME      equ 10          ; T-LIGHT-TIME 0.2 s
NO_TIME         equ 32          ; a refusal: 16 updates red on white, 16 white on red (TT-17)
MAX_FRAMES      equ 8           ; T-FRAMES
MAX_BPR         equ 4           ; T-BOX-SIZES: at most 32 dots across
MAX_BOX_H       equ 32          ; and 32 rows
MAX_FBYTES      equ MAX_BPR*MAX_BOX_H
MS_RING         equ 0           ; mask styles (MASK-01)
MS_SHAPE        equ 1
MS_BOX          equ 2
MS_HAND         equ 3
PLAY_DEFAULT    equ 4           ; index into play_times: 0.08 s
GAIN_SHIFT      equ 4           ; T-GAIN 1 step a count, position in 1/16 steps

GRID_X          equ 8           ; Grid: cols 1-16, rows 2-17
GRID_Y          equ 16
SQ_CAP          equ 16          ; Grid cells redrawn per update (squares of 8 dots)
SQ_CAP4         equ 8           ; (squares of 4 dots: four glyphs a cell)
IMG_CAP         equ 2           ; images (cards, strip slots) per update
SQ_CAP_M        equ 6           ; with the mouse (set_caps)
SQ_CAP4_M       equ 3
IMG_CAP_M       equ 1
DRAW_CAP_M      equ 6
N_IMG           equ 10
DRAW_CAP        equ 16          ; text characters per update

CUR_H           equ 10
MAX_X16         equ 255*16+15
MAX_Y16         equ 191*16+15

; right column (cols 23-31): readouts rows 7-11, drawer rows 12-21
RC              equ 23
RW              equ 9
DRAWER_ROW      equ 12
N_ROWS          equ 10          ; drawer switch + 9 controls

SONG_START      equ 1

; events (status line)
EV_NONE         equ 0
EV_INK          equ 1
EV_RUB          equ 2
EV_PREV         equ 3
EV_NEXT         equ 4
EV_NEW          equ 5
EV_DEL          equ 6
EV_CLR          equ 7
EV_UNDO         equ 8
EV_REDO         equ 9
EV_PLAY         equ 10
EV_STOP         equ 11
EV_SLOW         equ 12
EV_FAST         equ 13
EV_PICK         equ 14
EV_INPUT        equ 15
EV_NO_FIRST     equ 16
EV_NO_LAST      equ 17
EV_NO_MAX       equ 18
EV_NO_ONE       equ 19
EV_NO_UNDO      equ 20
EV_NO_SLOW      equ 21
EV_NO_FAST      equ 22
EV_ONION_ON     equ 23
EV_ONION_OFF    equ 24
EV_MIRROR       equ 25
EV_NUDGE        equ 26
EV_NOPROB       equ 27
EV_DRAWER0      equ 28
EV_DRAWER1      equ 29
EV_STRAY        equ 30          ; + frame number (ev_p1)
EV_ALIKE        equ 31          ; + frame numbers (ev_p1, ev_p2)
EV_DRAWER2      equ 32          ; (EV_DRAWER3 below)
EV_BOX          equ 33
EV_NO_BIG       equ 34
EV_NO_SMALL     equ 35
EV_OPENED       equ 36          ; + the figure's name
EV_ALL_ON       equ 37
EV_ALL_OFF      equ 38
EV_MIRROR_ALL   equ 39
EV_NUDGE_ALL    equ 40
EV_OUTSIDE      equ 41          ; + frame (ev_p1)
EV_DRAWER3      equ 42
EV_LAYER_PIC    equ 43
EV_LAYER_MASK   equ 44
EV_MS_RING      equ 45          ; + the style
EV_COVER        equ 49
EV_KEEP         equ 50
EV_HARD         equ 51          ; the figure's checks (CHECK-01, M5)
EV_FAR          equ 52
EV_NEWFIG       equ 53
EV_CHECKING     equ 54
EV_LESSON       equ 55

BANK_PORT       equ $7ffd
ROM48           equ %00010000
AY_SELECT       equ $fffd
AY_DATA         equ $bffd

im2_table       equ $be00
im2_jump        equ $bdbd
stack_top       equ im2_jump

AT_DEFAULT      equ %01000111   ; bright white on black
AT_HEAD         equ %01000110   ; bright yellow on black
AT_BUTTON       equ %01001111   ; bright white on blue
AT_TAB          equ %01001110   ; bright yellow on blue: the drawer switch
AT_LIT          equ %01110000   ; bright black on yellow: control used
AT_NO_A         equ %01111010   ; bright red on white: refused, first half (reads light in grey)
AT_NO_B         equ %01000111   ; bright white on black: refused, second half (TT: reads in grey)
AT_CHOSEN       equ %01100000   ; bright black on green: a toggle that is on
AT_CANVAS       equ %01111000   ; bright black on white
AT_MARK         equ %01101000   ; bright black on cyan: the square under the cursor
AT_OUT          equ %00000000   ; Grid cells outside the box: black
OUTSIDE         equ $ff         ; a Grid cell's kind (both bytes) outside the box
BLINK_TIME      equ 16          ; the 4-dot cursor square turns over every 0.32 s

; Read-only data from $6000 (the template's $6000 layout: CLEAR 24575): the Start picture,
; text and labels. Code and variables from $8000.
        org $6000
code_start:
; ---------------------------------------------------------------- text
start_first:
        db 19,1,"THE DESK OPENS ON A BLANK SHEET",0
        db 20,1,"L THERE: OUR GAMES' FIGURES,",0
        db 21,1,"0 THERE: THE CHAPTER'S LESSONS.",0
        db $ff
start_again:
        db 19,1,"YOUR SHEET IS KEPT.",0
        db 20,1,"CARRIES ON WHERE YOU LEFT IT.",0
        db 21,1,"0 ON THE DESK: THE LESSONS.",0
        db $ff

; the Start picture (assets/screens/start.scr; game/tools/pack_rle.py)

start_text:
        db 16,7,"CHOOSE YOUR INPUT",0
        db 17,3," 1 MOUSE ",0
        db 17,14," 2 KEYS/JOYSTICK ",0
        db 22,19,"PRESS 1 OR 2",0
        db $ff

desk_text:
        db 1,23,"EDIT",0
        db 1,28,"PLAY",0
        db $ff

txt_mark:   db "^^",0
txt_nomark: db "  ",0

s_mouse:    db "MOUSE",0
s_keys:     db "KEYS",0
s_nosq:     db "-,-",0
s_ink:      db "INK",0
s_paper:    db "PAPER",0
s_frame:    db "FRAME ",0
s_playing:  db "PLAY ",0
s_stop:     db "STOP ",0
s_checks:   db "CHECKS ",0
s_ok:       db "OK",0
s_inked:    db "INKED ",0
s_stray:    db "STRAY DOT: FRAME ",0
s_alike:    db "ALIKE ",0
s_more1:    db ": ",0
s_more2:    db "+",0
s_drawer0:  db "FRAMES  W",0
s_drawer1:  db "DRAWING W",0
s_drawer2:  db "FIGURE  W",0
s_drawer3:  db "MASK    W",0
s_cover:    db "COVER",0
s_keep:     db "KEEP",0
s_outside:  db "OUTSIDE MASK: FRAME ",0
s_at:       db "AT ",0
s_studio:   db "SPRITE STUDIO",0
s_hex:      db "HEX",0
        ALIGN 16
ks_tab:     db $ff,0,0,0,0,0,0,0          ; kprobe 0: present (and 1-4 probing, 7 = $ff absent)
            db 0,$ff,$ff,$ff,$ff,0,0,0
s_leg_keys: db "QAOP:MOVE SPC:DRAW L:LIB D:MASK ",0
s_leg_ms:   db "LEFT:DRAW RIGHT:RUB L:LIB D:MASK",0
s_leg_mkeys: db "QAOP:MOVE SPC:COVER/KEEP D:LAYER",0
s_leg_mms:  db "LEFT:COVER RIGHT:KEEP D:LAYER   ",0
s_lleg_keys: db "QA:MOVE OP:GAME SPACE:OPEN      ",0
s_lleg_ms:  db "CLICK:CHOOSE AGAIN/ENTER:OPEN   ",0
s_change:   db "CHANGE ",0
drawer_names: dw s_drawer0,s_drawer1,s_drawer2,s_drawer3
drawer_lists: dw drawer0,drawer1,drawer2,drawer3
; T-BOX-SIZES, across x down, in the spec's order: BIGGER and SMALLER step through them
box_list:   db 8,8, 16,8, 8,16, 16,16, 16,24, 24,16, 24,24, 24,32, 32,16, 32,24, 32,32
N_BOXES     equ ($-box_list)/2
play_names: db "0.320.240.160.120.080.04"

act_labels: dw l_prev,l_next,l_copy,l_del,l_clr,l_undo,l_play,l_slow,l_fast,l_back
            dw l_onion,l_mirror,l_nl,l_and,l_nu,l_nr,l_check,l_none
            dw l_bigger,l_smaller,l_lib,l_every,l_none,l_layer_p,l_ring,l_ground,l_sheet,l_lessons
l_sheet:    db "SHEET   9",0
l_lessons:  db "LESSONS 0",0
l_layer_p:  db "PICTURE D",0
l_layer_m:  db "MASK    D",0
l_ring:     db "RING    F",0
l_shape:    db "SHAPE   F",0
l_boxm:     db "BOX     F",0
l_hand:     db "HAND    F",0
l_ground:   db "GROUND  H",0
style_labels: dw l_ring,l_shape,l_boxm,l_hand
l_every:    db "ALL     E",0
l_lib:      db "LIBRARY L",0
l_bigger:   db "BIGGER  B",0
l_smaller:  db "SMALLER S",0
l_prev:     db "PREV    Z",0
l_next:     db "NEXT    X",0
l_copy:     db "COPY    C",0
l_del:      db "DELETE  V",0
l_clr:      db "CLEAR   R",0
l_undo:     db "UNDO    U",0
l_redo:     db "REDO    U",0
l_play:     db "PLAY    G",0
l_stop:     db "STOP    G",0
l_slow:     db "SLOWER  J",0
l_fast:     db "FASTER  K",0
l_back:     db "BACK    T",0
l_onion:    db "TRACING N",0
l_mirror:   db "MIRROR  I",0
l_nl:       db "NUDGE < 5",0
l_and:       db "NUDGE v 6",0
l_nu:       db "NUDGE ^ 7",0
l_nr:       db "NUDGE > 8",0
l_check:    db "CHECK   Y",0
l_none:     db 0

ev_names:   dw ev_0,ev_1,ev_2,ev_3,ev_4,ev_5,ev_6,ev_7,ev_8,ev_9,ev_10,ev_11
            dw ev_12,ev_13,ev_14,ev_15,ev_16,ev_17,ev_18,ev_19,ev_20,ev_21,ev_22
            dw ev_23,ev_24,ev_25,ev_26,ev_27,ev_28,ev_29,ev_0,ev_0
            dw ev_32,ev_33,ev_34,ev_35,ev_0,ev_37,ev_38,ev_39,ev_40,ev_0,ev_42,ev_43,ev_44
            dw ev_45,ev_46,ev_47,ev_48,ev_49,ev_50,s_hard,s_far,s_newfig,s_checking,les_cap
s_checking: db "CHECKING...",0
s_newfig: db "NEW FIGURE",0
s_hard: db "INK HARD TO SEE, KEY H",0
s_far:  db "MOVES TOO FAR",0
ev_49:  db "COVER",0
ev_50:  db "KEEP",0
ev_42:  db "MASK CONTROLS",0
ev_43:  db "PICTURE LAYER",0
ev_44:  db "MASK LAYER: COVER/KEEP",0
ev_45:  db "MASK: RING",0
ev_46:  db "MASK: SHAPE",0
ev_47:  db "MASK: BOX",0
ev_48:  db "MASK: BY HAND",0
ev_37:  db "ALL FRAMES: ON",0
ev_38:  db "ALL FRAMES: OFF",0
ev_39:  db "MIRRORED ALL FRAMES",0
ev_40:  db "NUDGED ALL FRAMES",0
ev_32:  db "FIGURE CONTROLS",0
ev_33:  db "BOX SIZE CHANGED",0
ev_34:  db "CAN'T: BIGGEST BOX",0
ev_35:  db "CAN'T: SMALLEST BOX",0
ev_0:   db "HOLD SPACE, MOVE: LINE",0
ev_1:   db "INK",0
ev_2:   db "RUB OUT",0
ev_3:   db "PREVIOUS FRAME",0
ev_4:   db "NEXT FRAME",0
ev_5:   db "FRAME COPIED",0
ev_6:   db "FRAME DELETED",0
ev_7:   db "FRAME CLEARED",0
ev_8:   db "UNDO",0
ev_9:   db "REDO",0
ev_10:  db "PLAY",0
ev_11:  db "STOP",0
ev_12:  db "SLOWER",0
ev_13:  db "FASTER",0
ev_14:  db "FRAME CHOSEN",0
ev_15:  db "INPUT CHOSEN",0
ev_16:  db "CAN'T: FIRST FRAME",0
ev_17:  db "CAN'T: LAST FRAME",0
ev_18:  db "CAN'T: 8 IS THE MOST",0
ev_19:  db "CAN'T: ONLY ONE LEFT",0
ev_20:  db "CAN'T: NOTHING TO UNDO",0
ev_21:  db "CAN'T: SLOWEST",0
ev_22:  db "CAN'T: FASTEST",0
ev_23:  db "TRACING PAPER ON",0
ev_24:  db "TRACING PAPER OFF",0
ev_25:  db "MIRRORED THIS FRAME",0
ev_26:  db "NUDGED THIS FRAME",0
ev_27:  db "NO PROBLEMS FOUND",0
ev_28:  db "FRAME CONTROLS",0
ev_29:  db "DRAWING CONTROLS",0

        INCLUDE "gen/library.inc"

; The sheet (one figure). The box (width, height) and its derived sizes travel with the frames,
; so Undo takes back a change of box too. Frames are packed: frame n starts at n * fbytes, each
; row is bpr bytes, left dot first (a .spr frame's layout). The Desk opens on a blank figure,
; box T-BOX-START, one frame (spec v0.2); the Library holds the studio's own (LIB-01).
sheet:
nframes:    db 1
cur_frame:  db 0
box_w:      db 16                   ; dots across: 8, 16, 24 or 32 (T-BOX-SIZES)
box_h:      db 16                   ; rows: 8 to 32
bpr:        db 2                    ; bytes a row = box_w / 8
fbytes:     db 32                   ; bytes a frame = bpr * box_h (at most 128)
fig_name:   db "FIGURE 1",0,0,0     ; the figure's name, at most 8 letters (T-NAME)
fig_game:   db $ff                  ; its game in the Library ($ff: drawn here)
mstyle:     db MS_RING              ; the mask style (MASK-01)
fig_ink:    db 2                    ; its ink colour (CLASH-01): red
SHEET_HEAD  equ $-sheet
frames_data:                        ; frames 0-7, then their masks as frames 8-15 (packed at fbytes)
        ds 2*MAX_FRAMES*MAX_FBYTES
SHEET_LEN   equ $-sheet             ; the most a sheet can hold (in the $6000 block: D-043)
        ALIGN 256
grid_want:  ds 512                  ; the Grid: top pairs, then bottom pairs 256 on (page-aligned)
grid_have:  ds 512
rev_tab:    ds 256                  ; each byte's bits reversed (build_rev)
kv_tab:     ds 256                  ; the stick port's values (build_kv)
pc_table:   ds 256                  ; dots in each byte value (build_pc)
half_tab:   ds 256                  ; each pair of dots one dot (build_half)
mk_o:       ds MAX_FBYTES           ; the masks' reached paper (masks.asm)
mk_res:     ds MAX_FBYTES           ; a mask being finished
lib_fbuf:   ds MAX_FBYTES           ; the Library preview's frame
check_bits: ds MAX_FBYTES           ; the squares CHECK marks
chk_buf:    ds MAX_FBYTES           ; the checks' workspace
text_want:  ds TEXT_LEN             ; the Desk's text panels: wanted, and on screen
text_have:  ds TEXT_LEN
        INCLUDE "ground_data.asm"
        ASSERT $ <= $8000

; Undo's two copies of the sheet are in bank 3 at $C000, paged in only to copy (D-043)
UNDO_BANK   equ 3
undo_buf    equ $c000
pre_buf     equ $c000+SHEET_LEN
        ASSERT $ <= $8000
        ds $8000-$
start:
        di
        ld sp,stack_top
        IF MACHINE=128
        ld a,ROM48
        ld (bank_shadow),a
        ld bc,BANK_PORT
        out (c),a
        call snd_init
        ENDIF
        call build_im2
        call build_pc
        call build_half
        call build_rev
        call build_kv
        ei
        call enter_start
        xor a
        ld (frames),a

main_loop:
.wait:  ld a,(frames)
        cp UPDATE_FRAMES
        jr nc,.go
        halt
        ld a,1
        ld (halted),a
        jr .wait
.go:    di
        ld a,(frames)
        sub UPDATE_FRAMES
        cp MAX_DEBT+1
        jr c,.keep
        ld a,MAX_DEBT
.keep:  ld (frames),a
        ei
        ld hl,(updates)
        inc hl
        ld (updates),hl
        ld a,(halted)           ; draw straight after an interrupt only, so the beam never meets a
        or a                    ; half-done draw phase; a late update does logic only, at most
        jr nz,.draw             ; MAX_DEBT + 1 running (M3 gate: flicker)
        ld a,(skipped)          ; catching up: logic only until caught up (at most MAX_DEBT); then wait
        cp MAX_DEBT+1           ; for the next interrupt and draw (never mid-frame)
        jr nc,.wait1
        inc a
        ld (skipped),a
        jr .nd
.wait1: halt
.draw:  xor a
        ld (skipped),a
        call draw_phase
.nd:    xor a
        ld (halted),a
        call take_input
        call logic
        jr main_loop

; ---------------------------------------------------------------- input
; NK key bytes, six rows of them: held (ISR), latched (ISR), down, locked, effective (down minus
; locked), fresh (effective now, not last update). Byte 5 (M4, D-044): D layer, F style, H ground.
NK      equ 5
EFF1    equ kb+4*NK
FRESH1  equ kb+5*NK
FRESH2  equ kb+5*NK+1
FRESH3  equ kb+5*NK+2
FRESH4  equ kb+5*NK+3
FRESH5  equ kb+5*NK+4
K_LAYER         equ 0           ; D (k5)
K_STYLE         equ 1           ; F
K_GROUND        equ 2           ; H
K_SHEET         equ 3           ; 9
K_LESSONS       equ 4           ; 0

take_input:
        ld ix,kb
        ld b,NK
.l:     di
        ld a,(ix+NK)
        or (ix+0)
        ld (ix+NK),0
        ei
        ld (ix+2*NK),a
        ld c,a
        ld a,(ix+3*NK)          ; a locked key stays locked only while it is down
        and c
        ld (ix+3*NK),a
        cpl
        and c
        ld c,a
        ld a,(ix+4*NK)
        cpl
        and c
        ld (ix+5*NK),a
        ld (ix+4*NK),c
        inc ix
        djnz .l
        ret

; STATE-03: lock every key down now; end any stroke, forget any repeat.
lock_buttons:
        ld hl,kb+2*NK
        ld de,kb+3*NK
        ld bc,NK
        ldir
        ld hl,kb+4*NK
        ld b,2*NK
.z:     ld (hl),0
        inc hl
        djnz .z
        xor a
        ld (rep_dirs),a
        jp stroke_end

; ---------------------------------------------------------------- logic
logic:
        ld a,(state)
        or a
        jp nz,desk_logic

start_logic:
        ld a,(FRESH2)
        bit K_CH_MOUSE,a
        jr z,.n1
        ld a,DEV_MOUSE
        call choose_input
        jp enter_desk
.n1:    bit K_CH_DIR,a
        jr z,.n2
        ld a,DEV_DIR
        call choose_input
        jp enter_desk
.n2:    ld a,(FRESH1)
        bit K_MUSIC,a
        ret z
        ld a,(music)
        xor 1
        ld (music),a
        ld a,1
        ld (music_dirty),a
        ret

desk_logic:
        ld a,(lib_open)
        or a
        jp nz,lib_logic
        ld a,(gn_open)
        or a
        jp nz,ground_logic
        ld a,(FRESH2)
        bit K_CH_MOUSE,a
        jr z,.n1
        ld a,DEV_MOUSE
        call choose_input
        jr .n2
.n1:    bit K_CH_DIR,a
        jr z,.n2
        ld a,DEV_DIR
        call choose_input
.n2:    ld a,(FRESH1)
        bit K_TITLE,a
        jr z,.n3
        ld a,A_TITLE
        jp do_action
.n3:    call move_cursor
        call calc_square
        call paint
        call key_actions
        ld a,(state)
        or a
        ret z                   ; Back was used
        ld a,(lib_open)
        ld hl,gn_open
        or (hl)
        ret nz                  ; a page opened (the Library, the Test Ground): it has taken over
        call play_tick
        call light_tick
        ld a,(stroke)           ; checks and masks are worked out when the sheet has changed, not mid-stroke
        or a
        jr nz,.nk
        ld a,(chk_pend)         ; the checks first, else the masks: one of them an update
        or a
        jr nz,.ck
        call mask_tick
        jr .nk
.ck:    ld a,(txt_dirty)
        ld hl,txt_pend
        or (hl)
        jr nz,.nk
        call check_tick
.nk:    ld a,(chk_wait)         ; CHECK waiting for the checks
        or a
        jr z,.nw
        ld a,(chk_pend)
        or a
        jr nz,.nw
        ld (chk_wait),a
        call act_check
.nw:    ld a,(cnt_dirty)
        or a
        jr z,.nc
        xor a
        ld (cnt_dirty),a
        call count_inked
.nc:    call cursor_rows
        call blink_tick
        call arrow_caps
        call grid_compute
        ld a,(txt_dirty)        ; panels to compose (once a change) ...
        or a
        jr z,.pend
        bit 0,a
        jr z,.r6
        or 16                   ; the readouts' input row goes with them
        ld (txt_dirty),a
.r6:    rra
        push af
        call c,compose_readouts
        pop af
        rra
        push af
        call c,compose_drawer
        pop af
        rra
        push af
        call c,compose_codes
        pop af
        rra
        call c,compose_status
        ld a,(txt_dirty)
        bit 5,a
        call nz,compose_header
        ld a,(txt_dirty)
        bit 6,a
        jr z,.nl
        or 128                  ; across and down go together
        ld (txt_dirty),a
        call compose_labels
.nl:
        ld a,(txt_dirty)        ; ... and to diff, until drawn (DRAW_CAP an update)
        ld hl,txt_pend
        or (hl)
        ld (hl),a
        xor a
        ld (txt_dirty),a
.pend:  ld a,(txt_pend)
        or a
        ret z
        jp panel_diff

; A = DEV_MOUSE or DEV_DIR (DEV-01). Mouse: the Arrow at the Grid centre, the counters as
; they are now as the baseline. Directional: the Grid Cursor on the square under the Arrow,
; else the centre square; from Start it stays where it was left (D-013).
choose_input:
        ld c,a
        ld a,(input_dev)
        ld b,a
        ld a,c
        ld (input_dev),a
        cp DEV_MOUSE
        jr nz,.dir
        di
        ld bc,$fbdf
        in a,(c)
        ld (ms_lastx),a
        ld b,$ff
        in a,(c)
        ld (ms_lasty),a
        ld hl,0
        ld (ms_dx),hl
        ld (ms_dy),hl
        ei
        ld hl,(GRID_X+64)*16
        ld (cx16),hl
        ld hl,(GRID_Y+64)*16
        ld (cy16),hl
        call to_pixels
        jr .com
.dir:   ld a,4
        ld (kprobe),a
        ld a,b
        or a
        jr z,.gc                ; from Start: the Grid Cursor stays where it was left
        cp DEV_MOUSE
        jr nz,.ctr
        ld a,(sq_ok)
        or a
        jr z,.ctr
        ld a,(sq_col)
        ld (gc_col),a
        ld a,(sq_row)
        ld (gc_row),a
        jr .gc
.ctr:   ld a,(box_w)            ; the centre square of the box
        srl a
        ld (gc_col),a
        ld a,(box_h)
        srl a
        ld (gc_row),a
.gc:    call gc_pixels
.com:   call lock_buttons
        call set_caps
        ld a,(state)            ; on the Desk (not the Library page): the key line follows
        or a
        jr z,.nl
        ld a,(lib_open)
        or a
        call z,desk_legend
.nl:
        call calc_square
        ld a,EV_INPUT
        ld (last_event),a
        ld a,%1111
        ld (txt_dirty),a
        ld a,3                  ; a chime
        ld (sfx_req),a
        ret

; ---------------------------------------------------------------- cursor
move_cursor:
        ld a,(input_dev)
        cp DEV_MOUSE
        jr nz,grid_move
        di
        ld hl,(ms_dx)
        ld de,(ms_dy)
        ld bc,0
        ld (ms_dx),bc
        ld (ms_dy),bc
        ei
        push de
        call clamp127
        call gain_de
        ld hl,(cx16)
        ld bc,MAX_X16
        call clamp_add
        ld (cx16),hl
        pop hl
        call clamp127
        neg
        call gain_de
        ld hl,(cy16)
        ld bc,MAX_Y16
        call clamp_add
        ld (cy16),hl
to_pixels:
        ld hl,(cx16)
        call div16
        ld (cur_x),a
        ld hl,(cy16)
        call div16
        ld (cur_y),a
        ret

; DEV-02: the Grid Cursor, one square a press, then repeat.
grid_move:
        ld a,(EFF1)
        and $0f
        ld c,a
        and 3
        cp 3
        jr nz,.h
        ld a,c
        and $0c
        ld c,a
.h:     ld a,c
        and $0c
        cp $0c
        jr nz,.v
        ld a,c
        and 3
        ld c,a
.v:     ld a,c
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
        jr gc_step
.same:  ld hl,rep_t
        dec (hl)
        ret nz
        ld (hl),REP_TIME
gc_step:
        ld hl,steer_n           ; every step the Grid Cursor acts on, blocked or not (verify)
        inc (hl)
        ld hl,gc_col
        bit K_RIGHT,c
        jr z,.nr
        ld a,(box_w)
        dec a
        cp (hl)
        jr z,.nr
        inc (hl)
.nr:    bit K_LEFT,c
        jr z,.nl
        ld a,(hl)
        or a
        jr z,.nl
        dec (hl)
.nl:    ld hl,gc_row
        bit K_DOWN,c
        jr z,.nd
        ld a,(box_h)
        dec a
        cp (hl)
        jr z,.nd
        inc (hl)
.nd:    bit K_UP,c
        jr z,gc_pixels
        ld a,(hl)
        or a
        jr z,gc_pixels
        dec (hl)
gc_pixels:
        ld a,(sq_sh)
        or a
        ld a,(gc_col)
        ld c,GRID_X+4
        jr nz,.f
        add a,a
        add a,a
        add a,a
        add a,c
        ld (cur_x),a
        ld a,(gc_row)
        add a,a
        add a,a
        add a,a
        add a,GRID_Y+4
        ld (cur_y),a
        ret
.f:     add a,a                 ; squares of 4 dots: the middle of the square
        add a,a
        add a,GRID_X+2
        ld (cur_x),a
        ld a,(gc_row)
        add a,a
        add a,a
        add a,GRID_Y+2
        ld (cur_y),a
        ret

div16:  add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld a,h
        ret

clamp127:
        bit 7,h
        jr nz,.neg
        ld a,h
        or a
        jr nz,.pmax
        ld a,l
        cp 128
        ret c
.pmax:  ld a,127
        ret
.neg:   ld a,h
        inc a
        jr nz,.nmax
        ld a,l
        cp $81
        ret nc
.nmax:  ld a,-127
        ret

gain_de:
        ld e,a
        ld d,0
        bit 7,a
        jr z,.p
        dec d
.p:     ld b,GAIN_SHIFT
.s:     sla e
        rl d
        djnz .s
        ret

clamp_add:
        add hl,de
        bit 7,h
        jr nz,.zero
        push hl
        or a
        sbc hl,bc
        pop hl
        ret c
        ld h,b
        ld l,c
        ret
.zero:  ld hl,0
        ret

; sq_ok/sq_col/sq_row: the Grid square under the cursor (inside the box only)
calc_square:
        ld a,(input_dev)
        cp DEV_DIR
        jr nz,.m
        ld a,(gc_col)
        ld (sq_col),a
        ld a,(gc_row)
        ld (sq_row),a
        ld a,1
        ld (sq_ok),a
        ret
.m:     xor a
        ld (sq_ok),a
        ld a,(cur_x)
        sub GRID_X
        ret c
        cp 128
        ret nc
        call sq_of
        ld hl,box_w
        cp (hl)
        ret nc
        ld c,a
        ld a,(cur_y)
        sub GRID_Y
        ret c
        cp 128
        ret nc
        call sq_of
        ld hl,box_h
        cp (hl)
        ret nc
        ld (sq_row),a
        ld a,c
        ld (sq_col),a
        ld a,1
        ld (sq_ok),a
        ret

; A = dots from the Grid's edge (0-127) -> A = square
sq_of:  ld b,a
        ld a,(sq_sh)
        or a
        ld a,b
        rrca
        rrca
        jr nz,.f
        rrca
        and 15
        ret
.f:     and 31
        ret

; The cursor's square changed: the rows it left and entered need new kinds; the HEX column
; follows the cursor's band of 16 rows and 2 bytes.
cursor_rows:
        ld a,(sq_ok)
        ld b,a
        ld a,(cur_was_ok)
        cp b
        jr nz,.chg
        or a
        ret z
        ld a,(sq_row)
        ld hl,cur_was_r
        cp (hl)
        jr nz,.chg
        ld a,(sq_col)
        ld hl,cur_was_c
        cp (hl)
        ret z
.chg:   ld a,(txt_dirty)
        or 1
        ld (txt_dirty),a
        ld a,(cur_was_ok)
        or a
        ld a,(cur_was_r)
        call nz,dirty_row
        ld a,(sq_ok)
        ld (cur_was_ok),a
        or a
        ret z
        ld a,(sq_row)
        ld (cur_was_r),a
        ld a,(sq_col)
        ld (cur_was_c),a
        rrca
        rrca
        rrca
        rrca
        and 1
        ld c,a
        ld a,(sq_row)
        rrca
        rrca
        rrca
        and 2
        or c                    ; the band: bit 1 rows 16-31, bit 0 columns 16-31
        ld hl,cd_band
        cp (hl)
        jr z,.b
        ld (hl),a
        ld a,(txt_dirty)
        or 4+64                 ; the HEX column and its header
        ld (txt_dirty),a
.b:     ld a,(sq_row)
; A = square row: mark its Grid row dirty
dirty_row:
        ld e,a
        ld a,(sq_sh)
        or a
        jr z,.r
        srl e
.r:     ld d,0
        ld hl,row_dirty
        add hl,de
        ld (hl),1
        ld a,1
        ld (grid_any),a
        ret

dirty_all:
        ld hl,row_dirty
        ld b,16
.l:     ld (hl),1
        inc hl
        djnz .l
        ld a,1
        ld (grid_any),a
        ret

; How much the draw phase does an update. With the mouse the XOR Arrow is erased first and drawn
; last, so the work between must end before the beam reaches the Arrow: smaller caps (M3 gate).
set_caps:
        ld a,(input_dev)
        cp DEV_MOUSE
        ld bc,SQ_CAP*256+SQ_CAP4
        ld de,IMG_CAP*256+DRAW_CAP
        jr nz,.k
        ld bc,SQ_CAP_M*256+SQ_CAP4_M
        ld de,IMG_CAP_M*256+DRAW_CAP_M
.k:     ld a,d
        ld (img_cap),a
        ld a,e
        ld (draw_cap),a
        ld a,(sq_sh)
        or a
        ld a,b
        jr z,.s
        ld a,c
.s:     ld (sq_cap),a
        ret

; With the pointer, the Grid cells an update follow the Arrow's height: the draw phase need only
; end before the beam reaches the Arrow's top row, so a low Arrow allows more (m3-r5 F-23, D-043):
; 4-dot cells y / 16, 8-dot cells about y / 11, at least 1 (D-044: measured by tools/flicker_recipes).
arrow_caps:
        ld a,(input_dev)
        cp DEV_MOUSE
        ret nz
        ld a,(cur_y)
        ld b,a
        srl b
        srl b
        srl b                   ; y / 8
        ld a,(sq_sh)
        or a
        ld a,b
        jr nz,.four
        srl b
        srl b                   ; y / 32
        sub b                   ; y / 8 - y / 32 (about y / 11)
        jr .m
.four:  srl a                   ; y / 16
.m:     or a
        jr nz,.s
        inc a
.s:     ld (sq_cap),a
        ret

; the 4-dot cursor square turns over every BLINK_TIME updates: its cell is drawn again
blink_tick:
        ld a,(sq_sh)
        or a
        ret z
        ld hl,blink_t
        dec (hl)
        ret nz
        ld (hl),BLINK_TIME
        ld a,(blink)
        xor 1
        ld (blink),a
        ld a,(cur_was_ok)
        or a
        ret z
        ld a,(cur_was_r)
        and $1e
        add a,a
        add a,a
        add a,a                 ; cell row * 16
        ld e,a
        ld a,(cur_was_c)
        srl a
        or e
        ld e,a
        ld d,0
        ld hl,grid_have
        add hl,de
        ld (hl),$fe             ; a kind no cell can want: queued again
        ld a,(cur_was_r)
        jp dirty_row

; ---------------------------------------------------------------- painting (DRAW-01)
paint:
        ld a,(stroke)
        or a
        jr nz,.cont
        ld a,(FRESH1)
        bit K_PRIM,a
        jr z,.sec
        ld a,(sq_ok)
        or a
        jp z,mouse_press
        call stroke_begin
        ld a,(sq_col)
        ld c,a
        ld a,(sq_row)
        ld b,a
        call get_sq
        ld a,1
        jr z,.m
        xor a
.m:     ld (pmode),a
        ld a,1
        jr .begin
.sec:   bit K_SEC,a
        ret z
        ld a,(sq_ok)
        or a
        ret z
        call stroke_begin
        xor a
        ld (pmode),a
        ld a,2
.begin: ld (stroke),a
        ld a,(layer)            ; the mask layer: COVER or KEEP (m4-r1 F-31)
        or a
        ld b,EV_INK
        jr z,.lw
        ld b,EV_COVER
.lw:    ld a,(pmode)
        or a
        ld a,b
        jr nz,.ev
        inc a                   ; EV_RUB / EV_KEEP follow
.ev:    ld (last_event),a
        ld a,(txt_dirty)
        or 8
        ld (txt_dirty),a
        jr .put
.cont:  ld a,(stroke)
        dec a
        ld a,(EFF1)
        jr nz,.s2
        and 1<<K_PRIM
        jr .t
.s2:    and 1<<K_SEC
.t:     jr nz,.held
        jp stroke_end
.held:  ld a,(sq_ok)
        or a
        jr nz,.on
        ld (last_ok),a
        ret
.on:    ld a,(last_ok)
        or a
        jr z,.put
        call line
        jr .last
.put:   ld a,(sq_col)
        ld c,a
        ld a,(sq_row)
        ld b,a
        call set_sq
.last:  ld a,(sq_col)
        ld (last_col),a
        ld a,(sq_row)
        ld (last_row),a
        ld a,1
        ld (last_ok),a
        ret

; Bresenham in squares from (last_col, last_row) to (sq_col, sq_row), every square set.
line:
        ld a,(last_col)
        ld (ln_x),a
        ld a,(last_row)
        ld (ln_y),a
        ld a,(sq_col)
        ld hl,ln_x
        sub (hl)
        ld c,1
        jr nc,.px
        neg
        ld c,-1
.px:    ld (ldx),a
        ld a,c
        ld (lsx),a
        ld a,(sq_row)
        ld hl,ln_y
        sub (hl)
        ld c,1
        jr nc,.py
        neg
        ld c,-1
.py:    neg
        ld (ldy),a
        ld a,c
        ld (lsy),a
        ld a,(ldx)
        ld hl,ldy
        add a,(hl)
        ld (lerr),a
.loop:  ld a,(ln_x)
        ld c,a
        ld a,(ln_y)
        ld b,a
        call set_sq
        ld a,(ln_x)
        ld hl,sq_col
        cp (hl)
        jr nz,.go
        ld a,(ln_y)
        ld hl,sq_row
        cp (hl)
        ret z
.go:    ld a,(lerr)
        add a,a
        ld e,a
        ld hl,ldy
        sub (hl)
        bit 7,a
        jr nz,.noX
        ld a,(lerr)
        add a,(hl)
        ld (lerr),a
        ld a,(lsx)
        ld hl,ln_x
        add a,(hl)
        ld (hl),a
.noX:   ld a,(ldx)
        sub e
        bit 7,a
        jr nz,.loop
        ld a,(lerr)
        ld hl,ldx
        add a,(hl)
        ld (lerr),a
        ld a,(lsy)
        ld hl,ln_y
        add a,(hl)
        ld (hl),a
        jr .loop

; C = col, B = row -> HL = byte in the current frame, A = bit mask. Keeps BC.
sq_addr:
        call edit_frame
        push bc
        call frame_ptr
        pop bc
        ld a,(bpr)              ; + row * bpr
        ld e,b
        ld d,0
.rw:    add hl,de
        dec a
        jr nz,.rw
        ld a,c                  ; + col / 8
        rrca
        rrca
        rrca
        and 3
        ld e,a
        add hl,de
        ld a,c
        and 7
        ld e,a
        push hl
        ld hl,bitmask
        add hl,de
        ld a,(hl)
        pop hl
        ret

get_sq:
        call sq_addr
        and (hl)
        ret

; square (C, B) := pmode. Keeps BC.
set_sq:
        call sq_addr
        ld e,a
        ld a,(pmode)
        or a
        ld a,e
        jr z,.clr
        or (hl)
        jr .d
.clr:   cpl
        and (hl)
.d:     cp (hl)
        ret z                   ; already so: nothing to redraw
        ld (hl),a
        ld a,(layer)
        or a
        jr z,.pic
        ld a,(mstyle)           ; the mask by hand from now on (the masks were finished at the
        cp MS_HAND              ; stroke's start)
        jr z,.mk
        ld a,MS_HAND
        ld (mstyle),a
        call drawer_dirty
.mk:    call checks_again
        ld a,(txt_dirty)
        or %1101
        ld (txt_dirty),a
        call clear_check
        ld a,b
        push bc
        call dirty_row
        pop bc
        ret
.pic:   ld hl,(inked)           ; one square more or less
        ld a,(pmode)
        or a
        jr z,.dn
        inc hl
        jr .dk
.dn:    dec hl
.dk:    ld (inked),hl
        push bc
        ld a,b
        call img_painted
        pop bc
        call checks_again
        ld a,(txt_dirty)
        or %1101                ; readouts, HEX column, status line
        ld (txt_dirty),a
        call clear_check
        ld a,b
        push bc
        call dirty_row
        pop bc
        ret

bitmask: db $80,$40,$20,$10,$08,$04,$02,$01

; ---------------------------------------------------------------- undo (DRAW-02)
; A stroke is one undo step only if it changed something (TT-2).
stroke_begin:
        ld a,(layer)            ; on the mask layer: this frame's mask finished first (it may turn Hand;
        or a                    ; the other frames finish in the background)
        jr z,.nf
.mf:    call mask_pending
        or a
        jr z,.nf
        call mask_tick
        jr .mf
.nf:
        ld a,(mstyle)
        ld (pre_style),a
        call edit_frame         ; a stroke changes only the frame shown: keep it
        call frame_ptr
        ld a,(fbytes)
        ld c,a
        ld b,0
        ld de,pre_buf
        ld a,UNDO_BANK
        call page_bank
        ldir
        jp page_home

; HL = a sheet (sheet, or undo_buf with its bank paged in) -> BC = the bytes it uses: the head
; and sixteen frames of its box (pictures and masks). Keeps HL.
used_len:
        push hl
        ld bc,5
        add hl,bc
        ld l,(hl)
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl               ; 16 frames: the pictures and their masks
        ld bc,SHEET_HEAD
        add hl,bc
        ld b,h
        ld c,l
        pop hl
        ret

stroke_end:
        ld a,(stroke)
        or a
        ret z
        xor a
        ld (stroke),a
        call edit_frame
        call frame_ptr
        ld a,(fbytes)
        ld b,a
        ld de,pre_buf
        ld a,UNDO_BANK
        call page_bank
.cmp:   ld a,(de)
        cp (hl)
        jr nz,.diff
        inc hl
        inc de
        djnz .cmp
        jp page_home
.diff:  call page_home
        call les_free
        call drawer_dirty
        ld a,UNDO_BANK
        call page_bank
        ld hl,sheet             ; Undo's copy: the sheet with the frame as it was
        call used_len
        ld de,undo_buf
        ldir
        ld a,(pre_style)        ; the style as it was (a mask stroke turns it Hand)
        ld (undo_buf+mstyle-sheet),a
        call edit_frame
        ld hl,undo_buf+SHEET_HEAD
        call fmul
        ex de,hl
        ld hl,pre_buf
        ld a,(fbytes)
        ld c,a
        ld b,0
        ldir
        call page_home
        ld a,1
        ld (undo_ok),a
        xor a
        ld (undo_redo),a
        ret

; a change to the lessons' figure makes it the reader's: the next lesson takes a new one (m7-r1 F-80)
les_free:
        ld a,(sh_cur)
        ld hl,les_slot
        cp (hl)
        ret nz
        ld (hl),$ff
        ret

snapshot:
        call les_free
        xor a
        ld (sh_lundo),a         ; (a change to the figure: Undo is for that now)
        call drawer_dirty
        call clear_check
        ld a,UNDO_BANK
        call page_bank
        ld hl,sheet
        call used_len
        ld de,undo_buf
        ldir
        call page_home
        ld a,1
        ld (undo_ok),a
        xor a
        ld (undo_redo),a
        ret

do_undo:
        ld a,(undo_ok)
        or a
        ld a,EV_NO_UNDO
        jp z,refuse
        ld a,(sh_lundo)         ; the last change was a load: the sheets change places
        or a
        jr z,.fig
        call sh_unload
        call draw_desk
        ld a,(undo_redo)
        or a
        ld a,EV_UNDO
        jp nz,ok_event
        ld a,EV_REDO
        jp ok_event
.fig:
        call clear_check
        ld a,UNDO_BANK
        call page_bank
        ld hl,undo_buf          ; swap the larger of the two
        call used_len
        push bc
        ld hl,sheet
        call used_len
        pop hl
        or a
        sbc hl,bc
        add hl,bc
        jr c,.big
        ld b,h
        ld c,l
.big:   ld hl,sheet
        ld de,undo_buf
.sw:    ld a,(de)
        ldi
        dec hl
        ld (hl),a
        inc hl
        jp pe,.sw
        ld hl,(box_w)           ; box_w, box_h
        ld de,(undo_buf+2)
        call page_home
        or a
        sbc hl,de
        call nz,box_refresh
        ld a,(txt_dirty)        ; the name may have changed too
        or %100000
        ld (txt_dirty),a
        call drawer_dirty
        ld a,(undo_redo)
        xor 1
        ld (undo_redo),a
        ld a,EV_UNDO
        jr nz,.u
        ld a,EV_REDO
.u:     push af
        call fix_play
        call fig_check          ; the ink came back with the sheet: hard to see again?
        pop af
        jp ok_sheet

; ---------------------------------------------------------------- controls (DEV-03)
; A press with the Arrow off the Grid: the drawer (cols 23-31, rows 12-21) or a strip frame.
mouse_press:
        ld a,(input_dev)
        cp DEV_MOUSE
        ret nz
        ld a,(cur_y)
        rrca
        rrca
        rrca
        and 31
        ld b,a                  ; character row
        ld a,(cur_x)
        rrca
        rrca
        rrca
        and 31
        ld c,a                  ; character column
        cp RC
        jr c,.strip
        ld a,b
        sub DRAWER_ROW
        ret c
        cp N_ROWS
        ret nc
        or a
        ld a,A_DRAWER
        jp z,do_action
        ld a,b
        sub DRAWER_ROW+1
        call drawer_id
        jp do_action
.strip: ld a,b
        cp 19
        ret c
        cp 21
        ret nc
        ld a,c
        ld b,0
.div:   cp 3
        jr c,.dd
        sub 3
        inc b
        jr .div
.dd:    cp 2
        ret nc
        ld a,b
        ld hl,nframes
        cp (hl)
        ret nc
        ld (cur_frame),a
        call frame_changed
        ld a,EV_PICK
        ld (last_event),a
        ld a,1
        ld (sfx_req),a
        ret

; A = slot 0-8 of the current drawer -> A = action id
drawer_id:
        push af
        call drawer_list
        pop af
        ld e,a
        ld d,0
        add hl,de
        ld a,(hl)
        ret

; -> HL = the open drawer's list of actions. Corrupts A, DE.
drawer_list:
        ld hl,drawer_lists
drawer_pick:
        ld a,(drawer)
        add a,a
        ld e,a
        ld d,0
        add hl,de
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ret

drawer0: db A_PREV,A_NEXT,A_NEW,A_DEL,A_CLR,A_PLAY,A_SLOW,A_FAST,A_TITLE
drawer1: db A_UNDO,A_ONION,A_MIRROR,A_NUDGE_L,A_NUDGE_D,A_NUDGE_U,A_NUDGE_R,A_CHECK,A_TITLE
drawer2: db A_LIB,A_BIGGER,A_SMALLER,A_EVERY,A_SHEET,A_LESSONS,A_NONE,A_NONE,A_TITLE
drawer3: db A_LAYER,A_STYLE,A_GROUND,A_NONE,A_NONE,A_NONE,A_NONE,A_NONE,A_TITLE

key_actions:
        ld a,(FRESH3)
        ld c,a
        ld b,0
.l:     srl c
        jr nc,.n
        push bc
        ld a,b
        call do_action
        pop bc
.n:     inc b
        ld a,b
        cp 8
        jr nz,.l
        ld a,(FRESH4)
        ld c,a
        ld b,A_ONION
.l4:    srl c
        jr nc,.n4
        push bc
        ld a,b
        call do_action
        pop bc
.n4:    inc b
        ld a,b
        cp A_ONION+8
        jr nz,.l4
        ld a,(FRESH2)
        bit K_LIB,a
        ld b,A_LIB
        call nz,.one
        ld a,(FRESH2)
        bit K_EVERY,a
        ld b,A_EVERY
        call nz,.one
        ld a,(FRESH2)
        bit K_BIGGER,a
        ld b,A_BIGGER
        call nz,.one
        ld a,(FRESH2)
        bit K_SMALLER,a
        ld b,A_SMALLER
        call nz,.one
        ld a,(FRESH5)
        bit K_LAYER,a
        ld b,A_LAYER
        call nz,.one
        ld a,(FRESH5)
        bit K_STYLE,a
        ld b,A_STYLE
        call nz,.one
        ld a,(FRESH5)
        bit K_GROUND,a
        ld b,A_GROUND
        call nz,.one
        ld a,(FRESH5)
        bit K_SHEET,a
        ld b,A_SHEET
        call nz,.one
        ld a,(FRESH5)
        bit K_LESSONS,a
        ld b,A_LESSONS
        call nz,.one
        ld a,(FRESH2)
        bit K_FAST,a
        ret z
        ld a,A_FAST
        jr do_action
.one:   ld a,(state)            ; (an earlier action may have left the Desk)
        or a
        ret z
        ld a,b
do_action:
        push af
        call stroke_end         ; a stroke held across an action ends here (one Undo step each)
        pop af
        ld (act_id),a
        add a,a
        ld e,a
        ld d,0
        ld hl,act_table
        add hl,de
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        jp (hl)

act_table:
        dw act_prev,act_next,act_new,act_del,act_clr,do_undo,act_play,act_slow,act_fast,act_title
        dw act_onion,act_mirror,act_nudge_l,act_nudge_d,act_nudge_u,act_nudge_r,act_check,act_drawer
        dw act_bigger,act_smaller,act_lib,act_every,act_none,act_layer,act_style,act_ground,act_sheet,act_lessons

act_prev:
        ld a,(cur_frame)
        or a
        ld a,EV_NO_FIRST
        jp z,refuse
        ld hl,cur_frame
        dec (hl)
        call frame_changed
        ld a,EV_PREV
        jp ok_event

act_next:
        ld a,(nframes)
        dec a
        ld hl,cur_frame
        cp (hl)
        ld a,EV_NO_LAST
        jp z,refuse
        inc (hl)
        call frame_changed
        ld a,EV_NEXT
        jp ok_event

; A = count of frames -> BC = count * fbytes. Corrupts DE, HL.
frames_bytes:
        ld hl,0
        call fmul
        ld b,h
        ld c,l
        ret

; HL += A * fbytes (A at most 8). Corrupts A, DE. Keeps BC.
fmul:   or a
        ret z
        ld e,a
        ld a,(fbytes)
        ld d,0
        push bc
        ld b,e
        ld e,a
.m:     add hl,de
        djnz .m
        pop bc
        ret

act_new:
        ld a,(nframes)
        cp MAX_FRAMES
        ld a,EV_NO_MAX
        jp z,refuse
        call snapshot
        xor a                   ; the pictures, then the masks
        call new_move
        ld a,MAX_FRAMES
        call new_move
        ld hl,nframes
        inc (hl)
        ld hl,cur_frame
        inc (hl)
        ld a,EV_NEW
        jp ok_sheet

; A = 0 (pictures) or MAX_FRAMES (masks): the frames after the current one move up one, and the
; current one is copied after itself
new_move:
        ld (fp_base),a
        ld a,(nframes)
        ld hl,cur_frame
        sub (hl)
        dec a
        jr z,.copy
        call frames_bytes
        push bc
        ld a,(nframes)
        call frame_ptr
        dec hl
        call add_fbytes
        pop bc
        lddr
.copy:  ld a,(cur_frame)
        call frame_ptr
        call add_fbytes
        ld a,(fbytes)
        ld c,a
        ld b,0
        ldir
fp_home:
        xor a
        ld (fp_base),a
        ret

act_del:
        ld a,(nframes)
        cp 1
        ld a,EV_NO_ONE
        jp z,refuse
        call snapshot
        xor a
        call del_move
        ld a,MAX_FRAMES
        call del_move
        ld hl,nframes
        dec (hl)
        ld a,(cur_frame)
        or a
        jr z,.e
        dec a
        ld (cur_frame),a
.e:     call fix_play
        ld a,EV_DEL
        jp ok_sheet

; A = 0 or MAX_FRAMES: the frames after the current one move down one; the last is cleared
del_move:
        ld (fp_base),a
        ld a,(nframes)
        ld hl,cur_frame
        sub (hl)
        dec a
        jr z,.clrlast
        call frames_bytes
        push bc
        ld a,(cur_frame)
        call frame_ptr
        call add_fbytes
        ex de,hl
        pop bc
        ldir
.clrlast:
        ld a,(nframes)
        dec a
        call frame_ptr
        call clear_frame
        jr fp_home

act_clr:
        call snapshot
        ld a,(cur_frame)        ; the picture and its mask
        push af
        call frame_ptr
        call clear_frame
        pop af
        add a,MAX_FRAMES
        call frame_ptr
        call clear_frame
        ld a,EV_CLR
        jp ok_sheet

; HL = a frame: all its bytes 0
clear_frame:
        ld a,(fbytes)
        ld b,a
.z:     ld (hl),0
        inc hl
        djnz .z
        ret

; HL -> HL unchanged, DE = HL + fbytes
add_fbytes:
        push hl
        ld a,(fbytes)
        ld e,a
        ld d,0
        add hl,de
        ex de,hl
        pop hl
        ret

act_play:
        call drawer_dirty
        ld a,(play_on)
        xor 1
        ld (play_on),a
        ld a,(play_lvl)
        call play_reload
        xor a
        ld (play_frame),a
        ld a,(play_on)
        or a
        ld a,EV_PLAY
        jr nz,.e
        ld a,EV_STOP
.e:     jp ok_event

act_slow:
        ld a,(play_lvl)
        or a
        ld a,EV_NO_SLOW
        jp z,refuse
        ld hl,play_lvl
        dec (hl)
        ld a,EV_SLOW
        jp ok_event

act_fast:
        ld a,(play_lvl)
        cp 5
        ld a,EV_NO_FAST
        jp z,refuse
        ld hl,play_lvl
        inc (hl)
        ld a,EV_FAST
        jp ok_event

act_title:
        ld a,1
        ld (sfx_req),a
        jp enter_start

; ANIM-03: onion skin on/off
act_onion:
        ld a,(onion_on)
        xor 1
        ld (onion_on),a
        call dirty_all
        ld a,(onion_on)
        or a
        ld a,EV_ONION_ON
        jr nz,.e
        ld a,EV_ONION_OFF
.e:     jp ok_event

; TOOL-01: mirror left to right
; TOOL-01. Mirror and nudge act on the frame on the Desk, or on every frame while ALL is on
; (m2-r2 F-2): each body takes HL = a frame, B = its rows.
act_mirror:
        ld hl,mirror_body
        ld c,EV_MIRROR
        jr each_frame
act_nudge_l:
        ld hl,nudge_l_body
        jr nudge_each
act_nudge_r:
        ld hl,nudge_r_body
        jr nudge_each
act_nudge_u:
        ld hl,nudge_u_body
        jr nudge_each
act_nudge_d:
        ld hl,nudge_d_body
nudge_each:
        ld c,EV_NUDGE
each_frame:
        ld (ef_body),hl
        ld a,c
        ld (ef_ev),a
        call snapshot
        ld a,(every_on)
        or a
        jr nz,.all
        ld a,(cur_frame)
        call .one
        ld a,(ef_ev)
        jp ok_sheet
.all:   xor a
.l:     push af
        call .one
        pop af
        inc a
        ld hl,nframes
        cp (hl)
        jr c,.l
        ld a,(ef_ev)
        cp EV_MIRROR
        ld a,EV_MIRROR_ALL
        jp z,ok_sheet
        ld a,EV_NUDGE_ALL
        jp ok_sheet
.one:   push af                 ; A = frame: its body on the picture, then on its mask
        call .body
        pop af
        add a,MAX_FRAMES
.body:  call frame_ptr
        ld a,(box_h)
        ld b,a
        ld de,(ef_body)
        push de
        ret

; ALL (E): mirror and nudge every frame together
act_every:
        call drawer_dirty
        ld a,(every_on)
        xor 1
        ld (every_on),a
        ld a,EV_ALL_ON
        jr nz,.e
        ld a,EV_ALL_OFF
.e:     call ok_event
        jp btn_compose

mirror_body:
.l:     push bc
        ld a,(bpr)              ; the row's bytes into row_tmp backwards, each reversed
        ld b,a
        ld de,row_tmp+MAX_BPR
.r:     dec de
        ld a,(hl)
        inc hl
        push de
        call rev8
        pop de
        ld (de),a
        djnz .r
        ld a,(bpr)
        ld c,a
        ld b,0
        or a
        sbc hl,bc               ; back to the row's start
        ex de,hl                ; HL = row_tmp + MAX_BPR - bpr
        ldir                    ; DE = the next row
        ex de,hl
        pop bc
        djnz .l
        ret

; A -> A with its bits in reverse order. Keeps BC? no: corrupts B? uses D, E.
rev8:   ld e,a
        ld d,8
.l:     rr e
        rla
        dec d
        jr nz,.l
        ret

; TOOL-01: nudge one square, wrapping
nudge_l_body:
.l:     push bc
        ld a,(bpr)
        ld b,a
        ld e,a
        ld d,0
        ld c,(hl)               ; the row's first byte
        add hl,de
        push hl                 ; the next row
        ld a,c
        rlca                    ; CF = the leftmost dot, which comes back on the right
.b:     dec hl
        rl (hl)
        djnz .b
        pop hl
        pop bc
        djnz .l
        ret

nudge_r_body:
.l:     push bc
        ld a,(bpr)
        ld b,a
        ld e,a
        ld d,0
        push hl
        add hl,de
        dec hl
        ld c,(hl)               ; the row's last byte
        pop hl
        ld a,c
        rrca                    ; CF = the rightmost dot
.b:     rr (hl)
        inc hl
        djnz .b
        pop bc
        djnz .l
        ret

nudge_u_body:
        call nudge_v
        push hl                 ; the first row
        ld de,row_tmp
        ldir                    ; keep it; HL = the second row
        pop de
        ld a,(nudge_n)
        ld c,a
        ld b,0
        ldir                    ; the rest up one
        call nudge_v
        ld hl,row_tmp
        ldir                    ; the first row at the bottom
        ret

nudge_d_body:
        call nudge_v
        push bc
        ld a,(nudge_n)
        ld c,a
        ld b,0
        add hl,bc               ; HL = the last row
        pop bc
        push hl
        ld de,row_tmp
        ldir                    ; keep it
        pop hl
        dec hl                  ; HL = the row above's last byte
        ld d,h
        ld e,l
        call nudge_v
        ex de,hl
        add hl,bc
        ex de,hl                ; DE = the frame's last byte
        ld a,(nudge_n)
        ld c,a
        ld b,0
        lddr                    ; the rest down one
        inc de
        call nudge_v
        ex de,hl
        or a
        sbc hl,bc
        ex de,hl                ; DE = the first row
        ld hl,row_tmp
        ldir                    ; the last row at the top
        ret

; HL kept; BC = bpr; nudge_n = the bytes in all rows but one
nudge_v:
        ld a,(bpr)
        ld c,a
        ld b,0
        ld a,(fbytes)
        sub c
        ld (nudge_n),a
        ret

; CHECK-01: step to the next problem found; mark its squares on the Grid
act_check:
        ld a,(chk_pend)         ; checks still being worked out: CHECK acts when they are done, an
        or a                    ; update at a time (finishing them all at once took up to 7 frames,
        jr z,.go                ; m5-outside32 after the masks' Hand recounts: D-059)
        ld a,1
        ld (chk_wait),a
        ld a,EV_CHECKING        ; and says so (m5-r5 F-53)
        jp ok_event
.go:    ld a,(chk_total)
        or a
        ld a,EV_NOPROB
        jp z,ok_event
        ld a,(chk_sel)          ; slot = frame * 4 + check (0 stray, 1 alike, 2 outside the mask)
        ld c,a
        ld b,32
.next:  inc c
        ld a,c
        and 31
        ld c,a
        and 3
        cp 3
        jr z,.fig               ; slot 3: hard to see, slot 7: moves too far (the figure's)
        ld a,c
        srl a
        srl a                   ; frame
        ld hl,nframes
        cp (hl)
        jr nc,.skip
        ld e,a
        ld d,0
        ld a,c
        and 3
        cp 3
        jr z,.skip
        ld hl,stray_n           ; stray_n, alike, outside_n: MAX_FRAMES apart
.ty:    or a
        jr z,.t
        push de
        ld de,MAX_FRAMES
        add hl,de
        pop de
        dec a
        jr .ty
.t:     add hl,de
        ld a,(hl)
        or a
        jr nz,.found
.skip:  djnz .next
        ld a,EV_NOPROB
        jp ok_event
.fig:   ld a,c
        ld e,1
        cp 3
        jr z,.fg
        cp 7
        jr nz,.skip
        ld e,2
.fg:    ld a,(fig_flags)
        and e
        jr z,.skip
        ld a,c
        ld (chk_sel),a
        ld hl,check_bits        ; nothing to mark on the Grid: the Test Ground shows it
        ld de,check_bits+1
        ld bc,MAX_FBYTES-1
        ld (hl),0
        ldir
        ld a,(chk_sel)
        cp 3
        ld a,EV_HARD
        jp z,.mark
        ld a,EV_FAR
        jp .mark
.found: ld a,c
        ld (chk_sel),a
        srl a
        srl a
        ld (cur_frame),a
        ld (chk_frame),a
        inc a
        ld (ev_p1),a
        ld a,c
        and 3
        jr z,.str
        dec a
        jr z,.al
        ld a,(chk_frame)        ; ink outside the mask: those dots marked
        call frame_ptr
        push hl
        ld a,(chk_frame)
        add a,MAX_FRAMES
        call frame_ptr
        pop de
        ld bc,check_bits
        ld a,(fbytes)
.ou:    push af
        ld a,(hl)
        cpl
        ex de,hl
        and (hl)
        ex de,hl
        ld (bc),a
        inc hl
        inc de
        inc bc
        pop af
        dec a
        jr nz,.ou
        ld a,EV_OUTSIDE
        jr .mark
.str:   call check_abandon
        ld a,(chk_frame)
        ld de,check_bits
        call stray_bits
        ld a,EV_STRAY
        jr .mark
.al:    ld a,(chk_frame)
        call next_frame
        ld (cur_frame),a        ; show the later frame of the pair (the copy just made)
        ld (chk_frame),a
        inc a
        ld (ev_p2),a
        ld a,(chk_sel)
        srl a
        srl a
        ld c,a
        ld b,0
        ld hl,chk_need
        add hl,bc
        ld a,(hl)
        ld (ev_p3),a
        ld a,(chk_frame)
        call frame_ptr
        push hl
        ld a,(chk_sel)
        srl a
        srl a
        call frame_ptr
        pop de
        ld bc,check_bits
        ld a,(fbytes)
.x:     push af
        ld a,(de)
        xor (hl)
        ld (bc),a
        inc hl
        inc de
        inc bc
        pop af
        dec a
        jr nz,.x
        ld a,EV_ALIKE
.mark:  push af
        ld a,1
        ld (check_on),a
        call check_goto
        call frame_changed_keep
        pop af
        jp ok_event

; With keys or the stick, the Grid Cursor goes to the first square CHECK marks, so the cursor and the
; square readout point at it (m5-r1 F-29: a marked ink square on 4-dot squares is hard to find at 1x)
check_goto:
        ld a,(input_dev)
        cp DEV_DIR
        ret nz
        ld hl,check_bits
        ld a,(fbytes)
        ld b,a
        ld c,0                  ; C = byte index
.f:     ld a,(hl)
        or a
        jr nz,.got
        inc hl
        inc c
        djnz .f
        ret                     ; nothing marked (the figure's own checks)
.got:   ld d,0                  ; D = the dot in the byte
.b:     rla
        jr c,.bit
        inc d
        jr .b
.bit:   ld a,(bpr)              ; row = C / bpr, column = (C mod bpr) * 8 + D
        ld e,a
        ld a,c
        ld b,0
.dv:    cp e
        jr c,.dd
        sub e
        inc b
        jr .dv
.dd:    add a,a
        add a,a
        add a,a
        add a,d
        ld (gc_col),a
        ld a,b
        ld (gc_row),a
        call gc_pixels
        jp calc_square

; A = frame -> A = the frame after it in play order (wraps)
next_frame:
        inc a
        ld hl,nframes
        cp (hl)
        ret c
        xor a
        ret

act_drawer:
        call drawer_dirty
        ld a,(drawer)
        inc a
        and 3
        ld (drawer),a
        ld b,EV_DRAWER0
        jr z,.e
        ld b,EV_DRAWER1
        dec a
        jr z,.e
        ld b,EV_DRAWER2
        dec a
        jr z,.e
        ld b,EV_DRAWER3
.e:     ld a,b
        jp ok_event

act_none:
        ret

; MASK-01: the picture layer or the mask layer (the Grid paints the one shown)
act_layer:
        call drawer_dirty
        ld a,(layer)
        xor 1
        ld (layer),a
        call dirty_all
        ld a,(txt_dirty)
        or %1101                ; readouts, HEX column, status line
        ld (txt_dirty),a
        call desk_legend
        ld a,(layer)
        or a
        ld a,EV_LAYER_PIC
        jr z,.e
        ld a,EV_LAYER_MASK
.e:     call ok_event
        jp btn_compose

; the next mask style: Ring, Shape, Box, Hand (Hand keeps the masks as they are). One Undo step.
act_style:
        call snapshot           ; Ring, Shape, Box in turn (Hand comes from painting the mask; from
        ld a,(mstyle)           ; Hand, F goes to Ring and U brings the hand-made mask back: m4-r1 F-28)
        inc a
        cp MS_HAND
        jr c,.s
        xor a
.s:     ld (mstyle),a
        call mask_all_auto
        ld a,(layer)
        or a
        call nz,dirty_all
        ld a,(txt_dirty)
        or 4
        ld (txt_dirty),a
        ld a,(mstyle)
        add a,EV_MS_RING
        jp ok_sheet

; -> A nonzero if the current frame's mask is still to be worked out (not Hand)
mask_pending:
        ld a,(cur_frame)
        ld b,a
        ld a,(mk_st)            ; being worked out now?
        or a
        jr z,.n
        ld a,(mk_k)
        cp b
        ld a,1
        ret z
.n:     ld a,1                  ; waiting its turn?
        inc b
.s:     dec b
        jr z,.t
        add a,a
        jr .s
.t:     ld hl,mk_need
        and (hl)
        ret

; masks to work out unless Hand
mask_all_auto:
        ld a,(mstyle)
        cp MS_HAND
        ret z
        jp mask_all

; A = the frame the Grid edits: the current frame, or its mask on the mask layer
edit_frame:
        ld a,(layer)
        or a
        ld a,(cur_frame)
        ret z
        add a,MAX_FRAMES
        ret

; SHEET-01: the box steps through T-BOX-SIZES. Growing keeps the drawing at the top left;
; shrinking drops the dots outside the new box. One Undo step: the frames are rebuilt from the
; snapshot Undo keeps, so no frame is overwritten before it is read.
act_bigger:
        call box_index          ; the next size in the list that holds this box
        ld b,a
.n:     inc b
        ld a,b
        cp N_BOXES
        jr nc,.no
        call box_at
        ld a,(box_w)
        cp d
        jr z,.w
        jr nc,.n
.w:     ld a,(box_h)
        cp e
        jr z,.ok
        jr nc,.n
.ok:    ld a,b
        jr box_go
.no:    ld a,EV_NO_BIG
        jp refuse
act_smaller:
        call box_index          ; the size before it in the list that fits inside this box
        ld b,a
.p:     ld a,b
        or a
        jr z,.no
        dec b
        call box_at
        ld a,(box_w)
        cp d
        jr c,.p
        ld a,(box_h)
        cp e
        jr c,.p
        ld a,b
        jr box_go
.no:    ld a,EV_NO_SMALL
        jp refuse

; B = place in box_list -> D = across, E = down
box_at: ld a,b
        add a,a
        ld e,a
        ld d,0
        ld hl,box_list
        add hl,de
        ld d,(hl)
        inc hl
        ld e,(hl)
        ret

; A = place in box_list
box_go: ld b,0
box_step:
        add a,b
        add a,a
        ld e,a
        ld d,0
        ld hl,box_list
        add hl,de
        push hl
        call snapshot
        pop hl
        ld a,(hl)
        ld (box_w),a
        inc hl
        ld a,(hl)
        ld (box_h),a
        call box_derive
        ld a,UNDO_BANK          ; the old sheet, from Undo's copy
        call page_bank
        xor a                   ; the pictures (frames 0..), then their masks (frames 8..)
        call box_pack
        ld a,MAX_FRAMES
        call box_pack
        call page_home
        call box_refresh
        ld a,EV_BOX
        jp ok_sheet

; A = the first frame (0 pictures, 8 masks): nframes frames rebuilt in the new box from the old
; (undo_buf paged in): zeroed, then each old row's bytes that fit, top left
box_pack:
        push af
        ld hl,frames_data
        call fmul               ; the new frames' start
        ld (bx_dst),hl
        pop af
        push af
        ld b,a                  ; the old: undo_buf + head + A * old fbytes
        ld hl,undo_buf+SHEET_HEAD
        ld a,(undo_buf+5)
        ld e,a
        ld d,0
        ld a,b
        or a
        jr z,.o
.om:    add hl,de
        djnz .om
.o:     ld (bx_src),hl
        pop af
        ld a,(nframes)
        call frames_bytes       ; zero the new frames
        ld hl,(bx_dst)
        ld (hl),0
        dec bc
        ld a,b
        or c
        jr z,.z
        ld d,h
        ld e,l
        inc de
        ldir
.z:     ld a,(undo_buf+3)       ; old box_h
        ld hl,box_h
        cp (hl)
        jr c,.h
        ld a,(hl)
.h:     ld (bx_rows),a          ; rows copied: the smaller height
        ld a,(undo_buf+4)       ; old bpr
        ld hl,bpr
        cp (hl)
        jr c,.w
        ld a,(hl)
.w:     ld (bx_cols),a          ; bytes copied: the smaller width
        ld a,(nframes)
        ld c,a
.f:     push bc
        ld hl,(bx_src)
        ld de,(bx_dst)
        ld a,(bx_rows)
        ld b,a
.r:     push bc
        push hl
        push de
        ld a,(bx_cols)
        ld c,a
        ld b,0
        ldir
        pop hl
        ld a,(bpr)
        ld e,a
        ld d,0
        add hl,de
        ex de,hl                ; DE = the next new row
        pop hl
        ld a,(undo_buf+4)
        ld c,a
        ld b,0
        add hl,bc               ; HL = the next old row
        pop bc
        djnz .r
        ld hl,(bx_src)
        ld a,(undo_buf+5)
        ld c,a
        ld b,0
        add hl,bc
        ld (bx_src),hl
        ld hl,(bx_dst)
        ld a,(fbytes)
        ld c,a
        add hl,bc
        ld (bx_dst),hl
        pop bc
        dec c
        jr nz,.f
        ret

; -> A = the box's place in box_list (0 if it is not there)
box_index:
        ld hl,box_list
        ld b,0
.l:     ld a,(box_w)
        cp (hl)
        inc hl
        jr nz,.n
        ld a,(box_h)
        cp (hl)
        jr z,.f
.n:     inc hl
        inc b
        ld a,b
        cp N_BOXES
        jr nz,.l
        ld b,0
.f:     ld a,b
        ret

; box_w, box_h -> bpr, fbytes
box_derive:
        ld a,(box_w)
        rrca
        rrca
        rrca
        and $1f
        ld (bpr),a
        ld b,a
        ld a,(box_h)
        ld c,a
        xor a
.m:     add a,c
        djnz .m
        ld (fbytes),a
        ret

; The box (or the figure) changed: the Grid's scale, the cursor's limits, every picture, the
; sheet's numbers, the header and the HEX column follow. Also called on entering the Desk.
box_refresh:
        ld a,(box_w)
        cp 17
        jr nc,.big
        ld a,(box_h)
        cp 17
.big:   ld a,0
        jr c,.s
        inc a
.s:     ld (sq_sh),a            ; 0: squares of 8 dots; 1: squares of 4 dots, 2 x 2 a cell
        ld hl,gc_col            ; the Grid Cursor stays inside the box
        ld a,(box_w)
        dec a
        cp (hl)
        jr nc,.c
        ld (hl),a
.c:     ld hl,gc_row
        ld a,(box_h)
        dec a
        cp (hl)
        jr nc,.r
        ld (hl),a
.r:     ld a,(input_dev)
        cp DEV_DIR
        call z,gc_pixels
        xor a
        ld (cur_was_ok),a
        ld a,$ff
        ld (cd_band),a
        xor a                   ; what is on the Grid was drawn at the old scale: draw every cell
        ld (sq_n),a
        ld hl,row_force
        ld b,16
.rf:    ld (hl),1
        inc hl
        djnz .rf
        call set_caps
        call dirty_all
        call img_all_full
        ld a,(txt_dirty)
        or %01110101            ; readouts, HEX column, header, the sheet's numbers
        ld (txt_dirty),a
        jp checks_again

; A = frame -> HL = its first byte. Corrupts DE.
frame_ptr:
        ld hl,fp_base           ; (fp_base MAX_FRAMES: the same frame's mask, for new and delete)
        add a,(hl)
        ld hl,frames_data
        jp fmul

; the current frame changed (or what it shows): checks unmarked, everything redrawn
frame_changed:
        call clear_check
frame_changed_keep:
        call img_cards
        ld a,(txt_dirty)
        or %1101                ; readouts, HEX column, status line
        ld (txt_dirty),a
        jp dirty_all

drawer_dirty:
        ld a,(txt_dirty)
        or 2
        ld (txt_dirty),a
        ret

clear_check:
        ld a,(check_on)
        or a
        ret z
        xor a
        ld (check_on),a
        ld a,$ff
        ld (chk_sel),a
        jp dirty_all

fix_play:
        ld a,(nframes)
        ld hl,play_frame
        cp (hl)
        jr z,.p0
        jr nc,.c
.p0:    ld (hl),0
.c:     ld hl,cur_frame
        cp (hl)
        jr z,.f
        ret nc
.f:     dec a
        ld (hl),a
        ret

; A = event after a change to the sheet
ok_sheet:
        push af
        call checks_again
        call frame_changed
        call img_all
        pop af
; A = event: act_id's control lights, the status line names it, a blip.
ok_event:
        ld (last_event),a
        call img_cards
        ld c,AT_LIT
        ld a,LIGHT_TIME
        jr light
refuse:
        ld (last_event),a
        ld c,AT_NO_A
        ld a,NO_TIME
; act_id's control (if it is in the open drawer) shows attribute C for A updates
light:
        ld (light_t),a
        ld a,(txt_dirty)
        or %1001                ; readouts and status line
        ld (txt_dirty),a
        ld a,c
        ld (light_attr),a
        cp AT_NO_A              ; the sound: refused, undo or redo, else a click
        ld a,2
        jr z,.k
        ld a,(last_event)
        sub EV_UNDO
        cp 2
        ld a,4
        jr c,.k
        ld a,1
.k:     ld (sfx_req),a
        ld a,(act_id)
        cp A_DRAWER
        ld b,0
        jr z,.got
        ld c,a
        push bc
        call drawer_list
        pop bc
        ld b,1
.s:     ld a,(hl)
        cp c
        jr z,.got
        inc hl
        inc b
        ld a,b
        cp N_ROWS
        jr nz,.s
        ld b,0                  ; not in the open drawer: the drawer switch shows it
.got:   ld a,b
        ld (light_row),a
        ret

light_tick:
        ld a,(light_row)
        cp $ff
        jr z,btn_compose
        ld hl,light_t
        dec (hl)
        jr nz,btn_compose
        ld a,$ff
        ld (light_row),a
; btn_want: the drawer rows' colours (switch, controls, an onion skin that is on, a light)
btn_compose:
        ld hl,btn_want
        ld (hl),AT_TAB
        inc hl
        ld b,N_ROWS-1
.f:     ld (hl),AT_BUTTON
        inc hl
        djnz .f
        ld a,(drawer)           ; toggles that are on show green: TRACING (drawer 1), ALL (drawer 2)
        cp 1
        jr nz,.d2
        ld a,(onion_on)
        or a
        jr z,.lit
        ld a,AT_CHOSEN
        ld (btn_want+2),a
        jr .lit
.d2:    cp 3
        jr nz,.d2b
        ld a,(layer)
        or a
        jr z,.lit
        ld a,AT_CHOSEN
        ld (btn_want+1),a       ; drawer 3, slot 1: the mask layer
        jr .lit
.d2b:   cp 2
        jr nz,.lit
        ld a,(every_on)
        or a
        jr z,.lit
        ld a,AT_CHOSEN
        ld (btn_want+4),a
.lit:   ld a,(light_row)
        cp $ff
        ret z
        ld e,a
        ld d,0
        ld hl,btn_want
        add hl,de
        ld a,(light_attr)
        cp AT_NO_A
        jr nz,.put
        ld a,(light_t)
        cp 17
        ld a,AT_NO_A
        jr nc,.put
        ld a,AT_NO_B
.put:   ld (hl),a
        ret

; ANIM-02: the flip-book turns a page every play time
play_tick:
        ld a,(play_on)
        or a
        ret z
        ld hl,play_t
        dec (hl)
        ret nz
        ld a,(play_lvl)
        call play_reload
        ld a,(play_frame)
        call next_frame
        ld (play_frame),a
        ld a,(img_need)
        or 2
        ld (img_need),a
        ld hl,$ff00             ; every row: a new page, not a painted row
        ld (img_rlo),hl
        ret

play_reload:
        ld e,a
        ld d,0
        ld hl,play_times
        add hl,de
        ld a,(hl)
        ld (play_t),a
        ret

play_times: db 16,12,8,6,4,2      ; T-PLAY-TIMES in updates: 0.32 .. 0.04 s

; inked = ink squares in the current frame (HARNESS_score)
count_inked:
        ld a,(cur_frame)
        call frame_ptr
        ld a,(fbytes)
        ld b,a
        call popcount
        ld (inked),de
        ret

; HL = bytes, B = count -> DE = ink dots in them (pc_table: dots in each byte value)
popcount:
        ld de,0
.l:     ld a,(hl)
        inc hl
        push hl
        ld l,a
        ld h,high pc_table
        ld a,(hl)
        pop hl
        add a,e
        ld e,a
        jr nc,.n
        inc d
.n:     djnz .l
        ret

build_pc:
        ld hl,pc_table
.v:     ld a,l
        ld c,0
.b:     or a
        jr z,.s
        add a,a
        jr nc,.b
        inc c
        jr .b
.s:     ld (hl),c
        inc l
        jr nz,.v
        ret

; ---------------------------------------------------------------- checks (CHECK-01)
; Round robin, one frame at a time, spread over updates so no update does too much whatever the
; box (late, never wrong): phase 1 finds the frame's stray dots SB_CAP rows an update; phase 2
; counts how it differs from the next frame AL_CAP bytes an update. chk_pend frames to go.
SB_CAP  equ 4
AL_CAP  equ 16

; the sheet changed: every frame is checked again, from a fresh start
checks_again:
        ld a,(nframes)
        ld (chk_pend),a
        xor a
        ld (chk_ph),a
        jp mask_again           ; the masks follow the picture too (not Hand)

check_tick:
        ld a,(chk_ph)
        or a
        jr nz,.go
        ld a,(chk_k)            ; the next frame in turn
        inc a
        ld hl,nframes
        cp (hl)
        jr c,.k
        xor a
.k:     ld (chk_k),a
        ld de,chk_buf
        call stray_init
        ld a,1
        ld (chk_ph),a
.go:    dec a
        jr nz,.alike
        ld a,SB_CAP
        call stray_rows
        ret nz                  ; rows still to do
        ld hl,chk_buf
        ld a,(fbytes)
        ld b,a
        call popcount
        ld a,(chk_k)
        ld c,a
        ld b,0
        ld a,d                  ; 256 or more: saturate, so a count of 256 still reads as some
        or a
        jr z,.s1
        ld e,255
.s1:    ld hl,stray_n
        add hl,bc
        ld (hl),e
        call outside_count
        ; too alike: (different squares) * 10 < (squares ink in either)
        xor a
        ld (chk_al),a
        ld a,(nframes)
        cp 2
        jp c,.store
        ld a,(chk_k)
        call frame_ptr
        ld (al_a),hl
        ld a,(chk_k)
        call next_frame
        call frame_ptr
        ld (al_b),hl
        ld hl,0
        ld (al_d),hl
        ld (al_u),hl
        ld a,(fbytes)
        ld (al_n),a
        ld a,2
        ld (chk_ph),a
        ret
.alike: ld a,(al_n)
        cp AL_CAP+1
        jr c,.last
        sub AL_CAP
        ld (al_n),a
        ld b,AL_CAP
        jp alike_bytes
.last:  ld b,a
        call alike_bytes
        ld de,(al_u)
        ld hl,(al_d)
        ld b,h
        ld c,l
        add hl,hl
        add hl,hl
        add hl,bc
        add hl,hl               ; diff * 10
        or a
        sbc hl,de
        jr nc,.store
        ld a,1
        ld (chk_al),a
        ; the fewest squares to change: rubbing out a square inked in both frames adds one to
        ; the difference and nothing to the union, so ceil((union - 10 * diff) / 10), shown
        ; "n OR MORE" (m2-r3 F-2); HL = 10 * diff - union (negative here)
        xor a
        sub l
        ld l,a
        sbc a,a
        sub h
        ld h,a                  ; HL = union - 10 * diff
        ld de,9
        add hl,de
        ld c,0
        ld de,10
.dv:    or a
        sbc hl,de
        jr c,.dd
        inc c
        jr .dv
.dd:    ld a,(chk_k)
        ld e,a
        ld d,0
        ld hl,chk_need
        add hl,de
        ld (hl),c
.store: xor a                   ; this frame is done
        ld (chk_ph),a
        ld hl,chk_pend
        dec (hl)
        ld a,(chk_k)
        ld c,a
        ld b,0
        ld hl,alike
        add hl,bc
        ld a,(chk_al)
        ld (hl),a
        ; total problems over the real frames
        ld hl,stray_n
        ld de,alike
        ld a,(nframes)
        ld b,a
        ld c,0
.t:     ld a,(hl)
        or a
        jr z,.t1
        inc c
.t1:    ld a,(de)
        or a
        jr z,.t2
        inc c
.t2:    push hl
        push de
        ld de,2*MAX_FRAMES
        add hl,de               ; outside_n
        ld a,(hl)
        pop de
        pop hl
        or a
        jr z,.t3
        inc c
.t3:    inc hl
        inc de
        djnz .t
        ld a,c
        ld (chk_ftot),a
; chk_total = the frames' checks + the figure's (fig_flags)
chk_sum:
        ld a,(fig_flags)
        ld c,a
        ld a,(chk_ftot)
        bit 0,c
        jr z,.s1
        inc a
.s1:    bit 1,c
        jr z,.s2
        inc a
.s2:    ld hl,chk_total
        cp (hl)
        ret z
        ld (hl),a
        ld a,(txt_dirty)
        or 1
        ld (txt_dirty),a
        ret

; the figure's own checks: hard to see (its ink and the Ground's paper both white, yellow or cyan,
; T-HARD-PAIRS) and moves too far (a step over T-STEP-MAX, 4 dots)
fig_check:
        ld a,(gn_ground)
        ld e,a
        ld d,0
        ld hl,gn_attrs
        add hl,de
        ld a,(hl)
        rrca
        rrca
        rrca
        and 7
        ld c,0
        cp 5
        jr c,.n
        ld a,(fig_ink)
        cp 5
        jr c,.n
        inc c
.n:     ld a,(wk_step)
        cp 3
        jr c,.s
        set 1,c
.s:     ld a,c
        ld (fig_flags),a
        jr chk_sum

; chk_k's frame: outside_n = its ink dots the mask does not cover (Hand only: the other styles
; always cover the ink), saturating at 255
outside_count:
        ld a,(chk_k)
        ld e,a
        ld d,0
        ld hl,outside_n
        add hl,de
        ld (hl),0
        ld a,(mstyle)
        cp MS_HAND
        ret nz
        push hl
        ld a,(chk_k)
        call frame_ptr
        push hl
        ld a,(chk_k)
        add a,MAX_FRAMES
        call frame_ptr
        pop de                  ; DE = picture, HL = mask
        ld a,(fbytes)
        ld b,a
        ld c,0
.l:     ld a,(hl)
        cpl
        ex de,hl
        and (hl)
        ex de,hl
        push hl
        ld l,a
        ld h,high pc_table
        ld a,(hl)
        pop hl
        add a,c
        jr nc,.n
        ld a,255
.n:     ld c,a
        inc hl
        inc de
        djnz .l
        pop hl
        ld (hl),c
        ret

; B bytes of the pair (al_a, al_b): al_d += dots that differ, al_u += dots ink in either
alike_bytes:
        ld hl,(al_a)
        ld de,(al_b)
.l:     ld a,(de)
        ld c,a
        or (hl)
        push hl
        ld h,high pc_table
        ld l,a
        ld a,(hl)
        ld hl,(al_u)
        add a,l
        ld l,a
        jr nc,.u
        inc h
.u:     ld (al_u),hl
        pop hl
        ld a,c
        xor (hl)
        push hl
        ld h,high pc_table
        ld l,a
        ld a,(hl)
        ld hl,(al_d)
        add a,l
        ld l,a
        jr nc,.d
        inc h
.d:     ld (al_d),hl
        pop hl
        inc hl
        inc de
        djnz .l
        ld (al_a),hl
        ld (al_b),de
        ret

; act_check used the stray-dot workspace: a frame half done starts again
check_abandon:
        ld a,(chk_ph)
        dec a
        ret nz
        ld (chk_ph),a
        ld hl,chk_k
        dec (hl)
        ret

; A = frame, DE = fbytes output -> the frame's stray dots (ink with no ink among its eight
; neighbours), row by row in the frame's layout. Each row is copied into sb_rows beside the rows
; above and below (blank past the box's edges), so one loop serves every box width.
SB_A    equ 0                   ; sb_rows: above, this row, below and V, MAX_BPR+2 bytes each
SB_R    equ MAX_BPR+2
SB_B    equ 2*(MAX_BPR+2)
SB_V    equ 3*(MAX_BPR+2)
stray_bits:
        call stray_init
        ld a,255
        jp stray_rows

stray_init:
        ld (sb_out),de
        call frame_ptr
        ld (sb_src),hl
        ld hl,zero32
        ld (sb_u),hl
        ld a,(bpr)
        ld e,a
        ld d,0
        ld hl,sb_rows+SB_V+1
        add hl,de
        ld (hl),0               ; V's blank byte on the right (the left one is never written)
        ld a,(box_h)
        ld (sb_n),a
        ret

; A = rows at most this call -> Z: the frame is done; NZ: rows still to do
stray_rows:
        ld (sb_cap),a
.row:   ld hl,(sb_src)
        ld a,(bpr)
        ld c,a
        ld b,0
        add hl,bc
        ld a,(sb_n)
        dec a
        jr nz,.hb
        ld hl,zero32
.hb:    ld (sb_d),hl
        ld a,c
        ld hl,(sb_u)
        ld de,sb_rows+SB_A+1
        ldir
        ld c,a
        ld hl,(sb_src)
        ld de,sb_rows+SB_R+1
        ldir
        ld c,a
        ld hl,(sb_d)
        ld de,sb_rows+SB_B+1
        ldir
        ld b,a
        ld ix,sb_rows+1
.v:     ld a,(ix+SB_A)          ; V = above | this | below
        or (ix+SB_R)
        or (ix+SB_B)
        ld (ix+SB_V),a
        inc ix
        djnz .v
        ld a,(bpr)
        ld b,a
        ld ix,sb_rows+1
        ld hl,(sb_out)
.n:     ld a,(ix+SB_V+1)        ; N = above | below | V << 1 | V >> 1, across the bytes
        rla
        ld a,(ix+SB_V)
        rla
        ld c,a
        ld a,(ix+SB_V-1)
        rra
        ld a,(ix+SB_V)
        rra
        or c
        or (ix+SB_A)
        or (ix+SB_B)
        cpl
        and (ix+SB_R)           ; stray = this & ~N
        ld (hl),a
        inc hl
        inc ix
        djnz .n
        ld (sb_out),hl
        ld hl,(sb_src)          ; down a row
        ld (sb_u),hl
        ld a,(bpr)
        ld e,a
        ld d,0
        add hl,de
        ld (sb_src),hl
        ld hl,sb_n
        dec (hl)
        ret z
        ld hl,sb_cap
        dec (hl)
        jp nz,.row
        inc (hl)                ; NZ
        ret

; ---------------------------------------------------------------- the Grid's kinds
; The Grid is 16 x 16 character cells. Squares of 8 dots (boxes up to 16 x 16): a cell is one
; square, its kind in grid_want (bit 0 ink, 1 onion, 2 check mark, 3 cursor). Squares of 4 dots
; (bigger boxes): a cell is 2 x 2 squares, their kinds as nibbles, the top pair in grid_want
; (left low) and the bottom pair 256 bytes on (grid_want+256). OUTSIDE in both: not in the box.
; grid_want for dirty rows (at most GC_CAP8 or GC_CAP4 an update); then queue cells whose want
; differs from grid_have.
GC_CAP8 equ 4
GC_CAP4 equ 1

grid_compute:
        ld a,(grid_any)
        or a
        ret z
        xor a
        ld (grid_any),a         ; set again if rows are left for the next update
        ld a,(sq_sh)
        or a
        ld a,GC_CAP8
        jr z,.cap
        ld a,GC_CAP4
.cap:   ld (gc_rows),a
        call gc_setup
        ld c,0                  ; cell row
.row:   ld hl,row_dirty
        ld b,0
        add hl,bc
        ld a,(hl)
        or a
        jr z,.next
        ld a,(gc_rows)
        or a
        jr nz,.do
        inc a
        ld (grid_any),a
        jr grid_queue
.do:    dec a
        ld (gc_rows),a
        ld (hl),0
        ld hl,row_pend
        add hl,bc
        ld (hl),1
        ld hl,row_force         ; drawn at the old scale: every cell of the row again
        add hl,bc
        ld a,(hl)
        or a
        jr z,.nf
        ld (hl),0
        ld a,c
        add a,a
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld hl,grid_have
        add hl,de
        ld b,16
.fv:    ld (hl),$fe             ; a kind no cell can want
        inc hl
        djnz .fv
.nf:    push bc
        call cell_row
        pop bc
.next:  inc c
        ld a,c
        cp 16
        jr nz,.row
; queue up to SQ_CAP cells from pending rows whose want differs from have
grid_queue:
        ld a,(sq_n)             ; cells queued but not drawn yet (a late update skipped its draw):
        or a                    ; keep them, queue more next time (D-040)
        jr z,.fill
        ld a,1
        ld (grid_any),a
        ret
.fill:  xor a
        ld (sq_n),a
        ld ix,sq_queue
        ld c,0
.r:     ld hl,row_pend
        ld b,0
        add hl,bc
        ld a,(hl)
        or a
        jr z,.nr
        push hl
        ld a,c
        add a,a
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld hl,grid_want
        add hl,de
        push hl
        ld hl,grid_have
        add hl,de
        ex de,hl                ; DE = have
        pop hl                  ; HL = want
        ld b,16
.s:     ld a,(de)
        cp (hl)
        jr nz,.diff
        inc d
        inc h
        ld a,(de)
        xor (hl)
        dec d
        dec h
        or a                    ; (the decrements set Z of their own)
        jr z,.same
.diff:  ld a,(sq_n)
        push hl
        ld hl,sq_cap
        cp (hl)
        pop hl
        jr z,.full
        inc a
        ld (sq_n),a
        ld a,(hl)
        ld (de),a
        ld (ix+1),a             ; kind (top pair)
        inc h
        inc d
        ld a,(hl)
        ld (de),a
        ld (ix+2),a             ; bottom pair
        dec h
        dec d
        ld a,c
        add a,a
        add a,a
        add a,a
        add a,a
        add a,16
        sub b                   ; row * 16 + (16 - B) = the cell
        ld (ix+0),a
        inc ix
        inc ix
        inc ix
.same:  inc hl
        inc de
        djnz .s
        pop hl
        ld (hl),0               ; this row is done
.nr:    inc c
        ld a,c
        cp 16
        jr nz,.r
        ret
.full:  pop hl                  ; the row stays pending
        ld a,1
        ld (grid_any),a
        ret

; the frames under the Grid: the current one, the one before (tracing paper), the check marks
gc_setup:
        xor a
        ld (gc_on),a
        ld a,(onion_on)
        or a
        jr z,.noon
        ld a,(nframes)
        cp 2
        jr c,.noon
        ld a,(cur_frame)
        or a
        jr nz,.pv
        ld a,(nframes)
.pv:    dec a
        call frame_ptr
        ld (gc_prev),hl
        ld a,1
        ld (gc_on),a
.noon:  ld a,(layer)            ; the mask layer: kind bit 1 is the mask's cover
        or a
        jr z,.nm
        ld a,(cur_frame)
        add a,MAX_FRAMES
        call frame_ptr
        ld (gc_prev),hl
        ld a,2
        ld (gc_on),a
.nm:    xor a
        ld (ex_mk),a
        ld a,(gc_on)            ; the mask layer while this frame's mask is still being worked out:
        cp 2                    ; ink is covered in every style but Hand, so show that and nothing
        jr nz,.nm2              ; more until the mask is done (late, never wrong: m4-r2 F-36)
        call mask_pending
        ld (ex_mk),a
.nm2:   xor a
        ld (ex_fl),a
        ld a,(check_on)
        or a
        jr z,.nf
        ld a,(chk_frame)
        ld hl,cur_frame
        cp (hl)
        jr nz,.nf
        ld a,1
        ld (ex_fl),a
.nf:    ld a,(cur_frame)
        call frame_ptr
        ld (gc_cur),hl
        ret

; C = cell row -> its 16 cells' kinds in grid_want (both pairs)
cell_row:
        ld a,c
        add a,a
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld hl,grid_want
        add hl,de
        ld (gw_dst),hl
        ld a,(sq_sh)
        or a
        jr nz,.four
        ld a,c                  ; squares of 8 dots: cell row = square row
        ld hl,box_h
        cp (hl)
        jr nc,.out
        ld de,kbuf
        call expand_row
        ld de,(gw_dst)
        ld hl,kbuf
        ld a,(box_w)
        ld b,a
.c8:    ld a,(hl)
        ld (de),a
        inc d
        xor a
        ld (de),a
        dec d
        inc hl
        inc de
        djnz .c8
        ld a,(box_w)
        jr .rest
.four:  ld a,c                  ; squares of 4 dots: two square rows a cell row
        add a,a
        ld hl,box_h
        cp (hl)
        jr nc,.out
        push af
        ld de,kbuf
        call expand_row
        pop af
        inc a
        ld de,kbuf+32
        call expand_row
        ld de,(gw_dst)
        ld ix,kbuf
        ld a,(box_w)
        rrca
        and $1f
        ld b,a                  ; cells across
.c4:    ld a,(ix+1)
        add a,a
        add a,a
        add a,a
        add a,a
        or (ix+0)
        ld (de),a
        inc d
        ld a,(ix+33)
        add a,a
        add a,a
        add a,a
        add a,a
        or (ix+32)
        ld (de),a
        dec d
        inc ix
        inc ix
        inc de
        djnz .c4
        ld a,(box_w)
        rrca
        and $1f
.rest:  sub 16                  ; the cells right of the box
        ret z
        neg
        ld b,a
        jr .fill
.out:   ld de,(gw_dst)
        ld b,16
.fill:  ld a,OUTSIDE
.f:     ld (de),a
        inc d
        ld (de),a
        dec d
        inc de
        djnz .f
        ret

; A = square row, DE = out -> a kind for each square of the row (bpr * 8 of them)
expand_row:
        ld (ex_out),de
        ld (ex_row),a
        ld e,a
        ld d,0
        ld hl,0
        ld a,(bpr)
        ld b,a
.m:     add hl,de
        djnz .m
        ld (ex_off),hl
        ld de,(gc_cur)
        add hl,de
        ld (ex_pi),hl
        ld hl,(ex_off)
        ld de,(gc_prev)
        add hl,de
        ld (ex_pp),hl
        ld hl,(ex_off)
        ld de,check_bits
        add hl,de
        ld (ex_pc),hl
        ld a,(bpr)
        ld (ex_n),a
        ld hl,(ex_out)
.b:     push hl
        ld hl,(ex_pi)
        ld b,(hl)               ; ink
        inc hl
        ld (ex_pi),hl
        ld hl,(ex_pp)
        ld c,0
        ld a,(gc_on)
        or a
        jr z,.no
        cp 2
        ld a,(hl)
        jr nz,.tp
        ld a,(ex_mk)            ; the mask layer: cover (the ink, while the mask is pending)
        or a
        ld a,(hl)
        jr z,.mk
        ld a,b
        jr .mk
.tp:
        ld a,b
        cpl
        and (hl)                ; tracing paper: ink in the frame before, paper here
.mk:    ld c,a
.no:    inc hl
        ld (ex_pp),hl
        ld hl,(ex_pc)
        ld d,0
        ld a,(ex_fl)
        or a
        jr z,.nf
        ld d,(hl)               ; check marks
.nf:    inc hl
        ld (ex_pc),hl
        pop hl
        call byte8
        ld a,(ex_n)
        dec a
        ld (ex_n),a
        jr nz,.b
        ld a,(sq_ok)            ; the cursor's square
        or a
        ret z
        ld a,(sq_row)
        ld hl,ex_row
        cp (hl)
        ret nz
        ld a,(sq_col)
        ld e,a
        ld d,0
        ld hl,(ex_out)
        add hl,de
        set 3,(hl)
        ret

; B ink, C onion, D check bits (left dot first) -> 8 kinds at (HL)+
byte8:  ld a,8
.b8:    ld e,0
        sla d
        rl e
        sla c
        rl e
        sla b
        rl e
        ld (hl),e
        inc hl
        dec a
        jr nz,.b8
        ret

; ---------------------------------------------------------------- screens
enter_start:
        xor a
        ld (state),a
        ld (phase),a
        ld (input_dev),a
        call lock_buttons
        ld a,SONG_START
        ld (song_req),a
        jp draw_start

enter_desk:
        ld a,1
        ld (visited),a
        ld a,ST_DESK
        ld (state),a
        ld (phase),a
        call lock_buttons
        jp draw_desk

; Screen change: attributes black first, so nothing is seen half-drawn.
new_screen:
        ld a,1
        ld (redraw),a
        xor a
        ld (cur_drawn),a
        ld (music_dirty),a
        ld (pend_n),a
        ld (sq_n),a
        ld hl,$5800
        ld de,$5801
        ld bc,767
        ld (hl),0
        ldir
        ld hl,$4000
        ld de,$4001
        ld bc,6143
        ld (hl),0
        ldir
        xor a
        out ($fe),a
        ret

set_attrs:
        ld hl,$5800
        ld de,$5801
        ld bc,767
        ld (hl),a
        ldir
        ret

; The Start screen: the picture (rows 0-15, unpacked whole: bitmap first, colours last), then the
; menu in the black rows below it, coloured once it is printed.
draw_start:
        call new_screen
        ld a,START_BANK         ; the packed picture is in bank 4 (D-044)
        call page_bank
        ld hl,start_rle
        ld de,$4000
        call unpack_rle
        call page_home
        ld hl,start_text
        call print_list
        ld hl,start_first
        ld a,(visited)
        or a
        jr z,.t
        ld hl,start_again
.t:     call print_list
        ld de,$1000
        ld bc,$2007
        ld a,AT_DEFAULT
        call fill_attr
        ld de,$1103
        ld bc,$0901
        ld a,AT_CHOSEN
        call fill_attr
        ld de,$110e
        ld bc,$1101
        ld a,AT_CHOSEN
        call fill_attr
        ld a,$40
        call house_footer
        jp show_music

; HL = (count, byte) runs -> DE, 6912 bytes in all
unpack_rle:
        ld bc,6912
.run:   ld a,(hl)
        inc hl
        push bc
        ld b,a
        ld a,(hl)
        inc hl
.put:   ld (de),a
        inc de
        djnz .put
        pop bc
        dec hl
        dec hl
        ld a,c
        sub (hl)
        ld c,a
        jr nc,.nc
        dec b
.nc:    inc hl
        inc hl
        ld a,b
        or c
        jr nz,.run
        ret

show_music:
        ld hl,house_txt_music_on
        ld a,(music)
        or a
        jr nz,.p
        ld hl,house_txt_music_off
.p:     ld de,$1601
        jp print_at

; row 22: the keys for the input chosen (m3-r5 F-24); HL = the keys' text, else the pointer's
draw_legend:
        ld a,(input_dev)
        cp DEV_MOUSE
        jr nz,.k
        ld h,d
        ld l,e
.k:     ld de,$1600
        jp print_at

desk_legend:
        ld a,(layer)
        or a
        ld hl,s_leg_keys
        ld de,s_leg_ms
        jr z,draw_legend
        ld hl,s_leg_mkeys
        ld de,s_leg_mms
        jr draw_legend

draw_desk:
        ld hl,panels
        ld (pd_table),hl
        ld a,N_PANELS
        ld (pd_count),a
        call new_screen
        ld hl,desk_text
        call print_list
        call desk_legend
        call box_refresh        ; the Grid's scale, the sheet's numbers
        ; the whole Grid, cell by cell, behind black attributes
        call calc_square
        call cursor_rows
        call gc_setup
        ld c,0
.cr:    push bc
        call cell_row
        pop bc
        inc c
        ld a,c
        cp 16
        jr nz,.cr
        xor a
        ld (sq_n),a
        ld (grid_any),a
        ld hl,row_dirty
        ld de,row_dirty+1
        ld bc,31                ; row_dirty and row_pend
        ld (hl),0
        ldir
        ld hl,row_force         ; drawn whole here: nothing to force
        ld b,16
.nf:    ld (hl),0
        inc hl
        djnz .nf
        ld hl,grid_want         ; have = want, both pairs
        ld de,grid_have
        ld bc,512
        ldir
        inc a
        ld (dk_noattr),a        ; colours come after, all at once
        ld c,0
.sq:    ld b,0
        ld hl,grid_have
        add hl,bc
        ld e,(hl)
        inc h
        ld d,(hl)
        push bc
        ld a,c
        call draw_kind
        pop bc
        inc c
        jr nz,.sq
        xor a
        ld (dk_noattr),a
        ld a,AT_DEFAULT
        call set_attrs
        ld de,$0001
        ld bc,$0d01
        ld a,AT_HEAD
        call fill_attr
        ld de,$0100             ; the Grid on a white, numbered sheet
        ld bc,$1212
        ld a,AT_CANVAS
        call fill_attr
        ld de,$0217             ; true-size cards
        ld bc,$0404
        ld a,AT_CANVAS
        call fill_attr
        ld de,$021c
        ld bc,$0404
        ld a,AT_CANVAS
        call fill_attr
        ld de,$0214             ; HEX: the right byte of each row in yellow, so the pair reads as two
        ld bc,$0210
        ld a,AT_HEAD
        call fill_attr
        ld c,0                  ; each Grid cell's colour (outside the box black, the cursor cyan)
.at:    ld b,0
        ld hl,grid_have
        add hl,bc
        ld e,(hl)
        inc h
        ld d,(hl)
        ld a,e
        and d
        cp OUTSIDE
        ld a,AT_OUT
        jr z,.ap
        ld a,(sq_sh)
        or a
        ld a,e
        jr z,.a8
        or d
        and $88
        jr .am
.a8:    and 8
.am:    ld a,AT_CANVAS
        jr z,.ap
        ld a,AT_MARK
.ap:    ld b,a
        ld a,c
        and $f0
        ld l,a
        ld h,0
        add hl,hl               ; cell row * 32
        ld a,c
        and 15
        inc a
        ld e,a
        ld d,0
        add hl,de
        ld de,$5840             ; attributes from row 2
        add hl,de
        ld (hl),b
        inc c
        jr nz,.at
        ld b,N_ROWS
        ld hl,btn_have
.bh:    ld (hl),0
        inc hl
        djnz .bh
        ld a,$ff
        ld (marker_have),a
        ld (code_mark_have),a
        ld hl,text_have
        ld de,text_have+1
        ld bc,TEXT_LEN-1
        ld (hl),' '
        ldir
        ld a,%11111111
        ld (txt_dirty),a
        xor a
        ld (txt_pend),a
        call count_inked
        jp btn_compose

; HL -> list of (row, col, text..., 0), ended by $ff
print_list:
        ld a,(hl)
        cp $ff
        ret z
        ld d,a
        inc hl
        ld e,(hl)
        inc hl
        call print_at
        inc hl
        jr print_list

; A = cell (row * 16 + col), E = kind (top pair), D = bottom pair -> the cell drawn, and its
; colour unless dk_noattr
draw_kind:
        ld c,a
        and 15
        ld (dk_col),a
        ld a,c
        rrca
        rrca
        rrca
        rrca
        and 15
        ld (dk_row),a
        ld a,e
        ld (dk_kind),a
        ld a,d
        ld (dk_kindb),a
        and e
        cp OUTSIDE
        jr nz,.in
        ld hl,gbuf              ; outside the box: black
        ld b,8
.z:     ld (hl),0
        inc hl
        djnz .z
        ld a,AT_OUT
        jp .w
.in:    ld a,(sq_sh)
        or a
        jp nz,.four
        ; base: ink block, onion ring or a paper dot
        ld a,(layer)            ; the mask layer: paper, ink not covered, cover, covered ink
        or a
        jr z,.pk
        ld a,e
        and 3
        add a,a
        ld l,a
        ld h,0
        ld bc,mask_glyphs
        add hl,bc
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        jr .b
.pk:    ld hl,g_paper
        bit 0,e
        jr z,.p
        ld hl,g_ink
        jr .b
.p:     bit 1,e
        jr z,.b
        ld hl,g_onion
.b:     ld de,gbuf
        ld bc,8
        ldir
        ld a,(dk_kind)
        bit 2,a
        jr z,.nf
        ld hl,gbuf              ; check mark: a tick, cut out of ink or drawn on paper (m2-r2 F-3)
        ld de,g_tick
        bit 0,a
        jr z,.fp
        ld b,7
.fh:    ld a,(de)
        cpl
        and (hl)
        ld (hl),a
        inc hl
        inc de
        djnz .fh
        jr .nf
.fp:    ld b,7
.fx:    ld a,(de)
        or (hl)
        ld (hl),a
        inc hl
        inc de
        djnz .fx
.nf:    ld a,(dk_kind)
        bit 3,a
        jr z,.nk
        ld hl,gbuf              ; cursor: a window in ink, a box on paper
        bit 0,a
        jr z,.kp
        inc hl
        inc hl
        ld b,3
.kw:    ld a,(hl)
        and $c7
        ld (hl),a
        inc hl
        djnz .kw
        jr .nk
.kp:    ld de,g_box
        ld b,7
.kb:    ld a,(de)
        or (hl)
        ld (hl),a
        inc hl
        inc de
        djnz .kb
.nk:    ld a,(dk_col)
        cp 7
        jr nz,.at8
        ld hl,gbuf              ; column 7: the heavier line between the two bytes
        ld b,8
.hl7:   set 0,(hl)
        inc hl
        djnz .hl7
.at8:   ld a,(dk_kind)
        and 8
        jr .attr
.four:  ld hl,gbuf              ; squares of 4 dots: two pairs of 4 x 4 glyphs
        ld a,(dk_kind)
        call pair4
        ld a,(dk_kindb)
        call pair4
        ld a,(dk_col)
        and 3
        cp 3
        jr nz,.at4
        ld hl,gbuf              ; every fourth cell: the line between two bytes
        ld b,8
.hl4:   set 0,(hl)
        inc hl
        djnz .hl4
.at4:   ld a,(dk_kind)
        ld hl,dk_kindb
        or (hl)
        and $88
.attr:  ld a,AT_CANVAS
        jr z,.w
        ld a,AT_MARK            ; cyan: the cursor is in this cell
.w:     ld (dk_attr),a
        ld a,(dk_row)
        add a,2
        ld l,a
        and $18
        or $40
        ld h,a
        ld a,l
        and 7
        rrca
        rrca
        rrca
        ld l,a
        ld a,(dk_col)
        inc a
        or l
        ld l,a
        ld de,gbuf
        ld b,8
.r:     ld a,(de)
        ld (hl),a
        inc de
        inc h
        djnz .r
        ld a,(dk_noattr)
        or a
        ret nz
        ld a,(dk_row)
        add a,2
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld a,(dk_col)
        inc a
        or l
        ld l,a
        ld a,h
        or $58
        ld h,a
        ld a,(dk_attr)
        ld (hl),a
        ret

; A = a pair of 4-dot kinds (left low nibble), HL = 4 rows of gbuf -> drawn; HL += 4.
; A cursor square turns over while blink is set.
pair4:  ld c,a
        and 15
        add a,a
        add a,a
        ld e,a
        ld d,0
        push hl
        ld hl,g4l
        ld a,(layer)
        or a
        jr z,.gl
        ld hl,g4ml
.gl:    add hl,de
        ex (sp),hl              ; (SP) = left glyph
        ld a,c
        rrca
        rrca
        rrca
        rrca
        ld c,a
        and 15
        add a,a
        add a,a
        ld e,a
        ld a,(blink)
        or a
        ld a,c
        jr nz,.bl
        xor a                   ; not blinking: no square turns over
.bl:    ld b,0
        bit 7,a                 ; (rotated: the left square's cursor bit)
        jr z,.l
        ld b,$f0
.l:     bit 3,a                 ; the right square's cursor bit
        jr z,.r
        ld a,b
        or $0f
        ld b,a
.r:     push hl
        ld hl,g4r
        ld a,(layer)
        or a
        jr z,.gr
        ld hl,g4mr
.gr:    add hl,de
        ex de,hl                ; DE = right glyph
        pop hl
        ex (sp),hl              ; HL = left glyph, (SP) = gbuf
        ld c,4
.row:   ld a,(de)
        or (hl)
        xor b
        ex (sp),hl
        ld (hl),a
        inc hl
        ex (sp),hl
        inc hl
        inc de
        dec c
        jr nz,.row
        pop hl
        ret

g_paper: db 0,0,0,0,0,0,0,$80
g_ink:   db $fe,$fe,$fe,$fe,$fe,$fe,$fe,0
g_onion: db 0,0,$10,$28,$10,0,0,$80     ; the onion skin: a small ring, lighter than ink
g_tick:  db 0,$04,$08,$50,$20,0,0       ; a check mark: a tick (cut out of ink, drawn on paper)
g_box:   db $fe,$82,$82,$82,$82,$82,$fe
g_hollow: db $fe,$82,$82,$82,$82,$82,$fe,0  ; mask layer: ink the mask does not cover
g_cover: db $88,$22,$88,$22,$88,$22,$88,$80 ; mask layer: cover, a light hatch
mask_glyphs: dw g_paper,g_hollow,g_cover,g_ink
; 4-dot squares by kind (bit 0 ink, 1 tracing, 2 check, 3 cursor: a box on paper, a solid square on ink,
; four corners on ink (a ring when turned over), m3-r2 F-15; turned over while blink is set): left square (top nibble), right square
g4l: db $00,$00,$00,$80,$e0,$e0,$e0,$00,$40,$a0,$40,$80,$e0,$e0,$e0,$00,$a0,$40,$a0,$80,$e0,$00,$e0,$00,$a0,$40,$a0,$80,$e0,$00,$e0,$00,$f0,$90,$90,$f0,$90,$60,$60,$90,$f0,$90,$90,$f0,$90,$60,$60,$90,$f0,$90,$90,$f0,$90,$60,$60,$90,$f0,$90,$90,$f0,$90,$60,$60,$90
g4ml: db $00,$00,$00,$80,$a0,$50,$a0,$50,$a0,$00,$a0,$80,$e0,$e0,$e0,$00,$a0,$40,$a0,$80,$e0,$00,$e0,$00,$a0,$40,$a0,$80,$e0,$00,$e0,$00,$f0,$90,$90,$f0,$90,$60,$60,$90,$f0,$90,$90,$f0,$90,$60,$60,$90,$f0,$90,$90,$f0,$90,$60,$60,$90,$f0,$90,$90,$f0,$90,$60,$60,$90
g4mr: db $00,$00,$00,$08,$0a,$05,$0a,$05,$0a,$00,$0a,$08,$0e,$0e,$0e,$00,$0a,$04,$0a,$08,$0e,$00,$0e,$00,$0a,$04,$0a,$08,$0e,$00,$0e,$00,$0f,$09,$09,$0f,$09,$06,$06,$09,$0f,$09,$09,$0f,$09,$06,$06,$09,$0f,$09,$09,$0f,$09,$06,$06,$09,$0f,$09,$09,$0f,$09,$06,$06,$09
g4r: db $00,$00,$00,$08,$0e,$0e,$0e,$00,$04,$0a,$04,$08,$0e,$0e,$0e,$00,$0a,$04,$0a,$08,$0e,$00,$0e,$00,$0a,$04,$0a,$08,$0e,$00,$0e,$00,$0f,$09,$09,$0f,$09,$06,$06,$09,$0f,$09,$09,$0f,$09,$06,$06,$09,$0f,$09,$09,$0f,$09,$06,$06,$09,$0f,$09,$09,$0f,$09,$06,$06,$09

; ---------------------------------------------------------------- draw phase
draw_phase:
        xor a
        ld (redraw),a
        ld a,(cur_drawn)
        or a
        jr z,.gone
        ld a,(drawn_x)
        ld c,a
        ld a,(drawn_y)
        call xor_cursor
        xor a
        ld (cur_drawn),a
.gone:  ld a,(state)
        or a
        jr nz,.desk
        ld a,(music_dirty)
        or a
        ret z
        xor a
        ld (music_dirty),a
        jp show_music
.desk:  ld a,(lib_open)
        or a
        jr z,.gn
        call lib_draw
        jr .arrow
.gn:    ld a,(gn_open)
        or a
        jr z,.dk
        call ground_draw
        jr .arrow
.dk:    xor a
        ld (img_heavy),a
        call img_pass           ; a whole picture with the mouse: the Grid's cells and the text
        ld a,(img_heavy)        ; wait (kept queued) so the Arrow is back before the beam (M3 gate)
        or a
        jr nz,.light
        call sq_pass
.clean: call btn_pass
        call marker_pass
        call code_mark_pass
        call print_pending
        jr .arrow
.light: call btn_pass
        call marker_pass
        call code_mark_pass
.arrow: ld a,(input_dev)
        cp DEV_MOUSE
        ret nz
        ld a,(cur_x)
        ld (drawn_x),a
        ld c,a
        ld a,(cur_y)
        ld (drawn_y),a
        call xor_cursor
        ld a,1
        ld (cur_drawn),a
        ret

; the squares queued by grid_queue
sq_pass:
        ld a,(sq_n)
        or a
        ret z
        ld b,a
        ld hl,sq_queue
.l:     push bc
        ld a,(hl)
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        push hl
        call draw_kind
        pop hl
        pop bc
        djnz .l
        xor a
        ld (sq_n),a
        ret

; Images: 0 EDIT card, 1 PLAY card (true size, 4 x 4 cells), 2-9 strip slots (2 x 2 cells; a
; box bigger than 16 x 16 is shown at half size). img_need: the images to draw (IMG_CAP an
; update); img_full: those whose whole area is written (the box changed), else only the
; figure's own rows. Each screen byte is written once with its final value.
img_all_full:
        ld hl,$03ff
        ld (img_full),hl
img_all:
        ld hl,$03ff
        ld (img_need),hl
img_rows_all:
        ld hl,$ff00             ; every row (lo 0, hi 255)
        ld (img_rlo),hl
        ld a,1
        ld (cnt_dirty),a
        ret

img_cards:
        ld a,(img_need)
        or 3
        ld (img_need),a
        jr img_rows_all

; the current frame was painted: its card, its slot, and PLAY if it shows the same frame
img_painted:
        ld hl,img_rlo           ; the painted rows: the range grows until every image is drawn
        cp (hl)
        jr nc,.lo
        ld (hl),a
.lo:    ld hl,img_rhi
        cp (hl)
        jr c,.hi
        ld (hl),a
.hi:    ld a,(cur_frame)
        add a,2
        call img_bit
        ld a,(cur_frame)
        ld hl,play_frame
        cp (hl)
        ld a,1
        jr nz,.e
        ld a,3
.e:     ld hl,img_need
        or (hl)
        ld (hl),a
        ret

; A = image -> its bit set in img_need
img_bit:
        ld hl,1
        or a
        jr z,.s
        ld b,a
.l:     add hl,hl
        djnz .l
.s:     ld de,(img_need)
        ld a,e
        or l
        ld e,a
        ld a,d
        or h
        ld d,a
        ld (img_need),de
        ret

img_pass:
        ld hl,(img_need)
        ld a,h
        or l
        jr nz,.go
        ld hl,$00ff             ; all drawn: no rows pending (lo 255, hi 0)
        ld (img_rlo),hl
        ret
.go:    ld a,(img_cap)
        ld (img_budget),a
        xor a
        ld (img_i),a
.l:     ld a,(img_i)
        ld hl,img_need
        call bit_ptr
        and (hl)
        jr z,.next
        ld a,(img_i)            ; a whole area counts as two
        ld hl,img_full
        call bit_ptr
        and (hl)
        ld a,(img_budget)
        jr z,.one
        sub 2
        jr .bud
.one:   sub 1
.bud:   jr nc,.fits
        ld a,(img_budget)       ; over the budget: only as the first picture this update (with
        ld hl,img_cap           ; the mouse's cap of 1 a whole area would otherwise never fit)
        cp (hl)
        ret nz                  ; the rest next update
        xor a
.fits:  ld (img_budget),a
        call img_draw
.next:  ld hl,img_i
        inc (hl)
        ld a,(hl)
        cp N_IMG
        jr nz,.l
        ret

; image img_i -> drawn
img_draw:
        ld a,(img_i)
        call img_clear_bit
        ld a,(img_i)
        cp 2
        jr nc,.slot
        ld b,a                  ; cards: rows 2-5, columns 23-26 and 28-31, true size
        or a
        ld a,(cur_frame)
        ld c,23
        jr z,.c0
        ld a,(play_frame)
        ld c,28
.c0:    call frame_ptr
        ld (im_src),hl
        ld a,c
        ld (im_col),a
        ld a,16
        ld (im_y),a
        ld a,4
        ld (im_wc),a
        ld a,32
        ld (im_h),a
        xor a
        ld (im_half),a
        jr .go
.slot:  sub 2                   ; the strip: rows 19-20, columns 3 * slot
        ld c,a
        add a,a
        add a,c
        ld (im_col),a
        ld a,152
        ld (im_y),a
        ld a,2
        ld (im_wc),a
        ld a,16
        ld (im_h),a
        ld a,(sq_sh)
        ld (im_half),a
        ld a,c
        ld hl,nframes
        cp (hl)
        ld hl,0
        jr nc,.none
        call frame_ptr
.none:  ld (im_src),hl
        ld a,h                  ; the slot's colour: white with a frame, black without
        or l
        ld a,AT_CANVAS
        jr nz,.sa
        xor a
.sa:    push af
        ld a,(im_y)
        rrca
        rrca
        rrca
        and 31
        ld d,a
        ld a,(im_col)
        ld e,a
        ld bc,$0202
        pop af
        call fill_attr
.go:    ; the figure's size and place in the area
        ld a,(bpr)
        ld b,a
        ld a,(box_h)
        ld c,a
        ld a,(im_half)
        or a
        jr z,.fs
        inc b
        srl b                   ; half: bytes (bpr + 1) / 2, rows box_h / 2
        srl c
.fs:    ld a,b
        ld (im_fw),a
        ld a,c
        ld (im_fh),a
        ld a,(im_wc)
        sub b
        srl a
        ld (im_ox),a
        ld a,(im_h)
        sub c
        srl a
        ld (im_oy),a
        ; whole area, or only the figure's rows
        ld a,(img_i)
        call img_full_bit       ; NZ: whole area (and the bit cleared)
        ld hl,(im_src)
        jr z,.part
        ld a,(input_dev)        ; (a whole area with the mouse: the rest of the draw phase waits)
        cp DEV_MOUSE
        jr nz,.whole
        ld (img_heavy),a
        jr .whole
.part:
        ld a,h
        or l
        jr z,.whole             ; an empty slot is written blank
        ld a,(img_rlo)          ; only the painted rows of the figure
        ld b,a
        ld a,(img_rhi)
        ld c,a
        ld a,(im_half)
        or a
        jr z,.t
        srl b
        srl c
.t:     ld a,(im_fh)
        dec a
        cp c
        jr nc,.c
        ld c,a                  ; hi at most the last row
.c:     ld a,c
        sub b
        ret c                   ; none
        inc a
        ld (im_n),a
        ld a,(im_oy)
        add a,b
        ld (im_r),a
        ld a,(im_half)
        or a
        jr nz,.half0
        jp img_fast             ; true size: straight from the frame
.half0: xor a
        jr .rows
.whole: ld a,(im_half)          ; true size with a frame: the fast whole-area path
        or a
        jr nz,.wg
        ld hl,(im_src)
        ld a,h
        or l
        jp nz,img_whole
.wg:    xor a
        ld (im_r),a
        ld a,(im_h)
        ld (im_n),a
        ld a,1
.rows:  ld (im_all),a
.row:   ld hl,im_buf            ; this row's bytes, blank first
        ld (hl),0
        ld de,im_buf+1
        ld bc,3
        ldir
        ld hl,(im_src)
        ld a,h
        or l
        jr z,.put
        ld a,(im_r)
        ld hl,im_oy
        sub (hl)
        jr c,.put
        ld hl,im_fh
        cp (hl)
        jr nc,.put
        call img_fetch          ; A = figure row -> its bytes at im_buf + im_ox
.put:   ld a,(im_y)
        ld hl,im_r
        add a,(hl)
        call row_addr
        ld a,(im_col)
        add a,l
        ld l,a
        ld de,im_buf
        ld a,(im_all)
        or a
        ld a,(im_wc)
        jr nz,.wr
        ld a,(im_ox)            ; only the figure's bytes
        add a,e
        ld e,a
        ld a,(im_ox)
        add a,l
        ld l,a
        ld a,(im_fw)
.wr:    ld b,a
.wb:    ld a,(de)
        ld (hl),a
        inc de
        inc l
        djnz .wb
        ld hl,im_r
        inc (hl)
        ld hl,im_n
        dec (hl)
        jr nz,.row
        ret

; True size, the whole area: each row's blank margins and the figure's bytes written straight
img_whole:
        xor a
        ld (im_r),a
.row:   ld a,(im_y)
        ld hl,im_r
        add a,(hl)
        call row_addr
        ld a,(im_col)
        add a,l
        ld l,a                  ; HL = the row's first byte
        ld a,(im_r)
        ld de,im_oy
        ex de,hl
        sub (hl)
        ex de,hl
        jr c,.blank
        ld de,im_fh
        ex de,hl
        cp (hl)
        ex de,hl
        jr nc,.blank
        push hl                 ; the figure's row A: src = im_src + A * bpr
        ld e,a
        ld d,0
        ld hl,(im_src)
        ld a,(bpr)
        ld b,a
.m:     add hl,de
        djnz .m
        ex de,hl                ; DE = source
        pop hl
        ld a,(im_ox)            ; left margin
        or a
        jr z,.f
        ld b,a
.l:     ld (hl),0
        inc l
        djnz .l
.f:     ld a,(bpr)
        ld b,a
.c:     ld a,(de)
        ld (hl),a
        inc de
        inc l
        djnz .c
        ld a,(im_wc)            ; right margin: wc - ox - bpr
        ld b,a
        ld a,(im_ox)
        ld c,a
        ld a,b
        sub c
        ld c,a
        ld a,(bpr)
        ld b,a
        ld a,c
        sub b
        jr z,.next
        ld b,a
.r:     ld (hl),0
        inc l
        djnz .r
        jr .next
.blank: ld a,(im_wc)
        ld b,a
.z:     ld (hl),0
        inc l
        djnz .z
.next:  ld hl,im_r
        inc (hl)
        ld a,(im_h)
        cp (hl)
        jr nz,.row
        ret

; True size, the figure's rows im_r - im_oy on, im_n of them: each row's bytes straight from
; the frame to the screen
img_fast:
        ld a,(im_r)
        ld hl,im_oy
        sub (hl)
        ld e,a
        ld d,0
        ld hl,(im_src)
        ld a,(bpr)
        ld b,a
.m:     add hl,de
        djnz .m
.row:   push hl
        ld a,(im_y)
        ld hl,im_r
        add a,(hl)
        call row_addr           ; HL = the screen row
        ld a,(im_ox)
        ld c,a
        ld a,(im_col)
        add a,c
        add a,l
        ld e,a
        ld d,h                  ; DE = the figure's first byte on it
        pop hl
        ld a,(bpr)
        ld c,a
        ld b,0
        ldir
        ld a,(im_r)
        inc a
        ld (im_r),a
        ld a,(im_n)
        dec a
        ld (im_n),a
        jr nz,.row
        ret

; A = row of the figure (or of its half) -> its bytes into im_buf + im_ox
img_fetch:
        ld e,a
        ld a,(im_half)
        or a
        jr nz,.half
        ld d,0                  ; true size: row * bpr
        ld hl,(im_src)
        ld a,(bpr)
        ld b,a
.m:     add hl,de
        djnz .m
        ld a,(im_ox)
        ld e,a
        ld d,0
        ex de,hl
        ld bc,im_buf
        add hl,bc
        ex de,hl
        ld a,(bpr)
        ld c,a
        ld b,0
        ldir
        ret
.half:  sla e                   ; rows 2r and 2r + 1, ORed; each pair of dots one dot
        ld d,0
        ld hl,(im_src)
        ld a,(bpr)
        ld b,a
.m2:    add hl,de
        djnz .m2
        ld a,(bpr)
        ld e,a
        ld (im_k),a
        push hl
        add hl,de
        ex de,hl                ; DE = the second row
        pop hl
        ld a,(im_ox)
        ld c,a
        ld b,0
        ld ix,im_buf
        add ix,bc
.hb:    ld a,(de)               ; left byte of the pair
        or (hl)
        inc hl
        inc de
        push hl
        ld h,high half_tab
        ld l,a
        ld c,(hl)               ; its 4 dots, top nibble
        pop hl
        ld a,(im_k)
        dec a
        ld (im_k),a
        jr z,.odd
        ld a,(de)               ; right byte of the pair
        or (hl)
        inc hl
        inc de
        push hl
        ld h,high half_tab
        ld l,a
        ld a,(hl)
        pop hl
        rrca
        rrca
        rrca
        rrca
        or c
        ld c,a
        ld a,(im_k)
        dec a
        ld (im_k),a
        ld (ix+0),c
        inc ix
        jr nz,.hb
        ret
.odd:   ld (ix+0),c
        ret

; A = image: clear its bit in img_need
img_clear_bit:
        ld hl,img_need
        call bit_ptr
        cpl
        and (hl)
        ld (hl),a
        ret

; A = image -> NZ if it was set in img_full (now cleared)
img_full_bit:
        ld hl,img_full
        call bit_ptr
        ld c,a
        and (hl)
        ret z
        ld a,c
        cpl
        and (hl)
        ld (hl),a
        or 1
        ret

; A = bit 0-15, HL = a word -> HL = its byte, A = the bit's mask
bit_ptr:
        cp 8
        jr c,.lo
        inc hl
        sub 8
.lo:    ld b,a
        ld a,1
        inc b
.l:     dec b
        ret z
        add a,a
        jr .l

; the half-size table: each pair of dots in a byte -> one dot, in the top nibble
build_half:
        ld hl,half_tab
.v:     ld c,0
        ld a,l
        ld b,4
.p:     ld e,a
        and $c0
        add a,$ff               ; carry if either dot of the pair is set
        rl c
        ld a,e
        add a,a
        add a,a
        djnz .p
        ld a,c
        rlca
        rlca
        rlca
        rlca
        ld (hl),a
        inc l
        jr nz,.v
        ret

; the drawer rows' colours
btn_pass:
        ld b,0
.l:     ld hl,btn_want
        ld e,b
        ld d,0
        add hl,de
        ld a,(hl)
        ld hl,btn_have
        add hl,de
        cp (hl)
        jr z,.n
        ld (hl),a
        push bc
        ld c,a
        ld a,b
        add a,DRAWER_ROW
        ld d,a
        ld e,RC
        ld a,c
        ld bc,$0901
        call fill_attr
        pop bc
.n:     inc b
        ld a,b
        cp N_ROWS
        jr nz,.l
        ret

; "^^" under the current frame in the strip
marker_pass:
        ld a,(cur_frame)
        ld hl,marker_have
        cp (hl)
        ret z
        ld c,(hl)
        ld (hl),a
        ld b,a
        ld a,c
        cp $ff
        jr z,.new
        ld hl,txt_nomark
        call .put
.new:   ld a,b
        ld hl,txt_mark
.put:   ld c,a
        add a,a
        add a,c
        ld e,a
        ld d,21
        jp print_at

; the HEX column: the cursor's row lit
code_mark_pass:
        ld a,(sq_ok)
        or a
        ld a,$ff
        jr z,.w
        ld a,(sq_row)
        and 15                  ; its row in the HEX band
.w:     ld hl,code_mark_have
        cp (hl)
        ret z
        ld c,(hl)
        ld (hl),a
        ld b,a
        ld a,c
        cp $ff
        jr z,.new
        add a,2
        ld d,a
        ld e,18
        push bc
        ld bc,$0201
        ld a,AT_DEFAULT
        call fill_attr
        ld e,20
        ld bc,$0201
        ld a,AT_HEAD
        call fill_attr
        pop bc
.new:   ld a,b
        cp $ff
        ret z
        add a,2
        ld d,a
        ld e,18
        push bc
        ld bc,$0401
        ld a,AT_MARK
        call fill_attr
        pop bc
        ret

; XOR the arrow with its hotspot at x = C, y = A
xor_cursor:
        ld e,a
        ld a,c
        rrca
        rrca
        rrca
        and 31
        ld (xc_col),a
        ld a,c
        and 7
        ld (xc_sh),a
        ld hl,cursor_gfx
        ld b,CUR_H
.row:   ld a,e
        cp 192
        ret nc
        push bc
        push hl
        ld d,(hl)
        ld c,0
        ld a,(xc_sh)
        or a
        jr z,.ns
        ld b,a
.sh:    srl d
        rr c
        djnz .sh
.ns:    ld a,e
        call row_addr
        ld a,(xc_col)
        add a,l
        ld l,a
        ld a,(hl)
        xor d
        ld (hl),a
        ld a,(xc_col)
        cp 31
        jr z,.nos
        inc l
        ld a,(hl)
        xor c
        ld (hl),a
.nos:   pop hl
        pop bc
        inc hl
        inc e
        djnz .row
        ret

cursor_gfx:
        db %10000000,%11000000,%11100000,%11110000,%11111000
        db %11111100,%11111110,%11111000,%11011000,%10001100

; ---------------------------------------------------------------- text panels
; Each panel: want, have, column, row, width, height. Diffed together, DRAW_CAP an update.
RD_W    equ RW*5
DR_W    equ RW*N_ROWS
CD_W    equ 4*16
ST_W    equ 32
HD_W    equ 31                      ; row 0, cols 1-31
TEXT_LEN equ RD_W+DR_W+CD_W+ST_W+RW+HD_W+37
rd_want equ text_want
dr_want equ text_want+RD_W
cd_want equ dr_want+DR_W
st_want equ cd_want+CD_W
r6_want equ st_want+ST_W
hd_want equ r6_want+RW
la_want equ hd_want+HD_W
ld_want equ la_want+21

panels: dw text_want, text_have
        db RC,7,RW,5
        dw dr_want, text_have+RD_W
        db RC,DRAWER_ROW,RW,N_ROWS
        dw cd_want, text_have+RD_W+DR_W
        db 18,2,4,16
        dw st_want, text_have+RD_W+DR_W+CD_W
        db 0,23,32,1
        dw r6_want, text_have+RD_W+DR_W+CD_W+ST_W
        db RC,6,RW,1
        dw hd_want, text_have+RD_W+DR_W+CD_W+ST_W+RW
        db 1,0,HD_W,1
        dw la_want, text_have+RD_W+DR_W+CD_W+ST_W+RW+HD_W
        db 1,1,21,1
        dw ld_want, text_have+RD_W+DR_W+CD_W+ST_W+RW+HD_W+21
        db 0,2,1,16
N_PANELS equ 8

; readouts (cols 23-31): row 6 the input; rows 7-11 the square under the cursor, INK or
; PAPER there, the frame, the flip-book and the checks
compose_readouts:
        ld hl,rd_want
        ld de,rd_want+1
        ld bc,RD_W-1
        ld (hl),' '
        ldir
        ld hl,r6_want
        ld de,r6_want+1
        ld bc,RW-1
        ld (hl),' '
        ldir
        ld a,(input_dev)
        ld hl,s_mouse
        cp DEV_MOUSE
        jr z,.i
        ld hl,s_keys
.i:     ld de,r6_want
        call put_str
        ld hl,s_at
        ld de,rd_want
        call put_str
        ld a,(sq_ok)
        or a
        jr nz,.sq
        ld hl,s_nosq
        call put_str
        jr .fr
.sq:    ld a,(sq_col)
        call put_coord
        ld a,','
        ld (de),a
        inc de
        ld a,(sq_row)
        call put_coord
        ld a,(sq_col)
        ld c,a
        ld a,(sq_row)
        ld b,a
        call get_sq
        push af
        ld a,(layer)
        or a
        jr nz,.km
        pop af
        ld hl,s_ink
        jr nz,.ik
        ld hl,s_paper
        jr .ik
.km:    pop af
        ld hl,s_cover
        jr nz,.ik
        ld hl,s_keep
.ik:    ld de,rd_want+RW
        call put_str
.fr:    ld hl,s_frame
        ld de,rd_want+2*RW
        call put_str
        ld a,(cur_frame)
        add a,'1'
        ld (de),a
        inc de
        ld a,'/'
        ld (de),a
        inc de
        ld a,(nframes)
        add a,'0'
        ld (de),a
        ld hl,s_stop
        ld a,(play_on)
        or a
        jr z,.on
        ld hl,s_playing
.on:    ld de,rd_want+3*RW
        call put_str
        ld a,(play_lvl)
        add a,a
        add a,a
        ld l,a
        ld h,0
        ld bc,play_names
        add hl,bc
        ld bc,4
        ldir
        ld hl,s_checks
        ld de,rd_want+4*RW
        call put_str
        ld a,(chk_total)
        or a
        jr nz,.cn
        ld hl,s_ok
        jp put_str
.cn:    add a,'0'
        ld (de),a
        ret

; A = a square's column or row: one hex digit for squares of 8 dots, two for squares of 4
put_coord:
        ld c,a
        ld a,(sq_sh)
        or a
        ld a,c
        jp z,put_hex1
        rrca
        rrca
        rrca
        rrca
        and 15
        call put_hex1
        ld a,c
        and 15
        jp put_hex1

; the header (row 0, cols 18-31): the figure's name and its box
compose_header:
        ld hl,hd_want
        ld de,hd_want+1
        ld bc,HD_W-1
        ld (hl),' '
        ldir
        ld hl,s_studio          ; the figure's game (AC-33), or the studio's name
        ld a,(fig_game)
        cp $ff
        call nz,lib_game_name
        ld de,hd_want
        call put_str
        ld hl,fig_name
        ld de,hd_want+17
        call put_str
        inc de
        ld a,(box_w)
        call put_num
        ld a,'X'
        ld (de),a
        inc de
        ld a,(box_h)
        jp put_num

; A -> its digits, no leading zeros, at DE+
put_num:
        cp 100
        jp nc,put_dec3
        cp 10
        jp nc,put_dec2
        ld c,1
        jp put_dig

; drawer (cols 23-31, rows 12-21): its name, then a label per control
compose_drawer:
        ld hl,dr_want
        ld de,dr_want+1
        ld bc,DR_W-1
        ld (hl),' '
        ldir
        ld hl,drawer_names
        call drawer_pick
        ld de,dr_want
        call put_str
        call drawer_list
        ld de,dr_want+RW
        ld b,N_ROWS-1
.l:     push bc
        push hl
        push de
        ld a,(hl)
        call act_label
        pop de
        push de
        call put_str
        pop de
        ld hl,RW
        add hl,de
        ex de,hl
        pop hl
        inc hl
        pop bc
        djnz .l
        ret

; A = action -> HL = its label (play/stop and undo/redo follow their state)
act_label:
        cp A_LAYER
        jr nz,.st
        ld a,(layer)
        or a
        ld hl,l_layer_p
        ret z
        ld hl,l_layer_m
        ret
.st:    cp A_STYLE
        jr nz,.pl
        ld a,(mstyle)
        add a,a
        ld e,a
        ld d,0
        ld hl,style_labels
        add hl,de
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ret
.pl:    cp A_PLAY
        jr nz,.u
        ld a,(play_on)
        or a
        ld hl,l_play
        ret z
        ld hl,l_stop
        ret
.u:     cp A_UNDO
        jr nz,.t
        ld a,(undo_redo)
        or a
        ld hl,l_undo
        ret z
        ld hl,l_redo
        ret
.t:     add a,a
        ld e,a
        ld d,0
        ld hl,act_labels
        add hl,de
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ret

; HEX column (cols 18-21, rows 2-17): the cursor's band of 16 rows and 2 bytes
compose_codes:
        ld hl,cd_want
        ld de,cd_want+1
        ld bc,CD_W-1
        ld (hl),' '
        ldir
        ld a,(cd_band)
        cp $ff
        jr nz,.b
        xor a
.b:     ld c,a
        and 2
        add a,a
        add a,a
        add a,a                 ; first row: 0 or 16
        ld (cd_r),a
        ld a,c
        and 1
        add a,a
        ld (cd_b),a             ; first byte: 0 or 2
        call edit_frame         ; (the mask's codes on the mask layer)
        call frame_ptr
        ld a,(cd_r)
        ld e,a
        ld d,0
        ld a,(bpr)
        ld b,a
.m:     add hl,de
        djnz .m
        ld a,(cd_b)
        ld e,a
        add hl,de               ; HL = the first row's first byte shown
        ld de,cd_want
        ld a,16
        ld (cd_n),a
.row:   ld a,(cd_r)
        ld b,a
        ld a,(box_h)
        cp b
        ret z                   ; past the box: blank
        ret c
        push de
        push hl
        ld a,(cd_b)
        ld c,a
        ld a,(bpr)
        sub c                   ; bytes left in the row from the first shown
        ld b,2
        cp 2
        jr nc,.two
        ld b,a
.two:   ld a,(hl)
        inc hl
        push af
        rrca
        rrca
        rrca
        rrca
        and 15
        call put_hex1
        pop af
        and 15
        call put_hex1
        djnz .two
        pop hl
        pop de
        inc de                  ; DE to the next row of the panel
        inc de
        inc de
        inc de
        ld a,(bpr)
        ld c,a
        ld b,0
        add hl,bc
        ld a,(cd_r)
        inc a
        ld (cd_r),a
        ld a,(cd_n)
        dec a
        ld (cd_n),a
        jr nz,.row
        ret

; the sheet's numbers: across (row 1) and down (col 0), for the squares in the box; squares
; of 4 dots: across at each byte's first square (two digits from 16), down every other row
compose_labels:
        ld hl,la_want
        ld de,la_want+1
        ld bc,36                ; across (with the HEX column's header) and down
        ld (hl),' '
        ldir
        ld de,la_want+17        ; the HEX header: HEX, or for big boxes H, the band's first row and
        ld a,(sq_sh)            ; < (bytes 0-1) or > (bytes 2-3), m3-r2 F-5
        or a
        jr nz,.hb
        ld hl,s_hex
        call put_str
        jr .hd
.hb:    ld a,'H'
        ld (de),a
        inc de
        ld a,(cd_band)
        cp $ff
        jr nz,.b
        xor a
.b:     ld c,a
        and 2
        rlca
        rlca
        rlca                    ; 0 or 16
        push bc
        call put_hex2
        pop bc
        ld a,c
        and 1
        ld a,'<'
        jr z,.lt
        ld a,'>'
.lt:    ld (de),a
.hd:
        ld b,0                  ; across
.a:     ld a,(sq_sh)
        or a
        ld a,b
        jr z,.a8
        and 3
        jr nz,.an
        ld a,b
        add a,a                 ; every fourth cell: the first square of a byte
.a8:    ld hl,box_w
        cp (hl)
        jr nc,.an
        call lbl_put
.an:    inc b
        ld a,b
        cp 16
        jr nz,.a
        ld b,0                  ; down
.d:     ld a,(sq_sh)
        or a
        ld a,b
        jr z,.d8
        bit 0,a
        jr nz,.dn
        add a,a
.d8:    ld hl,box_h
        cp (hl)
        jr nc,.dn
        and 15                  ; one digit: rows 16-31 read 0-F again, the HEX band says which
        call hex_ch
        ld e,b
        ld d,0
        ld hl,ld_want
        add hl,de
        ld (hl),a
.dn:    inc b
        ld a,b
        cp 16
        jr nz,.d
        ret

; A = number (0-31), B = cell -> its digits in la_want at B (and B + 1 for two)
lbl_put:
        ld e,b
        ld d,0
        ld hl,la_want
        add hl,de
        cp 16
        jr c,.one
        ld (hl),'1'
        inc hl
        sub 16
.one:   call hex_ch
        ld (hl),a
        ret

; A = 0-15 -> its hex character
hex_ch: cp 10
        jr c,.d
        add a,'A'-10
        ret
.d:     add a,'0'
        ret

; status line (row 23): inked squares and the last event, or a tip
compose_status:
        ld hl,st_want
        ld de,st_want+1
        ld bc,ST_W-1
        ld (hl),' '
        ldir
        ld hl,s_inked
        ld de,st_want
        call put_str
        ld hl,(inked)
        call put_dec16
        ld de,st_want+10
        ld a,(last_event)
        cp EV_LESSON            ; a lesson's caption has the whole row (DEMO-01)
        jr nz,.le
        ld de,st_want
        ld hl,les_cap
        jp put_str
.le:    cp EV_OPENED
        jr nz,.st
        ld hl,s_opened
        call put_str
        ld hl,fig_name
        jp put_str
.st:    cp EV_OUTSIDE
        jr nz,.st2
        ld hl,s_outside
        call put_str
        ld a,(ev_p1)
        add a,'0'
        ld (de),a
        ret
.st2:   cp EV_STRAY
        jr nz,.al
        ld hl,s_stray
        call put_str
        ld a,(ev_p1)
        add a,'0'
        ld (de),a
        ret
.al:    cp EV_ALIKE
        jr nz,.ev
        ld hl,s_alike
        call put_str
        ld a,(ev_p1)
        add a,'0'
        ld (de),a
        inc de
        ld a,','
        ld (de),a
        inc de
        ld a,(ev_p2)
        add a,'0'
        ld (de),a
        inc de
        ld hl,s_more1
        call put_str
        ld hl,s_change
        call put_str
        ld a,(ev_p3)
        call put_num
        ld hl,s_more2
        jp put_str
.ev:    add a,a
        ld l,a
        ld h,0
        ld bc,ev_names
        add hl,bc
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        jp put_str

; Compare every panel's want with its have; queue up to DRAW_CAP changed characters.
panel_diff:
        ld a,(pend_n)           ; characters queued but not printed yet: keep them (D-040)
        or a
        ret nz
        ld (pend_n),a
        ld ix,pend_list
        ld iy,(pd_table)
        ld a,1
        ld (pd_bit),a
        ld a,(pd_count)
.panel: ld (pd_left),a
        ld a,(txt_pend)
        ld hl,pd_bit
        and (hl)
        jr z,.skip
        ld l,(iy+0)
        ld h,(iy+1)
        ld e,(iy+2)
        ld d,(iy+3)
        ld c,(iy+5)             ; row
        ld a,(iy+7)
        ld (pd_h),a
.row:   ld b,(iy+6)             ; width, counting down
.col:   ld a,(de)
        cp (hl)
        jr nz,.diff
.same:  inc hl
        inc de
        djnz .col
        inc c
        ld a,(pd_h)
        dec a
        ld (pd_h),a
        jr nz,.row
        ld a,(pd_bit)           ; this panel is done
        cpl
        ld hl,txt_pend
        and (hl)
        ld (hl),a
.skip:  ld bc,8
        add iy,bc
        ld a,(pd_bit)
        add a,a
        ld (pd_bit),a
        ld a,(pd_left)
        dec a
        jr nz,.panel
        ret
.diff:  push hl
        ld hl,draw_cap
        ld a,(pend_n)
        cp (hl)
        pop hl
        ret nc
        inc a
        ld (pend_n),a
        ld a,(hl)
        ld (de),a
        ld (ix+2),a
        ld (ix+0),c
        ld a,(iy+4)             ; column = first + width - B
        add a,(iy+6)
        sub b
        ld (ix+1),a
        inc ix
        inc ix
        inc ix
        jr .same

print_pending:
        ld a,(pend_n)
        or a
        ret z
        ld b,a
        ld hl,pend_list
.p:     ld d,(hl)
        inc hl
        ld e,(hl)
        inc hl
        ld a,(hl)
        inc hl
        call print_char
        djnz .p
        xor a
        ld (pend_n),a
        ret

put_str:
        ld a,(hl)
        or a
        ret z
        ld (de),a
        inc hl
        inc de
        jr put_str

; A -> two hex digits at (DE)+
put_hex2:
        push af
        rrca
        rrca
        rrca
        rrca
        and 15
        call put_hex1
        pop af
        and 15
; A (0-15) -> one hex digit at (DE)+
put_hex1:
        add a,'0'
        cp '9'+1
        jr c,.d
        add a,'A'-'9'-1
.d:     ld (de),a
        inc de
        ret

; HL (up to 9999) -> three digits, four from 1000, at DE+
put_dec16:
        ld bc,1000
        or a
        sbc hl,bc
        add hl,bc
        jr c,.three
        ld a,'0'-1
.th:    inc a
        sbc hl,bc
        jr nc,.th
        add hl,bc
        ld (de),a
        inc de
.three: ld bc,100               ; under 1000
        ld a,'0'-1
.h:     inc a
        or a
        sbc hl,bc
        jr nc,.h
        add hl,bc
        ld (de),a
        inc de
        ld a,l
        jp put_dec2

put_dec3:
        ld c,100
        call put_dig
put_dec2:
        ld c,10
        call put_dig
        ld c,1
put_dig:
        ld b,'0'-1
.l:     inc b
        sub c
        jr nc,.l
        add a,c
        push af
        ld a,b
        ld (de),a
        inc de
        pop af
        ret

; ---------------------------------------------------------------- interrupt
isr:    push af
        push bc
        push de
        push hl
        ld hl,frames
        inc (hl)
        ld de,0                 ; D = k1, E = k2
        ld hl,0                 ; H = k3, L = k4
        ld bc,$fbfe             ; Q W E R T
        in a,(c)
        bit 0,a
        jr nz,.k1
        set K_UP,d
.k1:    bit 1,a
        jr nz,.k1a
        set 7,l                 ; W: drawer
.k1a:   bit 2,a
        jr nz,.k1b
        set K_EVERY,e           ; E: all frames
.k1b:   bit 3,a
        jr nz,.k2
        set A_CLR,h
.k2:    bit 4,a
        jr nz,.k3
        set K_TITLE,d
.k3:    ld b,$fd                ; A S D F G
        in a,(c)
        bit 0,a
        jr nz,.k4
        set K_DOWN,d
.k4:    bit 1,a
        jr nz,.k4a
        set K_SMALLER,e
.k4a:   bit 4,a
        jr nz,.k5
        set A_PLAY,h
.k5:    ld b,$df                ; P O I U Y
        in a,(c)
        bit 0,a
        jr nz,.k6
        set K_RIGHT,d
.k6:    bit 1,a
        jr nz,.k6a
        set K_LEFT,d
.k6a:   bit 2,a
        jr nz,.k7
        set 1,l                 ; I: mirror
.k7:    bit 3,a
        jr nz,.k7a
        set A_UNDO,h
.k7a:   bit 4,a
        jr nz,.k8
        set 6,l                 ; Y: check
.k8:    ld b,$7f                ; SPACE SS M N B
        in a,(c)
        bit 0,a
        jr nz,.k9
        set K_PRIM,d
.k9:    bit 2,a
        jr nz,.k9a
        set K_MUSIC,d
.k9a:   bit 3,a
        jr nz,.k9b
        set 0,l                 ; N: onion skin
.k9b:   bit 4,a
        jr nz,.k10
        set K_BIGGER,e
.k10:   ld b,$bf                ; ENTER L K J H
        in a,(c)
        bit 0,a
        jr nz,.k11
        set K_SEC,d
.k11:   bit 1,a
        jr nz,.k11a
        set K_LIB,e
.k11a:  bit 2,a
        jr nz,.k12
        set K_FAST,e
.k12:   bit 3,a
        jr nz,.k13
        set A_SLOW,h
.k13:   ld b,$f7                ; 1 2 3 4 5
        in a,(c)
        bit 0,a
        jr nz,.k14
        set K_CH_MOUSE,e
.k14:   bit 1,a
        jr nz,.k14a
        set K_CH_DIR,e
.k14a:  bit 4,a
        jr nz,.k15
        set 2,l                 ; 5: nudge left
.k15:   ld b,$ef                ; 0 9 8 7 6
        in a,(c)
        bit 2,a
        jr nz,.k16
        set 5,l                 ; 8: nudge right
.k16:   bit 3,a
        jr nz,.k17
        set 4,l                 ; 7: nudge up
.k17:   bit 4,a
        jr nz,.k18
        set 3,l                 ; 6: nudge down
.k18:   ld b,$fe                ; SHIFT Z X C V -> PREV NEXT NEW DEL
        in a,(c)
        cpl
        rrca
        and $0f
        or h
        ld (isr_k3),a
        ld a,l
        ld (isr_k4),a
        ld a,(input_dev)
        cp DEV_DIR
        jr nz,.nd
        call kemp_read
        jr .dev
.nd:    cp DEV_MOUSE
        call z,mouse_read
.dev:   ld a,d
        ld (kb+0),a
        ld hl,kb+NK
        or (hl)
        ld (hl),a
        ld a,e
        ld (kb+1),a
        inc hl
        or (hl)
        ld (hl),a
        ld a,(isr_k3)
        ld (kb+2),a
        inc hl
        or (hl)
        ld (hl),a
        ld a,(isr_k4)
        ld (kb+3),a
        inc hl
        or (hl)
        ld (hl),a
        ld e,0                  ; k5: D, F (A S D F G row), H (ENTER L K J H row)
        ld bc,$fdfe
        in a,(c)
        bit 2,a
        jr nz,.q1
        set K_LAYER,e
.q1:    bit 3,a
        jr nz,.q2
        set K_STYLE,e
.q2:    ld b,$bf
        in a,(c)
        bit 4,a
        jr nz,.q3
        set K_GROUND,e
.q3:    ld b,$ef                ; 9: the Sheet, 0: the Lessons
        in a,(c)
        bit 1,a
        jr nz,.q4
        set K_SHEET,e
.q4:    bit 0,a
        jr nz,.q5
        set K_LESSONS,e
.q5:    ld a,e
        ld (kb+4),a
        inc hl
        or (hl)
        ld (hl),a
        IF MACHINE=128
        call snd_tick
        ENDIF
        pop hl
        pop de
        pop bc
        pop af
        ei
        reti

; The stick (D |= its bits once probed present). The same time whatever is fitted, idle stick or
; nothing (a floating port), so the update count cannot drift between them (kempston_absent, D-046):
; no branches, a table for what the port's value means and masks for the probe's state
; (kprobe: 4..1 probing, 0 present, $ff absent).
kemp_read:
        push de
        in a,($1f)
        ld l,a
        ld h,high kv_tab
        ld c,(hl)               ; its bits, or bit 7 set: not a stick's value
        ld a,(kprobe)
        and 7
        add a,low ks_tab
        ld l,a
        ld h,high ks_tab
        ld b,(hl)               ; $ff present
        ld a,l
        add a,8
        ld l,a
        ld e,(hl)               ; $ff probing
        ld a,c
        rlca
        sbc a,a                 ; $ff not a stick's value
        ld d,a
        cpl
        and b
        and c
        and $1f
        ld b,a                  ; the bits to take
        ld a,(kprobe)           ; probing: one more good read (k - 1), or a bad one ($ff)
        dec a
        or d
        ld c,a
        ld a,(kprobe)
        xor c
        and e
        ld c,a
        ld a,(kprobe)
        xor c
        ld (kprobe),a
        pop de
        ld a,b
        or d
        ld d,a
        ret

; kv_tab: each port value -> its bits 0-4, or $80 when it cannot be a stick's
build_kv:
        ld hl,kv_tab
.l:     ld a,l
        call kemp_valid
        ld a,$80
        jr nz,.s
        ld a,l
        and $1f
.s:     ld (hl),a
        inc l
        jr nz,.l
        ret

kemp_valid:
        ld l,a
        and $e0
        ret nz
        ld a,l
        and 3
        cp 3
        jr z,.both
        ld a,l
        cp a
        ret
.both:  or 1
        ret

mouse_read:
        push de
        ld bc,$fbdf
        in a,(c)
        ld hl,ms_lastx
        ld e,(hl)
        ld (hl),a
        sub e
        ld e,a
        ld d,0
        bit 7,a
        jr z,.x
        dec d
.x:     ld hl,(ms_dx)
        add hl,de
        ld (ms_dx),hl
        ld b,$ff
        in a,(c)
        ld hl,ms_lasty
        ld e,(hl)
        ld (hl),a
        sub e
        ld e,a
        ld d,0
        bit 7,a
        jr z,.y
        dec d
.y:     ld hl,(ms_dy)
        add hl,de
        ld (ms_dy),hl
        ld b,$fa
        in a,(c)
        pop de
        bit 1,a
        jr nz,.b1
        set K_PRIM,d
.b1:    bit 0,a
        ret nz
        set K_SEC,d
        ret

build_im2:
        ld hl,im2_table
        ld de,im2_table+1
        ld bc,256
        ld (hl),high im2_jump
        ldir
        ld a,$c3
        ld (im2_jump),a
        ld hl,isr
        ld (im2_jump+1),hl
        ld a,high im2_table
        ld i,a
        im 2
        ret

; ---------------------------------------------------------------- sound (128K AY)
; Template stand-in player until zx-assets sound lands: the Start tune on A/B (Start screen
; only, PRES-01), effects on C; music off silences A/B, effects keep playing.
        IF MACHINE=128
MUS_SPEED       equ 8
SFX_LEN         equ 8

snd_init:
        ld a,7
        ld e,%00111000
        call ay_out
        ld e,0
        ld a,8
        call ay_out
        ld a,9
        call ay_out
        ld a,10
        jp ay_out

snd_tick:
        call song_tick
        call mus_tick
        jp sfx_tick

; The Start screen's tune. With music off it still runs, writing to a port nothing answers in the
; same time, so music on or off changes nothing else, frame for frame (music_parity, D-044).
mus_tick:
        ld a,(phase)
        or a
        jr z,.start
        xor a                   ; off the Start screen: silent
.off:   ld hl,mus_live
        cp (hl)
        ret z
        ld (hl),a
        ld e,a
        ld a,8
        call ay_out
        ld a,9
        jp ay_out
.start: ld a,(music)
        or a
        jr nz,.on
        ld hl,mus_live          ; just turned off: silence once
        cp (hl)
        jr nz,.off
.on:    ld (mus_live),a
.tick:  ld hl,mus_timer
        dec (hl)
        jr nz,.vol
        ld (hl),MUS_SPEED
        ld a,(mus_pos)
        inc a
        and 15
        ld (mus_pos),a
        add a,a
        ld e,a
        ld d,0
        ld hl,(mus_song)
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        xor a
        call mus_out
        push de
        ld e,d
        ld a,1
        call mus_out
        pop hl
        add hl,hl
        ld e,l
        ld a,2
        call mus_out
        ld e,h
        ld a,3
        call mus_out
        ld e,9
        ld a,9
        call mus_out
.vol:   ld a,(mus_timer)
        add a,4
        ld e,a
        ld a,8
mus_out:
        push af                 ; music on: the AY; off: the same time, no sound
        ld a,(music)
        or a
        jp z,.f
        pop af
        jp ay_out
.f:     pop af
        jp ay_fake

song_tick:
        ld a,(song_req)
        or a
        ret z
        ld c,a
        xor a
        ld (song_req),a
        ld a,c
        ld (cur_song),a
        ld hl,mus_notes
        ld (mus_song),hl
        ld a,15
        ld (mus_pos),a
        ld a,1
        ld (mus_timer),a
        ret

sfx_tick:
        ld a,(sfx_req)
        or a
        jr z,sfx_run
sfx_start:                      ; an effect starts, A = its id (zx-media-kit's trigger check): 1 click,
        ld (sfx_kind),a         ; 2 refused (a low blip), 3 chime (input chosen, sheet saved or loaded),
        xor a                   ; 4 undo or redo (a soft click): spec section 9 (D-070)
        ld (sfx_req),a
        ld a,(sfx_kind)
        cp 3
        ld a,SFX_LEN
        jr nz,.l
        add a,a                 ; (the chime lasts twice as long)
.l:     ld (sfx_timer),a
sfx_run:
        ld a,(sfx_timer)
        or a
        ret z
        dec a
        ld (sfx_timer),a
        add a,a
        add a,a
        add a,a
        ld e,a
        ld a,(sfx_kind)         ; the pitch: a base for each kind
        ld c,a
        ld b,0
        ld hl,sfx_base-1
        add hl,bc
        ld a,(hl)
        add a,e
        ld e,a
        ld a,4
        call ay_out
        ld e,0
        ld a,5
        call ay_out
        ld a,(sfx_timer)
        ld e,a
        ld a,(sfx_kind)
        cp 4
        jr nz,.v
        srl e                   ; (soft)
.v:     ld a,10
        jp ay_out               ; (not into ay_fake below: the effects were silent from M4 to M7, D-070)
; as ay_out, to ports no device decodes ($FFFF, $BFFF: A1 set, uncontended), in the same time
ay_fake:
        ld bc,$ffff
        out (c),a
        ld b,$bf
        out (c),e
        ret

ay_out: ld bc,AY_SELECT
        out (c),a
        ld b,high AY_DATA
        out (c),e
        ret

mus_notes:  dw 424,378,336,318, 283,318,336,378, 424,336,283,252, 283,336,378,424
mus_song:   dw mus_notes
mus_timer:  db 1
mus_pos:    db 15
mus_live:   db 0
sfx_timer:  db 0
sfx_kind:   db 1
sfx_base:   db 40,160,16,40         ; click, blip, chime, soft click
        ENDIF

; ---------------------------------------------------------------- drawing helpers
fill_attr:
        push af
        ld a,d
        rrca
        rrca
        rrca
        ld l,a
        and 3
        or $58
        ld h,a
        ld a,l
        and $e0
        or e
        ld l,a
        pop af
.r:     push hl
        push bc
.c:     ld (hl),a
        inc l
        djnz .c
        pop bc
        pop hl
        push de
        ld de,32
        add hl,de
        pop de
        dec c
        jr nz,.r
        ret

print_at:
        ld a,(hl)
        or a
        ret z
        call print_char
        inc hl
        inc e
        jr print_at

print_char:
        push hl
        push de
        push bc
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        ld bc,$3c00
        add hl,bc
        ld a,d
        and 7
        rrca
        rrca
        rrca
        or e
        ld c,a
        ld a,d
        and $18
        or $40
        ld d,a
        ld e,c
        ld b,8
.r:     ld a,(hl)
        ld (de),a
        inc hl
        inc d
        djnz .r
        pop bc
        pop de
        pop hl
        ret

row_addr:
        ld l,a
        and 7
        or $40
        ld h,a
        ld a,l
        rra
        rra
        rra
        and $18
        or h
        ld h,a
        ld a,l
        rla
        rla
        and $e0
        ld l,a
        ret

zero32: ds 32

        INCLUDE "house/house.asm"
        INCLUDE "library.asm"
        INCLUDE "masks.asm"

; The Test Ground's entries: its code is in bank 6 (D-051)
act_ground:
        ld hl,g6_enter
        jr bank6_call
ground_logic:
        ld hl,g6_logic
        jr bank6_call
ground_draw:
        ld hl,g6_draw
; HL = a routine in bank 6: paged in for the call, the bank before restored after. cur_bank is the
; bank page_home goes back to, so routines that page another bank (Undo, the Library) come back here.
bank6_call:
        ld a,(cur_bank)
        push af
        ld a,6
        ld (cur_bank),a
        call page_bank
        call .go
        pop af
        ld (cur_bank),a
        jp page_bank
.go:    jp (hl)

; every Test Ground panel whole again
act_sheet:
        ld hl,g6_sheet
        jp bank6_call
act_lessons:
        ld hl,g6_lessons
        jp bank6_call

; the Library's Mower into the current figure (the Lessons: lessons.asm), from bank 6
les_mower:
        ld a,LIB_MOWER
        ld (lib_sel),a
        call lib_rec
        ld a,LIB_INDEX_BANK
        call page_bank
        ld de,lib_now
        ld bc,32
        ldir
        call page_home
        jp lib_open_fig

; ---------------------------------------------------------------- the sheet (SHEET-01, D-061)
; Figure k's head is at sh_heads + k * SHEET_HEAD, its frames and masks (2048 bytes) at $C000 + k * 2048
; in sh_bank. The current figure is worked on in place (sheet); sh_store puts it back.
; A = figure -> HL = its head (the live one for the current figure)
sh_head:
        ld hl,sh_cur
        cp (hl)
        ld hl,sheet
        ret z
        ld hl,sh_heads
        or a
        ret z
        ld b,a
        ld de,SHEET_HEAD
.m:     add hl,de
        djnz .m
        ret

; A = figure -> HL = its frames in sh_bank (not paged in)
sh_slot:
        add a,a
        add a,a
        add a,a
        add a,$c0
        ld h,a
        ld l,0
        ret

; the current figure back to its place on the sheet (its masks finished first)
sh_store:
        call mask_finish
        ld a,(sh_cur)           ; (not sh_head: that gives the live head for the current figure)
        ld hl,sh_heads
        or a
        jr z,.h
        ld b,a
        ld de,SHEET_HEAD
.m:     add hl,de
        djnz .m
.h:     ex de,hl
        ld hl,sheet
        ld bc,SHEET_HEAD
        ldir
        ld a,(sh_bank)
        call page_bank
        ld a,(sh_cur)
        call sh_slot
        ex de,hl
        ld hl,frames_data
        ld bc,2*MAX_FRAMES*MAX_FBYTES
        ldir
        jp page_home

; A = figure -> it is current (its head and frames into the sheet)
sh_fetch:
        ld (sh_cur),a
        push af
        ld hl,sh_heads
        or a
        jr z,.h
        ld b,a
        ld de,SHEET_HEAD
.m:     add hl,de
        djnz .m
.h:     ld de,sheet
        ld bc,SHEET_HEAD
        ldir
        ld a,(sh_bank)
        call page_bank
        pop af
        call sh_slot
        ld de,frames_data
        ld bc,2*MAX_FRAMES*MAX_FBYTES
        ldir
        call page_home
; a figure has arrived on the Desk (from the sheet, the Library or a new one): what follows it
fig_arrived:
        call box_derive
        xor a
        ld (undo_ok),a          ; Undo starts afresh with each figure (D-061)
        ld (sh_lundo),a
        ld (undo_redo),a
        ld (play_frame),a
        ld (check_on),a
        call mask_all_auto      ; (a Hand mask is kept as it is)
        call fig_check
        call checks_again
        jp fix_play

; A = figure -> the current figure is put away and this one opened
sh_switch:
        push af
        call sh_store
        pop af
        call sh_fetch
        ld a,EV_OPENED
        ld (last_event),a
        ret

; a new blank figure, current -> carry set if the sheet is full
sh_add:
        ld a,(sh_count)
        cp SH_MAX
        ccf
        ret c
        call sh_store
        ld a,(sh_count)
        ld (sh_cur),a
        inc a
        ld (sh_count),a
        ld hl,sh_blank
        ld de,sheet
        ld bc,SHEET_HEAD
        ldir
        ld a,(sh_count)         ; its name: FIGURE and its number
        add a,'0'
        ld (fig_name+7),a
        ld hl,frames_data
        ld de,frames_data+1
        ld bc,2*MAX_FRAMES*MAX_FBYTES-1
        ld (hl),0
        ldir
        call fig_arrived
        ld a,EV_NEWFIG
        ld (last_event),a
        or a
        ret
sh_blank:   db 1,0,16,16,2,32,"FIGURE 1",0,0,0,$ff,MS_RING,2
        ASSERT $-sh_blank == SHEET_HEAD

; ---------------------------------------------------------------- the sheet on tape (SHEET-01, D-062)
; A sheet file: a CODE header "SHEET", block A (magic "SS", version, figures, current, the heads) and a
; headerless block B (each figure's frames and masks, 2048 bytes a figure). The ROM's SA-BYTES and
; LD-BYTES do the work, interrupts off; SPACE is BREAK (the ROM's error path is caught: tape_call).
SA_BYTES    equ $04c2
LD_BYTES    equ $0556
ERR_SP      equ $5c3d
SH_FA_LEN   equ 5+SH_MAX*SHEET_HEAD
SH_VERSION  equ 1

; HL = SA_BYTES or LD_BYTES, A = flag, IX = start, DE = length -> carry set if the block went right
tape_call:
        ld (tp_rom),hl
        ld (tp_flag),a
        di
        push de
        call snd_init           ; the AY quiet while the ROM has the machine
        pop de
        ld (tp_iy),iy
        ld hl,(ERR_SP)
        ld (tp_err),hl
        ld hl,.caught
        push hl
        ld (ERR_SP),sp          ; BREAK (SPACE) ends in the ROM's error routine: it returns here
        ld iy,$5c3a
        ld a,(tp_flag)
        scf                     ; (LD-BYTES: load, not verify)
        ld hl,(tp_rom)
        call .go
        pop hl                  ; (the catch's address)
        jr .done
.caught:
        or a                    ; BREAK: carry clear
.done:  push af
        ld hl,(tp_err)
        ld (ERR_SP),hl
        ld iy,(tp_iy)
        xor a                   ; the border black again
        out ($fe),a
        ld (frames),a           ; no debt of updates for the time on tape
        ld a,(cur_bank)         ; (the ROM leaves the paging alone, but be sure)
        call page_bank
.rel:   ld a,$7f                ; SPACE (BREAK) let go first: it is not a press on the page
        in a,($fe)
        rra
        jr nc,.rel
        ld hl,kb                ; and forgotten: the ROM lets interrupts in before its BREAK
        ld b,2*NK               ; test, so the key reader may have latched it
.z:     ld (hl),0
        inc hl
        djnz .z
        call lock_buttons
        ei
        pop af
        ret
.go:    jp (hl)

; the sheet to tape -> carry set if saved
sh_save:
        call sh_store
        call sh_filea           ; block A in sh_fbuf
        ld hl,sh_hdr_t          ; the header
        ld de,sh_hdr
        ld bc,17
        ldir
        ld ix,sh_hdr
        ld de,17
        xor a
        ld hl,SA_BYTES
        call tape_call
        ret nc
        ld ix,sh_fbuf
        ld de,SH_FA_LEN
        ld a,$ff
        ld hl,SA_BYTES
        call tape_call
        ret nc
        call sh_blen            ; DE = the frames' length
        ld a,(sh_bank)
        ld (cur_bank),a         ; (paged in for the ROM, put back after)
        call page_bank
        ld ix,$c000
        ld a,$ff
        ld hl,SA_BYTES
        call tape_call
        push af
        ld a,6
        ld (cur_bank),a
        call page_bank
        pop af
        ret

; DE = the frames' bytes on the sheet (2048 a figure)
sh_blen:
        ld a,(sh_count)
        add a,a
        add a,a
        add a,a
        ld d,a
        ld e,0
        ret

; a sheet from tape, into the other bank; checked; then it replaces the sheet (one Undo step)
; -> A = 0 loaded, 1 broken off or a tape error, 2 not a sheet
sh_load:
        call sh_store
        ld ix,sh_hdr
        ld de,17
        xor a
        ld hl,LD_BYTES
        call tape_call
        ld a,1
        ret nc
        ld a,(sh_hdr)           ; a CODE file (any name: a saved sheet, or a Library tape's
        cp 3                    ; figures); block A's magic says whether it is a sheet
        ld a,2
        ret nz
        ld ix,sh_fbuf
        ld de,SH_FA_LEN
        ld a,$ff
        ld hl,LD_BYTES
        call tape_call
        ld a,1
        ret nc
        call sh_valid
        ld a,2
        ret nz
        ld a,(sh_fbuf+3)        ; the frames, into the bank not in use
        add a,a
        add a,a
        add a,a
        ld d,a
        ld e,0
        ld a,(sh_bank)
        xor 7
        ld (cur_bank),a
        call page_bank
        ld ix,$c000
        ld a,$ff
        ld hl,LD_BYTES
        call tape_call
        push af
        ld a,6
        ld (cur_bank),a
        call page_bank
        pop af
        ld a,1
        ret nc
        ld hl,sh_heads          ; the sheet before, kept for Undo; the loaded one in its place
        ld de,sh_old+2
        ld bc,SH_MAX*SHEET_HEAD
        ldir
        ld a,(sh_count)
        ld (sh_old),a
        ld a,(sh_cur)
        ld (sh_old+1),a
        ld hl,sh_fbuf+5
        ld de,sh_heads
        ld bc,SH_MAX*SHEET_HEAD
        ldir
        ld a,(sh_fbuf+3)
        ld (sh_count),a
        ld a,(sh_bank)
        xor 7
        ld (sh_bank),a
        ld a,(sh_fbuf+4)
        call sh_fetch
        ld a,1
        ld (undo_ok),a
        ld (sh_lundo),a
        xor a
        ret

; Undo or Redo of a load: the two sheets change places
sh_unload:
        ld hl,sh_heads
        ld de,sh_old+2
        ld b,SH_MAX*SHEET_HEAD
.s:     ld a,(de)
        ld c,(hl)
        ld (hl),a
        ld a,c
        ld (de),a
        inc hl
        inc de
        djnz .s
        ld a,(sh_old)
        ld b,a
        ld a,(sh_count)
        ld (sh_old),a
        ld a,b
        ld (sh_count),a
        ld a,(sh_old+1)
        ld b,a
        ld a,(sh_cur)
        ld (sh_old+1),a
        ld a,(sh_bank)
        xor 7
        ld (sh_bank),a
        ld a,b
        call sh_fetch
        ld a,1
        ld (undo_ok),a
        ld (sh_lundo),a
        ld a,(undo_redo)
        xor 1
        ld (undo_redo),a
        ret

; Export (SHEET-01): the current figure's frames, then their masks, as assembler text (a comment line,
; then " DEFB $xx,..." a row), built in bank 3 after Undo's copies and saved as a CODE file named after
; the figure -> carry set if saved
EX_BUF      equ pre_buf+SHEET_LEN
sh_export:
        ld a,UNDO_BANK
        ld (cur_bank),a
        call page_bank
        ld de,EX_BUF
        ld hl,s_ex_head         ; "; NAME WXH, n FRAMES: PICTURES, THEN MASKS"
        call ex_str
        ld hl,fig_name
        call ex_str
        ld a,' '
        call ex_ch
        ld a,(box_w)
        call ex_num
        ld a,'X'
        call ex_ch
        ld a,(box_h)
        call ex_num
        ld hl,s_ex_head2
        call ex_str
        ld a,(nframes)
        call ex_num
        ld hl,s_ex_head3
        call ex_str
        xor a                   ; the pictures, then the masks
        ld (ex_k),a
.fr:    ld a,(ex_k)
        push de
        call frame_ptr
        pop de
        ld a,(box_h)
        ld c,a
.row:   push bc
        push hl
        ld hl,s_ex_defb
        call ex_str
        pop hl
        ld a,(bpr)
        ld b,a
.b:     ld a,'$'
        call ex_ch
        ld a,(hl)
        call ex_hex
        inc hl
        dec b
        jr z,.e
        ld a,','
        call ex_ch
        jr .b
.e:     ld a,10
        call ex_ch
        pop bc
        dec c
        jr nz,.row
        ld hl,ex_k              ; the next frame; after the last picture, the first mask
        inc (hl)
        ld a,(nframes)
        cp (hl)
        jr nz,.nm
        ld (hl),MAX_FRAMES
.nm:    ld a,(nframes)
        add a,MAX_FRAMES
        cp (hl)
        jr nz,.fr
        ex de,hl                ; the length
        ld de,EX_BUF
        or a
        sbc hl,de
        ld (ex_len),hl
        ld hl,sh_hdr_t          ; the header: CODE, the figure's name, the length
        ld de,sh_hdr
        ld bc,17
        ldir
        ld hl,fig_name
        ld de,sh_hdr+1
        ld b,8
.n:     ld a,(hl)
        or a
        jr z,.np
        ld (de),a
        inc hl
        inc de
        djnz .n
        jr .nd
.np:    ld a,' '
.npl:   ld (de),a
        inc de
        djnz .npl
.nd:    ld hl,(ex_len)
        ld (sh_hdr+11),hl
        ld ix,sh_hdr
        ld de,17
        xor a
        ld hl,SA_BYTES
        call tape_call
        jr nc,.home
        ld ix,EX_BUF
        ld de,(ex_len)
        ld a,$ff
        ld hl,SA_BYTES
        call tape_call
.home:  push af
        ld a,6
        ld (cur_bank),a
        call page_bank
        pop af
        ret

ex_str: ld a,(hl)
        or a
        ret z
        call ex_ch
        inc hl
        jr ex_str
ex_ch:  ld (de),a
        inc de
        ret
ex_hex: push af
        rrca
        rrca
        rrca
        rrca
        call .d
        pop af
.d:     and 15
        add a,'0'
        cp '9'+1
        jr c,ex_ch
        add a,7
        jr ex_ch
ex_num: cp 10                   ; A < 100
        jr c,.one
        ld c,'0'-1
.t:     inc c
        sub 10
        jr nc,.t
        add a,10
        push af
        ld a,c
        call ex_ch
        pop af
.one:   add a,'0'
        jr ex_ch
s_ex_head:  db "; ",0
s_ex_head2: db ", ",0
s_ex_head3: db " FRAMES: PICTURES, THEN MASKS (SPRITE STUDIO)",10,0
s_ex_defb:  db " DEFB ",0

sh_hdr_t:   db 3,"SHEET     "   ; a CODE header: the name, then the length and start
            dw SH_FA_LEN,$8000,$8000

gn_all: ld a,7
        ld (gn_need),a
        ld (gn_full),a
        ret

; a mask is finished: the Grid shows it if it is the current frame's on the Mask layer
mask_shown:
        ld a,(mstyle)           ; Hand (a mask finished after the style turned): the checks count
        cp MS_HAND              ; against it (not asking for masks again)
        jr nz,.ms
        ld a,(nframes)
        ld (chk_pend),a
        xor a
        ld (chk_ph),a
.ms:    ld a,(gn_open)          ; the Test Ground: its panels again
        or a
        jp nz,gn_all
        ld a,(layer)
        or a
        ret z
        ld a,(mk_k)
        ld hl,cur_frame
        cp (hl)
        ret nz
        ld a,(txt_dirty)        ; the HEX column shows the mask's codes, the readout COVER/KEEP
        or 4+1                  ; (m4-r1 F-26, m4-r2 F-35)
        ld (txt_dirty),a
        jp dirty_all

; ---------------------------------------------------------------- variables
updates:    dw 0
state:      db ST_START
phase:      db 0
lives:      db 1
redraw:     db 0
input_dev:  db DEV_NONE
inked:      dw 0
visited:    db 0
last_event: db 0
ev_p1:      db 0
ev_p2:      db 0
ev_p3:      db 0
act_id:     db 0
cx16:       dw 72*16
cy16:       dw 80*16
cur_x:      db 72
cur_y:      db 80
drawn_x:    db 0
drawn_y:    db 0
cur_drawn:  db 0
xc_col:     db 0
xc_sh:      db 0
gc_col:     db 8
gc_row:     db 8
rep_dirs:   db 0
rep_t:      db 0
steer_n:    db 0
sq_ok:      db 0
sq_col:     db 0
sq_row:     db 0
cur_was_ok: db 0
stroke:     db 0                ; 0 none, 1 primary, 2 secondary
pmode:      db 0                ; 1 ink, 0 clear
last_ok:    db 0
last_col:   db 0
last_row:   db 0
ln_x:       db 0
ln_y:       db 0
ldx:        db 0
ldy:        db 0
lsx:        db 0
lsy:        db 0
lerr:       db 0
undo_ok:    db 0
undo_redo:  db 0
play_on:    db 0
play_lvl:   db PLAY_DEFAULT
play_t:     db 4
play_frame: db 0
onion_on:   db 0
drawer:     db 0
light_row:  db $ff
light_t:    db 0
light_attr: db 0
check_on:   db 0
chk_frame:  db 0
chk_sel:    db $ff
chk_k:      db 0
chk_al:     db 0
chk_total:  db 0
chk_wait:   db 0                ; CHECK pressed while the checks were being worked out
fl_on:      db 0                ; the flicker demonstration (FLICK-01, ground.asm): on
les_cap:    ds 33               ; the lesson's caption (DEMO-01, lessons.asm)
les_slot:   db $ff              ; the sheet figure the lessons use ($ff: none yet)
les_sel:    db 0                ; the Lessons page's bar
fl_state:   db 0                ; 0 idle, 1 to rub out, 2 to draw
fl_valid:   db 0                ; the RUB OUT, DRAW copy has a figure drawn, at:
fl_ox:      db 0
fl_oy:      db 0
fl_odir:    db 0
fl_of:      db 0
; the sheet on tape (D-062): here, not in the $6000 block (full)
sh_old:     ds 2+SH_MAX*SHEET_HEAD  ; that sheet's figures, current and heads
sh_hdr:     ds 17                   ; a tape header
stray_n:    ds MAX_FRAMES               ; (stray_n, alike, outside_n in this order: act_check)
alike:      ds MAX_FRAMES
outside_n:  ds MAX_FRAMES
chk_need:   ds MAX_FRAMES
nudge_n:    db 0
every_on:   db 0
ef_body:    dw 0
ef_ev:      db 0
sb_out:     dw 0
sb_src:     dw 0
sb_u:       dw 0
sb_d:       dw 0
img_budget: db 0
img_i:      db 0
img_dst:    dw 0
img_srcp:   dw 0
img_attr:   db 0
gc_on:      db 0
gc_rows:    db 0
gc_prev:    dw 0
gc_cur:     dw 0
gw_dst:     dw 0
ex_out:     dw 0
ex_row:     db 0
ex_off:     dw 0
ex_pi:      dw 0
ex_pp:      dw 0
ex_pc:      dw 0
ex_n:       db 0
ex_fl:      db 0
dk_kindb:   db 0
dk_attr:    db 0
im_src:     dw 0
im_col:     db 0
im_y:       db 0
im_wc:      db 0
im_h:       db 0
im_half:    db 0
im_fw:      db 0
im_fh:      db 0
im_ox:      db 0
im_oy:      db 0
im_r:       db 0
im_n:       db 0
im_all:     db 0
im_k:       db 0
cd_r:       db 0
cd_b:       db 0
cd_n:       db 0
dk_row:     db 0
dk_col:     db 0
dk_kind:    db 0
dk_noattr:  db 0
gbuf:       ds 8
sq_n:       db 0
sq_queue:   ds SQ_CAP*3
marker_have: db $ff
code_mark_have: db $ff
music_dirty: db 0
frames:     db 0
isr_k3:     db 0
isr_k4:     db 0
kb:         ds 6*NK
kprobe:     db $ff
ms_lastx:   db 0
ms_lasty:   db 0
ms_dx:      dw 0
ms_dy:      dw 0
music:      db 1
sfx_req:    db 0
song_req:   db 0
cur_song:   db 0
bank_shadow: db ROM48
pd_table:   dw panels
pd_count:   db N_PANELS
lib_open:   db 0
lib_sel:    db LIB_MOWER
lib_top:    db 0
lib_bar_have: db $ff
lib_frame:  db 0
lib_t:      db 0
lib_prev:   db 0
lib_head:   db 0
lib_bpr:    db 0
lib_fb:     db 0
lib_ox:     db 0
lib_oy:     db 0
lib_now:    ds 32
btn_want:   ds N_ROWS,AT_BUTTON
btn_have:   ds N_ROWS
pend_n:     db 0
pd_left:    db 0
pd_bit:     db 0
txt_dirty:  db 0
txt_pend:   db 0
chk_pend:   db 0
pd_w:       db 0
pd_h:       db 0
pend_list:  ds DRAW_CAP*3
row_dirty:  ds 16
row_pend:   ds 16                   ; (straight after row_dirty: draw_desk clears both)
kbuf:       ds 64                   ; two square rows' kinds
im_buf:     ds 4
sb_rows:    ds 4*(MAX_BPR+2)        ; stray_bits: above, this row, below, V; a blank byte either side
sb_n:       db 0
bx_rows:    db 0
bx_cols:    db 0
bx_src:     dw 0
bx_dst:     dw 0
sq_sh:      db 0
cd_band:    db $ff
blink:      db 0
blink_t:    db BLINK_TIME
cnt_dirty:  db 0
img_need:   dw 0
img_full:   dw 0
img_rlo:    db 0
img_rhi:    db 255
grid_any:   db 0
row_force:  ds 16
sq_cap:     db SQ_CAP
halted:     db 0
cur_bank:   db 0                    ; the bank page_home restores
mk_style:   db 0
ex_mk:      db 0
gn_open:    db 0
gn_ground:  db 0
gn_frame:   db 0
gn_need:    db 0
gn_full:    db 0
gn_p:       db 0
gn_whole:   db 0
gn_ox:      db 0
gn_oy:      db 0
gn_col:     db 0
gn_y:       db 0
gn_n:       db 0
gn_g:       db 0
gn_src:     dw 0
gn_msk:     dw 0
gn_buf:     ds 6
gn_busy:    db 0
gn_cap:     db 0
fp_base:    db 0
layer:      db 0                    ; 0 the picture, 1 the mask (MASK-01)
pre_style:  db 0
mk_need:    db 0
mk_st:      db 0
mk_k:       db 0
mk_r:       db 0
mk_n:       db 0
mk_chg:     db 0
mk_src:     dw 0
mk_dst:     dw 0
mk_x:       ds 4*MAX_BPR
img_heavy:  db 0
skipped:    db 0
img_cap:    db IMG_CAP
draw_cap:   db DRAW_CAP
cur_was_r:  db 0
cur_was_c:  db 0
sb_cap:     db 0
chk_ph:     db 0
al_a:       dw 0
al_b:       dw 0
al_d:       dw 0
al_u:       dw 0
al_n:       db 0
row_tmp:    ds MAX_BPR

code_end:

        ASSERT (im2_jump & $ff) == (im2_jump >> 8)
        ASSERT (im2_table & $ff) == 0 && (im2_table >> 8) == (im2_jump & $ff) + 1
        ASSERT code_end + 256 < stack_top
        ; routines that page another bank in at $C000 must be resident (M6: export once moved into bank 6)
        ASSERT tape_call < $c000 && sh_save < $c000 && sh_load < $c000 && sh_export < $c000
        ASSERT sh_store < $c000 && sh_fetch < $c000 && sh_unload < $c000 && page_bank < $c000
        SAVEBIN "main.bin",code_start,code_end-code_start

; The Library's lines and frames (tools/build_library.py) in bank 1
        IF MACHINE=128
        SLOT 3
        PAGE 1
        ORG $c000
bank1_start:
        INCBIN "gen/library1.bin"
bank1_end:
        SAVEBIN "bank1.bin",bank1_start,bank1_end-bank1_start

; The rest of the Library, then the Start screen's packed picture, in bank 4 (paged in by draw_start)
START_BANK  equ 4
        PAGE START_BANK
        ORG $c000
bank4_start:
        IF LIB_BANK4_LEN > 0
        INCBIN "gen/library4.bin"
        ENDIF
start_rle:  INCBIN "gen/start.rle"
bank4_end:
        ASSERT bank4_end <= $10000
        SAVEBIN "bank4.bin",bank4_start,bank4_end-bank4_start

; The Test Ground's code (and, in M5, the colour and walking test) in bank 6 (D-051)
        PAGE 6
        ORG $c000
bank6_start:
        INCLUDE "ground.asm"
        INCLUDE "sheet.asm"
        INCLUDE "lessons.asm"
bank6_end:
        SAVEBIN "bank6.bin",bank6_start,bank6_end-bank6_start
        ENDIF

        INCLUDE "harness.asm"
