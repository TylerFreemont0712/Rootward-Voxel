# Village, homes and water

## Sparks ambient inhabitants

The active cast uses the Sparks & Machines paintings. Nell is absent for quest reasons. Spindle Lane has no named characters; the square has one Mira and one Rowan. Original character sources and the archived village's identities remain intact.

| Area | Named sprites | Anonymous painted crowd | Robot work rounds |
| --- | --- | --- | --- |
| Loft | Player and existing Hotaru scene | None | Existing companion only |
| Workshop floor | None | None | One small Tender, checking the work area |
| Spindle Lane | None | Two children; two or three arriving adults per tram | Pip visits house frontages, Wick checks gate lights, Trowel tends the green |
| Rootward Square | Mira and Rowan | Eighteen mixed adults and children | Postal deliveries from the post office, a café porter, east-garden Trowel, lamplighter Wick, Rootwell Tender, a Heron by the harbour stores and market Tally |

### Appearance

The three anonymous profiles are made from the **existing complete paintings**: `sparks_bram` for the man, `sparks_mira` for the woman and the approved `adventurer` for the child. The build preserves every source alpha pixel, frame region, anchor and animation duration, flattening only RGB to a mask. Rendering applies a neutral charcoal gray at 96% opacity. The child keeps the boy's poses with a modest width/height adjustment (96%/88%); the source paintings and player are unchanged. The crowd has no glowing material or ghost motion.

`art/source/characters/phantoms/v2/appearances.json` selects the sources and presentation. `pipeline/art-catalog.json` registers it; `pipeline/phantom_builder.gd` runs inside **`scripts/art.sh`** and writes the selected masks, inherited SpriteFrames and hash manifest under `assets/characters/phantoms/`. `PhantomActor` uses the existing sprite actor's facing, phase preservation, anchoring, breathing and idle. The rejected geometric silhouette study remains unselected under `art/source/characters/phantoms/v1/`.

### Movement, collision and tram passengers

Area `villagers` entries choose one appearance: `skin` (painted named sprite), `object` (a placed robot) or `phantom` (`man`, `woman`, `child`). Explicit appearances are ambient, without archived dialogue or quest marks. Robots have one movement owner and cannot also appear in `interior.life.robots`.

`VillageLife` advances at 60 Hz. All active inhabitants reserve both cells of a step against each other. **Phantoms do not reserve cells against the player and ignore the player's cells when routing**. Robots and named villagers keep their existing player collision. Paths use the same world, furniture, stair and support rules as player movement. Cached paths are checked before each step and replanned when obstructed. Doorways, ordinary walk-through arrivals and code-access approaches remain clear.

Crowd `wander: true` chooses varied nonrepeating stops from small, authored local routes, with deterministic changes of pause. Different walking speeds and initial waits break up the crowd's timing. Starts and stops remain area data; no renderer coordinates enter the simulation.

An adult phantom's `arrival` declares a delay, a service interval/offset and a real exit link. `TramSchedule` is the common pure timetable for the visible tram and spawning. Two adults arrive on every trip; the third arrives on alternate trips. Their disembark delays are 0.9, 4.8 and 8.5 seconds after docking. They use different platform starts, stairs, pauses, speeds and street stops before reaching either side of the square gate. Departure passengers alone may use that link's normally reserved corridor. They fade in over 0.45 seconds and out over 0.7 seconds, releasing occupancy after departure; the three-person pool is reused without population growth. The existing 90-second service and initial offset are retained.

Notebook, modal, title and builder pause crowd and tram clocks together. Each area visit restarts local rounds. Continue keeps player progress and position; a solid resident at a saved arrival moves aside, while a phantom may share the player's cell. No daily schedules, cross-area crowd persistence, dialogue or new quests are added.

`test/test_town_life.gd` verifies source-alpha identity, shared frames, cast uniqueness, crowd coverage, all route stops, deterministic separation, player pass-through and four services of arrivals/departures. `tools/phantom_crowd_review.gd` checks actual input, tram groups and the square at gameplay size with isolated progress. See the [current review](reviews/2026-10-31-painted-crowd-and-tram.md).

## Archived village foundation

The separately selectable [Village Morning](MORNING.md) concept reuses saved house travel but starts in a bespoke bedroom, before entering a minimal exterior. `content/interiors/catalog.json` can override a template for an exact `area-id/house-id`; its existing asset defaults still choose the ordinary rooms everywhere else. The following describes Kindle Hollow's established village.

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

Doors use a safe exterior landing shared by travel, routing and builder access rules. The Concept Cottage reserves one extra cell beyond its former threshold. Walking onto the landing is ordinary movement. The next inward attempt toward the door frame opens the leaf and fades from that safe current space to the saved room. Click routes reach the landing, then request that inward frame step. Inside, walk south from the exit sill to return outdoors. The closed leaf remains solid, and the character never walks into it during travel. Exiting and older threshold saves use the safe landing. [Current doorway review](reviews/2026-10-26-compact-desktop-and-room.md).

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

Village Morning now includes the [Rootward Square landmarks](reviews/2026-10-26-rootward-square.md). The town hall uses the same saved-instance travel path, with its own council-room template and oppositely opening double leaves.
