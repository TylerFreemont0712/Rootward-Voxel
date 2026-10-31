# Tablet screen, VS Code editor and blue ghost text — 2026-10-30

Slice 1 of [the quest line and tablet plan](../../docs/concept/v0.7/10-quest-line-and-tablet-plan.md), plus a small request the user made while it was in progress. Reviewed in Godot at 1600×1000 with `tools/tablet_review.gd`; frames are written to `.cache/tablet/` (not committed).

## What changed

- **Code is on glass.** The greeting page and every job page put their editor on a `TabletScreen`: file tabs, the editor, an OUTPUT strip and a status bar in VS Code Dark+ colours (`ui/code_palette.gd`). Job pages use the field slate; the greeting uses the loft desk terminal. Names a program makes up (`lamp`, `lamps`, `world`) are coloured as variables. The loop example in the morning-round guide is a read-only code block in the same colours.
- **The tablet is always whole.** It sits below the scrolling paper instructions rather than inside them, so a long page (the morning round) no longer pushes the editor and output off the bottom.
- **Replay is a debugger.** The executing line has VS Code's yellow highlight and a gutter arrow; any values the line worked with are written dim at its end. The caption reads `Line 3`, with values only when there are some.
- **Ghost text is blue.** A Test's speech is a translucent ice-blue bubble with a dashed outline whose dashes march, a breathing glow, thought-dots, a `TEST · GHOST` caption and a gentle bob, its newest letters fading in. Real speech is unchanged. World proposals (lamp glass, ghost boxes, bridge decks, gates, routes of builder previews) are the same blue, outlined, with coral for removal.
- **Lower-right hint removed; chat box extended.** The Sparks HUD no longer draws the "WASD walk · Click to travel …" card, which sat half under the story window. The portrait chat window now runs from just right of the HUD buttons to the right margin; the player's portrait is kept on screen.

## Not changed on purpose

- A previewed lamp still lights its fixture at reduced strength. The plan's "a ghost lamp does not light the room" lands with slice 3, when lamps become the room's light.
- Slices 2–5 (waking scene, lamplit rooms and lamp placement, the lamp commit beat, "Again?") are untouched.
- The archived journeys keep `CodeEditor`'s palette, the teal replay highlight and their own controls hint. The world-preview materials are shared, so their Test previews (and the builder's code previews) are blue now too.

## Checks

`test/test_ui.gd` gained 8 checks (variable colouring, Dark+ colours, tabs, output and status, terminal casing, the ghost frame); `test/test_sparks.gd` checks the story window's right edge on every page and that the Sparks HUD has no controls card; `test/test_workshop_quests.gd`'s text search now also reads code blocks. The full `scripts/test.sh` result is recorded in the session summary.

## Open for the user

- The ghost blue (`PaperPal.GHOST`, `#4aa8ff`) and the slate's bezel colour are first picks; say if they should move.
- The story window leaves the HUD buttons clear on the left (`HUD_CLEAR_LEFT`). If you would rather it span the whole width, the HUD buttons need to hide during a scene.
