#!/usr/bin/env python3
"""The Library's figures as tapes of their own (the owner's question, M6; D-064).

Each game's figures become sheet files, eight figures a file (T-FIGURES), in exactly the format the Studio
saves (D-062): a CODE header named after the game, block A (magic "SS", version 1, figures, current 0, the
eight heads) and block B (2,048 bytes a figure: its frames at their packed size, then its masks from frame
8). A figure that brings its game's mask (Hand) carries it; the others carry none and the Studio works one
out when the figure is opened (Ring). One .tap a game, its files one after another, in library-tapes/; the
Sheet page's L loads the next file on the tape. The Library stays built in as well.

Reads src/gen/library.json and the bank files from tools/build_library.py.

    build_library_tapes.py          (run from game/)
"""
import json
from pathlib import Path

SH_MAX, HEAD = 8, 20
MS_RING, MS_HAND = 0, 3
lib = json.loads(Path('src/gen/library.json').read_text())
banks = {b: Path(f'src/gen/library{b}.bin').read_bytes() for b in (1, 4)}
out = Path('library-tapes')
out.mkdir(exist_ok=True)


def block(flag, data):
    b = bytes([flag]) + data
    x = 0
    for c in b:
        x ^= c
    b += bytes([x])
    return len(b).to_bytes(2, 'little') + b


def sheet_file(name, figs):
    heads, frames = bytearray(), bytearray()
    for f in figs:
        w, h = f['box']
        bpr, fb, n = w // 8, w // 8 * h, f['frames']
        data = banks[f['bank']][f['addr'] - 0xC000:]
        name8 = f['character'][:8].encode('ascii')
        heads += bytes([n, 0, w, h, bpr, fb]) + name8.ljust(11, b'\0') + bytes(
            [f.get('gi', lib['games'].index(f['game'])), MS_HAND if f['masks'] else MS_RING, f['ink']])
        slot = bytearray(2048)
        slot[:n * fb] = data[:n * fb]
        if f['masks']:
            slot[8 * fb:8 * fb + n * fb] = data[n * fb:2 * n * fb]
        frames += slot
    heads = heads.ljust(SH_MAX * HEAD, b'\0')
    a = b'SS' + bytes([1, len(figs), 0]) + bytes(heads)
    hdr = bytes([3]) + name[:10].ljust(10).encode('ascii') + len(a).to_bytes(2, 'little') + (0x8000).to_bytes(2, 'little') * 2
    return block(0, hdr) + block(255, a) + block(255, bytes(frames))


index = []
for game in lib['games']:
    figs = [f for f in lib['figures'] if f['game'] == game]
    if not figs:
        continue
    tap = bytearray()
    parts = [figs[i:i + SH_MAX] for i in range(0, len(figs), SH_MAX)]
    for k, part in enumerate(parts):
        name = game[:8] if len(parts) == 1 else f'{game[:7]} {k + 1}'
        tap += sheet_file(name, part)
        index.append({'tape': f'{game.lower().replace(" ", "-")}.tap', 'file': name,
                      'figures': [f"{f['character']}/{f['figure']} {f['box'][0]}X{f['box'][1]}" for f in part]})
    (out / f'{game.lower().replace(" ", "-")}.tap').write_bytes(bytes(tap))
(out / 'index.json').write_text(json.dumps(index, indent=1) + '\n')
print(f'{len(index)} sheet files on {len(set(i["tape"] for i in index))} tapes in {out}/')
