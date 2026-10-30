# Asset requests, finished review and removal — 2026-10-29

The user requested an asset-change pipeline inside the title’s development showcase: update notes, new assets with selectable style references, actual removal, and a finished queue in the same menu.

## Implemented

- **Request update** adds optional notes and up to twelve dropdown reference assets. **Request new** adds a short name with the same notes/references. Both persist after closing the game.
- The top-level [asset-requests/](../../asset-requests/README.md) folder is the handoff. Each request has authoritative JSON and a readable Markdown brief with exact notes, selected reference metadata, catalog/source/runtime/manifest paths, content/placement uses, related source-pack files and the normal build/review commands. AGENTS.md points future asset work there.
- The **Requests** browser shows work and its status, readable notes, clickable source/context paths, delivery reviews and briefs. All/open/finished/accepted/deleted filters, refresh and local folder/brief buttons support the handoff.
- The showcase’s model filter offers All assets, Updates requested and **Finished**. Agents claim/deliver work with `scripts/asset-requests.sh start/finish`. Finished models remain available for inspection until accepted or sent back through Request update. Acceptance clears the finished queue without removing the model.
- Finish requires normal world-catalog IDs, source/runtime files, current build manifests, a summary and an existing review. New requests require a newly registered model. Delivered source/runtime/catalog hashes prevent acceptance after an unreviewed change. Earlier delivery history is retained when further changes are requested.
- **Delete** opens a concrete ownership/dependency summary. Unused, exclusively owned assets can be removed: source folder including earlier versions, runtime folder/import sidecars and world-catalog entry. Referenced assets instead create a deletion request listing the files the agent must resolve. The actual removal command rechecks its plan token and rolls files/catalog/receipt back if a write fails.
- This uses one local authoring backend, `pipeline/asset_workflow.py`, shared by the dev UI and CLI. Notes use a temporary JSON file, never executable source or shell text. Gameplay still uses the existing WASI runner and has no host-Python/Blender/AI-service requirement.

## Validation

- Headless import and focused showcase regression passed.
- **11 Python lifecycle tests passed:** optional notes/references, exact multiline/Unicode text and CLI reopen, multiple new results, build/review validation, stale-finish rejection, revision history, real source/history/runtime/sidecar/catalog deletion, dependency/shared/symlink protection, stale plan rejection, serialized writes, and exact rollback including an interrupted receipt write.
- **21 input-driven UI checks passed:** update/new forms, reference selection, persisted agent brief, requested/finished lists, queue details/acceptance, in-use deletion request, real unused-fixture removal and reopen. Every mutation/deletion used a disposable checkout under `.cache/`; production models/catalogs were not removed or rewritten.
- Native Compatibility/llvmpipe review passed at 1600×1000, 1280×720, and 1280×720 with 150% interface scale. The final polished browser and its source links fit at 150% scale.
- Full `scripts/test.sh` **passed, exit 0**, including legacy/main journeys, app/saves, WASI, the 35 showcase and 21 request UI checks, 11 new workflow lifecycle tests, source guards, 885 world-art checks and 1,352 pipeline/link checks. `git diff --check` passed. All three production world/art/character catalogs remain byte-identical to the pre-change snapshot; the production request queue is empty.

Logs: `.cache/asset-workflow-full-test.log`, `.cache/asset-workflow-python-test.log`, `.cache/asset-workflow-ui-test.log`, `.cache/asset-workflow-native-1600.log`, `.cache/asset-workflow-native-1280.log`, `.cache/asset-workflow-native-ui150.log`. Xvfb’s usual input-method and V-Sync warnings do not affect the checks.

## Evidence

- [Update notes and selected reference](../../evidence/asset-workflow/2026-10-29/1600x1000/01-update-request.png)
- [New asset request](../../evidence/asset-workflow/2026-10-29/1600x1000/02-new-request.png)
- [Finished filter and scale preview](../../evidence/asset-workflow/2026-10-29/1600x1000/03-finished-assets.png)
- [Readable queue and source links](../../evidence/asset-workflow/2026-10-29/1600x1000/04-request-queue.png)
- [Dependency-linked removal request](../../evidence/asset-workflow/2026-10-29/1600x1000/05-in-use-delete.png)
- [Actual removal confirmation](../../evidence/asset-workflow/2026-10-29/1600x1000/06-delete-confirmation.png)
- [Smaller window](../../evidence/asset-workflow/2026-10-29/1280x720/03-finished-assets.png)
- [150% interface](../../evidence/asset-workflow/2026-10-29/1280x720-ui150/03-finished-assets.png)

## Scope

Accepted for catalogued world models, which are the existing showcase’s buildings, props, room assets and robots. Standalone sprite/texture libraries retain their existing catalogs; the request guide links those pipelines. Submitting work does not launch an agent or call a service. Completion is an explicit authoring action after build/test/review. Referenced/shared assets are not silently detached from rooms or saved worlds. Resolve their dependencies deliberately before deletion; player save files are never silently rewritten.

No production asset was deleted for this feature, and no new art was generated. The production queue starts empty.
