#!/usr/bin/env bash
# Assemble Sprite Studio from game/src/ with sjasmplus 1.24 into build/ and check the result
# against tools/build.sha256: the exact code and bank images inside game/build/sprite-studio-m7.tap.
# Usage: tools/build.sh            (set SJASMPLUS to use a sjasmplus that is not on PATH)
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
asm="${SJASMPLUS:-sjasmplus}"
command -v "$asm" >/dev/null || { echo "build: sjasmplus not found (https://github.com/z00m128/sjasmplus, v1.24.0)" >&2; exit 1; }
mkdir -p "$root/build"
cd "$root/game/src"
"$asm" --nologo --msg=war --outprefix="$root/build/" main.asm
cd "$root/build"
if command -v sha256sum >/dev/null; then sha256sum -c "$root/tools/build.sha256"
else shasum -a 256 -c "$root/tools/build.sha256"; fi   # macOS has shasum, not sha256sum
echo "build: main.bin and bank1/4/6.bin match the M7 tape's code"
