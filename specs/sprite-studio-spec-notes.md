# Sprite Studio: spec notes

Owner brief (2026-11-11): "a sprite studio that supports the work that Joo describes in the podcast and book. It
should support drawing sprites with a keyboard or mouse. Animation and preview and dealing with colour clash and
other issues documented in the skills and cards. Please spec and start implementing this in a new private repo
without further input. I will review and refine when M1 is complete."

No interview was held: the owner asked for none. Every decision below is a `[Designer's call]` made by the agent
from the sources, waiting for the owner's review.

## Sources

- Hyun-joo Lee's method: the drawing chapter of the owner's unpublished Spectrum games book (its sections on drawing on squared paper, turning paper into
  bytes, a second frame, masks, shifting to any pixel and tinting), and Joo's episode of the owner's podcast.
- `zx-assets` skills: `zx-sprite-explain` (technique catalogue), `zx-sprite-data` (colour modes keep, ink and box;
  budget formula; mask ring), `zx-sprite-assets/references/finishing-rules.md` (rule 5 no stray pixels, rule 12 at
  most about 4 px per animation frame, rule 18 frames change at least 10%).
- Pattern cards: `A4/sprite-inventory.md`, `A4/runtime-mirroring-bit-reverse-table.md`,
  `A4/runtime-shift-vs-preshift.md`, `A5/hero-colour-at-shared-cells.md`, `A5/palette-and-attribute-usage.md`,
  `A5/monochrome-play-area.md`, `A20/animation-frames-per-action.md`.
- Kitchen Sink (the owner's earlier, unpublished test program): the input choice, pointer and directional fallback proven in its
  M1, reused here.

## Decisions

| ID | Decision | Status | Source |
| --- | --- | --- | --- |
| D1 | Two states only, Start (choose input, music) and Desk; Title returns to Start keeping everything | [Designer's call] | Kitchen Sink STATE pattern, simplified |
| D2 | Choose actions work on the Desk too (switch input without leaving), unlike Kitchen Sink | [Designer's call] | a tool is used for long sessions |
| D3 | Directional controls move a Grid Cursor one square at a time with key repeat, not a free cursor; every control has a direct action | [Designer's call] | Joo: "count the squares like stitches"; exact placement |
| D4 | Painting: the stroke's mode is decided by the square pressed (paper → ink, ink → clear); secondary always clears; unbroken lines between refreshes; no line across a gap off the Grid | [Designer's call] | squared paper and rubber |
| D5 | One level of undo, undo again redoes | [Designer's call] | cheap; protects Clear and Delete without confirmations |
| D6 | Up to 8 frames per sprite; New copies the current frame | [Designer's call] | Joo: "draw the second one beside the first"; A20 walk 8 frames typical |
| D7 | Flip-book play times 0.32 to 0.04 s, default 0.08 s (the studio's example game: two updates, four TV pictures) | [Designer's call] | the chapter's second-frame section; A20 75-150 ms |
| D8 | Starting Sprite: the studio's own lawn mower, facing right, its two rolling frames | [Designer's call] | the book's worked example; flip-book shows on first visit |
| D9 | Row Codes as base-16 pairs, leftmost dot most significant (squared paper to numbers) | [Designer's call] | the chapter's paper-to-bytes section |
| D10 | Checks: stray dot (8 neighbours), frames too alike (10%), ink outside mask, hard to see (pale ink on pale paper) | [Designer's call] | finishing rules 5 and 18; sprite-data colour rules |
| D11 | Mask styles Ring (1 dot, side by side), Shape, Box, Hand; auto masks follow the picture until hand-edited | [Designer's call] | the chapter's masks section; zx-sprite-explain *The ring round the mask* and *Box masks* |
| D12 | Test Ground shows Copy, Mix, Mask then mix over grass, stripes, plain paper and plain ink | [Designer's call] | the chapter's figure of three ways to put the Mower on the grass |
| D13 | Colour modes Keep, Ink, Box from zx-sprite-data; clash = recoloured scenery ink not under the mask; cells touched now and at worst | [Designer's call] | zx-sprite-data §2; `attr_cells_aligned/worst` |
| D14 | Walking test with steps 1, 2, 4, 8 dots; "Moves too far" above 4 | [Designer's call] | finishing rule 12 |
| D15 | Box sizes 8×8, 16×16, 16×24, 24×24, 24×32; up to 8 sprites per sheet | [Designer's call] | zx-sprite-data size defaults |
| D16 | Music on the Start screen only, never on the Desk; painting silent | [Designer's call] | standing music rule; a quiet desk |
| D17 | No names of the studio's people in the application; the Starting Sprite is unnamed beyond "MOWER" | [Designer's call] | TONE-01 caution |
| D19 | **owner** (2026-11-11): the Studio demonstrates what the book and podcast discuss: a Lessons list (DEMO-01) and the flicker demonstration (FLICK-01), slice 6 | owner | owner message |
| D20 | **owner** (2026-11-11): Joo (Hyun-joo Lee) presents a video advert when the Studio is ready, as well as the media kit | owner | owner message; implementation, not spec |
| D21 | Lessons follow the chapter's order; the FLICK-01 naive copy is the book's "green, hedgehog" made visible | [Designer's call] | the drawing chapter, Joo's podcast episode |
| D18 | Slices: 1 draw and flip; 2 onion, mirror, nudge, codes, checks; 3 masks; 4 colour and walking; 5 sheet, save, export | [Designer's call] | thin whole tool first |

| D22 | The Grid Cursor's square is kept with the other Desk settings across Title (STATE-02); DEV-01's placement rule applies to switching input on the Desk | [Designer's call] | tool trial m1 TT-5 |
| D23 | A stroke that changes nothing is not an Undo step (DRAW-02 "the last change" means the last change made) | [Designer's call] | tool trial m1 TT-2 |
| D24 | A refused control stays marked long enough to flash once (about 0.64 s), longer than `T-LIGHT-TIME` | [Designer's call] | tool trial m1 TT-6 |
| D25 | The Grid is numbered along its edges in base 16 (0-F), and the square readout uses the same digits | [Designer's call] | tool trial m1 TT-10 |
| D26 | The control for New reads COPY; the Start screen says the Desk opens on an example, or that the work is kept | [Designer's call] | tool trial m1 TT-9, TT-12, TT-13 |

| D27 | Controls may be grouped in drawers, one shown at a time, so long as every action keeps its own direct action; the Row Codes sit beside the rows they describe | [Designer's call] | M2 build, D-018 |
| D28 | The Checks list is shown as a count plus a step-through (each press shows the next problem, its frame and its squares) | [Designer's call] | M2 build, D-021 |

| D29 | On screen the onion skin is called tracing paper; "too alike" says how many more squares to change | [Designer's call] | M2 sit-beside trial |

| D30 | **owner** (2026-11-11): "The app is too focused on the mower. That can be one example that can be loaded but it should be possible to work with any Dalex sprite." Spec v0.2: the Library (LIB-01) of the studio's own figures; blank start; boxes up to 32 × 32 | owner | owner message |
| D31 | (Revised: the owner allowed All Disco's "Dan", 2026-11-11.) The Library takes figures from the studio's games (Mower Mayhem, Tiger Gorilla, Gold Master, WOLF, Antigravity; Wordris has none). Left out: WOLF's heads (drawn from real people), the dance demo's Joo poses (40 × 72, FLUX non-commercial), anything over 32 × 32 or 8 frames | [Designer's call] | tone and licence checks |

## Glossary additions

See the spec §13. "Colour Block" is the spec's word for an attribute cell; "Row Code" for a byte of sprite data.

## Target notes (for the target brief, not the spec)

- First target: ZX Spectrum 128K, Kempston mouse (A22 card; Kitchen Sink's reader) or keys/Kempston joystick.
- Picture Format = the Spectrum screen: 8×8 attribute cells, 8 colours plus BRIGHT, bytes of 8 pixels MSB left.
- Row Codes = `defb` bytes; export as `.spr` text or `defb` lines; save/load sheets to tape (SAVE/LOAD CODE), or
  through the harness.
- Data size = the zx-sprite-data budget formula (frames × mirror × shifts × height × bytes per row).
- Directional keys Q A O P, primary SPACE, secondary ENTER; one key per Desk action.

## Open frontier

None. Owner review after M1 (owner's words).
