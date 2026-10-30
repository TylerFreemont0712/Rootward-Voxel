# Guildhall Square source pack

The rebuilt square below Spindle Lane, after the selected [Guildhall Square concept](../../../../../docs/concept/v0.72/art/guildhall-square.png) and the [v0.72 robot sheets](../../../../../docs/concept/v0.72/art/robots/lineup.png). It uses the lane pack's palette, painted surfaces and primitives (`../../sparks-lane/v1/lane_kit.py`), so the street above and the square below read as one town.

Sixteen new editable Blender masters:

| Master | What it is |
|---|---|
| `guildhall-square-set` | The square in area coordinates, and the town round it. The square has cobbles, flagged pavements, an octagon of pale setts with a brass band round the beacon, brass power channels with studs and grates, grass between the setts on the open side, and pigeons. The stepped street (levels 2, 1 and 0 at x 0–1, 3–5 and 7–9 on rows y 21–25) carries on uphill out of view, with an iron railing over the shops' walled back garden (fruit tree, beds, shed, water butt, washing). North of it is the garden terrace: a retaining wall with ivy, a balustrade, a lawn, trees, steps up to a chained gate, and four houses. Round the square are a balustrade with flower boxes, a railing on a low wall, retaining walls down to the lower town and its two rows of houses and lamps, the houses rising uphill to the west, and the town behind the hall. |
| `square-beacon` | The root-power beacon: octagonal steps, a dressed drum with the dial facing the camera, a notice board, a maintenance door, valve wheels, an amber glass bell over a glowing root, a ribbed copper dome, a lantern and a finial. |
| `square-guildhall` | The guild hall: a clock tower with a pediment, a copper mansard with dormers and pinnacles, an arched entrance and public counter, banners, lanterns, ivy and doorstep treads. |
| `square-post-office` | The post office: a tiled canopy, the envelope sign, a parcel counter, a balcony and a hipped roof. |
| `square-west-terrace` | Morning Loaf, the greengrocer and Finch & Sons as one attached terrace facing +x. |
| `square-banner-lamp` | An iron lamppost with a lantern (`lamp_glass`) and a banner hung from its top edge (`cloth_banner`, with `banner_emblem` as its child). |
| `square-flower-stall`, `square-fruit-stall` | Market stalls under canvas roofs. |
| `square-tree-planter`, `square-timber-store` | A shade tree in a stone planter with seats; building stock on the open side. |
| `robot-pip`, `robot-trowel`, `robot-wick`, `robot-heron`, `robot-tender`, `robot-tally` | The six rolling robots. Each wheel is its own objects (`wheel_*`, `wheel_*_hub`) with its origin on the axle, so the street presenter can roll it. |

## Records

- `square_kit.py`: the shared helpers. Includes roof slopes of any shape (hips, mansards, slopes cut square at one end), octagons, a half-disc fanlight, domes, the town's sprout mark, ivy, clipped evergreens, robot wheels and the amber spark face.
- `author_landmarks.py`, `author_props.py`, `author_set.py`: guarded one-time authoring. Each refuses an existing master. Pass asset ids after `--` to author only some.

While the layout was being settled on 2026-10-29, before adoption, these unadopted masters were regenerated from their records several times. Each regeneration was a layout or detail fix: the guild hall's tower, the post office's sign, the robots' tyres and faces, the street moved north, and the paving under the café corner. From adoption onward, each `model.blend` is the editable authority: open it, edit it, and export with `scripts/world-art.sh build <id>`. Never regenerate an adopted master.

`content/areas/haverlund-square.json` (version 2) owns every placement, blocking footprint, level, stair, link, inspection, lamp, the screen, and `interior.life`: chimney smoke, swaying banners, gulls and the robots' rounds. Static meshes never decide traversal. The [Guildhall Square review](../../../../../pipeline/reviews/2026-10-29-guildhall-square.md) links the gameplay captures.
