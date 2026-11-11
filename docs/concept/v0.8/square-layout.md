# Arrange Spindle Walk

In **Sparks & Machines**, enter Rootward Square and press **B**, or click **Layout · B** at the bottom. This opens the existing builder for the restored upper landing, small garden and shop promenade. Other campaign rooms retain their current behavior; this is an area layout tool, not an interior furnishing editor.

| Control | Action |
| --- | --- |
| **4 / Land** | Choose grass, dirt, cobble or a floor material and drag to paint. Choose **Floors → Limestone Flags** for paving. |
| **[ / ]** | Change brush size: half a cell, one cell or two cells. |
| **Alt-click / I** | Pick the effective paint under the pointer. |
| **Eraser** | Remove added paint and reveal the original Blender surface. Paint grass to replace existing paving visually. |
| **3 / Objects** | Place one of fourteen garden pieces: trees, bench, planter, fountain, railings, posts, garden walls, balustrades or retaining-wall pieces. |
| **1 / Move** | Click a placed piece to select; click again or drag to lift it and set it down. Existing park doodads and upper railings use the same tool. |
| **R / Shift+R** | Rotate the selected or carried piece. |
| **2 / Delete** | Remove a piece. |
| **Ctrl+Z / Ctrl+Y** | Undo / redo. One drag is one paint edit. |
| **WASD / middle-drag, wheel** | Pan the builder camera and zoom. |
| **Done / B** | Return to walking and save. |

The source ground uses continuous painted images mapped with UVs onto the Blender mesh. A cell is one world unit; appearance painting divides each into four half-cell squares. Paint changes appearance only. Placed barriers and park objects have collision, and placement rules keep entrances, stairs and required routes open. Placement stays on level parts of the authored terraces; terrain raising, digging water and rebuilding stairs are hidden here.

Continue restores your layout with the campaign. After **Done**, the source checkout also gets a readable snapshot at **`content/development/layouts/haverlund-square.json`**, including edits and the resulting area document. Tell the coding assistant that your layout is ready; it can read that file directly. The snapshot does not automatically overwrite the authored map. No file upload or screenshot is required. Exported standalone games still keep normal saved edits; writing back to a project checkout requires that writable checkout.

The loading boundary remains four cells west along the incoming lane. The logical square stays 88×64 so the saved coordinate offset remains stable, but the large flat shelf has been removed. The smaller garden, older terrain and both stair flights are restored. The clockmaker's central door between the clock displays enters its newly furnished room. Thyme & Tonic now stands beside the clockmaker and the rear shelf is a walkable physic garden ([2026-11-05 review](../../../pipeline/reviews/2026-11-05-spindle-terrace-and-apothecary.md)); furnishing the cleared shops remains future work.

The restoration preserves your previous v7 layout sketch at `content/areas/archive/haverlund-square-v7-layout-sketch.json`, and leaves `content/development/layouts/haverlund-square.json` intact until you explicitly finish a new layout. On Continue, edits from the retired flat layout are retained in save metadata rather than applied across different terrain. Memory, inventory, programs and other campaign progress stay with their rooms. Feet on removed ground or new furniture recover to safe ground.

[Restored terraces](../../../evidence/square-restoration/06-restored-terraces.png) · [Current review](../../../pipeline/reviews/2026-11-04-square-restoration-and-clockshop.md).
