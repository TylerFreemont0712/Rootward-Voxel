# Nell's field slate — interface frame concept v1

Selected output: `nells-field-slate-frame.png`, an unchanged built-in imagegen result, copied to [concept v0.73](../../../../../docs/concept/v0.73/art/nells-field-slate-frame.png). The canvas is 1024×1536 RGBA with real exterior transparency. This is a visual concept, not a runtime-selected nine-slice resource.

The user requested warm cream enamel `#EFE3C6`, a teal `#2F8C8C` outer band, brass `#C99A3E` inner bead, four guards with two rivets each, a top-left jack socket and unlit lamp, a black recessed screen, and a deeper blank lower ledge with one pressed groove. A fine warm-brown outline and gentle corner wear suit Sparks & Machines' paper/enamel/brass interface. No perspective, controls, lettering or modern phone details.

- `prompt.txt` → `initial.png`: initial painted study; oversized upper/lower bands.
- `refinement-prompt.txt` → `refinement.png`: targeted edit, with the initial PNG as the edit target; cleaner straight edges and a reduced upper band.
- `layout-prompt.txt` → `nells-field-slate-frame.png`: a fresh generation emphasising the narrow upper strip and larger black screen; selected concept.
- `generation.json`: exact prompt/output hashes, original generated paths, image sizes and measured alpha/screen pixel statistics. The model identifier and seed were not exposed by the tool.

No pixels were changed after generation. The selected PNG's four exterior canvas corners are alpha 0. Screen RGB varies, and its generated alpha includes near-transparent pixels and reaches only 254; it is **not yet an exact opaque `#000000` screen fill**. Border and corner measurements also remain approximate. These need deterministic production cleanup before use as the live screen's nine-slice frame. The dark-navy `#1E2A33` mentioned in the brief is the intended game backdrop, not an added background layer.

Validation was limited to concept-image inspection, dimensions, PNG mode/transparency, source-copy hash equality and documentation links. No game code or runtime art was changed, so no new Godot play-through or full test run was needed for this concept save.

**Selected for runtime, 2026-10-30.** The user asked for this frame in the game. `nells-field-slate-frame.png` stays unchanged; the production cleanup the notes above call for happens in the build (`pipeline/interface_frame_builder.gd`, run by `scripts/art.sh`) from measurements pinned in `pipeline/art-catalog.json` (`interface_frames.nells-field-slate`): crop `[22, 23, 980, 1476]` to the casing; nine-slice margins `[220, 110, 110, 259]` (left, top, right, bottom, in cropped pixels, so the corner guards, jack and lamp never stretch); inner window `[78, 92, 824, 1144]`, filled with opaque `#000000` including its near-transparent pixels; jack centre `(136.5, 52)` radius 15 and lamp centre `(201.5, 50.5)` radius 12.5; transparent pixels' matte cleared; Lanczos to 50% (490×738). The runtime PNG and manifest are in `assets/ui/nells-field-slate/`.
