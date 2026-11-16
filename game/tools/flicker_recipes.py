#!/usr/bin/env python3
"""Flicker on the recipes, not only the idle smoke run.

verify_game.py measures flicker on its smoke and latency runs, which for this tool sit on a
blank Desk. This runs each named recipe beam-logged from verify's cold-load snapshot
(build/verify-m<N>/cold.z80, from the last verify or partial verify) and applies verify's own
flicker_check, HARNESS_redraw frames exempt.

    flicker_recipes.py <milestone> [recipe stem ...]   (default: every recipe)

Run from game/ with ZX_PLUGINS_DIR set (the zx-game plugin's scripts). Exit 1 if any transient byte.
"""
import json, os, sys
from pathlib import Path

S = Path(os.environ['ZX_PLUGINS_DIR']) / 'zx-game' / 'scripts'
sys.path.insert(0, str(S))
import run_bot, verify_game as vg  # noqa: E402

m = int(sys.argv[1])
stems = sys.argv[2:] or sorted(p.stem for p in Path('recipes').glob('*.json'))
build = Path('build')
snap = build / f'verify-m{m}' / 'cold.z80'
sym = vg.load_sym(build / 'sprite-studio.sym') if hasattr(vg, 'load_sym') else None
if sym is None:
    sym = {}
    for line in (build / 'sprite-studio.sym').read_text().splitlines():
        if ': EQU ' in line:
            k, v = line.split(': EQU ')
            sym[k.strip()] = int(v.strip(), 16)
extra = ['HARNESS_redraw']
bad = 0
for stem in stems:
    recipe = json.loads((Path('recipes') / f'{stem}.json').read_text())
    out = build / f'flicker-m{m}' / stem
    run_bot.run(snap, sym, recipe, out, extra_watch=extra, beamlog=True)
    frames = json.loads((out / 'frames.json').read_text())
    r = vg.flicker_check([frames], len(run_bot.WATCH))
    ok = r.get('pass', r.get('ok'))
    print(f"{'PASS' if ok else 'FAIL'}  {stem}: {r.get('detail', r)}")
    bad += not ok
sys.exit(1 if bad else 0)
