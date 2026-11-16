# Sprite Studio: how it was built

A running record of how the Studio was made: where each idea came from, what was decided and why, how the code
works, and what was checked. It is the source for anyone (Joo on air, a book section, a new programmer) who has
to explain the build. Add an entry at the end of every milestone round; never rewrite history, add to it.

## The brief (2026-11-11)

The owner asked for "a sprite studio that supports the work that Joo describes in the podcast and book": drawing
with keyboard or mouse, animation and preview, and the colour clash and other problems documented in the sprite
skills and pattern cards; spec and start building in a new private repository with no further questions. Later
the same day: the Studio must **demonstrate what the book and podcast discuss**; **Joo presents a video advert**
when it is ready, alongside the media kit; and **good records** must be kept so Joo can explain it.

It came straight after *Kitchen Sink* M1, which proved the Kempston mouse and the cursor on a 128K in Fuse.
The Studio reuses that input code.

## Sources

| Source | What it gave the Studio |
| --- | --- |
| The drawing chapter of the owner's unpublished Spectrum games book | squared paper and the heavier middle line; a row as two bytes; the Mower's two rolling frames (only rows 1, 2, 13, 14 change); each picture up two updates; masks and the ring; the three ways onto grass; colour belongs to the cell; write every byte once with its final value |
| Joo's episode of the owner's podcast (episode 6) | Joo's way of explaining: start from what the eye sees, work one row by hand, check at 1×; "green, hedgehog, green, hedgehog" for flicker |
| `zx-assets` skills: `zx-sprite-explain`, `zx-sprite-data`, `zx-sprite-assets` finishing rules | the technique catalogue; keep / ink / box colour modes; the memory budget formula; no stray pixels (rule 5); at most about 4 px a frame (rule 12); frames change at least 10% (rule 18) |
| Pattern cards A4, A5, A20 (the owner's private research notes on period games) | masks, mirroring, shifting, clash strategies, frames per action |
| *Mower Mayhem* `assets/sprites/mower.asm` | the Starting Sprite's bytes (the owner's own game) |
| *Kitchen Sink*, the owner's earlier unpublished test program | IM2 loop, key latching, button locking across screens, Kempston mouse and stick |

## The spec

`specs/sprite-studio-spec.md` (v0.1, draft) is machine-agnostic, as every Dalex spec is: it says what the user
experiences, never pixels, bytes or keys. So it calls a sprite a **Figure**, a byte a **Row Code**, an attribute
cell a **Colour Block**, and the Spectrum's screen rules the **Picture Format**, written down as the tool's
content. The spec checker passes with no errors or warnings. Every choice made without the owner is marked
`[Designer's call]` and listed in `specs/sprite-studio-spec-notes.md` (D1-D21) for review.

Slices: 1 draw and flip; 2 tracing paper, Row Codes and checks; 3 masks and three ways; 4 colour and walking;
5 the sheet; 6 the chapter's lessons and the flicker demonstration.

## M1: draw and flip

### How the screen is drawn

The Studio follows the rule it teaches: **every screen byte is written once an update, with its final value**.
A drawing tool redraws a lot, so this mattered from the first line of code.

- **Have-buffers.** The program keeps a copy of what is on the screen: which Grid squares are inked
  (`grid_have`, 32 bytes), each small picture (`img_have`: the true-size preview, the flip-book and the eight
  strip slots), every readout character (`panel_have`) and every control colour (`btn_have`). Each update it
  compares the sheet with those copies and redraws only what differs.
- **Capped work.** At most 16 Grid squares, two small pictures and 12 readout characters an update. A big change
  (Clear, a new frame) finishes over a few updates: *late, never wrong*, the chapter's phrase. Verify measured 0
  transient bytes; the late bytes are whole changes one frame late.
- **The arrow** is XOR-drawn: erased straight after the HALT, everything else drawn, then the arrow redrawn,
  before the beam reaches it.
- **A whole new screen** (Start to Desk) is drawn behind black attributes, then the colours go on in one pass:
  the "hide it behind black" trick from *Whole screens and cards*.

### How drawing works

- A Grid square is one character cell. Ink is a 7 × 7 block with a one-pixel gap; paper is a single dot, so the
  empty Grid reads as a dot grid. Column 7 carries the heavier line.
- The sheet is stored exactly as a game stores a sprite: 16 rows × 2 bytes, leftmost pixel in bit 7. The
  Mower's bytes went in unchanged from *Mower Mayhem*.
- **Strokes**: the square you press decides the stroke (paper → ink, ink → rub out); while held, the program
  joins the last square to the current one with Bresenham's line, so a fast mouse leaves no gaps.
- **Undo** keeps one copy of the whole sheet (258 bytes) and swaps it, so Undo again is Redo.
- **Keys** are latched in the interrupt, so a quick tap is never missed; a key held when the screen changes is
  ignored until released (from *Kitchen Sink*).
- **The Grid Cursor** moves one square a press, then repeats after 0.3 s every 0.08 s.

### What was checked (M1, round 1)

`game/verify/m1.md`, tap `1705dbc8…`: cold load from tape through the ROM, flicker 0 transient bytes, update
cost p90 43,050 T (61% of a frame), input latency 30/30, music on and off identical, no Kempston fitted changes
nothing, Dalex house style; ten recipes: start, key repeat, painting a line, undo/redo, frames up to 8 and down
to 1 with refusals, flip-book and speed limits, Title and back with a held button, mouse movement (by poking
the mouse counters: no emulator the agents use has a mouse), music on/off.

Playtest round 1: see `game/playtest/m1-r1.md`.

### Problems met on the way

| Problem | Fix |
| --- | --- |
| `lx`, `ly` as label names: the assembler reads them as halves of IX | renamed `ln_x`, `ln_y` |
| A recipe with overlapping key ranges (SPACE held, P tapped) pressed only one | write the chords out: `310-311:SPACE+p` |
| Verify's latency probe taps right: the Grid Cursor stops at column 15 after 7 taps | count every step press in `steer_n` and watch that (the *Wordris* approach) |
| "FLIP-BOOK" ran off column 31 and wrapped a K onto the next row | labels moved and shortened ("EDIT", "BACK T") |
| The tape name must be whole words of the title | `S.STUDIO` |

### Not checked by the agents

The real mouse (owner, in Fuse), feel at full speed, real hardware.

## M1, round 2: the first tool trial

The owner asked for the Studio to be made easier and more pleasant to use, by a new skill given to a cast
member, in the words of 1987. **Yvonne Standish**, the toolsmith and researcher, got it: she builds the
studio's own tools and writes down what she finds, and Sprite Studio is a studio tool. The skill is
`zx-game-ux` ("tool trials") in zx-game 0.24.0, released in zx-plugins v0.15.0. A tool trial has these
parts: who sits at the desk (the regulars), job cards (the jobs they came to do), keystroke counts (the
presses and seconds each job costs, after Card, Moran and Newell's 1983 timings), the ten-point inspection
(a checklist for every screen), the walk-through (each step of a job, as a newcomer), the sit-beside trial
(a tester thinks aloud, unhelped) with the ten-question card (a score out of 100), the black-and-white
portable test (nothing may depend on colour alone), two tapes (try two versions) and the fault log (what the
recipes count).

What the trial found and changed (`game/ux/m1-trial-r1.md`):

| Finding | Change |
| --- | --- |
| On an ink square the cursor was a 1-pixel cyan line | marked glyphs: a hollow box on paper, a block with a window on ink |
| Rubbing out paper took the only undo step | a stroke becomes the undo step only if it changed the sheet (the sheet is copied when the stroke starts and compared when it ends) |
| Edge squares merged into the black surround | the Grid sits on a white sheet (a one-cell margin) |
| "TRUE SIZE / EDIT FLIP-BOOK" read as three labels | "TRUE SIZE" over "FRAME" and "PLAY" |
| After Title the cursor jumped to the centre | the Grid Cursor is a Desk setting and is kept |
| On a black-and-white set a refusal (red) looked like any control (blue) | a refused control flashes, ink and paper swapping |

A bug found on the way: the "no square marked" value `$FF` was also square (15, 15), so that corner always drew
as marked; the mark now has its own on/off flag. Keystroke counts before and after are in the trial report:
leaving and carrying on went from 3 presses and 5.1 s to 2 presses and 3.3 s; undo after a no-op rub-out went
from impossible to one press.

Then the sit-beside trial: the playtester agent, as the newcomer with only the job cards, finished all eight
jobs with no slips and marked the Studio **77.5 out of 100** on the ten-question card (one tester, operated frame by frame: a
marker for the next round, not a rating). It
hesitated three times, and each became a change: the copy control now says COPY and the readout "FRAME
COPIED"; the squared paper is numbered 0-F along the top and side (hex, because that is how the bytes split),
so reading a row went from 24 presses to none; and the Start screen says the Desk opens on an example, or that
your pictures are kept. Tap `19d29dcb`, verify pass. A closing trial with a fresh tester on that tape finished
every job, marked it 80, and found three small things for M2: the undo key also redoes but doesn't say so,
nothing says that holding SPACE while moving draws a line, and the refusal's first flash is close in grey to the
other controls. Reading a row went from 24 presses to 7 (the edge numbers), not to none as estimated. M1 is
frozen at this tape: the next step is its gate, once the Start picture and loading screen exist.

## M2: tracing paper and numbers

The owner said "start M2 when ready"; the art for M1's gate still waits for the picture generator's key, so M2
was built on the frozen M1 tape (decision D-017).

**The Desk was rearranged.** M2 brings eighteen actions; at one six-cell control each they no longer fit. So the
controls went into **two drawers**, one open at a time (frame controls, drawing controls), a choice from
Yvonne's catalogue ("one drawer at a time"), which also leaves room for the mask, colour and sheet drawers to
come. Every action still has its own key. The freed space beside the Grid went to the **HEX column**: each
row's two bytes, level with the row, as the chapter's figure prints the Mower's bytes beside its rows.

**What M2 adds:** the HEX column (the cursor's row lit); tracing paper (onion skin: the previous frame's ink as
small rings); mirror; nudge with wrap-around on the Spectrum's own arrow keys, 5 to 8; and checks for stray
dots and frames too alike, stepped through with Y, with the problem squares marked. The last tool trial's
small findings were done too: the undo control says REDO when the next press redoes; the status line's idle
tip says "HOLD SPACE, MOVE: LINE"; a refusal shows red on white, then white on red, so it reads in grey; the
readout says INK or PAPER under the cursor.

**How the Grid is drawn now.** Each square has a *kind*: ink, an onion ring, a check mark, the cursor, in any
mix. The program keeps what kind each square shows (`grid_have`) and what it should show (`grid_want`),
recomputes only the rows that changed (eight at most an update), and draws at most sixteen squares an update,
building each square's eight bytes from small patterns. The same idea runs the text: four panels (readouts,
drawer, HEX column, status line) are recomposed only when something they show has changed.

**A cost problem, measured and fixed.** The first M2 tape took about 81,000 T-states an update, longer than a
frame (70,908): everything was recomputed every update. Three changes brought it to a typical 7,500 and a
90th-percentile 37,382, lighter than M1: work only when its inputs change; a 256-byte table to count the dots
in a byte; and a tighter loop comparing text. The checks recount once the stroke ends, not while drawing.

**Checked:** verify passes on tap `3e60b69a` (0 flicker), with every M1 recipe and five new ones; the pointer
fixture now clicks the drawer.

**The sit-beside trial** (a reader of the book, keys only) finished all eight jobs but marked the Studio 72.5,
lower than M1's 80: the new things were harder to find by their names. So the words changed: tracing paper
instead of onion skin, "PLAY 0.08" instead of a bare "0.08S OFF", SPACE:INK/RUB because SPACE rubs out ink,
"TOO ALIKE 2,3: 03 MORE" so you know how far to go, "CAN'T: FIRST FRAME" instead of "CAN'T: FIRST", and each
HEX pair in two colours so `28` `00` read as the book's two bytes. Tap `39bb8828`, verify pass.

## The pictures: a local model, then the cell grid

There was no key for the usual picture generator, so the owner said to use the local model and to check with the
Dalex Studio project (the owner's private studio tools). Dalex Studio runs image models on the studio's own machine; its still-picture model,
P-H3-Image (MiniMax H3 licence), drew the master from a brief and two references: the studio's photograph of an
unbranded portable television, and the Mower's first frame on squared paper, made from its bytes. The master
had the right idea: squared paper with the Mower in black squares, a pencil, a portable TV showing the Mower.

Converted straight to a Spectrum screen it fell apart: the photographic TV broke up across the colour cells and
the paper's lines vanished. So the screen was drawn again in code, on the 8 x 8 cell grid, after the master's
layout: the Mower on the paper drawn large from its real bytes, the TV in black and white trim showing the Mower
at true size, the title in doubled Spectrum letters. Every cell keeps its two colours (conversion error 0), and
the Dalex lockup sits in its corner. The same picture is the Start screen, packed to 2,426 bytes because a whole
screen would not fit below the stack. Provenance: `assets/decisions.md`.

## M3: every box size (and, next, the Library)

The owner looked at M2 and said the studio was too focused on the Mower: it should work with any figure Dalex
has drawn. The studio's games use boxes from 8 × 8 to 32 × 32, so the spec (v0.2) added a Library of those
figures and every box size, and M3 became that milestone. Masks, colour, the sheet and the lessons each moved
one milestone later.

**Step 1: the box became a number.** Until then everything assumed 16 × 16: 2 bytes a row, 32 a frame. Now the
sheet carries its box (width, height, bytes a row, bytes a frame) in front of the frames, and every routine
reads them. Frames are packed one after another, rows left dot first, the same layout as the games' own `.spr`
files, so a 16 × 16 sheet is byte for byte M2's and every earlier test passed unchanged. The checks were
rewritten for any width, and spread over several updates so a big box never costs more in one go. The "too
alike" count now gives the least that can clear it ("CHANGE 10+"): the M2 trial had found it over-stated when
the reader rubbed squares out.

**Step 2: big boxes on the same Grid.** A 32 × 32 figure cannot have 8-dot squares in a 16-character Grid, so
from 16 × 24 up each character holds four 4-dot squares. Each square is a 3 × 3 block or a dot; the cursor's
square flashes in its cyan character, like the Spectrum's own cursor. The HEX column shows the 16 rows and 2
bytes around the cursor; the cards show any box at true size; the strip shows big boxes at half size. A third
drawer, FIGURE, steps the box BIGGER (B) and SMALLER (S); one Undo takes it back.

**Problems met.** The first big-box tape ran over a frame an update. Three faults were behind most of it: a
comparison that let a flag through and redrew whole rows of the Grid instead of the squares that changed; card
rows copied to the wrong place (into the program's own variables) because an address was overwritten before
use; and after a change of box, squares whose old and new codes happened to match were never redrawn at the
new scale. With those fixed, and the work spread (one picture redrawn in full an update, text composed once
and drawn out), a typical update takes about 5,000 T-states and nine in ten under 33,000.

**Steps 3 to 5: the Library.** A small program reads every published game's `.spr` files with the same parser
the games were built with, and turns each animation (or a file's other drawings, grouped by size) into a Library
figure in the smallest box that holds it: 103 figures, 16 KB, in one of the 128K machine's extra memory banks.
It writes a manifest naming every source file and its checksum, and everything it left out and why. WOLF's heads
were drawn from real people, and its coaches carry real people's first names, so only WOLF's headless bodies and
props are in. The Library is a page of the Desk: a list by game and character, and the chosen figure flipping
at true size beside it. Opening one copies it onto the sheet as one Undo step. The Desk now opens on a blank
figure, and every earlier test opens the Mower from the Library first (two key presses). The loading and Start
picture was redrawn with Dan and the bird on the paper and the gorilla and the Mower on the television, read
from their own files: the playtester had taken the lone Mower for a beetle.

**Small things carried from M2:** ALL makes mirror and nudge act on every frame; check marks became ticks that
leave ink or paper readable; "too alike" now says the least number of squares to change.

## M4: masks and the Test Ground

Built overnight while the owner was away, from the spec's MASK-01 and GROUND-01.

**Masks.** Every frame now has a mask, kept right after the pictures so the same code moves, copies, mirrors
and undoes both. Ring, Shape and Box masks are worked out by the Studio as you draw: it finds the paper that
cannot be reached from the box's edge (that is the paper the figure encloses) with sweeps up and down the rows,
filling along each row in one step with a carry trick: adding a seed to a run of paper dots ripples a carry
up the run. The work is spread over updates and only ever shows a finished mask. To be sure it is right, a
checking tool loads all 103 Library figures, a spiral, a comb and a closed ring into the emulator, lets the
Studio work their masks out, and compares every dot with the same masks worked out the slow, obvious way in
Python: all match.

**The mask layer.** D shows the mask on the Grid: cover as a light hatch, covered ink as ink, uncovered ink
as a hollow square. Painting there turns the style to Hand; Undo puts back both the dots and the style. A new
check finds ink outside the mask.

**The Test Ground.** H shows the frame three times over grass, stripes or plain paper or ink: copied (the box
wipes the ground), mixed (the ground shows through the body) and masked then mixed (clean, with the ground up to
the ring). A checking tool works out every byte of the three panels in Python and compares them with the
screen.

**Memory.** Masks doubled the sheet, so the sheet, the Grid's tables and the text panels moved below $8000,
Undo's copies into one of the 128K machine's extra banks, and the Start picture into another.

**Carried from M3:** the pointer's key lines, labels for the HEX column on big boxes, a clearer cursor on ink, and
a measure of how long the screen takes to settle after a key (about a second at most).

## M5: colour and walking

**First, the M4 gate's issues.** A figure just opened no longer reads as "all outside its mask" while its
masks are still being worked out: the mask layer shows its ink as covered until the current frame's mask is
ready, and that frame's mask is worked out first. The Test Ground's code moved into another of the 128K
machine's banks to make room; the tape grew past five minutes at the ROM's speed, so it now loads through a
packed loader in about two and a half minutes.

**The colour strip.** Under the three panels, the figure stands or walks over a strip of Colour Blocks. It is
the hardest drawing in the Studio so far: the figure can sit at any dot, so its rows are shifted (and mirrored
when it walks left) before they are drawn; only the columns it left and entered are drawn again, each screen
byte once; and the colours of the blocks it touches are worked out from the mode, its ink and whether the
scenery left uncovered by its mask would be recoloured (a clash, which flashes). A checking tool works out the
whole strip, every byte and every colour, in Python and compares it with the screen.

**A starved strip.** The first walking test showed the figure standing still while the flip-book played: the
three panels redrew on every page and the strip only got a turn when they were idle. The draw phase now takes
turns (text, panels, strip), and the strip's colours go about 40 blocks an update, so a walking figure keeps
up within a step.

**Four sit-beside rounds.** The first reader could not walk the gorilla at all: a picture of a tall figure takes
five updates to prepare and the flip-book turned a page every four, so each page started the picture again and
none was ever finished. Fixed, the second reader still saw it stand still: now each finished picture was thrown
away for the next before its turn to be drawn. The bot's walking test had passed both times, because it only
looked once the walk had stopped. A new check now looks at every frame of a walk: the place the figure was last
drawn must keep moving, and the screen must match that picture exactly. The third round found the strip
keeping the old scenery when the Ground changed mid-walk; the fourth checked the fixes on the tap that passed
the gate.

## M6: the sheet

**Eight figures.** The figure you are working on stays where it always was; the other seven wait in one of the
128K machine's spare banks, 2,048 bytes each (exactly a bank for eight). The Sheet page lists them and swaps them
in and out.

**Tape.** Saving and loading use the Spectrum ROM's own tape routines. Three things needed care: SPACE is BREAK
inside the ROM, which ends in an error routine meant for BASIC, so the Studio points that routine back at
itself; the ROM lets interrupts in just before its BREAK test, so the held SPACE was latched and taken as a
press afterwards (found in the emulator, now forgotten on return); and a load goes into a second bank and is
checked before it replaces anything, so a bad tape leaves the sheet as it was and Undo can swap back. A check
tool saves a sheet, writes the blocks out as a real `.tap`, loads them into a fresh machine and compares every
byte.

**Export** writes the figure as `DEFB` lines; the check tool assembles the text with the same assembler the
Studio is built with and compares the bytes.

**The Library's tapes.** Each game's figures are also written as ordinary sheet files, so loading one needs
nothing new.

## M7: the lessons, and finish

**The sounds were silent.** Writing the check that every signal has a sound found that the Studio's effects
had made no sound since M4: a routine added then to keep the timing steady with the music off had been put just
above the one that talks to the sound chip, and the effects' last write fell into it. Verify's sound checks had
always been skipped (the Studio's tune and effects are its own code, not the asset pipeline's), so nothing had
noticed. Now each signal has its own sound: a click, a low blip for a refusal, a soft click for Undo, a chime.

**RUB OUT, DRAW.** The flicker demonstration draws a second copy of the walk the beginner's way, a frame of
scenery between rubbing out and drawing, from its own copy of each picture so it never slows the real one down.
A check counts the frames on which each copy shows no figure: about one in four for the beginner's copy, none
for the real one.

**The Lessons** set the Studio up for each section of the chapter. The check opens each lesson after each other
lesson (all 36 orders) and asks that the result is the same as opening it first.

## The tutorial video

Joo presents a two-minute tutorial (`game/video/tutorial.mp4`) that follows the Lessons. She opens and closes it on
camera: her own lines lip-synced on her checked still with Dalex Studio's cast-explainer method. Every Studio picture is the gated
M7 tap (d5d36798) running in zx-game's simulator, recorded by zx-media-kit's `record_demo.py` from eight new recipes,
one per shot. The voice is Joo's own, made by Dalex Studio's local voice: 27 lines, each under 15 words, each
transcribed back and compared word for word. Four were retaken for a dropped or misheard word. Every claim she makes
comes from this guide and is on screen while she says it. The recording waited for the M7 gate. The sheet's save,
about 20 seconds on tape, is cut from its first seconds to `SHEET SAVED`. The Start screen's "© 2026" line is
covered while it is on screen, because nothing in the film is dated after 1987. At the owner's request there is no
music: the Start tune is cut. A viewer found the first cut's lesson 1 too quick ("row one is two bytes, two eight,
then nought nought" means nothing to a normal person). So the narration now works through the binary: the squares
are worth 128 down to 1, and 32 + 8 = 40 = hex 28. She inks a square to turn 00 into 01, and the arithmetic is
written in the border as she says it. The other lessons say why, not only what. The film grew to four minutes. `game/video/README.md` says how
to rebuild it.

## Still to come

Joo's video advert (made with the owner's private studio tools,
once a gameplay recording exists). No magazine review: the owner ruled that the Studio is a tool,
not a game (D-031).
