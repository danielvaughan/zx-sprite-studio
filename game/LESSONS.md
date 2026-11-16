# Lessons

Generic tooling lessons from building Sprite Studio, for the zx-game pipeline and later games.

## A recipe that checks after the motion stops cannot see a draw that never happens during it (M5)

The walking test's bot recipe walked a 32 × 32 figure, stopped the flip-book, then checked the screen byte for
byte: it passed. Two playtest rounds found the figure never drew while it walked: first each new page restarted
the half-built picture, then each new page threw away the built picture before its turn to draw. Stopping let
the last picture through, so the end-state check was always clean.

For anything that moves continuously, check an invariant on every frame of the motion, not only the end state:
here, where the figure was last drawn must keep changing and stay close to where it is meant to be
(`tools/walk_check.py`). A per-frame `HARNESS_` or symbol trace in verify (for example "this value takes at
least N values while that flag is set") would catch the class in any game.

## Work split over updates needs a rule for what happens when the target moves mid-way (M5)

Late, never wrong, means a snapshot is finished and drawn before the next is begun. Restarting on every change
(or replacing a built snapshot not yet drawn) starves the screen whenever changes come faster than one
snapshot's work: a livelock that only shows on the biggest figure at the fastest speed.
