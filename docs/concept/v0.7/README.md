# v0.7 — Sparks & Machines

**Main-route decision, 2026-10-29:** Sparks & Machines is now the selected main game. New game opens Sparks directly; Kindle Hollow and Village Morning are archived for later rework, retaining their content, code and saves. The separate-journey wording below records the original additive implementation boundary. The title also exposes a development-only empty asset showcase; [current review](../../../pipeline/reviews/2026-10-29-main-route-and-asset-showcase.md).

**Status: connected loft, workshop, Spindle Lane and downhill Rootward Square, greeting and first workshop jobs implemented, 2026-10-29; the wider concept remains proposed.** The player wakes by the bed, finds Nell’s note and uses the screen terminal for a guided Blocks/Python greeting. Actual output ghost-types during Test and the committed greeting wakes Hotaru. The waking exchange sends the traveller to Nell’s field tablet on the bed; carried, it jacks into the workshop’s wall screen, the first area node. Code reaches only what the traveller stands beside: the stair lantern’s page beside the lantern, a whole zone at the wall screen, and plain open code everywhere else. Story scenes use paired portraits and a saved log, while ordinary inspections use world bubbles. The reached jobs book and a worked loop example support the existing downstairs chapter. Through the street doors, Spindle Lane (art `T7c`, `P1`) is the first outdoor scene: a cobbled terrace above the town with a painted harbour behind it, a tram halt, street life and Hotaru's arrival scene ([review](../../../pipeline/reviews/2026-10-28-spindle-lane.md)). Its gate lamp has no job yet. The gate now leads down to the square: a low Rootwell, clock hall, three shopfronts, markets and a service pedestal, with saved exploration and no new ticket yet ([review](../../../pipeline/reviews/2026-10-29-stairs-and-square.md)). Nell’s return, square quests, shop/hall interiors and tram travel remain proposed. See [the first morning review](../../../pipeline/reviews/2026-10-27-first-morning-tutorial.md) and [project handoff](../../PROJECT_HANDOFF.md).

The user asked to move the setting away from fairies and mysticism toward machines, with a little everyday magic to keep the world lively. The inspiration is the warmth of a mid-century harbour town and the real history of programmable automata. The goal is a world where programming has an obvious place, so new lessons and machines are easy to invent.

> **Magic gives a machine life. Code gives it a job.**

## Start here (next agents)

1. **Art direction.** The [38-image concept pack](art/INDEX.md) is complete. The user delegated selections and superseded phase approval stops. Ground-going automatons use rolling bases; Hotaru keeps her floating silhouette and tucked wheels.
2. **Meanwhile, the words.** [The dialogue guide](07-dialogue.md) and [the quest design](08-quests.md) set the voice and the first quests. Anyone writing lines reads the voice rules first.
3. **Continue the first slice.** The furnished loft, first greeting, connected workshop and its first jobs are implemented. Continue the [scenario](05-scenario.md) through deliberate next steps; The square is built for exploration; Nell’s arrival and outdoor jobs are not built. Preserve the other journeys’ content and sources.

Preserve the archived journeys’ authored content, art, text and saves. Regression tests and development tools use explicit legacy journey IDs now that the public default is Sparks ([the original boundary and current decision](05-scenario.md#the-rule-a-separate-journey)).

## Documents

1. [**World concept**](01-world-concept.md): premise, the rule of the world, the roots and the mystery, setting and era, the player's year, story spine, core loop, residents, the automaton roster, tone, an ideas backlog, and the guardrails against imitating films.
2. [**Art direction brief**](02-art-direction.md): pillars, references, era and technology, places and architecture, the Rootwell, palette ([swatches](palette.svg)), light and time of day, materials, characters, automaton design language, magic visuals, liveliness, interface, readability rules and an asset audit.
3. [**The robot companion**](03-robot-companion.md): Hotaru's cuter design, personality, following and working modes, the parts she gains as capabilities, the rules she follows, and how she sits beside the Village Morning fairy.
4. [**Art prompt pack**](04-art-prompts.md): every main asset in order: shared style blocks, references, and prompts for the town, Hotaru, the cast, places, props, automatons, interface and future places.
5. [**The scenario**](05-scenario.md): the new journey, how it starts, slice 1, later slices, and an implementation outline for the coding agent.
6. [**Characters and character style**](06-characters.md): sprite and portrait rules, the wardrobe era, the cast (the apprentice, Hotaru, Nell, Mira, Rowan, Bram, Tessa), the automatons and future characters.
7. [**Dialogue**](07-dialogue.md): an honest critique of the current dialogue with before-and-after rewrites, the rules for writing a line, a banned-phrase list, each character's voice, and the full opening script.
8. [**Quests**](08-quests.md): the main line (Jobs 0–8, from "Hello, Hotaru" to the founders' card), ten side jobs that each teach a different idea, and the API each one needs.
9. [**Concept art folder**](art/README.md): where the generated images go, how they're named and recorded.

## Decisions

The user settled these on 2026-10-26.

| # | Decision | Choice |
|---|---|---|
| 1 | The spark | **One gentle magical energy**, not plain electricity and not magical trades. |
| 2 | The companion | **A robot named Hotaru**, chosen as more fun and more programmable, **made a little cuter** than the first study ([design](03-robot-companion.md)). |
| 3 | The apprentice | **Mid-century work clothes**: same face, hair and proportions; tucked teal work shirt, belt on the trousers, neckerchief and boots kept. A new skin for the new journey only. |
| 4 | Roofs | **Terracotta and copper**, with violet kept as a rare accent. |
| 5 | The Rootward oak | **Removed** in the new journey. The spark comes from **ancient living roots** under the hills, tapped long ago by the founders' **buried machine network** (the Rootworks). **The Rootwell**, a low stone-and-brass wellhead, takes the oak's place; its dropping dial is the first clue ([the roots](01-world-concept.md#the-roots), [the Rootwell](02-art-direction.md#the-rootwell)). |
| 6 | Nell | **Retired automaton-maker** and the apprentice's landlady; she built Hotaru. |
| 7 | Interface | **Paper and enamel**, for the new journey. A replacement for the Cinzel display face is chosen in a UI review. |
| 8 | Town name | **Haverlund.** |
| 9 | Where it lives | **A separate journey.** The existing game does not change ([scenario](05-scenario.md)). |
| 10 | Who makes the art | **A separate image-generation agent**, working from [the prompt pack](04-art-prompts.md). |

Still open, and not blocking the first slice: the [story questions](01-world-concept.md#story-spine-sketch) (what is wrong at the roots, Hotaru's origin, Nell's part, who R.W. was), the other residents' suggested roles, and the automatons' names.

## What the new journey reuses and what it adds

| Reused unchanged | New for this journey only |
|---|---|
| Godot project, `core/` rules, the WASI Python sandbox, Preview/Apply, quests, build mode, terrain, saves | Its own areas: workshop loft, workshop floor, the lane, then the square, the outskirts and the town |
| Fixed orthographic camera and voxel-inspired 3D world | Palette: terracotta and copper roofs, a sky backdrop by day |
| The painted sprite template and portrait style | Mid-century skins and portraits for the apprentice and residents |
| The lesson rules for /00 Saying Hello and /01 First Steps | Robot Hotaru: body, portrait and dialogue under new ids |
| Field Notes and code legibility | A paper-and-enamel interface theme |

## Earlier work in this folder's history

A first robot study exists as reference only: a Blender model and render script (`art/source/world/hotaru-robot/v1/`, unregistered) and a painted portrait with expressions (`art/source/companions/hotaru/v3/`, unselected). The prompt pack uses them as inputs for the cuter design. Village Morning still selects the fairy; Sparks & Machines uses its approved robot and portrait.

## When implementation starts

As slices of the new journey land, these need updating so they keep describing what really works: `AGENTS.md` (project purpose mentions the third journey), `docs/PROJECT_HANDOFF.md`, `README.md`, `content/levels/catalog.json` (a new entry only), and the pipeline catalogs for any adopted art. These now record the implemented slices; keep proposed later work distinct.

9. [Zone terminals](09-zone-terminals.md): the shared screen computer, portable console, first two saved connections and the rule behind `world.zone(...)`.
10. [Quest line, tablet screen and lamplit rooms](10-quest-line-and-tablet-plan.md): a proposed plan (2026-10-30) for the next lessons, the tablet/VS Code code surface, blue ghost previews, the staged waking scene and lamplit rooms. Nothing in it is built.
