; The Test Ground's grounds (below $C000: the check tools read them), D-051
gn_names:   dw gn_n0,gn_n1,gn_n2,gn_n3
gn_n0:      db "GRASS ",0
gn_n1:      db "STRIPE",0
gn_n2:      db "PAPER ",0
gn_n3:      db "INK   ",0
; the Grounds, 8 dot rows each, the same byte across
gn_pats:    db $44,$44,$4c,$c8,$88,$89,$99,$11     ; grass: thin blades
            db $ff,$ff,$00,$00,$ff,$ff,$00,$00     ; stripes
            db $00,$00,$00,$00,$00,$00,$00,$00     ; plain paper
            db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff     ; plain ink
; the Grounds' colours (bright): grass green on white, stripes blue on yellow, paper black on cyan,
; ink yellow on blue (CLASH-01)
gn_attrs:   db $7c,$71,$68,$4e
; the colour strip's state (st_*: ground.asm), here so the check tools can read it
cmode:      db 0                    ; colour mode: 0 Keep, 1 Ink, 2 Box
wk_on:      db 0                    ; Walk on (MOVE-01)
wk_step:    db 1                    ; T-STEPS index: 2 dots
wk_steps:   db 1,2,4,8              ; T-STEPS
wk_play:    db 0                    ; Walk turned the flip-book on
fig_flags:  db 0                    ; the figure's checks: bit 0 hard to see, bit 1 moves too far
chk_ftot:   db 0                    ; the frames' checks (check_tick)
gn_act:     db 0
gn_turn:    db 0
gn_txt:     db 0
st_tx:      db 0                    ; where the figure is to be: x, y, facing (1: left)
st_ty:      db 0
st_tdir:    db 0
st_bx:      db 0                    ; the snapshot being built or drawn: x, y, facing, frame, Ground,
st_by:      db 0                    ; mode, ink
st_bdir:    db 0
st_bf:      db 0
st_bg:      db 0
st_bmode:   db 0
st_bink:    db 0
st_dx:      db 0                    ; the snapshot last drawn: x, y, facing, frame, Ground, mode, ink
st_dy:      db 0                    ; (as st_bx ... st_bink: the check tools read it while walking)
st_ddir:    db 0
st_df:      db 0
st_dg:      db 0
st_dmode:   db 0
st_dink:    db 0
st_dvalid:  db 0
st_bld:     db 0                    ; building (rows done: st_brow)
st_brow:    db 0
st_go:      db 0                    ; built, to draw
st_busy:    db 0                    ; being drawn
st_full:    db 0                    ; the whole strip next
st_bfull:   db 0                    ; ... for the snapshot being built or drawn
st_dirty:   db 0                    ; mode, ink or Ground changed
st_cap:     db 0
st_ncx:     db 0                    ; the cells the box touches, across and down
st_ncy:     db 0
st_clash:   db 0
st_gattr:   db 0
st_mattr:   db 0
st_chg:     db 0
st_i:       db 0
st_j:       db 0
st_cl:      ds 25                   ; the box's cells that clash, 5 a row
st_r0:      db 0
st_r1:      db 0
st_rt:      db 0
st_c0:      db 0
st_nc:      db 0
st_cx:      db 0
st_cy:      db 0
st_g:       db 0
st_acap:    db 0
gn_rows:    db 0                    ; this update's caps (gn_caps)
st_bud:     db 0
st_abud:    db 0
st_rbud:    db 0
st_rcap:    db 0
st_sp:      dw 0                    ; the next picture and mask rows to shift
st_mp:      dw 0
st_ast:     db 0                    ; drawing the cells' colours
; the sheet (SHEET-01, sheet.asm and main.asm's sh_*)
SH_MAX      equ 8                   ; T-FIGURES
sh_count:   db 1                    ; figures on the sheet
sh_cur:     db 0                    ; the current one (in sheet)
sh_sel:     db 0                    ; the Sheet page's bar
sh_bar_have: db $ff
sh_bank:    db 0                    ; the bank holding the figures' frames (0; 7 after a load: D-061)
sh_face:    db 1                    ; facings for the data size (1 or 2)
sh_pos:     db 8                    ; positions (1, 2, 4 or 8)
sh_grp:     db 0
sh_codes:   dw 0                    ; the picture's codes (the mask's are as many)
sh_msg:     dw 0
sh_act:     db 0
sh_heads:   ds SH_MAX*SHEET_HEAD
sh_lundo:   db 0                    ; Undo would put back the sheet before a load
tp_rom:     dw 0
tp_flag:    db 0
tp_iy:      dw 0
tp_err:     dw 0
ex_k:       db 0                    ; export: the frame being written
ex_len:     dw 0
