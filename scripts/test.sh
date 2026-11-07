#!/usr/bin/env bash
# The project's automated checks. `scripts/test.sh --help` lists the tiers; the tests are registered in test/manifest.json.
#   scripts/test.sh            quick tier: rules, documents, art contracts, guards (fast, run after every edit)
#   scripts/test.sh flow       + the real game scene driven headless
#   scripts/test.sh full       + the audit of every runtime model
#   scripts/test.sh smoke      boot the game and load every room
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
exec python3 "$project_root/scripts/run_tests.py" "$@"
