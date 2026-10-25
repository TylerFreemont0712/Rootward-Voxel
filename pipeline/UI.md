# Interface kit and screens

The interface is code-drawn from one palette, so it needs no texture files, scales cleanly and stays editable. Its look is *semi-fantasy*: dark warm wood and leather, thin brass trim, parchment text, engraved capitals. It follows the voxel concept's own HUD (dark brown plaques with gold borders) rather than ornate high fantasy. Playing needs no art service for any of it.

## Design rules

- **The world comes first.** The HUD is a location pill, an objective pill and four round buttons. Code is never on screen unless the player asks (E). The notebook is a drawer over the right of the screen; the camera shifts so the character stays centered in the free part.
- **It is a learning game.** Every error says which line, what the mistake probably is and what name was likely meant; the raw Python message stays visible. Lessons, hints and a searchable reference live beside the editor, and nothing is real until Apply.
- **Honest about what exists.** The character screen shows the boy apprentice, with no equipment slots. Mira and four other skins are village residents. Unvisited places are fogged on the map.
- **Keyboard and mouse both work.** Menu buttons take focus (Tab/arrows, Enter); HUD buttons are mouse-only with hotkeys; Esc peels back one layer at a time.

## Pieces

| File | Role |
|---|---|
| `ui/palette.gd` (`Pal`) | The color tokens. Change a color here, never inline. |
| `ui/fantasy_box.gd` | A `StyleBox` that **draws** a chamfered plaque (vertical gradient, brass border, inner hairline, rivets, shadow, glow) with `RenderingServer` calls. Its properties are `@export` so `duplicate()` keeps them. |
| `ui/glyph.gd` | About 30 vector icons (play, book, lamp, gate, bridge, lock, …) drawn with lines and polygons. `Glyph.paint` draws onto any `CanvasItem`. |
| `ui/ui_theme.gd` (`UITheme`) | Builds the one `Theme`: fonts, button variations (`ButtonPrimary`, `ButtonTab`, `ButtonQuiet`, `ButtonIcon`, `ButtonDanger`), panel variations (`PanelPill`, `PanelCard`, `PanelInset`, `PanelScrim`, `PanelDrawer`), inputs, scroll bars, sliders, tooltips. |
| `ui/f_button.gd`, `ui/toggle.gd`, `ui/ornament.gd`, `ui/ui.gd` | Button with an icon, a rune switch, the diamond divider, and small factories (`UI.button`, `UI.label`, `UI.hbox`, …) so screens read as layout. |
| `ui/fonts/` | Cinzel (headings, buttons), Alegreya (reading), IBM Plex Mono (code). Variable-weight faces, OFL, copied once from the main project; see `ui/fonts/README.md`. |

## Screens

| Screen | File | Opens from |
|---|---|---|
| Title | `ui/title_screen.gd` | Start, or Save and return to title |
| HUD | `ui/hud.gd` | While playing |
| Notebook | `ui/notebook_panel.gd` (+ `code_editor.gd`, `lesson_view.gd`, `reference_view.gd`, `world_view.gd`) | E, the Notebook button |
| Pause | `ui/pause_menu.gd` | Esc |
| Journal | `ui/journal_panel.gd` | J, the objective pill |
| Map | `ui/map_panel.gd`, `ui/map_view.gd` | M |
| Resident conversation | `ui/village_conversation.gd` | F, or clicking the speech bubble over the resident |
| Character | `ui/character_screen.gd` | Title, pause, New journey |
| Settings | `ui/settings_panel.gd` | Title, pause |
| Confirm, Epilogue | `ui/confirm_dialog.gd`, `ui/epilogue_screen.gd` | New journey over a save, reset; the last quest |

Modals derive from `ui/modal.gd` and stack: Settings above Pause hides Pause and returns to it. `app/game.gd` owns the stack, the title/play flow, autosave and the Esc ladder. `app/session.gd` owns the world and emits signals the UI observes; screens never touch world state.

## Build mode's interface

Build mode is laid out like a workshop, not a phone app: a **rail of round bubbles** down the left edge (Move, Delete, then the two build menus Objects and Land, then Undo, Redo and Done), a **tray along the whole bottom** of the screen for the catalog or the ground paints, and a **details panel** on the right (about a fifth of the width) for whatever is chosen. Object cards are 112×134 in a single sideways-scrolling row (wheel or page arrows). Size facts live in tooltips and the details panel. Ctrl+F searches titles, blurbs and categories across tabs; Esc clears search and Tab hides the tray. The eight category tabs sit in their own horizontal scroll area, automatically revealing the selected tab while search keeps its place. Window `ui_scale` applies throughout. Thumbnails draw the visible category first, then other models in the background and stay cached; the headless guard remains.

Land swaps in tinted ground swatches, Grass/Dirt/Stone/Soil/Floors tabs, Eraser, three brush sizes and Pick, then the **Terrain** (Raise, Lower, Stone stairs) and **Water** (Dig, Fill in) tabs, whose cards show pictures drawn from small sample terraces; for them the brush sizes become 1, 2 and 3 cells, Pick hides, and stairs need no brush. Their `raise`, `lower`, `stairs`, `water` and `fill` glyphs are code-drawn. The grid and footprint use half cells, with invalid ground red. Dragging shows a proposal; release commits one undo step; Esc/right-click cancels it. The `brush` and `eraser` glyphs are code-drawn. Cursor bubbles, toasts and the allowance chip remain. See [ground](GROUND.md).

`ui/build_hud.gd` is a full-screen layer the same kit builds: a brass-cornered frame, the rail of `ui/build_bubble.gd` bubbles (a domed round button with an icon, its name, a key badge, a hover lift and a swell when chosen), the tray of `ui/build_card.gd` cards that slides up for Objects and Land, `ui/build_details.gd` (the details panel: a live `scenes/model_turntable.gd` picture that turns when the thing can be turned, the facing compass, the facts, a code section and Remove), a key-hint line, a bubble at the pointer that names a good spot or gives the reason for a bad one (green tick, red warning), toasts under the hint line and an allowance chip. It shows state and emits signals; `app/build_mode.gd` decides what the details panel shows. The rail keeps its place whichever tool is chosen; the hint line centres itself between the rail and the panel. Card pictures come from `scenes/thumbnail_studio.gd`, which draws each real model once from the game's camera angle. The icons added for it are `hammer`, `house`, `tree`, `move`, `trash`, `redo`, `rotate`, `grid`, `cube` (Objects), `land`, `code`, `turn_left` and `turn_right`. Standing working props show their saved id, active state and Python members in the details panel, with **Write code for it** following discovery. The 95-entry catalog includes the fifty new [village-library pieces](BUILDER_LIBRARY.md). See [build mode](BUILD.md).

## Adding or changing a screen

1. Build it from `UI.*` factories and theme variations. Use `Pal` colors and the existing glyphs; add a glyph to `ui/glyph.gd` if you need one.
2. Make it a `Modal` if it takes over the screen. Give it a `setup(...)`, open it through `Game._push_modal`, and let Esc close it.
3. Add a shot to `tools/ui_tour.gd` and run `scripts/screenshot.sh`. Look at it at 1600×1000 and at `--resolution 1280x720`.
4. Test behavior (not pixels) in `test/test_app.gd` or `test/test_ui.gd`: open it through the real path, assert what a player would see change, close it.

## Notebook editor behavior

`ui/code_editor.gd` configures `CodeEdit`: Python colors; 4-space indent, automatic indent after `:`; bracket and quote pairing; current-line highlight; line numbers; Ctrl+Enter runs; a red marker and tint on the failing line (cleared by the next edit); completion triggered by `.` and by typing two letters, using `ApiReference.infer_type` to offer only the members of the object you are dotting (`lamp.` offers `set_lit`, `lit`, `id`, `zone`, `cell`). Starter and Clear replace the program as one undoable edit. Text size, completion and bracket pairing are settings.

The Character screen names and turns the boy. Mira, Rowan, Bram, Tessa and Nell are NPC skins with `selectable: false`; older Mira player preferences load as the boy. **F** (or clicking the speech bubble over them) opens a nearby resident’s single-speaker visual novel scene, and uses the working thing under the hand. There is no action button: `ui/world_prompts.gd` draws the bubble, the hand and residents’ **!**/**?** marks in the world ([marks and the speech bubble](DIALOGUE.md#marks-and-the-speech-bubble)). Conversations use five new high-definition portraits, smaller and raised to show the upper body; a bottom dialogue box; response choices; progressive text; History, Auto, Skip read, Hide UI and settings. Optional code panels are attached to relevant explanations and never execute or replace the player’s draft. Conversation pauses resident motion, hides the play HUD and uses the ordinary modal stack, with Escape closing an extra panel first. See [the conversation guide](DIALOGUE.md). House travel fades the view, cancels walking and clears previews. See [Village](VILLAGE.md).

## Settings

Standing-object Move details include material dropdowns with texture swatches for supported walls, roof, timber, masonry, metalwork and upholstery. Indoors the hammer/B opens `RoomFinishes`, a scrolling modal for six parts, Original, Undo, Redo and Done. Every house saves its own appearance. The outdoor Land tray adds a Floors family; see [Materials](MATERIALS.md).

`app/game_settings.gd` saves `fullscreen`, `ui_scale` (applied on slider release), `zoom`, `show_controls`, `font_size`, `completion`, `auto_brackets` and `character_skin`, `dialogue_speed` and `dialogue_delay` to `user://settings.cfg`. There is no audio setting because there is no audio.

## Checks

`test/test_ui.gd` covers lesson markup, error explanations, the API reference (including that every documented member exists in the Python harness), the editor and the widgets. `test/test_app.gd` drives the title, play flow, notebook, Ctrl+Enter, Esc ladder, modals, saves and Continue through the real objects. `tools/ui_tour.gd` writes a PNG of every screen for human review, and `tools/ui_gallery.gd -- <png>` renders the bare kit (buttons in every state, icons, tabs, a drawer, pills) on a neutral backdrop when you change the theme; passing tests do not replace looking at them.
