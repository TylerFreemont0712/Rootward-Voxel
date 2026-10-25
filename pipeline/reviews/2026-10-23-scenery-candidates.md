# Six unplaced scenery candidates — 2026-10-23

Status: completed standalone asset handoff, awaiting the user's visual choice. No area placements or gameplay connections were added by this work.

[Combined final PNG](../../evidence/scenery-candidates.png) · [source index and rebuild instructions](../../art/source/world/expansion-kit/v1/README.md)

The PNG shows actual exported GLBs rendered in Godot, with the unchanged painted player in every panel. All six captures use orthographic size 13, the existing camera heading/elevation and the same 1.45 m actor scale. The 3696×2480 PNG preserves the six native 1200×1000 renders without resizing or painting over the models.

- **Hearth oak:** bent branching trunk, exposed buttress roots, broad irregular leaf crown and moss.
- **Ridge cedar:** taller blue-green silhouette, layered bough pads and fluted trunk.
- **River willow:** arched scaffold limbs and separated hanging foliage curtains.
- **Hearth house:** proposed 5×5 footprint, violet clay tiles, stone-arched entry, porch, shutters and east dormer. One extra tile on every side of the original 3×3 home.
- **Lantern loft:** proposed 7×7 footprint, two storeys, teal gambrel roof, projecting balcony, octagonal oriel and brass finial. Two extra tiles on every side.
- **Brook mill:** 6×5 building shell, detailed separate waterwheel, bearing supports, dry trestle launder and feed gate, upper loading platform/hoist, louvred roof monitor and weather vane.

Each ID has a new versioned `.blend`, provenance and brief under `art/source/world/<id>/v1`, plus an audited GLB/manifest under `assets/world/<id>`. New catalog entries carry `status: candidate_unplaced`. The set uses packed v1 textures for plaster, stone, wood, bark and panes where appropriate; modeled tiles and leaf patches use palette materials. No raster stand-ins or new runtime authoring services are involved.

The first camera review led to broader foliage colour patches, softened leaf contour edges, the loft's broken-pitch roof, and the mill monitor. All new meshes have UVs, including untextured leaf surfaces, so the complete geometry participates in the established Godot audit. The loft's underboards and gables were deliberately finished in the saved Blender source after the roof profile edit.

Validation:

- All six passed `scripts/world-art.sh build <id>` with finite bounds, triangles, materials and complete geometry audit; source hashes remained unchanged during export.
- A second build of `brook-mill` reproduced the recorded GLB hash and preserved its Blender source. All six source/output hashes match their export and kit manifests.
- Native Godot front and 180-degree rear views were inspected for all six. Temporary individual renders and rear contact sheet live in `.cache/world-expansion-v1/`.
- The final `scripts/test.sh` run passed: world/WASI 73, areas 90, build rules 90, interface 32, app 89, movement 30, painted art 100, skins 42, world art 113, authoring guards 7 and pipeline handoff 298 checks. Log: `.cache/world-expansion-v1/tests.log`.
- Searches of `content/`, `app/`, `core/`, `scenes/` and `ui/` found no references to these six candidate IDs. Existing assets, areas and other ongoing workspace changes were not reverted.

The mill's `waterwheel_pivot` keeps a useful local X axle for a later adapter. It remains static here; no water effect, mechanism binding, enterable building or traversal change is supplied. Proposed blocking footprints exclude decorative roof/crown/porch/balcony/wheel/launder overhangs and require a deliberate layout review when the assets are placed.
