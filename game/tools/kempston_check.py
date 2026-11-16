#!/usr/bin/env python3
"""verify's kempston_absent, locally (it runs only in a full verify): play the same keys with an idle
Kempston stick and with nothing fitted (a floating port) in zx-game's Sim and compare HARNESS_updates
(and the state) frame for frame. M3 and M4 each lost a verify attempt to it (D-046).

    kempston_check.py <milestone> [frames]

Run from game/ with ZX_PLUGINS_DIR set. Exit 1 on the first difference.
"""
import os, sys
from pathlib import Path
sys.path.insert(0, str(Path(os.environ['ZX_PLUGINS_DIR']) / 'zx-game' / 'scripts'))
from sim import Sim  # noqa: E402

m = int(sys.argv[1])
n = int(sys.argv[2]) if len(sys.argv) > 2 else 420
keys = {f: ['2'] for f in range(100, 105)}
keys.update({f: ['p'] for f in range(200, 260)})
keys.update({f: ['SPACE'] for f in range(300, 302)})
runs = []
for floating in (False, True):
    s = Sim('.', m, floating_bus=floating)
    trace = []
    for f in range(n):
        s.press(keys.get(f, []))
        s.run_frames(1)
        trace.append((s.read('updates', size=2), s.read('state')))
    runs.append(trace)
for f, (a, b) in enumerate(zip(*runs)):
    if a != b:
        print(f'FAIL  kempston: frame {f}: idle stick {a}, nothing fitted {b}')
        sys.exit(1)
print(f'PASS  kempston: HARNESS_updates and state equal for {n} frames, idle stick and nothing fitted')
