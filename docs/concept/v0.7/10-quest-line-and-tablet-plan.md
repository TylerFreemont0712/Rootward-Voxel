# Quest line, tablet screen and lamplit rooms: plan — 2026-10-30

**Status: proposed. Nothing in this document is built.** It answers the user's review of the four scenes (loft, workshop, Spindle Lane, Rootward Square). Facts about today's code were checked on 2026-10-30; items marked *to verify* were not. Read [the quest design](08-quests.md), [the dialogue rules](07-dialogue.md) and [zone terminals](09-zone-terminals.md) first.

## 1. What the review asked for, and where each ask lands

| The user's ask | What is true today | Slice |
|---|---|---|
| A tablet-like code screen that matches the concept | Field Notes is a paper page. The code sits in a cream inset (`WorkshopJournal._paper_code`) | 1 |
| Code that looks like VS Code, not cream paper | Same. `CodeEditor` already has a dark palette, but the paper pages override it | 1 |
| The "go through the code" replay looks like code too | `ProgramPlayback` reuses the paper inset and a teal line highlight | 1 |
| Ghost text outlined in blue, obviously a ghost | A paper bubble at 80% opacity with the caption "GHOST PRINT · TEST" (`WorkshopSpeech`) | 1 |
| Apply should show a real bubble and a small waking scene before the chat | `WorkshopJournal.speak()` emits `waking_requested`, `Game._workshop_waking()` closes the notebook and opens the `loft-waking` portrait scene in the same frame. Hotaru's waking is a material swap with no staging | 2 |
| The workshop should not feel like the sun is in the room; shadows make no sense; lamps should make it easier to see | One shadow-casting `DirectionalLight3D` ("LateAfternoonSun") lights every room. Rooms get warmth 0.75 whether or not a lamp is lit. Lamp lights are unshadowed omnis | 3 |
| Lamp positions look random | `repair-light` hangs at (2.0, 5.3) but the repair bench's centre line is x 0.55, so it floats about 1.4 cells off the bench. Pendants hang from nothing (the cutaway has no ceiling). Nothing connects the lamps to the screen that controls them | 3 |
| Progression, not abrupt scene changes | Apply flips every lamp in one frame. Quest completion is a card and a scene | 2, 4 |
| A visible sign that the code worked | Lamps switch on instantly. The room does not change otherwise | 3, 4 |
| The next quest after "turn all the shop lights on" | The last scene finds Nell's "Again?" complaint from the north gate behind the workshop card. Lane and Square have no tickets | 5 |

## 2. The teaching progression

### 2.1 What the three built quests teach

| # | Quest | Named idea | Used but never named |
|---|---|---|---|
| 00 | Hello, Hotaru | `print`, strings | `def program(world):`, indentation |
| 01 | The landing light | An object found by name, a method call, `True`/`False` | Assignment (`lamp = world.lamp(...)`), dot notation |
| 02 | The morning round | A list and a `for` loop | Indexing (`lamps[0]`), the loop variable |

The honest gap: **no numbers, no comparisons and no `if` yet.** Village Morning taught arithmetic through its key-mapping lesson, and that journey is archived, so Sparks has no numbers at all. The loop arrived early, which is fine because three lamps justify it. The next lessons must slow down, reuse the loop, and add the missing ideas one at a time.

### 2.2 Rules for every quest from here

These extend [How a quest is built](08-quests.md#how-a-quest-is-built).

1. **One new idea, named once.** Anything used but not yet named gets named in the quest that first needs it.
2. **Spiral.** Each quest reuses the previous idea in a new setting. A short optional practice job follows each main job: same idea, new place, one twist.
3. **Fading scaffolds.** Change one word (00, 01) → replace one line using a shown pattern (02) → fix a nearly-right program (03) → fill a skeleton (04) → write from a comment (later). Hints come in three steps: a nudge, a pointer, then "show me", which types the answer as ghost text.
4. **The starter fails visibly.** The Test ghost shows the wrong result before Apply.
5. **The goal checks the world, never the code text.** Any program that makes the world right counts.
6. **Every concept has a visible proof**, listed in 2.4.
7. **Each quest ends on a reaction, not a moral.** Dialogue follows 07's rules; the notebook carries syntax.

### 2.3 The ladder

| # | Quest | New idea | Where | Visible proof | Needs |
|---|---|---|---|---|---|
| 00 | Hello, Hotaru ✔ | `print`, strings | Loft | Hotaru wakes | built; staging in slice 2 |
| 01 | The landing light ✔ | Object, method, `True`/`False` | Workshop | Stair lantern warms, its corner of the room brightens | built; staging in slices 3–4 |
| 02 | The morning round ✔ | List, `for` | Workshop | Three lamps come on one after another, in list order | built; staging in slice 4 |
| 03 | **"Again?"** (next) | Reading state: `lamp.lit`, `not`, `if` | Lane gate lamp | The lamp goes dark in the ghost, then stays lit | quest start state ("setup"); lane quest file |
| 04 | "Both posts" | `and`, `else` | Lane town gate | The iron gate swings open only when both post lamps are lit | second lamp, a real swinging gate, journey-level gating |
| 05 | "Legs!" | Sequence: order matters | Lane | A blue ghost Hotaru walks the route first | **new** `world.hotaru.step` and working mode (design: [03](03-robot-companion.md#suggested-stages)) |
| 06 | "The long way round" | Numbers, `range`, a variable you change | Lane to square | Hotaru walks N steps; change N and she stops short or overshoots | builds on 05 |
| 07 | "Light the Hollow" | Functions with a parameter, zones | Square and Lantern Row | A wave of lamps up the hill, then the Rootwell needle drops | zones exist; the Old Watch lamp |
| 08 | The founders' card | Reading code, indexes, off-by-one | Hill branch | The stair lamp that never lit | [08](08-quests.md#job-7--the-founders-card) |

Practice jobs, with no new idea, give the spiral room: after 02, **same loop, longer street** at the square pedestal (three lamps today, more later); after 04, [S8 Face the lane](08-quests.md#s8--face-the-lane), which uses today's `house.face`; after 06, [S6 Settle it](08-quests.md#s6--settle-it) for comparisons with numbers.

Why this order: conditions follow loops in most beginner paths, and 03 continues the story thread already in the game ("Again?"). Numbers wait until Hotaru can walk, because a number you can see her walk is a better lesson than one you print. The original ladder in 08 puts sequences before loops; the built game swapped them, so 05 now teaches sequence *after* loops and 06 uses `range` as the natural relief from repeated steps.

### 2.4 Visible proof, one language

A proposal and a fact must never look alike.

| Stage | Look |
|---|---|
| **Test (ghost)** | Blue outline, translucent, gently bobbing. Applies to speech, lamps, gates, Hotaru's route, anything proposed. |
| **Apply (commit)** | The notebook slides away, the camera moves to what changed, and the effect plays **in program order**, so a loop shows itself: one lamp per iteration. |
| **Settled (real)** | Solid, warm, and the room's real light changes. |

Per concept: `print` gives words in a bubble and on the glass; a method call gives one fitting changing; a loop gives the lamps in sequence with a spark running along the wire to each; `if` shows the branch not taken as a small ghost label ("skipped: already lit"); `and` gives a gate that stays shut until both lamps are on; a sequence gives Hotaru walking in the order written.

**Stretch (slice 6): code line to world.** When Replay steps a line, the thing that line changed glows blue in the room. This is the strongest "my code is doing that" link. The replay trace already records every executed line (`_on_line` in `sandbox/world_harness.py`), but a command does not appear to carry the line that made it, so the harness would stamp each command with the current line (*to verify* that nothing downstream rejects the extra field; `core/` validation refuses unknown command fields).

## 3. Slices

Each slice is small and reviewable, runs in Godot at gameplay camera scale, and stops for the user's review before the next ([AGENTS.md](../../../AGENTS.md)). Recommended order: 1, 2, 3, 4, 5.

### Slice 1 — Tablet screen, VS Code editor, ghost style

**Status: built 2026-10-30, awaiting the user's review** ([review](../../../pipeline/reviews/2026-10-30-tablet-screen-and-ghost-text.md)). One difference from the text below: a previewed lamp still lights its fixture at reduced strength; "does not light the room" lands with slice 3. The user also asked, mid-slice, for the lower-right controls hint to go and for the portrait chat window to run to the right edge; both are done.

**What the user sees.** The code surface becomes a device. Instructions stay on paper, because paper is Nell's voice. Code is on glass, because glass is the machine.

- **Two skins of one component** (`ui/tablet_screen.gd`, new). *Desk terminal* for /00: cream-and-teal casing with a recessed screen, matching the loft computer. *Field slate* for job pages: dark enamel bezel, brass cord and plug at the top edge, a link lamp reading `CONNECTED · workshop`. Before the slate is picked up, /00 uses the desk terminal; after, jobs use the slate.
- **Screen:** a file tab (`landing_light.py`), editor with line numbers, an OUTPUT strip below it in the same dark, and a thin status row (line and column, `Python`, link state). Test code and Apply sit on the lower bezel as keys, keeping their current styles.
- **Colours** in one new file, `ui/code_palette.gd`, so nothing is inline (the UI rule in [UI.md](../../../pipeline/UI.md)). VS Code Dark+ values: background `#1e1e1e`, text `#d4d4d4`, line numbers `#858585`, current line `#2a2d2e`, selection `#264f78`, keywords `#569cd6`, control flow (`for`, `if`, `in`, `not`) `#c586c0`, functions and builtins `#dcdcaa`, strings `#ce9178`, numbers `#b5cea8`, comments `#6a9955`, `.attributes` `#9cdcfe`. IBM Plex Mono stays; the existing font-size setting still applies.
- **Replay looks like a debugger.** The current line gets the yellow execution highlight with a gutter arrow, and variable values appear dim at the end of the line, as in VS Code's inline values. `ProgramPlayback` already carries the values.
- **Ghost text:** translucent blue-white fill, a 2 px blue outline with a soft pulsing glow, a **dashed** outline so it still reads without colour, a slow 2–3 px bob, letters fading in as they are typed, and a dotted tail. Real speech stays a solid paper bubble with dark ink. The caption becomes a small `TEST · GHOST` chip.
- **Ghost in the world:** the same blue outline and pulse for every Test proposal. A previewed lamp gets a blue outline and a blue halo that does not light the room; Apply is what makes the room really brighten.

**Where.** New `ui/tablet_screen.gd`, `ui/code_palette.gd`. Edit `ui/workshop_journal.gd`, `ui/workshop_jobs_journal.gd`, `ui/program_playback.gd`, `ui/workshop_speech.gd`, `scenes/clearing_view.gd` (`_ghost_material`, `_set_fixture_preview`, `_ghost_box`), `ui/paper_pal.gd` (ghost-blue tokens; exact blue picked from two or three on-screen swatches at review). `CodeEditor`'s default palette stays, so the archived journeys keep their look; the new palette is applied as an override, as `_paper_code` does now.

**Checks.** `test_sparks.gd` and `test_ui.gd` expectations updated. Screenshots at actual size of /00 (terminal skin), a job page (slate skin), a Test ghost bubble and a ghost lamp.

### Slice 2 — The waking scene

Today Send message closes the notebook and opens the portrait chat at once. Staged version, about eight seconds, skippable with a click:

1. The drawer slides away. The camera eases to hold the boy at the desk and the shelf.
2. The boy's committed words appear as a **solid** bubble: "Hello, Hotaru!" The terminal glass shows the sent line.
3. The message bell rings: visible chime arcs and a blinking terminal lamp (the project has no audio today; leave a hook).
4. A beat of stillness. Then dust lifts off the shelf, a shiver, the rotor ticks twice and spins up, the lantern glass warms from dim to amber (an animated blend, replacing today's hard material swap), the eyes flicker on with two blinks, and she rises into her bob.
5. The camera nudges to Hotaru. Her first words, "Oh. Morning.", appear as a world bubble. The portrait scene then continues from its second page.

Reusable shape for every Apply: **drawer away → camera to the change → effect in program order → reaction bubble → ticket stamp → optional portrait scene.** This slice builds it as one helper on the room stage (`WorkshopLoftStage`), with the waking as its first user.

**Where.** `scenes/workshop_loft_stage.gd` (the timeline), `app/game.gd` (`_workshop_waking`, the `loft-waking` scene needs a start page), `ui/workshop_journal.gd`, `content/journeys/sparks-and-machines.json`. A save that is already awake must not replay it. A save with the voice earned but the waking unseen (`restore_story`) keeps today's direct route. *To verify:* the camera frame API (`RoomStage.frame()`, `focus_on`).

**Checks.** `test_workshop.gd`/`test_sparks.gd` play-through still reaches the portrait scene; a new check that the skip control lands in the same end state as the full beat.

### Slice 3 — Lamplit rooms and lamp placement

**Light.** `ClearingView._make_lighting` builds one shadowed sun and `_apply_warmth` lifts it indoors to 0.75, so a closed room is lit like an outdoor afternoon. Add a per-room `interior.look: "lamplit"` (default unchanged for every other room):

- The sun becomes **window light**: cool, low (about 0.2–0.3), no hard shadow, no streaks. Optionally a soft pool under each real window.
- Ambient drops and cools. The unlit workshop reads as early, shutters half-closed: dim but legible. The readability rule in [02](02-art-direction.md) still applies.
- Each lit lamp becomes the **key light**: a warm `SpotLight3D` aimed down from the pendants, with shadows on (three spot shadows are cheap), and a shadowless omni for the stair lantern. Shadows then radiate from the lamp, so they make sense.
- The progression is visible: nothing lit is dim; the stair lantern lights the stairs; all three make the room cosy. The stove glow stays.
- The loft gets the same preset, with a little more window light, after the workshop is approved.

The user wants the look and the shadows kept ([performance memory](../../../pipeline/reviews/2026-10-25-frame-rate-and-gpu.md)): lamp shadows replace sun shadows rather than removing shadows. Re-measure frame time at the usual settings.

**Lamps.** Rules: (1) a lamp hangs over what it lights, centred on the bench's long axis and the table's centre; (2) the three lamps and the wall screen sit on **one visible circuit**, a brass conduit running from the screen to each lamp, in the same style as the city's power conduits; (3) pendants hang from something. Two ways, chosen after a look in the asset viewer: short ceiling joists crossing above each table (matching the loft's visible roof beams), or clamp-arm lamps on the benches with one pendant over the middle table.

**The order is part of the lesson.** `zone.lamps` order is authored, and the loop plays in that order. If the wire runs screen → bench → table → stairs, `lamps` and the quest text ("first the stair lantern, then…") must be reordered together, or the wire made to follow the list. Decide with the circuit.

**Where.** `scenes/clearing_view.gd`, `scenes/workshop_loft_stage.gd`, `content/areas/workshop-floor.json` (version bump; `lamps`, `interior.assets` positions, `lighting`, `lamp_fixtures`; the stair lantern's `stand` cell and the quest `focus` markers must move with it), and the lamp assets. Per [AGENTS.md](../../../AGENTS.md) the asset edits go through the request queue (`workshop-hanging-lamp`, `workshop-stair-lamp`, and the shell if joists are added), built with `scripts/world-art.sh`, and acceptance stays with the user.

**Checks.** Screenshots at zero, one and three lamps. Frame time before and after.

### Slice 4 — The lamp commit beat

Uses slice 2's helper on the lamps. A loop Apply plays the lamps in list order: a spark runs along the conduit, the lamp warms up, the room brightens a step, and the tablet's counter reads 1/3, 2/3, 3/3. Then Hotaru's reaction bubble and the ticket stamp. A single-lamp job plays one spark. Test plays the same sequence as blue ghosts only.

**Where.** `scenes/clearing_view.gd` (`apply_state`, `_set_fixture_preview`, the conduit pulse), `app/game.gd`, `ui/workshop_jobs_journal.gd`. Everything shown is derived from the committed state and command order, so a stale or rejected proposal never plays.

### Slice 5 — Chapter 2: "Again?"

**Story.** Behind the workshop card was a complaint from the north gate, with Nell's "Again?" written under "lamp replaced". Bram says the lamp was on when he went past and off when he came back. He has not touched it. (He has: he lit it by hand.) Nell's card says to flip it. Voice sketch only; the final lines follow [07](07-dialogue.md): specific, oblique, nobody explains Python.

**Code.**

```python
def program(world):
    lamp = world.lamp("gate-lamp")
    lamp.set_lit(not lamp.lit)    # Nell's card: flip it
```

Bram lit the lamp, so the starter turns it **off** and the ghost shows the lit lamp going dark. Fixes: `lamp.set_lit(True)`, or `if not lamp.lit: lamp.set_lit(True)`. The lesson names `lamp.lit`, `not` and `if`. The reference solution test also applies the fixed program twice and asserts the lamp is still lit.

**What the engine needs (verified).**
- A quest cannot set the world's starting state today. Add an optional `setup` (for example `{"lamps": {"gate-lamp": true}}`) applied once when the quest becomes current, and saved.
- `requires` is validated against quests in the same area (`AreaDef`), so the lane needs its own `haverlund-lane.quests.json`, and the workshop ticket gates it at journey level, the way `WorkshopStory.pending` does with `_journey_completed()`. Adding quests to the lane changes what its session holds (the `say-hello` gotcha in the v0.7 notes): `test_lane.gd` needs care.
- The gate lamp already has a `stand` cell and `requires: field-tablet` ability, so no new node is needed.

**Where.** `content/areas/haverlund-lane.quests.json` (new), `content/areas/workshop-floor.quests.json` (the ticket as an inspection, like "The waiting ticket"), `content/journeys/sparks-and-machines.json` (scenes, ticket "No. 4"), `core/area_def.gd` and `core/quests.gd` (`setup`), `test/test_area.gd` (reference solutions), a new `test/test_lane_quests.gd` added to `scripts/test.sh`.

**Next after it.** 04 "Both posts" needs a real gate. The lane's iron town gate is a room link today. Making it a swinging gate that stays shut until solved is the strongest proof in the ladder, but it is a progression lock on a route players already walk. Recommendation: lock it only for a save that has not yet entered the square, and keep it open for every older save.

## 4. Open decisions

1. **Next quest.** Recommended: 03 "Again?" then 04 "Both posts". Alternative: jump to 05 "Legs!" first, which is the most visual but needs new Hotaru API.
2. **The town gate.** Lock it until 04 is solved (new saves only), or leave it open and only animate it?
3. **Lamps.** Ceiling joists with pendants, or clamp-arm bench lamps? Decide from a render in slice 3.

## 5. Done means (per slice)

`scripts/test.sh` passes (new tests added to it); the changed view is reviewed in Godot at actual camera scale; a review note goes in `pipeline/reviews/`; this document, [08](08-quests.md), [UI.md](../../../pipeline/UI.md) and [09](09-zone-terminals.md) say what really works and keep proposals marked as proposals. Nothing is committed unless the user asks.
