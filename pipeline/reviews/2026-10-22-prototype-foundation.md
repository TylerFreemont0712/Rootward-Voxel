# Prototype foundation review — 2026-10-22

Historical baseline. See [the 2026-10-23 review](2026-10-23-painted-and-blender.md) for the selected painted diagonal animation, rejected cutout experiment and working Blender handoff.


Decision: keep this standalone prototype and its current selected art as the baseline for further evaluation. The custom world builder is deferred. This is not a production-readiness sign-off.

## What was changed

The player now uses a simple anime-inspired 2D sprite in the orthographic 3D clearing. Its transparent source atlas and exact built-in ChatGPT imagegen prompt are preserved under `art/source/adventurer/v1/`. The build generates animation resources and measured foot anchors, with three authored directions and mirrored left.

The world uses shared textured materials, violet/teal tiled buildings, a smaller workshop, clustered tree crowns, stone riverbanks, cobbled paths, rippling water and bridge handrails. Villagers, flowers, flower boxes and scattered small props are excluded.

Following the user's decision, movement is cardinal grid stepping with smooth visual interpolation, held-key repetition and click-to-walk. Authoritative state stays on integer cells. The controller settles a step before program snapshots and prevents Apply during a step.

## Checks actually run

`scripts/test.sh` passed 134 checks: 53 pure-world/real Python-WASI checks, 24 application checks, 25 grid movement/routing checks and 32 art-contract checks. The last suite includes animation-phase retention on turns.

`tools/movement_review.gd` passed its five live input observations: a mouse click planned a route; the destination across the built bridge was reached; holding D repeated steps; releasing stopped on a cell; focusing the editor prevented movement. It recorded 25 viewport frames. This is focused integration evidence rather than an exhaustive movement or visual-quality review.

Godot 4.7.2 used the GL Compatibility renderer on the AMD Radeon 680M for these captures. No performance benchmark or gamepad-hardware acceptance was performed.

## Evidence reviewed

- [Gameplay at 1600×1000](../../evidence/voxel-clearing.png)
- [Real Python changes applied](../../evidence/voxel-clearing-applied.png)
- [Character detail](../../evidence/character-detail.png)
- [Cottage detail](../../evidence/house-detail.png)
- [Mouse/keyboard review end state](../../evidence/sprite-movement.png)
- [Actual click-to-walk recording](../../evidence/grid-walk.gif)

The character detail, normal clearing, cottage and a frame crossing the bridge were inspected. The cottage capture contains no flower boxes. Scene depth, roof/beam detail and sprite ground contact are visible. The movement GIF was exported at 12 FPS from the viewport frames captured every five 60 Hz ticks; it is gameplay evidence, not generated concept art.

## Remaining visual differences

The reference is a painted concept with softer edge treatment, richer foliage shapes and more integrated warm lighting. The prototype's tree crowns remain angular clusters, its ground is simpler and its direct shadows are harder. The sprite has a cleaner anime treatment than the concept's characters. Some props can occlude the player in this fixed view; review approaches and silhouettes before expanding placement density.

Refine tree crown silhouette, roof/stone edge treatment and lighting at the same gameplay camera before adding decorative clutter. Keep the accepted reference and current captures as comparison points.

## Next proofs, in order

1. Put a second character design through the existing source/catalog/build/review route. Confirm that it requires no guessed per-character position patches.
2. Prove one reusable world asset with a second placement/variant and one source rebuild. If testing Blender, complete one GLB export/reimport round trip and define its logical footprint; the current clearing does not yet consume a general GLB asset catalog.
3. Extract the current clearing into a validated area definition shared by rules and rendering, then load a second tiny arrangement using existing assets.
4. Review the programming loop and movement with family players. Record observed confusion, visual readability and actual performance before deciding what a solid first game build includes.

The playbooks explain these routes and their limitations. They do not implement multiple character identities, arbitrary asset spawning, an area loader, world persistence or a custom editor. Those remain explicit future work.
