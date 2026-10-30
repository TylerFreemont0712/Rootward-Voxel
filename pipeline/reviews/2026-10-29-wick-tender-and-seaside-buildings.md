# Wick / Tender movement and seaside buildings — 2026-10-29

The user requested detailed movement sheets for Wick and Tender, with fewer frames than the human walk cycle and the game’s actual elevated view. They also explicitly requested a second agent for three distinctive seaside-town building concepts, shown from complementary orthographic angles.

## Robot movement result

[Wick and Tender gallery](../../docs/concept/v0.72/wick-tender-movement.md).

Each robot has sixteen full sprite keys: four rolling phases in each of SE, SW, NE and NW. The source paintings are native 1254-square 2×2 RGBA sheets. Their separately authored directions are packed into 2816-square atlases with 704-square cells, source pixels unchanged and wheel-contact origin `[352,660]`. Contact sheets and four-view GIFs expose the loop for review.

The user corrected the initial plan to mirror left views: Wick’s item would switch hands, and Tender’s asymmetric fittings have the same problem. **No robot directions are mirrored.** Wick keeps the pole in his own left hand, with its clamp on the left flank. Tender’s moss/coupling remain at the rear-right seam; the left shell stays plain and the moss is partly hidden from that side. Rear views show service details rather than another face. The approved human mirror/template contract is unchanged.

Tender’s first SE sheet pointed toward the opposite diagonal; it is preserved and a selected front-right correction establishes the direction for the remaining paintings. Wick’s first rear sheets incorrectly showed the front guide caster at the rear; targeted edits hide it properly. All first attempts, exact prompts, reference hashes and output hashes remain beside the source. The source notes explain the [anatomical-side contract](../../art/source/robots/v0.72/movement.md).

`pipeline/prepare_robot_movement.gd` is guarded source preparation, refusing an existing atlas/registration and retaining all opaque pixels. It registers on the lower wheel/chassis silhouette rather than the asymmetric pole. It does not resample paintings, select runtime assets or add another runtime build path. The current square’s adopted robot Blender masters and models remain selected.

## Native review

`tools/wick_tender_review.gd` uses the actual fixed orthographic heading/elevation, camera size 16 and the approved boy for scale. It plays all eight direction sprites with `flip_h=false`, observes all four rolling phases, then captures a closer size-10 view. Review sizes are 1.85 world units for Wick including his carried lantern and 0.95 for Tender; no placed actor was resized.

- [1600×1000 gameplay scale](../../evidence/sparks-robots/2026-10-29/1600x1000-directions.png)
- [1600×1000 closer view](../../evidence/sparks-robots/2026-10-29/1600x1000-detail.png)
- [1280×720 gameplay scale](../../evidence/sparks-robots/2026-10-29/1280x720-directions.png)

Both native runs passed and played all four phases. Complete caps, lanterns, wheels and moss remain visible; the front/rear pole and near/far shell details retain their anatomical sides. These are sprite movement candidates, not a replacement for the square’s 3D renderer or its future work animations.

## Building directions

The requested second agent authored [three seaside building studies](../../docs/concept/v0.72/seaside-buildings.md): **A Tideglass Chandlery**, **B Gullstitch Sail Loft**, **C Lowtide Baths & Washhouse**. Each has a distinct local function and a two-view plate with complete roof/base and practical service-side details. The approved square and workshop lane supply style/material references. The parent reviewed all three and requested a corrected complementary opposite view for B, whose first pair repeated the gallery side. Selected B-v2 now reveals the other long service wall; the initial plate remains archived. Building choices remain unselected, with exact dimensions and modelling decisions deferred.

Sources, prompts and provenance live under `art/source/world/seaside-building-concepts/v1/`; gallery copies live under the v0.72 docs. No existing building master, placement, collision, shop interior or quest changed.

## Verification

- `test_robot_movement_art.gd`: **124 checks passed**, including exact registration, complete opaque silhouettes, wheel anchors, padding, generation provenance and independent direction sources.
- Native 1600×1000 and 1280×720: passed; eight direction sprites, all four rolling phases, no x-flips.
- Full `scripts/test.sh`: passed, including 124 robot-art checks, 111 shared-frame checks, 885 world-art checks, 11 authoring guards, 1,331 pipeline/handoff checks and 121 ground-art handoff checks.
- Protected character template/catalog, approved boy, original robot concepts and adopted Wick/Tender Blender masters: all 21 protected files unchanged. All 11 movement generation records and both exact registration-script snapshots match their preserved hashes.
- Building source/gallery hashes and local links: passed. B-v2 replaces the repeated gallery-side view with the true opposite rear-left view, revealing the plain service wall; the first plate is preserved. A/C retained after angle review.
- `git diff --check`: passed.

The image tool exposed no model identifier or seed. Supplied art works offline. No commit, push or publication was made.
