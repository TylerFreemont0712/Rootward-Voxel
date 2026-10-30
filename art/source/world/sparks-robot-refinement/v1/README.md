# Six robot model refinements — 2026-10-29

The user requested closer 3D matches to the approved [robot sheets](../../../../../docs/concept/v0.72/cast-and-robots.md), beginning with Pip/Wick and then extending to all six. Their later Pip instruction supersedes the sheet’s bag: **no satchel; front compartments contain small packages**. All six get a small eye blink.

## Editable authority

Each model’s `art/source/world/robot-<name>/v2/model.blend` is now the adopted editable source. The original v1 files are preserved intact. Open the saved v2 file and export normally:

```sh
scripts/world-art.sh build robot-pip
scripts/test.sh
```

The records here are deliberate, one-time native source edits, **not replacement generators to run over adopted work**. New-version creation refuses existing v2 files; follow-up edits keep pre-edit source backups and refuse a repeated application.

| Model | Refinement |
| --- | --- |
| Pip | Rounded red postbox, brass face mount, real cubbies containing wrapped parcels, large two-wheel chassis/caster, jointed mitten arms, rear service cover. No bag. |
| Wick | Tapered cream torso, rounded lantern head and flared cap, broad chassis, front caster, articulated brass arms and a detailed telescoping pole/carried lantern. Pole stays in his own left hand: Blender +X with front -Y. |
| Trowel | Rounded cream watering-can body, two wheels/caster, tapered spout with perforated rose, carrying handle, open rear terracotta pot, modeled leaves/flowers and service cover. |
| Heron | Rounded crane cabin, diagonal bumper stripes, broad four-wheel base, articulated boom and hinge discs, connected cable/hoist/hook and posed slung crate. |
| Tender | Smooth low shell, four-wheel chassis, folded cream arms and mittens, fitted top cover/handle, rear service panel and coupling. Moss remains rear-right: Blender -X,+Y. |
| Tally | Rounded till body, teal cap, drawer, held tray with rimmed coins, short curved receipt and rear service cover. |

`textures/` contains four 256-square **Blender-native baked colour surfaces**: red and cream enamel, teal paint and canvas. They are packed into the .blend/GLB handoff; the removed bag’s original canvas bake remains source history. No new AI-generated painting or external runtime tool is required.

## Export and animation contract

- Drive tyre/hub objects preserve their axle origins, names beginning `wheel`, and X-axis rotation. `wheel_radius` in Blender extras gives the presenter the correct distance per rotation; older models fall back to the previous radius.
- Eye-only meshes carry `blink_eyes: true` in extras. `WorldAssetMeta` reads glTF extras and `RobotBlink` gently closes/reopens the eyes over 160 ms, with independent 4.8–7.2-second intervals. Glass, face light, carried lanterns and geometry stay steady.
- Finished model selection lives in `pipeline/world-catalog.json`; `spark_blink` enables the cosmetic controller. The existing human/robot sprite sheets and approved player remain unchanged.
- Placements, collision, inspections and routes still belong to the square document. This pass adds no new commands, jobs or tool-use animations.

## Records and review

`pip_wick_initial_edit.py` preserves the original first-edit record. `refine_sources.py` is its guarded source-edit helper, used by `refine_other_sources.py`. `pip_parcels_edit.py` records the completed Pip revision; `finish_pip_wick.py` includes Wick’s final light/eye setup. `finish_work_tools.py` fits Tender’s cap and refines Heron/Tally’s tools; `final_heron_pose.py` keeps the payload below its readable face. Per-model JSON records preserve source, backup and edit hashes.

Native review: [gallery](../../../../../docs/concept/v0.72/robot-model-refinement.md). [Review record](../../../../../pipeline/reviews/2026-10-29-robot-models-and-request-markers.md). Further edits use the saved sources.
