#!/usr/bin/env python3
"""Is the RUB OUT, DRAW copy seen with the figure gone, and the DRAW ONCE copy never? (FLICK-01, AC-32, D-071)

Replays recipe m7-flicker (the Mower walking on the Test Ground with the demonstration on) in zx-game's Sim
and, on every frame of the walk, reads the two strips from the screen: the RUB OUT, DRAW copy (rows 4-9) and
the DRAW ONCE strip (rows 11-16). A strip whose every byte is the Ground's own pattern shows no figure at all:
the scenery shows where the figure is. Passes when that happens on some frames of the copy and on none of the
strip's (the figure is never rubbed out there: each byte changes once, straight to its new value).

    flick_check.py <milestone> [recipe]     (run from game/ with ZX_PLUGINS_DIR set)
"""
import json, os, sys
from pathlib import Path

sys.path.insert(0, str(Path(os.environ['ZX_PLUGINS_DIR']) / 'zx-game' / 'scripts'))
from sim import Sim  # noqa: E402

m = int(sys.argv[1])
stem = sys.argv[2] if len(sys.argv) > 2 else 'm7-flicker'
r = json.loads((Path('recipes') / f'{stem}.json').read_text())


def keys_at(spec, f):
    held = []
    for part in spec.split(';'):
        rng, key = part.split(':', 1)
        a, _, b = rng.partition('-')
        if int(a) <= f <= int(b or a):
            held += key.split('+')
    return held


def bare(s, scr, y0):
    pats = [s.read(s.addr('gn_pats') + s.read('gn_ground') * 8 + i) for i in range(8)]
    for y in range(48):
        yy = y0 + y
        base = ((yy & 0xC0) << 5) | ((yy & 7) << 8) | ((yy & 0x38) << 2)
        if any(scr[base + c] != pats[y & 7] for c in range(32)):
            return False
    return True


s = Sim('.', m)
walking = copy_gone = strip_gone = 0
for f in range(r['frames']):
    s.press(keys_at(r['keys'], f))
    s.run_frames(1)
    if s.read('gn_open') == 1 and s.read('fl_on') and s.read('wk_on') and s.read('play_on') and s.read('fl_valid'):
        walking += 1
        scr = s.screen_bytes()
        copy_gone += bare(s, scr, 32)
        strip_gone += bare(s, scr, 88)
ok = walking > 100 and copy_gone > 0 and strip_gone == 0
print(f"{'PASS' if ok else 'FAIL'}  {stem}: {walking} walking frames; the figure gone from RUB OUT, DRAW on "
      f'{copy_gone} of them, from DRAW ONCE on {strip_gone}')
sys.exit(0 if ok else 1)
