#!/usr/bin/env python3
"""Build the Sprite Studio Library (LIB-01) from the studio's own games' .spr files.

Reads each game's figures with zx-sprite-data's own parser (spectrum_sprites.parse), turns them into
Library figures and writes:

    src/gen/library.bin   the line records and the frames, laid out for banks 1, 3, 4 and 6 at $C000
    src/gen/library.inc   equates: LIB_LINES, LIB_FIGURES, the banks used
    src/gen/library.json  the manifest: every figure, its source file and sha256, and what was left out and why

A figure is one @anim (its frames, in order), or a file's sprites in no @anim, grouped by size, at most
T-FRAMES (8) a figure. Its box is the smallest in T-BOX-SIZES that holds it; the art sits top left.
'#' is ink; '.' and 'o' (the outline the mask clears) are paper. A figure larger than 32 x 32 or with
more than 8 frames is not offered (spec LIB-01). A figure drawn with 'o' brings its game's own mask
(what the game clears: zx-sprite-data's planes() in the game's --mask mode, MASK_MODE), stored after its frames and opened as a Hand mask (M5); the others
have theirs worked out by the Studio. Its ink colour is its first sprite's ink= (else red, 2: CLASH-01).

The list the Desk shows: a heading line for each game, a line for each character (file) and a line for
each figure. Each line is a 32-byte record:

    +0  kind: 0 game, 1 character, 2 figure
    +1  14 characters of text (spaces after)
    +15 the character's name, 8 letters (zero after), figure lines only
    +23 box across, +24 box down, +25 frames
    +26 the bank holding the frames, +27 their address (word)
    +29 index of the game (0-based), +30 the ink colour, +31 1 if the game's masks follow the frames

Usage: build_library.py [--games-root <dir>] [--parser <dir of spectrum_sprites.py>]
The games root defaults to the folder holding this repository (the game repositories sit beside it);
the parser defaults to $ZX_PLUGINS_DIR, else ../zx-plugins/plugins beside this repository. Run from game/. Standard library only.
"""
import argparse, glob, hashlib, json, os, sys
from pathlib import Path

BOXES = [(8, 8), (16, 8), (8, 16), (16, 16), (16, 24), (24, 16), (24, 24), (24, 32), (32, 16), (32, 24), (32, 32)]
MAX_FRAMES = 8
BANKS = [1, 4]                       # bank 4 also holds the Start picture, after the Library (main.asm)
BANK_ROOM = {1: 16384, 4: 16384 - 3328}
BANK_SIZE = 16384
REC = 32

# The published games, in the order the Library lists them, and the files each offers (spec notes D31).
GAMES = [
    ('MOWER MAYHEM', 'zx-mower-mayhem', ['assets/sprites/*.spr']),
    ('TIGER GORILLA', 'zx-tiger-gorilla', ['assets/sprites/*/final/*.spr']),
    ('GOLD MASTER', 'zx-gold-master', ['assets/sprites/*.spr']),
    ('ANTIGRAVITY', 'zx-antigravity', ['assets/sprites/*.spr']),
    ('ALL DISCO', 'zx-all-disco-all-dan', ['assets/sprites/*.spr']),
    ('WOLF', 'zx-wolf', ['assets/sprites/*.spr']),
]
# How each game builds its masks (its sprite builds' --mask): outline = ink, 'o' and a one-dot halo round
# the ink; art = ink and 'o' (the games' review records and build scripts)
MASK_MODE = {'zx-antigravity': 'art'}
# Left out, with the reason (TONE-01: none drawn from a real person; the studio's own figures only).
LEFT_OUT = {
    'zx-mower-mayhem/assets/sprites/refusal-stub.spr': 'a test stub, not a figure',
    'zx-wolf/assets/sprites/heads.spr': 'drawn from real people (spec notes D31)',
    'zx-wolf/assets/sprites/heads-m4.spr': 'drawn from real people (spec notes D31)',
    'zx-wolf/assets/sprites/coach-benny.spr': "the coaches carry real people's first names (WOLF T-009)",
    'zx-wolf/assets/sprites/coach-stevo.spr': "the coaches carry real people's first names (WOLF T-009)",
    'zx-wolf/assets/sprites/coach-tim.spr': "the coaches carry real people's first names (WOLF T-009)",
    'zx-wolf/assets/sprites/body-standard-m4.spr': 'habits of named regulars, some after real people (WOLF T-009)',
    'zx-wolf/assets/sprites/scene-warmup.spr': 'the coaches leading (real first names, WOLF T-009)',
    'zx-wolf/assets/sprites/scene-warmup-m3.spr': 'the coaches leading (real first names, WOLF T-009)',
    'zx-wolf/assets/sprites/scene-finisher.spr': 'a named regular (WOLF T-009)',
}
# Character names the file stem would spell badly in 8 letters
NAMES = {
    'camera-drone': 'DRONE', 'parrot-scarlet': 'SCARLET', 'gorilla-walk': 'GORILLA', 'photographer': 'SNAPPER',
    'fx-boost-jet': 'JET', 'fx-fart-cloud': 'CLOUD', 'fx-alert': 'ALERT', 'fx-flash': 'FLASH', 'fx-stars': 'STARS',
    'icons-modes': 'MODES', 'station-objects': 'STATION', 'robin-suit': 'ROBIN', 'sentry-drone': 'SENTRY',
    'coolant-laser': 'LASER', 'body-standard': 'BODY', 'body-standard-m2': 'GYM', 'cat-peek': 'CAT PEEK',
    'stop-arc': 'STOP ARC', 'omnibot': 'ROBOT', 'hedgehog': 'HEDGEHOG', 'fx': 'EFFECTS', 'crocodile': 'CROC',
}
# Action names the anim label would spell badly in 8 letters
ACTIONS = {'knuckle_run': 'RUN', 'catpeek': 'PEEK', 'mo_walk_side': 'SIDEWAYS', 'mo_walk_down': 'WALK',
           'chestpress': 'PRESS', 'joo_dance': 'JOO', 'dez_dance': 'DEZ', 'bird_peck_anim': 'PECK',
           'plate_bounce': 'PLATE'}


def char_name(stem):
    if stem in NAMES:
        return NAMES[stem]
    if stem.startswith('props'):
        return 'PROPS'
    return stem.replace('-', ' ').upper()[:8]


def action_name(anim, stem):
    if anim in ACTIONS:
        return ACTIONS[anim]
    words = [w for w in anim.split('_') if w and w != 'anim']
    stem_words = set(stem.replace('-', '_').split('_')) | {stem.replace('-', '')[:3], stem.replace('-', '')[:4]}
    if len(words) > 1 and (words[0] in stem_words or len(words[0]) <= 3):
        words = words[1:]
    words = [w for w in words if w not in stem_words] or words
    out = ''
    for w in words:
        nxt = (out + ' ' + w).strip()
        if len(nxt) > 8:
            break
        out = nxt
    return (out or words[0][:8]).upper()


def box_for(w, h):
    fits = [b for b in BOXES if b[0] >= w and b[1] >= h]
    return min(fits, key=lambda b: (b[0] * b[1], b)) if fits else None


def frame_bytes(art, box):
    bw, bh = box
    bpr = bw // 8
    out = bytearray(bpr * bh)
    for y, row in enumerate(art):
        for x, c in enumerate(row):
            if c == '#':
                out[y * bpr + x // 8] |= 0x80 >> (x % 8)
    return bytes(out)


def mask_bytes(ss, art, box, mode):
    bw, bh = box
    bpr = bw // 8
    out = bytearray(bpr * bh)
    _, cover = ss.planes(art, mode, False)
    for y, row in enumerate(cover):
        for x, c in enumerate(row):
            if c:
                out[y * bpr + x // 8] |= 0x80 >> (x % 8)
    return bytes(out)


def ink_of(text, name):
    """The sprite's explicit ink= (the parser's default, white, is not the figure's), else red."""
    for line in text.splitlines():
        parts = line.split()
        if len(parts) > 1 and parts[0] == '@sprite' and parts[1] == name:
            for o in parts[2:]:
                if o.startswith('ink=') and o[4:].isdigit() and int(o[4:]) < 8:
                    return int(o[4:])
    return 2


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    games_root = Path(__file__).resolve().parents[3]   # game/tools/ -> the repository -> its parent
    plugins = os.environ.get('ZX_PLUGINS_DIR') or str(games_root / 'zx-plugins' / 'plugins')
    ap.add_argument('--games-root', default=str(games_root))
    ap.add_argument('--parser', default=os.path.join(plugins, 'zx-assets/skills/zx-sprite-data/scripts'))
    a = ap.parse_args(argv)
    sys.path.insert(0, a.parser)
    import spectrum_sprites as ss

    root = Path(a.games_root)
    lines, figures, left, sources = [], [], [], []
    for gi, (game, repo, pats) in enumerate(GAMES):
        files = sorted({f for p in pats for f in glob.glob(str(root / repo / p))})
        game_lines = []
        seen_by_char = {}
        for f in files:
            rel = os.path.relpath(f, root)
            if rel in LEFT_OUT:
                left.append({'source': rel, 'why': LEFT_OUT[rel]})
                continue
            text = Path(f).read_text()
            anims, poses = [], []
            sprites = ss.parse(text, anims, poses)
            by_name = {s['name']: s for s in sprites}
            stem = Path(f).stem
            cname = char_name(stem)
            groups = []
            used = set()
            for an in anims:
                frames = [by_name[n] for n in an['frames'] if n in by_name]
                if len(frames) != len(an['frames']):
                    left.append({'source': rel, 'figure': an['name'], 'why': 'made of poses, not frames'})
                    continue
                used |= set(an['frames'])
                groups.append((action_name(an['name'], stem), frames))
            loose = [s for s in sprites if s['name'] not in used]
            by_size = {}
            for s in loose:
                by_size.setdefault((len(s['art'][0]), len(s['art'])), []).append(s)
            sets = []
            for size, ss_ in by_size.items():
                for i in range(0, len(ss_), MAX_FRAMES):
                    sets.append(ss_[i:i + MAX_FRAMES])
            for i, fr in enumerate(sets):
                groups.append(('POSES' if len(sets) == 1 else 'SET %d' % (i + 1), fr))
            figs = []
            seen = seen_by_char.setdefault(cname, set())   # files of one character share a heading
            for act, frames in groups:
                w = max(len(s['art'][0]) for s in frames)
                h = max(len(s['art']) for s in frames)
                box = box_for(w, h)
                why = None
                if box is None:
                    why = 'larger than 32 x 32 (%d x %d)' % (w, h)
                elif len(frames) > MAX_FRAMES:
                    why = 'more than 8 frames'
                if why:
                    left.append({'source': rel, 'figure': act, 'why': why})
                    continue
                name = act
                n = 2
                while name in seen:
                    name = (act[:6] + ' %d' % n)[:8]
                    n += 1
                seen.add(name)
                data = b''.join(frame_bytes(s['art'], box) for s in frames)
                outlined = any('o' in r for s in frames for r in s['art'])
                if outlined:
                    data += b''.join(mask_bytes(ss, s['art'], box, MASK_MODE.get(repo, 'outline')) for s in frames)
                figs.append({'game': game, 'character': cname, 'figure': name, 'box': box,
                             'frames': len(frames), 'source': rel, 'masks': outlined,
                             'ink': ink_of(text, frames[0]['name']),
                             'sprites': [s['name'] for s in frames], 'data': data, 'gi': gi})
            if figs:
                sources.append({'source': rel, 'sha256': hashlib.sha256(text.encode()).hexdigest()})
                if not any(k == 'char' and t == cname for k, t, _ in game_lines):
                    game_lines.append(('char', cname, None))
                for fg in figs:
                    game_lines.append(('fig', fg['figure'], fg))
                    figures.append(fg)
        if game_lines:
            lines.append(('game', game, None))
            lines.extend(game_lines)

    # lay out: the line records first (bank 1), then the frames, never across a bank's end
    recs = len(lines) * REC
    banks = {b: bytearray() for b in BANKS}
    banks[BANKS[0]] += bytes(recs)
    for fg in figures:
        for b in BANKS:
            if len(banks[b]) + len(fg['data']) <= BANK_ROOM[b]:
                fg['bank'], fg['addr'] = b, 0xC000 + len(banks[b])
                banks[b] += fg['data']
                break
        else:
            raise SystemExit('the Library does not fit in banks %s' % BANKS)
    table = bytearray()
    for kind, text, fg in lines:
        r = bytearray(REC)
        r[0] = {'game': 0, 'char': 1, 'fig': 2}[kind]
        t = text if kind != 'fig' else '%-8s %dX%d' % (text, fg['box'][0], fg['box'][1])
        r[1:15] = t[:14].ljust(14).encode('ascii')
        if fg:
            r[15:23] = fg['character'][:8].encode('ascii').ljust(8, b'\0')
            r[23], r[24], r[25] = fg['box'][0], fg['box'][1], fg['frames']
            r[26] = fg['bank']
            r[27], r[28] = fg['addr'] & 255, fg['addr'] >> 8
            r[29] = fg['gi']
            r[30] = fg['ink']
            r[31] = 1 if fg['masks'] else 0
        table += r
    banks[BANKS[0]][:recs] = table

    gen = Path('src/gen')
    gen.mkdir(parents=True, exist_ok=True)
    for b in BANKS:
        (gen / ('library%d.bin' % b)).write_bytes(bytes(banks[b]))
    first = next(i for i, l in enumerate(lines) if l[0] == 'fig')
    mower = next(i for i, l in enumerate(lines) if l[0] == 'fig' and l[2]['character'] == 'MOWER')
    inc = ['; generated by tools/build_library.py: do not edit',
           'LIB_LINES   equ %d' % len(lines), 'LIB_FIGURES equ %d' % len(figures),
           'LIB_FIRST   equ %d   ; the first figure line' % first,
           'LIB_MOWER   equ %d   ; the Mower, rolling east' % mower]
    for b in BANKS:
        inc.append('LIB_BANK%d_LEN equ %d' % (b, len(banks[b])))
    inc.append('lib_games:')
    for g in GAMES:
        inc.append('        db "%s",0' % g[0])
    (gen / 'library.inc').write_text('\n'.join(inc) + '\n')
    man = {'games': [g[0] for g in GAMES], 'lines': len(lines), 'figures': [
        {k: (list(v) if k == 'box' else v) for k, v in fg.items() if k not in ('data', 'gi')} for fg in figures],
        'left_out': left, 'sources': sources,
        'bank_bytes': {str(b): len(banks[b]) for b in BANKS}}
    (gen / 'library.json').write_text(json.dumps(man, indent=1) + '\n')
    print('%d lines, %d figures, %d left out; bank bytes %s' % (
        len(lines), len(figures), len(left), {b: len(banks[b]) for b in BANKS}))


if __name__ == '__main__':
    main()
