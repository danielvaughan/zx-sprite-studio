# Sprite Studio: requirements (intake from specs/sprite-studio-spec.md v0.1, revised for v0.2)

Milestones follow spec v0.2's slices (D-026): M3 the Library and box sizes, M4 masks, M5 colour, M6 the sheet,
M7 the lessons.

Each requirement is one testable statement and cites the spec section(s) it came from. `M` is the milestone
that delivers it (see `milestones.md`). Never renumber: a dropped requirement keeps its ID and is marked
`deferred: <reason>`. The spec calls a sprite a *Figure*; this game folder says sprite.

| ID | Requirement | Spec | M |
| --- | --- | --- | --- |
| R-001 | Start screen with no input chosen: title, "Choose your input" with both choices, no cursor, music on; the sheet holds a blank figure and the Desk names the Library (spec v0.2; M1-M2 opened on the mower) | STATE-01, §5, AC-01 | M1 |
| R-002 | Choose pointing device / choose directional each by its own action, on the Start screen (opens the Desk) and on the Desk (switches at once); no device read until chosen | DEV-01, AC-02 | M1 |
| R-003 | Choosing the mouse puts the Arrow at the Grid centre with the device's current state as baseline (no jump); choosing directional puts the Grid Cursor on the square under the Arrow, else the centre square | DEV-01, AC-03 | M1 |
| R-004 | Directional: Grid Cursor moves one square per press, repeats after `T-REPEAT-DELAY` then every `T-REPEAT-TIME`; diagonals; opposite directions cancel; stops at the Grid edges | DEV-02, AC-04, AC-05 | M1 |
| R-005 | Mouse: Arrow moves by hand movement × `T-GAIN`, sub-step movement kept, away = up, reaches every point, clamped; the Grid square under it is marked | PTR-01, AC-06 | M1 |
| R-006 | Every Desk action has an on-screen control (primary press uses it once) and a direct key; a refused action shows the refusal signal and changes nothing; a used control lights `T-LIGHT-TIME` | DEV-03, AC-07 | M1 |
| R-007 | Painting: the stroke's mode is set by the square pressed (paper → ink, ink → clear); held, every square passed is set, with unbroken lines between refreshes; secondary strokes clear; nothing painted off the Grid or across a gap | DRAW-01, AC-08, AC-09, AC-10 | M1 |
| R-008 | One-level undo of the last change (stroke, New, Delete, Clear, ...); undo again redoes; refused with nothing to undo | DRAW-02, AC-11 | M1 |
| R-009 | True-size preview of the current frame, changed within one refresh | DRAW-03, AC-08 | M1 |
| R-010 | Frames 1..`T-FRAMES`: Previous/Next (refused at ends), New (copy after, refused at max), Delete (refused at one), Clear; "frame n of N"; frame strip with the current marked; a press on a strip frame selects it | ANIM-01, AC-12, AC-13 | M1 |
| R-011 | Flip-book: Play/Stop; loops the frames at the play time; faster/slower through `T-PLAY-TIMES` (refused at ends); drawing continues while playing | ANIM-02, AC-14, AC-15 | M1 |
| R-012 | Title returns to Start keeping the sheet and Desk settings; buttons and directions held across a change do nothing until released | STATE-02, STATE-03, AC-29 | M1 |
| R-013 | Music on/off on the Start screen, shown, kept for the session; no music on the Desk; `HARNESS_music` | PRES-01, PRES-02, AC-30 + standard | M1 |
| R-014 | Music changes nothing else (`music_parity`) | standard | M1 |
| R-015 | Readouts: input, square under the cursor, frame n of N, inked squares, play time, last event | §5 Desk | M1 |
| R-016 | Onion skin | ANIM-03, AC-16 | M2 |
| R-017 | Mirror and Nudge (wrapping) | TOOL-01, AC-17 | M2 |
| R-018 | Row Codes panel, cursor row highlighted | CODE-01, AC-18 | M2 |
| R-019 | Checks: stray dot, frames too alike (M2), ink outside the mask (M4), hard to see (M5); choosing one marks its squares | CHECK-01, AC-19, AC-20, AC-22 | M2 (D-021), M4 |
| R-020 | Masks: Ring, Shape, Box, Hand; Mask layer; masks follow the picture until edited | MASK-01, AC-21, AC-22 | M4 |
| R-021 | Test Ground: Copy, Mix, Mask then mix over four Grounds | GROUND-01, AC-23 | M4 |
| R-022 | Colour Blocks: Keep, Ink, Box modes; cells touched now and at worst; clashes marked and counted | CLASH-01, AC-24, AC-25 | M5 |
| R-023 | Walking test: steps 1, 2, 4, 8; facing; "Moves too far" | MOVE-01, AC-26 | M5 |
| R-024 | Sheet: up to 8 sprites, names, box sizes, save/load to tape, export as `defb` / `.spr`, data size | SHEET-01, AC-27, AC-28 | M6 |
| R-025 | Lessons list: the drawing chapter's lessons set up on the Desk with a caption | DEMO-01, AC-31 | M7 |
| R-026 | Flicker demonstration: "RUB OUT, DRAW" beside "DRAW ONCE" in the walking test | FLICK-01, AC-32 | M7 |
| R-027 | Every signal in spec §9 with its visible twin and its sound | §9 | M1 (input, control, refused, undo), later rest |
| R-028 | Content and tone: no real person, brand, product, company or existing game; text short and friendly; any breach is a severity-1 finding | TONE-01, TONE-02 + standard | every milestone |
| R-029 | Accessibility: marks differ by shape as well as colour; nothing needs fast reactions | §9 | every milestone (M1: cursor shape and flashing refusal, tool trial TT-1, TT-6) |
| R-031 | The Library: the studio's own figures from its games, by game, name and box; opening one copies it into the sheet as one Undo step; none from a real person, none over 32 × 32 or 8 frames | LIB-01, AC-33, AC-34 (spec v0.2) | M3 |
| R-032 | Every box in `T-BOX-SIZES` (8 × 8 to 32 × 32) works on the Grid, the cards, the strip, HEX and every tool | T-BOX-SIZES, SHEET-01 (box size) | M3 |
| R-030 | Nothing on the Desk is ever seen half-drawn (flicker 0); the Arrow never leaves marks | §11 | every milestone |

## Sections with no requirement

- §1, §2: intent, carried by the requirements above.
- §7: none by design (a tool; `HARNESS_score` mirrors the inked-square count of the current frame).
- §8: no randomness.
- §12, §13: cited through the requirements.
- §14 H-01..H-05: human goals, judged in playtests.

## Coverage (filled in at the final milestone)

| ID | Status | Evidence |
| --- | --- | --- |
