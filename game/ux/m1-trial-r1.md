# Tool trial: Sprite Studio M1, round 1

- Tap sha256: `19d29dcbf51f4ebd410f61a5faf457fa3bd077028628bf8eb0b62994e07146e3` (after all fixes); sit-beside on `8a5673c6c4c18905472063e219b62c51054c3ab7a7f0425987a2a4c9a26c8872`; counts "before"
  are on `1705dbc8f5ad88a994b13f49ea48372982c080fd4e41f8d009c4f3c54d807300`
- Trial by: Yvonne Standish's method (`zx-game-ux`, zx-game 0.24.0); counts and inspection by the controlling
  agent from recipes and screenshots; the sit-beside trial operated by the playtester agent (`playtest/m1-r2.md`)
- Not verified by the agent: feel at full speed; the Kempston mouse (owner, in Fuse); real hardware

> "Six things a newcomer would trip over. Five of them were in the playtest already; the sixth only shows on
> a black-and-white set. All six are fixed and written down." (Yvonne)

## Who sat at the desk

See [regulars.md](regulars.md): the sprite artist, a reader of the book, the newcomer at a show.

## Job cards and keystroke counts

**Estimated** with the keystroke model (Card, Moran and Newell): K 0.28 s, M 1.35 s; D(n) a held direction
over n squares = 0.3 + (n − 1) × 0.08 s. Presses are the regular's shortest path, checked against the recipes
named; the newcomer's measured presses are in the sit-beside table below and differ where the newcomer took
another path (J2: 3 measured against 6 estimated, because the copy was changed in place with ENTER; J3: 13
measured against 6, because the newcomer walked to the bottom row first). The "after" column is an estimate
until the closing round measures it.

| Job | Spec IDs | Operators | Presses before → after | Time before → after (s) | Recipe |
| --- | --- | --- | --- | --- | --- |
| J1 first square (from Start, keys) | DEV-01, DRAW-01 | M K(2) M K(SPACE) | 2 → 2 | 3.3 → 3.3 | `m1-start`, `m1-paint-keys` |
| J2 second frame, change one square, watch it | ANIM-01/02 | M K(C) M K K K M K(SPACE) M K(G) | 6 → 6 | 7.1 → 7.1 | `m1-frames`, `m1-play` |
| J3 a line of six squares | DRAW-01 | M K(SPACE held) K×5 | 6 → 6 | 3.0 → 3.0 | `m1-paint-keys` |
| J4 undo a slip | DRAW-02 | M K(U) | 1 → 1, **but impossible after a rub-out on paper** (F-2) | 1.6 → 1.6 | `m1-undo`, `m1-ux-undo` |
| J5 leave and carry on where you were | STATE-02 | M K(T) M K(2) + back to the square: M D(8) | 3 → **2** | 5.1 → **3.3** | `m1-title`, `m1-ux-keep` |
| J6 delete to one frame, undo the last delete | ANIM-01, DRAW-02 | (M K(V)) + M K(U) | 2 → 2 | 3.3 → 3.3 | `m1-frames` |
| J7 read row 1 | DRAW-01 | M + move along the row reading SQUARE | 17 → 17 | about 6 | — (Row Codes in M2 make this 0 presses) |
| J8 slower, then faster | ANIM-02 | M K(J) M K(K) | 2 → 2 | 3.3 → 3.3 | `m1-play` |

J5 before: the Grid Cursor came back on the centre square, so the operator had to find their place again
(8 squares on average: a held key, 0.86 s, plus a think). J4 before: a rub-out on paper silently took the only
undo step, so the real slip could not be taken back at any cost. J7 stays expensive until the Row Codes panel
(M2) shows the row's bytes at a glance.

## The ten-point inspection

| Point | Screen | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1 Every press answers | Desk | pass | pass | the EVENT readout and the control light answer every press |
| 2 The user's language | Desk | pass | pass | INK, RUB OUT, FRAME, FLIP: the artist's words |
| 3 A way out of everything | Desk, Start | pass | pass | BACK T on the Desk; 1 / 2 on Start |
| 4 Same key, same job | all | pass | pass | |
| 5 Stop the slip before it happens | Desk | pass | pass | impossible actions refused, nothing changed |
| 6 Nothing to remember | Desk | **fail**: on an ink square the cursor showed only a 1-pixel cyan line (F-1) | pass | marked glyphs: a box on paper, a window in ink |
| 7 Short cuts for the regular | Desk | pass | pass | a key on every control; the strip clickable |
| 8 Only what is needed | Desk | **fail**: "TRUE SIZE / EDIT FLIP-BOOK" made two labels read as three (F-4) | pass | "TRUE SIZE" over "FRAME" and "PLAY" |
| 9 Say what went wrong | Desk | pass | pass | "CAN'T: ONLY 1" |
| 10 Help where it is needed | Desk | pass | pass | key legend rows 22-23; keys on the controls |

## The walk-through (the newcomer)

| Job | Step | Try it? | See it? | Connect it? | See it worked? |
| --- | --- | --- | --- | --- | --- |
| J1 | press 2 | yes | yes ("PRESS 1 OR 2") | yes | yes: the Desk |
| J1 | press SPACE | yes | yes (legend "SPACE:PAINT") | yes | yes: square and both cards |
| J2 | copy the frame | **maybe**: "copy" is not a word on screen; NEW C makes a copy | yes | **no** before reading the guide | yes: "NEW FRAME", strip shows 2 → 3 |
| J2 | watch it | yes | yes (PLAY G) | yes | yes: the PLAY card moves |
| J4 | undo | yes | yes (UNDO U) | yes | before: **no** after a no-op rub-out (F-2); after: yes |
| J5 | carry on | yes | yes (BACK T, then 2) | yes | before: **no**, cursor moved (F-5); after: yes |

Carried forward: "NEW C" does not say it copies (TT-7, severity 3): the readout could say "NEW FRAME (A COPY)".
The words of the control are fixed by its 6-cell width; to M2 with the control layout.

## Black-and-white portable

`media/m1-bw-paint-ink.png`, `media/m1-bw-refuse-del.png` (before), `media/m1-r2-desk-colour-and-bw.png` (after).

| Mark | Before | After |
| --- | --- | --- |
| Grid Cursor on paper | pale grey square, faint | hollow box: reads |
| Grid Cursor on ink | invisible (1-pixel line) | window in the block: reads |
| Refused control (red) | the same dark grey as the blue controls: **reads by colour alone** (TT-6) | FLASHes (ink and paper swap) for 0.64 s: to be seen in the closing round's greyscale shot |
| Used control (yellow) | light grey: reads | unchanged |

## Reach (pointer targets)

Controls are 6 × 1 cells (48 × 8 pixels), stacked with no gap: small for a mouse, and a press on the row edge
can hit the neighbour. Not measurable without a mouse (D-006); for the owner's Fuse session and the M2 layout
(TT-8, severity 3).

## Sit-beside trial

Operated by the playtester agent as the newcomer on tap `8a5673c6`, keys only, job cards only, frame-stepped
(`../playtest/m1-r2.md`). Every job finished; no slips.

| Job | Finished? | Frames | Presses | Slips | Hesitation |
| --- | --- | --- | --- | --- | --- |
| J1 first square | yes | 41 | 2 | 0 | none |
| J2 copy, change, play | yes | 39 | 3 | 0 | "no COPY on the key card; guessed NEW" |
| J3 six-square line | yes | 77 | 13 | 0 | none |
| J4 undo a slip | yes | 11 | 1 | 0 | none |
| J5 leave and carry on | yes | 46 | 2 | 0 | the Start screen gave no sign the work was kept |
| J6 delete to one, undo | yes | 52 | 4 | 0 | none (the refusal "CAN'T: ONLY 1" understood) |
| J7 read row 1 | yes | 125 | 24 | 0 | could not count the row by eye: no numbers on the paper |
| J8 slower, faster | yes | ~30 | 3 | 0 | none |

**The ten-question card: 77.5 / 100**, one agent tester, operated frame by frame: a marker to compare the
next round against, not a rating. Pulled down by statements 2, 4, 8 and 9: the copy
step and the return to Start meant guessing, and the cursor moves one square a press.

After the round-2 fixes (tap `19d29dcb`): J2 needs no guess ("COPY C", "FRAME COPIED"); J7 should be read off the edge
numbers with no presses instead of 24 (to be measured in the closing round); J5's Start screen says "YOUR PICTURES ARE KEPT: PRESS 1 OR 2 TO CARRY ON".

### Closing round (tap `19d29dcb`, `../playtest/m1-r3.md`)

A fresh agent tester, the same job cards, frame by frame. All eight jobs finished; 35 presses, 1 slip (a second
U gave REDO), 2 hesitations. **The ten-question card: 80 / 100** (round 2: 77.5), again one agent tester: a
marker, not a rating.

| Job | Round 2 presses / hesitations | Round 3 presses / hesitations | Changed by |
| --- | --- | --- | --- |
| J2 copy, change, play | 3 / 1 ("no COPY") | 3 / 0 | TT-9 |
| J5 leave and carry on | 2 / 1 (no sign work kept) | 2 / 0 | TT-12, TT-5 |
| J7 read row 1 | 24 / 1 (no numbers) | 7 / 1 (the readout does not say ink or paper) | TT-10: measured 7, not the 0 estimated |
| J3 six-square line | 13 / 0 | 13 / 1 ("how to draw a line") | not changed: TT-16 |

The flash (TT-6), seen in grey: the swapped phase reads clearly; the red phase is only a little lighter than the
blue controls (119 against 81 of 255), so the refusal reads by its flash and its "CAN'T" message, not by its
first phase (TT-17).

## Findings

| ID | Severity | Source | Finding | Route | Disposition |
| --- | --- | --- | --- | --- | --- |
| TT-1 | 2 | both (F-1, inspection 6) | cursor invisible on ink | design (glyph) | fixed, tap `8a5673c6` |
| TT-2 | 2 | agent (F-2) | a no-op rub-out took the undo step | fix (DRAW-02 says "the last change") | fixed; `recipes/m1-ux-undo.json` |
| TT-3 | 3 | agent (F-3) | edge squares merge with the black surround | design (white margin) | fixed |
| TT-4 | 3 | both (F-4, inspection 8) | card labels unclear | design | fixed |
| TT-5 | 3 | agent (F-5) | cursor re-centred after Title | fix (STATE-02) | fixed; `recipes/m1-ux-keep.json`; D-013 |
| TT-6 | 2 | inspection (portable test) | a refusal read by colour alone | design (FLASH), spec §9 already says "flashes once" | fixed; D-015 |
| TT-7 | 3 | walk-through | "NEW" does not say it copies | design | defer to M2 (control layout) |
| TT-7 | — | — | (superseded by TT-9) | — | — |
| TT-8 | 3 | inspection (reach) | controls small and touching for a mouse | design | defer to M2; owner's Fuse session |
| TT-9 | 2 | agent (sit-beside F-1) + walk-through | copying is not shown anywhere | design (label, readout) | fixed: "COPY C", "FRAME COPIED"; tap `19d29dcb` |
| TT-10 | 2 | agent (sit-beside F-3) | no row or column numbers; a row cannot be counted by eye | design | fixed: 0-F along the top and left margins; SQUARE readout in the same hex digits |
| TT-11 | 3 | agent (sit-beside F-4) | Start legend repeats "PRESS 1 OR 2"; crowded foot | design | fixed: one legend line, "M: MUSIC ON OR OFF"; the house foot rows stay |
| TT-12 | 3 | agent (sit-beside F-2) | Start does not say the work is kept | design | fixed: "YOUR PICTURES ARE KEPT: PRESS 1 OR 2 TO CARRY ON." |
| TT-13 | 3 | agent (sit-beside F-5) | the example mower is not called an example | design | fixed: first visit says "THE DESK OPENS ON AN EXAMPLE, THE MOWER. CLR R CLEARS IT." |
| TT-15 | 3 | agent (r3 F-1) | U toggles undo and redo but the control says only UNDO | design | defer to M2 |
| TT-16 | 3 | agent (r3 F-2) | nothing says holding SPACE while moving draws a line | design (legend) | defer to M2 |
| TT-17 | 3 | agent (r3 F-3) | the refusal's first (red) phase is close to the blue controls in grey | design (start on the swapped phase) | defer to M2 |
| TT-14 | 3 | agent (sit-beside F-6) | ink or paper under the cursor shown only by the size of the cyan window | design | keep (the trial found the cursor always easy to find); revisit with Row Codes in M2 |
