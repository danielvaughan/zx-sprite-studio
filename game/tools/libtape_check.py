#!/usr/bin/env python3
"""Do the Library's tapes load as sheets? (D-064)

For each tape in library-tapes/ (tools/build_library_tapes.py), its first file is fed to a fresh Studio's
L on the Sheet page through the trapped LD-BYTES (as tape_check.py does). Then every figure on the loaded
sheet is opened and compared with the built-in Library's bytes for it (src/gen): frames, its game's masks
when it brings them (style Hand), its ink.

    libtape_check.py <milestone>    (run from game/ with ZX_PLUGINS_DIR set; exit 1 on a difference)
"""
import json, os, sys
from pathlib import Path

sys.path.insert(0, str(Path(os.environ['ZX_PLUGINS_DIR']) / 'zx-game' / 'scripts'))
from sim import Sim, REG8  # noqa: E402

m = int(sys.argv[1])
LD = 0x0556
lib = json.loads(Path('src/gen/library.json').read_text())
banks = {b: Path(f'src/gen/library{b}.bin').read_bytes() for b in (1, 4)}
index = json.loads(Path('library-tapes/index.json').read_text())
bad = []


def blocks(tap):
    out, i = [], 0
    while i < len(tap):
        n = int.from_bytes(tap[i:i + 2], 'little')
        b = tap[i + 2:i + 2 + n]
        out.append((b[0], b[1:-1]))
        i += 2 + n
    return out


def step(s, keys=(), n=1):
    for _ in range(n):
        s.press(list(keys))
        s.run_frames(1)


def ret(s, ok):
    r = s.sim.registers
    sp = s.reg('SP')
    ra = s.read(sp) | s.read(sp + 1) << 8
    r[12] = (sp + 2) & 0xFFFF
    r[REG8['H']], r[REG8['L']] = ra >> 8, ra & 255
    r[REG8['F']] = (r[REG8['F']] | 1) if ok else (r[REG8['F']] & 0xFE)


for tape in sorted({i['tape'] for i in index}):
    feed = blocks(Path('library-tapes', tape).read_bytes())[:3]
    first = next(i for i in index if i['tape'] == tape)
    s = Sim('.', m)

    def on_load(sim):
        if sim.reg('HL') != LD:
            return
        if not feed:
            ret(sim, False)
            return
        flag, data = feed.pop(0)
        ok = flag == sim.reg('A') and len(data) == sim.reg('DE')
        if ok:
            sim.write_bytes(sim.reg('IX'), list(data))
        ret(sim, ok)
    s.on_pc('tape_call.go', on_load)
    step(s, n=100)
    step(s, ['2'], 5)
    step(s, n=30)
    step(s, ['9'], 2)
    step(s, n=40)
    step(s, ['l'], 2)
    step(s, n=60)
    n = s.read('sh_count')
    if n != len(first['figures']):
        bad.append(f'{tape}: {n} figures loaded, not {len(first["figures"])}')
        continue
    game_figs = [f for f in lib['figures'] if f"{f['character']}/{f['figure']} {f['box'][0]}X{f['box'][1]}"
                 in first['figures']][:n]
    for k, f in enumerate(game_figs):
        if s.read('gn_open') != 2:
            step(s, ['9'], 2)
            step(s, n=30)
        while s.read('sh_sel') != k:
            step(s, ['a'] if s.read('sh_sel') < k else ['q'], 2)
            step(s, n=4)
        step(s, ['ENTER'], 2)
        step(s, n=60)
        w, h = f['box']
        fb, nf = w // 8 * h, f['frames']
        data = banks[f['bank']][f['addr'] - 0xC000:]
        base = s.addr('frames_data')
        got = bytes(s.read(base + i) for i in range(nf * fb))
        gm = bytes(s.read(base + 8 * fb + i) for i in range(nf * fb))
        ok = (got == data[:nf * fb] and (not f['masks'] or gm == data[nf * fb:2 * nf * fb])
              and s.read('mstyle') == (3 if f['masks'] else 0) and s.read('fig_ink') == f['ink']
              and (s.read('box_w'), s.read('box_h'), s.read('nframes')) == (w, h, nf))
        if not ok:
            bad.append(f'{tape} figure {k + 1} ({f["character"]}/{f["figure"]}): not as the Library has it')
    print(f"{tape}: file {first['file']!r}, {n} figures loaded and opened, "
          f"{'as the Library has them' if not any(tape in b for b in bad) else 'DIFFERENT'}")
print(f"{'PASS' if not bad else 'FAIL'}  library tapes: {'; '.join(bad) if bad else 'each first file loads as a sheet'}")
sys.exit(1 if bad else 0)
