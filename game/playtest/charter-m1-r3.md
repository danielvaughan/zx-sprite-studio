# Playtest charter: Sprite Studio M1, round 3 (closing sit-beside trial)

- Tap: `build/sprite-studio-m1.tap`, sha256 `19d29dcbf51f4ebd410f61a5faf457fa3bd077028628bf8eb0b62994e07146e3`
- Report: `playtest/m1-r3.md` (playtest report template) **and** the trial sections of `ux/m1-trial-r1.md`
  (the controller merges them); screenshots `playtest/media/m1-r3-*`
- Method: Yvonne Standish's sit-beside trial (skill `zx-game-ux` §4). You are **the newcomer at a show**:
  no manual, sound off, keys only. You get **only the job cards below**: no key list. Everything you need must
  come from the screen. **Think aloud**: before each press, write one line of what you expect and why; quote
  those lines in the report. Note every hesitation (a moment you did not know what to press) and every slip
  (a press you had to undo or that did something unexpected).
- Speed: 25% or frame-step, stated in the report. Agent-operated; feel at full speed not verified.
- Words: write the report in 1987 terms (the operator, a slip, a job, ergonomics); no modern jargon.

## Job cards

| Job | Goal (the newcomer's words) | Done when |
| --- | --- | --- |
| J1 | Start drawing: put one square of ink on the picture | a square you chose is black |
| J2 | Make the picture move: copy the first picture, change one square in the copy, and watch it play | the PLAY card animates two pictures that differ |
| J3 | Draw a straight line six squares long along the bottom row | six squares in a row inked |
| J4 | Take back a mistake you just made | the picture is as it was |
| J5 | Go back to the first screen, then come back and carry on where you were | same picture, same square |
| J6 | Throw away pictures until only one is left, then change your mind and get the last one back | one picture, then two again |
| J7 | Say which squares of the second row of the first picture are inked, counting from 0 | the answer, with how you found it |
| J8 | Make the moving picture slower, then faster | the PLAY card speed changes both ways |

For each job record: finished?, time (frames), presses, slips, hesitations, and your think-aloud lines.

## The ten-question card

After all jobs, score the ten statements in `ux` template (zx-game-ux `references/report-template.md`) 1-5
as the newcomer, compute the score, and say which statements pulled it down.

## Also

- The Grid Cursor: can you always see where you are, on ink and on paper? Cite screenshots.
- Refusals: when something cannot be done, do you understand why from the screen?
- Tone pass as round 1 (no real names; friendly words).
- Held-key repeat: hold one direction for a second; say whether the repeat pause and speed feel right.
- Refusal in black and white: make a refusal (e.g. DEL with one frame) and save two screenshots 8 frames apart
  while the control is marked (`m1-r3-refuse-a`, `m1-r3-refuse-b`), so the controller can check the flash in
  greyscale.
- This round's score is compared with round 2's (77.5, one agent tester, frame by frame): use the same job
  cards and the same ten statements.
