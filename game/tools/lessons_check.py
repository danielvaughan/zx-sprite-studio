#!/usr/bin/env python3
"""Do the Lessons set the Desk up as the spec says, whatever came before? (DEMO-01, AC-31, D-072)

In zx-game's Sim, from the Desk with keys: one ink square drawn on the blank figure (the reader's), then
0 (the Lessons), the bar moved, ENTER. For each lesson from cold the state is read back and checked against
what DEMO-01 names; then every ordered pair (lesson A, then lesson B) must leave the same state as B from
cold (36 pairs); and after any lesson the reader's figure is still on the sheet with its square.

    lessons_check.py <milestone> [--shots DIR]     (run from game/ with ZX_PLUGINS_DIR set)
"""
import os, sys
from pathlib import Path

sys.path.insert(0, str(Path(os.environ['ZX_PLUGINS_DIR']) / 'zx-game' / 'scripts'))
from sim import Sim  # noqa: E402

m = int(sys.argv[1])
shots = Path(sys.argv[sys.argv.index('--shots') + 1]) if '--shots' in sys.argv else None
KEYS = ('gn_open', 'phase', 'layer', 'onion_on', 'play_on', 'cmode', 'wk_on', 'fl_on', 'mstyle', 'gn_ground',
        'nframes', 'box_w', 'last_event', 'sh_count', 'sh_cur')
# what each lesson must show (DEMO-01): the Mower (2 frames, 16 wide) and ...
WANT = [dict(gn_open=0, layer=0, gc_row=1),
        dict(gn_open=0, onion_on=1, play_on=1),
        dict(gn_open=1, gn_ground=0, fl_on=0, cmode=0),
        dict(gn_open=0, layer=1, mstyle=0),
        dict(gn_open=1, fl_on=1, wk_on=1, play_on=1),
        dict(gn_open=1, cmode=1, fl_on=0)]


def step(s, keys=(), n=1):
    for _ in range(n):
        s.press(list(keys))
        s.run_frames(1)


SNAP = Path('build') / f'lessons-desk-m{m}.z80'
_s = Sim('.', m)
step(_s, n=100)
step(_s, ['2'], 5)
step(_s, n=30)
step(_s, ['SPACE'], 2)                          # the reader's figure: one ink square
step(_s, n=20)
_s.snapshot(SNAP)


def cold():
    return Sim('.', m, snap=SNAP)


def lesson(s, k):
    if s.read('gn_open') == 1:
        step(s, ['t'], 2)                       # (from the Test Ground, back to the Desk first)
        step(s, n=40)
    step(s, ['0'], 2)
    step(s, n=30)
    while s.read('les_sel') != k:
        step(s, ['a'] if s.read('les_sel') < k else ['q'], 2)
        step(s, n=4)
    step(s, ['ENTER'], 2)
    step(s, n=120)


def state(s):
    st = {k: s.read(k) for k in KEYS}
    cap = bytes(s.read(s.addr('les_cap') + i) for i in range(32)).split(bytes(1))[0].decode()
    st['caption'] = cap
    return st


bad = []
alone = []
for k in range(6):
    s = cold()
    lesson(s, k)
    st = state(s)
    alone.append(st)
    if shots:
        shots.mkdir(parents=True, exist_ok=True)
        s.shot(shots / f'lesson-{k + 1}.png', scale=2)
    want = dict(WANT[k], nframes=2, box_w=16)
    miss = {n: (s.read(n), v) for n, v in want.items() if s.read(n) != v}
    if not st['caption'].startswith(f'{k + 1}:') or st['sh_count'] != 2 or st['sh_cur'] != 1:
        miss['caption/sheet'] = (st['caption'], st['sh_count'], st['sh_cur'])
    print(f"{'PASS' if not miss else 'FAIL'}  lesson {k + 1} from cold: {st['caption']!r}" + (f'  {miss}' if miss else ''), flush=True)
    if miss:
        bad.append(f'lesson {k + 1}')
pairs = 0
for a in range(6):
    for b in range(6):
        s = cold()
        lesson(s, a)
        lesson(s, b)
        st = state(s)
        diff = {n: (st[n], alone[b][n]) for n in st if st[n] != alone[b][n] and n != 'last_event'}
        if diff:
            bad.append(f'{a + 1} then {b + 1}: {diff}')
        else:
            pairs += 1
        if a == b == 5:                         # the reader's figure is still there
            if s.read('gn_open') == 1:
                step(s, ['t'], 2)
                step(s, n=40)
            step(s, ['9'], 2)
            step(s, n=30)
            while s.read('sh_sel'):
                step(s, ['q'], 2)
                step(s, n=4)
            step(s, ['ENTER'], 2)
            step(s, n=60)
            if s.read('inked', size=2) != 1 or s.read('sh_cur') != 0:
                bad.append(f'the reader\'s figure: inked {s.read("inked", size=2)}, current {s.read("sh_cur")}')
            else:
                print("PASS  the reader's figure kept on the sheet, its square still inked")
s = cold()                                      # m7-r1 F-80: drawing on the lessons' figure makes it the reader's
lesson(s, 1)
step(s, ['g'], 2)                               # (stop the flip-book) and ink a square
step(s, n=10)
step(s, ['p'], 2)
step(s, ['SPACE'], 2)
step(s, n=20)
drawn = s.read('inked', size=2)
lesson(s, 2)
if s.read('sh_count') != 3:
    bad.append(f'F-80: after drawing on the lessons\' figure the next lesson used it (figures {s.read("sh_count")})')
else:
    print(f"PASS  a drawing on the lessons' figure is kept: the next lesson took a figure of its own ({s.read('sh_count')} on the sheet)")
print(f'{"PASS" if pairs == 36 else "FAIL"}  {pairs} of 36 ordered pairs leave the state of the second lesson alone')
for b in bad[:10]:
    print('  ', b)
print(f"{'PASS' if not bad else 'FAIL'}  lessons")
sys.exit(1 if bad else 0)
