---
version: "0.2"
status: "draft"
date: "2026-11-11"
---

# Sprite Studio — Application Specification <!-- platform-ok: product name -->

*A figure artist's desk: draw a small moving picture square by square, see it at its true size, flip its frames
like a flip-book, then find out how it will really look: on top of the scenery, through its mask, and inside the
Colour Blocks it moves across.*

This specification defines the application itself, independent of any machine. It combines design intent (what the
user should experience) with precise, checkable rules. Controls, screen layout, file formats, sound hardware and
memory belong to each implementation's own target brief, and every implementation must keep the rules here.

Markers: **[Designer's call]** a choice proposed or delegated and not yet confirmed by the designer; **[Tuning]** a
confirmed rule whose starting value playtesting may adjust. Unresolved questions are listed only in §16. The
words MUST, SHOULD and MAY are used as in BCP 14 (RFC 2119, RFC 8174) when written in capitals.

## 1. Identity and scope

- **Audience:** people making pictures for small retro games, and readers and listeners following the studio's
  drawing chapter and radio episode, who want to try the method for themselves.
- **Players:** one user.
- **Session:** minutes to an hour; the user draws, flips, checks and keeps the sheet.
- **Objective:** make a figure that reads at its true size, animates, sits cleanly on its scenery and survives the
  colour rules of the Picture Format.
- **Genre and touchstones:** a drawing tool, like squared paper, a strict pencil and a flip-book on one desk.
- **No score, no failure:** this is a tool. Mistakes are shown as checks the user can act on, never as a loss.
- **Works with:** any figure the studio has made for its games, through the Library (LIB-01), and new ones drawn
  from blank, in any box in `T-BOX-SIZES`.
- **Out of scope:** drawing whole screens or tile maps, sound, importing photographs, figures larger than the
  biggest box in `T-BOX-SIZES`.

## 2. Concept, pillars and headline features

The user draws on a large grid of squares, each square one dot of the finished figure. Beside the grid the same
figure is always shown at its true size. Frames make it move; the mask decides how it sits on scenery; the colour
cells decide what happens to colour when it moves. Each of these is something the user does and sees, not reads.

### Pillars

1. **Count the squares.** Every dot is a square the user places on purpose, with the pointing device or one square
   at a time with directional controls, like counting stitches.
2. **Always at its true size.** Whatever the user edits, the true-size picture beside it changes at once. A figure
   is judged at the size the player will see it.
3. **Show the cause.** When something will go wrong in a game (a stray dot, frames too alike, ink outside the mask,
   colour spilling onto scenery) the studio shows the exact square or cell responsible: "That frame's wrong. Look."

### Headline features

Each is met, or clearly signposted, on the Desk the first time it appears.

| Feature | First met | Requirement IDs |
| --- | --- | --- |
| Draw square by square, by hand or by directional controls | Desk, first screen after choosing an input | DRAW-01, DEV-02 |
| True-size preview, live | Desk, beside the Grid | DRAW-03 |
| Frames and flip-book playback | Desk; any Library figure has its frames | ANIM-01, ANIM-02 |
| The studio's own figures to open, study and change | Desk, the Library, named on the first visit | LIB-01 |
| Masks and the three ways to put a figure down | Desk, mask layer and Test Ground | MASK-01, GROUND-01 |
| Colour Blocks and clash, shown moving | Desk, Test Ground in colour | CLASH-01, MOVE-01 |
| Row Codes: squared paper to numbers | Desk, beside the Grid | CODE-01 |
| The drawing chapter's lessons, shown live | Desk, Lessons list | DEMO-01, FLICK-01 |

## 3. Player actions

| Action | Held or momentary | Available in | Effect, simultaneity and refusal |
| --- | --- | --- | --- |
| Choose pointing device | momentary | Start, Desk | chooses the pointing device as the input (DEV-01) |
| Choose directional | momentary | Start, Desk | chooses directional controls as the input (DEV-01) |
| Move cursor (by hand) | continuous | Desk, pointing device chosen | moves the Arrow (PTR-01) |
| Move cursor (directional) | held | Desk, directional chosen | moves the Grid Cursor one square at a time (DEV-02); opposite directions together cancel |
| Primary button | held | Desk | on the Grid: paints (DRAW-01); on a control: uses it (DEV-03) |
| Secondary button | held | Desk | on the Grid: clears squares (DRAW-01) |
| Undo | momentary | Desk | DRAW-02 |
| Previous frame / Next frame | momentary | Desk | ANIM-01; refused at the first or last frame |
| New frame | momentary | Desk | ANIM-01; refused when the sheet holds `T-FRAMES` frames |
| Delete frame | momentary | Desk | ANIM-01; refused when only one frame is left |
| Clear frame | momentary | Desk | ANIM-01 |
| Play / stop | momentary | Desk | ANIM-02 |
| Play faster / play slower | momentary | Desk | ANIM-02; refused at the ends of `T-PLAY-TIMES` |
| Onion skin on/off | momentary | Desk | ANIM-03 |
| Mirror / Nudge (four directions) | momentary | Desk | TOOL-01 |
| Picture layer / Mask layer | momentary | Desk | MASK-01 |
| Mask style | momentary | Desk | MASK-01; steps through the styles |
| Ground | momentary | Desk | GROUND-01; steps through the grounds |
| Colour mode / Figure ink | momentary | Desk | CLASH-01; each steps through its choices |
| Walk on/off, step size | momentary | Desk | MOVE-01 |
| Library | momentary | Desk | LIB-01: shows the Library; choosing a figure opens a copy of it |
| Box size | momentary | Desk | SHEET-01: steps through `T-BOX-SIZES` |
| Choose figure, save sheet, load sheet, export | momentary | Desk | SHEET-01 |
| Title | momentary | Desk | returns to the Start screen (STATE-02) |
| Music on/off | momentary | Start | PRES-02 |

Actions are abstract. Each implementation binds them to its own inputs. With a two-button pointing device the
primary and secondary buttons are its buttons; with directional controls they are two separate controls. Every
action on the Desk MUST also be available as its own control on screen, so a pointing-device user can do
everything by pointing, and as its own direct action, so a directional user never has to steer to a control.

## 4. States and lifecycle

| State | Entered when | Leaves to | What runs, freezes or resets |
| --- | --- | --- | --- |
| Start | the application starts; Title | Desk | music plays (if on); the sheet is kept |
| Desk | an input is chosen on the Start screen | Start | everything on the Desk runs |

Neither state has a time-out: if nothing is pressed, the Start screen waits with its music playing (if on) and the
Desk waits as it is, the flip-book still playing if it was. There is no pause, because nothing on the Desk is timed
against the user.

### STATE-01 — Starting

The application starts on the Start screen with no input chosen: the title, "Choose your input" with both choices,
and the music setting. Music is on (PRES-01). The sheet holds one blank figure, box `T-BOX-START`, one frame; on
the first visit the Desk names the Library (LIB-01).

### STATE-02 — Moving between Start and Desk

Choosing an input on the Start screen opens the Desk with the current frame and every Desk setting as they were
last left (on the first visit: frame 1, picture layer, play stopped, play speed `T-PLAY-DEFAULT`). The Title
action returns to the Start screen; the sheet, frames, undo and every Desk setting are kept for the session.

### STATE-03 — Buttons held across a change

Any button held when the screen changes (Start to Desk, Desk to Start, or a change of input) is ignored until it is
released: it paints nothing and uses no control. The same holds for a held direction: it moves nothing until
released and pressed again.

## 5. World, objects and content

The **Picture Format** is the set of rules the finished figure must live with. It is content of this tool, like a
word list in a word game, and every rule below that mentions it cites it.

**Picture Format** (authoritative content):

- A picture is a grid of dots, each **ink** or **paper**; a dot carries no colour of its own.
- Colour is held per **Colour Block**, a square block of `T-CELL` × `T-CELL` dots aligned to the scene: each cell has
  exactly one ink colour and one paper colour, chosen from `T-COLOURS` colours, and one brightness (plain or bright)
  shared by both.
- A figure's dots are read in **groups** of `T-GROUP` dots along a row, left to right; each group is one Row Code
  (CODE-01).

**The Desk:**

| Object | Role | Behaviour | On contact with the cursor | Never touches |
| --- | --- | --- | --- | --- |
| Grid | the figure drawn large, one square per dot | the current frame of the current figure; a heavier line after every `T-GROUP` squares across | primary paints, secondary clears (DRAW-01) | the controls |
| True-size preview | the current frame at the size the player sees it | redrawn within one refresh of any change (DRAW-03) | nothing | — |
| Flip-book | the figure's frames played in order at true size | ANIM-02 | nothing | — |
| Frame strip | all the frames at true size, the current one marked | ANIM-01 | primary on a frame makes it current | — |
| Controls | one on-screen control per Desk action | DEV-03 | primary uses it | the Grid |
| Readouts | input, square under the cursor, frame "n of N", inked squares, play speed, last event | updated every refresh | nothing | — |
| Row Codes panel | the current frame's Row Codes | CODE-01 | nothing | — |
| Checks panel | what a game would show wrong | CHECK-01 | primary on a check marks its squares on the Grid | — |
| Test Ground | the figure on scenery, in colour, moving | GROUND-01, CLASH-01, MOVE-01 | nothing | — |

**Sheet:** up to `T-FIGURES` figures; each figure has a name of up to `T-NAME` letters, a box size from
`T-BOX-SIZES`, from one to `T-FRAMES` frames, a mask for each of its frames (MASK-01), a mask style, and an ink colour.

**The Library:** the figures the studio has made for its own games (LIB-01), each with its name, its game, its box
and its frames. Among them is the drawing chapter's worked example, the lawn mower seen from above in its two
rolling frames, which differ only in rows 1, 2, 13 and 14 (counting from 0).

### LIB-01 — The Library

**Intent:** the studio's whole cast is on the desk to study, change and learn from, not one example.

**Rules:** the Library lists the figures the studio has made for its games, grouped by game, each with its name and
box. Choosing one replaces the current figure with a copy of it (its box, name and frames, up to `T-FRAMES`) as one
Undo step; the original in the Library never changes. The Library holds only figures the studio drew for its own
games and none drawn from a real person. A figure with more frames than `T-FRAMES`, or a box larger than the
largest in `T-BOX-SIZES`, is not offered.

**Feedback:** the readouts name the figure, its game and its box; the status line says "OPENED" and the name.

**Acceptance:** AC-33, AC-34

## 6. Mechanics

### DEV-01 — Choosing the input

**Intent:** the studio works whatever the user has, and never guesses.

**Rules:** two inputs are offered: a pointing device, or directional controls. Each is chosen by its own choose
action, which works on the Start screen and on the Desk, whatever input is current. Nothing is detected
automatically and no device is read until it is chosen. On the Start screen, choosing an input opens the Desk
(STATE-02). On the Desk, choosing an input switches to it at once.

**Interactions:** choosing the pointing device places the Arrow at the centre of the Grid and takes the device's
current state as its starting point, so the Arrow does not jump. Choosing directional controls places the Grid
Cursor on the square the Arrow was over, or on the Grid's centre square when the Arrow was off the Grid.
Buttons held at that moment follow STATE-03.

**Feedback:** the input in use is named in the readouts; the input-chosen signal (§9).

**Acceptance:** AC-01, AC-02, AC-03

### DEV-02 — Directional controls on the Grid

**Intent:** a user with only directional controls can place every square exactly and still draw lines quickly.

**Rules:** with directional controls the cursor is the **Grid Cursor**, which always sits on one square of the
Grid. A direction pressed moves it one square at once; held, it moves one more square after `T-REPEAT-DELAY` and
then one square every `T-REPEAT-TIME`. Diagonals are two directions held together. Opposite directions held
together cancel on that axis. The Grid Cursor stops at the Grid's edges and does not wrap. Controls are reached by
their direct actions (§3), not by steering.

**Interactions:** while primary or secondary is held, every square the Grid Cursor moves onto is painted or
cleared (DRAW-01), so a held button and a held direction draw a line.

**Feedback:** the square under the Grid Cursor is marked in a way that reads on both ink and paper squares; the
readouts show its column and row.

**Worked example:** right held for 1 second with `T-REPEAT-DELAY` 0.3 s and `T-REPEAT-TIME` 0.08 s: one square at
once, one at 0.3 s, then one every 0.08 s up to 1 s (at 0.38, 0.46, ... 0.94 s: 8 more): 10 squares.

**Acceptance:** AC-04, AC-05

### PTR-01 — The Arrow

**Intent:** the Arrow feels attached to the hand, slow movement included.

**Rules:** each refresh, the Arrow moves by the hand's movement since the previous refresh times `T-GAIN`.
Movement too small to move it a whole step is kept for the next refresh, so none is lost. Moving the hand away from
the user moves the Arrow up. The Arrow can reach every visible point of the Desk, stops at its edges and does
not wrap.

**Feedback:** the Arrow is always drawn on top, never damages what is under it, and the Grid square under it is
marked as the Grid Cursor's square is.

**Acceptance:** AC-06

### DEV-03 — Controls

**Intent:** every action can be found on screen.

**Rules:** each Desk action has an on-screen control with a short label. A primary press on a control uses it at
once (once per press: holding does not repeat). A control whose action would be refused shows the refusal signal
and changes nothing. With directional controls, the direct action does the same as the control.

**Feedback:** the control lights for `T-LIGHT-TIME` when used; the last event readout names the action.

**Acceptance:** AC-07

### DRAW-01 — Painting squares

**Intent:** drawing feels like filling in squared paper with a pencil and a rubber.

**Rules:** a primary press on a Grid square starts a **stroke**. The stroke's mode is decided by the square pressed:
on a paper square the stroke inks, on an ink square it clears. That square is changed at once. While primary stays
held, every square the cursor passes over is set by the stroke's mode, including every square on the straight
line between its positions at consecutive refreshes, so a fast movement leaves an unbroken line. A secondary press
starts a clearing stroke the same way, whatever the square. Releasing the button ends the stroke. Leaving the Grid
during a stroke paints nothing outside it and nothing across the gap; the stroke continues from where the cursor
comes back onto the Grid while the button is still held. While the Mask layer is selected, strokes paint the mask
instead (MASK-01).

**Interactions:** a stroke is one step for Undo (DRAW-02). Primary and secondary pressed together: the first
pressed wins until both are released.

**Feedback:** each changed square shows on the Grid and in the true-size preview within one refresh.

**Acceptance:** AC-08, AC-09, AC-10

### DRAW-02 — Undo

**Intent:** a slip of the hand costs nothing.

**Rules:** Undo restores the sheet to how it was before the last change: a stroke, or New, Delete, Clear, Mirror,
Nudge, a mask style change, a hand edit of the mask, a box size change. Using Undo again straight away redoes that
change. Only the last change is kept. With nothing to undo, Undo is refused.

**Feedback:** the readout names what was undone or redone.

**Acceptance:** AC-11

### DRAW-03 — True-size preview

**Intent:** the user always judges the figure at the size the player will see.

**Rules:** the true-size preview shows the current frame, dot for dot, with ink and paper as on the Grid, and
changes within one refresh of any change to it.

**Acceptance:** AC-08

### ANIM-01 — Frames

**Intent:** a second picture, a little different, makes the figure move; making one should cost one press.

**Rules:** a figure has from one to `T-FRAMES` frames, shown in order in the frame strip. Previous and Next make
the neighbouring frame current, refused at the first or last frame. New inserts a copy of the current frame
straight after it and makes the copy current; refused when the figure has `T-FRAMES` frames. Delete removes the
current frame and makes its neighbour current (the previous one, or the next when it was the first); refused when
only one frame is left. Clear makes every dot of the current frame paper.

**Feedback:** the frame readout shows "frame n of N"; the strip marks the current frame.

**Acceptance:** AC-12, AC-13

### ANIM-02 — Flip-book

**Intent:** see the frames move, at a speed a game would show them, while still drawing.

**Rules:** Play starts the flip-book: it shows the figure's frames in order at true size, each for the current play
time, then starts again from frame 1. Stop holds it on frame 1. Play faster and play slower step the play time
through `T-PLAY-TIMES`, refused at either end. Drawing continues while the flip-book plays, and an edit appears in
the flip-book the next time that frame is shown. With one frame, the flip-book shows that frame.

**Feedback:** the play readout shows the time each picture is shown; the Play control reads "Stop" while playing.

**Acceptance:** AC-14, AC-15

### ANIM-03 — Onion skin

**Intent:** draw the next frame against the last, like tracing paper.

**Rules:** with onion skin on, the Grid marks the squares that are ink in the previous frame and paper in the
current one with a light mark, distinct from both ink and paper. It never changes the frame. On frame 1 it shows
the last frame.

**Acceptance:** AC-16

### TOOL-01 — Mirror and nudge

**Intent:** the moves an artist makes on paper by turning it over or sliding it along.

**Rules:** Mirror reflects the current frame left to right. Nudge moves every dot of the current frame one square
in the chosen direction; the row or column pushed off one edge comes back on the opposite edge, so nothing is lost.

**Acceptance:** AC-17

### CODE-01 — Row Codes

**Intent:** squared paper to numbers: the user sees what each row will become in a program.

**Rules:** for every row of the current frame, the panel shows one Row Code per group of `T-GROUP` dots: ink = 1,
paper = 0, the leftmost dot the most significant, written as two base-16 digits. When a figure's width is not a
whole number of groups, the last group is padded with paper on the right. The row under the cursor is highlighted.
With the Mask layer selected, the codes are the mask's.

**Worked example:** row 1 of the Library's lawn mower, first frame, has ink in columns 2 and 4 (counting from 0): the
first group is 00101000, code 28; the second group is 00.

**Acceptance:** AC-18

### CHECK-01 — Checks

**Intent:** the studio spots what a figure artist would spot from the door.

**Rules:** the Checks panel lists, live, each problem found in the current figure, with the frame it is in:

| Check | Found when | Squares marked |
| --- | --- | --- |
| Stray dot | an ink dot with no ink among its eight neighbours | the dot |
| Frames too alike | two frames next to each other in play order (the last and frame 1 included) differ in fewer than `T-STRIDE-MIN` of the squares that are ink in either | the squares that differ |
| Ink outside the mask | an ink dot not covered by the frame's mask | the dot |
| Hard to see | the figure's ink and the Test Ground's paper are a pair in `T-HARD-PAIRS` | none; the Test Ground cells are marked |

A primary press on a check makes its frame current and marks its squares on the Grid until the next change. A
figure with no problems shows "No problems found".

**Acceptance:** AC-19, AC-20

### MASK-01 — Masks

**Intent:** a mask is a second picture that says which scenery dots the figure replaces; the user sees it, picks
how wide its ring is, and can edit it.

**Rules:** each of the frames has a mask the size of the figure. A dot in the mask is either **cover** (the scenery dot is
cleared) or **keep**. The figure's mask style is one of:

- **Ring:** cover every ink dot, every paper dot enclosed by ink (not reachable from the box edge through paper dots
  side by side), and every dot within `T-RING` dots side by side of an ink dot.
- **Shape:** as Ring with no ring.
- **Box:** cover every dot of the box.
- **Hand:** as last drawn by the user.

Ring, Shape and Box masks follow the picture: they are recalculated whenever the picture changes. Painting on the
Mask layer turns the style to Hand for the whole figure, keeping the masks as it was, and from then on the
masks change only by hand or by choosing another style. The Mask layer shows the picture's ink dots and, beneath
them, the mask's cover dots in a distinct mark.

**Interactions:** Mirror and Nudge apply to the mask with the picture.

**Acceptance:** AC-21, AC-22

### GROUND-01 — Three ways to put it down

**Intent:** see why a mask is needed, on real scenery.

**Rules:** the Test Ground shows the current frame at true size three times over the chosen Ground, side by side:
**Copy** (every dot of the box replaced by the figure's dot), **Mix** (the figure's ink added on top of the
scenery) and **Mask then mix** (scenery cleared where the mask covers it, then the ink added). The Grounds are:
grass (a busy pattern of thin blades), stripes, plain paper and plain ink. The flip-book plays here too when on.

**Acceptance:** AC-23

### CLASH-01 — Colour Blocks

**Intent:** colour belongs to the cell, not the figure; the user sees what that does to the scenery before a game
does.

**Rules:** with colour on, the Test Ground is drawn in Colour Blocks (§5), each with the Ground's own ink and paper,
and the figure moves over it (MOVE-01). The **colour mode** decides the colour of every cell the figure's box
touches:

- **Keep:** cells keep their colours; the figure's ink shows in each cell's ink colour.
- **Ink:** cells take the figure's ink colour and keep their paper.
- **Box:** cells take the figure's ink colour and a black paper.

A **clash** is a cell whose colour the figure changed that also holds scenery ink not covered by the mask: that
scenery is recoloured with the figure. The Test Ground marks clashing cells, and the readout shows the number of
cells the box touches now, the most it can touch at any position, and the clashes now.

**Worked example:** a 16 × 16 box with `T-CELL` 8 touches 4 cells when it sits on the cell grid and 9 when it is
offset in both directions.

**Acceptance:** AC-24, AC-25

### MOVE-01 — Walking test

**Intent:** a figure that looks right standing still can still jump, smear or clash when it moves.

**Rules:** with Walk on, the figure crosses the Test Ground left to right and back, moving the step size each time
the flip-book turns to the next frame in the flip-book, facing the way it moves (mirrored when going left). The step size is one of
`T-STEPS`. The readout shows the step size; a step larger than `T-STEP-MAX` adds the check "Moves too far". With Walk off, the figure stands at the Ground's left edge, on the cell grid.

**Acceptance:** AC-26

### DEMO-01 — The drawing chapter, shown

**Intent:** everything the studio's drawing chapter and its radio episode explain can be seen happening on the
Desk, with the Library's lawn mower (the chapter's worked example), in the order they are taught.

**Rules:** a **Lessons** list on the Desk names each lesson below. Choosing one sets the Desk up to show it (the
lawn mower opened from the Library, the settings named) and shows a one-line caption; the user can then change
anything. Leaving a lesson keeps the Desk as it is.

| Lesson | The Desk shows | Requirement IDs |
| --- | --- | --- |
| A figure is rows of dots | the Grid with the heavier middle line; the Row Codes of row 1 ("28 00") highlighted | DRAW-01, CODE-01 |
| A second frame | the two rolling frames, onion skin on, flip-book playing at `T-PLAY-DEFAULT` | ANIM-01, ANIM-02, ANIM-03 |
| Three ways to put it down | the Test Ground on grass: Copy, Mix, Mask then mix | GROUND-01 |
| The mask and its ring | the Mask layer, Ring style, then Box style | MASK-01 |
| Why drawing flickers | the walking test drawn both ways, side by side (FLICK-01) | FLICK-01 |
| Colour belongs to the cell | the Test Ground in colour, Ink mode, the clashing cells marked | CLASH-01 |

**Feedback:** the caption names the lesson and what to look at, in one plain line.

**Acceptance:** AC-31

### FLICK-01 — Rub out, or draw once

**Intent:** the user sees why a figure artist insists that each dot of the picture changes once, straight to its
final state.

**Rules:** during the walking test the Test Ground can show a second copy of the walk drawn the naive way: each
time the figure moves, it is first rubbed out (its old place restored to scenery and shown) and only then drawn
in its new place, so the viewer briefly sees scenery where the figure is. The normal copy changes each dot once,
straight from its old state to its new one. The naive copy is labelled "RUB OUT, DRAW" and the normal one "DRAW
ONCE".

**Acceptance:** AC-32

### SHEET-01 — The sheet

**Intent:** a whole cast on one sheet, kept between sessions, ready for a game.

**Rules:** Choose figure steps through the sheet's figures and "new figure" (refused when the sheet holds
`T-FIGURES`), which adds a blank figure named "FIGURE" plus its number, box `T-BOX-START`. Box size steps through
`T-BOX-SIZES`; growing keeps the drawing at the top left, shrinking drops the dots outside the new box (one Undo
step). Save sheet keeps the whole sheet between sessions; Load sheet brings back the last saved sheet, replacing the
current one (one Undo step). Export writes the current figure's frames as Row Codes a game can include, picture and
mask for all its frames. The readout shows the **data size**: frames × facings × positions × rows × groups per row,
picture and mask counted separately, for the facings and positions chosen for export.

**Acceptance:** AC-27, AC-28

## 7. Progression, scoring and economy

None: this is a tool. The inked-square count and the checks are readouts, not a score.

## 8. Randomness and repeatability

No randomness: the same actions always give the same sheet.

## 9. Presentation

**Art direction:** a tidy desk: the Grid like squared paper with a heavier line every `T-GROUP` squares, the
true-size picture framed beside it like a sheet held at arm's length, labels in plain capitals.

**Always visible on the Desk:** the Grid, the true-size preview, the frame strip, the input in use, the square under
the cursor, "frame n of N", and the way to the Start screen.

**Signals** (every audible cue has a visible twin, so the studio is fully usable with sound off)

| Event | Visible signal | Audible cue | Requirement IDs |
| --- | --- | --- | --- |
| Input chosen | the readout names the input | short chime | DEV-01 |
| Control used | the control lights; the last event readout names it | short click | DEV-03 |
| Refused | the control flashes once; the readout shows "can't" and why | low blip | DEV-03, ANIM-01, ANIM-02, DRAW-02 |
| Undo / redo | the readout shows "undo" or "redo" | soft click | DRAW-02 |
| Check found | the Checks panel lists it | none | CHECK-01 |
| Sheet saved or loaded | the readout shows "saved" or "loaded" | chime | SHEET-01 |

Painting makes no sound: it happens many times a second.

### PRES-01 — Music

A short, light tune plays on the Start screen, on at start; none plays on the Desk.

### PRES-02 — Music off

The user MUST be able to switch music off and on from the Start screen. The setting is shown, effects keep
playing, and the setting is kept for the session.

**Accessibility:** no readout or mark relies on colour alone: the cursor square, onion skin, mask and check marks
differ by shape or pattern as well. Nothing needs fast reactions.

## 10. Content and tone rules

### TONE-01 — No real people or brands

No real person, brand, product, company or other publisher's game appears in names, text, art or sound, and no
invented name evokes one. The studio's own games and the figures it made for them may be named (LIB-01); none of
them shows a real person.

### TONE-02 — Plain and welcoming

Text is short, plain and friendly; checks say what is wrong and where, never that the user is wrong.

## 11. Quality requirements

- Every change appears within one refresh; painting keeps up with the fastest hand movement.
- Nothing on the Desk is ever seen half-drawn: each part of the picture changes from its old state straight to its
  new one, a refresh late at worst, never wrong.
- The Arrow never flickers or leaves marks.

## 12. Tuning table

| ID | Quantity | Value | Unit | Notes |
| --- | --- | --- | --- | --- |
| T-GAIN | Arrow movement per unit of hand movement | 1 | steps | [Tuning] |
| T-REPEAT-DELAY | Held direction: time before the second square | 0.3 | seconds | [Tuning] [Designer's call] |
| T-REPEAT-TIME | Held direction: time between later squares | 0.08 | seconds | [Tuning] [Designer's call] |
| T-LIGHT-TIME | How long a used control stays lit | 0.2 | seconds | [Tuning] |
| T-FRAMES | Most frames in one figure | 8 | frames | [Designer's call] |
| T-PLAY-TIMES | Flip-book time on each picture, slowest to fastest | 0.32, 0.24, 0.16, 0.12, 0.08, 0.04 | seconds | [Tuning] [Designer's call] |
| T-PLAY-DEFAULT | Starting play time | 0.08 | seconds | [Tuning] two updates of the studio's own example game |
| T-GROUP | Dots per Row Code | 8 | dots | Picture Format |
| T-CELL | Colour Block side | 8 | dots | Picture Format |
| T-COLOURS | Colours: black, blue, red, magenta, green, cyan, yellow, white | 8 | colours | Picture Format |
| T-BOX-START | Box of a new figure | 16 × 16 | dots | |
| T-BOX-SIZES | Box sizes, across × down | 8 by 8, 16 × 8, 8 × 16, 16 × 16, 16 × 24, 24 × 16, 24 × 24, 24 × 32, 32 × 16, 32 × 24, 32 × 32 | dots | owner (v0.2): the sizes the studio's games use, up to 32 × 32 |
| T-FIGURES | Most figures on a sheet | 8 | figures | [Designer's call] |
| T-NAME | Longest figure name | 8 | letters | |
| T-RING | Ring width of a Ring mask | 1 | dots | [Designer's call] |
| T-STRIDE-MIN | Least change between neighbouring frames | 10 | per cent of squares inked in either | [Tuning] |
| T-STEPS | Walking test step sizes | 1, 2, 4, 8 | dots per step | |
| T-STEP-MAX | Largest step before "Moves too far" | 4 | dots per step | [Tuning] |
| T-HARD-PAIRS | Ink on paper hard to see | white, yellow or cyan on white, yellow or cyan | colour pairs | [Tuning] |

## 13. Glossary

- **Sheet:** everything the user is working on: up to `T-FIGURES` figures.
- **Figure:** a small picture with its frames, masks, box size, name and ink colour; game makers call it a sprite. <!-- platform-ok: defines the tool's subject once -->
- **Box:** the figure's size in dots, across × down.
- **Dot:** one point of the finished picture, ink or paper.
- **Square:** one dot drawn large on the Grid.
- **Ink, paper:** a dot is ink (drawn) or paper (empty); in colour, each cell has one ink colour and one paper
  colour.
- **Frame:** one picture of a figure; the flip-book shows the frames in turn.
- **Grid:** the large drawing area showing the current frame, one square per dot.
- **Grid Cursor:** the marked square that directional controls move.
- **Arrow:** the cursor moved by the pointing device.
- **Stroke:** the squares painted from a button press to its release.
- **Mask:** a second picture belonging to a frame: which scenery dots the figure replaces.
- **Ring:** the band of covered dots around a figure's ink in a Ring mask.
- **Picture Format:** the rules in §5 the finished figure must live with.
- **Colour Block:** a block of `T-CELL` × `T-CELL` dots sharing one ink colour and one paper colour.
- **Clash:** scenery ink recoloured because the figure changed its cell's colour.
- **Row Code:** one group of `T-GROUP` dots of a row written as a two-digit base-16 number.
- **Test Ground:** the scenery area where the figure is shown three ways, in colour, and walking.
- **Ground:** the scenery pattern of the Test Ground.
- **Library:** the figures the studio made for its own games, to open as copies (LIB-01).
- **Step:** the finest position the Arrow can take; each implementation chooses it so the Arrow can reach every
  visible point.
- **Unit of hand movement:** the smallest movement the pointing device reports.
- **Pointing device:** an input moved by hand that reports how far it moved, with a primary and a secondary button.
- **Directional controls:** an input of eight directions and two buttons.
- **Refresh:** one update of the display.
- **Desk, Start screen:** the two states in §4.

## 14. Acceptance

| ID | Requirements | Given / When / Then |
| --- | --- | --- |
| AC-01 | STATE-01, DEV-01, PRES-01 | Given the application just started, when nothing is pressed, then the Start screen shows "Choose your input" with both inputs, no cursor, and music playing. |
| AC-02 | DEV-01, STATE-02, LIB-01 | Given the Start screen on the first visit, when directional is chosen, then the Desk shows a blank figure, "frame 1 of 1", names the Library, the Grid Cursor on the Grid's centre square, and the user can paint. |
| AC-03 | DEV-01 | Given the Desk with directional controls and the Grid Cursor moved, when the pointing device is chosen and then directional again, then the Arrow starts at the Grid's centre without jumping, and the Grid Cursor returns on the square the Arrow was over. |
| AC-04 | DEV-02 | Given the Grid Cursor at column 0, when right is held for 1 second, then it is at column 10 and stops at once on release. |
| AC-05 | DEV-02 | Given the Grid Cursor at the top-left square, when up and left are held, then it stays there and does not wrap. |
| AC-06 | PTR-01 | Given the pointing device, when the hand moves away from the user, then the Arrow moves up, and at the top edge it stops. |
| AC-07 | DEV-03 | Given the Desk, when New is used by its control and by its direct action, then each adds one frame, the control lights, and the readout names it. |
| AC-08 | DRAW-01, DRAW-03 | Given a paper square under the cursor, when primary is pressed and released, then the square is ink on the Grid and in the true-size preview within one refresh; pressed again, it is paper. |
| AC-09 | DRAW-01, DEV-02 | Given directional controls on a paper square, when primary is held and right held for five squares, then six squares in a row are ink. |
| AC-10 | DRAW-01 | Given the pointing device, when primary is pressed on a paper square and the Arrow moved fast across the Grid, off it and back on at another point, then an unbroken inked line follows the path on the Grid and nothing is painted across the gap. |
| AC-11 | DRAW-02 | Given a stroke just painted, when Undo is used, then the frame is as before the stroke; Undo again restores the stroke; the user can carry on painting. |
| AC-12 | ANIM-01 | Given a figure of two frames on frame 2, when New is used, then there are three frames, frame 3 is current and identical to frame 2. |
| AC-13 | ANIM-01 | Given a figure of one frame, when Delete is used, then nothing changes and the refusal signal shows; with `T-FRAMES` frames, New is refused the same way. |
| AC-14 | ANIM-02 | Given the Library's lawn mower opened, when Play is used, then the flip-book alternates its two frames, each shown for `T-PLAY-DEFAULT`, until Stop. |
| AC-15 | ANIM-02 | Given the flip-book playing, when a square of frame 2 is painted, then the flip-book shows the change the next time frame 2 comes round and keeps playing. |
| AC-16 | ANIM-03 | Given onion skin on and frame 2 current, then the squares ink in frame 1 and paper in frame 2 carry the onion mark, and painting one makes it ink with no mark. |
| AC-17 | TOOL-01 | Given a frame with ink in column 0 only, when Nudge left is used, then the ink is in the last column; Mirror then puts it back in column 0. |
| AC-18 | CODE-01 | Given the Library's lawn mower, frame 1, then row 1's Row Codes read 28 00; after inking column 15 of that row they read 28 01. |
| AC-19 | CHECK-01 | Given a frame with one ink dot far from any other, then the Checks panel lists "Stray dot" with its frame, and choosing it marks that square. |
| AC-20 | CHECK-01 | Given two frames identical but for one square, then "Frames too alike" is listed; after painting enough squares to differ by `T-STRIDE-MIN`, it is gone. |
| AC-21 | MASK-01 | Given the Ring style, when a square is inked, then the mask covers it and the dots beside it side by side within `T-RING`. |
| AC-22 | MASK-01, CHECK-01 | Given the Mask layer, when a covered dot under ink is painted to keep, then the style shows Hand and "Ink outside the mask" is listed. |
| AC-23 | GROUND-01 | Given the grass Ground, then Copy shows the figure in a clean box, Mix shows grass through its body, and Mask then mix shows the figure whole with grass up to its ring. |
| AC-24 | CLASH-01 | Given the Ink mode over grass with ink blades, when the figure stands offset from the cell grid, then the readout shows 9 cells touched and the cells with recoloured blades are marked as clashes. |
| AC-25 | CLASH-01 | Given the Keep mode, then the clash count is 0 and the figure shows in each cell's own ink. |
| AC-26 | MOVE-01 | Given Walk on with step 8, then "Moves too far" is listed; with step 2 it is gone, and the figure turns to face left at the right edge and walks back. |
| AC-27 | SHEET-01 | Given a sheet with two figures, when it is saved, the application restarted and the sheet loaded, then both figures, their frames and masks are as saved, and the user can carry on drawing. |
| AC-28 | SHEET-01 | Given a 16 × 16 figure of two frames exported with one facing and 8 positions, then the data size shown is 2 × 1 × 8 × 16 × 3 codes for the picture and the same for the mask. |
| AC-29 | STATE-02, STATE-03 | Given the Desk on frame 2 with play on, when Title is used and an input chosen again while primary is held, then the Desk shows frame 2, still playing, and nothing is painted until primary is released and pressed again. |
| AC-30 | PRES-02 | Given music playing on the Start screen, when music is switched off, then it stops, the setting is shown, and it stays off after a visit to the Desk. |
| AC-31 | DEMO-01 | Given the Desk, when the lesson "A second frame" is chosen, then the Library's lawn mower is current with onion skin on and the flip-book playing, and the caption names the lesson; the user can then paint as usual. |
| AC-32 | FLICK-01 | Given the walking test with both copies, when they are watched for 10 seconds, then the "RUB OUT, DRAW" copy is seen with scenery showing through the figure at moments, and the "DRAW ONCE" copy never is. |
| AC-33 | LIB-01 | Given the Desk, when the Library is opened and a 32 × 32 figure from one of the studio's games is chosen, then the Grid shows its frame 1 whole, the readouts name it, its game and "32X32", the true-size preview shows it dot for dot, and Undo brings back the figure before; the user can paint on it. |
| AC-34 | LIB-01, TONE-01 | Given the Library, then every figure in it was made by the studio for its own games, none shows a real person, and none is larger than the largest box in `T-BOX-SIZES`. |

| ID | Requirements | Human evaluation goal |
| --- | --- | --- |
| H-01 | Pillar 1, DRAW-01, DEV-02 | A tester draws a 16 × 16 figure with directional controls alone and says placing squares felt exact. |
| H-02 | Pillar 2, DRAW-03, ANIM-02 | A tester judges a two-frame walk from the true-size flip-book without looking at the Grid. |
| H-03 | Pillar 3, CHECK-01, CLASH-01 | A first-time user can say why a marked cell clashes within a minute of seeing it. |
| H-05 | DEMO-01 | A reader of the drawing chapter recognises each lesson on the Desk and says it matched the book. |
| H-04 | TONE-01, TONE-02 | A reviewer reads every text and finds no real name or brand and nothing unfriendly. |

## 15. Playable slices

Recommended build order. Each slice is usable and checkable on its own; implementations may re-slice.

| Slice | What the user can do | Requirement IDs |
| --- | --- | --- |
| 1 | Choose an input, draw on the Grid by hand or square by square, see it at true size, undo, add and remove frames, play the flip-book, go back to the Start screen | STATE-01, STATE-02, STATE-03, DEV-01, DEV-02, DEV-03, PTR-01, DRAW-01, DRAW-02, DRAW-03, ANIM-01, ANIM-02, PRES-01, PRES-02 |
| 2 | Onion skin, mirror and nudge, Row Codes, checks for stray dots and frames too alike | ANIM-03, TOOL-01, CODE-01, CHECK-01 |
| 3 | The Library of the studio's own figures, and every box size | LIB-01, SHEET-01 (box size) |
| 4 | Masks and the three ways on the Test Ground | MASK-01, GROUND-01 |
| 5 | Colour Blocks, clash and the walking test | CLASH-01, MOVE-01 |
| 6 | A sheet of figures, save, load and export | SHEET-01 |
| 7 | The chapter's lessons, one choice each, and the flicker demonstration | DEMO-01, FLICK-01 |

TONE-01 and TONE-02 apply to every slice.

## 16. Still to decide

Nothing open. Status stays draft until the designer confirms the `[Designer's call]` items (D1–D31 in the spec notes beside this file).

## 17. Revision record

| Version | Date | Change | Why |
| --- | --- | --- | --- |
| 0.1 | 2026-11-11 | First draft: Start and Desk; input choice; drawing by hand and square by square; undo; true-size preview; frames and flip-book; onion skin; mirror and nudge; Row Codes; checks; masks; three ways; Colour Blocks and clash; walking test; the sheet | owner brief; `sprite-studio-spec-notes.md` |
| 0.2 | 2026-11-11 | The Library (LIB-01) of the studio's own figures replaces the single Starting Figure; the Desk opens on a blank figure; box sizes up to 32 × 32; TONE-01 allows the studio's own games and figures; slice 3 is the Library and box sizes | owner: "The app is too focused on the mower ... it should be possible to work with any Dalex sprite" <!-- platform-ok: the owner's words --> |
