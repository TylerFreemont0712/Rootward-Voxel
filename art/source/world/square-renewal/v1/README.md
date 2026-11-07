# Rootward Square lighting and shop revision — 2026-11-03

The user's annotated square screenshot requested real street illumination, removal of the small path lights, reusable colliding barriers, bakery/food/clothing interiors, a shopping strip and a quieter upper park. Their final shop choice was **clockmaker + apothecary**, to support a later programming challenge.

The approved boy, camera and current materials remain the presentation baseline. The current area documents are the placement/collision authorities. Existing authored masters were copied into a new source version before deliberate mesh edits; prior versions remain intact.

- `clean_frontage.py` removes the retained original fascia faces behind the new joinery; the coplanar regression verifies the result.
- `revise_shops.py` edits only the adopted ground-floor frontage/dressing of the copied bakery, food shop and clothier. The clockmaker/apothecary derive from the preserved food-shop master. Distinct recessed wares replace flat shop pictures; separate glazed hinged leaves carry common `DoorSwing` metadata. Their saved `.blend` files now own the artwork.
- `chunk_ground.py` cuts existing ground faces into spatial sections while retaining UVs/materials. Near sections span 4 m, distant sections 16 m. This keeps local lights from competing across a whole-town mesh and permits local culling.
- `chunk_landmarks.py` sections large static buckets in preserved copies of the Rootwell/plaza masters at 3 m, preserving UVs and corner normals. Civic moving parts stay whole.
- `replace_wall.py` replaces one straight 3 m retaining-wall bay beside the upper terrace with `town-retaining-wall`. Special stair cheeks and other terrain retaining surfaces remain in the ground master.
- `author_modules.py` originally created the reusable shop shell and retaining-wall module. `author_clock_stock.py` created the clockmaker's display cabinet. Both refuse existing sources.
- `revise_area.py` records the deliberate layout revision. It is a historical one-time edit, **not** a command to regenerate the current area. Current `content/areas/*.json` files remain authoritative; do not rerun it over later authored changes.

Normal future edits: open the selected master, save it, run `scripts/world-art.sh build <id>`. No authoring service is needed at runtime. All eleven changed/new assets went through that build and its GLB audit. Shop room state uses the existing journey saves. Shop trading and clock/apothecary programming quests remain future work.
