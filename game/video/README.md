# The Sprite Studio tutorial video

`tutorial.mp4` (4:07, 960 × 768, H.264 and AAC, 15 MB) is a tutorial presented by Hyun-joo Lee (Joo), the studio's
sprite artist. She introduces it on camera (10 s), then it goes into the Studio. It follows the Lessons from her
drawing chapter: choosing keys and drawing on the Desk, then lessons 1, 2, 4, 3, 5 and 6, then the Sheet (data size,
save and export). She closes on camera and ends on a smile, which dissolves over a second into the Dalex
Software logo on black (4 s, silent).

Each lesson is explained, not just named. Lesson 1 works through the binary: a square is a bit, eight make a byte.
The squares are worth 128 down to 1, so row 1's inked squares 2 and 4 are 32 + 8 = 40, which is hex 28. Then she
inks the last square, and the right byte turns from 00 to 01 on screen. While she does the arithmetic, the border
shows it written down in yellow.

There is no music, at the owner's request (12 November 2026). The Start tune, the only music in the recording, is
cut while the Start screen is up. The Studio's own effects (the tape tones) stay, ducked under her voice.

**Published** on 12 November 2026, Public: <https://youtu.be/kdW7khOQViU>, in the Dalex Software tutorials
playlist, with these subtitles (`voice-timeline.json`) and a thumbnail of Joo beside lesson 1.

## What it was recorded from

Every picture of the Studio is real emulator footage of the gated M7 tap, recorded by zx-media-kit's `record_demo.py` in
zx-game's simulator. The run is deterministic and bound to the tap.

- **Tap:** `game/build/sprite-studio-m7.tap`
- **sha256:** `d5d367981b573fab9cb264ee82812e05d92c181ca2935db8047a1b0670839e91`
- **Gate:** `game/milestones/m7.md`, "pass with issues", 2026-11-12.

`raw.json` is the recorder's sidecar. It names the tap, each window's recipe and sha256, and the sound checks:
the music, the AY log and the effects all pass. Audio and video are frame-locked (drift 0 ms).

One change is made to the Studio's picture. While the Start screen is up (about 3 seconds), a black bar covers its
bottom line, "© 2026 DALEX SOFTWARE": nothing on screen may be dated after 1987 (the owner's choice, 12 November
2026). Captions are drawn in the bottom border, never over the Spectrum's screen.

## Files

| File | What it is |
| --- | --- |
| `end-ident.png` | the end screen: the house ident `ident.scr` (zx-assets `house-style/logo/`, sha256 60274a1e…), drawn pixel for pixel in the recorder's palette with its 32-pixel border, ×3 |
| `talk/open.mp4`, `talk/close.mp4` | Joo on camera, lip-synced to her own lines (`talk/README.md`: how they were made and checked) |
| `talk/open.wav`, `talk/close.wav` | the voice the talking shots were lip-synced to, played from the shot's first frame |
| `recipes/tut-*.json` | the key schedules (by frame, cold load = frame 0) for each shot |
| `edit.json` | the edit list `record_demo.py` reads: each shot's recipe and frame window |
| `make_tutorial.py` | the plan (talking shots, tool shots, captions, where each voice line plays); writes `edit.json`, records `raw.mp4`, joins the talking shots and mixes `tutorial.mp4` |
| `voice-lines.json` | Joo's lines (her voice is made with the owner's private studio tools, which are not in this repository) |
| `voice-script.md` | each line with its length and Whisper's transcript |
| `voice-timeline.json` | where each line plays in the finished video |
| `vo/report.json` | the take report (`vo/*.wav` are ignored by Git) |

## Rebuild

This needs the owner's private tools: the zx-media-kit plugin records the footage, and Dalex Studio holds
Joo's voice. From the repository root:

```sh
export ZX_PLUGINS_DIR=...             # the private zx-plugins
python3 game/video/make_tutorial.py   # edit.json, then raw.mp4 (about a minute), then tutorial.mp4
```

`record_demo.py` refuses to record if the tap's sha256 does not match `game/build/build-m7.json`. Use
`--mix-only` to remix the voice without recording again.

## Checked, and not checked

- Every voice line's transcript was compared with its text. Lines 04, 09, 11 and 21 were retaken. Whisper writes
  "Dalex" (said "Dallex") as "Daleks"; the owner listened and confirmed "Dalex" is right (12 November 2026).
- A one-frame-a-second contact sheet of the finished cut was looked at. It shows the right screen under each line,
  no brands, and nothing dated after 1987.
- The talking shots score 10.25 and 10.62 on SyncNet on their own (the target is 4 or more). In the finished cut,
  they score 10.35 and 8.62, with the sound within one or two frames of the lips. Their mouths are clean frame by
  frame.
- Levels: the whole mix averages -22 dB, with peaks at the limiter, and her lines measure about -22 dB. While she
  speaks, the Studio's sound is ducked, so during the save the tape tones fall well under her voice.
  **Nobody has listened to the mix yet:** that is the owner's.
