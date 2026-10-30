# Sparks cast skins and six rolling robot concepts — 2026-10-29

The user requested 5–6 wheeled robot concepts and the remaining cast as sprite and movement sheets, with human characters using the existing sprite pipeline. This pass supplies six robots and new concept-wardrobe skins for Nell, Mira, Rowan, Bram and Tessa. The approved boy, Hotaru, original resident appearances and existing journeys retain their artwork and behavior.

## Reviewable result

[Gallery with motion previews and individual sheets](../../docs/concept/v0.72/cast-and-robots.md).

The human skins are `sparks_nell`, `sparks_mira`, `sparks_rowan`, `sparks_bram` and `sparks_tessa`, registered as hidden appearances in the existing character catalog. All share the approved template’s poses, anchors, scale, timing, front blinks and breathing. SE/NE were painted from the approved gait and selected v0.7 identity references; SW/NW are exact per-cell mirrors. No bone rig or private animation settings were added.

Generated masters and their exact prompt/reference/output records remain in `art/source/characters/<id>/sparks-v1/`. The initially uneven row spacing let a few hats cross nominal cell boundaries. The selected `sparks-v2` source recovers all complete figures using integer translation, preserving the original paintings and all opaque pixels. The guarded `reflow_cast_source.gd` records source rectangles, destinations and hashes; the existing directional packer and `scripts/art.sh` compile the result. Ninety painted figures retain their opaque pixels and have at least four pixels clear to the source-cell edges. See [source/registration notes](../../art/source/characters/sparks-v072.md) and [pixel review record](../../art/source/characters/sparks-v072-review.json).

The user noticed the tightly framed blink images during authoring. These were eye-edit references, not runtime frames. Finished blinks retain the full character and change only two eye patches; the complete neutral and blink previews show hair, hats, props and boots intact. Nell’s stick was also corrected across the gait, with first attempts retained alongside the chosen edit.

The robots are Pip (postal sorter), Trowel (gardener), Wick (lamplighter), Heron (small crane), Tender (maintenance helper) and Tally (provisional trading assistant). Each sheet contains a turnaround, four rolling keys, off/idle and two work keys. Sources, prompts and hashes are in the [robot catalog](../../art/source/robots/v0.72/catalog.json). Preview crops compensate for generated row spacing and pad the complete wheels/tools. These remain robot concept and motion sheets: production directional registration, coherent wheel rotation and runtime work animation are future integration work. This pass adds no robot controller, quests, residents or placements.

## Native visual review

`tools/sparks_cast_review.gd` runs the actual `SpriteAdventurer` with the approved boy beside all five new skins in four directions. It captures walk playback and an eight-second neutral/breath/blink sequence. Both 1600×1000 and 1280×720 reviews show 24 complete actors; all 12 front views blink and all rear views retain their neutral artwork. The orthographic heading, elevation and approximate gameplay pixel height follow the existing character review fixture.

- [1600×1000 directions](../../evidence/sparks-cast/2026-10-29/1600x1000-directions.png)
- [1600×1000 blinks](../../evidence/sparks-cast/2026-10-29/1600x1000-blink.png)
- [1280×720 directions](../../evidence/sparks-cast/2026-10-29/1280x720-directions.png)
- [1280×720 blinks](../../evidence/sparks-cast/2026-10-29/1280x720-blink.png)

The derived documentation movement sheets and GIF inputs come from `tools/sparks_sprite_gallery.gd`; preview resizing does not alter source paintings or runtime atlases. Robot preview scale is fitted for comparison rather than a world-height decision.

## Verification

- `scripts/art.sh`: passed; 100 painted-art checks and 111 shared-frame checks on the final registration.
- Full `scripts/test.sh`: passed on the final registration, including 111 shared-frame checks, 10 authoring guards, 1,273 pipeline/handoff checks and 121 ground-art handoff checks.
- New checks cover generated-master/output provenance, exact recovery of all 18 poses per skin, complete neutral references, per-cell mirrors, blink isolation and authoring overwrite guards.
- Source audit: all 23 generation records match preserved input/output hashes; 62 protected template, boy and original-cast files remain unchanged.
- Native playback: 1600×1000 and 1280×720 passed, including 12 front blinks and unchanged rear views.
- `git diff --check`: passed.

The image tool exposed no model identifier or seed. Source records state that limitation. Network/image generation is used only for authoring; the supplied runtime skins and existing game remain playable offline. No commits, pushes or external publishing were performed.
