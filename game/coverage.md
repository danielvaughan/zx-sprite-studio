# Requirement coverage

Every requirement in `requirements.md` and the evidence that shows it on the latest tap (M7). Recipes are in
`recipes/` (run by `verify_game.py`, flicker and screen checked by `tools/flicker_recipes.py` and
`tools/screen_check.py` on every recipe); the tools are in `tools/` (outputs in `verify/*-m7.txt`); trials are in
`playtest/`. "Fixture" means a recipe that sets the pointer's place with a poke (the harness has no Kempston
mouse): it shows the behaviour, not that a hand reaches it.

| Req | What | Evidence |
| --- | --- | --- |
| R-001 | Start screen: title, choose your input, music on, a blank figure | `m1-start`; verify `house_*`, `no_crash` |
| R-002 | Choose the pointer or keys, on Start and on the Desk | `m1-start`, `m1-mouse` (fixture), `m1-paint-keys`; `signals_check` (input chosen) |
| R-003 | The mouse's Arrow at the Grid centre, no jump; keys' Grid Cursor | `m1-mouse` (fixture), `m1-paint-keys`; `kempston_check` |
| R-004 | Keys: one square a press, repeat, diagonals | `m1-repeat`, verify `input_latency` |
| R-005 | Mouse: gain, clamp, the square under the Arrow | `m1-mouse`, `m1-mouse-controls` (fixtures); the owner's Fuse session (TT-8) for a real mouse |
| R-006 | Every action has a control and a key; refusals | `m1-mouse-controls` (fixture), `m2-drawer`, `m6-sheet-click` (fixture); `signals_check` (refused) |
| R-007 | Painting: ink or clear by the first square, unbroken lines | `m1-paint-keys`, `m1-ux-keep` |
| R-008 | One-level Undo, Redo, refused with nothing to undo | `m1-undo`, `m1-ux-undo`, `m6-sheet-switch`; `signals_check` (undo, redo) |
| R-009 | True-size preview | `m1-paint-keys` shots; `screen_check` (cards) |
| R-010 | Frames: previous, next, new, delete, clear, refusals | `m1-frames` |
| R-011 | Flip-book, faster, slower | `m1-play`, `m4-ground-play`, `m7-lesson2` |
| R-012 | Title keeps the sheet; held keys do nothing until let go | `m1-title` |
| R-013 | Music on and off on the Start screen, none on the Desk | `m1-music`, `m1-nomusic`; verify `toggle_latency` |
| R-014 | Music changes nothing else | verify `music_parity` |
| R-015 | Readouts | `screen_check` (every panel against its want) on every recipe |
| R-016 | Tracing paper (onion skin) | `m2-onion`, `m7-lesson2` |
| R-017 | Mirror and nudge, one frame or all | `m2-mirror-nudge`, `m3-all`, `m5-nudge-mask` |
| R-018 | Row Codes, the cursor's row marked | `m2-codes`; `lessons_check` (lesson 1) |
| R-019 | Checks: stray dot, too alike, outside the mask, hard to see; CHECK marks and points | `m2-checks`, `m4-hand`, `m5-hand32`, `m5-outside32`, `m5-hard`, `m5-hard-mark`; trial m6-r1 (F-2, F-3, F-39 by name) |
| R-020 | Masks: Ring, Shape, Box, Hand; the Mask layer | `m4-ring`, `m4-hand`, `m4-mask-ms`; `mask_check` (Ring, Shape, Box on 106 figures); `m5-lib-mask`, `library_check` (games' masks as Hand) |
| R-021 | The Test Ground: Copy, Mix, Mask then Mix over four Grounds | `m4-ground`, `m4-ground-stay`, `m5-ground32`; `screen_check` (every panel byte) |
| R-022 | Colour Blocks: Keep, Ink, Box; cells now and most; clashes | `m5-clash` (AC-24), `m5-keep` (AC-25), `m6-box-colour`; `screen_check` (every strip byte and colour) |
| R-023 | The walking test: steps, facing, moves too far | `m5-walk` (AC-26), `m5-walk32`, `m5-gorilla-walk`, `m5-walk-g`, `m5-ground-play-h`; `walk_check` (every walking frame) |
| R-024 | The sheet: 8 figures, save and load on tape, export, data size | `m6-sheet-full`, `m6-sheet-switch`, `m6-data-size` (AC-28); `tape_check` (AC-27), `export_check`, `libtape_check`. `.spr` export not done (D-063); F-64 with the owner (D-069) |
| R-025 | The Lessons | `m7-lesson2` (AC-31); `lessons_check` (six lessons, 36 ordered pairs, the reader's figure kept) |
| R-026 | RUB OUT, DRAW beside DRAW ONCE | `m7-flicker`; `flick_check` (AC-32) |
| R-027 | Every signal in section 9 with its visible twin and its sound | `signals_check` (each event's id at `sfx_start` and channel C's volume rising: input chosen, control, refused, undo, redo, sheet saved; painting silent; the save and load messages are seen on screen in trials m6-r1 to m6-r3 and the M7 gate's own run, not checked by a tool); D-070 (the effects were silent from M4 to M7). Nobody has listened: the owner's Fuse session |
| R-028 | Content and tone | every trial's tone pass (latest `playtest/m7-r2.md`); the Library's sources and what was left out and why (D-034, `src/gen/library.json` `left_out`) |
| R-029 | Accessibility: shape as well as colour; nothing fast | grey checks in `playtest/m4-r2.md` (marks), `playtest/m5-r1.md` (clash FLASH in black and white), `playtest/m5-r5.md` (F-29 in grey); the mark glyphs in `src/main.asm` (`g4l`, `g_tick`, `g_hollow`, `g_cover`); D-052 |
| R-030 | Nothing seen half-drawn; the Arrow leaves no marks | `flicker_recipes` (0 transient bytes on every recipe), `screen_check` |
| R-031 | The Library of the studio's own figures | `m3-library`, `m3-big`, `library_check`, `libtape_check` |
| R-032 | Every box size on every tool | `m3-box`, `m3-small`, `m3-big`, `m5-ground32`, `m5-walk32` |

Not verified by the agents: feel at full speed, a real Kempston mouse, a real tape, sound by ear, real hardware
(the owner's Fuse session: `build/sheet-check.tap`, the Library's tapes).
