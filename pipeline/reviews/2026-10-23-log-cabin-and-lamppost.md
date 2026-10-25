# Log cabin and lamppost, recreated from the concept and adopted into Blender — 2026-10-23

- **Asset/area/source version:** `log-cabin` v1 and `lamppost` v1 (new): `art/source/world/<id>/v1/model.blend` with `seed.glb`, `provenance.json` and a filled [asset brief](../../art/source/world/log-cabin/v1/brief.md) ([lamppost brief](../../art/source/world/lamppost/v1/brief.md)); runtime `assets/world/<id>/model.glb`; catalog entries with authority `blender`. Placed in `content/areas/kindle-hollow.json` (three cabins; every post lamp in it and in `rune-mill` is the lamppost). Recipes: `pipeline/world_recipes.gd`. Two palette colours and one emissive material were added for them: `stone_warm`, `lamp_glass`, `window_glow`.
- **Intended change and reference qualities:** the violet-roofed log cabin and the hanging-lantern lamppost from [reference/voxel-isometric.png](../../reference/voxel-isometric.png), replacing the generic plaster cottage and the thin procedural lamp where they stand. Cabin: chunky violet tiles with a lighter lip, log walls with dark chinking on a limestone foundation, an arched stone door, a round gable window, a stone chimney, a glowing side window. Lamppost: a square timber post on an iron foot, a braced arm, a chunky lantern whose glass the game can light, a limestone pedestal.
- **Build/check commands actually run:**
  - Design loop before adoption: `tools/asset_shot.gd -- <id> <png> recipe`, at gameplay zoom 13 and in close-ups, beside the character, against crops of the concept. It took several passes (below).
  - `scripts/world-art.sh seed|init|build|compare` for both assets: seed exported without geometry loss (cabin 10,044 triangles, lamppost 432); `init` saved the `.blend`; `build` audited and promoted the GLB; **`compare` passed for both** (geometry/UVs at 0.0001, normals at 0.001, material colours and lossless texture pixels). The sequence was run twice: the first drafts were replaced after the side-by-side review (see defects).
  - `tools/blender_preview.py` renders each `.blend` from the game's camera in Blender itself (EEVEE): both show the same textured designs. The final `.blend` hashes still match the manifests after rendering, so nothing was saved.
  - `scripts/test.sh`: all suites pass. New checks: the lamppost is the post lamp's model and its `lamp_glass` mesh is found by material; lit lamps swap the glass and dark ones keep the model's own; the halo hangs where the lantern is; every lamp (post and beacon) can be lit; Kindle Hollow places the cabin and each cabin node holds the model's meshes; the cabin blocks exactly the cottage's cells (`test_area`, both facings); the four new `seed`/`init` calls refuse to run on the adopted sources (`test_authoring_guards.py`, 7 checks). The catalog loop in `test_world_art.gd` covers both new assets: runtime hash, recorded source hash, loads without Blender, geometry matches the audit.
  - `tools/playthrough.gd`: **5 of 5 quests complete, 19 of 19 lamps lit** through the real controls, with the new lamps.
  - `scripts/screenshot.sh`: refreshed `title.png`, `voxel-clearing.png`, `notebook-*.png`, `map.png`, `character.png`.
- **Gameplay resolution/camera and renderer:** 1440×900 for the asset and area shots, 1600×1000 for the tour; GL Compatibility on an AMD Radeon 680M. Orthographic, 31° elevation; size 13 is the gameplay camera, the scale at which the cabin's size against the character is close to the concept's. Kindle Hollow's landing view (`area_shot.gd kindle-hollow … 26 8 7 1`): 221 draw calls, against 208 before the new models. Frame rate measured 122 to 168 fps across runs, on a machine shared with other work, so it is not a clean comparison.
- **Selected evidence:** [concept beside the built asset and the Blender render](../../evidence/cabin-lamppost-vs-concept.png) (left to right: concept, runtime GLB in Godot, the `.blend` in Blender); [in Kindle Hollow, lamp lit](../../evidence/hollow-cabin-lamppost.png); [the play start](../../evidence/voxel-clearing.png) and [title backdrop](../../evidence/title.png), which now show both.

## What was observed

- Side by side with the concept the cabin matches in silhouette, roof colour, log walls, arched door with voussoirs, round gable window with log ends under the rake, chimney and the pale finial at the front peak. The side window glows amber against its dark frame, in Godot and in Blender, so the emissive material survives the Blender round trip. At gameplay scale it reads clearly as a different, warmer building than the cottage beside it.
- The lamppost reads as the concept's lamp at gameplay scale: tall post, arm and brace, a chunky lantern, an iron foot and a limestone pedestal. Lit, its glass glows and the halo and pooled light sit at the lantern (the model's own glass bounds place them). Unlit it keeps its own smoked glass.
- Adding the cabin and lamppost changed no rule: the cabin's catalog footprint (2.90 × 2.86) blocks the same three-by-three cells as the cottage, and the area tests, routing and the whole playthrough are unchanged.
- The `.blend` files are grouped by role (Masonry, Roof, Timber, Windows, Metal; Lantern for the lamp), one mesh per material, textures packed, so a human can select the roof or the glass at once. Individual tiles and logs are not separate objects, as with the other seeds.

## Defects found and fixed during the work

- The first side window drew its glass behind a solid frame slab, so the glow never showed. It is now four border bars round a recessed pane.
- The pale and dark strips that round each log were put on the +x/+z face of every wall, so they were hidden on the −x and −z walls. They now follow the wall's outward side.
- The first roof was pale with near-black tiles and the walls were low under a deep overhang. Tiles are now chunkier with bigger lips and a milder light/dark mix, the walls are taller and the overhang shorter, so more wall and the window show.
- The first drafts were adopted before the side-by-side comparison showed these gaps. Their `.blend` hashes matched the manifest (no human edit), so they were moved to a temporary folder outside the repository, which is not kept, and the one-time handoff was redone cleanly rather than bumping a version for a draft nobody had reviewed. Nothing human-edited was replaced. Only the redone v1 exists now.
- `tools/blender_preview.py` first turned the model the wrong way round Z; fixed.

## Known gaps

- Tiles, arch and round window are built from boxes, so there is no rolled tile edge, gloss or painterly highlight as in the concept image; the geometry is chunky and voxel-like rather than a copy of the painting. The cabin has no porch, flower box, barrel or bench (the excluded props).
- The concept's conifer in the planter is left out (no shrubs in this prototype), so the pedestal is solid. Say if you want it back.
- Every lamp points its lantern the same way (+z). There is no per-lamp facing in the area document yet.
- `compare` checks albedo and roughness, not emission, so the glow is verified by eye, not by the audit.
- Only three homes are cabins; the other cottages, the workshop and the teal-roofed mill are unchanged. The concept's market stall, benches, signs and bridge posts are not built. The beacon, gates, decks and wheel stay procedural.
- No human play session has judged it; the reviews are mine, at 1440×900 and 1600×1000 (no 1280×720 pass for these assets). `tools/blender_preview.py` uses `World.use_nodes`, which Blender 6 will remove.

## Decision

Accept as the first concept-matched, Blender-adopted house and lamp; keep the cottage and mill as they are.

## Next smallest proofs

1. Open `art/source/world/log-cabin/v1/model.blend` in Blender, make one visual edit (for example the tile colours or the door), save, run `scripts/world-art.sh build log-cabin` and check it in game: this is the human half of the loop, which this review did not exercise.
2. Build the concept's teal-roofed water mill the same way (a new version of `mill-house`), then the market stall.
3. Add an optional `facing` to lamps in the area document so the lanterns can turn toward the road.

## Addendum: the lamppost after a hand edit in Blender (2026-10-23)

- The project owner opened `art/source/world/lamppost/v1/model.blend`, lifted the post, foot, arm and lantern onto the pedestal, centred the pedestal under them and deleted the dark core `stone_dark_geometry`. Object placement only: every vertex is unchanged (checked object by object against Blender's `model.blend1` backup of the first version). The lamp is now 2.86 high.
- `scripts/world-art.sh build lamppost` promoted that version (7 meshes, 408 triangles). The game needed no change except one test: it required the halo below a height of 2.0, which encoded my first geometry. It now checks that the halo sits at the lantern glass's bounds wherever the model puts it.
- The evidence images above show the lamppost as first built, before this edit; they are not refreshed yet.
- Not yet saved: a set of dark cross bars on the lantern's four glass faces (a separate `lantern_mullions_geometry` object), added in the open Blender session and checked in the game from a candidate export. The lit lantern then reads as four glowing panes, as in the concept.
