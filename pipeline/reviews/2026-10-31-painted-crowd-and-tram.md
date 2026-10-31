# Painted anonymous crowd and tram passengers — 2026-10-31

The anonymous townspeople now use gray versions of the existing painted character sheets and their exact animations. The child is slightly smaller. Nell is absent; there are no named villagers outside her shop. The square retains one Mira and one Rowan.

## Current population

| Area | People | Robot routine |
| --- | --- | --- |
| Workshop floor | None; Nell has not arrived | One small Tender checks the work area |
| Spindle Lane | Two resident children; each tram brings two or three adults | Pip visits house frontages, Wick checks gate lights, Trowel tends the green |
| Rootward Square | Eighteen anonymous adults/children; Mira and Rowan | Postal round, café porter, garden care, lighting, Rootwell maintenance, harbour lifting and market round |

The eleven robots include repeated postal, maintenance and gardening models in appropriate districts. No new robot models, conversations or quests were added. The loft's opening and the existing companion are retained.

## Appearance and ownership

The man uses `sparks_bram`, the woman `sparks_mira`, and the child the approved boy. Every source alpha byte is preserved; only RGB is flattened. Frame regions, anchors, frame durations, gait timing, projected facing and idle behavior come from the approved shared template. The child is rendered at 96% width and 88% height; adults retain their approved size. Rendering uses neutral gray 0.46 at 96% opacity. This gives solid anonymous figures with the established painted silhouettes.

- Editable selection: `art/source/characters/phantoms/v2/appearances.json`.
- Catalog/build: `pipeline/art-catalog.json`, `pipeline/phantom_builder.gd`, **`scripts/art.sh`**.
- Derived output: `assets/characters/phantoms/` (three masks, inherited SpriteFrames and source/build hashes).
- Presenter: `art/phantom_actor.gd`, using the existing `SpriteAdventurer` playback and anchors.

Original character paintings and the player are unchanged. The earlier geometric silhouette study is rejected and unselected, with its source and previews retained in `art/source/characters/phantoms/v1/`. The runtime build stages metadata in `.cache/phantom-art/` and publishes only a complete manifest, so preparation cannot expose missing playback metadata to a running view.

## Timetable and movement

The visible tram and its passengers share `core/tram_schedule.gd`. The existing 90-second service and initial offset remain. Two adults disembark every trip; a third joins alternate trips. They have different starts, delays (0.9/4.8/8.5 seconds after docking), speeds, intermediate stops and pauses. They climb the real platform stairs and use either side of the town gate, fading away at the end. Their three-person pool is reused without population growth.

The eighteen square residents choose varied local stops, with deterministic variation of pauses and walking speed. Cached routes are rechecked before each step. Terrain, stair and furniture legality remain pure world rules. All inhabitants reserve both cells of a step against other residents and robots. Anonymous people do **not** collide with the player, and ignore the player's occupied cells; robots and named villagers retain player collision. An outgoing passenger may use their departure link's ordinary reserved corridor. Other doors, arrivals and code approaches stay clear.

Notebook, modal, title and build mode freeze passenger and tram clocks together. Each area visit restarts local ambient routes. Continue keeps the player's position and progress; only a solid resident overlapping a saved arrival moves aside. No save format or area-version change is needed.

## Native review

`tools/phantom_crowd_review.gd` runs the real game with isolated progress and travels through the existing stairs, shop doors and town steps. It observes the first three-adult service, passengers leaving at the gate, the gap between trams and the following two-adult service. It then checks actual movement input through a gray person and against a robot, plus modal pause.

The painted version was reviewed at **1600×1000** and **1280×720** using the existing camera heading, elevation and gameplay zoom. The final neutral-gray palette was reviewed at both sizes; selected captures are linked below. Renderer: Godot 4.7.2 Compatibility/OpenGL on AMD Radeon 680M. Full frame sequences and logs are in `.cache/phantom-crowd/`.

- [Workshop without Nell](../../evidence/painted-crowd/2026-10-31/workshop-1280.png)
- [Tram arrival](../../evidence/painted-crowd/2026-10-31/tram-arrival-1280.png) · [following service](../../evidence/painted-crowd/2026-10-31/second-tram-1280.png)
- [Lane with children and passengers](../../evidence/painted-crowd/2026-10-31/lane-1280.png) · [1600×1000 view](../../evidence/painted-crowd/2026-10-31/lane-1600.png) · [passengers approaching the gate](../../evidence/painted-crowd/2026-10-31/gate-1280.png)
- [Square shops](../../evidence/painted-crowd/2026-10-31/square-shops-1280.png) · [market](../../evidence/painted-crowd/2026-10-31/square-market-1280.png) · [garden](../../evidence/painted-crowd/2026-10-31/square-garden-1280.png) · [Rootwell](../../evidence/painted-crowd/2026-10-31/square-rootwell-1280.png)

## Verification

- `scripts/art.sh`: passed; 100 painted-art and 111 shared-frame checks, plus the three crowd appearance builds.
- Focused `test/test_town_life.gd`: 1,061 checks passed, including every source alpha byte, exact inherited frame metadata, cast uniqueness, population counts, valid routes, deterministic separation and four successive passenger services.
- Native painted-crowd review at both resolutions: passed, including real player pass-through and robot collision.
- Full `scripts/test.sh`: **passed with no script/runtime errors** on the final build. This includes 1,061 crowd checks, workshop/quests (73/91), lane (156), square (169), dialogue (144), house travel/saves (38), movement, UI and sandbox checks, 933 world-art checks and 1,469 handoff checks. An earlier run overlapped an art rebuild and was discarded; the clean run followed the completed build and review record.
- `git diff --check`: passed.

This is local ambient movement, without daily schedules, persistent resident clocks, robot work animations, new dialogue or quest logic. Named cast sources remain available for later story placement; Nell's return is not implemented. The user retains visual acceptance. No commit, push, publishing or external message was made.
