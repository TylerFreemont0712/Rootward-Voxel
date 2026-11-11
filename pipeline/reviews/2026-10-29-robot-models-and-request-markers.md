# Six robot models and request markers — 2026-10-29

The square's six proxy robots have new adopted Blender revisions following the approved paintings. The user's latest Pip decision takes precedence over his older sheet: no bag, with packages in his front compartments. The dev showcase also identifies pending removal and update requests directly in its model list.

## Delivered appearance

| Model | Revision |
| --- | --- |
| Pip | Rounded red postbox shell and cap, brass face mount, open four-compartment front with wrapped parcels, jointed arms, rear access panel, large drive wheels and caster. The satchel is removed. |
| Wick | Cream lantern head and tapered body, flared teal cap, curved wheel chassis, jointed arms and a segmented pole lantern with separate glass, ribs and roof. The pole stays in his own left hand. |
| Trowel | Watering-can shell, perforated watering rose, curved handle, open terracotta pot, leaves and daisies, service cover and folded arm. |
| Heron | Rounded cab, teal turret, articulated two-section crane, hinge discs, winch, cable, hook and slung timber crate, with a striped bumper. The final crate pose sits below his face. |
| Tender | Low rounded shell, fitted curved roof, folded maintenance arms, four wheels, rear hatch/coupling and moss on the physical rear-right seam. |
| Tally | Rounded till shell, drawer and handle, rimmed coin tray, curved printed receipt, brass ears and rear service panel. |

All six use eye-only, 160 ms blinks at independently varied intervals. They close into narrow lines and restore their original scale. The lamp flames, face glass and other geometry do not blink. Wheel pivots are retained, and rolling now uses each exported wheel radius. Tools are posed geometry; crane operation and additional work animations remain future work.

## Source and runtime

The selected sources are `art/source/world/robot-<name>/v2/model.blend`, exported with `scripts/world-art.sh build robot-<name>`. Previous v1 masters remain intact. Deliberate edit records, texture bakes and provenance are in the [source pack](../../art/source/world/sparks-robot-refinement/v1/README.md). Red/cream/teal enamel textures are packed in the masters and GLBs. A historical canvas bake remains source history after Pip's bag removal.

Only the six robot catalog entries select these revisions and opt into `spark_blink`. `WorldAssetMeta` reads the GLB importer's `extras` dictionary, so `blink_eyes` and `wheel_radius` retain their authored meaning. No area layout, collision rule, boy sprite or camera setting changes are needed. Existing adopted sources are edited deliberately; old seed generators are not rerun over them.

## Request-list feedback

Pending deletion gives the model row a slight red tint and a small **X** in a reserved right-hand gutter. An update gives it a yellow tint and outlined square. The marks remain visible on selected rows, long names and scrolling; deletion takes priority when both kinds are pending. Finished/accepted requests no longer mark the row. Reload and queue refresh also refresh externally changed request status.

`AssetRequestList` draws after the native ItemList has computed its row rectangles. The final native review caught and corrected an initial empty-layout draw that showed the tint without its symbol.

## Review and validation

- [Six-model comparison gallery](../../docs/concept/v0.72/robot-model-refinement.md): painted reference, previous model and new model from four angles, plus closed-eye keys.
- [Closer native lineup](../../evidence/robot-models/2026-10-29/lineup-detail.png) and [square-camera lineup](../../evidence/robot-models/2026-10-29/lineup-gameplay.png), with the approved boy for scale. This uses the game's camera heading/elevation; the latter uses the square's size-16 camera.
- [Actual square play-through](../../evidence/robot-models/2026-10-29/square-1280/10-overview.png): arrival, stair descent, shops, yard, terminal test and save/return path in a 1280×720 native window.
- [Update square](../../evidence/asset-workflow/2026-10-29-markers/02a-update-marker.png) and [delete X](../../evidence/asset-workflow/2026-10-29-markers/05a-delete-marker.png). Native review also covers 1280×720 at 150% interface scale.
- **86 refined-model checks passed:** preserved source hashes, eyes closing/reopening without changing other parts, wheel pivots/radii/rolling, no Pip satchel, parcel geometry and Wick/Tender handedness.
- **25 request UI checks passed:** pending tints/symbols, delete priority, finished clearing, durable briefs, queue and removal workflow. Mutating/removal tests use a disposable fixture, not production models.
- Full `scripts/test.sh` passed on the stable final build, including 909 world-art checks, 11 authoring-source checks, 11 workflow lifecycle tests and 1,386 pipeline/handoff checks. The first run overlapped the last Heron rebuild and correctly rejected its changing source hash; the stable full rerun passed.
- The final documentation check passed again after adding this gallery and review. A separate snapshot audit confirms 215 pre-existing source/art hashes are unchanged and only the six requested robot entries changed in the world catalog. `git diff --check` passed.

Native captures use Godot 4.7.2 Compatibility on Xvfb/llvmpipe. These are appearance and integration reviews, not a hardware performance benchmark. Logs live in `.cache/pip-wick-refinement/`.

The six authorized update requests are now **Finished**, with current source/runtime/catalog fingerprints. A [read-only native queue review](../../evidence/robot-models/2026-10-29/finished-robots.png) confirms all six appear in the production dev menu. They await the user's review/acceptance. All unrelated deletion requests, including cottage-bed, remain pending; no production asset is deleted by this pass. Player saves and original robot paintings/movement sheets are preserved.
