# Next outdoor quest — A proper welcome

Implemented first pass · 2026-11-02 · Chapter 03, after the existing three-light morning round.

This continues the [opening storyboard](storyboard.md). The user proposed a neighbour coming out of the fenced house and a programmable welcome sign at the tram stairs. This document develops that option, with alternatives and the actual work it needs. The sign, Iona, Braum’s entrance, conversations, finite print card, payments and property systems are now implemented. Alternatives and later follow-ups below remain proposals. See the [delivery review](../../../pipeline/reviews/2026-11-02-welcome-quest-and-property.md) and [property contract](../../../pipeline/PROPERTY.md).

## The options

| Quest | What the player does outside | Reinforcement / next idea | What it needs |
|---|---|---|---|
| **A proper welcome — recommended** | Meet Braum at his garden gate, walk to the tram landing, help a signmaker install a repeating two/three-message welcome | `print`, strings and the existing `for` pattern; optional introduction to making a list of strings | New sign and display rules, Iona's character art, Braum entrance/conversations |
| **On means on** | Meet Braum, inspect the existing gate lamp, replace an instruction that toggles it with one that leaves it on | `True` revisited, then reading `lamp.lit` and a simple `if`; correct twice is better than lucky once | Existing lamp/model, a once-only quest setup that starts it lit, NPC scene and new goal/tests |
| **The collection notice** | Carry a request to the existing postal box and write a small readable notice for its two collections | Strings and multiple output lines in a new context | Notice holder/output surface; postal inspection/dialogue. Programmable parcel inventory/routes would be separate work |

Build the sign as one main quest. Save the gate-lamp condition lesson for afterward, rather than requiring another single-lamp tutorial before anyone can reach the sign. Its old “Again?” complaint remains useful for the developing supply mystery. The sign is a fresh success with room for personal expression.

**Name:** the user used **Braum**. Use that display name in this draft for the established carpenter/neighbour; the sprite id is now `sparks_braum` (2026-11-07) and identity. Do not create a second almost-identical carpenter or rename resources as a side effect of this proposal.

## What makes this a quest

**Braum's want:** finish the landing he promised the tram staff, and get people using it before another neighbour asks whether it is ready.

**Iona's want:** deliver a legible sign on her first powered-display commission. She can paint, mount and lay out a sign. She asked Nell to do the routine because that is a different trade.

**The player's job:** make the new display show more than one message, put their own words into it, and leave a working installation behind.

The public result is the reward. A returning tram group passes the sign; it keeps cycling after the player puts the slate away and comes back. Braum introduces the player by name at the end. There is no new money, reputation bar, timed payment or inventory reward required for this slice.

### Learning boundary

The workshop already teaches a loop over lamps. This quest transfers that pattern to text and optionally shows how to create a list with square brackets. It does not introduce `while True`, sleeping, event handlers, live timetable data and formatting expressions in the same exercise.

Two or three ordinary `print()` calls are a valid solution. A list plus `for` is another valid solution. The goal checks the installed messages, not whether the source contains a particular keyword.

## 03.01 · Someone at the garden gate

[PLACE · Spindle Lane, outside the workshop. Braum exits the fenced house/garden onto the lane. Use the existing carpenter identity; no house interior is necessary for an exterior entrance.]

[TRIGGER · First suitable visit after `morning-round` has actually completed and the player carries the slate. This is a new proposed encounter, not an existing ambient route.]

[STAGE · Open the small garden gate, walk Braum along an authored reachable route, then let him call from nearby. He must not emerge through a solid fence or wall. His exact threshold and safe stopping cell must be established from the area collision and model in Godot. Do not confuse his garden gate with the working town-stair gate.]

[STAGE · Wait until the player has finished any step and no editor, dialogue or transition owns input. Stop short of the player; do not push them or chase them through stairs. Show a speech mark. A short call can invite interaction; opening a long conversation should wait for the player's response.]

**Braum:** You there. From Nell's, are you?

**You — A:** I'm staying upstairs.

**Braum:** Thought so. Saw your bag go past last night.

**You — B:** Depends what needs fixing.

**Braum:** Nothing I've built. The new sign. Well, the talking part of it.

**You — C:** Is something wrong?

**Braum:** Not wrong. Waiting. There's a difference, though Iona's stopped agreeing with me.

[JOIN · All branches continue.]

**Braum:** Braum. Next door. I've put a new frame up by the tram steps. Iona's doing the sign.

**Braum:** She wanted Nell for the message card. You've got her slate. Would you have a look?

[CHOICE · Accept or defer; neither answer invents an employment contract with Nell.]

| You | Braum | Result |
|---|---|---|
| I'll take a look. | Good. Up by the shelter. Mind the fresh edge on the step; it's sound, just sharp. | Offer the tram landing destination; Braum walks there at normal pace. |
| What does the sign need to do? | Say where we are. Then a couple of useful things. It currently says where we are very firmly. | Follow with the same accept/defer choice. |
| Later. I've something to finish. | Right. I'll be up there. The frame won't wander. | Leave an available quest mark at the landing; no penalty or repeated intercept. |

[PRODUCTION · “What does it need to do?” can be a short topic followed by a fresh choice page, not a fourth button. Existing authored conversations support three options per page.]

[PIN]

> CHAPTER 03 · A proper welcome  
> **The sign at the tram steps**  
> Meet Braum and the signmaker beside the tram shelter.  
> Familiar code · Words and repetition

## 03.02 · A signmaker, not a programmer

[PLACE · The landing beside the tram approach and shelter, not the tracks or the downhill town gate. The sign faces the arriving pedestrian approach. Iona is checking its viewing angle. Braum leaves her room to work.]

[ART · New story character **Iona Venn**, signwriter. Her biography and voice are in the [character guide](characters.md). A tool roll and modest open maintenance cover establish the work; do not permanently block the stairs with a large construction site.]

**Braum:** Iona. Found someone from Nell's.

**Iona:** Did she send you?

| You | Iona |
|---|---|
| Braum asked me to have a look. | Fair enough. Come round this side. You can see it better from here. |
| I've got her slate. | That's the plug I was waiting for. Come round this side. |
| I've only done the workshop lights. | Then we'll try it before we leave anything running. |

[JOIN · All branches continue.]

**Iona:** Iona Venn. I painted the old board. This one's got a message card instead of a second coat.

**Narrator:** The glass reads WELCOME TO SPINDLE LANE. After a moment, it reads WELCOME TO SPINDLE LANE again.

**Braum:** It's welcoming. Can't fault that.

**Iona:** It's meant to change. The name first, then something useful for the people getting off.

**Iona:** Two or three messages. Leave each one up long enough to read. You can choose the last one.

**Hotaru:** Where does the next one go?

**Iona:** On the card, I hope. That's the part I asked Nell about.

[UI · New sign access page: **Tram welcome sign · Connected display**. The slate plugs into a service socket. Pairing/plugging is at this sign; this does not create remote access to every display in town.]

[NOTE · Make this two short conversations if page count would exceed the existing 12-page scene limit once response/rejoin pages are mapped. Braum can introduce Iona, then step aside; subsequent help comes from Iona.]

## 03.03 · The first card

[CODE SIGN.STARTER · Player starter; a valid single-message card that leaves the quest incomplete

```python
def program(world):
    print("Welcome to Spindle Lane")
```

]

[UI · Notebook: “Each printed line becomes one message on this sign's card. Your program runs once. The sign repeats the card after you apply it.”]

[STAGE · Debug previews exactly one message. It must not invent a second screen because the quest expects one. Show **1 message · the sign repeats this page**. A successful program with an incomplete job is distinct from a syntax error.]

[CHOICE OF SOLUTION · Offer these as progressively requested help. They are not mandatory dialogue choices.]

[CODE SIGN.DIRECT · Straightforward reference solution, reusing the first lesson

```python
def program(world):
    print("Welcome to Spindle Lane")
    print("No. 7 stops here")
    print("Please mind the step")
```

]

[CODE SIGN.TWO · Two messages are enough; no hidden requirement for exactly three

```python
def program(world):
    print("Welcome to Spindle Lane")
    print("Please mind the step")
```

]

[UI · Once multiple pages work, offer “Try the loop you used in the workshop” as an optional practice view. Introduce one new representation: a list made from strings. Keep the same names and indentation pattern as the lamp example.]

[CODE SIGN.LIST · Optional reference using a list of strings and the familiar for loop

```python
def program(world):
    messages = [
        "Welcome to Spindle Lane",
        "No. 7 stops here",
        "Please mind the step",
    ]

    for message in messages:
        print(message)
```

]

[UI · Explanation: “Square brackets collect the messages into a list. `for message in messages:` takes one message at a time. The indented `print(message)` puts each one on the card.”]

[CODE SIGN.CUSTOM · Example of a player choosing their own last page

```python
def program(world):
    messages = [
        "Welcome to Spindle Lane",
        "No. 7 stops here",
        "Tea first. Tram second.",
    ]

    for message in messages:
        print(message)
```

]

[STAGE · Retain case, punctuation and message order. Player text is plain text, never interpreted as UI markup. The examples are suggestions, not passwords. Do not reject a valid card because it says something other than the suggested welcome or because the player used repeated calls instead of a loop. The physical sign can have a permanent stop-name plaque so identification does not depend on the custom content.]

### Feedback and hints

| Result | What happens |
|---|---|
| One message | Valid preview/card, job still open: “This card has one message. Add another printed line.” |
| Two or three distinct messages | Preview cycles the exact pages, with a visible page count and Next page control. Ready to Apply. |
| Repeated identical messages only | Display the actual result; explain that there is still only one distinct message. No source-text guessing. |
| Blank/too-long message or more than three pages | Name the offending message/count and the supported limit. Reject the replacement as a whole; keep the previous real card. |
| Syntax error | Existing editor line/error help. The working sign does not go blank because a draft failed. |
| Endless `while True` attempt | The sandbox limit stops it. Explain: “Print each message once. The sign repeats the finished card.” |
| Debug a good card, then edit/step away | Clear the proposal; keep the draft. Reconnect and Debug before Apply. |
| Apply | Replace the sign's real card with the exact validated preview; cycle independently of the editor or Python runner. |

Hints: (1) “What happens if you print a second line?” (2) “Each printed line is another page on the card.” (3) Offer the direct-call example. The list/loop page is useful transfer practice, not a gate hiding the simplest answer.

## 03.04 · Read it from the steps

[STAGE · Apply commits the playlist. Keep the slate near the service point for the actual write; then put it away. Let the player walk down/up the approach and see the messages from where a passenger would stand. This is the second useful movement within the quest, not another menu confirmation.]

[GOAL · Two/three distinct valid messages installed. A short “view from the approach” beat can be an inspection/discovery after installation, without making the player wait for a particular tram or a full real-time cycle. A Next page control on inspection makes reading accessible.]

**Iona:** Hold there. That's where you first see it coming up.

**Narrator:** The first message gives way to the next. Braum reads it with his head tipped back.

**Braum:** There. Even I know which stop it is.

**Iona:** You're standing under the nameplate.

**Braum:** Helps.

| You | Iona |
|---|---|
| Is that slow enough? | I can read it before it changes. That's what I needed. |
| I put my own words on the last page. | Good. Anyone waiting here will have time to read them. |
| It keeps going after I put the slate away? | That's the idea. Come past tomorrow; I don't want to be here pressing anything. |

[JOIN · A modest acknowledgement, not generic praise or a speech explaining loops.]

**Braum:** What was your name, then?

**You:** {player_name}.

**Braum:** Right. I'll tell Nell. Can't keep calling you the one with the bag.

[UI · Job DONE. The sign remains editable and saved. If the player changes the card later, use the same validation/preview rules without replaying the introduction and first-completion scene.]

[OPTIONAL · The next ordinary tram group walks past using existing ambient behavior. A nearby passenger can pause and look if authored later; no extra NPC crowd, guaranteed schedule wait or new travel destination is necessary for completion. Do not pretend the text is a live timetable: “No. 7 stops here” is a route notice, not a countdown.]

## Technical boundary — implemented display context

The sign uses an exclusive `display_sink` snapshot while its own editor is open. Ordinary Hotaru print behavior remains available in its own context. `core/display_cards.gd` validates the returned replacement command; the presenter cycles the installed pages independently of Python.

Implemented contract:

1. Add an area-owned display definition and physical approach for `tram-welcome`. Reuse the carried slate and range/visited-place rules. Do not scatter layout/collision constants through UI code.
2. A sign-run snapshot declares this specific display as the permitted output sink. The sandbox's sign-context `print` records ordered messages separately from ordinary stdout and speech. Preserve ordinary `print` formatting: completed logical lines become pages, including explicit newlines, rather than treating each printed argument as a page. A normal final newline is a terminator, not an extra blank page. It must not grant a general write-to-any-device capability or send simultaneous greetings to Hotaru.
3. After the finite program returns successfully, form one typed replacement command, for example `set_sign_messages`, with `target: tram-welcome` and the whole message list. The core validates target, context/reach, item requirement, message count/types/length/layout constraints and the current mounted device. Writing text does not move a character or occupy another cell; the sign's physical footprint is checked by the area, and its interaction point must stay reachable.
4. Permit a safe one-page card so the starter is valid but incomplete. Limits: one–three nonblank pages; a maximum of 32 characters per page, with deterministic wrapping into two rows of 16 character cells in a fixed-advance font. Test actual font coverage and native readability before finalizing those numbers. Do not quietly truncate or replace player words to make them fit.
5. The quest goal requires two–three distinct installed pages. It checks committed world data, not source syntax or prescribed words. Host/core validation still applies even if player code fabricates a raw command or edits its own Python objects.
6. Debug remains a detached card with manual Next/Replay and an obvious ghost indication. Apply commits that same proposal atomically. Edits, motion, context changes and travel invalidate it. Raw stdout/error text is not trusted device content; the existing result framing and core checks remain in force.
7. Save the installed messages and editable source with the area/journey. A lightweight presenter cycles the committed pages every roughly four seconds, resetting its cosmetic phase on re-entry if convenient. It never repeatedly runs Python, holds a worker alive, performs `sleep`, or saves every visual tick.

Limits are one to three nonblank messages, each at most 32 characters from printable ASCII or Latin-1 (excluding control characters). Two distinct messages complete the goal. Text wraps deterministically into two rows of 16 fixed-advance character cells; overlong/unsupported output gives an explicit error. The sign uses the same JobsJournal slate, notepad, Dark+ editor and line debugger as the light jobs. Its card readout includes a Next page button. The slate sidebar can be dragged, folded or hidden with Ctrl+B.

### Art and character work

- **Tram welcome sign:** new adopted world asset, cream enamel/brass with a dark glass message face and warm, high-contrast lettering. Match the workshop terminals and seaside street, with a small maintenance lid and slate socket. A static stop-name plaque and a two-row changeable face keep it useful with any custom text. No modern neon advertising wall is needed.
- **Placement:** beside the tram stair landing/shelter, facing the pedestrian approach. Keep clear of tracks, the tram's movement envelope, passenger arrival cells, handrails and the ordinary path to the workshop. The current `tram-halt` inspection approaches `[18, 2]`; this is a reference for locating the work, not an approved new sign footprint.
- **Readability proof:** actual 1600×1000 and 1280×720 camera views, at the normal camera scale, with the longest allowed page. Make the physical panel/text layout readable from the approach before adding decorative detail. Also provide a nearby inspection view with current message, page navigation and the full card. Inspection supports the sign; it must not be the only place its lettering exists.
- **Braum:** reuse the established `sparks_braum` appearance. Author his entrance/gate presentation and a portrait matching his selected clothes if the existing portrait does not. Preserve the old masters and IDs. No new motion template is needed.
- **Iona:** a new shared-frame skin, full-body conversation portrait, prompts/provenance and catalog entries through the existing art build. Cropped dark curls with a silver forelock, blue work apron, bone-coloured paint marks and a narrow rolled smock distinguish her from Nell, Mira and Tessa. No one-sided writing on clothing that would break mirrored frames.
- **Work dressing:** one restrained tool roll/paint pot/temporary trestle group if useful. Reuse suitable existing props; no new house interior or wholesale tram-station rebuild is required.

World-art work goes through [asset requests](../../../asset-requests/README.md) and the existing world build. The sign and garden hinge have asset-request records and delivered review artifacts. Character skins/portraits use their established catalogs. Human story participants also need a modest dialogue extension: `StoryScenes` now permits Braum and Iona as named speakers, switches their whole-body portraits and preserves the replying speaker and player name in the log.

## Build order and proof

1. Prototype a readable two-row sign and finite-message preview/commit/save rules. Prove at both resolutions with no new cast dependency.
2. Add the new character/art sources and safe garden-to-lane introduction, named-speaker dialogue and log support. Then build the complete one-quest route.
3. Add a reference solution and unchanged-starter proof in `test/test_area.gd`, plus pure validation tests and a native walk-through. Verify custom messages, repeat Apply, empty/oversized/wrong-target/out-of-range commands, interrupted dialogue, stale previews, switching between Hotaru and sign contexts, Continue and return visits. The wrong final message must reject the whole proposed card without destroying the existing one.
4. Extend F8 with start/end/reference completion only once the quest and its real goal exist. Existing regular saves and earlier quests remain intact. Run `scripts/test.sh` and review the actual walk/lettering before calling it finished.

### What comes after

Use the returned gate-lamp ticket for a short **state / if** lesson after this quest. Braum has already lit it by hand; the old “flip the switch” routine turns it off again. Compare that with an instruction that leaves it on, test twice, then investigate why different addresses keep receiving replacement fittings. This leads naturally toward the guildhall service room and shared-supply story.

Do not have the welcome sign mysteriously lose the player's saved messages to foreshadow an outage. Future power problems can dim a known branch while its program/data remain correct, once those supply rules and observations actually exist.

## Design checks

The five bracketed programs were run through the existing CPython/WASI runner with ordinary print output enabled: **20 checks passed**, including exact output order, two- versus three-page examples, custom text and the proposed character budget. This verifies finite Python output only; it does not test a sign command, quest goal or asset that does not exist yet. Local scratch runner/output: `.cache/storyboard-v08/outdoor-check.gd` and `outdoor-examples.log`. Player source was not executed by host Python.

The implementation now includes all four build steps, with a real WASI reference in `test/test_area.gd`, pure display/account tests and a native complete quest/banking tour. Exact verification and captures are in the [delivery review](../../../pipeline/reviews/2026-11-02-welcome-quest-and-property.md). First completion pays 25 p; Iona gives one reusable message card. Existing paid light jobs receive 6 p and 12 p. Home building costs, passive income, shops and the later power-source quest remain future work.

The active layout now places the sign west of the tram steps on the upper pedestrian paving. Braum and Iona stand beside it; lamps guard both ends of the waiting area and Wick checks both. [Shared-slate and layout follow-up](../../../pipeline/reviews/2026-11-02-tram-stop-and-shared-slate.md).
