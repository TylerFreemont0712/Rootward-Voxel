# The robot companion: Hotaru — 2026-10-26

**Status: the loft companion and greeting are implemented; the wider movement and working-mode design remains proposed.** On 2026-10-26 the user chose a robot companion, which they found more fun and more programmable, kept the name Hotaru, and asked for her to be a little cuter than the first study. Robot Hotaru belongs only to the new [Sparks & Machines journey](05-scenario.md). The fairy Hotaru in Village Morning (`art/hotaru.gd`, `content/companions/hotaru.json`) stays exactly as she is.

## Why a robot

- **She is programmable.** A fairy can only comment on your code. A robot can run it. Every new thing the player learns can become something Hotaru does in the world.
- **She explains the world.** Under the rule *magic gives a machine life, code gives it a job*, she is the clearest example: a spark makes her willing, and the player's instructions make her useful.
- **She grows visibly.** Each new ability is a new part on her body, so progress shows on screen without menus.
- **She is funnier.** She does exactly what you wrote. That makes bugs visible, harmless and often charming.

## Who she is

Hotaru is Nell’s workshop companion. She has been dozing most of this week while Nell is out on calls. The printer is connected to her message receiver; an addressed greeting rings its bell and wakes her from an ordinary nap. The new lodger has not repaired her or shown unusual mechanical ability. Her age and the player’s origins are not established.

**Open story idea:** Nell may first have built Hotaru to tend the Rootworks. That would explain why Nell kept her, and why Hotaru sometimes knows things about the network that she can't explain. See the [story spine](01-world-concept.md#story-spine-sketch).

**Personality:** curious, literal, cheerful and honest. She speaks in short sentences with slightly old-fashioned manners. She has opinions but no plans: she will tell you what she thinks of the lane, but she only *acts* through routines you write. She remembers what you taught her and is proud of each new part.

**She is authored, not an AI.** Her lines are written dialogue in `content/companions/`, using the shared conversation scene. No language model runs at play time; the game stays playable offline and without any AI service.

**Example lines** (tone only, not final copy):

- On waking: *"Oh. Morning."* · *"You’re the one in the loft, then? I’m Hotaru."*
- On a good preview: *"Ooh. It's thinking about it."*
- On an error: *"There's a word on the tape I don't know. 'lmap'. Is that a kind of lamp?"*
- On a new part: *"Legs! I'd forgotten I had legs."*

Her full voice (habits, what she never says, when she first uses the apprentice's name) is in [the dialogue guide](07-dialogue.md#hotaru).

## Design (cuter version)

The [first study](../../../art/source/companions/hotaru/v3/concept/turnaround-sheet.png) ([expressions](../../../art/source/companions/hotaru/v3/concept/expression-sheet.png)) got the parts right but read as a sturdy little barrel. The user liked the idea and asked for it **a little cuter**. Cuteness comes from proportion, softness and the face:

| Element | Spec |
|---|---|
| **Proportions** | Squat and round, about as wide as she is tall, like a plump teakettle or an egg. Her cap is big, about 40% of her height, like an oversized hat. |
| **Face** | One big round **spark window**, about 60% of her body's width, in a thick soft brass rim, set a little below the middle. The spark inside forms two large glowing oval eyes, set slightly wide, each with a tiny bright highlight. This is her one touch of visible magic and her whole range of expression. |
| **Cheeks** | Two small rosy enamel dots (`#E8A487`) beside the window, like painted blush. |
| **Cap** | A teal dome with a soft, rounded brim. On top, a small folding rotor with two rounded, slightly curled paddle blades, and a big red bobble knob, her single bright accent. |
| **Tape reader** | A narrow slot under the window, with a short curl of cream paper tape peeking out. Tape from the workshop machine feeds in, so she literally reads what you print. |
| **Arms** | Tiny stubby arms with round teal mitten hands. A favourite pose: one hand raised in a little wave. Later parts replace them (below). |
| **Legs** | Folded away while floating. When she works on the ground, two tiny round brass legs with cream button boots fold out. |
| **Back** | A small brass name plate (no legible text needed) and two rivets. |
| **Colour** | Warm cream enamel `#EFE3C6`, teal cap and bands `#2F8C8C` (highlights `#4FB3AC`), brass `#C99A3E`, red knob `#C8453A`, rosy cheeks `#E8A487`, spark `#FFC861` with a core of `#FFF1C2`. |
| **Finish** | Soft enamel, not glossy plastic. Every edge rounded; no sharp corners, exposed gears, rust or grime. |
| **Size** | Floating: about 0.32 m (a third of a cell) tall, about the size of the apprentice's head, at his shoulder. Working: the same height on her little legs. |
| **Wear** | Dusty on the first morning on the shelf; clean and polished after she wakes. |

**Expressions** come from the spark forming eyes. The same set serves the in-world model and the painted portrait.

| Expression | Eyes | Used when |
|---|---|---|
| Off | No spark | Before waking; switched off |
| Neutral | Two soft dots | Default |
| Happy | Two upward arcs | Success, greetings |
| Thinking | One eye narrowed | Preview, reading code |
| Surprised | Two wide rings | A new part, an unexpected result |
| Stopped | Eyes low, quick flicker | An error; always paired with a small shudder |

## Two modes

The modes keep today's companion behaviour and add a programmable one with clear rules.

| | **Following** (today's behaviour) | **Working** (new) |
|---|---|---|
| Where | Floats beside the apprentice | Stands on a grid cell |
| Occupies cells | No; cosmetic only, no collision | Yes; she blocks her cell like any actor |
| Movement | Smooth follow | Grid steps by the player's rules: same foot footprint, passages, slopes and stairs |
| Started by | Default | A program that uses her |
| Ends | — | When she is called back (F, or the speech bubble), or when the apprentice leaves the area |

She lands on the nearest free cell beside the apprentice when a routine starts. When it ends she waits where it left her, glowing idle, until called back. Whether her parked spot is saved is a decision for the first working-mode slice.

## Programmable growth

Each part is a capability, using the existing `Quests` `unlocks` and capability mechanism. Each one arrives through its own lesson and adds a visible part to her model. The existing `world` API stays valid; her parts add new abilities alongside it.

The Python below is **illustrative only**. Names are proposals to be settled when each stage is designed.

| Part | Capability | Python (illustrative) | Teaches | What changes on her |
|---|---|---|---|---|
| **Tape reader** | (exists) | `print("Hello, Hotaru!")` | Calls, strings | She wakes |
| **Walking legs** | `walk` | `hotaru.step("north")`, `hotaru.turn("left")`, `hotaru.cell` | Sequences, loops | Legs fold out |
| **Hand** | `reach` | `hotaru.use(world.lamp("landing-lamp"))` | Objects, method calls | A small hand on one arm |
| **Lens** | `sense` | `hotaru.ahead`, `hotaru.can_step("east")` | Conditions, `while` loops | A lens hood over her window |
| **Gripper** | `carry` | `hotaru.pick_up()`, `hotaru.put_down()`, `hotaru.holding` | State, variables | A gripper claw |
| **Memory drum** | `remember` | `hotaru.memory["route"] = [...]` | Lists, dictionaries | A brass drum on her back |
| **Routine slots** | `routines` | A function she runs on a trigger such as dusk or the bell | Functions, events | Card slots on her side |
| **Radio** | `radio` | `hotaru.send("lamplighter", "start")` | Messages, networking | A short antenna |
| **Helper bench** | `helpers` | `class Helper: ...` describing small helpers the workshop can build | Classes, objects, concurrency | Tiny helpers that follow her |

**Some parts need new runtime design, not just new commands.** Routine slots require the game to re-run a saved program when a world event happens. Today a program runs once when the player presses Run, so each of these parts needs its own design pass first.

## Rules she follows

These are the project's existing rules applied to her. They are not exceptions.

- **Every action is a command validated by `core/`.** For example, a step has an explicit type, target, direction, range, occupancy rule and plain-word error. Batches are atomic.
- **Preview, then Apply.** In preview, a translucent ghost of Hotaru walks the proposed route, with numbered steps. Apply commits exactly that proposal. Editing the source, moving, undoing or resetting makes the preview stale.
- **She only knows places you have visited.** Asking her to go somewhere unknown is an error that lists what she does know.
- **Errors stop her safely.** The preview stops at the failing step. The notebook explains the error in plain words, and she adds one in-character line. Nothing is damaged.
- **She never runs code herself.** All player code runs in the WASI sandbox. She is a presentation of validated commands.
- **No grid cheating.** She cannot cross water, gaps or blocked cells the apprentice cannot, unless a later part explicitly adds that ability with its own rules.

## Art production

- **In the world:** a 3D model in the world-asset pipeline (`pipeline/WORLD_ASSETS.md`), with each part a separate mesh that can be shown once unlocked. The spark window is a separate mesh with its own named material, so the game can find and light it. This follows the lamppost's `lamp_glass` convention; a name such as `spark_glass` is suggested.
- **Four views:** as a 3D model she turns naturally; no mirrored sprite pairs are needed.
- **Portrait:** painted in the residents' portrait style, three-quarter view, with the six expressions above.
- **Concept first:** prompts `H1` (turnaround), `H2` (expressions), `H3` (portrait) and `H4` (scale in the world) in [the prompt pack](04-art-prompts.md#phase-2--hotaru), reviewed by the user before any modelling. The 3D model is then rebuilt to match the approved `H1`. The first study's Blender source (`art/source/world/hotaru-robot/v1/`) is a starting point, not the final model.

## Beside the fairy, not instead of her

Village Morning keeps the fairy. The robot is a separate companion that only the new journey selects ([implementation outline](05-scenario.md#implementation-outline-for-the-coding-agent-later)).

| Shared with Village Morning | Robot only (new files and ids) |
|---|---|
| The name Hotaru (Japanese for *firefly*; Nell named her for the spark). Decided 2026-10-26. | Her body: a `HotaruRobot` node and a registered 3D model |
| The lesson programs `print("Hello, Hotaru!")` and First Steps, and their rules | Her portrait and compact avatar: an `art-catalog` `companions.hotaru-robot` entry with its own runtime files |
| Field Notes /00 and /01 flow, Test and Speak, the shared dialogue scene, the F prompt | Her dialogue: `content/companions/hotaru-robot.json`. Instead of the apprentice having no voice, Hotaru has been dark, and the first program wakes her. |

## Suggested stages

Each stage is one small, reviewable slice, reviewed in Godot at gameplay scale.

0. **The new journey's companion.** In the Sparks & Machines first slice, robot Hotaru follows the apprentice and runs Field Notes /00 and /01 with today's rules. Village Morning is unchanged.
1. **Walking legs.** Working mode, `step` and `turn`, ghost preview, and one lesson in the workshop yard.
2. **Hand and lens.** Using things and sensing the cell ahead, with a short route lesson on the outskirts.
3. **Gripper and memory drum.** Deliveries for residents.
4. **Routine slots, radio and helpers.** Each needs its own runtime design first (above).
