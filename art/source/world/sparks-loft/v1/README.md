# Sparks loft — bespoke source pack

Fourteen new Blender assets furnish the first Sparks & Machines room after the selected T7a concept. All geometry is real 3D, with the existing fine sepia hull outlines. The original shell is deliberately refined with its first source preserved.

The five selected painted surfaces are oak v2, cream plaster, the patchwork quilt, rag rug and harbour view. Six original image outputs are preserved, including the earlier yellow oak. [Exact built-in imagegen prompts and input hashes](prompts.json) record their origin. Playing needs no generator, Blender process or network.

## Editable masters

| Asset | Native bounds, X × height × depth (m) | Runtime meshes |
|---|---|---:|
| [loft-bed](../../loft-bed/v1/model.blend) | 2.19 × 1.46 × 3.01 | 9 |
| [loft-desk](../../loft-desk/v1/model.blend) | 2.60 × 1.74 × 1.19 | 15 |
| [loft-chair](../../loft-chair/v1/model.blend) | 1.02 × 1.34 × 0.90 | 6 |
| [loft-shelf](../../loft-shelf/v1/model.blend) | 2.49 × 2.42 × 0.68 | 17 |
| [loft-luggage](../../loft-luggage/v1/model.blend) | 1.36 × 1.37 × 1.72 | 8 |
| [loft-cabinet](../../loft-cabinet/v1/model.blend) | 1.12 × 1.72 × 0.88 | 7 |
| [loft-wall-life](../../loft-wall-life/v1/model.blend) | 1.88 × 2.30 × 0.62 | 16 |
| [loft-rug](../../loft-rug/v1/model.blend) | 3.70 × 0.05 × 2.69 | 2 |
| [loft-travel-stacks](../../loft-travel-stacks/v1/model.blend) | 1.52 × 1.25 × 1.13 | 14 |
| [loft-window-life](../../loft-window-life/v1/model.blend) | 1.08 × 0.60 × 0.52 | 10 |
| [loft-postcard](../../loft-postcard/v1/model.blend) | 0.88 × 0.64 × 0.10 | 4 |
| [loft-tape-machine](../../loft-tape-machine/v1/model.blend) | 0.75 × 0.71 × 0.59 | 8 |
| [loft-hotaru](../../loft-hotaru/v1/model.blend) | 0.62 × 0.72 × 0.56 | 12 |
| [loft-cable](../../loft-cable/v1/model.blend) | 0.51 × 1.13 × 2.57 | 1 |

## Authoring boundary

`author.py` is the guarded one-time record; it refuses existing masters. It is not a normal build command. `refine_shell.py` edits the adopted shell with a preserved `model.pre-furnishing.blend`. `polish_sources.py`, `refine_surfaces.py`, `quilt_export_finish.py` and `complete_uvs.py` document deliberate edits to saved source, including the Blender 5 glTF tint-node correction. `refine_marked_assets.py` and `finish_marked_review.py` record the annotated review corrections, with `model.pre-marked-review.blend` copies preserving the preceding masters. Crates now have matching slats and corner joints on every side; the quilt fits above the footboard and inside the posts; the coat has weighted folds and loose sleeves, and the satchel has a soft gusset and a broad strap. Both north windows sample one correctly proportioned panorama with a shared horizon: the upper porthole sees sky. `lived_in_revision.py` and `lived_in_linen_finish.py` then record the slept-in bedding, coat over the chair and lower bag hanging on taut straps. Each of those three prior masters is preserved as `model.pre-lived-in.blend`. Future art edits start from each `model.blend`.

Normal export: `scripts/world-art.sh build <asset-id>`. The world catalog selects source/runtime paths, and each GLB manifest pins source, output, geometry and material/texture audits. Surface paintings are packed in the editable sources; do not run the generic `retexture` command over these bespoke materials.

## Composition and behavior

Fifteen placements live in the area document: a bed under the round window, desk and reader, Hotaru on the bookcase, chair, coats and bags, luggage and boots, cabinet and lantern, windowsill keepsakes, postcard, rug, moving-in crates and books, and a cable linking reader and shelf. Two differently turned/scaled travel clusters demonstrate reuse. Furniture blocks routes through the same document; the rag rug stays walkable.

The stage renders provisional tape after a real WASI test. Speak commits that validated proposal; the window lights, eyes appear and rotor moves only from committed greeting/quest progress. A source edit clears the test tape and disables Speak. The real returned print commands also type into a ghost speech bubble over the player; wrong names and multiple prints are preserved. Replay restarts that output. Speak follows with committed speech, Hotaru’s sleepy morning greeting, three authored replies and a return to experimentation. Her question remains visible while the player chooses; introduction read state and waking persist through Continue. The desk and reader sit flush against the west wall, with a fitted cable, and new players begin beside the desk. The area document’s stairwell profile lowers the actual player onto the three existing treads, including when using click-to-walk, and raises them again on ascent. The hatch now connects to the saved workshop described below. Free following and movement-key mapping remain outside this chapter.

The final [unedited bed rebuild](rebuild-proof.json) preserves source, runtime bytes and the complete audit exactly. [Validation](validation.json) records all source/output/painted-input hashes and the selected gameplay captures.

The [current review](../../../../../pipeline/reviews/2026-10-27-loft-lived-in-and-stairs.md) uses an ordinary week of dozing rather than a long shutdown. The printer’s addressed-message bell gets Hotaru’s attention; the lodger has no established origin or special machinery talent.

The [first workshop jobs](../../../../../pipeline/reviews/2026-10-27-workshop-first-jobs.md) subsequently connect the downstairs room and two lighting routines. `remove_sill_plant.py` deliberately removes only the windowsill plant from `loft-window-life`, keeping its book and keepsake box. The prior master is preserved as `model.pre-sill-plant-removal.blend`; `sill-plant-removal.json` records both hashes. The other loft plants, models, paintings, boy and camera are unchanged. Earlier validation and captures above describe their dated milestones.

The [tablet and wall screen review](../../../../../pipeline/reviews/2026-10-27-tablet-and-wall-screen.md) adds `field-tablet` (guarded first authoring in `field_tablet.py`) and replaces the loft desk mug’s flat disc with a hollow enamel mug (`desk_mug.py`; the prior master is `model.pre-empty-mug.blend` and `desk-mug.json` records both hashes). The hand console model `loft-hand-terminal` is no longer placed; its master and runtime stay as history.

The [loft and stairs review](../../../../../pipeline/reviews/2026-10-28-loft-and-stairs.md) matches the loft to the workshop as it stands on Spindle Lane. `flipped_loft_revision.py` deliberately edits the adopted shell (the prior master is `model.pre-flip.blend`; `loft-shell/v1/flip-revision.json` records the hashes): the room grows to 14×12 and is seen from the yard side, its street wall gains three windows and its yard gable a second window beside the centred round window (copies of the tall window's own parts), and the stair comes up through a railed opening in the middle of the floor. Floorboards, floor structure and the stairwell are rebuilt in the shell's own materials; everything else is the adopted geometry, moved. `flipped_loft_props.py` first-authors `loft-wardrobe`, `loft-window-seat`, `loft-rocking-chair` and `loft-floor-plant` for the new space.
