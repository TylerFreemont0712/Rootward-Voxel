#!/usr/bin/env bash
# Everything a fresh clone needs before scripts/play.sh and scripts/test.sh, on Linux x86_64:
#   scripts/setup.sh          the Python sandbox runtime and the game's pictures and models (about 800 MB, once)
#   scripts/setup.sh --dev    also the art sources: Blender masters, source paintings, concept boards (about 3 GB more)
# Safe to re-run: each step skips what is already here. Needs python3, curl, tar and unzip.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
"$root/scripts/setup-runtime.sh"
if [[ "${1:-}" == "--dev" ]]; then
  "$root/scripts/fetch-media.sh" all
else
  "$root/scripts/fetch-media.sh"
fi
echo "Ready: scripts/play.sh to play, scripts/test.sh to test (Godot 4.7.2 as 'godot' on the PATH, or GODOT_BIN)."
