# Milestones

Every milestone ships `build/sprite-studio-m<N>.tap` and passes `verify_game.py`. Follows the spec's slices.

## M1: draw and flip

Requirements: R-001 to R-015, R-027 (input, control, refused, undo), R-028, R-029, R-030.

Tap must show: loading screen, Start with music and its legend, the input choice, the Desk with the mower's two
frames, painting by keys (and mouse on real hardware), true-size preview, frame strip, flip-book, undo, Title.
No failure or success beat: a refusal shows "CAN'T", a success changes the sheet.

Acceptance (recipes in `recipes/`):

- `m1-start`: nothing pressed for 300 frames: state 0; then `2`: state 1, `nframes` 2, Grid Cursor at (8, 8) (AC-01, AC-02).
- `m1-repeat`: right held 50 frames from column 0: `gc_col` 10 (AC-04); up+left at the corner: stays (AC-05).
- `m1-paint-keys`: SPACE held while moving right five squares on a paper row: six squares inked (AC-09); a tap toggles (AC-08).
- `m1-undo`: paint, `u`: as before; `u` again: restored (AC-11).
- `m1-frames`: `c` on frame 2: three frames, frame 3 = frame 2 (AC-12); `v` on one frame and `c` at 8 refused (AC-13).
- `m1-play`: `g`: `play_frame` alternates every 4 updates (AC-14); `j`/`k` at the ends refused.
- `m1-title`: `t` then `2` with SPACE held: Desk on the same frame, nothing painted (AC-29).
- `m1-mouse` (fixture): choose `1`, poke the counters: the Arrow moves, away = up (AC-06).
- `m1-music` / `m1-nomusic`: music parity; music off kept (AC-30).
- `m1-ux-undo`: a rub-out on paper is not an undo step: `u` takes back the last real change (tool trial TT-2).
- `m1-ux-keep`: the Grid Cursor stays where it was left across Title (STATE-02, TT-5).
- `m1-mouse-controls` (fixture): the Arrow clicks COPY, a strip frame, and draws an unbroken 7-square diagonal in one update (AC-07, AC-10).

Assets:

- asset ready: screens loading (local P-H3 master, drawn on the cell grid; assets/decisions.md A-001..A-003)
- asset ready: screens start-title (the same picture, packed; M2 tap onwards)

## M2: tracing paper and numbers

Requirements: R-016, R-017, R-018, R-019 (stray dot, frames too alike); tool trial carry-overs TT-8 (mouse reach), TT-14, TT-15 (undo/redo label), TT-16 (line hint), TT-17 (refusal phase).

Tap must show: the HEX column beside the Grid, onion skin, mirror and nudge, checks with marked squares, two
drawers of controls, the status line. Built under D-017 (M1's gate waits for art).

Acceptance (recipes; every M1 recipe still runs):

- `m2-onion`: N on frame 2: square (2,1), ink in frame 1 and paper in frame 2, carries the onion ring; painted, it is ink with no ring (AC-16).
- `m2-mirror-nudge`: a dot at (0,0); 5 nudges it to column 15, I mirrors it back, 7 and 6 move it up (wrapping to row 15) and down, 8 right (AC-17).
- `m2-codes`: row 1 reads 2800; inking (15,1) makes it 2801, on screen (AC-18).
- `m2-checks`: a lone dot is a stray dot; Y shows it marked; a copy is too alike until one square more is painted (AC-19, AC-20).
- `m2-drawer`: W switches drawers; N works whichever is open.
- `m1-mouse-controls` (fixture): moved to the M2 layout (COPY in the frame drawer, strip from column 0).

## M3: the Library and every box size (spec v0.2, owner)

Requirements: R-031 (Library), R-032 (box sizes up to 32 × 32), R-001/R-003 revised (blank start, the Library
named); carry-overs from M2 (m2-r2 F-2: mirror and nudge on all frames; F-3: check marks keep ink or paper
readable; m2-r3 F-2: the TOO ALIKE count when rubbing out; m2-r3 F-3: the Start picture) and TT-8 (D-029).

Plan (in order, each step verified):

1. The box becomes a variable with 16 × 16 its only value: every square index, frame size, row word and readout
   generalised; every M1 and M2 recipe passes unchanged (behind a "open the Library's mower" preamble once the
   Desk opens blank).
2. A second size (32 × 32): squares drawn 4 pixels wide (two by two in a character cell), the Grid's footprint
   unchanged; HEX shows the cursor's 16-row band; the cards and strip draw any box up to 32 × 32.
3. Memory: the read-only data (Start picture, text, the Library) moves out of the resident block (the template's
   `$6000` layout or a paged bank, checked against run_bot's watched-symbol rule).
4. The Library: generated at build time from the games' `.spr` files with zx-sprite-data's own parser, from the
   published games, tone- and licence-checked (spec notes D31), at most 8 frames per figure.
5. De-mowering: the Desk header names the open figure; the Start line names the Library; the loading and Start
   picture shows several of the studio's figures.

Acceptance so far (every M1 and M2 recipe still runs; `m2-drawer` steps three drawers):

- `m3-box`: BIGGER seven times grows the Mower's box to 32 × 32, drawing kept top left; once more is refused
  ("CAN'T: BIGGEST BOX"); a stroke paints in 4-dot squares; SMALLER gives 32 × 24; Undo gives 32 × 32 back.
- `m3-small`: SMALLER three times gives 8 × 8; once more is refused; the cursor stays inside the box; the
  FIGURE drawer opens with W.
- `m3-library`: L opens the Library on the Mower; P jumps to Tiger Gorilla, A eleven times reaches the
  gorilla's run (32 × 32, 4 frames); SPACE opens it (header TIGER GORILLA, GORILLA 32X32; "OPENED: GORILLA"); a stroke
  paints on it; U takes the stroke back (AC-33).
- Every M1 and M2 recipe opens the Mower from the Library first (L, ENTER), the Desk now opening blank (D-035).

## M4: masks and three ways

Carried from M3's trials: m3-r2 F-5 (HEX band labels for boxes over 16), F-15 / m3-r5 F-23 (4-dot cursor and
Grid speed with the pointer), m3-r5 F-24 (the Library's key line with the pointer: CLICK, ENTER:OPEN).

Requirements: R-020, R-021, R-019 (ink outside the mask).

## M5: colour and walking

First, the M4 gate's issues (D-049): m4-r2 F-36 (masks worked out during the opening redraw), F-35 (the readout
follows a finished mask), F-29 (ink outside the mask on 4-dot squares, S2), F-39, AC-22 on 32 × 32, F-37, F-38;
the settle bound including mask work; evidence for the M2/M3 carry-overs; nudge and the mask; Box and Hand in
mask_check; pointer clicks on the MASK controls; the headline table and the cold Desk's signposts. Then the
Library's figures bring their games' own masks (Hand) where the `.spr` has them.

Requirements: R-022, R-023, R-019 (hard to see).

Acceptance (spec v0.2 CLASH-01, MOVE-01, CHECK-01; T-CELL 8, T-STEPS 1, 2, 4, 8, T-STEP-MAX 4, T-HARD-PAIRS):

- AC-24: Ink mode over grass, the figure a dot off the cell grid both ways: the readout shows 9 cells and the
  clashing cells are marked (recipe `m5-clash`; screen_check compares every strip byte and colour, the flash
  included).
- AC-25: Keep mode: 0 clashes, the figure in each cell's own ink (recipe `m5-keep`, screen_check).
- AC-26: Walk on with step 8 lists "Moves too far"; with step 2 it is gone; the figure turns to face left at the
  right edge and walks back (recipes `m5-walk`, `m5-walk32`, `m5-gorilla-walk`; `tools/walk_check.py` compares
  the strip with the drawn picture on walking frames, facing left off the byte grid included).
- Hard to see (R-019): `m5-hard` (CHECK names it), `m5-hard-mark` (the cells marked).
- F-29 / CHECK-01 on 32 × 32 (D-049's condition): `m5-outside32` (CHECK takes the Grid Cursor to the marked
  square, `check_bits` asserted at it), playtest m5-r5.
- The page's controls by key and by pointer: `m5-click-walk`, `m5-click-colour` (fixtures), `m5-walk-g`,
  `m5-ground-play-h`, `m5-walk-back`.
- Library masks and ink (D-053, D-054): `m5-lib-mask`, `tools/library_check.py`; mask_check Ring, Shape, Box.
- Flicker 0 and every screen settled on every recipe (`verify/flicker-recipes-m5.txt`,
  `verify/screen-check-m5.txt`).

## M6: the sheet

First, the M5 gate's issues (D-060): F-53 (CHECK waiting with no sign: a CHECKING... status), F-54 (the Desk's
HARD TO SEE to name the ink and the Ground), F-29's pointer side (CHECK with the pointer points at nothing),
F-45 (a second T after the Test Ground), F-38 (D:LAYER on the picture line), PRESS 1 OR 2 twice on the return
Start screen, the Desk coming back on the Mask layer; `m5-outside32`'s second shot to frame 800; evidence for
Box mode's colours and for more of the 77 game masks; the old M2/M3 carry-overs (m2-r3 F-2, m2-r2 F-3, m3-r2
F-15, m3-r5 F-24) and F-39, by name, or close them with a reason. Owner answers pending: F-41, F-44 (game masks).

Requirements: R-024 (tape save/load, export).

Acceptance (spec v0.2 SHEET-01; T-FIGURES 8):

- The sheet: Choose figure and new figure on the Sheet page, the refusal at 8 (`m6-sheet-full`), switching
  (`m6-sheet-switch`: Undo starts afresh with each figure, D-061), the pointer on the page (`m6-sheet-click`,
  fixture).
- AC-27: two figures saved, the application restarted, the sheet loaded: both figures, frames and masks as saved,
  drawing goes on (`tools/tape_check.py`; also Undo of a load, a broken-off load, a file that is not a sheet, the
  ROM's own save and a SPACE break; `build/sheet-check.tap` for Fuse).
- AC-28: the data size 2 x 1 x 8 x 16 x 3 for a 16 x 16 figure of two frames, one facing, 8 positions
  (`m6-data-size`, `tools/export_check.py`).
- Export: DEFB text that assembles to the figure's pictures and masks (`tools/export_check.py`, Mower and a
  32 x 32 figure).
- The Library's tapes load as sheets (`tools/libtape_check.py`, D-064).
- M5's carried items: `m6-box-colour` (Box mode's colours, screen_check), `tools/library_check.py` (10 figures,
  both banks), CHECKING... (F-53), INK HARD TO SEE, KEY H (F-54), D:MASK on the key lines (F-38), the Start text,
  and the old M2/M3 findings re-checked by name in the trial.
- Flicker 0 and every screen settled on every recipe.

Owner question (2026-11-11, during M4): can the example figures load separately? Plan: the Library leaves the
program's own tape: each game's figures become a file loaded like a saved sheet (the Mower stays built in as the
chapter's worked example), freeing bank 1 and letting new games' figures be added without rebuilding the Studio.

Owner question (2026-11-11): can saving to disk be emulated with Fuse and tested? Plan: tape save/load is the
main route (every 128K). Tests: recipes in zx-game's Sim trap the ROM's tape save routine to capture the saved
block, then feed it back through the load routine and compare the sheet byte for byte (Fuse has no scripting, so
it cannot run unattended). Disk: +3DOS on the +3 (`fuse --machine plus3` with a `.dsk` image), tested the same way
around the +3DOS calls, plus a by-hand Fuse session for the owner.

## M7: the chapter's lessons, and finish

First, the M6 gate's issues (D-069): F-64 (the data size counts the facings and positions chosen, export writes
the frames as drawn: owner), F-73 (say "start the recorder" again), F-72 (the check count after Undo), F-68
(a message half replaced), F-48 and F-52 (colours a frame after dots), F-45 (a second T after the Test Ground),
PRESS 1 OR 2 twice on the return Start screen, the Desk coming back on the Mask layer (keep or close by name),
F-29's pointer side; evidence for more of the Library's tapes and game masks; owner answers (F-41, F-44, F-71,
D-064's built-in Library, F-24 in the Fuse session).

Requirements: R-025, R-026, R-027 (all), coverage of every requirement. Media kit and Joo's video advert (D-002): the media kit is skipped (D-031); Joo's tutorial video is made separately (owner request).

Acceptance (spec v0.2 DEMO-01, FLICK-01, section 9; the whole spec's coverage in `coverage.md`):

- AC-31: lesson 2 sets up the Mower, tracing paper on, the flip-book playing, the caption naming it, painting goes
  on (`m7-lesson2`); every lesson from cold, all 36 ordered pairs, the reader's figure kept (`tools/lessons_check.py`).
- AC-32: RUB OUT, DRAW seen with the figure gone, DRAW ONCE never (`m7-flicker`, `tools/flick_check.py`).
- R-027: every signal's visible twin and sound (`tools/signals_check.py`, D-070).
- M6's carried items by name: F-73 (record), the Start text (1 OR 2 once), F-45, the Mask-layer return, F-72,
  F-68, F-48 and F-52 (dispositions in the M7 trial), the owner's answers where given.
- Flicker 0 and every screen settled on every recipe; `coverage.md` names evidence for every requirement.

Owner request (2026-11-12): when the work is complete, Joo prepares a **short tutorial video** of the Studio:
drawing a figure, the flip-book, the mask and the Test Ground in colour, the sheet and export, recorded from the
finished tap with her narration from `docs/studio-guide.md` (alongside the advert).

Assets: the start tune and the signal sounds are the Studio's own, written in code since M1 (no zx-assets music
or effects, so verify's `audio` check stays skipped); their evidence is `tools/signals_check.py` (D-070).
