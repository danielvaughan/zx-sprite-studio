#!/usr/bin/env python3
"""Does Export write what a game can include? (SHEET-01, D-063)

Export saves the current figure as a CODE file of assembler text: a comment line, then one " DEFB" line a
row, every frame's picture and then every frame's mask. In zx-game's Sim the save is trapped at
`tape_call.go` (as tape_check.py does), the text assembled with sjasmplus, and the bytes compared with the
figure's frames and masks in the sheet. Also checks the CODE header (the figure's name, the length) and
the data size readout (AC-28: a 16 x 16 figure of two frames, one facing, 8 positions: 2 x 1 x 8 x 16 x 3).

    export_check.py <milestone>     (run from game/ with ZX_PLUGINS_DIR and ZX_SJASMPLUS set; exit 1 on a fault)
"""
import os, subprocess, sys, tempfile
from pathlib import Path

sys.path.insert(0, str(Path(os.environ['ZX_PLUGINS_DIR']) / 'zx-game' / 'scripts'))
from sim import Sim, REG8  # noqa: E402

m = int(sys.argv[1])
SA = 0x04C2
bad = []


def step(s, keys=(), n=1):
    for _ in range(n):
        s.press(list(keys))
        s.run_frames(1)


def ret_ok(s):
    r = s.sim.registers
    sp = s.reg('SP')
    ra = s.read(sp) | s.read(sp + 1) << 8
    r[12] = (sp + 2) & 0xFFFF
    r[REG8['H']], r[REG8['L']] = ra >> 8, ra & 255
    r[REG8['F']] |= 1


def export(presses, name):
    s = Sim('.', m)
    blocks = []

    def on_save(sim):
        if sim.reg('HL') == SA:
            ix, de = sim.reg('IX'), sim.reg('DE')
            blocks.append((sim.reg('A'), bytes(sim.read(ix + i) for i in range(de))))
            ret_ok(sim)
    s.on_pc('tape_call.go', on_save)
    step(s, n=100)
    step(s, ['2'], 5)
    step(s, n=30)
    step(s, ['l'], 2)
    step(s, n=14)
    for _ in range(presses):
        step(s, ['a'], 1)
        step(s, n=5)
    step(s, n=20)
    step(s, ['ENTER'], 2)
    step(s, n=400)                               # its masks worked out
    step(s, ['9'], 2)
    step(s, n=40)
    size = s.read('sh_codes', size=2)
    step(s, ['x'], 2)
    step(s, n=40)
    w, h, nf = s.read('box_w'), s.read('box_h'), s.read('nframes')
    fb = w // 8 * h
    base = s.addr('frames_data')
    want = bytes(s.read(base + i) for i in range(nf * fb)) + bytes(s.read(base + 8 * fb + i) for i in range(nf * fb))
    if [f for f, _ in blocks] != [0, 255]:
        bad.append(f'{name}: blocks {[(f, len(d)) for f, d in blocks]}')
        return None
    hdr, text = blocks[0][1], blocks[1][1]
    if hdr[0] != 3 or int.from_bytes(hdr[11:13], 'little') != len(text):
        bad.append(f'{name}: header {hdr.hex()} for {len(text)} bytes')
    with tempfile.TemporaryDirectory() as d:
        src = Path(d) / 'fig.asm'
        src.write_bytes(text)
        Path(d, 'main.asm').write_text(' OUTPUT "out.bin"\n INCLUDE "fig.asm"\n')
        r = subprocess.run([os.environ['ZX_SJASMPLUS'], '--nologo', 'main.asm'], cwd=d, capture_output=True, text=True)
        out = Path(d) / 'out.bin'
        got = out.read_bytes() if out.exists() else b''
    if r.returncode or got != want:
        bad.append(f'{name}: sjasmplus exit {r.returncode}, {len(got)} bytes assembled, {len(want)} wanted '
                   f'({sum(x != y for x, y in zip(got, want))} differ) {r.stdout[-200:]}{r.stderr[-200:]}')
    else:
        first = text.split(b'\n')[0].decode()
        print(f'{name}: {w}X{h}, {nf} frames: {len(text)} bytes of text, header "{hdr[1:11].decode().strip()}", '
              f'assembled to {len(got)} bytes = pictures and masks; "{first}"')
    return w, h, nf, size


r = export(0, 'Mower')                          # the Library opens on the Mower
if r:
    w, h, nf, size = r
    if (w, h, nf) == (16, 16, 2) and size != 2 * 1 * 8 * 16 * 3:
        bad.append(f'AC-28: data size {size}, not 2 x 1 x 8 x 16 x 3 = 768')
    elif (w, h, nf) == (16, 16, 2):
        print(f'AC-28: data size {size} = 2 x 1 x 8 x 16 x 3 (and as many for the mask)')
export(21, 'Gorilla run')                       # 21 lines down: TIGER GORILLA, GORILLA, RUN 32X32
print(f"{'PASS' if not bad else 'FAIL'}  export: {'; '.join(bad) if bad else 'DEFB text assembles to the figure'}")
sys.exit(1 if bad else 0)
