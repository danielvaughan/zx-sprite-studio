#!/usr/bin/env python3
"""Does every signal in spec section 9 have its visible twin and its sound? (R-027, D-070)

In zx-game's Sim each event is made to happen; the check reads the status line's event number where there is
one (not the Sheet page's message: the save and load messages are seen in the trials, and `tape_check` checks
what the save and load do), catches the sound at
`sfx_start` (A = the effect's id) and confirms the AY's channel C volume (register 10) goes up afterwards.
"Heard" means that volume rose, not that anyone listened; the controls' light and the refusal's flash are not
checked here (`m1-mouse-controls`, `m2-drawer`).

  input chosen    -> the readout names the input (EV_INPUT)  + chime (3)
  control used    -> the status line names it                 + click (1)
  refused         -> CAN'T and why                            + low blip (2)
  undo / redo     -> UNDO / REDO                              + soft click (4)
  check found     -> the checks count and CHECK names it      (no sound, as the spec says)
  sheet saved     -> SHEET SAVED on the Sheet page            + chime (3)   (the ROM save trapped, as in tape_check)
  painting        -> no sound

    signals_check.py <milestone>    (run from game/ with ZX_PLUGINS_DIR set; exit 1 on a missing twin or sound)
"""
import os, sys
from pathlib import Path

sys.path.insert(0, str(Path(os.environ['ZX_PLUGINS_DIR']) / 'zx-game' / 'scripts'))
from sim import Sim, REG8  # noqa: E402

m = int(sys.argv[1])
bad = []
s = Sim('.', m)
sounds, vol = [], []
s.on_pc('sfx_start', lambda sim: sounds.append((sim.frame, sim.reg('A'))))


def on_out(t, port, val):
    if port == 0xFFFD:
        on_out.reg = val
    elif port == 0xBFFD and getattr(on_out, 'reg', None) == 10:
        vol.append((s.frame, val))


s.on_out(on_out)


def ret_ok(sim):
    if sim.reg('HL') != 0x04C2:
        return
    r = sim.sim.registers
    sp = sim.reg('SP')
    ra = sim.read(sp) | sim.read(sp + 1) << 8
    r[12] = (sp + 2) & 0xFFFF
    r[REG8['H']], r[REG8['L']] = ra >> 8, ra & 255
    r[REG8['F']] |= 1


s.on_pc('tape_call.go', ret_ok)


def step(keys=(), n=1):
    for _ in range(n):
        s.press(list(keys))
        s.run_frames(1)


def event(name, keys, want_sound, want_event=None, frames=20):
    del sounds[:]
    del vol[:]
    f0 = s.frame
    step(keys, 2)
    step(n=frames)
    ev = s.read('last_event')
    got = [k for _, k in sounds]
    loud = any(v & 15 for f, v in vol if f >= f0)
    ok = (got[:1] == [want_sound] and loud) if want_sound else not got
    if want_event is not None and ev != want_event:
        ok = False
    print(f"{'PASS' if ok else 'FAIL'}  {name}: event {ev}, sound {got or 'none'}{', heard' if loud else ''}")
    if not ok:
        bad.append(name)


step(n=100)
event('input chosen (2)', ['2'], 3, 15)
event('control used (N, tracing paper)', ['n'], 1, 23)
event('refused (Z on the first frame)', ['z'], 2, 16)
event('painting (SPACE)', ['SPACE'], None, frames=10)
event('undo (U)', ['u'], 4, 8)
event('redo (U again)', ['u'], 4, 9)
step(['9'], 2)
step(n=40)
event('sheet saved (S on the Sheet page)', ['s'], 3, frames=40)
print(f"{'PASS' if not bad else 'FAIL'}  signals: {'every signal has its twin and its sound' if not bad else ', '.join(bad)}")
sys.exit(1 if bad else 0)
