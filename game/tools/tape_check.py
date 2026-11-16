#!/usr/bin/env python3
"""Does a sheet saved to tape come back whole? (SHEET-01, AC-27, D-062)

The Studio saves and loads through the ROM's SA-BYTES and LD-BYTES, called from `tape_call` by a
`jp (hl)` (`tape_call.go`). In zx-game's Sim that jump is trapped: a save's blocks are captured (flag,
start, bytes) and the jump made to return at once with the carry set; a load is fed the captured blocks
the same way. Real tape timing is not run (the ROM routines are the ROM's own).

  1. Machine A: the Mower from the Library, a second figure added on the Sheet page and drawn on, the
     sheet saved (S). Its blocks are written to build/sheet-check.tap (a real .tap: the owner can open it
     in Fuse and load it with the Studio).
  2. Machine B, from cold: the sheet loaded (L) from those blocks. Every figure is opened in turn on the
     Sheet page and its head, frames and masks compared with machine A's saved bytes; then a square is
     painted (the user can carry on drawing) and Undo takes it back.
  3. Machine B again: U after the load puts back the sheet before it (one Undo step).
  4. Machine C: a load broken off (BREAK) and a tape that is not a sheet leave the sheet as it was.
  5. The ROM's own routines, not trapped: a whole save (the MIC line toggles, the Studio comes back to the
     Sheet page) and a load with no tape, stopped with SPACE (the ROM's BREAK error path is caught: the
     page stays, the sheet as it was, SPACE not taken as a press afterwards).

    tape_check.py <milestone>       (run from game/ with ZX_PLUGINS_DIR set; exit 1 on any difference)
"""
import os, sys
from pathlib import Path

sys.path.insert(0, str(Path(os.environ['ZX_PLUGINS_DIR']) / 'zx-game' / 'scripts'))
from sim import Sim, REG8  # noqa: E402

m = int(sys.argv[1])
SA, LD = 0x04C2, 0x0556
bad = []


def step(s, keys=(), n=1):
    for _ in range(n):
        s.press(list(keys))
        s.run_frames(1)


def ret_from(s, ok):
    """At tape_call.go (jp (hl)): make the jump a return from the ROM routine, carry = ok."""
    r = s.sim.registers
    sp = s.reg('SP')
    ra = s.read(sp) | s.read(sp + 1) << 8
    r[12] = (sp + 2) & 0xFFFF
    r[REG8['H']], r[REG8['L']] = ra >> 8, ra & 255
    r[REG8['F']] = (r[REG8['F']] | 1) if ok else (r[REG8['F']] & 0xFE)


def to_desk(s):
    step(s, n=100)
    step(s, ['2'], 5)
    step(s, n=30)


def head(s):
    n = s.read('box_w') // 8 * s.read('box_h')
    return (bytes(s.read(s.addr('nframes') + i) for i in range(20)),
            bytes(s.read(s.addr('frames_data') + i) for i in range(16 * n)))


# ---- 1: machine A saves
a = Sim('.', m)
saved = []


def on_save(s):
    if s.reg('HL') != SA:
        return
    ix, de, flag = s.reg('IX'), s.reg('DE'), s.reg('A')
    saved.append((flag, bytes(s.read(ix + i) for i in range(de))))
    ret_from(s, True)


a.on_pc('tape_call.go', on_save)
to_desk(a)
step(a, ['l'], 2)
step(a, n=14)
step(a, ['ENTER'], 2)
step(a, n=120)                                  # the Mower, its masks worked out
step(a, ['9'], 2)
step(a, n=40)
step(a, ['n'], 2)                               # a second figure: FIGURE 2, on the Desk
step(a, n=60)
for k in ('p', 'p', 'a', 'SPACE', 'p', 'SPACE', 'a', 'SPACE'):  # three squares inked
    step(a, [k], 2)
    step(a, n=6)
step(a, n=60)
step(a, ['9'], 2)
step(a, n=40)
step(a, ['s'], 2)                               # S: save
step(a, n=40)
if [f for f, _ in saved] != [0, 255, 255] or a.read('sh_count') != 2:
    bad.append(f'save: blocks {[(f, len(d)) for f, d in saved]}, figures {a.read("sh_count")}')
else:
    tap = bytearray()
    for flag, data in saved:
        blk = bytes([flag]) + data
        x = 0
        for b in blk:
            x ^= b
        blk += bytes([x])
        tap += len(blk).to_bytes(2, 'little') + blk
    Path('build/sheet-check.tap').write_bytes(bytes(tap))
    print(f'saved: {len(saved)} blocks ({", ".join(str(len(d)) for _, d in saved)} bytes), build/sheet-check.tap')

blocka = saved[1][1] if len(saved) > 1 else b''
blockb = saved[2][1] if len(saved) > 2 else b''


# ---- 2 and 3: machine B loads
def loader(blocks, mode='ok'):
    feed = list(blocks)

    def on_load(s):
        if s.reg('HL') != LD:
            return
        if mode == 'break' or not feed:
            ret_from(s, False)
            return
        flag, data = feed.pop(0)
        ix, de = s.reg('IX'), s.reg('DE')
        ok = flag == s.reg('A') and len(data) == de
        if ok:
            s.write_bytes(ix, list(data))
        ret_from(s, ok)
    return on_load


b = Sim('.', m)
b.on_pc('tape_call.go', loader(saved))
to_desk(b)
step(b, ['9'], 2)
step(b, n=40)
step(b, ['l'], 2)                               # L: load
step(b, n=60)
if b.read('sh_count') != 2:
    bad.append(f'load: {b.read("sh_count")} figures, not 2')
heads = [blocka[5 + k * 20:5 + (k + 1) * 20] for k in range(2)]
for k in range(2):
    step(b, ['9'], 2) if not b.read('gn_open') else None
    step(b, n=30)
    while b.read('sh_sel') > k:
        step(b, ['q'], 2)
        step(b, n=4)
    while b.read('sh_sel') < k:
        step(b, ['a'], 2)
        step(b, n=4)
    step(b, ['ENTER'], 2)
    step(b, n=80)
    h, frames = head(b)
    want = heads[k]
    fb = want[0x05]
    if h[0] != want[0] or h[2:4] != want[2:4] or h[6:] != want[6:]:
        bad.append(f'figure {k + 1}: head {h.hex()} not {want.hex()}')
    if frames != blockb[k * 2048:k * 2048 + 16 * fb]:
        diff = sum(x != y for x, y in zip(frames, blockb[k * 2048:]))
        bad.append(f'figure {k + 1}: {diff} frame or mask bytes differ')
    else:
        name = bytes(h[6:14]).split(bytes(1))[0].decode()
        print(f'figure {k + 1} ({name}): head, frames and masks as saved')
inked = b.read('inked', size=2)
step(b, ['SPACE'], 2)                           # carry on drawing: paint, then Undo
step(b, n=30)
painted = b.read('inked', size=2)
step(b, ['u'], 2)
step(b, n=30)
if painted == inked or b.read('inked', size=2) != inked:
    bad.append(f'drawing after the load: inked {inked} -> {painted} -> {b.read("inked", size=2)}')
else:
    print(f'drawing after the load: inked {inked} -> {painted}, Undo -> {b.read("inked", size=2)}')

c = Sim('.', m)                                 # 3: Undo of the load
c.on_pc('tape_call.go', loader(saved))
to_desk(c)
step(c, ['9'], 2)
step(c, n=40)
step(c, ['l'], 2)
step(c, n=60)
step(c, ['t'], 2)
step(c, n=40)
n_loaded = c.read('sh_count')
step(c, ['u'], 2)
step(c, n=60)
if (n_loaded, c.read('sh_count')) != (2, 1):
    bad.append(f'Undo of the load: figures {n_loaded} -> {c.read("sh_count")}, not 2 -> 1')
else:
    print('Undo of the load: 2 figures -> 1 (the sheet before)')

for mode, blocks, why in (('break', saved, 'broken off'),
                          ('ok', [saved[0], (255, b'XX' + saved[1][1][2:])] + saved[2:], 'not a sheet')):
    d = Sim('.', m)                             # 4: nothing changes
    d.on_pc('tape_call.go', loader(blocks, mode))
    to_desk(d)
    before = head(d)
    step(d, ['9'], 2)
    step(d, n=40)
    step(d, ['l'], 2)
    step(d, n=60)
    if d.read('sh_count') != 1 or head(d) != before or not d.read('gn_open'):
        bad.append(f'load {why}: the sheet changed or the page closed')
    else:
        print(f'load {why}: the sheet as it was, the Sheet page still open')

e = Sim('.', m)                                 # 5: the ROM's own routines
to_desk(e)
step(e, ['9'], 2)
step(e, n=40)
mic = []
e.on_out(lambda t, port, val: mic.append(val & 8) if port & 1 == 0 else None)
step(e, ['s'], 2)
step(e, n=900)
edges = sum(1 for i in range(1, len(mic)) if mic[i] != mic[i - 1])
if edges < 10000 or e.read('gn_open') != 2 or e.read('state') != 1:
    bad.append(f'ROM save: {edges} MIC edges, page {e.read("gn_open")}')
else:
    print(f'ROM save: {edges} MIC edges, back on the Sheet page')
step(e, ['l'], 2)
step(e, n=200)
step(e, ['SPACE'], 20)
step(e, n=60)
if e.read('gn_open') != 2 or e.read('sh_count') != 1:
    bad.append(f'ROM load stopped with SPACE: page {e.read("gn_open")}, figures {e.read("sh_count")}')
else:
    print('ROM load with no tape, SPACE: stopped, the Sheet page and the sheet as they were')

print(f"{'PASS' if not bad else 'FAIL'}  tape: {'; '.join(bad) if bad else 'saved, loaded whole, drawn on, undone'}")
sys.exit(1 if bad else 0)
