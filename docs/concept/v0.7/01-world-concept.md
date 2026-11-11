# World concept: Sparks & Machines — 2026-10-26

**Status: direction chosen, not implemented.** The user settled the open decisions on 2026-10-26 ([list](README.md#decisions)). The first loft and greeting are playable; the wider setting and story below remain proposals. It is the setting of a **new, separate journey** ([the scenario](05-scenario.md)); Kindle Hollow and Village Morning are unchanged. It does not change the engine, rules, sandbox or lesson systems.

## One line

An apprentice spends a year at the edge of a sunlit harbour town where helpful machines have gone quiet. Writing real Python gives them their jobs back.

## The rule of the world

> **Magic gives a machine life. Code gives it a job.**

This sentence answers every "why does code do that here?" question. It also sets how much magic the world has.

- **The spark** is the world's one fantastical thing. It is a small, warm light that lives behind glass in lamps, windows and automatons. People treat it the way we treat electricity: useful, ordinary and a little wonderful. It comes up from **the roots** under the hills (below), is stored at the sparkworks (the old brook mill), carried in glass and paid for on a bill.
- **Automatons** are machines with a spark inside. A spark makes a machine willing. It does not tell the machine what to do. Instructions are written for it, and the town has nearly forgotten how to write them.
- **Code is never a spell.** Programs are real Python run in the existing sandbox, and the game says so. The fiction calls them *instructions*, *routines* or *cards*, never incantations.

**What the world does not have:** fairies, spirits, runes, crystals, wards, prophecies, chosen ones, ancient evils, wands or spell words. There is no danger and no villain. Everyday problems are practical: an outage, a jammed lock, a late delivery, a festival to get ready.

**Mystery, not mysticism.** The world does have one big unanswered question: where the spark comes from, and why it is fading. It is a mystery with answers the player can investigate, read in old routines and reach on foot. Nobody worships the roots, and nothing about them is foretold.

## The roots

**Decided 2026-10-26.** The spark has two halves, which match the rule of the world:

- **The living roots (the magic).** Far beneath the hills runs an ancient system of living root-veins that slowly makes the spark. No one alive has seen where it begins.
- **The Rootworks (the machine).** Long ago, founders nobody remembers built a buried network to tap the roots: pipes, cables, valves, relay chambers and old tender automatons. It runs from the deep roots up to **the Rootwell** in the town square, then out under the cobbles to every lamp and automaton. The sparkworks is one tap on that network.

**The mystery.** The Rootwell's dial has been dropping for years. Lamps are a little dimmer and automatons go quiet one by one, and the town blames age. It isn't random. The questions that drive the story:

1. Why is the spark fading, and why only in some branches?
2. Who were the founders, and why can nobody read their routines any more?
3. What is at the bottom, where the roots begin?

The player answers them with code: reading the founders' old routines, tracing the network branch by branch, and repairing relay routines on the way down.

**Why it suits the game.** Going *rootward* means following the network down toward its source, which gives the game's title a meaning. The Rootworks is literally a tree with a root, so its puzzles teach tree structures, recursion, graph traversal and reading someone else's old code, the advanced topics that come at the end.

## Setting

**Era.** A gentle mid-century that never quite existed. It has telephones and a switchboard, radios, bicycles, a tram up the hill, a few small round delivery vans, posted letters and telegrams, typewriters and an airship that crosses the sky now and then. It has no screens, computers, plastic, neon or highways.

**Place.** **Haverlund**, a harbour town on a hillside, with plaster houses and copper-roofed spires. The game begins on its wooded edge:

| Area | Role in the concept | Starting point (new area documents, never edits) |
|---|---|---|
| **Kindle Hollow** | The wooded outskirts above the town: cottages, the brook, the old mill (now the sparkworks), orchards, a tram halt at the lane's end. It is where the apprentice proves themself. | A new outskirts map modelled on `kindle-hollow.json` and its five lessons |
| **The workshop** | The apprentice's home and business, an old automaton-maker's workshop with a loft bedroom. | New loft and workshop interiors, using the same interior flow as Village Morning's home |
| **Rootward Square** | The upper square where the edge of town meets the hill: the Rootwell at its centre, and the town hall with its clock. | A new square modelled on Village Morning's, keeping its town hall design; the Rootwell instead of the oak |
| **Haverlund harbour** | *Future.* Steep lanes, stairs, market, tram, harbour cranes, the lighthouse and the telephone exchange. | Not built |
| **The Rootworks** | *Future.* The buried network under the town and hills: brick vaults, relay chambers, tender automatons, and the living roots threading through it all. | Not built |

The world grows as the programming grows. Outskirts teach fundamentals; the town brings data, scheduling and messages; the harbour brings many machines working at once; the Rootworks brings trees, recursion and old code.

## The player's year

The player is an ordinary new lodger. Their previous home and reasons for arriving are left open. They rent the loft above Nell’s workshop. Hotaru has been dozing while Nell is out on calls this week; the desk printer’s message bell gets her attention. Sending a greeting is a first use of an unfamiliar tool, not a remarkable repair. That robot is **Hotaru**, their companion ([full design](03-robot-companion.md)).

The emotional thread is independence and craft: learning a trade, earning a place in a new town, and keeping going when the work goes wrong. The story has one deliberate setback. A big job fails in public, and the apprentice gets back their confidence through small programs that work. Debugging is the emotional arc as well as the skill.

## Story spine (sketch)

This is a shape to build toward, not a script.

| Act | Where | What happens | Programming |
|---|---|---|---|
| **1. Light the hollow** | Kindle Hollow, the workshop, Rootward Square | The apprentice wakes Hotaru, lights the Hollow and earns the town's first jobs. Nell notices the Rootwell's dial and says nothing. | Calls, loops, variables, conditions, functions |
| **2. The town** | Haverlund | Jobs across town. Then the setback: the festival lights fail in front of everyone. Part of the failure is the apprentice's own bug, which they find and fix. Part of it isn't: a whole branch of the network has gone dim. The mystery becomes undeniable. | Data, sorting, scheduling, messages, many machines at once |
| **3. Rootward** | The Rootworks | With Nell's memories and Hotaru's help, the apprentice follows the network down, reads the founders' routines, wakes the tender automatons and reaches the roots. | Trees, recursion, graph traversal, reading old code |

**Open story questions** (not decided; they don't block the first slices):

- **What is wrong at the roots?** One cozy direction: the roots aren't dying, they are *growing*, and the founders' fixed routines can't follow them. The town needs new routines that respond to a living thing, and someone who keeps maintaining them. That echoes the apprentice's own year.
- **Hotaru's origin.** Was she first built to tend the Rootworks? That would explain why Nell kept her and why she knows things she can't explain.
- **Nell's part.** How much did she know about the dial, and why did she stop going down?
- **Who was R.W.?** The founders' card is signed R.W. and warns *never more than three branches at once*. Lighting the whole hill drops the Rootwell's needle ([Job 6 and Job 7](08-quests.md#job-6--light-the-hollow)).

## Core loop

1. **A job arrives.** Residents pin orders to the workshop board or ask in person, using the existing in-world cues: speech bubbles, use icons, `!` and `?` marks.
2. **Go and look.** Walk to the machine. Read its parts, its route and its spark window. Code can only see places you have visited (existing rule).
3. **Write the routine.** Use the Field Notes, with blocks or Python.
4. **Preview.** The machine's ghost shows the proposed result (existing Preview rule).
5. **Apply.** The routine card slides into the machine and it goes to work (existing atomic Apply).
6. **Reward.** New parts for Hotaru, paint and fittings for the workshop, new customers and new areas.

Every effect of code is carried out by a machine the player can see. A lamp lit by code is lit by the lamplighter or the wire to that lamp. A house turned by code is turned by the crane.

## How today's lessons carry over

The new journey retells today's lessons in its own areas, with the same rules and goal types. The existing journeys themselves are unchanged. The full quest design, with starters, solutions and side jobs, is in [the quest design](08-quests.md); the dialogue is in [the dialogue guide](07-dialogue.md).

| Existing piece | In this concept |
|---|---|
| *A spark at the landing* (method call) | The first lamp on the lane. The wire runs from the sparkworks, but nobody wrote the switch-on routine. |
| *Light the green* (lists, for-loops) | The lamplighter automaton's route around the green. |
| *A way across* (variables) | The mill bridge decks, laid by the yard machine. |
| *The night gate* (if/else) | The gate's catch only releases when both lamps beside it are lit. |
| *Kindle the hollow* (functions) | One routine lights the whole Hollow, including the signal lamp at the Old Watch (formerly the beacon), which the town below can see. |
| *Face the lane* (optional chapter) | Bram's crane turns the cottages to face the lane. |
| *Field Notes /00, Saying Hello* | Waking Hotaru: `print("Hello, Hotaru!")` comes out of the workshop's tape machine, Hotaru reads her own name, and she wakes. The program is unchanged. |
| *Field Notes /01, First Steps* | The apprentice's own key bindings, demonstrated in the workshop. |
| Rootward oak | Not in the new journey. **The Rootwell** stands at the centre of its square (see the [art brief](02-art-direction.md#the-rootwell)). |

## Residents

Full looks, wardrobe and voices are in [the characters document](06-characters.md). In the new journey each resident keeps their name, face and teaching topic. Each gains a mid-century trade and a machine they care about. Nell's new role was decided on 2026-10-26; the others are suggestions.

| Resident | Today | Suggested role | Their machine | Teaches |
|---|---|---|---|---|
| Mira | Cartographer | Surveyor and map-maker | Route maps for the delivery automaton | Variables, coordinates, routes |
| Rowan | Millwright | Keeps the sparkworks (the old mill) | Mill wheel, sluice gates | Conditions, state, timing |
| Bram | Carpenter | Carpenter and builder | The yard crane | Attributes, turning and placing (code that builds) |
| Tessa | Gardener | Orchard keeper | A gardener automaton in the rows | Loops over rows (grids) |
| Nell | Herbalist | Retired automaton-maker and your landlady | Hotaru, whom she built long ago | Functions, "write it down once" |

Nell's change is the largest, and the most useful to the story: she is the one person who still remembers how routines were written, and the last person who went down into the Rootworks. She can no longer write routines herself.

## Automaton roster

These are the machines the world could need. They are listed roughly in teaching order. Each is a real place in the world with a job, not a minigame menu.

| Machine | Where | Its job | Programming concepts | Size |
|---|---|---|---|---|
| **Hotaru** | Everywhere | Companion; anything you teach her | Everything, one part at a time | Small |
| **Lamplighter** | Lanes | Lights the lamps along a route at dusk | Calls, lists, loops | Medium |
| **Sparkworks wheel** | The brook | Opens sluices, fills spark jars | Conditions, state, events | Large, fixed |
| **Yard crane** | Bram's yard | Lays bridge decks, turns and places houses | Attributes, coordinates | Large |
| **Gardener** | Orchard | Plants, waters and harvests rows | Nested loops, grids | Medium |
| **Clock and bells** | Town hall | Rings the hours, plays tunes | Sequences, lists, timing | Large, fixed |
| **Post sorter** | Post office | Sorts letters and plans rounds | Sorting, dictionaries, pathfinding | Medium |
| **Lock keeper** | Canal or drawbridge | Lets boats and carts through safely | State machines | Large, fixed |
| **Tram** | The hill | Keeps the timetable | Queues, scheduling | Large |
| **Switchboard** | Telephone exchange | Connects calls between houses | Messages, routing, networking | Large, fixed |
| **Weather station** | Hilltop | Records readings and warns the harbour | Data, averages | Small, fixed |
| **Festival helpers** | The square | Many machines working together | Concurrency, coordination | Mixed |
| **The Rootwell** | Rootward Square | Shows the network's pressure; opens and closes branches | Reading state, conditions over many values | Large, fixed |
| **Relay chambers** | The Rootworks | Route spark between branches | Graph traversal, finding faults | Large, fixed |
| **Tender automatons** | The Rootworks | Follow the roots and keep the pipes clear; asleep for decades | Trees, recursion, reading and repairing old routines | Medium |

## Ideas backlog

Not decided; collected so they aren't lost. Each would be a job from a resident, never a separate minigame menu.

- **The tram timetable:** schedule the tram so nobody waits more than a few minutes (queues, scheduling).
- **Sorting the post:** Pip's pigeonholes, faster each day (sorting, dictionaries).
- **Bell tunes:** compose the clock tower's hourly tune as a list of notes (sequences, lists, loops).
- **The festival light show:** many lamps and automatons in time together (concurrency, events).
- **Weather records:** the hilltop station's readings, averages and a warning for the harbour (data, lists).
- **The switchboard:** route calls between houses (messages, graphs).
- **The lock keeper:** let boats and carts through safely (state machines).
- **Repair jobs:** an automaton's old routine is broken; read it, find the bug, fix it (debugging, reading code).
- **The baker's oven:** a routine that takes the bread type as a parameter (functions with parameters).
- **Hotaru's dance:** a little routine for the festival (loops, timing). Purely for joy.
- **Seasons:** the same town in autumn, with harvest and longer evenings, which means more lamps.

## Tone and writing

- Warm, everyday and a little funny. Machines do exactly what they are told, and the comedy comes from that literalness, never from humiliation.
- Mistakes are visible and harmless: a machine bumps, stops, puffs and waits. Nothing breaks permanently.
- Residents speak like working people with their own days. They are not tutors in costume.
- The notebook keeps explaining errors in plain words (existing rule). Hotaru adds one short, in-character line.

## Inspiration, not imitation

This concept is inspired by the *feeling* of *Kiki's Delivery Service*: a mid-century European harbour town, big summer light, a young person making a living in a new place. It is equally inspired by the real history of programmable automata and punch-card looms. It must not borrow specific creative elements:

- No witch on a broom, black cat, bakery-loft premise, red bow, dark dress or delivery-girl protagonist.
- No characters, names, places, plot beats or shot compositions from any film.
- Don't put film titles, studio names or film stills into image generators. Describe the qualities instead: era, light, materials, palette. (See the [art direction brief](02-art-direction.md#references).)
