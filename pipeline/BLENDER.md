# Visually editing world assets in Blender

This is the working human-editable route. Prototype code can create a seed; after handoff, `model.blend` is the editable source and Godot consumes its exported GLB. Rebuilding a runtime model does not regenerate or save over the Blender source.

The [detail material library](MATERIALS.md) adds fifteen catalog recipes and runtime pictures for future authoring. `blender_retexture.py` honors optional roughness/metallic values. No existing master was retextured for this addition: builder finishes use saved instance overrides. Deliberately changing an adopted model's defaults still requires editing its existing source and reviewing the export. If you rename an original material, update its `finish_slots` binding after checking the GLB audit.

## Start here: edit a shipped model

1. Find the asset in `pipeline/world-catalog.json` (its `source` is the master) and open that `model.blend` in Blender with **File → Open**. These files already exist; do not run `seed` or `init` again.
2. Use the Outliner to find the parts. Most masters are joined by material role (walls, roof, timber, glass, metal); the clockshop and workshop furniture are one mesh per material under an empty named for the asset. Mesh names identify shared material roles.
3. For a broad change select the relevant mesh. For a local change enter Edit Mode with **Tab**, select the intended vertices or faces and move them. New detail is easiest added as new geometry in the same materials (the clockshop revision scripts under `art/source/world/clockshop-interior/` show how, with the shared `house_kit`).
4. Keep the imported root, scale and base in place. Moving a footprint or entrance also needs a matching layout review in Godot.
5. Save with **Ctrl+S**, then from the project root:

```sh
scripts/world-art.sh build <asset-id>
godot --headless --editor --import --quit
scripts/test.sh flow
scripts/play.sh
```

The build exports a candidate, checks it in Godot, and updates `assets/world/<id>/model.glb` plus its manifest. Every placement of that asset changes together. Do not edit the exported GLB as the master; the next build replaces it. For a deliberate redesign, copy the master into a new `vN/` directory, edit that, and point the catalog entry's `source` at it so the earlier version is preserved.

To look at a candidate before promoting it: export with `pipeline/blender_handoff.py` and view it with `tools/asset_shot.gd <id> <png> <candidate.glb>`.

The installed authoring version used here is Blender 5.2.2 LTS; the engine is Godot 4.7.2. The script finds `blender` on PATH or the current local install. On another machine set `BLENDER_BIN` and, if needed, `GODOT_BIN`. Blender is an authoring dependency only; the game loads supplied runtime GLBs.

## Ownership: one source of truth per asset

`pipeline/world-catalog.json` records the source/version, runtime file, authority, pivot, logical footprint and behavior notes.

- `authority: "blender"` selects the runtime GLB built from the artist's source. Editing the old generator does not change that asset in-game. Missing selected output is an error, not permission to silently regenerate the shape.
- Logical footprints, supported cells, mechanism state and player commands remain in `core/`. Blender owns visible shape and materials; it does not grant new gameplay capabilities.

An agent must read the catalog before changing art. After adoption, modify the existing `.blend` or guide the human through it. Do not regenerate a fresh approximation from code and discard visual edits. Preserve prior accepted versions when making a deliberate redesign.

## First handoff of a prototype recipe

These commands are **one-time initialization**, not the normal edit loop:

```sh
scripts/world-art.sh seed <asset-id>
scripts/world-art.sh init <asset-id>
scripts/world-art.sh build <asset-id>
scripts/world-art.sh compare <asset-id>
```

The supplied assets have already completed this sequence. `seed` and `init` refuse to overwrite existing source/seed files. For a new procedural version, first choose a new version/source directory in the catalog and add/adjust its explicit seed recipe. The seed exporter's recipes covered the village models that were retired on 2026-11-05; new models are authored directly in Blender (below), so `seed` is effectively retired. To see an editable source as the game's camera does, run `blender --background --factory-startup --python tools/blender_preview.py -- <model.blend> <out.png> [yaw] [ortho_scale] [look_height]`; it renders without saving the file.

`seed` runs only the selected maker, turns material batches into ordinary grouped meshes, exports lossless PNG textures in GLB and checks the result before saving the seed/provenance. `init` imports that GLB, packs the textures and saves an editable `.blend` with an orthographic material-preview view. It does not weld, simplify or remesh the geometry.

## Painting a source with the texture pack

`scripts/world-art.sh retexture <id>` then `build <id>` bakes `pipeline/texture-catalog.json` into an adopted `.blend` (new pictures on every catalogued material, new world-scale UVs). It is a deliberate source edit: the file you had is kept as `model.pre-retexture.blend`, geometry is untouched, and `retexture.json` records which catalog it came from. If the file is open in Blender, close it first, or run the same function inside the open session (`blender_retexture.retexture(catalog, root)`) and save. See [world assets](WORLD_ASSETS.md#materials-and-textures).

## What build and compare actually check

`build` reads the saved Blender source and exports all objects in its active scene, including hidden mesh objects. Keep reference-only objects in a separate scene, not merely hidden in the export scene. Cameras, lights and animations are excluded. Mesh simplification/compression tools are disabled. Keep textures in supported glTF material nodes; imported PNGs export without pixel loss in the current round trip.

A candidate must reimport in Godot, contain triangles and have finite bounds inside the 128-unit asset envelope (raised from 64 on 2026-10-29 for town-sized ground models). The tool records source/runtime/exporter hashes, dimensions, triangle count, material names and texture/color/roughness audit data. It checks that the `.blend` hash did not change during export. It promotes the candidate only after that audit, retaining one previous runtime export in `.cache/world-art/<id>/previous.glb`.

`compare` is the stricter **unedited round-trip** proof. It checks triangle-corner positions and UVs at 0.0001 precision, normals within 0.001 vector distance, and the audited material values/decoded texture pixels against the original seed. File bytes and vertex order may differ. All four supplied seeds passed this check. It is not a promise that lighting, all shader settings or every possible Blender material are identical.

After an intentional visual edit, compare against the original may correctly fail. Review the new result in-game; do not undo the artist's change just to satisfy an old geometry hash. `scripts/test.sh` validates the selected source/export manifest and actual runtime asset loading, not a demand that every future model equal its original seed.

## Scale, axes, materials and separate parts

One cell is one Godot unit. Blender uses meters at unit scale 1. glTF handles Blender's Z-up/Godot's Y-up conversion. Keep the imported asset root and orientation; do not manually rotate 90° to compensate for the two tools' axis displays. In Godot the house front is +Z; the logical adapter maps `[x,y,height]` to `(x,height,-y)`.

A building's pivot is its ground origin. Ground masters (`haverlund-square-ground`, the lane set) keep whole-area coordinates so their paving, stairs and walls line up with the area document. A new small prop should have its own ground pivot and local dimensions. Keep decorative overhang separate from the blocking footprint.

The seed preserves simple palette/material roles and small texture patterns. Arbitrary Blender node networks do not transfer as-is; use supported glTF materials or deliberately bake/recreate the needed surface. Godot ShaderMaterials, including animated water, remain engine effects. See [Godot export limitations](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/exporting_3d_scenes.html) and [format guidance](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html).

Keep a wheel, gate leaf or other moving part separate with a useful pivot before introducing behavior. The current building shells are decorative; the handoff does not invent enterable doors, interiors or programmable subparts.

## New hand-made assets and later expansion

For a new bench/house made directly in Blender, a procedural seed is optional. Save a versioned `model.blend`, register its source/runtime/footprint in the catalog, run `build`, then add a deliberate placement/adapter in the current clearing. The present view only has placement hooks for its existing asset IDs; a catalog entry alone does not spawn a new asset.

Follow [world asset rules](WORLD_ASSETS.md), [area rules](AREAS.md) and [review](REVIEW.md). General area-document loading and a custom world builder remain deferred. Extend this same source/catalog/export boundary when those systems arrive.
