#!/usr/bin/env python3
"""Is a walking figure drawn as it walks? (m5-r1 and m5-r2 F-40: the logic walked, the strip never drew)

Replays each named recipe in zx-game's Sim and, on every frame the Test Ground is open with Walk on and the
flip-book turning, reads where the figure is to be (st_tx) and where it was last drawn (st_dx). Passes when
the drawn place took at least 10 different values (one for every 10 walking frames on a short walk) and
never fell more than 40 dots behind. Every 5th frame on which no snapshot is part drawn, the strip is also compared byte for byte and colour for colour with that
snapshot (screen_check's model), facing left included.

    walk_check.py <milestone> [recipe stem ...]   (default: the walking recipes; run from game/)
"""
import json, os, sys
from pathlib import Path

sys.path.insert(0, str(Path(os.environ['ZX_PLUGINS_DIR']) / 'zx-game' / 'scripts'))
from sim import Sim  # noqa: E402
sys.path.insert(0, str(Path(__file__).parent))
from screen_check import strip_errors  # noqa: E402

m = int(sys.argv[1])
stems = sys.argv[2:] or ['m5-walk', 'm5-walk32', 'm5-gorilla-walk', 'm5-click-walk']


def keys_at(spec, f):
    held = []
    for part in spec.split(';'):
        rng, key = part.split(':', 1)
        a, _, b = rng.partition('-')
        if int(a) <= f <= int(b or a):
            held += key.split('+')
    return held


bad = 0
for stem in stems:
    r = json.loads((Path('recipes') / f'{stem}.json').read_text())
    s = Sim('.', m)
    if r.get('pokes'):
        s.schedule_pokes(r['pokes'])
    seen, lag, frames, looked, left, errs = set(), 0, 0, 0, 0, []
    for f in range(r.get('frames', 400)):
        s.press(keys_at(r['keys'], f))
        s.run_frames(1)
        if s.read('gn_open') and s.read('wk_on') and s.read('play_on') and s.read('st_dvalid'):
            frames += 1
            seen.add(s.read('st_dx'))
            lag = max(lag, abs(s.read('st_tx') - s.read('st_dx')))
            if f % 5 == 0 and not s.read('st_busy'):
                looked += 1
                left += s.read('st_ddir') and s.read('st_dx') % 8 != 0
                e = strip_errors(s, s.screen_bytes(), moving=True)
                errs += [f'frame {f}: {x}' for x in e]
    ok = lag <= 40 and len(seen) >= min(10, frames // 10) and not errs
    bad += not ok
    print(f"{'PASS' if ok else 'FAIL'}  {stem}: {frames} walking frames, drawn at {len(seen)} places, "
          f'at most {lag} dots behind; strip compared {looked} times ({left} facing left off the byte grid)'
          + ('' if not errs else ': ' + '; '.join(errs[:4])))
sys.exit(1 if bad else 0)
