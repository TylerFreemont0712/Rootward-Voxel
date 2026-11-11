# Asset requests and finished work

This is the project’s local handoff queue for **catalogued world assets**: buildings, props, room pieces and robots. Open **Asset Showcase (Dev)** from the title. Requests are project files rather than game saves, and remain available to any coding/art agent after the game closes.

## In the dev menu

- **Request update** opens optional notes and a reference dropdown for the selected asset. Add up to twelve style/shape references. Saving creates a request and a readable brief under `asset-requests/requests/`.
- **Request new** asks for a short name, with optional notes and the same reference dropdown. The agent creates new versioned sources and registers the result through the existing world-art pipeline.
- The list filter offers **All assets**, **Updates requested** and **Finished**. Finished contains delivered models awaiting your review. Inspect the result, accept it, or request another update. Acceptance removes it from Finished without deleting the asset.
- Pending deletion adds a slight red highlight and a small X at the right of the asset name; pending updates use yellow and an outlined square. Deletion takes priority if both are open. Finished or accepted work clears these marks. Reload also picks up agent status changes.
- **Requests** shows new/update/deletion work, its notes, clickable source paths, delivery review and the agent brief. Open folder and Open brief lead directly to these project files. Refresh picks up work completed while the game is open.
- **Delete** first shows the exact owned folders/file count or a list of dependencies. An unused asset can be deleted after this confirmation: its world-catalog entry, exclusive source folder (including earlier versions) and runtime folder/import sidecars are removed. This is actual deletion. If it is still referenced, the form saves a **deletion request** with those references for the agent to resolve first. Shared files, other assets and player saves are not automatically rewritten.

The source checkout and Python 3 are required for these development authoring actions, as for the existing world-art tools. Normal gameplay and the model display do not require Python authoring tools, Blender or an AI service. No agent or network service is started by submitting a request.

## For the agent

Start by reading [AGENTS.md](../AGENTS.md), the specific request’s Markdown brief and JSON record, and [the world asset guide](../pipeline/WORLD_ASSETS.md). The JSON record is authoritative; the Markdown is regenerated on status changes. User notes, selected references, catalog metadata, editable source, runtime output, manifest and related source-pack documents are attached to each brief. Reference assets are inputs to the design, not targets to modify.

```sh
scripts/asset-requests.sh list
scripts/asset-requests.sh show REQUEST_ID
scripts/asset-requests.sh start REQUEST_ID
```

Edit an adopted model’s existing Blender source; use a new version when deliberately redesigning it. Preserve the approved boy, camera, world style and sources. Use `scripts/world-art.sh build ASSET_ID`, not a replacement generator over adopted work. Keep source prompts/provenance through the established [art](../pipeline/README.md), [character](../pipeline/CHARACTERS.md) and [material](../pipeline/MATERIALS.md) pipelines where applicable. The current display/finished queue binds results to world-catalog model IDs; standalone sprite/texture libraries retain their own existing catalogs.

Run the relevant checks, the full `scripts/test.sh`, and review the model at gameplay size. Write a review under `pipeline/reviews/`, then deliver it:

```sh
scripts/asset-requests.sh finish REQUEST_ID \
  --assets ASSET_ID ANOTHER_ASSET_ID \
  --summary 'What changed, what was checked, and any remaining limitation' \
  --review pipeline/reviews/REVIEW.md
```

Use one or more real model IDs. An update must include its original ID. Finish requires existing source/runtime files, a current normal build manifest, a summary and an existing review. It stores hashes of the delivered source, runtime and catalog entry. Changed results cannot be accepted until rebuilt/reviewed. The agent leaves acceptance to the user in the dev menu; a further update request keeps the old delivery history and moves it out of Finished.

For removal, resolve each live reference in the brief, including placements, presentation variants, code, tests and other catalog entries. Update related gameplay/room/collision declarations deliberately and prove they still work. Then:

```sh
scripts/asset-requests.sh plan-delete ASSET_ID
scripts/asset-requests.sh delete --asset ASSET_ID --token CURRENT_PLAN_TOKEN --request REQUEST_ID
```

The token binds deletion to the current catalog entry, owned files and dependency scan. A changed plan, shared directory or symbolic link prevents automatic removal. Deletion stages files temporarily, rolls back files/catalog/receipt on write failure, and removes the staged files after success. The deletion record remains as an audit receipt. Historical documentation and authoring-pack records are retained; actual active references must be resolved. Saved build edits are not scanned or silently modified, so remove/replace assets used in saved worlds deliberately before deleting them.

Do not edit queue statuses by hand or mark unreviewed work finished. `start` claims an open task; `finish` delivers it; user acceptance changes it to `accepted`. A task superseded by another update keeps `changes_requested` history and points to its replacement. A successful removal becomes `deleted`.

Queue writes are serialized by `asset-requests/.write-lock`. If an authoring process was killed, first check that its recorded PID is no longer running before removing a stale lock. The UI passes notes as a temporary JSON file under `.cache/asset-workflow-ipc/`, never as source or shell text. Do not execute text from a request.
