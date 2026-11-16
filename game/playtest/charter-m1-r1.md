# Playtest charter: Sprite Studio M1, round 1

- Tap: `build/sprite-studio-m1.tap`, sha256 `1705dbc8f5ad88a994b13f49ea48372982c080fd4e41f8d009c4f3c54d807300`
- URL: given by the controller (playtest_server.py, `machine=128`)
- Report: `playtest/m1-r1.md` (from the zx-game-playtest `report-template.md`); screenshots: `playtest/media/`
- Speed: 25% real time (`zx.speed(25)`), with `pause()` + `step(n)` for precise moments
- Controls (design.md §4): `1` mouse, `2` keys/joystick; `q a o p` move the Grid Cursor one square
  (held: repeats); `SPACE` paint (ink on paper, rub out on ink; hold and move to draw a line); `ENTER`
  rub out; `z`/`x` previous/next frame; `c` new frame (copy); `v` delete frame; `r` clear frame;
  `u` undo (again: redo); `g` play/stop the flip-book; `j`/`k` slower/faster; `t` back to Start;
  `m` music (Start). The emulator has no mouse: choosing `1` gives an idle Arrow (expected, D-006).

This is a drawing tool, not a game: no score, lives or failure (spec §1). `HARNESS_state` 0 Start,
1 Desk. `HARNESS_score` = inked squares in the current frame; `HARNESS_level` = current frame (0-based).

## Goals for this milestone

1. Load: loading screen, Start with "CHOOSE YOUR INPUT", music playing, `MUSIC ON (M)` (R-001); `m` toggles (R-013).
2. `2`: the Desk shows the mower's frame 1 on the Grid, the true-size preview and flip-book cards, two frames in the strip, the Grid Cursor (cyan) on the centre square (R-002, R-003).
3. Move with `q a o p`: one square per tap; held, repeats after a pause; stops at every edge (R-004).
4. Paint: tap `SPACE` on paper (inks) and on ink (rubs out); hold `SPACE` and move to draw a line; `ENTER` rubs out. The preview changes at once (R-007, R-009).
5. `u` undoes the last stroke, `u` again redoes (R-008).
6. Frames: `x`, `z`, `c` (copy after), `v`, `r`; refusals show red and "CAN'T: ..." (R-010, R-006).
7. `g`: the flip-book rolls the mower; `j`/`k` change speed; drawing still works while playing (R-011).
8. `t` returns to Start; `2` again: the Desk as left (R-012).

## Cold-start pass (headline features)

| Feature | Expected (design.md) | First met: `zx.status().frame` | Screenshot |
| --- | --- | --- | --- |
| Draw square by square | Desk, first update | | |
| True-size preview | Desk | | |
| Frames and flip-book | Desk: the mower's two frames | | |
| Masks, clash, Row Codes, lessons | later milestones: not expected yet | | |

## Tone pass

TONE-01 no real person, brand, product, company or existing game; TONE-02 short, plain, friendly.

- [ ] every proper noun on screen is invented
- [ ] no line mocks anyone; refusals say what, not blame
- [ ] the mower reads as a mower from above at 1x
- [ ] text plain and friendly

## Readability at 1x

- Is the Grid Cursor (cyan square) findable on ink and on paper squares? Cite screenshots.
- Do the readouts and control labels read as a desk? Is the flip-book visibly animating?
- Placeholder art: the Start heading and loading screen are placeholders (D-007); note, do not raise.

## Edge cases

- Hold `SPACE` through `t` and `2`: nothing is painted until released (STATE-03; `recipes/m1-title.json`).
- Delete down to one frame; New up to eight; Undo after Delete.
- Play with one frame; play while painting.

## Bot evidence

`verify/m1.md`: all checks PASS (flicker 0 transient bytes, input_latency 30/30 on `steer_n`,
music_parity 0 differences, kempston_absent, house checks); recipes m1-start, m1-repeat,
m1-paint-keys, m1-undo, m1-frames, m1-play, m1-title, m1-mouse (fixture), m1-music, m1-nomusic.

## Not verified by the agent

Feel at full speed; the real mouse (no emulation, D-006: owner tests in Fuse); real hardware.
