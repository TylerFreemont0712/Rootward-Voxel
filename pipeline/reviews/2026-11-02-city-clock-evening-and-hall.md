# Shared city clock, closing round and City Hall

2026-11-02–03 · Sparks & Machines · three requests delivered to Finished; user acceptance pending.

## Delivered slice

- Saved journey-wide clock, 24-minute exploration days, phase/orbit HUD, gradual dawn/dusk lighting and a first-evening story hold. Reading/code/dialogue/travel pause the clock. The hall’s original clock hands follow it.
- Shared saved supply pressure: normal 5.6; green below 8, amber 8–9, red at 9+. The Rootwell face stops at 10 and flutters above it; the loading meter reads through 15. An overload at 15 trips a latched breaker. Street lights and conduit/column glow lose supply. The source chamber retains its own glow. Supply controls remain outside player Python.
- 148 mapped logical fittings cover every placed lamp-glass / festoon-glass asset, including bedside, shops, Rootwell and surrounding houses. Background/large building lanterns are addressed from the district service screen, without inventing off-map walking cells. Hidden cosmetic lantern parts do not produce floating halos or light sources. The early workshop lessons retain their manual lamp behavior.
- Chapter 04, **After the light**: Nell walks home; both shop relays have the wrong conditional. Actual Python runs in the existing WASI worker for daylight and darkness. Debug proposes; Apply installs both decisions; Undo restores them. Both correct routines plus Nell’s accepted ticket complete the job and pay 18 p once.
- Real saved robot settings for pace, pause/resume and ordered authored service stops, using the same slate, preview and atomic rules. Worker rounds follow ordinary legal paths; pausing the lane’s first worker leaves the tram/passenger service clock running. This is not a general autonomous-repair system.
- Enterable city hall: removed outside counter, two hinged oak leaves, original hand geometry separated for the clock, a large independently saved 28×22 cutaway lobby, enquiries, a Public Works desk opening the existing job ledger, waiting/archives and programmable pendants.
- Loading train drop shadows removed, heading/meter/caption separated; F8 adds Chapter 04, City Hall, clock phases, pressure and explicit breaker reset, with scrolling controls at small resolutions.

## Sources and boundaries

Adopted masters `square-guildhall` and `rootwell-beacon` were deliberately edited with preserved backups, source records and hashes. Three new saved masters are `city-hall-shell`, `city-hall-help-desk`, `city-hall-job-desk`; normal world-art builds exported/audited each. Existing painted civic materials and approved furniture are reused. The character template, approved boy artwork and camera heading/elevation are preserved. No new runtime service, provider, engine, combat or paid asset dependency was introduced. No regular player save or sibling project was edited; tests/review use fresh or isolated temporary save paths.

`core/city_cycle.gd`, `core/lamp_programs.gd`, `core/robot_programs.gd` own plain-data rules. The app owns timing, WASI sequencing and story staging. The view presents their decisions. District mappings, service approaches and reciprocal entry cells live in the area documents.

## Verification

**Full `scripts/test.sh`: exit 0, Godot 4.7.2.** Focused city tests: **331 checks, 0 failures**; actual runtime fixture audit: **597 checks, 0 failures** across all 148 bindings, illuminated materials, hidden-geometry preview halos, visible fixture light and real breaker shutdown; ordinary quest/property flow: **43 checks**; programmable town life: **2422 checks**; square: **280 checks**; transitions: **47 checks**; development tools: **81 checks**. World-art audit: **949 checks**; protected authoring: **11 checks**; asset workflow: **11 tests**; handoff links: **1551 checks**; ground-art handoff: **121 checks**. `git diff --check` is clean. Focused checks cover genuine WASI if/else trials, reversed/missing branches, access rejection, atomic robot commands, physical programmed stop order, restore/Undo, safe malformed settings, every placed lamp-glass mapping and service/door reachability. The central `test/test_area.gd` contains the new quest’s starter/reference proof.

Native Godot review passes **23 checks at each of 1600×1000 and 1280×720** and exercises Nell’s moving gait and F marker, the real slate preview/apply, the shared pressure instruments, overload, actual hall entry/return, both desks and the expanded development panel. Evidence: [1600](../../evidence/city-cycle/1600/09-city-hall-lobby.png), [1280](../../evidence/city-cycle/1280/09-city-hall-lobby.png). The larger run uses native X11/llvmpipe in a 1920×1200 virtual display to retain the requested window height; the smaller run uses the desktop GPU. Loading, night, pressure and desk captures accompany them. `tools/reviews/city_fixture_audit.gd` constructs each of the five real area views and inspects every actual binding after a normal frame, then trips the supply and inspects their real lights.

A separate native loading study checks 5.6 (green), 8.5 (amber), 9.5 (red), 12 (pegged instrument range) and 15 (offline, with its numerical reading retained), using the same saved-power interface.

The slate restores up to 256 valid pages, retaining existing drafts rather than dropping the whole collection at the former 16-page limit; 32-page JSON round trips and oversized-collection handling are verified.

The command budget is now 128, retaining bounded atomic proposals while allowing a whole district’s connected lamps in one loop. Boundary and playback-metadata tests check the new maximum and reject the first value beyond it. Fixture binding uses an indexed mapping and presents loading frames between fittings.

## Deliberate next work

Public Works currently lists existing tickets; new civic orders and a staffed clerk are not implemented. Lamp controllers are finite day/dark decisions, not arbitrary persistent Python or minute-by-minute scheduling. Workers expose route/pace/running controls; fault-specific repair actions remain a future quest/API slice. The city-source failure storyline, player pressure controls, house purchases and passive income remain future work.
