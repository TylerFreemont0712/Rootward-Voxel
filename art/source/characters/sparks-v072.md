# Sparks cast — v0.72 source record

Nell, Mira, Rowan, Bram and Tessa use the selected v0.7 wardrobe references listed in `sparks-v072-plan.json`. Generated masters are preserved in `sparks-v1`; the selected complete-figure registration is `sparks-v2` for each resident. The original village `v1` paintings remain unchanged. Approved adventurer SE/NE sheets supplied the camera, gait and pose layout. All source painting and blink edits used the built-in `image_gen.imagegen` tool with transparent background. Model identifier and seed were not exposed.

Each `*/sparks-v1/` folder contains:

- `SE.png`, `NE.png`: native 1254-square, 3×3 paintings. Poses 0–7 walk; pose 8 is neutral.
- Matching `*.generation.json`: exact prompts, reference paths/hashes and original generated output paths/hashes.
- `SW.png`, `NW.png`: exact per-cell horizontal mirrors, retaining pose order.
- `idle-se.png`: the complete 418-square neutral, extracted unchanged.
- `blink-reference.png`: a 250-square eye-edit reference at neutral crop `[90,35,250,250]`. It is not a runtime frame.
- `blink-generated.png`: the generated closed-eye reference. Only the two eye ellipses in `blink-assembly.json` are composited onto the complete neutral, preserving its alpha and other pixels.
- `blink-se.png`, `blink-sw.png`: complete 418-square blink keys. `authoring.json` records input hashes and the adapter hash.
- `sheet.png`, `provenance.json`: the existing directional packer’s 1536×5376 registered source atlas and integer translations/hashes.

Nell’s first SE/NE attempts are preserved as `SE-initial.png` and `NE-initial.png`, with their generation records. The second imagegen pass restores the walking stick across every phase. Her initial neutral/eye reference is also preserved; the generated blink used that initial crop, then only its eyelids were applied to the final complete neutral. The generation record tracks the renamed initial reference and the argument used at generation.

## Complete-figure registration

The generated v1 paintings have slightly uneven row spacing. A few silhouettes cross the nominal 418-pixel boundaries, which would cut a hat or copy a fragment into the neighbouring frame. `pipeline/reflow_cast_source.gd` recovers the three separated complete figures in each column and places them in true cells using integer vertical translations. It preserves the original paintings in v1 and records every source rectangle, destination and hash in v2. Existing eye-only blink differences follow the same neutral translation; recovered hair and hats remain intact. The normalized source is packed by the existing directional packer and built by `scripts/art.sh`, without resampling the painted figures.

```sh
godot --headless --path . -s res://pipeline/reflow_cast_source.gd -- \
  --source res://art/source/characters/<id>/<painted-version> \
  --output res://art/source/characters/<id>/<NEW-registered-version>
godot --headless --path . -s res://pipeline/prepare_directional_walk.gd -- \
  --source res://art/source/characters/<id>/<registered-version>
scripts/art.sh
```

The reflow adapter refuses an existing output directory. It is a source registration step, not another runtime build path. Its output contains complete SE/NE paintings, exact SW/NW mirrors, full neutral/blinks and an authoring record. Tests compare all eighteen recovered pose crops byte for byte with their generated masters.

## Reproduce source preparation on a new version

After authoring the final SE/NE paintings, extract the neutral and blink reference:

```sh
godot --headless --path . -s res://pipeline/prepare_cast_source.gd -- \
  --source res://art/source/characters/<id>/<new-version> --stage references
```

Generate the closed-eye reference, set the two local eye rectangles in `blink-assembly.json`, then assemble and register:

```sh
godot --headless --path . -s res://pipeline/prepare_cast_source.gd -- \
  --source res://art/source/characters/<id>/<new-version> --stage assemble
godot --headless --path . -s res://pipeline/prepare_directional_walk.gd -- \
  --source res://art/source/characters/<id>/<new-version>
scripts/art.sh
```

These are guarded source-authoring steps. Normal builds still use only `scripts/art.sh`; they do not invoke imagegen or regenerate artist sources. The five `sparks_*` skins select `sparks-v2` and use `selectable: false` in the existing character catalog and inherit all motion from the shared template. The boy remains the active player and existing resident IDs retain their previous art.

Derived gallery PNGs and GIF inputs come from `tools/sparks_sprite_gallery.gd`. Half-size contact sheets resize for documentation only; the source packer performs integer translation without resampling. Native playback review uses `tools/sparks_cast_review.gd` with the actual `SpriteAdventurer`, shared SpriteFrames and gameplay-scale camera. See [the gallery](../../../docs/concept/v0.72/cast-and-robots.md).
