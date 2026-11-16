#!/usr/bin/env python3
"""Build the Sprite Studio tutorial: Joo on camera, then real emulator footage of the gated M7 tap with her voice
over it, then Joo on camera again.

    export ZX_PLUGINS_DIR=...                 # the private zx-plugins (zx-media-kit records the footage)
    python3 game/video/make_tutorial.py       # edit.json -> raw.mp4 (record_demo) -> tutorial.mp4
    python3 game/video/make_tutorial.py --mix-only    # remix without recording again

The plan below is the whole edit. Each tool shot names a recipe in game/video/recipes/ and a window of its frames
(cold load = frame 0, 50 frames a second), the voice lines that play over it (seconds from the start of the shot)
and a caption drawn in the bottom border, never over the Spectrum's own picture. record_demo.py records every window
from the tap, deterministically, and checks the tap's sha256 against game/build/build-m7.json.

The talking shots (talk/open.mp4, talk/close.mp4) are Joo's own lines lip-synced on her checked still, made with
Dalex Studio's cast-explainer method (Wan 2.2 S2V, LatentSync at guidance 1.5); talk/README.md says how.

No music (the owner, 12 November 2026): the Start tune, the only music in the recording, is cut while the Start
screen is up; the Studio's own effects (clicks, chimes, the tape) stay. The Start screen's copyright line is
covered while it is on screen (its date is not 1987). The end screen is the Dalex Software house ident
(zx-assets house-style/logo/ident.scr, drawn pixel for pixel by the recorder's palette), held silent.
"""
import json, os, subprocess, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
GAME = HERE.parent
GAME_GAIN = 0.5             # the Studio's effects under the voice (there is no music left under it)
VOICE_GAIN = 1.8            # +5 dB: her takes peak at -7 dBFS
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf'
W, H = 960, 768
RATE = '295575/5909'        # the recording's frame rate: the 128K's 50.021 Hz
END_IDENT = 4.0            # the end screen: the house ident (Dalex Software on black), silent
CLOSE_SMILE = 4.2          # the closing shot ends here, on her smile (frame 104: eyes open; after it they close)
FADE_START = 4.0           # her line ends at 3.97 s; the smile then dissolves into the logo
FADE = 1.0
IDENT = HERE / 'end-ident.png'

# the talking shots: (clip, the voice it was lip-synced to, caption, the lines it says). The voice starts with the
# picture: the clip was lip-synced to exactly this file from its first sample.
TALK_OPEN = ('talk/open.mp4', 'talk/open.wav', 'Hyun-joo Lee, sprite artist', ['01-hello', '02-paper'])
TALK_CLOSE = ('talk/close.mp4', 'talk/close.wav', 'Hyun-joo Lee', ['27-bye'])

# The tool shots: (name, recipe, from, to, caption, [(line id, at seconds)], [(from, to, note)]). A note replaces the
# caption in the border while it shows: the arithmetic she is saying, written down.
PLAN = [
    ('start and desk', 'tut-start-desk', 410, 1450, 'Choose your input, then draw',
     [('03-keys', 2.3), ('04-paint', 7.6), ('04b-true', 11.7), ('04c-hex', 15.9)], []),
    ('lesson 1', 'tut-lesson1', 250, 3130, 'Lesson 1: a figure is rows of dots',
     [('05-lessons', 0.3), ('06-l1', 3.9), ('07a-bits', 7.8), ('07b-bytes', 12.6), ('07c-worth', 16.8),
      ('07d-worth2', 22.1), ('07e-row1', 27.4), ('07f-add', 31.3), ('07g-hex', 36.2), ('07h-right', 41.7),
      ('07i-f', 45.8), ('07j-01', 52.2)],
     [(7.8, 16.5, '1 square = 1 bit   8 bits = 1 byte'),
      (16.8, 27.1, 'worth: 128  64  32  16  8  4  2  1'),
      (27.4, 31.1, 'row 1, left byte: 0 0 1 0 1 0 0 0'),
      (31.3, 36.0, '0 0 1 0 1 0 0 0 = 32 + 8 = 40'),
      (36.2, 41.5, '40 = 2 sixteens + 8 = hex 28'),
      (41.7, 45.6, 'right byte: 0 0 0 0 0 0 0 0 = hex 00'),
      (51.6, 57.6, 'right byte: 0 0 0 0 0 0 0 1 = hex 01')]),
    ('lesson 2', 'tut-lesson2', 235, 1425, 'Lesson 2: a second frame',
     [('08-l2', 0.7), ('08b-anim', 5.3), ('08c-rows', 9.6), ('09-l2-play', 13.9), ('09b-speed', 17.9)],
     [(17.9, 23.8, '4 TV frames at 50 a second = 0.08 s')]),
    ('lesson 4', 'tut-lesson4', 235, 1145, 'Lesson 4: the mask and its ring',
     [('10-l4', 0.4), ('11b-ring', 5.3), ('11-l4-ring', 9.6), ('12-l4-box', 13.9)], []),
    ('lesson 3', 'tut-lesson3', 235, 1375, 'Lesson 3: three ways to put it down',
     [('13-l3', 0.4), ('14-l3-copy', 4.9), ('14b-mix', 9.6), ('15-l3-mask', 13.3), ('15b-clean', 18.4)], []),
    ('lesson 5', 'tut-lesson5', 235, 1235, 'Lesson 5: why drawing flickers',
     [('16-l5', 0.4), ('17-l5-rub', 3.6), ('18-l5-blink', 6.9), ('19-l5-once', 10.2), ('19b-rule', 14.5)], []),
    ('lesson 6', 'tut-lesson6', 245, 1775, 'Lesson 6: colour belongs to the cell',
     [('20-l6', 0.4), ('21a-blocks', 4.6), ('21-l6-block', 7.9), ('21b-ink', 13.1), ('21c-grass', 17.2),
      ('21d-nine', 21.8), ('22-l6-look', 25.4)],
     [(4.6, 12.8, 'each 8 x 8 block: one ink, one paper')]),
    ('sheet', 'tut-sheet', 240, 1810, 'The Sheet: key 9',
     [('23-sheet', 0.4), ('24-size', 4.4), ('24b-pos', 7.8), ('24c-spill', 12.7), ('25-sum8', 17.3),
      ('25b-one', 23.6), ('26-tape', 29.0)],
     [(12.7, 16.9, 'shifted right, 16 dots spill into 3 bytes'),
      (17.3, 23.4, '2 x 8 x 16 x 3 = 768'),
      (23.6, 28.8, '2 x 1 x 16 x 2 = 64')]),
    ('sheet saved, export', 'tut-sheet', 2900, 3080, 'The Sheet: save and export', [], []),
]
START_PRESS = 560           # tut-start-desk: 2 pressed here; the Start screen (and its tune) ends with it


def esc(text):
    return text.replace(':', r'\:').replace("'", '’')


def caption(text, t0, t1, y=700):
    return (f"drawtext=fontfile={FONT}:text='{esc(text)}':fontsize=34:fontcolor=white:x=(w-tw)/2:y={y}:"
            f"box=1:boxcolor=black@0.55:boxborderw=8:enable='between(t,{t0:.3f},{t1:.3f})'")


def main():
    edl = {'title': 'Sprite Studio', 'subtitle': 'ZX Spectrum 128K', 'title_card': 0, 'end_card': 0,
           'fade_in': 0.001, 'fade_out': 0.001,          # the recording sits between the talking shots: hard cuts
           'segments': [{'name': n, 'recipe': f'recipes/{r}.json', 'from': a, 'to': b} for n, r, a, b, *_ in PLAN]}
    (HERE / 'edit.json').write_text(json.dumps(edl, indent=1) + '\n')
    raw = HERE / 'raw.mp4'
    if '--mix-only' not in sys.argv:
        script = Path(os.environ['ZX_PLUGINS_DIR']) / 'zx-media-kit/scripts/record_demo.py'
        subprocess.run([os.environ.get('ZX_PYTHON', 'python3'), str(script), str(GAME), '--milestone', '7',
                        '--edl', str(HERE / 'edit.json'), '--out', str(raw)], check=True)
    side = json.loads((HERE / 'raw.json').read_text())
    starts = [s['video_start_s'] for s in side['segments']]
    body_end = side['av']['video_duration_s']
    known = {v['id']: v for v in json.loads((HERE / 'vo/report.json').read_text())}

    # the timeline: open talk, the tool, close talk, end ident
    def secs(p):
        return float(subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0',
                                     str(HERE / p)], capture_output=True, text=True).stdout)
    d_open = secs(TALK_OPEN[1]) + 0.6
    d_close = FADE_START       # the logo's 4 s start here, the first second dissolving in from her smile
    t_body, t_close = d_open, d_open + body_end
    t_end = t_close + d_close

    inputs = ['-i', str(raw), '-i', str(HERE / TALK_OPEN[0]), '-i', str(HERE / TALK_CLOSE[0]),
              '-loop', '1', '-i', str(IDENT)]
    f, voices, timeline = [], [], []

    def add_voice(wav, t):
        nonlocal inputs
        inputs += ['-i', str(HERE / wav)]
        n = inputs.count('-i') - 1
        f.append(f'[{n}:a]aresample=48000,volume={VOICE_GAIN},adelay={int(t * 1000)}|{int(t * 1000)}[v{n}]')
        voices.append(f'[v{n}]')

    for (clip, wav, _, lines), t0 in ((TALK_OPEN, 0.0), (TALK_CLOSE, t_close)):
        add_voice(wav, t0)
        timeline.append({'id': '+'.join(lines), 'shot': 'talk ' + Path(clip).stem, 'start_s': round(t0, 3),
                         'end_s': round(t0 + secs(wav), 3), 'text': ' '.join(known[i]['text'] for i in lines),
                         'heard': ' '.join((HERE / wav).with_suffix('.heard.txt').read_text().split())})

    def add_line(lid, t, shot):
        add_voice(f'vo/{lid}.wav', t)
        v = known[lid]
        timeline.append({'id': lid, 'shot': shot, 'start_s': round(t, 3), 'end_s': round(t + v['seconds'], 3),
                         'text': v['text'], 'heard': v['heard']})

    for k, (name, _, a, b, _, lines, _) in enumerate(PLAN):
        for j, (lid, at) in enumerate(lines):
            t = t_body + starts[k] + at
            nxt = PLAN[k + 1] if k + 1 < len(PLAN) else None     # a silent shot after it can carry the line on
            spill = (nxt[3] - nxt[2]) / 50.0 if nxt and not nxt[5] else 1.0
            end = (lines[j + 1][1] if j + 1 < len(lines) else (b - a) / 50.0 + spill)
            if at + known[lid]['seconds'] > end:
                raise SystemExit(f'{lid} ({known[lid]["seconds"]} s at {at}) runs into what follows ({end})')
            add_line(lid, t, name)

    # pictures
    def talk_v(n, d, label):
        return (f'[{n}:v]scale=-2:{H}:flags=lanczos,crop={W}:{H},setsar=1,fps={RATE},'
                f'tpad=stop_mode=clone:stop_duration=10,trim=duration={d:.3f},setpts=PTS-STARTPTS[{label}]')
    f.append(talk_v(1, d_open, 'to'))
    f.append(f'[2:v]trim=duration={CLOSE_SMILE},scale=-2:{H}:flags=lanczos,crop={W}:{H},setsar=1,fps={RATE},'
             f'tpad=stop_mode=clone:stop_duration=5,trim=duration={FADE_START + FADE:.3f},setpts=PTS-STARTPTS,'
             f'format=yuv420p,settb=AVTB[tc]')
    cover_end = starts[0] + (START_PRESS + 1 - PLAN[0][2]) / 50.0
    vf = [f"drawbox=x=96:y=648:w=768:h=24:color=black:t=fill:enable='lt(t,{cover_end:.3f})'"]
    for k, (_, _, a, b, cap, _, notes) in enumerate(PLAN):
        t0, t1 = starts[k], starts[k] + (b - a) / 50.0
        hide = ''.join(f'*not(between(t,{t0 + n0:.3f},{t0 + n1:.3f}))' for n0, n1, _ in notes)
        vf.append(caption(cap, t0, t1).replace(f"enable='between(t,{t0:.3f},{t1:.3f})'",
                                               f"enable='between(t,{t0:.3f},{t1:.3f}){hide}'"))
        for n0, n1, text in notes:
            vf.append(caption(text, t0 + n0, t0 + n1).replace('fontcolor=white', 'fontcolor=yellow'))
    f.append(f'[0:v]{",".join(vf)},trim=0:{body_end:.4f},setpts=PTS-STARTPTS[body]')
    f.append(f'[3:v]setsar=1,fps={RATE},trim=duration={END_IDENT},setpts=PTS-STARTPTS,format=yuv420p,settb=AVTB[card]')
    f.append(f'[tc][card]xfade=transition=fade:duration={FADE}:offset={FADE_START}[tail]')
    f.append(f'[to][body][tail]concat=n=3:v=1:a=0,'
             f'{caption(TALK_OPEN[2], 0.4, d_open - 0.3)},{caption(TALK_CLOSE[2], t_close + 0.3, t_end - 0.4)}[vout]')
    # sound: the recording's own sound with the Start tune cut, placed after the opening talk; voices on top
    f.append(f"[0:a]aresample=48000,volume=0:enable='lt(t,{cover_end:.3f})',volume={GAME_GAIN},"
             f'atrim=0:{body_end:.4f},asetpts=PTS-STARTPTS,adelay={int(t_body * 1000)}|{int(t_body * 1000)}[gm0]')
    # the Studio's sound ducks under her voice (the tape's save tones were louder than her line about them)
    total = t_end + END_IDENT
    f.append(f'{"".join(voices)}amix=inputs={len(voices)}:normalize=0:duration=longest,apad,atrim=0:{total:.3f},'
             f'asplit[vm][vs]')
    f.append(f'[gm0]apad,atrim=0:{total:.3f}[gm]')
    f.append('[gm][vs]sidechaincompress=threshold=0.01:ratio=10:attack=15:release=400:makeup=1[gd]')
    f.append(f'[gd][vm]amix=inputs=2:normalize=0:duration=longest,alimiter=limit=0.89,atrim=0:{total:.3f}[mixed]')
    out = HERE / 'tutorial.mp4'
    subprocess.run(['ffmpeg', '-nostdin', '-y', '-loglevel', 'error', *inputs, '-filter_complex', ';'.join(f),
                    '-map', '[vout]', '-map', '[mixed]', '-c:v', 'libx264', '-crf', '18', '-pix_fmt', 'yuv420p',
                    '-c:a', 'aac', '-b:a', '160k', '-movflags', '+faststart', str(out)], check=True)
    (HERE / 'voice-timeline.json').write_text(json.dumps(timeline, indent=1) + '\n')
    print(out, f'{len(timeline)} voice lines; opening talk {d_open:.1f} s, tool {body_end:.1f} s, '
               f'closing talk {d_close:.1f} s, end ident {END_IDENT:.1f} s')


if __name__ == '__main__':
    main()
