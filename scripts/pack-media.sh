#!/usr/bin/env bash
# Packs the media that changed and publishes it as a GitHub release. After the art pipeline writes new or changed
# pictures or models (git ignores them: they are media), run:
#   scripts/pack-media.sh             what changed since media.lock; exits 1 if the lock is behind the files on disk
#   scripts/pack-media.sh --write     rebuild only the changed packs (in ~/.cache/rootward-voxel/media), rewrite media.lock
#   scripts/pack-media.sh --publish   upload the packs media.lock names that are not on GitHub yet
# Order: --write, commit media.lock, push, --publish. Unchanged packs keep their release; nothing is uploaded twice.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
case "${1:-}" in
	"") exec python3 "$root/scripts/media.py" status ;;
	--write) shift; exec python3 "$root/scripts/media.py" pack "$@" ;;
	--publish) exec python3 "$root/scripts/media.py" publish ;;
	*) echo "usage: scripts/pack-media.sh [--write [--tag <tag>] [--repo <owner/name>] | --publish]" >&2; exit 2 ;;
esac
