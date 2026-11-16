#!/usr/bin/env python3
"""Are the Studio's Ring, Shape and Box masks right? (MASK-01, D-044)

Puts figures straight into the sheet in zx-game's Sim (every Library figure, plus a spiral and a comb that
make the fill work hard), lets the Studio work their masks out, and compares each mask frame with a
reference worked out here: Shape = ink | paper not reachable from the box's edge through paper dots side by
side; Ring = Shape | the ink's dots side by side (T-RING 1).

    mask_check.py <milestone> [--style ring|shape] [--limit N]

Run from game/ with ZX_PLUGINS_DIR set. Exit 1 on any difference.
"""
import argparse, json, os, sys
from pathlib import Path

sys.path.insert(0, str(Path(os.environ['ZX_PLUGINS_DIR']) / 'zx-game' / 'scripts'))
from sim import Sim  # noqa: E402

ap = argparse.ArgumentParser()
ap.add_argument('milestone', type=int)
ap.add_argument('--style', choices=('ring', 'shape', 'box'), default='ring')
ap.add_argument('--limit', type=int, default=0)
a = ap.parse_args()


def to_rows(data, w, h):
    bpr = w // 8
    return [[(data[r * bpr + x // 8] >> (7 - x % 8)) & 1 for x in range(w)] for r in range(h)]


def reference(ink, w, h, ring):
    reached = [[0] * w for _ in range(h)]
    stack = [(x, y) for y in range(h) for x in range(w) if (x in (0, w - 1) or y in (0, h - 1)) and not ink[y][x]]
    for x, y in stack:
        reached[y][x] = 1
    while stack:
        x, y = stack.pop()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not ink[ny][nx] and not reached[ny][nx]:
                reached[ny][nx] = 1
                stack.append((nx, ny))
    m = [[1 if ink[y][x] or not reached[y][x] else 0 for x in range(w)] for y in range(h)]
    if ring:
        for y in range(h):
            for x in range(w):
                if ink[y][x]:
                    for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                        if 0 <= nx < w and 0 <= ny < h:
                            m[ny][nx] = 1
    return m


def pack(rows):
    out = bytearray()
    for r in rows:
        for b in range(0, len(r), 8):
            v = 0
            for i, bit in enumerate(r[b:b + 8]):
                v |= bit << (7 - i)
            out.append(v)
    return bytes(out)


def synthetic():
    w = h = 32                                      # a square spiral (a long snaking way in)
    g = [[0] * w for _ in range(h)]
    x0, y0, x1, y1 = 0, 0, w - 1, h - 1
    while x0 < x1 and y0 < y1:
        for x in range(x0, x1 + 1):
            g[y0][x] = 1
        for y in range(y0, y1 + 1):
            g[y][x1] = 1
        for x in range(x0 + 2, x1 + 1):
            g[y1][x] = 1
        for y in range(y0 + 2, y1 + 1):
            g[y][x0 + 2] = 1
        x0, y0, x1, y1 = x0 + 4, y0 + 2, x1 - 2, y1 - 2
    comb = [[1 if (y == 0 or (x % 3 == 0 and y < 22)) and x < 32 else 0 for x in range(32)] for y in range(24)]
    ring = [[1 if (x in (4, 27) and 4 <= y <= 27) or (y in (4, 27) and 4 <= x <= 27) else 0 for x in range(32)]
            for y in range(32)]
    return [('spiral', 32, 32, [pack(g)]), ('comb', 32, 24, [pack(comb)]), ('closed ring', 32, 32, [pack(ring)])]


lib = json.loads(Path('src/gen/library.json').read_text())
banks = {b: Path(f'src/gen/library{b}.bin').read_bytes() for b in (1, 4) if Path(f'src/gen/library{b}.bin').exists()}
figs = synthetic()
for f in lib['figures']:
    w, h = f['box']
    fb = w // 8 * h
    off = f['addr'] - 0xC000
    data = banks[f.get('bank', 1)]
    figs.append((f"{f['game']}/{f['character']}/{f['figure']}", w, h,
                 [data[off + i * fb: off + (i + 1) * fb] for i in range(f['frames'])]))
if a.limit:
    figs = figs[:a.limit]

s = Sim('.', a.milestone)
for f in range(110):                                 # to the Desk with keys
    s.press(['2'] if 100 <= f <= 104 else [])
    s.run_frames(1)
style = {'ring': 0, 'shape': 1, 'box': 2}[a.style]
bad = 0
for name, w, h, frames in figs:
    bpr, fb = w // 8, w // 8 * h
    s.write('box_w', w)
    s.write('box_h', h)
    s.write('bpr', bpr)
    s.write('fbytes', fb)
    s.write('nframes', len(frames))
    s.write('cur_frame', 0)
    s.write('mstyle', style)
    s.write('mk_style', style)
    s.write_bytes('frames_data', b''.join(frames))
    s.write('mk_need', 0xFF)
    s.write('mk_st', 0)
    for _ in range(400):
        s.run_frames(1)
        if s.read('mk_need') == 0 and s.read('mk_st') == 0:
            break
    else:
        print(f'FAIL  {name}: masks not finished in 400 frames')
        bad += 1
        continue
    for i, fr in enumerate(frames):
        want = bytes([255] * fb) if style == 2 else pack(reference(to_rows(fr, w, h), w, h, style == 0))
        got = bytes(s.read(s.addr('frames_data') + (8 + i) * fb + j) for j in range(fb))
        if want != got:
            diff = sum(bin(x ^ y).count('1') for x, y in zip(want, got))
            print(f'FAIL  {name} frame {i + 1}: {diff} dots differ')
            bad += 1
print(f"{'PASS' if not bad else 'FAIL'}  {len(figs)} figures ({a.style}); {bad} differences")
sys.exit(1 if bad else 0)
