#!/usr/bin/env python3
"""Do Library figures open whole, wherever they are stored? (D-053)

Opens ten figures spread through the Library (8 that bring their game's masks, from both banks, and 2 that
do not)
through the Library page in zx-game's Sim, and compares the sheet's frames, its masks (a figure that
brings its game's own), its mask style (Hand when it does) and its ink with src/gen's bank file.

    library_check.py <milestone>      (run from game/ with ZX_PLUGINS_DIR set; exit 1 on a difference)
"""
import os, sys
from pathlib import Path

sys.path.insert(0, str(Path(os.environ['ZX_PLUGINS_DIR']) / 'zx-game' / 'scripts'))
from sim import Sim  # noqa: E402

m = int(sys.argv[1])
b1 = Path('src/gen/library1.bin').read_bytes()
banks = {1: b1, 4: Path('src/gen/library4.bin').read_bytes()}
recs = [b1[i * 32:(i + 1) * 32] for i in range(len(b1) // 32) if b1[i * 32] in (0, 1, 2)]
lines = []
for i, r in enumerate(recs):
    if r[1] == 0:
        break
    lines.append(r)
figs = [i for i, r in enumerate(lines) if r[0] == 2]
masked = [i for i in figs if lines[i][31]]
plain = [i for i in figs if not lines[i][31]]
spread = [masked[k * (len(masked) - 1) // 7] for k in range(8)] + [plain[0], plain[-1]]   # 8 with masks, 2 without
bad = 0
for line in spread:
    r = lines[line]
    s = Sim('.', m)

    def step(k=()):
        s.press(list(k))
        s.run_frames(1)
    for f in range(145):
        step(['2'] if 100 <= f < 105 else ['l'] if 115 <= f < 117 else [])
    n = 0
    while s.read('lib_sel') != line and n < 400:
        step(['a'] if s.read('lib_sel') < line else ['q'])
        for _ in range(3):
            step()
        n += 1
    for _ in range(20):
        step()
    step(['ENTER'])
    step(['ENTER'])
    for _ in range(60):
        step()
    w, h, nf = r[23], r[24], r[25]
    fb = w // 8 * h
    off = (r[27] | r[28] << 8) - 0xC000
    base = s.addr('frames_data')
    got = bytes(s.read(base + i) for i in range(nf * fb))
    gm = bytes(s.read(base + 8 * fb + i) for i in range(nf * fb))
    bk = banks[r[26]]
    ok = (got == bk[off:off + nf * fb] and (not r[31] or gm == bk[off + nf * fb:off + 2 * nf * fb])
          and s.read('mstyle') == (3 if r[31] else 0) and s.read('fig_ink') == r[30])
    bad += not ok
    print(f"{'PASS' if ok else 'FAIL'}  line {line} bank {r[26]} {r[1:15].decode().strip()}: frames, masks, style {s.read('mstyle')}, "
          f"ink {s.read('fig_ink')}")
print(f"{'PASS' if not bad else 'FAIL'}  {len(spread)} Library figures open whole (banks 1 and 4; 8 with their game's masks)")
sys.exit(1 if bad else 0)
