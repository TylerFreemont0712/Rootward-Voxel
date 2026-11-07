# Dialogue and clockwork transitions — 2026-11-02

The story window now follows the user's marked composition: higher, narrower and clear of the bottom HUD. The traveller has a new full-body painting facing Hotaru, whose portrait stage is larger. Natural Sparks crossings animate the walk, prepare the next scene in bounded steps and warm it under cover before arrival.

The loading train now has seven actual involute wheel profiles with matching pitch, clearance and angular ratios. Brass/copper faces, spoke openings, bolts, turned collars and a luminous code core sit over an engraved dial. Three conduits carry moving sparks between the source and their terminals. The **City power** meter shows source strength, separately from loading progress.

## Sources and ownership

- `ui/workshop_scene.gd`: fixed raised/inset window, a scrolling text column, right-side responses and distinct portrait stages. Existing story content and speaker highlighting are retained.
- [Traveller v2 source pack](../../art/source/portraits/sparks/v2/README.md): 1024×1536 RGBA, generated with the built-in image tool from the approved boy and existing portraits. Exact [prompt](../../art/source/portraits/sparks/v2/traveller-prompt.json) and [provenance](../../art/source/portraits/sparks/v2/traveller-provenance.json) are recorded. The output is copied losslessly through `scripts/art.sh`, selected by `portrait_libraries` in the art catalog. Old sources, gameplay sprite pixels and the shared character template are preserved.
- `ui/gear_geometry.gd`, `ui/clockwork_wheel.gd`, `ui/clockwork_gears.gd`: code-drawn presentation; no new generated gear textures or world-asset pipeline.
- `ui/gear_veil.gd` and its shader: toothed cover/reveal, a persistent bounded phase clock and the power snapshot entry point.
- `art/outline_job.gd`, `art/illustrated_edges.gd`, `art/world_assets.gd`, `art/workshop_loft_room.gd`, `scenes/clearing_view.gd`: threaded resource preparation, incremental versions of the same outline/placement operations and gradual hidden rendering. Synchronous tools retain their existing setup API. Only the main thread creates nodes.
- `app/game.gd`: awaits the covered build, renders at least eight warm-up frames plus 0.25 seconds, holds full cover for at least 0.9 seconds, and gives visual travel ownership of walking animation until arrival. The player template/atlas remain referenced across the swap, avoiding an end-of-load texture reload. Integer destinations, collision and saved room state retain their existing authority.

This pass does not edit Blender sources, area layout, the previous lane deliverables or quest solutions.

## Power presentation contract

`GearVeil.set_world_state({"city_power":{"strength":0.65,"stability":1.0,"restored_links":1}})` sets a copied and clamped presentation snapshot. Strength controls the source light, meter and modest speed change; stability controls conduit/source fluctuations; restored links brighten the three branches. Missing power data keeps the normal neutral presentation. Gears continue moving in the low-power preset so the loading signal remains legible.

**Dev · F8 → Loading screen** offers Low power, Steady and Restored previews. These neither switch chapter nor change the journey save. The future source-failure/programming-repair story can drive the same snapshot; its quests, persistent power state and programming API are still to be authored one quest at a time.

## Validation and native review

- `scripts/art.sh`: passed, including 100 painted-art/idle checks and 111 shared-frame skin checks.
- `test/test_transitions.gd`: 47 checks passed. Covers triangulated profiles, clearance through a full tooth engagement for every neighbouring pair, tooth-count angular ratios, non-mutating/clamped power data, identical synchronous/incremental outline arrays, long-text scrolling and dialogue bounds at both sizes, real input crossings and changing walk frames, warm-up/minimum cover, animation ownership release and a power preview that preserves the save.
- `test/test_sparks.gd`: 371 checks passed during the full suite, including all authored story pages sharing one stable window and opposing portraits.
- Full `scripts/test.sh`: passed with no script/engine errors, including world-art/source handoff, saved rooms, quests, WASI boundaries, movement, dialogue, development tools and 11 asset-workflow lifecycle tests.
- Native `tools/dialogue_transition_review.gd`: reviewed at 1600×1000 and 1280×720, Godot 4.7.2, Compatibility/OpenGL on the AMD Radeon 680M. Both reviews exercise the real floor → lane → square → lane links, actual changing walking frames, dialogue replies and the F8 power controls. Final cadence and selected captures accompany this review.

```sh
scripts/play.sh --resolution 1600x1000 -s res://tools/dialogue_transition_review.gd -- .cache/dialogue-transitions/final-1600
scripts/play.sh --resolution 1280x720 -s res://tools/dialogue_transition_review.gd -- .cache/dialogue-transitions/final-1280
```

The following final measurements exclude PNG capture time. The 1280 review fixes its own frame cap at 60 to prevent OS focus changes from invoking the normal game's 30 fps background cap; it does not move focus or change the regular game.

| Resolution / crossing | Full-cover seconds | Loading p95 ms | Warming p95 ms | Reveal p95 ms |
|---|---:|---:|---:|---:|
| 1600×1000 · first lane | 6.661 | 24.59 | 16.82 | 16.78 |
| 1600×1000 · first square | 5.387 | 24.25 | 16.80 | 16.72 |
| 1600×1000 · cached lane | 0.901 | 50.20 (six build frames) | 16.82 | 16.71 |
| 1280×720 · first lane | 6.578 | 23.67 | 16.74 | 18.47 |
| 1280×720 · first square | 5.295 | 24.74 | 16.76 | 16.78 |
| 1280×720 · cached lane | 0.909 | 47.26 (six build frames) | 19.34 | 16.74 |

First visits still do real resource and outline work while the veil stays up. Cached returns keep the deliberate minimum cover. Warm-up hides preparation before walking is revealed; the final maximum reveal frame was 19.44 ms at 1600 and 18.74 ms at 1280. There are still isolated covered build/renderer frames up to about 79 ms. The old end-of-load player-atlas pause is removed; this desktop review does not promise every OS/driver frame on other hardware stays within 16.7 ms.

## Selected evidence

Images are native gameplay captures; the motion clip is encoded from native captures. Intermediate frames and test logs remain in `.cache/dialogue-transitions/`.

- [Hotaru and raised dialogue at 1600×1000](../../evidence/dialogue-transitions/2026-11-02/dialogue-hotaru-1600.png)
- [Full-body traveller reply at 1600×1000](../../evidence/dialogue-transitions/2026-11-02/dialogue-player-1600.png)
- [Three choices and clear HUD at 1280×720](../../evidence/dialogue-transitions/2026-11-02/dialogue-choices-1280.png)
- [F8 power previews at 1280×720](../../evidence/dialogue-transitions/2026-11-02/dev-power-1280.png)
- [Low-power source](../../evidence/dialogue-transitions/2026-11-02/clockwork-low-1600.png), [steady source](../../evidence/dialogue-transitions/2026-11-02/clockwork-steady-1600.png), [restored source](../../evidence/dialogue-transitions/2026-11-02/clockwork-restored-1600.png)
- [Clockwork motion, 2.4-second MP4 from native captures](../../evidence/dialogue-transitions/2026-11-02/clockwork-motion.mp4)
- [1600×1000 cadence measurements](../../evidence/dialogue-transitions/2026-11-02/cadence-1600.json) and [1280×720 measurements](../../evidence/dialogue-transitions/2026-11-02/cadence-1280.json)
- [Clockwork at 1280×720](../../evidence/dialogue-transitions/2026-11-02/clockwork-steady-1280.png)

Decision: implemented and ready for user review. Questline revision remains the next collaborative slice, beginning with Chapter 00.
