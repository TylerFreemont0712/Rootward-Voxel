# Interface kit and screens

The interface is code-drawn from one palette, so it needs no texture files, scales cleanly and stays editable. Its look is *semi-fantasy*: dark warm wood and leather, thin brass trim, parchment text, engraved capitals. It follows the voxel concept's own HUD (dark brown plaques with gold borders) rather than ornate high fantasy. Playing needs no art service for any of it.

## Design rules

- **The world comes first.** Location stays above a translucent quest/next-step panel on the left; quest completion temporarily uses that same space. Code opens in a stitched notebook drawer on the right, with no scrim. Both journeys share the drawer and tracker, and the camera shifts to keep the player in the free area. Menus that take over the screen still use modals.
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
| `ui/lesson_test_window.gd` | A separately placed foreground demonstration window over the lower-right free world area; it never adds to camera reservation. |
| `ui/side_drawer.gd` | Shared responsive notebook dock, stitched spine, slide animation and extent signal for camera/HUD layout. Used by both coding notebooks. |
| `ui/fonts/` | Cinzel (headings, buttons), Alegreya (reading), IBM Plex Mono (code). Variable-weight faces, OFL, copied once from the main project; see `ui/fonts/README.md`. |

## Screens

| Screen | File | Opens from |
|---|---|---|
| Title | `ui/title_screen.gd` | Start, or Save and return to title |
| Archived journey picker | `ui/level_select.gd` | Retained component; public New game opens Sparks naming directly |
| Asset Showcase (Dev) | `ui/asset_showcase.gd`, `scenes/asset_showcase_stage.gd` | Main title, development builds and enabled project setting |
| Asset request / deletion form | `ui/asset_request_dialog.gd` | Showcase’s Request update, Request new or Delete |
| Asset work queue | `ui/asset_request_queue.gd` | Showcase’s Requests button |
| Hotaru / Field notes | `ui/village_conversation.gd`, `app/hotaru_dialogue.gd`, `ui/greeting_lesson.gd`, `ui/movement_lesson.gd` | Village Morning's opening; E, Field Notes button or objective pill |
| HUD | `ui/hud.gd` | While playing |
| Notebook | `ui/notebook_panel.gd` (+ `code_editor.gd`, `lesson_view.gd`, `reference_view.gd`, `world_view.gd`) | E, the Notebook button |
| Pause | `ui/pause_menu.gd` | Esc |
| Journal | `ui/journal_panel.gd` | J, the objective pill |
| Map | `ui/map_panel.gd`, `ui/map_view.gd` | M |
| Resident conversation | `ui/village_conversation.gd` | F, or clicking the speech bubble over the resident |
| Character | `ui/character_screen.gd` | Title, pause, New journey |
| Settings | `ui/settings_panel.gd` | Title, pause |
| Confirm, Epilogue | `ui/confirm_dialog.gd`, `ui/epilogue_screen.gd` | New journey over a save, reset; the last quest |

**Current title:** Sparks & Machines is the main route, backed by `content/levels/catalog.json`’s `default`. New game opens its naming screen; Continue considers only unarchived saves. The initial backdrop is the loft at the fixed room camera. Legacy concepts stay directly callable in tests and development tools.

The developer showcase uses the existing modal stack and a separate `ModelTurntable` viewport. It opens empty, hides and pauses the journey presentation, and restores it on Esc/Back to title. Search lists world-catalog models; load/reload uses `WorldAssets` so outlines/materials stay consistent. Drag turns, wheel zooms, buttons quarter-turn/reset, and optional auto-rotation, metre grid and scale boy support inspection. Model bounds fit the orthographic view through all rotations. It never creates an area, edits a ledger or accesses saves. `rootward/development/asset_showcase_on_title` is enabled now; disabling it hides both the title entry and handler. Release builds also hide it.

The showcase now also writes local authoring requests: optional notes, dropdown reference selection, an all/requested/finished model filter and a readable work-queue browser with clickable file paths. New assets stay in the request browser until delivered; Finished is for delivered catalogued models. Acceptance clears that queue entry; asking for another update retains the old delivery history. Delete opens an explicit source/runtime summary, or a linked removal request when dependencies remain. A nested form handles Esc before the showcase. `AssetWorkflowClient` invokes fixed local Python authoring operations with notes in a temporary JSON file, and reports failures in the form instead of repeated popups. [Workflow](../asset-requests/README.md).

`AssetRequestList` reserves a right-hand marker gutter: requested/in-progress deletions show a slight red row tint and X, updates a yellow tint and outline square. Selection and scrolling retain the symbols; long names ellipsize before the gutter. Deletion wins when both requests exist. Finished/accepted rows clear the mark. Reload and request-browser refresh pick up external agent transitions. See the [native marker review](reviews/2026-10-29-robot-models-and-request-markers.md).

Modals derive from `ui/modal.gd` and stack: Settings above Pause hides Pause and returns to it. `app/game.gd` owns the stack, the title/play flow, autosave and the Esc ladder. `app/session.gd` owns the world and emits signals the UI observes; screens never touch world state.

Hotaru uses the portrait dialogue scene as a presentation style, with the interaction chosen for each scene. The tutorial opening is a **guided sequence**: no player reply choices before learning to speak, a compact History/Settings/Continue footer, and an automatic notebook handoff from the final page. Field Notes /00 — Saying Hello uses a print block or Python, Test and Speak. Committing a successful greeting immediately starts the guided First Steps introduction; finishing that chat opens /01 automatically. Optional spoken replies are available once the voice lesson is complete. Dialogue choices and full visual novel controls remain available for ordinary conversations; they are not mandatory for every interaction.

The detached voice window shows the player's words. Field Notes /01 uses Apply, then Continue to the room for practice; Finish is available when practice is complete. `ui/learning_lesson.gd` shares their lifecycle; `ui/program_playback.gd` replays bounded actual WASI execution lines/values, automatically displaying Python beneath blocks or highlighting the handwritten editor. Replay/Pause/Next line inspect the same evidence. Edits and world changes clear playback. Block arrows test only their event and cannot Apply fragments; Test code validates the full program.

Village Morning's movement notebook is a `SideDrawer`, outside the modal stack. Its four indented, numbered event blocks edit a key, `x +=` / `x -=` / `y +=` / `y -=`, and an amount from 0–4. **See Python** shows the generated source. **Test code** compiles and runs the real WASI program, then both editors consume the same bounded movement traces in a separate foreground window (`ui/lesson_test_window.gd`) using `scenes/movement_test_view.gd`: a copied room, animated boy, numbered one-cell/overshoot targets, collision stops and replay keys. Test traces cannot mutate world state or count practice. Only valid unit cardinal bindings can be applied. Syntax/runtime errors mark the Python line; successful events get green fills/borders and Passed badges, while incorrect events get red fills/borders and Fix/Blocked badges. Edits clear the old verdicts. Invalid arithmetic explains the amount. Drafts save independently; edits, mode changes and closing discard old proposals and replays. See [the lesson contract](MORNING.md) and [review](reviews/2026-10-25-interactive-notebooks.md).

## Build mode's interface

Build mode is laid out like a workshop, not a phone app: a **rail of round bubbles** down the left edge (Move, Delete, then the two build menus Objects and Land, then Undo, Redo and Done), a **tray along the whole bottom** of the screen for the catalog or the ground paints, and a **details panel** on the right (about a fifth of the width) for whatever is chosen. Object cards are 112×134 in a single sideways-scrolling row (wheel or page arrows). Size facts live in tooltips and the details panel. Ctrl+F searches titles, blurbs and categories across tabs; Esc clears search and Tab hides the tray. The eight category tabs sit in their own horizontal scroll area, automatically revealing the selected tab while search keeps its place. Window `ui_scale` applies throughout. Thumbnails draw the visible category first, then other models in the background and stay cached; the headless guard remains.

Land swaps in tinted ground swatches, Grass/Dirt/Stone/Soil/Floors tabs, Eraser, three brush sizes and Pick, then the **Terrain** (Raise, Lower, Stone stairs) and **Water** (Dig, Fill in) tabs, whose cards show pictures drawn from small sample terraces; for them the brush sizes become 1, 2 and 3 cells, Pick hides, and stairs need no brush. Their `raise`, `lower`, `stairs`, `water` and `fill` glyphs are code-drawn. The grid and footprint use half cells, with invalid ground red. Dragging shows a proposal; release commits one undo step; Esc/right-click cancels it. The `brush` and `eraser` glyphs are code-drawn. Cursor bubbles, toasts and the allowance chip remain. See [ground](GROUND.md).

`ui/build_hud.gd` is a full-screen layer the same kit builds: a brass-cornered frame, the rail of `ui/build_bubble.gd` bubbles (a domed round button with an icon, its name, a key badge, a hover lift and a swell when chosen), the tray of `ui/build_card.gd` cards that slides up for Objects and Land, `ui/build_details.gd` (the details panel: a live `scenes/model_turntable.gd` picture that turns when the thing can be turned, the facing compass, the facts, a code section and Remove), a key-hint line, a bubble at the pointer that names a good spot or gives the reason for a bad one (green tick, red warning), toasts under the hint line and an allowance chip. It shows state and emits signals; `app/build_mode.gd` decides what the details panel shows. The rail keeps its place whichever tool is chosen; the hint line centres itself between the rail and the panel. Card pictures come from `scenes/thumbnail_studio.gd`, which draws each real model once from the game's camera angle. The icons added for it are `hammer`, `house`, `tree`, `move`, `trash`, `redo`, `rotate`, `grid`, `cube` (Objects), `land`, `code`, `turn_left` and `turn_right`. Standing working props show their saved id, active state and Python members in the details panel, with **Write code for it** following discovery. The 95-entry catalog includes the fifty new [village-library pieces](BUILDER_LIBRARY.md). See [build mode](BUILD.md).

## Scene change veil

Every change of place (room links and stairs, houses, a new game, back to the title) goes through `Game._fade`, which drives `ui/gear_veil.gd` (`GearVeil`, shader `ui/gear_veil.gdshader`). It is a clockwork curtain: a brass edge in the shape of a gear wheel grows out of a point (the apprentice, or the doorway being walked into) until nothing else shows; five meshed gears and an engraved dial of minute ticks turn on a dark workshop floor while the next scene is built behind it; the same edge then opens a hole where the apprentice arrives. Timings are `Game.VEIL_CLOSE_SECONDS` (0.55), `VEIL_CLOSED_SECONDS` (0.55, the least time it stays closed, the build included) and `VEIL_OPEN_SECONDS` (0.7). The gears turn at a calm pace (the main wheel about a quarter turn in three seconds) and are always turning while the veil shows.

- `Game._fade(action, down_seconds, during_down, during_up, origin, up_seconds, lead_in)` covers, calls `action`, then opens. `during_down`/`during_up` receive 0..1 as each half plays so a walk carries on underneath, and `lead_in` is how long the first plays, seen, before the veil starts to grow. The veil never decides anything: it blocks the mouse while it shows and the game waits on it.
- A new place is built in one go on the main thread (three to six seconds for the square), when nothing would be drawn and the gears would stand still. The builders (`ClearingView._try_world_asset`, `_flush_batches`, terrain chunks, `IllustratedEdges`) call `BuildPump.pump()` between pieces; while `Game._fade` runs its action `BuildPump.tick` is the veil's `keep_turning`, which sets the gears from the clock (so a stalled frame never jumps them) and redraws the screen with `RenderingServer.force_draw`. The 3D world underneath is not drawn meanwhile. Any new long build step should call `BuildPump.pump()`.
- The gears are meshed for real (`meshed()` in the shader gives each wheel the rotation that locks its teeth into the one before), so a new wheel is added by chaining it, not by placing it.
- `tools/gear_veil_review.gd` holds the veil at fixed points of its sweep over the workshop and saves frames; `tools/transition_review.gd` plays the real scene changes. See the [review](reviews/2026-10-30-doorways-transitions-and-flicker.md).

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

`app/game_settings.gd` saves `fullscreen`, `ui_scale` (60–150%, applied on slider release), `zoom`, `show_controls`, `font_size` (10–26 px; default 15), `completion`, `auto_brackets` and `character_skin`, `dialogue_speed` and `dialogue_delay` to `user://settings.cfg`. There is no audio setting because there is no audio.

## Checks

`test/test_ui.gd` covers lesson markup, error explanations, the API reference (including that every documented member exists in the Python harness), the editor and the widgets. `test/test_app.gd` drives the title, play flow, notebook, Ctrl+Enter, Esc ladder, modals, saves and Continue through the real objects. `tools/ui_tour.gd` writes a PNG of every screen for human review, and `tools/ui_gallery.gd -- <png>` renders the bare kit (buttons in every state, icons, tabs, a drawer, pills) on a neutral backdrop when you change the theme; passing tests do not replace looking at them.

The [detached-window revision](reviews/2026-10-25-doorway-and-test-window.md) follows the user’s lower-right placement reference. The notebook keeps its original camera reservation; the preview overlays the scene. Its width/height adapt to the free world area, with a deferred size pass after text wrapping settles. Closing the notebook hides and disposes the preview along with it.


## Compact full-screen desktop profile

The reference canvas is 1920×1080, with full screen as the normal starting mode. A one-time settings layout migration selects full screen and replaces the former default 18 px code font with 15 px; later choices remain saved. The interface kit uses smaller buttons, glyphs, text and padding. Lesson event rows retain their code appearance and green/red feedback. The drawer keeps its width while execution Python grows into the remaining height, showing at least twelve lines in reviewed layouts. Manual Python receives the main workspace; See Python shares the active execution highlight. Live font-size settings update all editor variants. Existing input and Test → Apply behavior is unchanged.

[Desktop, room and doorway review](reviews/2026-10-26-compact-desktop-and-room.md).

The Sparks first morning begins beside the bed. A physical note under the mug opens a side card and is removed only when put away; using or clicking the terminal opens `ui/workshop_journal.gd`. The first page offers Blocks and Python, with independent drafts; both feed the existing WASI runner. Test ghost-types actual returned output in `ui/workshop_speech.gd`, and Send message commits that same proposal. A wrong name still prints but does not ring Hotaru’s message bell. The completed waking exchange sends the player to Nell’s field tablet on the bed; the wall screen downstairs needs it. See [the tablet and wall screen review](reviews/2026-10-27-tablet-and-wall-screen.md).

The pinned `JobTicket` shows the first job’s concrete steps and opens `WorkshopJobLedger` for reached jobs. `WorkshopScene` uses the selected Hotaru portrait on the left and the traveller portrait on the right; the speaker is highlighted, choices are solid, and read dialogue is saved in `WorkshopLog`, alongside Nell’s note. Ordinary inspections and repeat chatter use wider world-anchored bubbles that do not block movement. The relocated stair lantern remains visible while its fixture preview is tested. The morning-round page includes a worked loop example; the shared zone computers now provide the physical connection for these pages. Later lessons remain proposed. See the [first morning review](reviews/2026-10-27-first-morning-tutorial.md).

The story window is one fixed card, `WINDOW_WIDTH` 0.69 by `WINDOW_HEIGHT` 0.225 of the screen (clamped), centred near the bottom, for every page of every scene. The speaker, page count and words sit on the left in a clipped area that never changes the card’s size; the reply choices, or Continue, are buttons inside the card on the right; the two portraits stand behind its top corners. Layout is computed from the screen alone, never from the text. [Review](reviews/2026-10-28-story-window.md).

Where code is written follows the traveller: `ZoneConnectionPanel` also offers to walk to a single fitting (`setup_device`), `WorkshopJobLedger` gives each unfinished job a "Go to" button from `FieldAccess.place_for`, and the job ticket says where to stand. The paper style of `ClearingView` (`marker_style`) draws route steps as outlined dots from `art/route_marker.gdshader`, the end of a route as a breathing ring, a glow from `art/target_glow.gdshader` on the object being walked to or about to be used, and the job mark as a brass dial (`art/spark_dial.gdshader`) with rising sparks (`art/spark_mote.gdshader`); other journeys keep their original markers.

Fixed zone terminals use `ZoneTerminalDisplay` for real screen output and connection lamps; it lays its lettering on whichever model’s `terminal_screen` glass the area names, so the desk computer and the wall screen share it. `ZoneConnectionPanel` points an unlinked room to its authored terminal (a terminal that `requires` an item is presented as an area node and says to plug the tablet in); clicking/F links the zone, and the editor header repeats its exact code name. [Review](reviews/2026-10-27-zone-terminals.md) and [tablet and wall screen](reviews/2026-10-27-tablet-and-wall-screen.md).
