# Buildings, doors, mill and lamps — 2026-10-24

Reviewed the eight existing building assets and lamppost, deliberately edited their saved Blender masters, and added two authored shop buildings. The [building guide](../BUILDINGS.md) lists the changes and controls. Existing source backups and before/after hashes remain beside every modified master.

## Visible changes

- Common painted violet/teal roof family and 1.2-unit picture scale across the old cottages/cabins, porch/dormer roofs, loft/turret and Brook Mill/hoist/monitor. Existing silhouettes and building footprints are preserved.
- [Older cottage](../../evidence/building-polish/cottage.png), [small cabin](../../evidence/building-polish/log-cabin.png) and [larger cabin](../../evidence/building-polish/log-cabin-large.png): taller legible oak planks, limestone arches, iron hinge straps/studs, brass knockers and pale low steps. Original gable windows and wall identities remain.
- [Hearth House](../../evidence/building-polish/hearth-house.png) retains its porch/dormer. The [loft](../../evidence/building-polish/lantern-loft.png) and [Brook Mill](../../evidence/building-polish/brook-mill.png) ground entrances/thresholds align with the center-front logical approach; the upper mill cargo entry stays distinct.
- The quest mill's [before](../../evidence/building-polish/mill-before.png) and [after](../../evidence/building-polish/mill-after.png) show its larger wheel in river water, with paired spokes, rims, iron bands, a hub and paddles. The fixed axle/stone bearing connects to the shell and blocks walking through the machinery. Rune Mill's original test-area wheel receives the same treatment at its own scale. Spray follows the wheel document.
- [Lit lamp close-up](../../evidence/building-polish/lamp-lit.png): metal rain cap/base, brass cage/rivets, suspension ring, diagonal bracket, post collars and pedestal cap. Separate `lamp_glass` still receives the game's state material, halo and pooled light.
- New [Hearth Bakery](../../evidence/building-polish/hollow-bakery.png): cream/oak, violet roof, brick oven/flue, bread display/sign and side windows. New [Riverside Smithy](../../evidence/building-polish/hollow-smithy.png): stone, teal roof, open forge/anvil/tools and tall chimney. They are placed at `[23,63]` / `[73,16]`, with short path approaches, builder cards, saved finishes and separate rooms using the existing templates.

The first Godot review caught reversed roof slopes and a covered forge mouth on the two new models. These were corrected in their saved masters, then side windows/timber bands were added and both models re-exported. Final front/rear views were inspected for all eleven assets at zoom 13. The real builder/room flow was reviewed at 1600×1000 and 1280×720; [bakery builder](../../evidence/building-polish/hollow-bakery-builder-1280.png), [smithy builder](../../evidence/building-polish/hollow-smithy-builder-1280.png).

## Verification

- All eleven source exports passed `scripts/world-art.sh build <id>` candidate audits. The original nine masters were backed up before deliberate editing; normal export left their edited sources untouched.
- `test/test_building_refresh.gd`: **48 checks passed**, including bounded/malformed/legacy wheel data, axle collision, preserved source backups, rotated new shop placement, finish JSON/undo, real builder selectors, actual door/exit, saved interior state/materials, working lamp glass and a rotating rotor beside a fixed bearing. The same 48 checks passed in both windowed sizes.
- `tools/playthrough.gd` completed **all six quests**, including the optional building chapter, with **19 lamps lit** and `failed=false`, through real walking and notebook preview/Apply.
- Approved character pictures and the shared texture-library PNGs were preserved. Changes to pre-existing binary art are limited to the nine intended `.blend` masters, their nine GLBs and six derived extracted model roof pictures. Original masters are retained beside the edited files.
- The complete suite reported **24 suites / 4,757 checks passed**. Concurrent terrain/water authoring was preserved; intermediate runs encountered partially written methods. The last full run also caught a duplicate variable in the concurrently edited ground shader, which was corrected in that work. The affected code/app tests and real windowed building flow were rechecked afterward. Details are in the [final verification manifest](../../evidence/building-polish/verification.json).

## Limits

This adds building presentation and existing builder/travel integration. Shop ovens/forges/signs are decorative, with no trading/crafting behavior or new quests. Brook Mill's built-in wheel remains static scenery; the quest mill rotor is the separate animated mechanism. Roof materials add detail without new texture generation, normal maps or displacement. No sibling project, release or commit was created.
