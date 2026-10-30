# Characters and character style — 2026-10-26

**Status: proposal, not implemented.** The cast of the [Sparks & Machines journey](05-scenario.md), how each person and machine looks, and the rules every character picture follows. How they **talk** is in [the dialogue guide](07-dialogue.md#4-voices). The existing journeys keep their current art; everything here is for the new journey. Prompt ids (`C1`, `H1` and so on) refer to [the prompt pack](04-art-prompts.md).

## Character style rules

### People in the world: painted sprites

People are **painted whole-body chibi sprites** on the approved shared template (`pipeline/character-template.json`, `pipeline/CHARACTERS.md`). The template, not the art, decides motion and framing:

| Rule | Value |
|---|---|
| Frame | 384×448 px cells, feet anchored at (192, 420), world height 1.45 m |
| Views | Four screen diagonals: SE, SW, NE, NW. SW mirrors SE and NW mirrors NE, so a design must read correctly when mirrored (no one-sided lettering or badges that must not flip). |
| Motion | An 8-frame walk; an idle on the neutral pose with subtle breathing; front views blink every 6–7 seconds |
| Proportions | A big head of about 1/2.6 of total height; large warm eyes; short sturdy limbs; small hands and feet |
| Rendering | Soft painterly shading with a warm rim light, and a thin warm dark-brown outline (never pure black) |
| Wardrobe | Mid-century working clothes (below). Every person has one **signature colour** that reads at gameplay size. |

A new person or outfit is a **new skin** on the same template. Skins cannot change motion settings. Concept images for sprites (`C1` and the `b` images) are single idle frames used as design references; production sprites go through the character pipeline.

### People in conversation: painted portraits

Conversation portraits match the five existing resident portraits (`assets/portraits/*.png`; recipe in `art/source/portraits/v1/README.md`):

- Waist-up, three-quarter view turned slightly toward the viewer's right, looking warmly at the viewer.
- 1024×1536, **truly transparent background**, about 8% clear margin above and at the sides.
- Detailed anime painting: rich hair strands, shaded irises, confident linework, painterly fabric folds, soft warm daylight.
- A friendly stylised face with generous head proportions. Never photorealistic, never a fashion model. Non-romantic.
- For the existing residents: **same face, hair, skin tone and age; new mid-century clothes.** The identity references are their current portrait and their `art/source/characters/<name>/v1/idle-se.png` sprite.

The apprentice is the player and has no conversation portrait, as today.

### Machines

Automatons follow the [automaton design language](02-art-direction.md#automaton-design-language): rounded enamel bodies, brass fittings, one round spark window as heart and face, a visible routine slot, and readable state. In the world they are 3D models; companions with dialogue also get a painted portrait. **People never look like machines, and machines never look like people.** No automaton has a human face, mouth or nose: only spark-eyes behind glass.

### Wardrobe era

| Belongs | Does not belong |
|---|---|
| Short-sleeved and rolled-sleeve work shirts, knit vests, waistcoats, cardigans | Fantasy tunics cinched with belts, capes, robes, armour |
| Neckerchiefs, flat caps, sun hats, berets, headscarves | Wizard hats, circlets, pointed ears |
| Canvas aprons, overalls, field jackets, pinafores | Hoodies, sneakers, jeans with modern cuts, logos |
| Satchels, tool rolls, pencils behind ears, measuring tapes | Wands, staffs, glowing gems |
| Lace-up boots, sturdy shoes | High-tech gear, goggles worn as fashion |

## The cast

### The apprentice (player)

| | |
|---|---|
| Role | The player. A young apprentice in their first year living alone, renting the loft above Nell's old workshop. The player names them. |
| Keep (approved art) | The approved boy's face, tousled orange-red hair, brown eyes, chibi proportions, rendering style, teal-and-yellow signature. |
| New wardrobe (`C1`) | Teal short-sleeved collared work shirt, sleeves rolled, tucked in; brown trousers with the belt now holding them up; the same yellow neckerchief; the same brown lace-up boots; optional canvas satchel worn across the body. |
| Signature colour | Teal `#2F8C8C` with yellow |
| Personality | Curious, quietly determined, a little stubborn; learns by trying. |
| Story | Independence and craft: earning a place in a new town, and recovering after the festival failure. |

### Hotaru (companion)

Full design in [the robot companion document](03-robot-companion.md). In short: a palm-sized, round, lantern-shaped robot with a teal brimmed cap, a big spark window for a face, rosy enamel cheeks, a tiny rotor and stubby mitten hands. She is curious, literal, cheerful and honest. She has opinions but no plans, and acts only through the player's routines. Prompts `H1`–`H4`.

### Nell, retired automaton-maker and landlady

| | |
|---|---|
| Keep (identity) | Silver-grey hair in a braided bun with loose waves, warm brown skin, brown eyes, round brass spectacles, kind half-smile (`assets/portraits/nell.png`). |
| New wardrobe (`C2`) | A soft teal-green cardigan over a cream blouse and a plum work skirt; a canvas work apron with small brass tools in its pocket (a screwdriver, a tiny spanner); spectacles on a thin chain; a walking stick with a brass ferrule (sprite only). |
| Signature colour | Plum with teal |
| Personality | Warm, wry and patient; proud and a little sad. Speaks in short, practical sentences. |
| Teaches | Functions ("write it down once"), and reading old routines |
| Story | She built Hotaru long ago and is the last person who went down into the Rootworks. She can no longer write routines herself. She has noticed the Rootwell's dial and says little. |
| Sample line | *"Breakfast's on me, then. For a month. I'll regret that."* |

### Mira, surveyor and map-maker

| | |
|---|---|
| Keep (identity) | Short wavy espresso bob, two brass hair clips, warm medium-brown skin, brown eyes, bright friendly face (`assets/portraits/mira.png`). |
| New wardrobe (`C3`) | Plum field jacket with many pockets and sage turned cuffs, cream shirt, ochre neckerchief, map satchel with rolled maps, a measuring tape and a pencil. |
| Signature colour | Plum with ochre |
| Personality | Brisk, curious, precise; delighted by a good shortcut. |
| Teaches | Variables, coordinates and routes |
| Machine | Route maps for the post sorter's rounds |
| Sample line | *"Don't move. You're standing exactly on a corner." · "Of the map."* |

### Rowan, keeper of the sparkworks

| | |
|---|---|
| Keep (identity) | Silver swept-back hair and short beard, warm skin, brown eyes, steady calm look (`assets/portraits/rowan.png`). |
| New wardrobe (`C4`) | Teal waistcoat over a cream collarless shirt with rolled sleeves, rust neckerchief, canvas work trousers, a flat cap, a brass pressure gauge clipped to a breast pocket. |
| Signature colour | Teal with rust |
| Personality | Calm, dependable, dry humour; trusts what he can measure. |
| Teaches | Conditions, state and timing |
| Machine | The sparkworks wheel and sluice gates |
| Sample line | *"Mind the walkway. It's wet. It's always wet."* |

### Bram, carpenter and builder

| | |
|---|---|
| Keep (identity) | Dark curly hair, warm brown skin, brown eyes, cheerful grin (`assets/portraits/bram.png`). |
| New wardrobe (`C5`) | Rust-orange knit vest over a burgundy shirt with rolled sleeves, a leather carpenter's apron, a pencil behind his ear, a folding wooden ruler in the apron pocket. |
| Signature colour | Orange with burgundy |
| Personality | Loud, generous, overpromising ("Done by lunch!"); worries about his fence, which nobody has ever touched. |
| Teaches | Attributes, turning and placing (code that builds) |
| Machine | The yard crane |
| Sample line | *"Four's a kind of three-ish."* |

### Tessa, orchard keeper

| | |
|---|---|
| Keep (identity) | Copper-orange hair in a long side braid, freckles, brown eyes, warm smile (`assets/portraits/tessa.png`). |
| New wardrobe (`C6`) | A wide-brimmed straw sun hat with a sage ribbon (replacing the moss beanie), sage neckerchief, rust-red short work jacket over a cream shirt, olive work trousers, gardening gloves tucked in the belt. |
| Signature colour | Sage with rust |
| Personality | Sunny, chatty, digressive; has named every tree in the orchard after a relative and talks to them. |
| Teaches | Loops over rows (grids) |
| Machine | The gardener automaton |
| Sample line | *"That's Uncle Ferenc. He leans. We don't talk about why."* |

## Automatons

Names are proposals. Each machine has one signature trait so it reads at a glance. Prompts `A1`–`A4`.

| Machine | Name | Size | Look | Personality |
|---|---|---|---|---|
| Lamplighter | Wick | Medium | Tall, narrow cream body on two long-ish legs; a telescoping brass lighting pole; a lantern-shaped head with the spark window | Punctual and fussy; hums the hour |
| Gardener | Trowel | Medium | Low and round like a watering can on short legs; a spout arm; a seed hopper on its back; moss in the seams | Slow, contented |
| Post sorter | Pip | Medium | A boxy red enamel body like a post box, with a pigeonhole chest and a little satchel arm | Brisk and polite |
| Yard crane | Heron | Large | A tall brass-and-teal crane on a rolling base with a long neck boom and a hook | Grand and careful |
| Sparkworks wheel | The Old Wheel | Large, fixed | The water wheel with a brass gearbox and a big spark window in its hub | Silent; communicates by gauge |
| Tender automatons | The Sleepers | Medium | Squat, moss-covered, many-jointed arms for clearing pipes; spark windows dim | Asleep for decades; gentle when woken |
| Clock and bells | Old Tom | Large, fixed | The town hall's clock works, seen through a glass panel | Rings on time, no matter what |

## Future characters (ideas, not designed)

- **The postmistress** who runs the telephone switchboard (messages, routing).
- **The tram conductor** with the timetable (queues, scheduling).
- **The harbour master** and the lighthouse keeper (Act 2).
- **A second apprentice** from the harbour side: a friendly rival who writes routines differently. A way to show that there is more than one right program.
