; Harness contract (see the zx-game template's harness.asm for the full description).
; Sprite Studio mapping: design.md section 7.

HARNESS_updates     equ updates
HARNESS_state       equ state         ; 0 Start, 1 Desk
HARNESS_lives       equ lives         ; always 1: no lives
HARNESS_score       equ inked         ; inked squares in the current frame (binary)
HARNESS_level       equ cur_frame     ; current frame, 0-based (D-011)
HARNESS_player_x    equ cur_x         ; Arrow hotspot, or the Grid Cursor square's centre (pixels)
HARNESS_player_y    equ cur_y
HARNESS_phase       equ phase         ; 0 Start, 1 Desk
HARNESS_redraw      equ redraw

HARNESS_music       equ music
HARNESS_song        equ cur_song
