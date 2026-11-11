#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
# Compatibility name for the single active painted-character pipeline.
exec "$project_root/scripts/art.sh" "$@"
