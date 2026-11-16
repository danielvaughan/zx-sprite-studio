#!/usr/bin/env python3
"""Does the screen show what the program thinks it shows? (m3-r3: text and cells lost when a draw
was skipped.) Replays each recipe in zx-game's Sim, idles a while, then checks:

  - every character of every text panel in the current panel table (pd_table, pd_count): the screen
    cell holds the ROM font's glyph for the panel's `have` character, and have == want;
  - the Desk's Grid: nothing queued or pending (sq_n, row_pend, row_dirty) and grid_have == grid_want.

    screen_check.py <milestone> [recipe stem ...]   (default: every recipe; run from game/)

Also reports the settle time: frames from the recipe's last key (or poke) until the screen first matches
(checked every 2 frames), the M3 gate's measure of "a refresh late at worst". Exit 1 on any mismatch. Needs ZX_PLUGINS_DIR (the private zx-plugins).
"""
import json, os, sys
from pathlib import Path

sys.path.insert(0, str(Path(os.environ['ZX_PLUGINS_DIR']) / 'zx-game' / 'scripts'))
from sim import Sim  # noqa: E402

IDLE = 100


def keys_at(spec, f):
    held = []
    for part in spec.split(';'):
        rng, key = part.split(':', 1)
        a, _, b = rng.partition('-')
        if int(a) <= f <= int(b or a):
            held += key.split('+')
    return held


def cell(scr, row, col):
    return bytes(scr[((row & 0x18) << 8) | ((row & 7) << 5) | col | (line << 8)] for line in range(8))


def under_arrow(s, col, row):
    """The XOR Arrow (8 dots wide, CUR_H 10 rows, hotspot at its top left) covers this character cell."""
    if s.read('input_dev') != 1 or not s.read('cur_drawn'):
        return False
    x, y = s.read('drawn_x'), s.read('drawn_y')
    return x // 8 <= col <= (x + 7) // 8 and y // 8 <= row <= (y + 9) // 8


def ground_errors(s, scr):
    """The Test Ground (AC-23): each panel's bytes against COPY, MIX and MASK+MIX worked out here."""
    if s.read('fl_on'):
        return fl_errors(s, scr) + strip_errors(s, scr)
    if s.read('gn_need') or s.read('gn_busy') or s.read('mk_need') or s.read('mk_st'):
        return ['ground: panels still to draw']
    errs = []
    bpr, h, fb = s.read('bpr'), s.read('box_h'), s.read('fbytes')
    fr = s.read('gn_frame')
    base = s.addr('frames_data')
    pic = [s.read(base + fr * fb + i) for i in range(fb)]
    msk = [s.read(base + (8 + fr) * fb + i) for i in range(fb)]
    pats = [s.read(s.addr('gn_pats') + s.read('gn_ground') * 8 + i) for i in range(8)]
    ox, oy = (6 - bpr) // 2, (48 - h) // 2
    for p, col in enumerate((2, 12, 22)):
        for y in range(48):
            g = pats[y & 7]
            for b in range(6):
                v = g
                fy, fx = y - oy, b - ox
                if 0 <= fy < h and 0 <= fx < bpr:
                    i, m = pic[fy * bpr + fx], msk[fy * bpr + fx]
                    v = (i, g | i, (g & ~m & 255) | i)[p]
                yy = 32 + y
                addr = ((yy & 0xC0) << 5) | ((yy & 7) << 8) | ((yy & 0x38) << 2) | (col + b)
                if scr[addr] != v:
                    errs.append(f'ground panel {p} row {y} byte {b}: {scr[addr]:02x} not {v:02x}')
    return errs[:8] + strip_errors(s, scr)


def fl_errors(s, scr):
    """The RUB OUT, DRAW copy (FLICK-01, rows 4-9): settled, the figure at its last drawn place (fl_ox, fl_oy,
    fl_odir, fl_of) MASK+MIX over the Ground, the whole copy in the Ground's colours (Keep)."""
    if s.read('fl_state') or not s.read('fl_valid'):
        return ['rub-out copy: still to draw']
    w, h, bpr, fb = s.read('box_w'), s.read('box_h'), s.read('bpr'), s.read('fbytes')
    bx, by, bd, bf = (s.read(n) for n in ('fl_ox', 'fl_oy', 'fl_odir', 'fl_of'))
    base = s.addr('frames_data')
    gr = s.read('gn_ground')
    pats = [s.read(s.addr('gn_pats') + gr * 8 + i) for i in range(8)]

    def dots(frame):
        data = [s.read(base + frame * fb + i) for i in range(fb)]
        rows = [[(data[r * bpr + x // 8] >> (7 - x % 8)) & 1 for x in range(w)] for r in range(h)]
        return [r[::-1] for r in rows] if bd else rows
    ink, msk = dots(bf), dots(8 + bf)
    errs = []
    for y in range(48):
        for col in range(32):
            if under_arrow(s, col, 4 + y // 8):
                continue
            v = 0
            for b in range(8):
                x, fy = col * 8 + b, y - by
                fx = x - bx
                i = ink[fy][fx] if 0 <= fx < w and 0 <= fy < h else 0
                mk = msk[fy][fx] if 0 <= fx < w and 0 <= fy < h else 0
                v |= (((pats[y & 7] >> (7 - b)) & 1 and not mk) or i) << (7 - b)
            yy = 32 + y
            addr = ((yy & 0xC0) << 5) | ((yy & 7) << 8) | ((yy & 0x38) << 2) | col
            if scr[addr] != v:
                errs.append(f'rub-out copy row {y} byte {col}: {scr[addr]:02x} not {v:02x}')
    gattr = s.read(s.addr('gn_attrs') + gr)
    for cy in range(6):
        for cx in range(32):
            if scr[0x1800 + (4 + cy) * 32 + cx] != gattr:
                errs.append(f'rub-out copy cell ({cx},{cy}) not the Ground\'s colours')
    return errs[:8]


def strip_errors(s, scr, moving=False):
    """The colour strip (CLASH-01, MOVE-01): the figure MASK+MIX at (st_bx, st_by), mirrored facing left,
    over the Ground in Colour Blocks; the touched cells in the mode's colours, the clashes flashing."""
    busy = [n for n in (('st_busy',) if moving else ('st_busy', 'st_go', 'st_bld', 'st_dirty', 'st_full', 'st_bfull'))
            if s.read(n)]
    if busy or not s.read('st_dvalid'):
        return ['strip: still to draw (%s)' % ','.join(busy or ['not drawn'])]
    tx, ty, td = (s.read(n) for n in ('st_tx', 'st_ty', 'st_tdir'))
    bx, by, bd, bf = (s.read(n) for n in (('st_dx', 'st_dy', 'st_ddir', 'st_df') if moving
                                          else ('st_bx', 'st_by', 'st_bdir', 'st_bf')))
    if not moving and (tx, ty, td, s.read('gn_frame')) != (bx, by, bd, bf):
        return ['strip: the figure is not yet where it is to be']
    errs = []
    w, h, bpr, fb = s.read('box_w'), s.read('box_h'), s.read('bpr'), s.read('fbytes')
    base = s.addr('frames_data')
    gr = s.read('st_dg') if moving else s.read('gn_ground')
    pats = [s.read(s.addr('gn_pats') + gr * 8 + i) for i in range(8)]

    def dots(frame):
        data = [s.read(base + frame * fb + i) for i in range(fb)]
        rows = [[(data[r * bpr + x // 8] >> (7 - x % 8)) & 1 for x in range(w)] for r in range(h)]
        return [r[::-1] for r in rows] if bd else rows
    ink, msk = dots(bf), dots(8 + bf)

    def at(grid, x, y):
        fx, fy = x - bx, y - by
        return grid[fy][fx] if 0 <= fx < w and 0 <= fy < h else 0
    for y in range(48):
        g = pats[y & 7]
        for col in range(32):
            if under_arrow(s, col, 11 + y // 8):
                continue
            v = 0
            for b in range(8):
                x = col * 8 + b
                gd = (g >> (7 - b)) & 1
                d = (gd and not at(msk, x, y)) or at(ink, x, y)
                v |= d << (7 - b)
            yy = 88 + y
            addr = ((yy & 0xC0) << 5) | ((yy & 7) << 8) | ((yy & 0x38) << 2) | col
            if scr[addr] != v:
                errs.append(f'strip row {y} byte {col}: {scr[addr]:02x} not {v:02x}')
    gattr = s.read(s.addr('gn_attrs') + gr)
    mode, fink = (s.read('st_dmode'), s.read('st_dink')) if moving else (s.read('cmode'), s.read('fig_ink'))
    mattr = (gattr, (gattr & 0xF8) | fink, 0x40 | fink)[mode]
    changed = mattr != gattr
    if fink >= 5 and (gattr >> 3) & 7 >= 5:      # hard to see: the box's cells marked, not bright
        mattr &= ~0x40
    cx0, cx1, cy0, cy1 = bx // 8, (bx + w - 1) // 8, by // 8, (by + h - 1) // 8
    clashes = 0
    for cy in range(6):
        for cx in range(32):
            want = gattr
            if cx0 <= cx <= cx1 and cy0 <= cy <= cy1:
                want = mattr
                clash = changed and any(
                    (pats[r] >> (7 - b)) & 1 and not at(msk, cx * 8 + b, cy * 8 + r) for r in range(8) for b in range(8))
                if clash:
                    want |= 0x80
                    clashes += 1
            got = scr[0x1800 + (11 + cy) * 32 + cx]
            if got != want:
                errs.append(f'strip cell ({cx},{cy}) colour {got:02x} not {want:02x}')
    cells = (cx1 - cx0 + 1) * (cy1 - cy0 + 1)
    if not moving and (s.read('st_ncx') * s.read('st_ncy') != cells or s.read('st_clash') != clashes):
        errs.append(f"strip readout: cells {s.read('st_ncx') * s.read('st_ncy')} clashes {s.read('st_clash')}, "
                    f'worked out {cells} and {clashes}')
    return errs[:8]


def check(s):
    errs = []
    mem = lambda a, n=1: bytes(s.read(a + i) for i in range(n))  # noqa: E731
    scr = s.screen_bytes()
    rom = lambda ch: bytes(s.read(0x3D00 + (ch - 32) * 8 + i) for i in range(8))  # noqa: E731
    if s.read('state') == 1 and s.read('gn_open') == 1:
        errs += ground_errors(s, scr)
    table = s.read('pd_table', size=2)
    for p in range(s.read('pd_count') if s.read('state') == 1 else 0):   # panels: the Desk, Library, Test Ground
        e = table + 8 * p
        want = s.read(e, size=2)
        have = s.read(e + 2, size=2)
        col, row, w, h = (s.read(e + 4 + i) for i in range(4))
        for r in range(h):
            for c in range(w):
                i = r * w + c
                hv, wv = s.read(have + i), s.read(want + i)
                if hv != wv:
                    errs.append(f'panel {p} ({col + c},{row + r}): want {chr(wv)!r} have {chr(hv)!r}')
                elif under_arrow(s, col + c, row + r):
                    continue                   # the pointer's Arrow is drawn over this cell (XOR)
                elif 32 <= hv < 128 and cell(scr, row + r, col + c) != rom(hv):
                    errs.append(f'panel {p} ({col + c},{row + r}): screen is not {chr(hv)!r}')
    if s.read('state') == 1 and not s.read('lib_open') and not s.read('gn_open'):
        if s.read('layer') and (s.read('mk_need') or s.read('mk_st')):
            errs.append('mask layer: masks still to work out')   # (D-049: the settle includes the masks)
        if s.read('sq_n'):
            errs.append('grid: cells still queued')
        if s.read('img_need', size=2) & (0xFFFD if s.read('play_on') else 0xFFFF):   # (PLAY: every page)
            errs.append('pictures: cards or strip still to draw')
        pend = mem(s.addr('row_pend'), 16) + mem(s.addr('row_dirty'), 16)
        if any(pend):
            errs.append('grid: rows still pending')
        gw, gh = mem(s.addr('grid_want'), 512), mem(s.addr('grid_have'), 512)
        bad = [i for i in range(512) if gw[i] != gh[i]]
        if bad:
            errs.append(f'grid: {len(bad)} cells have != want (first {bad[0]})')
    return errs


def main():
    m = int(sys.argv[1])
    stems = sys.argv[2:] or sorted(p.stem for p in Path('recipes').glob('*.json'))
    fails = 0
    settles = []
    for stem in stems:
        r = json.loads((Path('recipes') / f'{stem}.json').read_text())
        s = Sim('.', m)
        if r.get('pokes'):
            s.schedule_pokes(r['pokes'])
        total = r.get('frames', 400)
        last = max(int(part.split(':')[0].split('-')[-1]) for part in r['keys'].split(';'))
        last = max(last, max((p['frame'] for p in r.get('pokes', [])), default=0))
        settle = None
        for f in range(max(total, last + 300) + IDLE):
            s.press(keys_at(r['keys'], f) if f < total else [])
            s.run_frames(1)
            if settle is None and f > last and (f - last) % 2 == 0 and not check(s):
                settle = f - last          # settle: frames from the last key until the screen matches
        for _ in range(20):                # (a cell queued for one update, e.g. the cursor's flash, is no fault)
            errs = check(s)
            if not errs:
                break
            s.run_frames(1)
        settles.append((settle if settle is not None else 999, stem))
        print(f"{'PASS' if not errs else 'FAIL'}  {stem}: settle {settle} frames after the last key" +
              ('' if not errs else ': ' + '; '.join(errs[:6]) + (f' (+{len(errs) - 6} more)' if len(errs) > 6 else '')))
        fails += bool(errs)
    print('longest settle: %d frames (%s)' % max(settles))
    sys.exit(1 if fails else 0)


if __name__ == '__main__':
    main()
