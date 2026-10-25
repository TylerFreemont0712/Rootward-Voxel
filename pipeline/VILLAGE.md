# Village, homes and water

Kindle Hollow version 2 is 96×80 cells (2.5 times the original area), with 23 buildings, 224 playable trees, fourteen zones and five residents. The lesson lamps, gate and bridge retain their coordinates. The quest mill wheel now sits in the river with a solid axle/bearing connection; the five-quest arc is preserved. Connecting roads change thirty existing walkable cells at the north/east edges; the original river, gate and bridge locks remain intact. North Common and Cedar Rise extend past the old gate; the Eastbank and Brookside districts extend beyond the mill crossing. Version 1 is preserved under `content/areas/archive/`.

## Sources and rules

| Source | Owns |
| --- | --- |
| `content/areas/kindle-hollow.json` | Terrain, house ids, resident starts/routes/homes and scenic boundary settings. |
| `content/interiors/catalog.json` | Building asset → room template → area id. |
| `content/areas/village-{cottage,workshop,loft,mill}.json` | Room dimensions, arrival, exit, furniture footprints, host positions/routes, zone and programmable sconce. |
| `content/villagers.json` | Resident names, professions, skin ids and dialogue. |
| `core/house_instances.gd` | Directed door crossings, safe doorstep, instance address and saved-room filtering. |
| `core/village_life.gd` | Deterministic resident route steps using ordinary `LabWorld` passages. |
| `art/interior_builder.gd` | Procedural cutaway walls and furniture from each room document. |
| `scenes/villager_view.gd` | Shared-frame actors and visual interpolation of resident state. |
| `app/game.gd` | F interaction, dialogue, fades, travel and saves. |

Walk from the doorstep toward a building to enter: its leaf swings inward, the boy walks through the opening, and the screen fades to that home’s saved room. Clicking a visible door or the building routes to its entrance first. Inside, walk south from the exit mat through the open timber frame to return outdoors. Only that directed crossing triggers travel; walking past a house, arriving inside, loading a save or standing on the returned doorstep does not. The outdoor approach must be walkable. Pure rules own the crossing and furniture collision; the short walk through the opening is presentation between areas. See [the doorway review](reviews/2026-10-25-steps-doors-and-cottage.md).

Residents stroll between their document's route points, wait between trips and never step into the player's cells or each other's: they walk round, or wait when there is no way round. They are solid to the player too: walking into one stops and faces them, click-to-walk routes round them, and clicking one walks up beside them. They still lock no quests: lesson rules, Python and the builder ignore them. Marks over their heads say who has something to say ([marks and the speech bubble](DIALOGUE.md#marks-and-the-speech-bubble)). Dialogue pauses resident motion and uses the [single-speaker visual novel scene](DIALOGUE.md), including the resident’s high-definition portrait, response topics and optional code examples. Read flags follow the resident across outdoor and indoor conversations. Each resident's home presents that resident indoors too; this is a local scene presentation, not a persistent daily schedule. Outdoor build placements protect their route stops and access. Movement and facing use the same shared character template as the boy.

The outdoor builder includes Hearth House, Lantern Loft, Brook Mill, Hearth Oak, Ridge Cedar and River Willow. All registered house assets have room mappings, including player-built homes. Moving a house preserves its room address; removing it makes its cache inactive. Fresh building ids prevent a replacement house from inheriting that room. Undo/redo retain the same house identity. Indoor furniture editing is not implemented.

The [building pass](BUILDINGS.md) adds Hearth Bakery and Riverside Smithy with short street approaches, builder entries and saved rooms, and polishes all existing shells and lamps. The quest wheel now reaches the river through its document placement and an explicit solid axle connection.

## Save behavior

Rooms now have authored `interior.materials` palettes: cottage parquet/limewash, workshop limestone/brick, loft teal tile/wallpaper and mill terracotta/limewash. **B** offers six saved material controls, with Original and undo/redo. A room's save contains `edits` alongside state; `_activate_room` replays them over its template and `_cache_room` stores them. Finishes belong to the stable house instance, so visiting another house or Continue indoors preserves isolation. Furniture layout is unchanged. See [Materials](MATERIALS.md).

The existing version-1 save envelope keeps Kindle Hollow's state, completed quests, build/paint edits and return position at the top level. An optional block adds rooms:

```json
"travel": {
  "version": 1,
  "active": "kindle-hollow/home",
  "rooms": {
    "kindle-hollow/home": {
      "house": "home",
      "template": "village-cottage",
      "save": {"state": {}, "completed": [], "source": "...", "stats": {}, "edits": []}
    }
  }
}
```

`save` above represents the ordinary full session save, abbreviated here. Each house stores its own lamp state, visited zones and Python memory. Notebook source, name and run/apply counts follow the player; outdoor quest progress stays outdoors. Reset indoors affects only the current room, and Character still shows the overall journey. Continue restores an active room only when its house and template still match. Orphaned caches are ignored, and saves without `travel` continue outdoors. Entering or leaving cancels walking and invalidates pending previews before replacing the session. The runtime keeps only one area view active; old geometry and its light pool are replaced together.

## Boundaries and water

The optional `boundary` block specifies an apron of 16–64 world units and forest/mist toggles. `art/village_boundary.gd` draws four land strips outside the logical map, scenic tree rows and faint animated mist planes. The ordinary in-bounds rules stop travel. The scenery never adds walkable cells or hides water inside the map.

`art/water_surface.gd` draws continuous subdivided tops in chunks, using the selected water and foam textures plus procedural detail noise. `art/water.gdshader` adds two moving texture scales, depth colour, shoreline foam, small vertex waves, highlights and expanding rings. The original wheel has CPU particle spray. These effects are visual and require no service. The adopted Rune Mill land GLB remains unchanged; its declared water rectangles receive the new surface. Brook Mill's decorative static wheel has no mechanism or spray.

## Verification

Run `scripts/art.sh` after changing character sources and `scripts/test.sh` for all checks. `test/test_places.gd` covers room rules/data, routes, saved identities and boundaries; `test/test_house_flow.gd` drives actual transitions and Continue. Existing area tests solve all five quests through Python/WASI. `tools/village_tour.gd` captures the real game, all residents, four room types and both builder categories in a window with scratch saves. See the [review](reviews/2026-10-23-village-expansion.md) for actual results and captures.

General travel between outdoor regions, stacked floors, daily schedules, furniture editing, resident quests and procedural room generation remain future features.
