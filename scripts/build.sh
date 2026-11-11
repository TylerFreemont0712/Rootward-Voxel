#!/usr/bin/env bash
# Builds Rootward Voxel for Linux and Windows and its installers; see scripts/build.py and docs/RELEASES.md.
set -euo pipefail
exec python3 "$(dirname "$0")/build.py" "$@"
