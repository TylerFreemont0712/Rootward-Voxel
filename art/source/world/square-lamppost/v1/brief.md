# Rootward Square lamp — 2026-10-26

A deliberate new Blender model study after the square lamps in
`reference/voxel-isometric.png`: dark timber and charcoal metal, a simple hanging
amber lantern, a cream limestone planter and a small clipped evergreen.
Use bevel highlights, broad colour variation and fine brown silhouette lines.
Keep the existing painted player and camera.

The earlier `lamppost/v1/model.blend` remains untouched. This model starts from
that file's hierarchy and post, replacing its lantern, finish and pedestal.
`model.blend` is the editable authority after authoring. The authoring script
is a guarded design record, not a second build pipeline.

The separate glass mesh retains the material name `lamp_glass`. Illumination,
halos and command validation still use the existing lamp mechanism. The planter
is decorative within the existing post's grid clearance; no collision or save
format changes. Export with `scripts/world-art.sh build square-lamppost`.
