# Reach, arm's length and route marks — 2026-10-27

Playing the tablet revision showed three things that did not fit the idea of a short-range link: the first workshop job could be written from anywhere in the room, F offered things from several cells away, and the click-to-walk marks were small tiles that were easy to lose.

## Code reaches only what you stand beside

`core/field_access.gd` holds the rule, so a later "remote access" skill changes one place.

* A **zone** (`world.zone("workshop")`, its lamps, gates, bridges and objects) is in reach only while the traveller stands at its terminal, having jacked into it with the tablet. Leaving the screen takes the zone away from a program; Apply checks position again.
* A **lamp** that names a `stand` cell is in reach while the traveller carries its required item (the tablet) and is within a cell of that spot. The stair lantern is written at the stair lantern, not from across the room, and from there nothing else answers: `world.zone` is absent and another lamp is refused with where to stand.
* Areas without terminals keep their older discovery rules.

In play: **F at a fitting** opens that fitting's job page (`WorkshopJobsJournal` now takes a place and lists only the pages written there; at a zone's screen its lamps' pages stay open too). **F at the screen** opens the zone's pages. **E, anywhere else,** is the plain open page (the original greeting editor), so Field Notes never reaches the world from a distance. Nell's ticket and the lit lantern each end by offering to walk to the next place (`ZoneConnectionPanel`, now also for fittings); the job book gives every unfinished job a "Go to the stair lantern" or "Go to the workshop screen" button; the pinned ticket adds "Stand beside the stair lantern and press F."

The quest data says where each job lives (`access` on a quest, `stand`, `title` and `requires` on a lamp, all validated by `AreaDef`), and the job mark now sits on the cell to stand on. The ticket scene, the stair-lantern scene and the lesson text were reworded to match; Hotaru's lines are in [the dialogue document](../../docs/concept/v0.7/07-dialogue.md).

## Arm's length

F was offered up to 1.6 cells from an authored approach point, and from up to 2 cells beyond that to the object. In these rooms it is now about one cell (`FieldAccess.RANGE`), for terminals, pickups, inspections, stairs and Hotaru (who sits on furniture and is reached from the nearest standing place within 1.6). `RoomLinks.nearest` takes the radius as an optional argument, and only the workshop journal asks for the shorter one, so the other journeys keep theirs. A test checks that every authored thing in both rooms has a walkable, reachable cell inside its reach.

## Route and destination marks (paper journey only)

* Route steps are round dots with a solid dark-teal outline and a cream fill, drawn from a distance field so they stay crisp at every zoom; the last cell is a larger breathing ring.
* The object being walked to (note, screen, tablet, lantern) takes a soft teal pulse, and the same pulse stays on whatever F is about to use.
* The old "look here" tile ring and beam is a brass dial with a ring of ticks and a warm glow on the floor, with a few sparks rising from it, since sparks are this world's one gentle magic.

Kindle Hollow and Village Morning keep the square gold tiles and the tiled ring; a test pins both.

## Reviewed

Native captures in `evidence/sparks-workshop/reach-and-markers/`: [route to a cell](../../evidence/sparks-workshop/reach-and-markers/1600/l-route-cell.png), [route to the lantern](../../evidence/sparks-workshop/reach-and-markers/1600/l-route-lamp.png), [route to the screen](../../evidence/sparks-workshop/reach-and-markers/1600/l-route-screen.png), [arrived at the lantern](../../evidence/sparks-workshop/reach-and-markers/1600/l-at-lamp.png), [the job book](../../evidence/sparks-workshop/reach-and-markers/1600/l-job-book.png), [the lantern's page](../../evidence/sparks-workshop/reach-and-markers/1600/l-lamp-code.png) and [the screen's page](../../evidence/sparks-workshop/reach-and-markers/1600/l-screen-code.png), with 1280×720 equivalents beside them in `1280/`.

Checks: the complete `scripts/test.sh` passed. Focused suites against the start of the day: Sparks journey 103 → 137 (wheel, tablet, route and job marks, the old style kept elsewhere, Hotaru within reach), zone terminals 25 → 78 (the reach rule, one lamp against a whole zone, every authored thing reachable at arm's length), workshop quests 74 → 82 (walking to the lantern, then to the screen, the open page elsewhere), area documents 151 → 152, world art 673 → 681 and handoff links 1130 → 1143.

