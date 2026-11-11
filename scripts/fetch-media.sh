#!/usr/bin/env bash
# Installs Rootward Voxel's pictures and models from the packs on the repository's GitHub releases.
#   scripts/fetch-media.sh            what the game shows (the `game` packs)
#   scripts/fetch-media.sh dev        the art sources too: Blender masters, source paintings, concept boards
#   scripts/fetch-media.sh all        everything; or name packs: scripts/fetch-media.sh world-loft dev-art-characters
#   scripts/fetch-media.sh --status   what is installed, missing or changed; installs nothing
#   --force                           also replace files changed here since they were fetched
# Every pack and file is pinned by SHA-256 in media.lock. Safe to re-run; it only fetches what is missing or stale.
# Offline, point VOXEL_MEDIA_FROM at a folder holding the packs (`<pack>.tar`). See docs/RELEASES.md.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
python="$(command -v python3 || command -v python)"
if [ "${1:-}" = "--status" ]; then
	exec "$python" "$root/scripts/media.py" status
fi
exec "$python" "$root/scripts/media.py" fetch "$@"
