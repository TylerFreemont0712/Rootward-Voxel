# Townspeople and service rounds

## Sparks ambient inhabitants

The active cast uses the Sparks & Machines paintings. Nell is absent for quest reasons. Spindle Lane has no named characters; the square has one Mira and one Rowan. Original character sources and the archived village's identities remain intact.

| Area | Named sprites | Anonymous painted crowd | Robot work rounds |
| --- | --- | --- | --- |
| Loft | Player and existing Hotaru scene | None | Existing companion only |
| Workshop floor | None | None | One small Tender, checking the work area |
| Spindle Lane | None | Two children; two or three arriving adults per tram | Pip visits house frontages, Wick checks gate lights, Trowel tends the green |
| Rootward Square | Mira and Rowan | Eighteen mixed adults and children | Postal deliveries from the post office, a café porter, east-garden Trowel, lamplighter Wick, Rootwell Tender, a Heron by the harbour stores and market Tally |

### Appearance

Thirteen anonymous profiles derive from eleven existing complete paintings: both original and Sparks villager wardrobes plus the approved boy. Three reduced profiles form the child pool. Every alpha byte, frame region, anchor and animation duration is preserved; only RGB is flattened. The presenter uses charcoal (0.20) at 98% opacity with no glow.

`art/source/characters/phantoms/v3/appearances.json` owns source selection and compatible pools. `pipeline/phantom_builder.gd` runs within **`scripts/art.sh`**, producing masks, inherited SpriteFrames and hashes in `assets/characters/phantoms/`. `VillagerView` shuffles cosmetic appearance bags per visit and refreshes returning tram passengers. Appearance choice never affects deterministic motion. Previous source selections remain preserved and unselected.

### Movement, collision and tram passengers

Area `villagers` entries choose one appearance: `skin` (painted named sprite), `object` (a placed robot) or `phantom` (`man`, `woman`, `child`). Explicit appearances are ambient, without archived dialogue or quest marks. Robots have one movement owner and cannot also appear in `interior.life.robots`.

`VillageLife` advances at 60 Hz. All active inhabitants reserve both cells of a step against each other. **Phantoms do not reserve cells against the player and ignore the player's cells when routing**. Robots and named villagers keep their existing player collision. Paths use the same world, furniture, stair and support rules as player movement. Cached paths are checked before each step and replanned when obstructed. Doorways, ordinary walk-through arrivals and code-access approaches remain clear.

The outdoor maps now author **ordered errands**, rather than random small circuits. A resident's `route` gives legal standing cells; the parallel `errands` list gives a real placed `target`, an `activity` and `seconds` (1–15). The parser validates the list lengths, activity, target and a six-cell maximum distance to its centre (allowing large buildings). A round cannot combine errands with random wandering or tram arrivals. On reaching a stop, pure state records the activity/target, faces the object, waits its authored duration and continues. Presentation turns sprites/robots toward their work; the task never changes collision or inventory.

Pip collects from post boxes and delivers to smaller boxes by house fronts/the shops and the post office. Wick visits the gate, pavement and platform lamps on the lane and six lamp posts round the square. Trowel visits water and planting; Tender checks the Rootwell and planters; Heron moves between supply stacks; Tally visits market stalls. Residents read notices, shop, rest and visit fountains; the two lane children have longer purposeful outings. Outdoor robots move at 1.5–1.9 cells/second (previously 0.55–0.9), anonymous residents about 1.7–2.5, with actual work/rest pauses. Named sprites keep the shared template's step duration. The original `wander` option remains supported for archived/local authored routes.

These are deterministic local rounds with visible destinations and facing, not persistent daily schedules, parcel inventories, physical tool-use animations or changes to quest lamp state.

An adult phantom's `arrival` declares a delay, a service interval/offset and a real exit link. `TramSchedule` is the common pure timetable for the visible tram and spawning. Two adults arrive on every trip; the third arrives on alternate trips. Their disembark delays are 0.9, 4.8 and 8.5 seconds after docking. They use different platform starts, stairs, pauses, speeds and street stops before reaching either side of the square gate. Departure passengers alone may use that link's normally reserved corridor. They fade in over 0.45 seconds and out over 0.7 seconds, releasing occupancy after departure; the three-person pool is reused without population growth. The existing 90-second service and initial offset are retained.

Notebook, modal, title and builder pause crowd and tram clocks together. Each area visit restarts local rounds. Continue keeps player progress and position; a solid resident at a saved arrival moves aside, while a phantom may share the player's cell. No daily schedules, cross-area crowd persistence, dialogue or new quests are added.

`test/test_town_life.gd` verifies source-alpha identity, shared frames, cast uniqueness, crowd coverage, all route stops, deterministic separation, player pass-through and four services of arrivals/departures. `tools/phantom_crowd_review.gd` checks actual input, tram groups and the square at gameplay size with isolated progress. See the [current review](reviews/2026-10-31-painted-crowd-and-tram.md).

## Programmable service rounds — 2026-11-02

`RobotPrograms` defines the visited-place/service-screen access rule and validates `set_robot` commands. The only writable fields are `running` (Boolean), `speed` (0.5–3 cells/s) and `route` (1–12 existing service-stop names). Commands commit atomically with other validated commands. The persisted room layer restores settings through that same validator. No engine object or renderer position is exposed to Python.

`VillageLife.advance` consumes committed settings while retaining ordinary legal paths, occupancy and current-step interpolation. A route edit clears the previous plan at the next ordinary work update; Undo back to the authored round also clears it. Pausing holds the round and resuming continues it. Story actors, phantoms and the tram are not worker targets. These controls do not implement autonomous repairs or new mechanical work actions yet.
