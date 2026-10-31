# Field slate and spiral notepad — 2026-10-30

The user liked the idea of the code surface as its own solid device, with Field Notes kept separately for instructions, names and hints, and asked to see it in game with both in view. Two decisions came with it: only zones are plugged in (everything else links "like bluetooth"), and Field Notes should feel like a ringed notepad. The first greeting at the loft terminal stays as it was. Reviewed at 1920×1080 with `tools/tablet_review.gd` (frames in `.cache/tablet/`, not committed).

## What it looks like

- **The slate (right, about 41% of the width).** Dark enamel bezel with brass corner rivets. Along the top: the link lamp and its words, and a close button. On the glass: a file tab per reached job page (`landing_light.py`, `morning_round.py`), a DEVICES column with each lamp on the link (amber when lit; a blue ring and `off → on` while a Test proposes it), the editor and debugger replay, OUTPUT and the status bar. Test code and Apply routine are enamel keys on the lower bezel.
- **The notepad (lower left).** A wire coil through punched holes over a cardboard back, ruled blue lines and a red margin, two sheets peeking out underneath, and index tabs standing off the right edge: Job (teal), Names (brass), Hints (red). Job is Nell's text and the worked loop example. Names lists what the link reaches (`world.zone("workshop")`, `"landing-lamp"`, …) and the names the program makes up (`lamps`, `lamp`, `world`), with the last small value a Test saw. Hints reveals one more each press. A pencilled line under every tab carries the Test/Apply guidance; `/00 · Hello` and Story log sit at the foot. The HUD ticket hides while the notepad covers its corner.
- **The room between them.** It draws back by `Game.SLATE_PULL_BACK` (1.24) and is framed between the notepad and the slate, and both return when the slate is put down.
- **Wired at a zone.** The lamp reads `JACKED IN · WORKSHOP · 3 DEVICES`, a cord hangs from the slate's left edge, and in the room a grey cord runs from the apprentice to the socket under the wall screen.
- **Paired beside a fitting.** The lamp reads `PAIRED · STAIR LANTERN` and sends out signal arcs; in the room small teal sparks hop from the apprentice to the lantern.

## Notes

- The drawer this journal inherits is the slate's dock (`SideDrawer._wanted_width()` lets it ask for more width); the notepad is a `top_level` child that slides in from the left with it, so the game drives both through the same open/close calls.
- The page list is still the hidden `OptionButton` behind the file tabs, so saved pages, reach and the existing tests are unchanged.
- At 16:10 (1600×1000) the room is tighter between the two; 16:9 is the target.

## Checks

`test/test_workshop_quests.gd` gained 5 checks: paired beside the lantern with sparks in the room, both surfaces in view with the ticket stepped aside, plugged in at the wall screen with its cord, three devices and two file tabs, and everything restored when the slate is put down. The full `scripts/test.sh` result is in the session summary.

## Open for the user

- Slate width, notepad size and the room's pull-back are first picks.
- The in-room cord is a simple sagging tube from the apprentice's hand to the bottom of the screen; it is not modelled art.
- Lane and square have no job pages yet, so their pedestal still opens the scratch page on the same slate.

## Second pass, the same day (user adjustments)

The user asked for the notepad beside the slate's lower end, its coil on the left with sticky markers on top, a little wider for code samples, an index that grows with the lessons, a bigger jack, green for lit devices, programs that read like real programs (with their variables, such as the list of lights, and an obvious area to fix), and a prompt for a more solid slate. They also asked to lift the 16 KiB cap.

- **Notepad:** clipped to the slate's lower left by a binder clip, about 25% of the width; coil down the left edge over a cardboard spine; stickies Index · Job · Names · Hints standing up from the top edge (the open one stands tallest). It rises with the slate. The HUD ticket stays visible again.
- **Index:** every lesson reached here, numbered from /00 with its idea and a tick or dot; a title opens that page (on this link), the greeting, or says where the page is written.
- **Slate:** a larger brass jack with a knurled collar, strain relief and socket ring (and a larger plug in the room); DEVICES are green when lit; a **VARIABLES** column under them shows the program's names and values, stepping with the replay.
- **Programs:** the stair-lantern and morning-round starters are small scripts with a header comment, named variables and a `# TODO:` over the lines to fix; the editor marks that area with an amber band and gutter bar. Saved pages keep the player's own text.
- **Sandbox evidence:** each traced line records which of the program's names changed, as short text (`Lamp('landing-lamp', lit=False)`, `[Lamp('landing-lamp'), …]`), and the names `program` held on return come back as `locals`. Both are text only, bounded and validated (`LabProgram.safe_trace`, `safe_names`). The replay writes them at the end of the line that set them.
- **Limits:** results 16 → 64 KiB, source 16 → 64 KiB, combined output 32 → 128 KiB (it must stay above the result cap). Time and memory are unchanged.
- **Art prompt:** `U3 · Nell's field slate (frame)` in [the prompt pack](../../docs/concept/v0.7/04-art-prompts.md#u3--nells-field-slate-frame), a cream-enamel, teal and brass casing with a flat black window, shaped to be stretched as a nine-slice. Adopting it is a later step.

Checks added: `test/test_lab.gd` (variables as short text, a program over the old source limit runs, malformed variable evidence refused); the workshop play-through checks the notepad is clipped to the slate's lower end and open at the job.

## Third pass: the painted slate (v0.73)

The user asked for the generated slate in `docs/concept/v0.73/` to replace the drawn bezel, which blended into the dark surround.

- **Pipeline.** The authored PNG (`art/source/ui/nells-field-slate/v1/`) is unchanged. A new `interface_frames` entry in `pipeline/art-catalog.json` pins its hash and the measurements taken from it: casing crop, nine-slice margins that keep the corner guards, jack and lamp fixed, the inner window, and the jack and lamp centres. `scripts/art.sh` runs `pipeline/interface_frame_builder.gd`: crop, clear the transparent matte, fill the window with exact opaque black (the generated screen had near-transparent pixels, which first showed as a ragged ring), Lanczos to 50% (490×738), and write `assets/ui/nells-field-slate/frame.png` and its manifest. The full art build changed no other asset.
- **In game.** `TabletScreen` draws the frame as a nine-slice when the manifest exists. The glass fills the painted window, the link words and close button move into a dark title bar on the glass, the painted lamp glows when linked and sends arcs when paired, the cord is seated in the painted jack (a knurled cap over the socket, the cord leaving over the top-left corner), and the keys stand on the ledge below its groove, clear of the guards. The desk terminal is unchanged, and the drawn bezel remains as the fallback.
- **Checks.** `test/test_ui.gd`: the slate is framed with a title bar on its glass; the glass stays inside the painted window at a stretched size; the jack and lamp sit in the fixed corner. `test/test_pipeline_handoff.py`: the frame's source hash, provenance, built frame and manifest match. `scripts/art.sh`'s own checks passed.

## Fourth pass: reading the program, Debug and Job done

The user asked to drop the notepad's clip and let it be put away, to make names such as `workshop.lamps` explainable and clickable "as a program", to rename Test to Debug with the usual symbol, and to make finishing a job lead clearly back to the story.

- **Notepad:** no clip. **Put away** tucks it down to its stickies and gives the room the space; any sticky brings it back; the choice lasts the session.
- **Hover and go-to-definition:** hovering a name shows an editor-style card: kind, signature and type, a line from the API reference, what it holds (a list's items with indexes) and where it is set. Ctrl+click goes to a variable's definition (and selects it) or pins an API name's card. Answers come from `CodeLookup` (program text, `ApiReference`, the link's lamps), preferring the last debug run's values.
- **VARIABLES tree:** lists open with ▸ to show `[0] Lamp('landing-lamp')` and so on; a name goes to its definition. After Apply it shows the program's final values.
- **Debug:** the key is Debug with a play-and-bug icon (also F5); while a run shows, the status bar is orange, "Debugging · ghost in the room". Guidance, lesson and hint text on the job pages say Debug. The first greeting at the desk terminal still says Test.
- **Finishing:** a run that would finish the job says so in green and makes Apply glow. When Apply finishes the job the keys give way to one **Job done · put the slate away** key (green status bar, a ✓ in OUTPUT), which closes the slate so the story continues.
- **Checks:** `test/test_ui.gd` covers the lookups (expression under the pointer, definitions, types, list items, members through indexes, keywords, debug values winning); the workshop play-through checks the Job done key, put away and back, and go-to-definition.
