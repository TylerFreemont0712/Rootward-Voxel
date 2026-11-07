# Flat upper square and saved layout tools

The user asked to set up the upper paths, park and barriers personally. They confirmed a completely flat upper landing, park, frontage plots and rear ground, retaining the stairs down to the square, and moving loading four cells back along the incoming lane.

## Delivered behavior

Sparks & Machines now offers **Layout · B** in Rootward Square. The existing builder paints half-cell appearance tiles; places fourteen park/barrier pieces; moves, rotates and removes 74 existing park/railing props; and retains undo/redo and normal campaign saves. Terrain shaping is hidden on this authored shelf. Real footprints, authored scenery collision and required-route checks protect the stairs, loading entrances and service access. Other campaign rooms keep their existing behavior; interior furnishing and original shop models remain future work.

Closing the builder saves the campaign and additionally exports `content/development/layouts/haverlund-square.json` in a writable source checkout. The file contains both edits and the effective area document. It is a review artifact and never automatically overwrites the base map. Test/native runs use isolated saves and scratch exports.

The continuous ground paintings remain UV-mapped in the adopted Blender model. A sparse masked paint layer reveals the unchanged native surface where no explicit paint exists. Only painted 3-cell chunks allocate a mesh. Undo, cancellation and Eraser remove paint correctly, and asynchronous Continue restores it.

## Layout and source

Area v7 expands to 88×64 by rebasing all prior square positions 16 cells east, bringing the western park/plots into logical bounds. The loading boundary is `(12,12)`, four cells west of its rebased former `(16,12)`. Wide arrival targets are `(13,11)` / `(13,13)`, with the existing two-cell walk-in. Spindle Lane's own gate stays in place. The generic interior exit matches the real uphill link; an obsolete exit across the park no longer interrupts walking. Other rooms' destination coordinates are updated while their own layouts stay intact.

`map_offset` migrates saved player coordinates once. Object IDs, programs, accounts, inventory, lamp routines and room memory survive. The preserved v6 document is used to verify migration.

Ground v4 copies the adopted v3 source before a deliberate upper-shelf edit. Lower square, power pillars, stair treads and retained material paintings remain. The normal world-art build audits **1,191 mesh sections / 135,559 triangles**, down from v3's 1,246 / 165,971. This is a geometry reduction, not a claimed whole-game frame-rate measurement. No overlay geometry is drawn before painting. All 68 logical lights (including the new clockmaker) remain bound, and the whole-square lighting test finds zero meshes above eight affecting point lights.

[Source/edit record](../../art/source/world/spindle-strip/v2/README.md) · [User guide](../../docs/concept/v0.8/square-layout.md).

## Validation

- Flat layout, migration, collision, editable placements, save reconstruction and schema: **25 checks passed**.
- Square graph and real lane travel: **234 checks passed**.
- Cleared shops, barriers and legacy room exits: **40 checks passed**.
- Native Godot 4.7.2 / Compatibility, 1600×1000: **28 checks passed**, covering westward loading both ways, real mouse placement, selection/rotation, path painting, cancellation, undo/redo, scratch export, asynchronous Continue with campaign memory and both retained stair flights. Original approved camera and player art preserved.
- Full `scripts/test.sh`: **passed**, including all gameplay/UI/sandbox checks, 969 world-view checks, source/workflow guards, 1,592 handoff checks and 121 ground-art checks. Final model, light and legacy-save checks also passed after the clockmaker refinement.

[Flat arrival](../../evidence/layout-studio/01-flat-arrival.png) · [Flat rear plots](../../evidence/layout-studio/02-flat-plots.png) · [Builder tray](../../evidence/layout-studio/03-layout-builder.png) · [Painted path](../../evidence/layout-studio/05-painted-path.png) · [Continued layout](../../evidence/layout-studio/06-layout-continued.png) · [Stairs](../../evidence/layout-studio/07-stairs-preserved.png).

An initial native review exposed the stale generic exit; it was corrected and the full native review rerun. A transient builder plaque triangulation error was fixed by clamping inset chamfers and rejecting degenerate bodies. The first full-suite run found a test still standing at the bank's former coordinate; it now reads the bank approach from the area document, and the final complete suite passed. Acceptance of the revised ground remains with the user in the Finished queue.
