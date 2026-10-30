# Art prompt pack: Sparks & Machines — 2026-10-26

**For the image-generation agent.** This pack produces the main concept art for the [Sparks & Machines journey](05-scenario.md), in order, into `docs/concept/v0.7/art/`. Read [the world concept](01-world-concept.md), [the art direction brief](02-art-direction.md), [Hotaru](03-robot-companion.md) and [the characters](06-characters.md) first. Every image here is a **concept reference**, not a runtime asset. Adopting art into the game is a later, separate step through the project's pipelines.

## Ground rules

1. **Do not change the game.** Write only under `docs/concept/v0.7/art/`. Never edit or overwrite anything in `assets/`, `art/`, `content/`, `pipeline/`, the code folders or the earlier `docs/concept/` folders.
2. **Work phase by phase, in order.** Stop at the end of each phase so the user can review it. An approved image becomes an input for later prompts (for example, the approved `H1` is the design reference for every later Hotaru picture).
3. **For each prompt:** attach the listed inputs in the listed order. Begin the prompt with the shared blocks it names, in that order, then add its own text. Make 2–4 variants, choose the one that passes its **Check** list, and save it at the listed path. Keep up to two runners-up as `<name>.alt1.png` and `<name>.alt2.png`.
4. **Record every saved image** in `docs/concept/v0.7/art/prompts.json` (format in [art/README.md](art/README.md)): its id, file, the exact final prompt text, inputs, tool, date and which variant was chosen.
5. **Never name a film, studio or artist** in a prompt, and never use film stills as inputs. Describe qualities instead. The inputs listed here are this project's own images.
6. **Canvas sizes:** landscape 1536×1024, portrait 1024×1536 and square 1024×1024. Use transparency only where a prompt asks for it.

## Shared blocks

Copy these word for word where a prompt names them.

**STYLE-WORLD**
```text
Art direction: a cozy, sunlit edge-of-town in an invented, gentle mid-century European hillside harbour town that never quite existed: plaster houses in cream, ochre, salmon and pale blue; terracotta and green-copper roofs; wooden poles carrying wires from house to house; bicycles, a little tram, posted letters, chimney smoke and laundry lines. Slightly fantastical in one way only: friendly enamel-and-brass automatons work everywhere, each with a small warm amber "spark" glowing behind one round glass window. Rendering: painterly hand-painted textures over chunky, modular, voxel-inspired 3D forms with softened bevelled edges and a fine warm-brown outline; big warm light; soft cool blue-violet shadows, never black; gentle haze. Large surfaces stay calm and soft; saturation lives in small places (doors, awnings, enamel, sparks). The world feels alive through smoke, wind, birds and working machines, not clutter.
```

**PALETTE**
```text
Palette: plaster cream #F2E6CF, ochre #E2B866, salmon #E8A487, pale blue #A9C8D8; roofs terracotta #C4613F and deep terracotta #9A4632 with verdigris copper #6FAE9B (slate violet #7D6AA8 only as a rare accent); timber #8A5A3B; cobbles and footings #C9BBA3; meadow grass #8DBA5A; foliage #4E8A3E and #2F5E3A; water #3E8E9A; machine enamel cream #EFE3C6, teal #2F8C8C, red #C8453A; brass #C99A3E; spark amber #FFC861 with a #FFF1C2 core; shadow tint #4A5A80. Spark amber appears only in sparks, lamps and lit windows.
```

**CAMERA-GAME**
```text
Camera: the game's fixed orthographic camera, exactly like Input 1's screenshot: looking down about 31 degrees from horizontal along a 45-degree diagonal, with no perspective convergence (vertical edges stay parallel). One grid cell is about one metre. The world is a tidy diorama of walkable lanes (lighter than the grass), buildings with doors facing the lanes, and clear open ground. Beyond the map edge, a soft sky-blue haze by day (not a dark void).
```

**HOTARU**
```text
Hotaru is a palm-sized, very cute lantern-shaped robot, about the size of a child's head. She is squat and round, about as wide as she is tall, like a plump teakettle or an egg, in warm cream enamel #EFE3C6 with two teal bands #2F8C8C. Her big teal dome cap with a soft rounded brim takes about 40% of her height, like an oversized hat. Her face is one big round glass "spark window", about 60% of her body's width, in a thick soft brass rim #C99A3E, set a little below the middle. Inside the glass glows a warm amber light #FFC861, and the light forms two large glowing oval eyes, set slightly wide apart, each with a tiny bright highlight. There is no mouth, nose or human face. Two small rosy enamel dots #E8A487 sit beside the window like painted blush. On top of the cap: a small folding rotor with two rounded, slightly curled brass paddle blades and a big red bobble knob #C8453A. A narrow tape slot under the window has a short curl of cream paper tape peeking out. She has tiny stubby arms with round teal mitten hands, and on her back a small brass name plate with two rivets. When floating, her legs are folded away. When working on the ground, two tiny round brass legs with cream button boots show. Soft enamel, not glossy plastic; every edge rounded; no sharp corners, exposed gears, rust or grime. Friendly, curious and gentle.
```

**CHAR-SPRITE** (an edit of an existing sprite)
```text
Asset type: one game-sprite design reference, transparent PNG 1024x1024. Edit Input 1, a painted chibi game sprite. Keep exactly its pose, view, proportions, face, hair, skin tone, outline weight, painterly shading, warm rim light, and its size and position on the canvas. Change only the clothes and accessories as described below. Clothes must read at very small size: big simple shapes, one signature colour, no tiny patterns or lettering, and the design must still look right when mirrored. Truly transparent background, no ground shadow, no text.
```

**CHAR-PORTRAIT** (a conversation portrait)
```text
Use case: illustration-story. Asset type: production 2D character portrait PNG for a cozy anime visual novel, with a genuinely transparent alpha background. Paint a newly illustrated, high-definition waist-up portrait of ONE person, not an enlarged game sprite: rich detailed hair strands, expressive shaded irises, clean confident linework, subtle painterly fabric folds, soft warm daylight, cozy hand-painted anime finish, consistent with the portrait style reference. A friendly stylised face with generous head proportions; not photorealistic, not a fashion model; a non-romantic village conversation. Framing: portrait canvas 1024x1536; complete head, hair and both shoulders, down to the waist; about 8% clear transparent margin above and at both sides, no clipped hair or elbows; three-quarter front view turned slightly toward the viewer's right, looking warmly at the viewer; arms resting naturally. The background must be truly transparent, including the corners and around the hair: no painted backdrop, gradient, cast shadow or checkerboard. No frame, lettering, UI, watermark or extra people.
```

**AVOID**
```text
Avoid: fairies, wings, pointed ears, runes, sigils, crystals, magic circles, purple or neon glows, swirling sparkles; steampunk goggles, decorative gears, brown-and-brass-everything; rust and grime; screens, computers, phones, plastic, neon signs, modern cars (a rare small round delivery van is fine); weapons or menacing machines; human faces, mouths or noses on machines; photorealism; watermarks, signatures and lettering unless asked for.
```

## Reference images (this project's own)

| Key | File | Use |
|---|---|---|
| R1 | `evidence/rootward-square/rootward-overview.png` | The game's camera, scale and voxel-inspired look today |
| R2 | `reference/voxel-isometric.png` | The original approved concept for the voxel-isometric look |
| R3 | `evidence/rootward-square/town-hall.png` | The town hall to keep (cream half-timbering, blue roof, clock tower) |
| R4 | `evidence/rootward-square/bedroom.png` | The interior cutaway camera |
| R5 | `art/source/adventurer/v9-directional-walk/idle-se.png` | The approved boy (the apprentice), front-facing idle |
| R6 | `art/source/adventurer/v9-directional-walk/NE.png` | The approved boy from behind (use its top-left frame) |
| R7 | `art/source/companions/hotaru/v3/concept/turnaround-sheet.png` | Hotaru's first study: parts and layout, to be made cuter |
| R8 | `art/source/companions/hotaru/v3/concept/expression-sheet.png` | Hotaru's first study: the six spark-eye expressions |
| R9 | `assets/portraits/mira.png` | Conversation portrait style |
| R10 | `assets/portraits/<name>.png` | Each resident's face and identity |
| R11 | `art/source/characters/<name>/v1/idle-se.png` | Each resident's sprite |
| R12 | `evidence/village-dialogue/nell-greeting.png` | How a portrait sits in the game's dialogue scene |

## Order of work

| Phase | Ids | Why first | Needed for |
|---|---|---|---|
| 1. Style lock | `T1`, `T6` | Fixes the town's look and light before anything specific | Everything |
| 2. Hotaru | `H1`–`H4` | The heart of the journey; the cuter design | Slice 1 |
| 3. Apprentice and Nell | `C1`, `C2` | The two people in the opening | Slice 1 |
| 4. Opening places | `T7a`, `T7b`, `T7c`, `P3`, `P1` | The loft, the workshop and the lane | Slice 1 |
| 5. The town | `T3`, `T4`, `T5`, `T2`, `P2` | The square, the Rootwell and the outskirts | Slices 2–3 |
| 6. Automatons | `A1`–`A4` | The machine family | Slices 2–3 |
| 7. The rest of the cast | `C3`–`C7` | Mira, Rowan, Bram, Tessa and the lineup | Slices 2–3 |
| 8. Interface | `U1`, `U2` | Paper and enamel; the journey card | Slice 1 polish |
| 9. Future places | `F1`–`F3` | The harbour, the Rootworks and the festival | Later acts |

---

## Phase 1 — Style lock

### T1 · Haverlund key art
- **Output:** `art/1-style/T1-haverlund-key-art.png`, 1536×1024, opaque
- **Inputs:** 1 = R2, 2 = R1
- **Blocks:** STYLE-WORLD, PALETTE, AVOID

```text
Asset type: one wide establishing key illustration for the game's new setting (not the game camera). Use Input 1 and Input 2 only for the chunky voxel-inspired building forms, warm materials and painted finish, so the town clearly belongs to the same game.
Scene: late golden afternoon, seen from the wooded hill road above the town, looking down toward the sea. Foreground left: the old two-storey workshop (timber and cream plaster, terracotta roof, a dormer loft window, big green double shop doors, a hanging sign with a simple spark-and-cog icon), a low stone wall and a lamp on a wooden post. Wooden poles carry wires from the workshop down the hill, house to house. A small cream-and-teal tram climbs the hill line. Middle: a little square with a low round stone-and-brass wellhead whose glass dome glows softly (the Rootwell), beside a cream half-timbered town hall with a blue roof and a clock tower; terracotta roofs and copper spires cascade down the slope. Background: the harbour with two cranes, a lighthouse on the point, boats and a calm teal sea; one small airship far off in the sky. Chimney smoke leans with the breeze; gulls; laundry between houses. Two or three tiny friendly automatons at work on the street. No people in close-up.
Composition: generous sky with soft cumulus clouds; strong readable roof shapes; a warm path of light leading the eye from the workshop to the harbour.
```
**Check:** the place feels lived-in, sunny and gentle; it looks like the same game as R1 and R2; no fantasy-castle or steampunk feel; the Rootwell is low and does not dominate the skyline.

### T6 · Lighting key
- **Output:** `art/1-style/T6-lighting-key.png`, 1536×1024, opaque
- **Inputs:** 1 = R1, 2 = the approved T1
- **Blocks:** STYLE-WORLD, PALETTE, CAMERA-GAME, AVOID

```text
Asset type: a lighting and colour key. Six equal panels in a 3x2 grid (three on top, three below). The first five panels show the SAME small cobbled lane at the game camera of Input 1: two plaster cottages with terracotta roofs, a wooden pole with wires, one lamp on a post, a bench, a tree and a patch of grass. Panel order: morning (pale gold low light, long cool shadows, gentle haze, lamp off); afternoon (warm white high light, short soft blue-tinted shadows, lamp off); golden hour (deep amber low light, long violet-blue shadows, the first windows glowing); dusk (rose-to-violet sky bounce, blue world, the lamp and windows leading the image); night (cool moonlight, deep navy, warm lamps and windows). The sixth panel holds plain colour swatch blocks of the palette, with no text.
```
**Check:** the five panels show identical geometry; shadows are never black; amber appears only in lamps and windows; the lane stays lighter than the grass in every panel.

---

## Phase 2 — Hotaru

### H1 · Hotaru turnaround (cuter)
- **Output:** `art/2-hotaru/H1-turnaround.png`, 1536×1024, plain warm paper background `#F6F0E2`
- **Inputs:** 1 = R7, 2 = R8, 3 = R5
- **Blocks:** HOTARU, AVOID

```text
Asset type: a clean character model sheet for a 3D modeller. Redesign the robot in Input 1 to be noticeably CUTER, following the HOTARU description exactly: rounder and squatter, a bigger brimmed cap, a much bigger window face with big glowing oval eyes and tiny highlights, rosy cheek dots, a smaller rotor with rounded curled paddles, a big red bobble, tiny mitten hands, and a curl of paper tape from the slot. Keep Input 1's parts and colours; Input 2 shows how the eyes live inside the glass.
Layout on a plain warm paper background: top row, FLOATING mode (legs folded, rotor up): front, front three-quarter, side, back three-quarter, back. Bottom row, WORKING mode (tiny brass legs with cream button boots out, standing): the same five views. All ten views at the same size, orthographic, the same neutral happy eyes, consistent in every detail. At the right edge, a small scale inset: the boy from Input 3 standing, with Hotaru floating beside his shoulder at the size of his head. Soft even studio light; a painted 3D-toy finish with a fine warm-brown outline. No text.
```
**Check:** clearly cuter than R7 (rounder, bigger face and eyes, softer); the same design in all ten views; no mouth or human features; the colours match the hex values; the scale inset shows her about head-sized.

### H2 · Spark-eye expressions
- **Output:** `art/2-hotaru/H2-expressions.png`, 1536×1024, paper background `#F6F0E2`
- **Inputs:** 1 = approved H1, 2 = R8
- **Blocks:** HOTARU, AVOID

```text
Asset type: an expression sheet. Six panels in a 3x2 grid, each showing Hotaru from Input 1 floating in the same front three-quarter view, waist-up framing of her whole small body, identical design and lighting. Only the light in her window and a small body pose change. In reading order: 1 OFF, dark amber glass with no light and no eyes, slightly slumped, rotor still; 2 NEUTRAL, two soft glowing oval eyes with tiny highlights; 3 HAPPY, two upward curved closed-eye arcs, body tilted a little, one mitten hand raised in a wave; 4 THINKING, one eye a narrow flat oval, the other normal, body tilted, a hand near the window; 5 SURPRISED, two wide glowing rings, rotor blades flicked up; 6 STOPPED, small eyes low in the window, the glow turned orange, a tiny puff of steam from the tape slot, a slight shudder pose. No text or labels.
```
**Check:** the expression reads from the eyes alone; the design is identical across panels; Off really has no light.

### H3 · Hotaru dialogue portrait
- **Output:** `art/2-hotaru/H3-portrait.png`, 1024×1536, **transparent**
- **Inputs:** 1 = approved H1, 2 = R9, 3 = R12
- **Blocks:** HOTARU, AVOID

```text
Use case: illustration-story. Asset type: production 2D companion portrait PNG for a cozy anime visual novel, with a genuinely transparent alpha background. Paint Hotaru from Input 1 as a newly illustrated high-definition painting in the same rendering style as the portrait in Input 2: confident linework, soft warm daylight, painterly enamel and brass with gentle reflections, cozy hand-painted anime finish. Input 3 shows where the portrait sits in the game's dialogue scene, at the lower left above a wide dialogue box. Framing: her whole small body, floating, three-quarter view turned slightly toward the viewer's right, filling the lower two-thirds of the canvas, with about 8% clear margin at the top and sides. NEUTRAL eyes with tiny highlights, one mitten hand raised in a small hello, rotor slightly blurred as if spinning, the warm window glow lighting her cheeks. The background must be truly transparent, including the corners: no backdrop, gradient, shadow or checkerboard. No text.
```
**Check:** sits well beside the residents' portraits (R9); transparent edges are clean; she is cute and readable at half size.

### H4 · Hotaru in the world, at game scale
- **Output:** `art/2-hotaru/H4-in-world.png`, 1536×1024, opaque
- **Inputs:** 1 = R1, 2 = approved H1, 3 = R5
- **Blocks:** STYLE-WORLD, PALETTE, CAMERA-GAME, AVOID

```text
Asset type: an in-game readability mockup at the real game zoom of Input 1. A small cobbled lane between two cottages in morning light. The boy from Input 3 stands on the lane; Hotaru from Input 2 floats beside his shoulder at the height of his head, her window glowing softly and her rotor a blur. Keep both exactly at the small on-screen size of the player in Input 1 (the boy is about one twenty-fifth of the frame height). Add a small inset in the bottom-right corner showing the same two characters magnified three times, for reference.
```
**Check:** at true size, Hotaru reads as a little teal-capped lantern with a warm window, and is not lost or confused with a lamp.

---

## Phase 3 — The apprentice and Nell

### C1 · The apprentice, mid-century work clothes
- **Outputs:** `art/3-cast/C1-apprentice-se.png` and `art/3-cast/C1-apprentice-ne.png`, 1024×1024, **transparent**
- **Inputs:** first image: 1 = R5. Second image: 1 = the top-left frame of R6, 2 = the approved front image.
- **Blocks:** CHAR-SPRITE, AVOID

```text
Clothes for the apprentice (the boy in Input 1): replace the fantasy tunic cinched by a belt with a teal (#2F8C8C) short-sleeved collared work shirt, sleeves rolled once, tucked into the same brown trousers; the brown belt now sits at the trouser waist with a small brass buckle; keep the same yellow neckerchief tied at the collar and the same brown lace-up boots; add a small canvas satchel worn across the body on a thin strap, sitting at the hip. Same face, same tousled orange-red hair, same chibi proportions and painted finish.
```
For the back view, add: `Show the same new outfit from behind, matching Input 2 exactly; the satchel strap crosses the back.`

**Check:** unmistakably the same boy as the approved sprite; the outfit reads as mid-century and not fantasy; it still looks right mirrored; there is no lettering.

### C2 · Nell
- **C2a portrait output:** `art/3-cast/C2a-nell-portrait.png`, 1024×1536, **transparent**. Inputs: 1 = `assets/portraits/nell.png` (identity), 2 = R9 (style), 3 = `art/source/characters/nell/v1/idle-se.png` (identity). Blocks: CHAR-PORTRAIT, AVOID.

```text
Subject: Nell, the town's retired automaton-maker and the apprentice's landlady. Keep exactly her face from Input 1: silver-grey hair in a braided bun with loose waves at the temples, warm brown skin, brown eyes, round brass spectacles, a kind wry half-smile. New mid-century clothes: a soft teal-green knitted cardigan over a cream blouse with a small collar, a plum work skirt, and a canvas work apron with a small brass screwdriver and a tiny spanner in its chest pocket; her spectacles hang on a thin chain. Warm, patient, a little proud.
```
- **C2b sprite output:** `art/3-cast/C2b-nell-sprite.png`, 1024×1024, **transparent**. Inputs: 1 = `art/source/characters/nell/v1/idle-se.png`. Blocks: CHAR-SPRITE, AVOID.

```text
Clothes for Nell: the same teal-green cardigan over a cream blouse, plum skirt, canvas work apron with brass tools in the pocket, spectacles on a chain, and a short wooden walking stick with a brass tip held in one hand.
```
**Check:** her face is unchanged; the outfit says "maker" and is warm, not fantasy; the portrait matches R9's finish.

---

## Phase 4 — Opening places

### T7a · The workshop loft (first morning)
- **Output:** `art/4-opening/T7a-workshop-loft.png`, 1536×1024, opaque
- **Inputs:** 1 = R4, 2 = approved H1, 3 = approved C1 front
- **Blocks:** STYLE-WORLD, PALETTE, AVOID

```text
Asset type: an in-game interior concept at the same cutaway camera as Input 1 (two back walls, the floor, no front walls, orthographic, looking down about 31 degrees). A cosy attic loft room above a workshop, about 12 by 10 metres, on the first morning after moving in. Sloping roof beams; a round attic window and a dormer window letting in pale gold morning light with long soft shadows; cream plaster between timber posts; honey-coloured floorboards. A single bed with a teal-and-cream quilt; a writing desk with a small cream-and-brass tape machine (like a little typewriter with a paper-tape spool) whose thin cable runs to a shelf beside the desk; on that shelf sits Hotaru from Input 2, dusty and dark (no light in her window, eyes off); a half-unpacked suitcase; a rag rug; wall pegs with a jacket; a pinned postcard of a harbour; a stair hatch in the floor leading down. The boy from Input 3 stands beside the bed, small, at the game's scale. Warm, quiet, a little dusty, full of promise.
```
**Check:** it reads as the same camera and scale as R4; the tape machine, the cable and dark Hotaru on the shelf are clearly readable; there is a clear walkable floor.

### T7b · The workshop floor
- **Output:** `art/4-opening/T7b-workshop-floor.png`, 1536×1024, opaque
- **Inputs:** 1 = R4, 2 = approved C2a or C2b
- **Blocks:** STYLE-WORLD, PALETTE, AVOID

```text
Asset type: an in-game interior concept at the cutaway camera of Input 1. The ground floor of an old automaton-maker's workshop: two long wooden workbenches with a vice and neatly hung tools; shelves of small drawers; half-built automaton parts resting under a dust sheet (a cream enamel arm, a spare round spark window, unlit); a parts crate; a wide pair of green shop doors at the front, slightly open with afternoon light streaming in and dust motes; a cork job board by the door with one stamped paper ticket pinned to it; a staircase up to the loft; a cosy corner with a worn armchair, a small stove and a teapot. Nell from Input 2 stands by the job board, small, at the game's scale. Orderly but long unused.
```
**Check:** the job board and its single ticket read clearly; the room says "workshop", not "forge" or "alchemy lab".

### T7c · The lane outside the workshop
- **Output:** `art/4-opening/T7c-workshop-lane.png`, 1536×1024, opaque
- **Inputs:** 1 = R1, 2 = approved T1, 3 = approved H4
- **Blocks:** STYLE-WORLD, PALETTE, CAMERA-GAME, AVOID

```text
Asset type: an in-game exterior concept, a small map about 40 by 28 metres, morning light. The workshop from Input 2 (two storeys, timber and cream plaster, terracotta roof, dormer loft window, green double shop doors, a hanging spark-and-cog sign) stands on a cobbled lane. Two neighbouring cottages with terracotta roofs and window boxes. Wooden poles carry wires from the workshop along the lane to a lamp on a post beside a low stone wall and an open gate; the lamp is DARK (unlit). At the map edge, a little tram halt with a bench and a shelter. Beyond the gate, the lane runs down toward the town; far off, the glass dome of the Rootwell glows faintly among terracotta roofs. The boy and Hotaru from Input 3 stand by the workshop doors at true game scale. A few trees, a bench, a post box, laundry on a line, chimney smoke.
```
**Check:** the unlit gate lamp and its wire are easy to find (the first job); the lane is clearly walkable; the distant Rootwell glow is visible but subtle.

### P3 · Workshop props sheet
- **Output:** `art/4-opening/P3-workshop-props.png`, 1536×1024, paper background `#F6F0E2`
- **Inputs:** 1 = R4, 2 = approved T7a, 3 = approved T7b
- **Blocks:** STYLE-WORLD, PALETTE, AVOID

```text
Asset type: a props design sheet for 3D modelling. Each object isolated, shown at the game's three-quarter camera from above (like Input 1), all at consistent scale and lighting, arranged in a tidy grid with space between, matching the objects in Inputs 2 and 3: the tape machine with its paper-tape spool and cable; a workbench with a vice; a shelf of small drawers; the cork job board with three stamped tickets; a crate of glass spark jars (two glowing amber, one dark); Nell's worn armchair; the loft bed with its teal-and-cream quilt; a half-unpacked suitcase; the stair hatch; the green shop doors; a small stove with a teapot. No text labels.
```
**Check:** every prop is readable at small size; chunky voxel-inspired forms with painted detail; consistent light.

### P1 · Street props sheet
- **Output:** `art/4-opening/P1-street-props.png`, 1536×1024, paper background `#F6F0E2`
- **Inputs:** 1 = R1, 2 = approved T7c
- **Blocks:** STYLE-WORLD, PALETTE, AVOID

```text
Asset type: a street props design sheet for 3D modelling, each object isolated at the game's three-quarter camera from above, consistent scale and lighting, in a tidy grid: a wooden pole with crossarm, insulators and wire stubs (tall and short versions); a spark street lamp on a post, shown both unlit and lit (amber spark behind glass panes); the gate lamp on a stone pier; a tram halt shelter with a bench; a red enamel post box; an outdoor job board under a little roof; a park bench; a bicycle leaning on a stand; a laundry line between two posts; a window box with flowers; an enamel street sign with only a simple icon (no letters); a brass pressure gauge on a short post. No text labels.
```
**Check:** the lamp's lit and unlit states are clearly different; poles and wires read as connections; nothing looks like a fantasy prop.

---

## Phase 5 — The town

### T3 · Rootward Square by day
- **Output:** `art/5-town/T3-rootward-square-day.png`, 1536×1024, opaque
- **Inputs:** 1 = R1, 2 = R3, 3 = approved T1
- **Blocks:** STYLE-WORLD, PALETTE, CAMERA-GAME, AVOID

```text
Asset type: an in-game exterior concept of the town's upper square in warm afternoon light. Input 1 shows the current square with a giant tree; REMOVE the tree entirely. In its place, at the centre: the Rootwell, a LOW round wellhead about 3 by 3 metres and lower than the town hall's eaves; a stone base with a broad brass rim wide enough to sit on, and steps on the side facing the main lane. At its centre is a glass dome holding a soft amber spark, with the top of a living tree root curling up inside the glass. An oversized brass pressure dial faces the main lane, its needle sitting low. Four brass valve wheels each face a different lane, and four brass inlay strips run from the base under the cobbles toward each lane. Keep the town hall from Input 2 (cream half-timbering, blue roof, clock tower) on one side. Terracotta-roofed houses, benches ringing the Rootwell, spark street lamps, wooden poles with wires, a tram line along one edge, a few townspeople and one cream lamplighter automaton walking its route.
```
**Check:** the Rootwell is low, central and readable, with the dial and inlay lines visible; the square is open and walkable; no magic circle or glowing runes.

### T4 · Rootward Square at dusk
- **Output:** `art/5-town/T4-rootward-square-dusk.png`, 1536×1024, opaque
- **Inputs:** 1 = approved T3, 2 = approved T6
- **Blocks:** STYLE-WORLD, PALETTE, CAMERA-GAME, AVOID

```text
The exact scene of Input 1 at dusk, lit like the dusk panel of Input 2. The lamps along three lanes are lit and their brass inlay strips have a faint warm sheen; the fourth lane's lamps and strip stay dim (a quiet story clue, not alarming). The Rootwell's dome glows softly; the windows are warm; the lamplighter automaton is lighting the last lamp with its long pole.
```
**Check:** identical geometry to T3; the one dim branch is noticeable but subtle.

### T5 · The Rootwell design sheet
- **Output:** `art/5-town/T5-rootwell-sheet.png`, 1536×1024, paper background `#F6F0E2`
- **Inputs:** 1 = approved T3
- **Blocks:** STYLE-WORLD, PALETTE, AVOID

```text
Asset type: an object design sheet for 3D modelling of the Rootwell from Input 1. A large three-quarter view from above; a front elevation; a top-down plan showing the four valve wheels and four inlay strips leaving the base; and three detail callouts: the oversized brass dial with its needle low; one valve wheel; and the glass dome with a living root curling inside, warm amber light moving slowly within the root. Stone base, broad brass rim, steps on one side. Clean, consistent lighting. No text labels.
```
**Check:** buildable from the sheet; the dial reads as half a metre across; the root inside the dome is gentle and natural, not creepy.

### T2 · The outskirts at golden hour
- **Output:** `art/5-town/T2-outskirts-golden-hour.png`, 1536×1024, opaque
- **Inputs:** 1 = R1, 2 = R2, 3 = approved T6
- **Blocks:** STYLE-WORLD, PALETTE, CAMERA-GAME, AVOID

```text
Asset type: a wide in-game exterior concept of the town's wooded outskirts (Kindle Hollow) at golden hour, lit like the golden-hour panel of Input 3. A brook crossing the map with a short timber bridge. The sparkworks: an old water mill with a turning wheel, plus a small glass-roofed annex whose shelves hold rows of glowing amber spark jars. Cottages with terracotta roofs and window boxes; an orchard in neat rows and allotments; wooden poles carrying wires between houses; a lamplighter automaton walking a route around a small green lighting four lamps; a tram halt at the edge; the roofs of the town beyond the trees. The map edge fades into soft sky haze.
```
**Check:** the sparkworks reads as "mill plus spark jars"; the lamplighter's route is easy to follow; the scene feels like evening work, not fantasy.

### P2 · Outskirts buildings sheet
- **Output:** `art/5-town/P2-outskirts-buildings.png`, 1536×1024, paper background `#F6F0E2`
- **Inputs:** 1 = R2, 2 = approved T7c, 3 = approved T2
- **Blocks:** STYLE-WORLD, PALETTE, AVOID

```text
Asset type: a building design sheet for 3D modelling, each building isolated at the game's three-quarter camera from above, consistent scale: the apprentice's workshop (from Input 2); the sparkworks mill with its glass spark-jar annex (from Input 3); a plaster cottage with a terracotta roof; a small corner shop with a striped awning and a hanging icon sign; a pump house; the tram halt. Big readable roofs; doors facing the viewer's lower right; chimneys. No text labels.
```
**Check:** every roof reads as terracotta or copper; the doors are obvious; the shapes are chunky and buildable.

---

## Phase 6 — Automatons

### A1 · The automaton family
- **Output:** `art/6-automatons/A1-family.png`, 1536×1024, paper background `#F6F0E2`
- **Inputs:** 1 = approved H1, 2 = approved C1 front
- **Blocks:** STYLE-WORLD, PALETTE, AVOID

```text
Asset type: a family lineup sheet of friendly automatons that clearly share one design language with Hotaru (Input 1): rounded enamel bodies in cream, teal or red; brass rims and rivets; one round glass spark window each, with glowing oval eyes; a visible card slot for routines; cared for, not rusty. Left to right, smallest to largest, standing on a common baseline at the same scale: Hotaru (floating); Pip the post sorter (a boxy red enamel body like a post box, with a pigeonhole chest and a little satchel arm); Trowel the gardener (low and round like a watering can on short legs, a spout arm, a seed hopper on its back, a little moss in its seams); Wick the lamplighter (a tall, narrow cream body on two legs, a telescoping brass lighting pole, a lantern-shaped head with the spark window); a Sleeper tender (squat, moss-covered, folded many-jointed arms, a dim window); and Heron the yard crane (a tall teal-and-brass crane on a rolling base with a long boom and hook). A small silhouette of the boy from Input 2 stands at the end for scale. No text.
```
**Check:** they read as one family; each has one signature shape; none looks human or menacing.

### A2 · Wick the lamplighter
- **Output:** `art/6-automatons/A2-lamplighter.png`, 1536×1024, paper background `#F6F0E2`
- **Inputs:** 1 = approved A1
- **Blocks:** STYLE-WORLD, PALETTE, AVOID

```text
Asset type: a character sheet for Wick the lamplighter from Input 1: front, three-quarter, side and back views; an action pose raising its telescoping pole to light a street lamp; and two small window close-ups, idle (a soft amber pulse) and running (bright steady). Punctual and fussy in posture. No text.
```

### A3 · Heron the yard crane
- **Output:** `art/6-automatons/A3-yard-crane.png`, 1536×1024, paper background `#F6F0E2`
- **Inputs:** 1 = approved A1, 2 = approved C1 front
- **Blocks:** STYLE-WORLD, PALETTE, AVOID

```text
Asset type: a design sheet for Heron the yard crane from Input 1: a three-quarter view lifting a timber bridge deck, a side view with the boom folded, and a small view turning a cottage on a wide turntable base. The boy from Input 2 stands beside it for scale. Grand, careful and friendly. No text.
```

### A4 · The Sleepers
- **Output:** `art/6-automatons/A4-sleeper.png`, 1536×1024, opaque
- **Inputs:** 1 = approved A1
- **Blocks:** STYLE-WORLD, PALETTE, AVOID

```text
Asset type: a mood concept. Left: a Sleeper tender automaton from Input 1 curled asleep in a brick niche underground, covered in soft moss, its window a faint ember, a living root curving past it with slow amber light inside. Right: the same Sleeper just woken, stretching its many-jointed arms, its window brightening, moss falling away. Gentle, cozy and a little mysterious; not scary.
```

---

## Phase 7 — The rest of the cast

For each resident, make a **portrait (a)** and a **sprite (b)**, using the wardrobe in [the characters document](06-characters.md).

| Id | Person | Portrait inputs (a) | Sprite input (b) | Clothes text to add after the blocks |
|---|---|---|---|---|
| `C3` | Mira | 1 = `assets/portraits/mira.png`, 2 = R9, 3 = `art/source/characters/mira/v1/idle-se.png` | `art/source/characters/mira/v1/idle-se.png` | `Subject: Mira, the town's surveyor and map-maker. Keep exactly her face and hair from Input 1: a short wavy espresso bob, two brass hair clips, warm medium-brown skin, brown eyes. New clothes: a plum field jacket with many pockets and sage turned cuffs, a cream shirt, an ochre neckerchief, a map satchel with rolled maps, a measuring tape and a pencil. Brisk and curious.` |
| `C4` | Rowan | 1 = `assets/portraits/rowan.png`, 2 = R9, 3 = `art/source/characters/rowan/v1/idle-se.png` | `art/source/characters/rowan/v1/idle-se.png` | `Subject: Rowan, keeper of the sparkworks. Keep exactly his face and hair from Input 1: silver swept-back hair and short beard, warm skin, brown eyes. New clothes: a teal waistcoat over a cream collarless shirt with rolled sleeves, a rust neckerchief, canvas work trousers, a flat cap, and a small brass pressure gauge clipped to his breast pocket. Calm and dependable.` |
| `C5` | Bram | 1 = `assets/portraits/bram.png`, 2 = R9, 3 = `art/source/characters/bram/v1/idle-se.png` | `art/source/characters/bram/v1/idle-se.png` | `Subject: Bram, the town's carpenter and builder. Keep exactly his face and hair from Input 1: dark curly hair, warm brown skin, brown eyes, a cheerful grin. New clothes: a rust-orange knit vest over a burgundy shirt with rolled sleeves, a leather carpenter's apron, a pencil behind his ear, a folding wooden ruler in the apron pocket. Energetic and generous.` |
| `C6` | Tessa | 1 = `assets/portraits/tessa.png`, 2 = R9, 3 = `art/source/characters/tessa/v1/idle-se.png` | `art/source/characters/tessa/v1/idle-se.png` | `Subject: Tessa, the orchard keeper. Keep exactly her face and hair from Input 1: copper-orange hair in a long side braid, freckles, brown eyes, a warm smile. New clothes: a wide-brimmed straw sun hat with a sage ribbon (replacing the knit beanie), a sage neckerchief, a rust-red short work jacket over a cream shirt, olive work trousers, gardening gloves tucked into her belt. Sunny and patient.` |

- **Portrait outputs:** `art/7-cast/C<n>a-<name>-portrait.png`, 1024×1536, transparent. Blocks: CHAR-PORTRAIT, AVOID, then the clothes text.
- **Sprite outputs:** `art/7-cast/C<n>b-<name>-sprite.png`, 1024×1024, transparent. Blocks: CHAR-SPRITE, AVOID, then the clothes text without the "Keep exactly…" sentence.
- **Check:** the faces are unchanged; each signature colour reads; nobody wears fantasy costume.

### C7 · Cast lineup
- **Output:** `art/7-cast/C7-cast-lineup.png`, 1536×1024, paper background `#F6F0E2`
- **Inputs:** the approved `C1`, `C2b`, `C3b`, `C4b`, `C5b` and `C6b` sprites, plus the approved `H1`
- **Blocks:** AVOID

```text
Asset type: a consistency lineup. The six sprites from the inputs standing side by side on one baseline at exactly the same scale and lighting, in the same south-east three-quarter view, with Hotaru floating beside the apprentice at head height. Keep every character exactly as given. Plain warm paper background, soft contact shadows only. No text.
```
**Check:** they look like one cast in one era; Hotaru is clearly not a person.

---

## Phase 8 — Interface

### U1 · Paper-and-enamel interface sheet
- **Output:** `art/8-interface/U1-ui-sheet.png`, 1536×1024, opaque
- **Inputs:** 1 = R12, 2 = `evidence/rootward-square/bedroom.png` (the current interface)
- **Blocks:** PALETTE, AVOID (lettering allowed as noted)

```text
Asset type: a flat 2D game-interface style sheet that restyles the current interface in Inputs 1 and 2 from dark navy and gold into warm "paper and enamel", like mid-century tickets, labels and enamel signs. Show, neatly arranged: (1) a job board panel with three stamped paper job tickets (small icon, short title line, a red rubber stamp mark); (2) the objective tracker as a single pinned ticket; (3) the Field Notes notebook frame on cream graph paper, with its code area kept HIGH-CONTRAST, dark monospace code on a pale background with a few placeholder lines starting "def program(world):"; (4) a strip of ticker tape showing printed output "Hello, Hotaru!"; (5) rounded enamel-sign buttons in teal, cream and red, each in default, hover, pressed and disabled states, with short labels such as "Test", "Speak", "Apply"; (6) small enamel badges: "!", "?", a speech bubble with three dots, and a hand "use" icon; (7) the bottom dialogue box with a nameplate tab and room for a portrait on the left. Calm, legible, friendly; the code must stay perfectly readable.
```
**Check:** the code area is plainly readable; the buttons have clear states; nothing is dark navy with gold.

### U2 · Journey card
- **Output:** `art/8-interface/U2-journey-card.png`, 1536×1024, opaque
- **Inputs:** 1 = approved T1, 2 = approved H1
- **Blocks:** STYLE-WORLD, PALETTE, AVOID

```text
Asset type: a painterly card illustration for the level-select screen. The old workshop on the hill at golden hour, its loft window lit; on the window sill, a tiny Hotaru from Input 2 with her spark glowing; wires running down the hill to the town and harbour below; soft clouds. Keep the left third of the image calm and simple (sky and hill) so a title can be placed there later. No text.
```

---

## Phase 9 — Future places

### F1 · A harbour street
- **Output:** `art/9-future/F1-harbour-street.png`, 1536×1024, opaque. Inputs: 1 = R1, 2 = approved T1. Blocks: STYLE-WORLD, PALETTE, CAMERA-GAME, AVOID.

```text
Asset type: an in-game exterior concept of a steep stepped lane in the harbour town on a bright afternoon: tall, narrow plaster townhouses in ochre, salmon, cream and pale blue with terracotta roofs and green-copper spires; stairs and landings (several terrain levels); market stalls under striped awnings; the little tram on its line; the post sorter automaton on its round; the harbour cranes and lighthouse beyond; gulls; laundry between windows.
```

### F2 · A Rootworks chamber
- **Output:** `art/9-future/F2-rootworks-chamber.png`, 1536×1024, opaque. Inputs: 1 = R4, 2 = approved A4, 3 = approved H1. Blocks: STYLE-WORLD, PALETTE, AVOID.

```text
Asset type: an in-game interior concept at the cutaway camera of Input 1, underground. Brick and stone vaults built around huge living tree roots that thread through the masonry, with warm amber light moving slowly inside them. Iron pipes and cables follow the roots. A relay chamber has two big brass valve wheels and a panel of switches and gauges. A Sleeper tender from Input 2 dozes in a niche; spark lamps hang on the pipes. The apprentice and Hotaru (Input 3) explore with her window lighting their way. Mysterious, quiet and cozy, never scary.
```

### F3 · Festival night
- **Output:** `art/9-future/F3-festival-night.png`, 1536×1024, opaque. Inputs: 1 = approved T3, 2 = approved A1. Blocks: STYLE-WORLD, PALETTE, CAMERA-GAME, AVOID.

```text
Asset type: the square from Input 1 at night during the lantern festival: strings of spark lamps crossing between houses, the automatons from Input 2 working together (lamplighters on ladders, the yard crane hanging a garland, the post sorter handing out paper lanterns), townspeople with lanterns, the Rootwell glowing at the centre, and a small airship with warm lights passing overhead. Joyful and warm.
```

---

## After the art

When a phase is approved, the user decides which images become production art. Adopting one follows the project's pipelines, not this pack: characters through `pipeline/CHARACTERS.md` and the shared skin template, portraits through `art/source/portraits/` and `scripts/art.sh`, and 3D objects through `pipeline/WORLD_ASSETS.md`. All of it happens inside the new journey ([scenario](05-scenario.md)), never by editing the existing journeys.
