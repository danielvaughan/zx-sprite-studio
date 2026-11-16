# Joo's talking shots

`open.mp4` (her lines 01 and 02) and `close.mp4` (line 27) are Joo speaking her own takes from `../vo/`, made on
12 November 2026 with Dalex Studio's `cast-explainer` method (`devtools/dalex/video/cast_explainer.py --stage talk`):

- the still is her checked host picture `mo-hj-host.png`, the one used in the *Press Play on Tape* making-of;
- a Wan 2.2 S2V base driven by her voice (seed 1987, 1024 × 576), then LatentSync 1.6 at guidance 1.5, then
  `face_smooth --mouth 0 --sharpen 1.0`.

Checks:

| Shot | Length | SyncNet (target 4 or more) | Mouth check against the base |
| --- | --- | --- | --- |
| open | 9.72 s | 10.25, offset 0 | 1 of 243 frames flagged, OK |
| close | 4.40 s | 10.62, offset 0 | 0 of 110 frames flagged, OK |

I also looked at the frames by eye: the mouth is clean in every one, and she looks the same throughout. The
monitor behind her is blank.
