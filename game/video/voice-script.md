# Joo's voice script

Hyun-joo Lee (Joo), the studio's sprite artist, presents the tutorial. Each line was made in her voice (actor
HYUNJOO, Dalex Studio's local voice), then transcribed back with Whisper and compared word by word.
A line with a dropped or misheard word was retaken, or reworded and retaken, until every word came back; the table
shows the wording kept.

Lines 01, 02 and 27 are spoken on camera. Their audio is `talk/open.wav` and `talk/close.wav`, the exact takes the
talking shots were lip-synced to (heard back: `talk/*.heard.txt`). The `vo/` takes of those three lines were made
again later and are not used.

Lesson 1 explains the binary step by step, after a viewer's comment (12 November 2026) that "row one is two
bytes, two eight, then nought nought" told a normal person nothing. The other lessons were filled out in the same
way. While she does the arithmetic, the border shows it written down (`make_tutorial.py`, the notes in `PLAN`).

Whisper's spellings are not errors in the take: it writes numbers as digits, "Joo" as "Ju", "byte" as "bite",
"nought" as "not", and "Dalex" (said "Dallex") as "Daleks" whatever the voice says. The owner listened and
confirmed "Dalex" is right (12 November 2026).

| # | Line | Seconds | Heard (Whisper) |
| --- | --- | --- | --- |
| 01-hello | Hello, I'm Joo, the sprite artist at Dallex. This is Sprite Studio. | 4.96 | (on camera: see `talk/open.heard.txt`) |
| 02-paper | It's my squared paper, on the one two eight K Spectrum. | 3.24 | (on camera: see `talk/open.heard.txt`) |
| 03-keys | Press two for the keys. Q, A, O and P move the cursor. | 4.44 | Press 2 for the keys. Q, A, O and P move the cursor. |
| 04-paint | Press space to paint a square. Hold it and move to draw a line. | 3.76 | Press space to paint a square, hold it and move to draw a line. |
| 04b-true | The pictures at the top show it at true size, as a player sees it. | 3.84 | The pictures at the top show it at true size as a player sees it. |
| 04c-hex | And the numbers beside each row are that row's two bytes, in hex. | 4.16 | and the numbers beside each row are that row's two bytes in hex. |
| 05-lessons | Press nought for the Lessons, from my drawing chapter. | 3.12 | Press 0 for the lessons from my drawing chapter. |
| 06-l1 | Lesson one. A figure is just rows of dots. | 3.56 | Lesson 1. A figure is just rows of dots. |
| 07a-bits | Every square is one bit: inked is a one, empty is a zero. | 4.44 | Every square is one bit. Inked is a 1, empty is a 0. |
| 07b-bytes | Eight squares make a byte, so a row of sixteen is two bytes. | 3.84 | Eight squares make a byte, so a row of sixteen is two bytes. |
| 07c-worth | Read a byte from the left. Its squares are worth one hundred and twenty-eight, | 5.08 | Read a byte from the left. Its squares are worth 128. |
| 07d-worth2 | then sixty-four, thirty-two, sixteen, eight, four, two and one. | 4.92 | then 64 32 16 8 4 2 and 1 |
| 07e-row1 | On row one of the Mower, squares two and four are inked. | 3.56 | On row one of the mower, squares two and four are inked. |
| 07f-add | They're worth thirty-two and eight. Add them up, and you get forty. | 4.56 | They're worth 32 and 8. Add them up and you get 40. |
| 07g-hex | In hex, forty is two sixteens and eight, so it's written two eight. | 5.2 | in hex. Forty is two sixteens and eight, so it's written two eight. |
| 07h-right | The right half of the row is empty, so that byte is zero zero. | 3.76 | The right half of the row is empty, so that byte is zero, zero. |
| 07i-f | Now I'll ink the very last square, worth one. Watch the right byte. | 5.64 | Now I'll ink the very last square, worth one. Watch the right bite. |
| 07j-01 | It reads zero one. You can read any sprite this way, a row at a time. | 4.6 | It reads 01. You can read any sprite this way, a row at a time. |
| 08-l2 | Lesson two. Tracing paper shows the last frame as little rings. | 4.24 | Lesson 2. Tracing paper shows the last frame as little rings. |
| 08b-anim | A moving figure is just a few pictures, shown one after another. | 3.92 | A moving figure is just a few pictures shown one after another. |
| 08c-rows | The Mower's two frames differ in only four rows, at its corners. | 3.92 | The mower's two frames differ in only four rows, at its corners. |
| 09-l2-play | And the flip book plays both frames, at the speed the game uses. | 3.68 | and the flipbook plays both frames at the speed the game uses. |
| 09b-speed | Each picture stays up for four TV frames: nought point nought eight seconds. | 5.12 | Each picture stays up for 4 TV frames, 0.08 seconds. |
| 10-l4 | Lesson four, the mask. It clears the scenery under the figure. | 4.6 | Lesson 4: The mask. It clears the scenery under the figure. |
| 11-l4-ring | The Ring mask adds one dot all round the ink. F changes it. | 4.0 | The ring mask adds one dot all round the ink. F changes it. |
| 11b-ring | The hatched squares are covered: the ink, the paper inside, and a ring. | 3.92 | The hatched squares are covered, the ink, the paper inside and a ring. |
| 12-l4-box | Shape has no ring. Box covers the whole box. | 3.48 | Shape has no ring. Box covers the whole box. |
| 13-l3 | Lesson three. The Test Ground puts it down three ways. | 4.16 | Lesson three. The test ground puts it down three ways. |
| 14-l3-copy | Copy wipes out the grass in its box. Mix lets the grass show through. | 4.4 | Copy wipes out the grass in its box. Mix lets the grass show through. |
| 14b-mix | That's quick, but in busy grass the figure gets hard to see. | 3.36 | That's quick, but in busy grass the figure gets hard to see. |
| 15-l3-mask | Mask then mix clears the grass under the mask, then adds the ink. | 4.8 | Mask then mix clears the grass under the mask Then adds the ink |
| 15b-clean | The figure stays solid, with the grass right up to its edge. | 3.6 | The figure stays solid, with the grass right up to its edge. |
| 16-l5 | Lesson five. Why does drawing flicker? | 2.84 | Lesson 5. Why does drawing flicker? |
| 17-l5-rub | The top copy rubs the figure out, then draws it again. | 3.0 | The top copy rubs the figure out, then draws it again. |
| 18-l5-blink | Watch it blink. For a moment there's only grass. | 2.96 | Watch it blink. For a moment there's only grass. |
| 19-l5-once | Draw once changes each dot just once, and never shows the gap. | 4.0 | Draw once changes each dot just once and never shows the gap. |
| 19b-rule | So never rub out and redraw. Change each dot straight to its new value. | 4.76 | So never rub out and redraw. Change each dot straight to its new value. |
| 20-l6 | Lesson six. On the Spectrum, colour belongs to the cell. | 3.92 | Lesson 6. On the spectrum, colour belongs to the cell. |
| 21a-blocks | The screen is cut into blocks, eight dots square. | 2.96 | The screen is cut into blocks eight dots square. |
| 21-l6-block | Each block has one ink colour and one paper colour. Clashing blocks flash. | 4.92 | Each block has one ink colour and one paper colour. Clashing blocks flash. |
| 21b-ink | In Ink mode, every block the Mower touches takes its red ink. | 3.76 | In Ink mode, every block the mower touches takes its red ink. |
| 21c-grass | But the grass in those blocks is ink too, so it turns red as well. | 4.24 | but the grass in those blocks is inked too, so it turns red as well. |
| 21d-nine | One dot off the grid, the Mower touches nine blocks instead of four. | 3.32 | One dot off the grid, the mower touches nine blocks instead of four. |
| 22-l6-look | That frame's wrong. Look. The grass round the Mower has turned red. | 4.48 | That frame's wrong. Look, the grass round the mower has turned red. |
| 23-sheet | Press nine for the Sheet. It holds up to eight figures. | 3.64 | Press 9 for the sheet. It holds up to 8 figures. |
| 24-size | The data size counts the Row Codes a game would store. | 3.04 | The data size counts the row codes a game would store. |
| 24b-pos | A game often stores a figure eight times, shifted one dot further each time. | 4.52 | A game often stores a figure eight times, shifted one dot further each time. |
| 24c-spill | Shifting it right spills into the next byte, so each row needs three bytes. | 4.24 | Shifting it right spills into the next byte, so each row needs three bytes. |
| 25-sum8 | Two frames, eight positions, sixteen rows, three bytes: seven hundred and sixty-eight. | 5.76 | two frames, eight positions, 16 rows, three bytes, 768. |
| 25b-one | Stored once, it's two frames, sixteen rows, two bytes: just sixty-four. | 5.04 | Stored once, it's 2 frames, 16 rows, 2 bytes, just 64. |
| 26-tape | S saves the sheet to tape. X exports the figure, ready for a game. | 5.36 | S saves the sheet to tape. X exports the figure, ready for a game. |
| 27-bye | Now draw something, flip it, and show me. I'll find your stray pixel. | 5.12 | (on camera: see `talk/close.heard.txt`) |

Each claim comes from `docs/studio-guide.md`, or is the arithmetic of what is on screen, and is shown while she
says it (`edit.json`, `voice-timeline.json`).
