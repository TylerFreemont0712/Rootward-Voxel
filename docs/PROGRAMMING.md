# The programming API

This describes what a player's Python can do today. The authoritative implementations are `sandbox/world_harness.py` (the objects), `core/lab_world.gd` (what is legal) and `app/session.gd` (preview, apply, undo). The in-game Reference tab is generated from `core/api_reference.gd`, and a test checks that every entry exists in the harness.

## Your program

Field Notes run a function called `program` inside CPython/WASI each time you press Test or Debug:

```python
def program(world):
    workshop = world.zone("workshop")
    for lamp in workshop.lamps:
        lamp.set_lit(True)
```

You do not need to return anything. Calls like `lamp.set_lit(True)` are recorded as commands. Run **previews** the proposed changes, drawn in the world as translucent shapes and listed in the notebook; **Apply** commits that exact validated proposal. Editing the source, taking a step, undoing or resetting makes a preview stale.

## Objects

| Object | You get it from | Members |
|---|---|---|
| `world` | passed to `program` | `lamp(name)`, `lamps`, `gate(name)`, `gates`, `bridge(name)`, `bridges`, `zone(name)`, `zones`, `here`, `player`, `memory` |
| Zone | `world.zone("workshop")`, `world.zones` | `id`, `name`, `lamps` (and `gates`, `bridges` where an area has them) |
| Lamp | `world.lamp("landing-lamp")`, `zone.lamps` | `id`, `zone`, `cell`, `lit`, `set_lit(True/False)` |
| Gate | `world.gate("id")`, `zone.gates` | `id`, `zone`, `cell`, `is_open`, `set_open(True/False)` (engine support; no shipped room has a programmable gate) |
| Bridge | `world.bridge("id")`, `zone.bridges` | `id`, `zone`, `cells`, `built`, `place_deck(cell)`, `remove_deck(cell)` (engine support; none shipped) |

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

Extra fields and unknown commands are rejected. Commands run in order against a detached candidate; one invalid command rejects the whole batch. Up to 128 commands are allowed. Cells are whole-number `[x,y,height]`. Height is always 0 in code today, even where build mode has raised the land into terraces.

Walking takes one cardinal cell at a time; the picture slides smoothly between centers while the authoritative state commits at the end of each step. Passage checks use the full circular foot footprint against buildings, trunks, lamp posts, fences, walls, rock, water and closed gates.

## Previews, undo and reset

Run cancels a click route, waits for an active step to finish, then executes your code against that settled snapshot. Apply is unavailable during a step, so a program cannot remove support from under a walking character. **Undo** reverts the most recent committed world change, whether an applied program or a manual prop action (lamps, gates, bridges, working props, memory) and leaves you where you stand and what you have discovered intact; it refuses while you stand on a deck or gate it would remove. **Start the hollow over** darkens the valley and deactivates working props but keeps your code, finished quests, explored places and build edits. Saved active states survive moving or turning a prop and Continue; older saves with no prop state start those props inactive.

## Tram message cards

After Iona's commission conversation, F at the tram welcome sign opens its own slate page. This context directs `print` into a card, instead of speaking to Hotaru. A program finishes normally; the sign's presenter repeats the installed pages every four seconds without running Python again.

This is the same field-slate workspace used for workshop lights: Job/Index/Names/Hints notes, files, devices, variables, the code editor and line debugger. The job book can walk you to its connection. Drag or fold the sidebar, or press Ctrl+B, to enlarge the code view; Put away still tucks the paper notes. There is one Debug → Apply routine flow for both jobs.

```python
def program(world):
    messages = [
        "Welcome to Spindle Lane",
        "No. 7 stops here",
        "Tea first. Tram second.",
    ]
    for message in messages:
        print(message)
```

Several ordinary `print` calls work too. Completed logical lines become messages, preserving `sep`, `end` and explicit newlines. A final newline terminates the last message. Use one to three nonblank messages, at most 32 printable ASCII/Latin-1 characters each; two distinct installed messages complete the job. Controls, emoji and longer output give a plain error. Each message wraps into two fixed-width rows of 16 cells. Debug previews the whole card and lets you step through its pages; Apply commits the same validated proposal. Editing/moving/closing/travel clears a stale preview. Messages and the separate draft save. Rewriting the card never pays the wage again.

The internal typed command is `set_sign_messages` with a mounted target ID and full message list. Core validates commission, carried slate, visited zone, physical range and text before accepting a batch atomically. No new general device API or money-writing capability is exposed to player code. See [property rules](../pipeline/PROPERTY.md).

## Errors and help

A failed run reports the **line**, marks it in the editor, explains the mistake in plain words and, for typos, suggests the nearest known name ("Did you mean `True`?"). The raw Python message is always shown too. Common causes are mapped in `core/error_advice.gd`: syntax and indentation errors, unknown names and attributes, wrong value types, missing keys, unknown ids.

## Limits

The Python sandbox has a 2-second runtime timeout, a 7-second wall-clock backstop, a 96 MiB memory cap and a 128 KiB combined output cap. Source is limited to 64 KiB, returned results to 64 KiB (raised from 16 KiB on 2026-10-30 so longer programs and debugger evidence fit), memory to 2 KiB of small JSON at most four levels deep. The output cap stays above the result cap because the framed result travels in the same stdout as the program's printing. Execution evidence also carries the program's own variables: each traced line records the names that changed (short, Python-shaped text such as `Lamp('landing-lamp')`), and the names `program` held when it returned come back as `locals`; both are text only, bounded and validated (`LabProgram.safe_trace`, `safe_names`). Player code receives its job files and a read-only standard library; it cannot reach the host filesystem or network, and it never runs in host Python.

## Where to look

`docs/PROGRAMMING.md` (this) · `sandbox/world_harness.py` (objects) · `core/lab_world.gd` (rules) · `core/api_reference.gd` (what the Reference tab and completion show) · `content/areas/*.quests.json` (the lessons that teach it).

## Shared time and daylight routines

Sparks & Machines exposes `world.time.is_dark`, a Boolean that is True from 18:00 until 06:00. `world.time.hour` is a fractional hour from 0 to just below 24; `phase` is Morning, Day, Evening or Night, and `day` starts at 1. The clock is read-only. It is shared across the loft, workshop, lane, square and city hall, saved between sessions, and paused while reading, coding or talking. City pressure and breaker controls are not part of the player API.

Every placed lamp-glass/festoon-glass model is connected: 148 logical fittings cover the loft, workshop, lane, square, surrounding house lanterns and City Hall. Background and large-building lanterns are addressed from the district service screens; their code does not require walking off the map.

At a lamp’s shared field slate, **Daylight routine** makes Debug execute the same Python twice in the WASI worker: a daylight input and a darkness input. Each connected lamp must receive a Boolean instruction in both tests. Apply installs those two decisions; the clock selects between them on later dusk/dawn changes. This is a finite day/dark controller, not arbitrary background Python or a minute-by-minute scheduler. Other device/build commands belong on separate pages. Manual lamp instructions remain available when the mode is unchecked.

```python
def program(world):
    lamp = world.lamp("shop-door-lamp")
    if world.time.is_dark:
        lamp.set_lit(True)
    else:
        lamp.set_lit(False)
```

The shop’s Chapter 04 ticket requires the correct decision for **both** connected shop lamps, plus Nell’s accepted ticket. A permanently lit lamp does not complete it. Debug remains a proposal; Apply commits that same validated day/night table, and Undo restores the previous table. Time itself is outside machine Undo.

## Service robots

The street service screen, square screen and civic screen expose `world.robots` and `world.robot(id)`. A worker’s place must already have been visited. Its `id`, `running`, `speed`, `stops` and current `route` are readable. Some workers also have a nearby authored service point. The runtime validates every command again; a fake address, unsupported stop or out-of-range speed rejects the whole batch.

```python
def program(world):
    wick = world.robot("square-wick")
    print(wick.stops)
    wick.set_speed(2.5)       # 0.5 to 3 cells per second
    wick.set_route([wick.stops[-1], wick.stops[0]])
    wick.resume()            # pause() stops the round
```

A route contains 1–12 names from that worker’s own service stops; normal collision, residents and passages still apply. Settings are saved per room and take part in Preview, Apply and Undo. This first interface controls work rounds and pace. Fault-specific repairs and arbitrary robot movement destinations are not implemented.
