# Village visual novel conversations — 2026-10-24

Implemented the user's classic single-speaker direction for all five villagers. Each has a new high-definition painted portrait, a wide dialogue box, response topics and optional code explanations. The smaller portrait scale is retained; the user's follow-up correction raises portraits **125 px at the standard 1600×1000 view**, proportionally at other sizes, with more lift at enlarged UI settings when needed to keep shoulders visible. The nameplate sits clear of the face.

See [the conversation guide](../DIALOGUE.md) for controls, content schema, save behavior and source ownership. The [portrait source index](../../art/source/portraits/v1/README.md) links every original painting, exact prompts and generation/reference hashes. The classic concept is a reference; the screenshots below are the actual Godot game.

## Portraits and source integrity

Five separate **1024×1536 RGBA** portraits were generated with the built-in `image_gen.imagegen` tool, each using that resident's existing neutral sprite as the identity reference and concept A as the illustration-style reference. Mira retains her bob, brass clips, plum coat and ochre scarf; Rowan his silver hair/beard, teal vest and rust scarf; Bram his dark curls, copper vest and leather apron; Tessa her strawberry braid and moss cap; Nell her silver braid, brass spectacles and teal/gold shawl.

Original outputs were copied without pixel edits to `art/source/portraits/v1/`. They contain real transparency; the transparent pixels' underlying RGB preview is not a runtime backdrop. The art catalog pins source hashes, prompts and provenance. The existing `scripts/art.sh` now also validates and builds the portrait set, configures lossless UI imports and writes `assets/portraits/library.json`; `art/dialogue_portraits.gd` reads that compiled selection. No service is needed while playing.

A before/after SHA-256 comparison covers **134 pre-existing character source/runtime/template files**. They remain unchanged, including the approved boy, resident frame art, shared animation template, skin catalog, frame resources and manifests. The art build's existing 100 character checks and 66 shared-frame checks pass.

## Actual game review

Reviewed in Godot 4.7.2, Compatibility renderer, AMD Radeon 680M, at **1600×1000**, **1280×720**, and **1280×720 with 150% interface size**. `tools/dialogue_tour.gd` uses each resident's real nearby F prompt and the ordinary conversation controller, drives actual Space / H / Escape input, captures greetings, replies and optional code for all five people, then saves and Continues to check read flags. Scratch saves preserve the player's journey.

| View | Capture |
|---|---|
| Mira, raised portrait | [1600×1000](../../evidence/village-dialogue/mira-greeting.png), [1280×720](../../evidence/village-dialogue/mira-1280.png) |
| Rowan | [Greeting](../../evidence/village-dialogue/rowan-greeting.png) |
| Bram | [Greeting](../../evidence/village-dialogue/bram-greeting.png) |
| Tessa | [Greeting](../../evidence/village-dialogue/tessa-greeting.png) |
| Nell | [Greeting](../../evidence/village-dialogue/nell-greeting.png) |
| Response topics | [Mira's choices](../../evidence/village-dialogue/mira-choices.png) |
| Optional variables example | [Mira's code](../../evidence/village-dialogue/mira-code.png) |
| Optional conditions example | [Nell's code](../../evidence/village-dialogue/nell-code.png) |
| History and settings | [History](../../evidence/village-dialogue/history.png), [settings](../../evidence/village-dialogue/settings.png) |
| Enlarged interface | [Portrait and code at 150%](../../evidence/village-dialogue/large-ui.png) |

The first view exposed a low portrait/nameplate overlap; the nameplate moved beside the portrait. The user's follow-up then raised the portrait without increasing its scale. An enlarged-interface review led to wrapping controls, a scrolling optional panel and showing the code before its explanatory text. Optional panels stop above the speaker's nameplate. Faces and shoulders remain visible. At large interface size, the optional content scrolls to its remaining explanation and actions.

## Implemented behavior

Click / Space / Next first completes progressive text, then advances. Response pages wait for a choice. History includes the player's responses; Auto waits for replies and pauses while another panel/modal is open. Skip read fast-forwards known pages and stops at new text or choices. Read flags persist per resident across Continue and house travel. Hide UI leaves input blocked, and H / Escape restores the scene. Conversation preferences remember text speed and auto delay. Leaving restores the normal play HUD and movement.

All residents have ordinary village topics plus an optional teaching topic: Mira variables, Rowan loops, Bram functions, Tessa lists and Nell conditions. Show code appears on the relevant explanation and starts closed. It opens a highlighted read-only source example, with explanation, Copy example and Open notebook. Opening a conversation or example changes no world state, program memory, quests or source. Open notebook preserves the player's draft. Running and applying copied code remains the existing bounded WASI/validated preview/Apply flow. No new quest or NPC-command capability is added.

## Verification

`test/test_dialogue.gd` passes **119 checks**: five portrait/source/import/reference contracts, authored topic validation, forbidden choices, optional code timing, bounded history and saved-read filtering; every sample program through real Python/WASI and command validation; the actual F modal flow, typewriter reveal, Auto/Skip boundaries, hidden UI, settings stack, draft/world preservation, save/Continue and indoor host conversation.

A pre-existing builder-code test also created two unattached Character-screen skill lists without freeing them. Its cleanup now frees those temporary controls; the test assertions and runtime behavior are unchanged.

`scripts/art.sh` passes. `scripts/test.sh` covers the new dialogue checks alongside existing world/quest/WASI, house, builder, painting, programming, UI, movement, sprite and source-handoff checks. Final logs and intermediate frames are under `.cache/vn-dialogue/`; selected captures above belong with this review. The [verification record](../../evidence/village-dialogue/verification.json) records the final full run and protected-art comparison.

The delivered portraits are one expression per resident. Voice/audio, expression libraries and persistent conversation backlogs are not implemented. History is for the current conversation; durable read flags support Skip read. Optional examples are educational source, never a second execution path.
