# Brook mill  /  6 × 5 tile shell

Status: **unplaced candidate**, version v1. Separate wheel • dry sluice • loading hoist • roof vent.

Editable authority: [model.blend](model.blend), authored in Blender 5.2.2 LTS.
Export: `assets/world/brook-mill/model.glb`; registered with `status: candidate_unplaced` in `pipeline/world-catalog.json`.
One tile is one metre. Ground origin, front Godot +Z / Blender -Y. Visible bounds (width, height, depth): [7.905, 8.639, 7.01] metres.
The original painted player remains 1.45 metres tall. House door leaves are 2.18 / 2.28 metres high.

Normal rebuild: `scripts/world-art.sh build brook-mill`. Edit the saved Blender source; do not rerun the historical makers.
Initial authorship, deterministic seed and deliberate review edits are recorded in [provenance.json](provenance.json).
Supported Principled materials, rough nonmetal surfaces, opaque colour textures packed into the Blender file and GLB.
Uses the v1 texture pack for wood, plaster, stone, bark and window panes where appropriate; tile geometry and leaf crowns use palette materials.
World-sized box UVs repeat once per metre. No network, Blender or generation service is required to load the supplied GLB in Godot.

Footprint in the catalog is a proposal for later placement. Crowns, porches, eaves, balcony, wheel and sluice have decorative overhang.
No area placements, traversal rules, interiors, door interactions or runtime mechanism bindings were added by this asset set.
The mill's `waterwheel_pivot` is a separate local-X axle assembly for later integration; the sluice is dry and static.

Review: `evidence/scenery-candidates.png`, rendered in Godot at zoom 13, game camera heading/elevation and original actor scale.
