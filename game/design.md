# Sprite Studio: engine and design (128K)

## 1. Target

- Machine: 128K (128/+2 timing, 70,908 T a frame). AY for the Start tune and effects.
- Update rate: one update every frame (`update_frames: 1`); a spec "refresh" is one update (D-004).
- Genre: a drawing tool. Two screens (Start, Desk), no scrolling, one software arrow.
- Picture Format (spec §5) = the Spectrum screen: dots = pixels, Colour Blocks = 8 × 8 attribute cells,
  Row Codes = bytes, MSB left.

Layout (character cells, 32 × 24):

| Screen | Rows / columns | Contents |
| --- | --- | --- |
| Start | rows 2-4 | "SPRITE STUDIO" heading (placeholder until the zx-assets title picture, D-007) and tagline |
| Start | rows 8-9 | "CHOOSE YOUR INPUT", `1 MOUSE`, `2 KEYS/JOYSTICK` |
| Start | rows 20-23 | legend, "MUSIC ON (M)", `PRESS 1 OR 2`, Dalex footer |
| Desk | row 0 | "SPRITE STUDIO", sprite name and box (`MOWER 16X16`) |
| Desk | cols 0-17, rows 1-18 | a white sheet: the Grid's margin, with hex column numbers 0-F on row 1 and row numbers on col 0 (D-016, TT-3, TT-10) |
| Desk | cols 1-16, rows 2-17 | the Grid: 16 × 16 squares, one character cell per square (x 8-135, y 16-143); heavier line after column 7 |
| Desk | rows 1-6, cols 18-27 | "TRUE SIZE" over "FRAME" and "PLAY"; the frame at cols 19-20 rows 4-5 and the flip-book at cols 25-26 rows 4-5, each on a white 4 × 4-cell card (TT-4) |
| Desk | rows 7-12, cols 18-31 | readouts: input, square (hex column,row), frame n of N, inked, flip-book time and play state, last event |
| Desk | rows 14-18, cols 18-30 | ten controls, two a row, 6 cells wide: PREV Z, NEXT X / COPY C, DEL V / CLR R, UNDO U / PLAY G, BACK T / SLOW J, FAST K; a used control lights yellow, a refused one FLASHes red for 0.64 s (TT-6) |
| Desk | rows 19-21, cols 1-23 | frame strip: slot i at cols 1+3i, rows 19-20, true size; "^^" under the current frame on row 21; "FRAMES" at row 19 col 25 |
| Desk | rows 22-23 | key legend |

Grid squares: paper = a dot at the cell's bottom-left (a dot grid); ink = a 7 × 7 block with a one-pixel gap
right and below. Column 7 carries the heavier line (bit 0 on every pixel row). The square under the cursor
(Grid Cursor, or the square under the Arrow) is marked by shape and colour: a hollow box on paper, a block
with a window on ink, on cyan paper (TT-1; `mark_ok` / `mark_have`).

### M2 Desk (D-018)

| Rows / columns | Contents |
| --- | --- |
| row 0 | "SPRITE STUDIO", "MOWER 16X16" |
| cols 0-17, rows 1-18 | the white, numbered sheet with the Grid (cols 1-16, rows 2-17) |
| cols 18-21, rows 1-17 | "HEX", then each row's two bytes in hex beside its Grid row; the cursor's row cyan |
| cols 23-31, rows 1-6 | "TRUE SIZE"; EDIT card cols 23-26, PLAY card cols 28-31 (labels inside, sprites at rows 3-4) |
| cols 23-31, rows 7-11 | readouts: input; square and INK/PAPER; FRAME n/N; play time and ON/OFF; CHECKS n/OK |
| cols 23-31, row 12 | the drawer switch: "FRAMES W" / "DRAWING W" (yellow on blue) |
| cols 23-31, rows 13-21 | the open drawer: nine controls, one a row, label and key |
| cols 0-22, rows 19-21 | frame strip (slot i at col 3i), ↑↑ under the current frame |
| row 22 | key legend; row 23 the status line: INKED nnn and the last event (or the line tip) |

Drawers: FRAMES = PREV Z, NEXT X, COPY C, DELETE V, CLEAR R, PLAY/STOP G, SLOWER J, FASTER K, BACK T;
DRAWING = UNDO/REDO U, ONION N (green while on), MIRROR I, NUDGE < 5, v 6, ^ 7, > 8, CHECK Y, BACK T.

### M3 Desk: every box size (D-033)

The M2 layout stays, with these changes:

| Rows / columns | Contents |
| --- | --- |
| row 0, cols 18-31 | the header panel: the figure's name and box, "MOWER 32X32" |
| row 1 | the sheet's numbers across (a panel); "HEX", "EDIT" (col 23), "PLAY" (col 28) |
| col 0, rows 2-17 | the sheet's numbers down (a panel) |
| cols 1-16, rows 2-17 | the Grid. Boxes up to 16 × 16: one square a cell (8 dots). Bigger: 2 × 2 squares a cell (4 dots each, a 3 × 3 glyph and a gap). Cells outside the box are black |
| cols 18-21, rows 2-17 | HEX: the cursor's band of 16 rows and 2 bytes (rows 0-15 or 16-31, bytes 0-1 or 2-3) |
| cols 23-26 / 28-31, rows 2-5 | EDIT and PLAY cards: the figure at true size, centred, up to 32 × 32 |
| cols 23-31, row 6 | readout: KEYS or MOUSE |
| cols 23-31, rows 7-11 | readouts: AT col,row (two hex digits for squares of 4 dots); INK or PAPER; FRAME; PLAY; CHECKS |
| rows 19-20 | strip slots: true size up to 16 × 16, half size for bigger boxes (each 2 × 2 dots one dot) |

A third drawer, FIGURE: LIBRARY L, BIGGER B, SMALLER S, ALL E (mirror and nudge every frame; green while on),
BACK T. BIGGER and SMALLER step the box through T-BOX-SIZES (8 × 8 ... 32 × 32). W cycles FRAMES, DRAWING,
FIGURE.

### The Library page (D-034)

A page of the Desk (state 1, phase 2): row 0 "THE LIBRARY", "FIGURES BY GAME"; cols 1-16, rows 2-21 the list
(games, characters one in, figures two in with their box; the chosen line cyan); cols 22-25, rows 3-6 the chosen
figure flipping through its frames at true size; cols 18-31, rows 9-12 its game, character, name, box and
frames; rows 22-23 the keys. Q/A choose, O/P the first figure of the game before or after, SPACE or ENTER (or
a second click) opens, T or L goes back. The list and the figure's details are panels drawn with the Desk's
panel code, their want/have in the Grid's tables (free while the page shows).

Squares of 4 dots: ink is a 3 × 3 block, paper a corner dot, tracing paper a middle dot, a check mark a ring
(ink) or a small cross (paper). The cursor's cell is cyan and its square turns over (inverse) every 0.32 s,
like the Spectrum's own flashing cursor. Squares of 8 dots keep M2's glyphs, but a check mark is now a tick
cut out of ink or drawn on paper, so a marked square still reads as ink or paper (m2-r2 F-3).

### M4: masks and the Test Ground (D-044)

A fourth drawer, MASK: PICTURE/MASK D (the layer; green on the mask), the style RING/SHAPE/BOX/HAND F, GROUND
H, BACK T. On the mask layer kind bit 1 is the mask's cover: 8-dot glyphs paper, hollow (ink not covered),
light hatch (cover), ink; 4-dot tables g4ml/g4mr likewise. The readout says COVER or KEEP; HEX shows the
mask's codes. The Test Ground is a page of the Desk (phase 3): COPY, MIX and MASK+MIX panels of 6 x 6 cells at
columns 2, 12 and 22, rows 4-9, the figure centred on whole bytes; the ground's name top right; H, G, T.

## 2. Memory and bank map

| Range / bank | Contents |
| --- | --- |
| `$6000` `code_start` - `$7FFF` | read-only text and labels; the sheet (head, frames 0-7, their masks as frames 8-15); the Grid's want/have (page-aligned); rev, popcount and half tables; mask, check and preview workspaces; the text panels' want/have; BASIC `CLEAR 24575` (M4, D-044) |
| bank 1, 4, 3 | the Library (bank 4 also holds the packed Start picture after it); Undo's two copies of the current figure and Export's text (bank 3) |
| bank 6 at `$C000` | the Test Ground's and the Sheet page's code and texts (paged in by `bank6_call`, D-051, D-061) |
| bank 0 and 7 at `$C000` | the sheet's eight figures' frames and masks, 2,048 bytes each (`sh_bank`); the other bank takes a load before it replaces the sheet (D-061, D-062) |
| `$8000` - `code_end` | resident code, variables, the sheet (head plus 8 frames × up to 128 bytes), Grid have/want (2 × 512), have-buffers, `pc_table` and `half_tab` (bank 2) |
| ... `stack_top` (`$BDBD`) | stack |
| `$BDBD` / `$BE00` | `JP isr` / IM2 table |

The sheet from M3: `sheet` = `nframes`, `cur_frame`, `box_w`, `box_h`, `bpr` (bytes a row), `fbytes` (bytes a
frame), `fig_name` (8 letters and a 0), then `frames_data`: frames packed at `fbytes` each, rows `bpr` bytes,
MSB left (a `.spr` frame's layout). A 16 × 16 sheet is byte for byte M2's. Undo keeps one copy of the sheet's
used bytes and swaps them (D-005); a stroke keeps only its frame until it ends (D-033).

## 3. Frame budget (per 1-frame update = 70,908 T)

| Subsystem | Budget T | Notes |
| --- | --- | --- |
| ISR: 7 keyboard half-rows, stick or mouse, sound | 4,500 | estimate |
| input, cursor, painting (a line of up to 16 squares) | 4,000 | estimate |
| draw: Arrow erase + draw (XOR) | 3,000 | straight after HALT |
| draw: Grid squares (cap 16 an update, ~250 T each) | 4,000 | diff of `grid_have` against the frame |
| draw: images (preview, flip-book, strip slots; cap 2 an update, compare + 32-byte blit) | 6,000 | only when `img_dirty` |
| draw: readouts (cap 12 characters) and control lights | 5,000 | |
| margin | 10,000 | |
| **total** | 36,500 | `update_budget_t` 45,000; measured by verify |

Entering the Desk draws the whole Grid at once behind black attributes (one long update, about 1-2 frames,
`HARNESS_redraw`); the previews, strip and readouts then fill over the next updates. Drawing order each update:
HALT, erase Arrow, Grid squares, images, marks, text, draw Arrow. Every screen byte is written once with its
final value (flicker 0), the Arrow excepted, which is erased and redrawn before the beam reaches its rows.

## 4. Controls

| Action | Key | Kempston | Mouse |
| --- | --- | --- | --- |
| choose mouse / directional | 1 / 2 | | |
| up / down / left / right | q / a / o / p | stick | movement |
| primary (paint, use control) | SPACE | fire | left |
| secondary (rub out) | ENTER | | right |
| previous / next frame | z / x | | PREV / NEXT controls |
| new / delete / clear frame | c / v / r | | NEW / DEL / CLR |
| undo | u | | UNDO |
| play / stop | g | | PLAY |
| slower / faster | j / k | | SLOW / FAST |
| title | t | | TITLE |
| music on/off | m (Start) | | |

```yaml
keys: {left: o, right: p, up: q, down: a, fire: SPACE, start: '2', music: m, mouse: '1', secondary: ENTER, back: t}
```

Every action acts on a fresh press latched in the ISR; buttons held across a screen change are locked until
released (STATE-03). The mouse and stick are read only while chosen; the stick after a 4-frame presence test.

## 5. Engine choices

| Subsystem | Technique | Source |
| --- | --- | --- |
| frame loop, ISR, input locking, mouse, stick | Kitchen Sink M1 (owner's own code, proven in Fuse with a mouse) | Kitchen Sink `game/src/main.asm` (unpublished) |
| Grid Cursor repeat | press = one square, 15 updates, then every 4 | D-003 |
| painting lines | integer Bresenham in squares between the last and current square | DRAW-01 |
| redraw | diff against have-buffers, capped per update (late, never wrong) | the drawing chapter *Compose*; `patterns/A4/compose-offscreen-then-copy.md` idea |
| Arrow | XOR 8 × 10 arrow | Kitchen Sink |
| sound | template stand-in AY player (Start tune A/B, effects C) | template |

## 6. Game model

`HARNESS_state`: 0 Start (no input chosen this visit), 1 Desk. `HARNESS_phase` the same (0 Start, 1 Desk). No
pause, no cards, no failure.

### Headline features

| Feature | Spec | First met | Recipe |
| --- | --- | --- | --- |
| Draw square by square, mouse or keys | DRAW-01, DEV-02 | Desk, first update | `m1-paint-keys`, `m1-mouse` (fixture) |
| True-size preview | DRAW-03 | Desk | `m1-paint-keys` screenshot |
| Frames and flip-book | ANIM-01/02 | Desk; the Mower's two frames from the Library | `m1-frames`, `m1-play` |
| Row Codes (HEX) | CODE-01 | Desk, beside the Grid (M2) | `m2-codes` |
| The Library: the studio's own figures | LIB-01 | the Desk's key line (L:LIBRARY) and the Start screen (M3) | `m3-library`, `m3-big` |
| Every box size to 32 × 32 | T-BOX-SIZES | FIGURE drawer (M3) | `m3-box`, `m3-small` |
| Masks and the Test Ground | MASK-01, GROUND-01 | MASK drawer (D, F, H) (M4) | `m4-ring`, `m4-hand`, `m4-ground*` |
| Colour Blocks, clash and the walking test | CLASH-01, MOVE-01 | the Test Ground (H, or GROUND in the MASK drawer): the colour strip under the panels, its keys on the page (M5) | `m5-clash`, `m5-keep`, `m5-walk`, `m5-gorilla-walk` |
| The sheet: eight figures, saved and loaded on tape, exported as DEFB, the data size | SHEET-01 | the Sheet page (9, or SHEET in the FIGURE drawer) (M6) | `m6-sheet-full`, `m6-data-size`, `tools/tape_check.py` |
| The Lessons and the flicker demonstration | DEMO-01, FLICK-01 | the Lessons (0, or LESSONS in the FIGURE drawer; named on the Start screen); R on the Test Ground (M7) | `m7-lesson2`, `m7-flicker`, `tools/lessons_check.py`, `tools/flick_check.py` |

### Sound plan

| Sound | Trigger | Channel |
| --- | --- | --- |
| Start tune (template stand-in) | Start screen, music on | A/B |
| blip | input chosen, control used, refused, undo | C |

### Visible signals

| Sound | Visible twin |
| --- | --- |
| input chosen | readout "INPUT ..." and event |
| control used | control lights yellow 0.2 s; event names it |
| refused | control lights red 0.2 s; event "CAN'T: ..." |

## 7. Harness symbols

| Symbol | Points at | Notes |
| --- | --- | --- |
| `HARNESS_updates` | `updates` | |
| `HARNESS_state` / `HARNESS_phase` | `state` / `phase` | 0 Start, 1 Desk |
| `HARNESS_lives` | `lives` | always 1 |
| `HARNESS_score` | `inked` (word) | inked squares in the current frame |
| `HARNESS_level` | `cur_frame` | current frame, 0-based |
| `HARNESS_player_x` / `_y` | `cur_x` / `cur_y` | Arrow hotspot, or the Grid Cursor square's centre |
| `HARNESS_redraw`, `HARNESS_music`, `HARNESS_song` | as named | |

Recipe symbols: `nframes`, `frames_data` (+n), `gc_col`, `gc_row`, `input_dev`, `play_on`, `play_frame`,
`play_lvl`, `last_event`, `undo_ok`, `ms_lastx`, `ms_lasty`.

## 8. Asset integration

| Module | zx-assets entries | Format |
| --- | --- | --- |
| loading screen | `screens loading` (missing; template placeholder) | `.scr` |
| Start picture | `screens start-title` (missing; code heading) | `.scr` region |
| Starting Sprite | the mower's two east frames from Mower Mayhem's `assets/sprites/mower.asm` (owner's game) | bytes |
| music, effects | `music start-tune`, `sfx` (missing) | aypat |

## 9. Exemplars

- Kitchen Sink M1 (the owner's unpublished test program): the same input stack; compare Arrow feel.
- Period paint and sprite designers driven by a port mouse or keys (`patterns/A22/mouse-pointer-input.md`,
  `patterns/A13/pointer-and-icon-interfaces.md`): compare placement precision and redraw flicker.
