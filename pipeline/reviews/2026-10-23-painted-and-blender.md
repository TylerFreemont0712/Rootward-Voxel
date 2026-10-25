# Painted character and editable world handoff — 2026-10-23

The character selection below is historical. The [approved directional walk/idle review](2026-10-23-approved-directional-walk.md) now selects v9. The Blender handoff recorded here remains current.

This supersedes the 2026-10-22 foundation review for current asset selection. It records a working prototype improvement, not production approval of character animation.

## Decisions

The user rejected the assembled cutout appearance and asked to preserve the original character. The selected player therefore uses the approved painted whole-body art, with four authored diagonal views and offline in-betweens. The cutout sources/study remain inactive. Clothing customization and held-item layering are deferred. No 3D Blender character is selected.

World art has a separate, working Blender handoff. Cottage/workshop, mill shell and static clearing land load selected GLBs built from saved `.blend` sources. Tree reference source is supplied but existing varied procedural crowns remain selected. Water, wheel, lamps, gate and bridge remain engine-controlled.

## Character evidence and limits

- The original v2 PNG is unchanged: SHA-256 `d947716e3bbb55683455f47c61057265c437107164b8748636fb90c426ca6918`.
- All four painted keys in each of the four views are preserved byte-for-byte after integer translation/padding. Twelve generated in-betweens per direction provide sixteen samples at 32 FPS, retaining the half-second cycle. Provenance pins source/output/script/backend/model hashes.
- Actual held-key camera projection was reviewed for SE/NE/NW/SW; each key follows its intended logical axis. Starts/turns preserve the intended phase, and stopping settles to an existing passing drawing rather than snapping to a different pose.
- [Selected painted views](../../evidence/painted-directions.png), [painted motion recording](../../evidence/painted-walk.gif), [gameplay](../../evidence/voxel-clearing.png), [live movement](../../evidence/sprite-movement.png).

The source keys repeat the same leading foot in several directions. Interpolation cannot repair this. Some generated transitions can soften painted edges. Idle is a fixed held drawing; there is no new breathing/blinking cycle. Correct alternating contact/passing keys and a deliberate idle remain required before calling this a complete production animation pipeline. The next art pass must preserve this exact design while correcting those poses.

The rejected experiment's capture is archived at `art/source/archive/rejected-cutout/evidence/cutout-rig.png`. It is not evidence of the selected character or an accepted alternative.

## Blender evidence and limits

Four unedited Godot → Blender → Godot assets passed triangle-corner position/UV comparison at 0.0001 precision, normal comparison within 0.001 vector distance, and material/decoded texture checks: cottage 3420 triangles, mill-house 3468, clearing-ground 7224, tree 1284. The first three are selected; the tree remains a reference. This verifies the supplied round trips, not every Blender shader or a universal pixel-identical render.

The saved `.blend` is protected after adoption. Normal builds export to a candidate, audit in Godot, verify the source hash is unchanged and promote only the checked GLB/manifest. One prior export is retained in `.cache/`. Seed/init refuse existing sources. [The Blender guide](../BLENDER.md) gives human editing instructions and limits of the grouped block geometry.

## Validation

`scripts/test.sh` covers pure world/WASI/app behavior, held movement and routing, painted source identity/phase/settling, selected world sources/exports and runtime instantiation, camera-facing mapping, and protected source initialization. **Final run passed: 175 checks** — 53 world/WASI, 24 app, 25 grid/routing, 43 painted-art, 26 world-art/projected-facing and 4 source-protection checks. No failing or skipped checks in this suite.

Live Godot checks passed: clicking across a bridge built by real Python, reaching the clicked destination, held-key repeat, release settling to a cell, and editor-focus input safety. The four-direction review passed all four projected views and logical-axis checks. These are focused input checks; no hardware gamepad or family play session was conducted.

## Remaining gates

1. Correct original-style walk keys and a deliberate idle; visual acceptance takes priority over rig/customization convenience.
2. A second faithful character through a deliberately extended registry/adapter; multiple character identities are not implemented.
3. A human visual edit/export review of an adopted Blender source. The supplied unedited handoff is proven; the source must never be regenerated over that edit.
4. Extract one shared area document, then load a second small area before building a custom editor.
5. World persistence, larger content/performance measurements and family play feedback remain separate gates. The project stays standalone.
