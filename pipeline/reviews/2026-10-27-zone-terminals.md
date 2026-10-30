# Reusable zone computers — 2026-10-27

The loft and workshop now use the same outlined cream-and-teal computer: a recessed glass screen, physical keyboard, connection lamp, side vents, docking port and rear power lead. The old typewriter masters remain as historical source; their tape spools, feed and loose output sheet are no longer selected in these rooms. The hand console remains a smaller portable companion to the fixed computer.

A fixed terminal connects one authored zone. Its screen names that zone; the editor shows the same connected name. Test displays actual greeting output on the glass and in the world bubble, while Send message delivers the greeting to Hotaru. Lighting tests show their proposed light count on the workshop computer. Using a new fixed terminal records its link; the hand console can reuse that connection while in the room. Entering a zone alone does not connect it.

`AreaDef.terminals` owns each terminal’s id, title, placed model, zone and approach cell. The declaration can reference a room asset or a placed prop, and must use a model registered as a terminal. `ZoneTerminals` validates physical range and prior visitation; player Python cannot forge a connection command or grant it through memory. The normal WASI snapshot and core lamp/gate/bridge/working-prop validation use the same connection boundary. Areas without terminal declarations keep their existing discovery rules. Terminal links save separately per area and remain through Undo and Reset. Earlier visited-room saves preserve earned access when migrating from saves without terminal-link data.

The new editable [computer master](../../art/source/world/zone-terminal/v1/model.blend), [guarded authoring record](../../art/source/world/zone-terminal/v1/author.py) and [provenance](../../art/source/world/zone-terminal/v1/provenance.json) use native Blender geometry and the existing palette. Export through `scripts/world-art.sh build zone-terminal`; the runtime has no Blender or network dependency.

The focused terminal rules suite covers range, independent zones, command rejection, atomic batches, saved links, model validation and Undo. The existing first-morning and workshop playthroughs cover the click/F interactions, connection guidance, screen output and Continue. Gameplay-size evidence is under `evidence/sparks-workshop/zone-terminals/`.

| In-game view | Capture |
|---|---|
| Shared computer on the loft desk | [1600×1000 loft](../../evidence/sparks-workshop/zone-terminals/1600/03-loft-before-note.png) |
| Actual greeting on the glass and in Field Notes | [Live output](../../evidence/sparks-workshop/zone-terminals/1600/06-test-tape.png) |
| First connection at the workshop | [1280×720 connection card](../../evidence/sparks-workshop/zone-terminals/1280/workshop/03b-zone-connection.png) |
| Same computer with a workshop lighting test | [Connected workshop](../../evidence/sparks-workshop/zone-terminals/1280/workshop/04-lantern-preview.png) |

The audited world build and complete `scripts/test.sh` passed. After the gameplay review, the focused checks passed again: 25 terminal rules, 151 area/reference-solution checks, 103 first-morning checks, and 74 workshop-story checks. Native runs reviewed both rooms at gameplay scale. The terminal source remains unchanged by the audited export.
