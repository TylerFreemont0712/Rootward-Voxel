# Village conversations and portraits

F beside Mira, Rowan, Bram, Tessa or Nell opens a single-speaker visual novel conversation over the current village or house. A newly painted, high-definition portrait appears at the left, with a wide dark wood/brass dialogue box along the bottom. The boy remains the player and has no second conversation portrait.

Portraits retain the smaller scale, at most half the canvas height. Following the user's height correction, they are lifted **125 px on the standard 1000 px canvas**, proportionally at other sizes. Large interface settings raise them further when necessary to keep shoulders visible. The nameplate sits beside the portrait, clear of its face. The actual world and approved camera stay behind the scene; the play HUD steps aside and walking/resident motion pause.

## Reading and controls

- **Click the dialogue/background, Space, or Next**: finish revealing the current page, then advance. Reply pages wait for a choice; buttons support mouse and ordinary Tab/arrow/Enter focus.
- **History**: scroll through the current conversation, including your responses.
- **Auto**: advance after the text finishes and a reading delay. It waits at choices and pauses while an extra panel, hidden UI or another modal is open.
- **Skip read**: fast-forward previously read pages; stop at new text and choices. Read flags save per resident and survive Continue. A new journey clears them.
- **Hide UI / H**: hide portrait and panels to see the world. Click, H, Space or Escape restores dialogue; walking remains blocked.
- **Settings**: conversation text speed (0 means instant), auto delay and a link to the usual game settings. Preferences save through `GameSettings`.
- **Leave / Escape**: leave. Escape first restores hidden UI or closes an extra panel. Each topic also returns to the reply menu, with a “See you around” option.

Auto never selects a response. These controls affect dialogue presentation and read metadata, not quests or world commands. History is bounded to the current conversation's last 128 entries; it is not a durable journey log.

## Optional code explanations

Each resident offers a normal village topic and a teaching topic. Talking and learning remain optional. On the relevant final page of an explanation, **Show code** offers a highlighted example, concept title and plain-language explanation. The panel starts closed. Reading code pauses automatic advancement; Close / Escape returns to the conversation.

| Resident | Example |
|---|---|
| Mira, cartographer | Variables: naming a place and storing a map note. |
| Rowan, millwright | For loops: proposing a light change for each known lamp. |
| Bram, carpenter | Functions: a reusable maker's label. |
| Tessa, gardener | Lists: keeping plant names together. |
| Nell, herbalist | Conditions: choosing a branch with `if` / `else`. |

**Copy example** copies the displayed source to the clipboard. **Open notebook** closes the conversation and opens the player's existing draft unchanged. Paste or edit deliberately there; Run previews and Apply commits under the ordinary WASI/rule validation. Opening a conversation or a code panel never executes an example, edits program memory, changes the world or replaces the player's code. The examples are real runnable Python, tested through the local WASI runner. Code sees only discovered places, including only the current saved room when indoors.

These topics do not add or complete quests, unlock extra building abilities, or expose an NPC-command API. Future explanations can attach the same optional lesson block to another topic.

## Marks and the speech bubble

Nothing about talking sits in a button. `ui/world_prompts.gd` draws, over the world and with the play HUD:

- a parchment **speech bubble** with an **F** key over the resident F would talk to (the nearest within 1.9 cells, on the same level). Clicking it does what F does, and both turn to face each other as the conversation opens;
- a **hand** with an F key over the working thing F would use, when no resident is nearer (its tooltip says what F does, such as "Open Wayfarer's Chest");
- a **mark** over every resident here with something to say. `VillageDialogue.marker` decides it from the resident's topics, the read flags, whether you have met, and the current quest: **?** (teal) while one of their topics `helps` with the current quest and you have not heard all of it, else **!** (gold) if you have never spoken or some page is unread, else nothing. The bubble carries the mark, or "…" when there is nothing new.

Residents are solid. `VillageLife` keeps each one out of the player's cells (and the cell the player is stepping into) and out of each other's, walking round when there is room and waiting when there is not; the session stops the player at a resident, routes a click-to-walk round them (after a moment's wait), and turns clicking on a resident into walking up beside them. Residents still lock nothing: lesson rules, Python and the builder's cut-off check ignore them.

## Content and architecture

`content/villagers.json` retains each resident's identity, greeting and original village lines, and adds `topics`:

```json
{
  "id": "map-notes",
  "title": "Tell me about your maps.",
  "helps": ["mill-bridge"],
  "lines": ["An ordinary explanation.", "The page that can offer a code representation."],
  "lesson": {
    "title": "A name for a place",
    "concept": "Variables",
    "explanation": "What the example shows.",
    "source": "def program(world):\n    world.memory[\"note\"] = \"Kindle Hollow\"\n"
  }
}
```

`lesson` is optional. Its button appears only on that topic's last page. `helps` is optional: up to eight quest ids this topic helps with (`test/test_dialogue.gd` checks each names a real quest). Topic ids must be unique, distinct from `greeting`, `menu` and `leave`; each topic has 1–12 nonempty pages of at most 500 characters. There are 1–8 topics per person. Lesson title/concept/explanation/source must be strings, and source must fit the 16 KiB notebook limit. The greeting leads to a reply menu; every topic returns there. The leave action ends the conversation. No rendering or arbitrary code execution decides navigation.

| Layer | Owns |
|---|---|
| `core/village_dialogue.gd` | Pure content validation, topic/page transitions, choice validation, bounded history and read flags. |
| `app/area_store.gd` | File loading and validation at the content boundary. |
| `ui/village_conversation.gd` | Layout, portrait, typewriter, controls, optional code/history/settings panels; requests notebook/settings actions. |
| `app/game.gd` | F interaction and its target, the residents' marks, modal stack, input/HUD gates, notebook handoff and saved `dialogue_read` metadata. |
| `ui/world_prompts.gd` | The speech bubble, the hand and the marks, drawn over the world at heads and object tops. |
| `app/game_settings.gd` | Persisted `dialogue_speed` and `dialogue_delay` preferences. |

Saves add an optional `dialogue_read` map of resident ids to read page keys. Unknown residents, obsolete pages, duplicates and malformed values are filtered. Old saves without it work. Read state follows the resident across the valley and their saved home. It is separate from each room's world state, discoveries and Python memory.

## Portrait source and build

Five new **1024×1536 RGBA** paintings are versioned under [art/source/portraits/v1](../art/source/portraits/v1/README.md). Each uses its original shared-frame identity plus classic concept A as the style reference. Existing boy/resident sprite artwork, timing, anchors and idle behavior are preserved.

`pipeline/art-catalog.json` selects the five sources, hashes, prompt/provenance and runtime paths. `pipeline/portrait_builder.gd` is part of the existing **`scripts/art.sh`** build: validate source/reference/prompt hashes, copy losslessly, configure transparent UI imports, and write `assets/portraits/library.json`. Runtime PNGs live in `assets/portraits/`; `art/dialogue_portraits.gd` reads the compiled selection rather than guessing portrait paths. Missing selected output is reported; it does not silently enlarge a walking sprite instead. Linear UI filtering, lossless RGBA, alpha-edge repair and no mipmaps are pinned.

For a new portrait, preserve the current source and author a new version with its prompt, identity/style reference hashes and source hash; update the selected catalog entry, run `scripts/art.sh`, then review at gameplay sizes. Portraits are a separate UI illustration layer, not new motion skins or a second animation pipeline. The game needs no image service or authoring tool at runtime.

## Verification

`test/test_dialogue.gd` covers all five portraits and their source/runtime/import contracts, valid/invalid topics, navigation and bounded history, saved-read filtering, every example through real Python/WASI, the marks, the bubble's anchor and click, the hand, solid residents, F/modal flow, progressive reveal, Auto/Skip boundaries, optional code, preserved world/draft, hidden UI, settings return, Continue and indoor conversation.

```sh
scripts/art.sh
scripts/test.sh
VOXEL_LAB_FRESH=1 scripts/play.sh --resolution 1600x1000 -s res://tools/dialogue_tour.gd
VOXEL_LAB_FRESH=1 scripts/play.sh --resolution 1280x720 -s res://tools/dialogue_tour.gd -- .cache/vn-dialogue/tour-1280
```

Add a final `1.5` argument to review enlarged UI. The tour uses isolated scratch saves, exercises all five actual F conversations, and captures greetings, replies, code and controls. Selected captures and actual check results are in [the review](reviews/2026-10-24-village-dialogue.md).
