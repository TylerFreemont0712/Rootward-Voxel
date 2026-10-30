# The scenario: Sparks & Machines — 2026-10-26

**Status: loft, greeting, connected workshop and first workshop jobs implemented, 2026-10-27; remaining outdoor scenario proposed.** The opening note, furnished loft and /00 journal are playable. Real Python Test ghost-types output; Speak wakes Hotaru. Her reply exchange leads to the downstairs workshop, where a work ticket, stair-light routine and three-light opening round form the next chapter. Four original scenes connect discoveries and committed results; separate drafts, read scenes and both floors save. Normal walking stays available. Spindle Lane, the street outside (the scenario's `haverlund-lane`), is built and open whenever the workshop is: a 24×28 outdoor scene with Nell's house beside the workshop, the tram halt, street life, a painted harbour and Hotaru's first-visit scene ([review](../../../pipeline/reviews/2026-10-28-spindle-lane.md)). Free following, Nell's return, the gate-lamp job and the hook remain proposals. See [the current first-jobs review](../../../pipeline/reviews/2026-10-27-workshop-first-jobs.md).

## The rule: a separate journey

**Superseded route decision, 2026-10-29:** the user selected Sparks & Machines as the main game and paused Kindle Hollow/Village Morning for rework. The public journey selector has been retired; New game and Continue use Sparks. Legacy definitions, content and save filenames remain intact, and explicit development/test calls still work. The following is the original 2026-10-26 implementation boundary; its content/source preservation continues to apply.

The user's instruction, 2026-10-26: *don't change the game; if anything changes, make it a different scenario.*

- **Kindle Hollow and Village Morning stay exactly as they are**: their areas, art, text, fairy Hotaru, saves and tests.
- The concept lives in a **third journey** that the player chooses from **New journey**, beside the other two.
- New content gets **new ids and new files**. It never edits an existing area document, companion file, portrait or skin.
- Shared code may only be extended **additively**. Every new option defaults to today's behaviour, so the existing journeys play identically and their test suites pass unchanged.
- The fairy Hotaru belongs to Village Morning. The robot Hotaru belongs only to this journey.

## Identity

| Field | Value |
|---|---|
| Journey id | `sparks-and-machines` |
| Title | Sparks & Machines |
| Subtitle | An apprentice's year |
| Level-select description | Move into the old workshop above Haverlund, wake Hotaru, and give the town's quiet machines their jobs back. |
| Save | Its own save, through the existing per-journey save mechanism |
| Setting | [World concept](01-world-concept.md) and [art direction](02-art-direction.md) |
| Cast | [Characters](06-characters.md) and [Hotaru](03-robot-companion.md) |

## How it starts (what the player sees)

The full dialogue for these beats is in [the opening script](07-dialogue.md#5-the-opening-script-slice-1); the quests that follow are in [the quest design](08-quests.md).

The opening follows Village Morning's proven shape (wake, first voice, first steps), told in the new world.

1. **The journey card.** The old workshop on the hill at golden hour, with the town and harbour below (art `U2`).
2. **The first morning.** A short prose page, then a fade into the loft bedroom: a bell somewhere below, a smell of dust and machine oil. On the shelf by the desk sits a little lantern-shaped robot, dark and dusty (art `T7a`, `H1`, `H2` Off). Nell’s note says she has been out on calls this week and Hotaru has mostly been asleep. The loft terminal rings Hotaru’s message bell when an addressed greeting is sent. The player is a new lodger with no special ability or established origin.
3. **Waking Hotaru: Field Notes /00, Saying Hello.** The player uses the small screen terminal on the desk and writes `print("Hello, Hotaru!")`, as a message block or Python. **Test** previews the actual words on the glass and ghost-types them in the room; **Send message** delivers the greeting. Hotaru’s light and rotor wake at her addressed-message bell. Her first lines: *"Oh. Morning."* · *"You’re the one in the loft, then? I’m Hotaru."* Hotaru then mentions something Nell left on the quilt and tells the traveller to pick it up: **Nell’s field tablet**, a slate with a cord and a brass plug. Carried, it is what the workshop’s wall screen, the first area node, accepts ([zone terminals](09-zone-terminals.md)).
4. **Current continuation: the workshop tickets.** The traveller already walks normally. Read Nell's ticket, restore the stair lantern, then finish the three-light opening round. The movement-key exercise below is an earlier proposal, not a gate on this chapter.
5. **Downstairs.** The workshop floor (art `T7b`): dusty benches, half-built automaton parts, and the job board with one ticket pinned to it. Nell arrives (portrait conversation): she is the landlady and the retired automaton-maker who built Hotaru. She is glad Hotaru is awake and doesn't say how long it has been.
6. **The first job (method call).** Outside on the lane (art `T7c`), the gate lamp is dark. A wire runs to it, but nobody wrote the switch-on routine. The player lights it with one call, the same goal as today's *A spark at the landing*, in new words.
7. **The hook.** With the lamp lit, the view opens down the lane to Rootward Square, where the Rootwell's glass dome glows faintly. Hotaru: *"The needle on its dial is low, though. Lower than I remember."* End of the first slice.

## Slice 1: "The workshop morning"

The smallest playable start of the journey. One slice at a time, each reviewed in Godot at gameplay scale before the next.

| Part | Content |
|---|---|
| Areas | `workshop-loft`: interior bedroom with desk, screen terminal, shelf (about 12×10 cells, like the morning bedroom). `workshop-floor`: interior ground floor with benches and job board. `haverlund-lane`: small exterior (about 40×28) with the workshop, two cottages, poles and wires, the gate lamp, a tram halt at the edge, and a view toward the square. |
| Lessons | /00 Saying Hello (wakes Hotaru), /01 First Steps, Job 1: the gate lamp. These reuse today's lesson rules and goal types (the greeting flag, movement bindings, a lit lamp) with new text and art. |
| People | The apprentice (mid-century skin), Hotaru (robot, following mode only), Nell. |
| Art needed | `H1`–`H4`, `C1`, `C2`, `T7a`, `T7b`, `T7c`, `P1`, `P3` and optionally `U1`. See [the prompt pack](04-art-prompts.md). |
| Not in slice 1 | Rootward Square and the Rootwell, other residents, the outskirts quests, Hotaru's working mode, the harbour, the Rootworks. |

## Later slices

1. **Rootward Square.** The Rootwell (replacing the oak), the town hall, Mira and Rowan, a job board that grows. Art: `T3`, `T4`, `T5`, `C3`, `C4`.
2. **The outskirts arc.** The five "Light the hollow" lessons (loops, variables, conditions, functions) on a new outskirts map, with the lamplighter, the yard crane and the gate. This is a new area document, not an edit of `kindle-hollow.json`. Art: `T2`, `A1`, `A2`.
3. **Hotaru stage 1.** Walking legs and working mode ([design](03-robot-companion.md#suggested-stages)).
4. **Act 2, the town of Haverlund**, and **Act 3, the Rootworks** ([story spine](01-world-concept.md#story-spine-sketch)).

## Implementation outline (for the coding agent, later)

This is an outline, not a plan of record. Confirm it with the user before building, and read `AGENTS.md` first.

- **Journey entry.** Add a new object to `content/levels/catalog.json` and leave the existing two entries untouched.
- **Areas.** New documents `content/areas/workshop-loft.json` (with its `.quests.json`), `workshop-floor.json` and `haverlund-lane.json`. Reuse the interior and house-instance flow that Village Morning's `morning-home` uses.
- **Per-journey companion.** Village Morning is special-cased today: `app/game.gd` checks `level=="village-morning"` and `_root_area_id=="village-morning"`, and `HotaruDialogue` reads a fixed `content/companions/hotaru.json`. Generalise these into optional level-entry fields (for example `"companion": "hotaru-robot"` and an opening flag) whose defaults reproduce Village Morning exactly. Robot Hotaru gets `content/companions/hotaru-robot.json`, an `art-catalog` `companions.hotaru-robot` entry with its own runtime files, and a `HotaruRobot` body. A first study exists under `art/source/world/hotaru-robot/v1/` (unregistered); the cuter `H1` design supersedes it.
- **Apprentice skin.** Register the mid-century wardrobe as a new skin in `pipeline/character-catalog.json` through `pipeline/CHARACTERS.md`, selected only in this journey. Shared frame skins already preserve playback on swap.
- **Interface theme.** If paper and enamel (`U1`) is adopted, make it a theme variant applied only in this journey.
- **World assets.** New models go through `pipeline/WORLD_ASSETS.md` and get registered in `pipeline/world-catalog.json` only when an area uses them.
- **Tests.** Add a test for the journey. Every existing suite in `scripts/test.sh` must pass unchanged.

## Slice 1 is done when

- The new journey can be chosen, started, saved and resumed. The other two journeys are byte-for-byte unaffected (same saves, same tests).
- The opening runs from the loft through the lit gate lamp and the hook, with no dead ends.
- Hotaru, the apprentice and Nell read clearly at the real camera scale, and the user has reviewed them in Godot.
- `scripts/test.sh` passes, including the new journey's test.


## Implemented place: downhill Rootward Square — 2026-10-29

After the lane, the traveller can use the iron town gate to descend into a separate saved square. The visible arrival is two short flights with a landing, representing the foot of the longer route. Shops, a clock hall, market tables and the low glass Rootwell establish the civic centre in the lane’s style. An arrival scene and short object observations are available; no new work tickets are assigned. The square service pedestal accepts Nell’s slate using the existing physical connection rules. Later quests will make use of this place after its art review. Tram boarding and its separate destination, shop/hall interiors, residents and Nell’s return remain unimplemented. See the [review](../../../pipeline/reviews/2026-10-29-stairs-and-square.md).
