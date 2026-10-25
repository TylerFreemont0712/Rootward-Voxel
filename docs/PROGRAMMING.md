# The programming API

This describes what a player's Python can do today. The authoritative implementations are `sandbox/world_harness.py` (the objects), `core/lab_world.gd` (what is legal) and `app/session.gd` (preview, apply, undo). The in-game Reference tab is generated from `core/api_reference.gd`, and a test checks that every entry exists in the harness.

Residents offer optional [conversation examples](../pipeline/DIALOGUE.md) for variables, loops, functions, lists and conditions. **Show code** is read-only; **Copy example** and **Open notebook** let you try one deliberately. Opening an example leaves your draft, world and quests unchanged.

## Your program

The notebook runs a function called `program` inside CPython/WASI each time you press Run:

```python
def program(world):
    green = world.zone("green")
    for lamp in green.lamps:
        lamp.set_lit(True)
```

You do not need to return anything. Calls like `lamp.set_lit(True)` are recorded as commands. Run **previews** the proposed changes, drawn in the world as translucent shapes and listed in the notebook; **Apply** commits that exact validated proposal. Editing the source, taking a step, undoing or resetting makes a preview stale.

## Objects

| Object | You get it from | Members |
|---|---|---|
| `world` | passed to `program` | `lamp(name)`, `lamps`, `gate(name)`, `gates`, `bridge(name)`, `bridges`, `prop(name)`, `props`, `house(id)`, `houses`, `tree(x, y)`, `trees`, `doodad(id)`, `doodads`, `zone(name)`, `zones`, `here`, `player`, `memory` |
| Zone | `world.zone("green")`, `world.zones` | `id`, `name`, `lamps`, `gates`, `bridges`, `props`, `houses`, `trees`, `doodads` |
| Lamp | `world.lamp("landing-lamp")`, `zone.lamps` | `id`, `zone`, `cell`, `lit`, `set_lit(True/False)` |
| Gate | `world.gate("night-gate")`, `zone.gates` | `id`, `zone`, `cell`, `is_open`, `set_open(True/False)` |
| Bridge | `world.bridge("mill-bridge")`, `zone.bridges` | `id`, `zone`, `cells`, `built`, `place_deck(cell)`, `remove_deck(cell)` |
| Prop | `world.prop("prop-1")`, `world.props`, `zone.props` | `id`, `asset`, `name`, `zone`, `cell`, `active`, `set_active(True/False)` |
| House | `world.house("home")`, `world.houses`, `zone.houses` | `id`, `kind`, `name`, `at`, `cell`, `facing`, `zone`, `locked`, `face("north")` |
| Doodad | `world.doodad("prop-1")`, `world.doodads`, `zone.doodads` | `id`, `kind`, `name`, `at`, `cell`, `facing`, `solid`, `zone`, `face("east")` |
| Tree | `world.tree(31.5, 6)`, `world.trees`, `zone.trees` | `at`, `cell`, `size`, `kind`, `zone` |

An object mirrors your own calls: after `lamp.set_lit(True)`, `lamp.lit` is `True` in the same run, so `if west.lit and east.lit:` sees what you just did. `world.memory` is a dictionary of small JSON values that persists once you Apply.

**Places you have not visited do not exist.** A zone becomes known when you step into it. `world.zones`, `world.lamps` and friends only list known places, and asking for an unknown id raises a `WorldError` that lists what you do know. Commands against an unexplored zone are also refused by the rules. Only interactive props appear in `world.props`; a prop in a named district follows that district's discovery. A prop outside named districts is visible to Python while you are within 2.2 cells of it.

Older programs still work: `world["player"]` and `world["memory"]` read the raw snapshot, and a program may still return `{"commands": [...], "memory": {...}}` or a plain list of raw commands.

## Commands the world accepts

The objects above produce these commands, and `core/` validates every one, whatever produced it:

| Command | Required fields | Rule |
|---|---|---|
| `set_field` | `op`, `entity_id`, `field`, `value` | Lamps expose `enabled`; gates expose `open`; interactive props expose `active`. `value` must be a real Boolean. The target must be known. A gate cannot close on the cell the player stands on. |
| `place` | `op`, `kind`, `at` | `kind` is `bridge_deck`; `at` is a bridge socket `[x,y,0]`. Decks go down in socket order, so each is supported by the one before. Placing a deck that exists is harmless. |
| `remove` | `op`, `at` | Removes the last deck of a bridge. Not under the player; not leaving a deck unsupported. |
| `rotate` | `op`, `entity_id`, `facing` | Turns a house or doodad on the spot; `facing` is `N`, `E`, `S` or `W`. Needs the `turn` ability; see [Houses, trees and doodads](#houses-trees-and-doodads). |

Extra fields and unknown commands are rejected. Commands run in order against a detached candidate; one invalid command rejects the whole batch. Up to 64 commands are allowed. Cells are whole-number `[x,y,height]`. Height is always 0 in code today, even where build mode has raised the land into terraces.

Walking takes one cardinal cell at a time; the picture slides smoothly between centers while the authoritative state commits at the end of each step. Passage checks use the full circular foot footprint against buildings, trunks, lamp posts, fences, walls, rock, water and closed gates.

## Previews, undo and reset

Run cancels a click route, waits for an active step to finish, then executes your code against that settled snapshot. Apply is unavailable during a step, so a program cannot remove support from under a walking character. **Undo** reverts the most recent committed world change, whether an applied program or a manual prop action (lamps, gates, bridges, working props, memory) and leaves you where you stand and what you have discovered intact; it refuses while you stand on a deck or gate it would remove. **Start the hollow over** darkens the valley and deactivates working props but keeps your code, finished quests, explored places and build edits. Saved active states survive moving or turning a prop and Continue; older saves with no prop state start those props inactive.

## Working props

Place an interactive item from the [builder library](../pipeline/BUILDER_LIBRARY.md), choose the standing object with Move, and read its actual `prop-N` id and Code section. **Write code for it** inserts the fetching line. These instance ids are distinct from asset names such as `hollow-brass-lever`.

```python
def program(world):
    lever = world.prop("prop-1")
    lantern = world.prop("prop-2")
    lantern.set_active(lever.active)
```

Replace the two ids with your own placed objects. `active` is a Boolean: it opens/closes a chest, pulls/resets a lever, starts/stops a wheel or pump, swings/stops a bell, or lights/dims a glowing piece. Static furniture is absent from this API. Python may change known objects remotely, like lamps; **F** is a nearby manual action requiring a clear approach within 2.2 cells. Neither path changes support or the object's blocking footprint. A manual action clears a stale code proposal. The bell animates without audio; containers have no inventory, and workbenches do not craft items.

## Houses, trees and doodads

Your code can read the village's houses, trees and doodads, and turn houses and doodads, once the lessons have taught it. These are **structures**, not state: a change is one of the builder's own edits (`{op: "move", …, turned: true, by: "code"}`), kept in the same layer over the area document, saved with the journey and drawn by the same code. A working prop is a doodad too, with the same id: `world.prop(id)` gives its on/off state, `world.doodad(id)` where it stands.

```python
def program(world):
    row = world.zone("cottage-row")
    for house in row.houses:
        if house.cell[1] < 18:
            house.face("north")
```

`facing` is a word (`"north"`, `"east"`, `"south"` or `"west"`); `at` is the centre as `[x, y]` (x grows eastward, y northward); `cell` is `[x, y, 0]`, so `house.cell[1]` is how far north it stands. `kind` is the builder tray's own id (`"house-hollow"`, `"tree-oak"`, `"park-bench"`). Trees have no id and no facing: `world.tree(x, y)` finds the one standing there, and `world.trees` lists them. The object mirrors your calls (`house.face("north")` then `house.facing == "north"`), and asking for the facing a house already has records nothing.

**Abilities.** A lesson's `unlocks` list teaches the code an ability: `read` (see houses, trees and doodads) and `turn` (`face`). The ability arrives when the lesson is **reached** (becomes available), not when it is finished, because the lesson's own goal needs it; finishing keeps it. Until then, `world.houses` and friends raise a `WorldError` that names the lesson, the Reference tab dims those entries with the same lesson in the tooltip, and the World tab says where they will appear. The harness only explains this; the host enforces it, so a hand-written `rotate` command is refused too. For trying the API without playing to the lesson, start the game with `VOXEL_CODE_ABILITIES=all` (or `read,turn`).

**Reach.** Code sees and touches a thing only if it stands in a place you have visited, **or** within 12 cells of where you stand. (The valley's named places cover only about two thirds of it and most trees stand between them, so the second rule is what makes the forests reachable: walk there.) The test applies to the thing's own position, and to both ends of anything that moves.

**Rules.** Each command is checked by the same rules as the builder (`AreaBuild.check_*`): a house cannot turn to face water, rock or another wall, locked things (the mill) refuse with "part of the lessons", and the refusal is in plain words with the command's number (`Command 2: …`). A run may use at most 16 building commands. Building is refused inside a home (go outside first). The whole batch is atomic: if any command is refused nothing changes. The cheap rules run for every command against the world the earlier ones left; the slow check that nothing you need is cut off (every lamp, door and place stays reachable) runs **once** for the whole batch.

**Preview, Apply, Undo.** Run draws translucent models where a house would turn (up to 48); Apply commits that same proposal into the builder's edit list, so it saves, shows in build mode's history and undoes like any edit. **Undo** takes a program's building away with its other changes, but only while nothing has been built since: if you have placed or moved things by hand, undo those first (the notebook says so) rather than have history reordered. **Start the hollow over** keeps everything built.

Captures: [the World tab](../evidence/code-world-tab.png), [a Run preview](../evidence/code-preview.png), [after Apply](../evidence/code-applied.png) and [the builder's Code section](../evidence/code-build-details.png) and, in the second chapter, [the lesson](../evidence/code-lesson.png) and [the journal](../evidence/code-journal.png).

**The lesson.** `read` and `turn` are taught by **Face the lane**, the first lesson of an optional second chapter ("Chapter two · Shaping the hollow") that opens after the epilogue: the two southern cottages of Cottage Row turn their sides to the lane, and the player loops over `row.houses`, tests `house.cell[1] < 18` and calls `house.face("north")`. The goal is the `houses_facing` goal type; the reference solution is in `test/test_area.gd` and its starter, which only prints what each house knows, does not solve it. The five-quest arc and its epilogue are unchanged: the epilogue fires when the *main* arc finishes (quests marked `optional` never hold it back or repeat it), points to the chapter, and the journal lists the chapter under its own heading.

**Status.** The abilities, rules, preview, apply, undo, interface and the first lesson are built and tested (`test/test_code_build.gd`, `test/test_area.gd`). Not built yet: placing, moving and removing houses, trees and doodads from code, and the lessons that would teach them. These later abilities are planned; nothing exposes them. `VOXEL_CODE_ABILITIES=all` (or `read,turn`) still grants abilities regardless of lessons, for trying the API early.

## Errors and help

A failed run reports the **line**, marks it in the editor, explains the mistake in plain words and, for typos, suggests the nearest known name ("Did you mean `True`?"). The raw Python message is always shown too. Common causes are mapped in `core/error_advice.gd`: syntax and indentation errors, unknown names and attributes, wrong value types, missing keys, unknown ids.

## Limits

The Python sandbox has a 2-second runtime timeout, a 7-second wall-clock backstop, a 96 MiB memory cap and a 32 KiB combined output cap. Source is limited to 16 KiB, returned results to 16 KiB, memory to 2 KiB of small JSON at most four levels deep. Player code receives its job files and a read-only standard library; it cannot reach the host filesystem or network, and it never runs in host Python.

## Where to look

`docs/PROGRAMMING.md` (this) · `sandbox/world_harness.py` (objects) · `core/lab_world.gd` (rules) · `core/code_build.gd` (what code may do to houses, trees and doodads) · `core/api_reference.gd` (what the Reference tab and completion show) · `content/areas/kindle-hollow.quests.json` (the lessons that teach it).
