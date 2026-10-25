# Village dialogue concepts — v1

Three alternative visual novel conversation layouts, generated with the built-in `image_gen.imagegen` tool for user selection. These are illustrative mockups rather than gameplay captures. No layout is selected or connected to the runtime conversation screen.

| Concept | Mockup | Direction |
|---|---|---|
| A — Classic portrait stage | [Open A](a-classic-portrait-stage.png) | One large Mira portrait, a bottom dialogue box, and responses over the village. Closest to a familiar anime visual novel. |
| B — Cinematic two-speaker | [Open B](b-cinematic-two-speaker.png) | Mira and the boy have detailed portraits facing into a conversation stage, with a quiet subtitle band and central choices. |
| C — Storybook side panel | [Open C](c-storybook-side-panel.png) | A parchment page groups portrait, dialogue and choices on the right, leaving more of the village visible. |

All three show the same sample conversation and the controls Next / Click / Space, History, Auto, Skip, Hide UI, Settings and Leave. The choices and controls illustrate proposed behavior; this task does not implement them. In-game avatars and painted walk/idle sources remain separate from these proposed high-definition dialogue portraits.

The same Mira identity anchors all three comparisons: wavy espresso bob, brass clips, warm brown eyes/skin, plum coat, ochre scarf and sage cuffs. B also illustrates a detailed portrait of the existing boy. The village background is a generated interpretation of the supplied art references, not a promise to replace the game's camera or environment. After selection, the chosen conversation layout can be shared by Mira, Rowan, Bram, Tessa, Nell and any future residents, with individually authored portrait artwork and expressions.

[Exact prompt set](prompts.json) · [Generation record and image/reference hashes](generation.json)

Individual prompts: [A](a-classic-portrait-stage.txt), [B](b-cinematic-two-speaker.txt), [C](c-storybook-side-panel.txt). Generation used the four local reference images listed in the record; original outputs were copied here without altering their pixels. Model identifier and seed were not exposed. Originals remain at the tool's generated-image paths.

These concepts stay under import-excluded `art/source/`; none is added to the active art catalog or `assets/`. Selecting a layout and preparing runtime portraits is the next decision.
