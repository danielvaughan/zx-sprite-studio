# Sprite Studio: the user guide

*Squared paper and a pencil, on the Spectrum.* This guide says what the Studio is for, how to use it, and which
part of the drawing chapter each feature shows. It is written so Hyun-joo Lee (Joo) can explain the Studio to a
reader, a listener or a new artist at the desk. Keep it current: every milestone that changes what the user can
do updates this file.

Current version: **M7** (tap `game/build/sprite-studio-m7.tap`). The tapes of earlier milestones, M1 to M6, are
beside it in `game/build/`.

## What it is for

A sprite is a small picture that moves over a background. On the Spectrum it is only bytes the program copies:
no hardware helps. Joo draws sprites on squared paper, one square per pixel, a heavier line down the middle
because each half of a 16-wide row is one byte. The Studio is that sheet of squared paper, with three things
paper can't do:

1. **It shows the sprite at its true size** the whole time, because a sprite is judged at the size the player
   sees it, not drawn large.
2. **It flips the frames** like a flip-book, at the speed a game would show them.
3. **It will show what goes wrong in a game** (later milestones): the mask, the colour clash, the stray pixel,
   the frames too alike to read as movement.

## Starting

Load the tape (128K). The Start screen asks you to **choose your input**:

- **1: mouse.** A Kempston mouse moves an arrow. Left button paints, right button rubs out. Click the blue
  controls to use them. (In Fuse: `fuse --machine 128 --kempston-mouse sprite-studio-m1.tap`, click the screen
  to grab the mouse.)
- **2: keys or joystick.** Q A O P (or a Kempston stick) move the **Grid Cursor** one square at a time: a cyan
  square drawn as a hollow box on paper, or a block with a window on ink, so it shows on a black-and-white set
  too. Hold a direction and it repeats. SPACE paints, ENTER rubs out. It stays where you left it when you go
  back to the Start screen and return.

You can switch at any time on the Desk by pressing 1 or 2. **M** turns the Start tune on and off.

## The Desk

| Part | Where | What it does |
| --- | --- | --- |
| **The Grid** | left, on a white numbered sheet | the current frame drawn large. A box up to 16 × 16 has one big square a character; a bigger box (up to 32 × 32) has four small squares a character. The heavier lines mark where one byte ends and the next begins; anything outside the box is black |
| **HEX** | beside the Grid | each row's two bytes in hex, level with its row (the left byte white, the right yellow): squared paper to numbers. The cursor's row is lit. For a box wider or taller than 16, it shows the 16 rows and 2 bytes around the cursor |
| **True size: EDIT and PLAY** | top right | the frame you are drawing, pixel for pixel; and the flip-book, all the frames in turn |
| **Header** | top right | the figure's name and its box, for example MOWER 16X16 |
| **Readouts** | right | KEYS or MOUSE; AT the square under the cursor; whether it is INK or PAPER; FRAME n/N; the flip-book speed and ON/OFF; CHECKS (how many problems) |
| **Drawers** | right, blue | three drawers of controls, one open at a time: FRAMES, DRAWING and FIGURE. The yellow top row (or W) opens the next. Every key works whichever drawer is open |
| **Frame strip** | bottom left | every frame (at true size, or half size for a box bigger than 16 × 16); ↑↑ under the current one; click one to choose it |
| **Status line** | bottom row | inked squares, and what just happened; with nothing happening, a tip |

The Desk opens on a blank figure, 16 × 16, one frame. Press **L** for **the Library**: every figure the studio
drew for its own games (Mower Mayhem, Tiger Gorilla, Gold Master, Antigravity, All Disco and WOLF), listed
by game and character, the one you are on flipping at true size beside the list. Q and A choose, O and P jump a
game, SPACE (or ENTER, or a second click) opens a copy on the Desk; T or L goes back without opening. The
Library starts on **the Mower** from *Mower Mayhem*, rolling east in its two frames: the worked example from the
drawing chapter. Opening a figure is one Undo step, and the Library's own copy never changes.

## Drawing

- **Paint:** press SPACE (or the left button) on a square. On paper it inks; on ink it rubs out. Keep it held
  and move: every square you pass gets the same treatment, in an unbroken line, however fast you move.
- **Rub out:** ENTER (or the right button) always rubs out, held or tapped.
- **Undo:** U undoes the last change (a stroke, a new or deleted frame, a clear). U again puts it back.

## Frames and the flip-book

| Key | Control | Does |
| --- | --- | --- |
| Z / X | PREV / NEXT | the previous / next frame |
| C | COPY | a copy of this frame, straight after it, ready to change (up to 8) |
| V | DEL | delete this frame (not the last one left) |
| R | CLR | clear this frame |
| G | PLAY / STOP | start or stop the flip-book |
| J / K | SLOW / FAST | 0.32, 0.24, 0.16, 0.12, 0.08 or 0.04 seconds a picture (starts at 0.08) |
| T | BACK | back to the Start screen; everything is kept |

These are in the **FRAMES** drawer. The **DRAWING** drawer holds:

| Key | Control | Does |
| --- | --- | --- |
| U | UNDO / REDO | take back the last change; the label says REDO when the next press puts it back |
| N | TRACING | tracing paper (an onion skin): squares inked in the previous frame and empty in this one show as small rings (the control turns green while it is on) |
| I | MIRROR | flip the frame left to right |
| 5 6 7 8 | NUDGE < v ^ > | slide the frame one square (the Spectrum's arrow keys); what goes off one edge comes back on the other |
| Y | CHECK | show the next problem: its frame, and its squares marked with a tick (cut out of ink, or drawn on paper, so you can still tell which) |

The **FIGURE** drawer holds:

| Key | Control | Does |
| --- | --- | --- |
| L | LIBRARY | the Library (above) |
| B | BIGGER | the next box size: 8 × 8, 16 × 8, 8 × 16, 16 × 16, 16 × 24, 24 × 16, 24 × 24, 24 × 32, 32 × 16, 32 × 24, 32 × 32. The drawing stays at the top left |
| S | SMALLER | the size before; anything outside the smaller box is dropped (U puts it back) |
| E | ALL | MIRROR and NUDGE act on every frame together (green while on), so a walking figure turns round or moves in one press |

With small squares (a box over 16 × 16) the square under the cursor flashes, like the Spectrum's own cursor, in
its cyan character.

The **MASK** drawer holds:

| Key | Control | Does |
| --- | --- | --- |
| D | PICTURE / MASK | the layer the Grid shows and paints: the picture, or its mask (green while on the mask). On the mask layer, SPACE makes a dot **cover** (the scenery there is cleared) or **keep**; covered paper shows as a light hatch, covered ink as ink, and ink the mask does not cover as a hollow square |
| F | RING / SHAPE / BOX / HAND | the mask style. **Ring**: the ink, the paper it encloses and a ring one dot wide round the ink. **Shape**: the same with no ring. **Box**: the whole box. **Hand**: as you paint it. Ring, Shape and Box follow the picture as you draw; painting on the mask turns the style to Hand |
| H | GROUND | the **Test Ground**: the frame three times over a ground, as a game would put it down: **COPY** (the box wipes the ground), **MIX** (the ground shows through the figure) and **MASK+MIX** (the ground is cleared under the mask, then the ink goes on). H steps through grass, stripes, plain paper and plain ink; G plays the flip-book there; T goes back |

Below the three panels, the Test Ground shows the figure **in colour**, standing or walking across a strip of
scenery made of 8 × 8 **Colour Blocks** (each block has one ink colour and one paper colour, as on the
Spectrum's screen). The keys on that page (or click their words):

| Key | Does |
| --- | --- |
| C | the **colour mode** for every block the figure's box touches: **KEEP** (the blocks keep their colours; the figure's ink shows in each block's ink colour), **INK** (the blocks take the figure's ink colour and keep their paper), **BOX** (the figure's ink on black) |
| I | the figure's **ink colour** (it belongs to the figure: Library figures bring their game's) |
| W | **Walk** on or off: on, the figure steps across and back each time the flip-book turns a page (W starts the flip-book), mirrored going left; off, it stands at the left edge on the block grid, and Q, A, O, P move it a dot. G stops the flip-book and the walk with it |
| S | the **step**: 1, 2, 4 or 8 dots a page |

While a big figure's masks are still being worked out the readout says WORKING OUT THE MASKS... and the
pictures wait for them (a few seconds for a 32 × 32 figure).

The readout counts the blocks the box touches now, the most it can touch anywhere (a 16 × 16 figure touches 4
blocks on the grid, 9 one dot off it), and the **clashes**: blocks whose colour the figure changed that still hold
scenery ink its mask does not cover, so the scenery there turns the figure's colour. Clashing blocks **flash**.
Two checks belong to the whole figure: **HARD TO SEE** (white, yellow or cyan ink on a white, yellow or cyan
ground) and **MOVES TOO FAR** (a step over 4 dots: it jumps rather than walks).

**Checks** look for what Joo would spot from the door: **ink outside the mask** (with a Hand mask, an ink dot the mask does not cover: it would show the scenery through it), a **stray dot** (an inked square with no ink beside it,
even corner to corner) and **frames too alike** (two frames in play order that differ in fewer than one square in
ten of those inked in either: they won't read as movement). The status line says how many squares at least to
change: ALIKE 3,4: CHANGE 10+ means rubbing out ten squares the two frames share would clear it; inking new
squares takes a few more. The marks go when you next change something.

When something can't be done (Delete with one frame left, Next on the last), the control shows red, then
inverts (so it reads on a black-and-white set too), and the
readout says **CAN'T** and why. Nothing changes. A stroke that changes nothing (rubbing out paper) is not an
undo step, so U always takes back your last real change.

## The Lessons

**0** (or LESSONS in the FIGURE drawer) lists the drawing chapter's lessons. Choose one with Q, A and ENTER and
the Studio sets itself up to show it, with the lawn mower from the Library and a caption on the bottom line; then
carry on as you like. The lessons use a figure of their own on the sheet, so yours is kept.

| Lesson | What you see |
| --- | --- |
| 1 A figure is rows of dots | the Mower, the cursor on row 1: its Row Codes read 28 00, two bytes for sixteen dots |
| 2 A second frame | tracing paper on, the flip-book playing the Mower's two frames |
| 3 Three ways to put it down | the Test Ground on grass: copied, mixed, masked then mixed |
| 4 The mask and its ring | the Mask layer with a Ring mask; press F for Box |
| 5 Why drawing flickers | the walk drawn two ways (below) |
| 6 Colour belongs to the cell | the Test Ground in Ink mode, the Mower a dot off the grid: the clashing blocks flash |

**RUB OUT, DRAW.** On the Test Ground, R swaps the three pictures for a second copy of the walk drawn the way a
beginner would: rub the figure out, show that, then draw it in its new place. Watch it blink: for a moment there
is only grass where the figure should be. The strip below, DRAW ONCE, changes each dot once, straight to its new
value, and never shows the gap. R again puts the pictures back.

## The sheet: several figures, saved on tape

**9** (or SHEET in the FIGURE drawer) opens the **Sheet**: every figure you are working on, up to eight, one a
line, the current one marked `*`. Q and A move the bar; ENTER opens the figure under it (or NEW FIGURE adds a
blank one, FIGURE 2 and so on). Undo starts afresh with each figure you open.

| Key | Does |
| --- | --- |
| N | a new blank figure (refused when the sheet holds eight) |
| S | **save the sheet** to tape: start the recorder first. SPACE stops |
| L | **load a sheet** from tape: it replaces the sheet (U puts the old one back). SPACE stops; a tape that is not a sheet changes nothing |
| X | **export** the current figure to tape as assembler `DEFB` lines, every frame's picture and then every frame's mask, ready to `INCLUDE` in a game |
| F, P | facings (1 or 2) and positions (1, 2, 4 or 8) for the **data size**: how many Row Codes a game would store for this figure, picture and mask each |
| 9, T | back to the Desk |

The data size counts frames × facings × positions × rows × groups a row. A figure stored at 8 positions needs
one more group a row, because shifting it right spills into the next byte: a 16 × 16 figure of two frames, one
facing, eight positions, is 2 × 1 × 8 × 16 × 3 = 768 codes, and as many again for its mask.

**The Library on tape.** Each game's figures also come as tapes of their own (`game/library-tapes/`, eight
figures a file). Load one on the Sheet page with L, like a saved sheet.

## Things to try (from the drawing chapter)

(Open the Mower from the Library first: L, then SPACE.)

1. **A sprite is rows of bits.** Look along row 1 of the Mower (the numbers on the edge help): squares 2 and 4
   are inked. That is `00101000`, $28, in the left byte; the right byte is $00. The HEX column beside row 1 says
   `2800`. Ink square F of that row and watch it become `2801`. CHECKS now finds **ink outside the mask**: the
   Mower came with its game's own mask, which has no hole for your new dot. F (in the MASK drawer) works a
   Ring mask out to fit, or U takes the dot back.
2. **A second frame.** Press G. Only rows 1, 2, 13 and 14 differ between the two frames: the checkered marks at
   the back corners move along one square, and the Mower rolls. 0.08 s a picture is what the game uses: each
   picture up for two updates, four TV frames.
3. **Make your own second frame.** Press C (COPY) to copy a frame, turn on the tracing paper (N, TRACING), change a few
   squares, press G and watch the flip-book. If CHECKS says the frames are too alike, they will look like a
   cardboard cut-out sliding about: change more.
4. **Facing the other way.** MIRROR (I) gives the left-facing frame; games often store one facing and flip it
   as they draw.
