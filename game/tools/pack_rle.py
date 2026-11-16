"""Pack a 6912-byte .scr as (count, byte) runs for unpack_rle in main.asm.

    python3 game/tools/pack_rle.py assets/screens/start.scr game/src/gen/start.rle
"""
import sys

data = open(sys.argv[1], 'rb').read()
assert len(data) == 6912, len(data)
out = bytearray()
i = 0
while i < len(data):
    j = i
    while j < len(data) and data[j] == data[i] and j - i < 255:
        j += 1
    out += bytes([j - i, data[i]])
    i = j
open(sys.argv[2], 'wb').write(out)
print(f'{len(data)} -> {len(out)} bytes')
