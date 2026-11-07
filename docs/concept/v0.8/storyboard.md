# Sparks & Machines — v0.8 storyboard

**Chapter 00 · A first hello**  
**Chapter 01 · A place at the bench**

Editorial draft · 2026-11-02 · Based on the playable loft, workshop, Spindle Lane and Rootward Square.

This is the proposed script for the next content passes. Dialogue and screen copy below are written out for review. Existing features and proposed changes are distinguished in the production notes; this file does not silently change runtime dialogue, saves or quests.

## 1. The shape of the opening

You arrived late, with a bag and an address. Nell has given you a room and gone out to work. Before meeting the rest of the town, you get someone’s attention, find the tool she left for you, and make one small part of her workshop useful again.

The first repair is ordinary. Nell has already replaced a damaged fitting; its instruction still asks for darkness. You change the instruction. Later, repeated complaints from different parts of town will suggest a separate problem in the shared supply. Local programs must visibly work before the story asks the player to investigate a larger fault.

The long thread is **the city’s power source is in trouble, and understanding and repairing its programs will help restore it**. These chapters establish the tools and a reason to care about the town. They do not let one lantern routine repair the Rootwell.

| Chapter | Dramatic question | Programming focus | Required place | Exit |
|---|---|---|---|---|
| 00 · A first hello | Who lives here, and what has Nell left me? | Change a string; `print()` displays and sends words | `workshop-loft` | Hotaru introduced; field slate collected |
| 01 · A place at the bench | Can I finish a small job Nell has left? | Find one object; call `set_lit(True)` instead of `False` | `workshop-floor` | Stair lantern really lit; next card introduced |
| 02 · The morning round | Can the same instruction serve several fittings? | Existing list/`for` lesson | Same workshop | Outside the scope of this full script; handoff included |

The target is roughly 8–12 minutes for each opening chapter, including exploration and experimentation. This is a pacing target, not a timer or a requirement to complete the code quickly.

### Reading the script

- **Narrator**, **Hotaru**, **You** and **Nell’s note/ticket** are the words the player reads. The player’s chosen name is used wherever `{player_name}` is required; “You” remains the dialogue speaker label. No fixed name or personal history is invented.
- `[STAGE …]`, `[UI …]`, `[TRIGGER …]` and `[JOIN …]` are authoring directions, not spoken lines. Each numbered dialogue entry is one page. A choice appears after that page has finished revealing.
- Code is enclosed in square brackets, starting with `[CODE …` and ending with `]`. Fenced Python inside is the actual source. **Starters** are shown to the player; **reference solutions** are author-facing unless a full hint is requested.
- **A / B / C** choices have their own replies and rejoin immediately afterward. None silently changes a quest result, grants an item or creates an unimplemented relationship statistic.
- **Existing capability** means the current game can perform the action. **Content revision** means this script changes its wording, timing or presentation. **Future dependency** means a new system or scene is still needed.

### Direction and tone

[STAGE · Keep the approved boy, normal orthographic camera, walking scale and paired dialogue portraits. The traveller stands at the right facing Hotaru at the left. Use the current larger Hotaru stage and raised dialogue box. No new character animation is required for the script.]

Nell is absent throughout both chapters. Her note, a stool pulled out from the bench and the prepared slate establish her care without a speech about it. Hotaru has been dozing during a quiet week, not broken for years. The player is an ordinary lodger, not a chosen operator or someone who needs code to gain the ability to speak or walk.

Hotaru is literal, observant and sometimes funny. She knows the workshop; she does not narrate every button press. Instructions, syntax and error explanations belong on the terminal/slate. A successful job ends with something useful in the room, rather than a lesson summary in her mouth.

## 2. Chapter 00 — A first hello

### 00.01 · First morning

[PLACE · Loft. Existing bed, desk, mug/note, terminal, bookshelf Hotaru and slate on the quilt.]

[TRIGGER · Begin a new journey after character naming. Existing opening-card presentation; three pages, then normal control.]

**Narrator 1:** You arrived after dark with a bag and Nell’s address. The key was under the third flowerpot, just as she’d said.

**Narrator 2:** You remember carrying your things upstairs. After that, mostly the bed. Now there’s daylight across the floor.

**Narrator 3:** A tram bell sounds below the windows. A corner of paper peeks out from under the mug on the desk.

[UI · Final action: **Begin the morning**. This replaces the misleading opening action “Open Field Notes”; the player first needs to find the note.]

[UI · Initial pin]

> CHAPTER 00 · A first hello  
> **A note under the mug**  
> Nell left a note on the desk. Walk over and read it.  
> First job · Words on the terminal

[STAGE · Release control beside the bed at the current spawn. Walking and click-to-walk already work. Show ordinary contextual F prompts; do not open a movement-programming lesson. The slate is visible but remains an unoffered room object until Hotaru mentions it.]

### 00.02 · The note

[TRIGGER · Reach `nell-note` at the desk and interact. Existing paper-note panel, not portrait dialogue.]

**Nell’s note:**

> Lodger —
>
> There’s bread in the tin downstairs. I’ll be back around lunchtime.
>
> The little one on the shelf is Hotaru. I’ve been out on calls all week, so she’s mostly been asleep.
>
> The terminal on the desk is linked to her message bell. Send her a hello if you need a hand.
>
> — N.

[UI · Action: **Put the note away**. Only this deliberate action records the note as read. Escape leaves it available. Its text remains in the story log.]

[UI · Pin after the note]

> CHAPTER 00 · A first hello  
> **Hello, Hotaru**  
> Use the desk terminal to send Hotaru a greeting.  
> Code · `print()` and words

[OPTIONAL · Terminal before the note: “There’s a note under the mug.” Leave the player in the room. Looking at Hotaru: “A little light behind dark glass. The rotor hasn’t moved.” Neither action awards the greeting.]

### 00.03 · Words on the glass

[TRIGGER · Use `desk-terminal`. Existing approach `[1, 8]`; no slate required. Connect the loft terminal and open Field Notes /00.]

[UI · Title: **FIELD NOTES /00 · Hello, Hotaru**. The terminal has **Blocks** and **Python** tabs. Default Blocks contains the editable words `Hello`; Python contains the complete starter below. Both produce the same real Python program.]

[UI · Paper directions]

> 1. Change `Hello` to a greeting that includes Hotaru’s name.  
> 2. **Test code** shows the words your program produces.  
> 3. **Send message** delivers the tested words to her bell.

[UI · Small note: “The quotation marks hold the words. Keep the spaces before `print`.” The `def program(world):` wrapper is supplied; writing a function definition is not the task here.]

[CODE 00.STARTER · Editable Python already on the terminal

```python
def program(world):
    print("Hello")
```

]

[PLAYER OPTIONS]

- **A · Test the starter first.** Output is exactly `Hello`. Blue ghost words appear beside the player; Hotaru remains asleep. Sending that message is allowed, but it does not complete the job.
- **B · Edit in Blocks.** Change only the message field. Switching to Python exposes the generated program; it is not a separate answer path or a simulated result.
- **C · Edit Python directly.** Change the string on line 2. The wrapper and indentation remain in place.
- **D · Close and explore.** Save the draft, return control and keep the terminal reachable. No test result becomes a fact simply because the panel closed.

[CODE 00.SOLUTION · One accepted answer; reveal only as the final hint

```python
def program(world):
    print("Hello, Hotaru!")
```

]

[UI · Hints, requested in order]

1. “Her bell listens for a greeting addressed to Hotaru.”
2. “Change the words inside the quotation marks on line 2.”
3. “Try `print("Hello, Hotaru!")`. Keep it indented under `def program(world):`.”

### 00.04 · What a test does

[STAGE · On a successful Test, display the actual returned text on the terminal and in the blue ghost print. Retain Replay and the real line trace. Do not substitute the reference greeting if the player wrote something different. No chime, awake state, DONE stamp or conversation yet.]

[UI · Valid result: **Test ready. Send message delivers these words to Hotaru.**]

[CODE 00.ALTERNATE_HI · Accepted alternative

```python
def program(world):
    print("Hi, Hotaru.")
```

]

[CODE 00.ALTERNATE_MORNING · Accepted alternative

```python
def program(world):
    print("Good morning, Hotaru.")
```

]

[STAGE · These alternatives get the same wake-up beat. Exact punctuation and the word “Hello” are not a password. The current greeting rule also accepts “Hey” with her name.]

| Player experiment | Visible result | Response / continuation |
|---|---|---|
| Test `Hello` | The actual word appears in blue | No wake-up. Hint points toward an addressed greeting. |
| Send `Hello` | The word is delivered; Hotaru stays asleep | Terminal: “Your message was sent. Include Hotaru’s name in a greeting to ring her bell.” |
| Send `Hello, Nell!` | Those actual words are delivered | Same rule; no fake reply from Nell and no quest completion. |
| Leave off a quotation mark | The program fails on the actual line | Mark that line; explain the missing closing quotation mark. Do not speak for Hotaru while she sleeps. |
| Use `Print` | The program fails | “Python treats `Print` and `print` as different names. Use lowercase `print`.” |
| Edit after a Test | Ghost/result becomes stale | **Send message** is disabled until a fresh Test. |
| Walk away or travel | Proposal clears; draft remains | Return to the terminal and Test again. |
| Reopen after success | Awake Hotaru; saved draft | Experimentation stays available; the first introduction is not awarded twice. |

[PRODUCTION · Feedback wording above is editorial copy. Underlying outcomes already exist; additional bespoke feedback should use existing error/status surfaces rather than create a portrait conversation for every mistake. More than one `print` must continue to display the actual lines in order.]

### 00.05 · The message lands

[TRIGGER · Send the same fresh validated proposal that contains an accepted greeting. Existing goal: `hotaru_greeted`; quest ID: `say-hello`.]

[STAGE · Keep the real delivered message distinct from the ghost. The terminal chimes; Hotaru’s existing face light and rotor wake. Let this be readable before the portrait exchange. This is a brief presentation beat, not another condition to solve.]

[UI · `Hello, Hotaru` becomes DONE only after sending. The first program/draft remains saved. The slate has not yet been collected.]

### 00.06 · A sleepy greeting

[SCENE · Reuse `loft-waking`; proposed six-page version. Two choice pages, each with three replies.]

**Hotaru 1:** Oh. Morning.

**Hotaru 2:** You’re the one in the loft, then? I’m Hotaru.

[CHOICE 00.A · After page 2]

| Option | You | Hotaru’s reply |
|---|---|---|
| A · Earnest | I got in last night. | I heard your bag on the stairs. I thought Nell was moving things again. |
| B · Wry | Have you been asleep all week? | Most of it. Nell’s been taking the calls herself. Is it still morning? |
| C · Direct | Nell said you could show me around. | Yes. She’s left you the desk, and something on your bed. |

[JOIN · All replies continue to page 3. Choices are ordinary conversation, not code the player has to write.]

**Hotaru 3:** The desk drawers stick a little. Lift them as you pull.

**Hotaru 4:** Nell came up again after you’d gone to sleep. The board by the bed always gives her away.

**Hotaru 5:** She left something on your quilt. Set down very square.

[CHOICE 00.B · After page 5]

| Option | You | Hotaru’s reply |
|---|---|---|
| A · Curious | What is it? | I can only see one edge from here. She’s put the interesting side down. |
| B · Wry | Is it going to bite? | It hasn’t moved all night. I’d have heard. |
| C · Direct | Did she leave instructions? | Only “there”. She says that when a thing is sitting right. |

[JOIN · Continue to page 6.]

**Hotaru 6:** Pick it up before we go down. There’s a work ticket waiting in the workshop.

[UI · Final action: **Back to the loft**. Finishing records the introduction; Escape is not completion. If interrupted, reopen the pending introduction without sending the greeting again.]

[UI · Pin after the completed exchange]

> CHAPTER 00 · A first hello  
> **Something on the quilt**  
> Nell left something on your bed. Take a look before going downstairs.  
> Hello sent · Collect Nell’s slate

### 00.07 · Nell’s field slate

[TRIGGER · Interact with `tablet` at its existing approach `[7, 8]`, now offered. Authored pickup grants `field-tablet`; hide the room prop and save the item. Closing the following conversation must not remove it or duplicate it.]

[SCENE · Reuse `tablet-taken`; four pages.]

**Narrator 1:** It is lighter than it looks. A grey cord trails from one edge and ends in a brass plug no thicker than a pencil.

**Hotaru 2:** Nell’s field slate. She used to carry it everywhere.

**Hotaru 3:** She’d hold it beside whatever was misbehaving and ask what the matter was.

[CHOICE 00.C · After page 3]

| Option | You | Hotaru’s reply |
|---|---|---|
| A · Curious | Did it ever answer? | Mostly it said “fault”, in capitals. Nell found that helpful. |
| B · Practical | Where does the plug go? | The screen downstairs. There’s a socket under the glass, with a brass collar. |
| C · Quiet | So it’s hers. | Was. She put it where you’d trip over it. That’s how she hands things over. |

[JOIN · Continue to page 4.]

**Hotaru 4:** A fitting answers if you’re close. The wall screen can reach the whole workshop.

[UI · Final action: **Back to the loft**. No forced teleport downstairs; the player walks there.]

[UI · Chapter 00 exit pin]

> CHAPTER 00 · A first hello  
> **Down to the workshop**  
> Take the slate downstairs. Nell’s ticket is on the board.  
> Hotaru awake · Slate collected

### 00.08 · Leaving the loft

[TRIGGER · Use the existing `downstairs` link through the central stairwell. Existing tread-following motion and clockwork veil carry the player to `workshop-floor`.]

[OPTIONAL · After Hotaru has offered the slate, trying the stairs without it gives the existing reminder: “Nell’s slate is still on the bed.” Do not imply a broken staircase or a power lock. Before the introduction, movement is already free; see the exploration rules below.]

[STAGE · Use the normal steady loading presentation. Waking Hotaru is not a city-power repair. No power meter fill or restored conduit is awarded for this chapter.]

[EXIT CHECK · `say-hello` completed, introduction finished, `field-tablet` carried. Narratively this completes Chapter 00. The current F8 `hello-end` checkpoint stops earlier, immediately after the greeting; the proposed chapter-pin/checkpoint alignment is listed in section 6.]

## 3. Chapter 01 — A place at the bench

### 01.01 · A stool pulled out

[PLACE · Existing workshop. Job board by the window, stair lantern, benches, stove, bread cupboard and wall screen. No new building or interior is required.]

[TRIGGER · First workshop arrival after Hotaru’s introduction. Reuse `workshop-arrival`; five pages. A player who explored downstairs earlier gets the scene on returning after the introduction.]

**Narrator 1:** A knot of shavings has collected beneath the vice. Beside it, someone has pulled a stool out from the bench.

**Hotaru 2:** Nell made room for you last night.

**Hotaru 3:** She was down here after you’d gone to bed.

[CHOICE 01.A · After page 3]

| Option | You | Hotaru’s reply |
|---|---|---|
| A · Curious | Where does she usually work? | At the long bench. Keep the narrow drawer clear; she opens it with her knee. |
| B · Wry | I didn’t hear a thing. | You were asleep before she’d found the spare key. |
| C · Direct | Is there anything I can do? | There’s a ticket on the board. She pinned it before she went out. |

[JOIN · Continue to page 4.]

**Narrator 4:** Hotaru looks back towards the stair lantern.

**Hotaru 5:** It was my job to put that on. I appear to have spent the morning on a shelf.

[UI · Final action: **Back to the workshop**. No automatic editor.]

[UI · Pin]

> CHAPTER 01 · A place at the bench  
> **The waiting ticket**  
> Read Nell’s work ticket on the board beside the window.  
> Job No. 1 · Find the work

### 01.02 · The waiting ticket

[TRIGGER · Stand near `job-board` and press F. Reuse `waiting-ticket`. The quest is an inspection, not a dummy Python task.]

**Narrator 1:** The ticket is soft along one edge. It has spent some time in a coat pocket.

**Nell’s ticket 2:**

> STAIR LIGHT  
> Relay replaced. Fitting checked.  
> Return to service before evening.  
> Address: landing-lamp  
> — N.

**Hotaru 3:** The glass cracked on Tuesday. Nell put it right yesterday.

[CHOICE 01.B · After page 3]

| Option | You | Hotaru’s reply |
|---|---|---|
| A · Curious | Then what’s left? | The instruction still asks for it to stay off. She left that part for you. |
| B · Personal | It was dark when I arrived. | She meant to have it done before then. |
| C · Direct | Show me where. | Beside the stairs. Bring the slate close enough for the fitting to answer. |

[JOIN · Continue to page 4.]

**Narrator 4:** There is a short card behind the ticket. Its other two names are repair-light and assembly-light.

**Hotaru 5:** Leave the stair light on. She’ll be carrying things when she comes back.

**Hotaru 6:** The lantern is on the wall beside the stairs. The new glass is the bit without paint on it.

[UI · Final action: **Find the stair lantern**. Completing the scene records `job-board` as read and finishes `waiting-ticket`. The destination prompt offers to walk to the fitting, or the player can close it and walk there. The actual code editor opens beside the lantern.]

[UI · Inspection completion copy: **Ticket read. Restore the stair lantern.** Replace the current “The fitting is repaired” wording: Nell repaired the hardware; the player has only read the instruction.]

[UI · Pin]

> CHAPTER 01 · A place at the bench  
> **The landing light**  
> Stand beside the stair lantern with Nell’s slate. Restore it before evening.  
> Job No. 2 · One object, one instruction

[PRODUCTION · The final action currently says “Open Field Notes” but leads to a destination prompt. The revised label should describe that immediate action. Escape before the final page does not finish the ticket; it remains available to reread.]

### 01.03 · Beside the fitting

[TRIGGER · Reach the existing `landing-lamp` approach `[5, 11]`. Carrying `field-tablet` and standing within the current physical interaction range permits the device page.]

[STAGE · The slate pairs wirelessly with the nearby lantern. Its cord does not run to the lamp. Only the workshop’s zone screen uses the physical plug. Keep the lamp in view through the current room/editor framing.]

[UI · Page: **landing_light.py**. Context: **Stair lantern · Nearby fitting**. The reached-jobs book keeps /00 available; opening this page does not replace the greeting draft.]

[UI · Notebook text]

> Nell has checked the fitting. The saved routine still asks it to stay off.
>
> `world.lamp("landing-lamp")` finds this lamp. The name `lamp` on the left lets the next line use that same object.
>
> `set_lit(True)` asks for light. `set_lit(False)` asks for darkness. Change the value in the marked line.

[CODE 01.STARTER · Editable Python at the stair lantern

```python
# landing_light.py
# Stair lantern: new relay, unfinished instruction.

def program(world):
    lamp = world.lamp("landing-lamp")

    # TODO: Nell wants the stair lantern left on.
    lamp.set_lit(False)
```

]

[UI · Actions: **Debug** and **Apply routine**. Plain copy: “Debug shows the proposed result. Apply routine keeps that tested result.” Highlight the TODO area; do not highlight the whole file as if every line needs rewriting.]

[PLAYER OPTIONS]

- **A · Debug unchanged.** A valid instruction requests off. The lantern remains dark; the result shows that the job is still open. This is a correct program with the wrong outcome, not a syntax failure.
- **B · Change `False` to `True`.** Debug shows the lantern’s blue proposed state. The real lamp remains dark until Apply.
- **C · Read the object names / hover information.** Use the existing reach/variables panels. Do not require a second, hidden device address.
- **D · Walk away.** Keep the source, discard the proposal and retain the unfinished ticket. Return beside the lamp and Debug again.

[CODE 01.SOLUTION · Reference solution

```python
# landing_light.py
# Stair lantern: new relay, unfinished instruction.

def program(world):
    lamp = world.lamp("landing-lamp")

    # Leave the stair lantern on for Nell's return.
    lamp.set_lit(True)
```

]

[CODE 01.ALTERNATE · Equally valid direct call

```python
def program(world):
    world.lamp("landing-lamp").set_lit(True)
```

]

[PRODUCTION · Accept the actual world goal, not a string comparison with the reference. A different local variable name, single quotes or the direct call above must not be treated as a wrong answer. The supplied `lamp = …` scaffolding can be explained in one sentence; assignment is not another mandatory exercise in this chapter.]

### 01.04 · A wrong instruction and a useful preview

[UI · Authoring target for an unchanged starter: **0 / 1 lights on. The stair lantern is still off.** The program ran; it did not achieve the ticket. A valid incomplete result may still be applied, following the current proposal rules, but it cannot award completion.]

[STAGE · A dark-state proposal need not invent a glowing ghost. Use the existing slate’s off state and result count. If a one-line Hotaru reaction is added later, use “It’s doing exactly what the card asks.” Trigger it once per distinct incomplete outcome, not on every Debug click.]

[UI · Requested hints]

1. “The last line asks for the lantern to stay off.”
2. “Look at the value inside `set_lit(...)`.”
3. “Replace `False` with `True`, then Debug and Apply routine.”

[CODE 01.WRONG_VALUE · Deliberate error example for author/review use

```python
def program(world):
    lamp = world.lamp("landing-lamp")
    lamp.set_lit("True")
```

]

[UI · Error explanation: “Use `True` without quotation marks. `"True"` is a word; this instruction needs a Boolean value.” Keep the actual engine error and line available. No lamp changes and no completion.]

| Situation | Result / recovery |
|---|---|
| `true` instead of `True` | Mark the real failing line; explain the capital T. |
| `lmap.set_lit(True)` | Unknown name; point back to the name `lamp` defined above. |
| Wrong lamp address | List the fitting actually in reach; do not let the code affect an unseen lamp. |
| Successful Debug, then edit | Clear the old ghost and disable Apply until a new Debug. |
| Successful Debug, then step away | Keep the source but invalidate the result. The fitting is no longer in reach. |
| Open this page from the job book elsewhere | Show the destination/place hint; do not grant remote access. |
| Apply a valid `False` proposal | Preserve a dark lamp and an unfinished job. There is no fabricated failure animation or penalty. |
| Apply `True` | Commit that exact validated proposal; only then light the real lantern and complete the job. |
| Run the correct program again | The lamp remains on. Do not replay the first-completion scene indefinitely. |

### 01.05 · Light under the rail

[TRIGGER · Apply the fresh successful proposal. Existing quest `landing-light`, goal `lamps_lit` for `landing-lamp`. Other workshop lamps remain in their current states.]

[STAGE · Put the slate away when the player chooses to return to the room. Show the actual committed light on the stair lantern and underside of the rail. The job stamp and Hotaru’s response follow the fact. Debug alone must never play this as a real repair.]

[PRODUCTION · Existing light/state presentation is enough. A later warm-up or conduit pulse can embellish it, but is not a missing gameplay requirement and must derive from the committed lamp state. Do not add a temporary outage that contradicts the successful routine.]

[SCENE · Reuse `landing-lit`; six proposed pages.]

**Narrator 1:** Light catches the underside of the handrail. The new glass throws a small square onto the stair.

**Hotaru 2:** There.

**Narrator 3:** She waits a moment, watching it. Then turns towards the benches.

**Hotaru 4:** Nell left the tables off while she was changing the fitting. We used to bring them on together.

[CHOICE 01.C · After page 4]

| Option | You | Hotaru’s reply |
|---|---|---|
| A · Curious | Which ones? | The long bench and the assembly table. The card has all three addresses. |
| B · Personal | Did you write the old card? | Nell wrote it. I used to read out the names while she checked them. |
| C · Ready | Let me try the rest. | I’ll stay by the table. It’s easier to see the glass from there. |

[JOIN · Continue to page 5. The player may be interested, but no choice switches the remaining lamps on.]

**Narrator 5:** The other card is headed OPENING ROUND. Under it are the same three lamp names.

**Hotaru 6:** That screen by the long bench reaches all three. There’s a socket under the glass.

[UI · Final action: **Find the workshop screen**. Finish the story scene, then offer the existing zone destination prompt. Let the player close it or walk to the screen. Do not put the new loop exercise in a character’s mouth.]

[UI · Chapter 01 completion entry]

> CHAPTER 01 · A place at the bench  
> **The stair lantern is back in service**  
> Routine saved · landing-lamp on  
> Next · The morning round

[EXIT CHECK · Ticket read; `landing-light` completed; `landing-lamp` really on; slate and both source drafts retained. Reading the ticket, opening the lamp page or seeing a successful ghost is not enough.]

### 01.06 · The next card, without starting another chapter here

[HANDOFF · Chapter 02 begins when the player proceeds to the opening-round work. Its programming job already exists as `morning-round`. This storyboard keeps the boundary: Chapter 01 teaches one object/method and True/False; Chapter 02 introduces a collection and repetition.]

[UI · Next pin]

> CHAPTER 02 · The morning round  
> **The opening card**  
> Take the slate to the workshop screen. The card lists three lights.  
> Job No. 3 · A list and a loop

[STAGE · At the screen, the cord plugs into the existing brass-collared socket. A saved connection does not grant permanent range: the player must still stand at the linked screen to work on its zone. The first job’s routine remains on its own page.]

[CODE 02.HANDOFF · Existing next-chapter reference, included for continuity only

```python
def program(world):
    workshop = world.zone("workshop")
    lamps = workshop.lamps

    for lamp in lamps:
        lamp.set_lit(True)
```

]

[SCOPE · Do not show this solution as an unsolicited Chapter 01 reward or require it to finish Chapter 01. The actual Chapter 02 starter still reaches only `lamps[0]`. Its three-lamp proof and the returned gate complaint get their own full script later.]

## 4. Optional exploration, interruptions and the way back

These paths are part of the setup. They should not require guessed quest order or trap a player who followed a door before following a pin.

### The rooms

| Where / action | Optional text or response | Progress consequence |
|---|---|---|
| Bread cupboard | **Narrator:** “A loaf sits under the raised lid, one end cut unevenly. The knife lies beside a scatter of crumbs.” | Inspection only. No invented food inventory, eating animation or hunger meter. |
| Stove | **Narrator:** “The kettle is still warm. There’s a second cup beside it, turned upside down.” | Inspection only; supports Nell’s expected return. |
| Repair bench | **Narrator:** “An enamel hand rests beside its housing. Every screw has its own tray.” | The repair bench is not another programmable job yet. |
| Parts drawers | **Narrator:** “Washers, collars, springs. The narrow drawer has a clean patch where someone’s knee catches it.” | Callback to Hotaru’s line; optional revised inspection copy. |
| Workshop screen before the ticket | Existing socket / connection behavior and the correct currently reached page | Must not mark `waiting-ticket` read or light the lantern. A connected scratch page is not a quest completion. |
| Lantern before a job is available | “Nothing has been asked of it yet. Nell’s ticket will say what she wants.” | Existing device response; board remains the next objective. |

No optional inspection is required to see the main thread. The chapter pins should always state the next concrete action.

### The lane and the square

[RULE · Preserve open exploration. Street doors and town stairs already work; do not turn the repaired gate into a new story lock. Room changes use their walking animation and veil. Nell remains out on calls. Ambient mail, lamp and garden robots continue their existing errands; the player is not secretly programming those routes in these chapters.]

If the player reaches the lane after the introduction, use the existing first-visit scene in this revised four-page form:

**Narrator 1:** The doors swing out onto warm cobbles. Below the wall, a tram bell rings once and stops.

**Hotaru 2:** Four days since I was last out here. Someone’s chalked squares on the cobbles since then.

**Hotaru 3:** And Braum’s painted his gate again. That makes three coats this month.

[CHOICE OUTSIDE.A]

| Option | You | Hotaru’s reply |
|---|---|---|
| A | Who’s Braum? | Next door. He builds things. Mostly that fence. |
| B | Is it always this quiet? | Until the tram comes up. Then it’s quiet with a tram in it. |
| C | Where do the steps go? | The square. The top step says two hundred and twelve. I intend to check. |

[JOIN · Continue to page 4.]

**Hotaru 4:** Nell comes back up that way. You hear the gate before you see her.

[UI · **Back to the lane**. Before the introduction, free exploration does not fabricate this conversation with an awake Hotaru; returning to the loft terminal remains the way to start.]

At the square, keep the existing short first-visit scene:

**Narrator 1:** The street drops its last few steps into the square. Awnings down one side, and the smell of bread.

**Hotaru 2:** That’s the beacon in the middle. Nell stops there on the way back. Every time. I’ve counted.

**Narrator 3:** Under the glass a root glows the colour of strong tea. The needle on its pressure dial sits low.

[UI · **Back to the square**. Optional inspection of `beacon-dial`: “The needle sits just past the first mark. Somebody has scratched a line in the brass where it used to rest.”]

[STORY · This is the first physical clue to the power thread if the player visits early. It is a pressure dial, not a clock. Nobody concludes that the source is dying, blames the player or sends a beginner into the Rootworks. No Rootwell control API is available.]

[PIN · On optional outdoor visits, retain the active chapter objective and add “Nell’s workshop · Back up Spindle Steps” as a location hint. Do not replace an unfinished task with “Nothing out here has a ticket yet.” This is a proposed pin-content/routing improvement.]

### Leaving, returning and saving

| Interruption | Required behavior |
|---|---|
| Close Nell’s note before putting it away | Note remains readable; first terminal reminder still points to it. |
| Close a conversation before its final action | Do not invent a chosen reply or mark the scene finished. Completed message/item/lamp state remains true. Allow the pending beat to be reopened. |
| Save after waking Hotaru but before her introduction ends | Continue restores awake Hotaru and offers the unfinished exchange. Do not require another greeting. |
| Save after slate pickup but during its conversation | Item stays carried. Do not respawn a second slate. Offer the unfinished explanation through its existing story/log surfaces. |
| Read the job board before greeting Hotaru | An ordinary inspection can already be saved. On returning after the introduction, offer the full ticket conversation without erasing the earlier discovery or skipping its important information. |
| Apply the lamp repair, then close before Hotaru reacts | Keep the committed light. Offer the pending reaction; do not undo the repair to replay it. |
| Return to the loft after starting the lamp job | Greeting and lamp sources remain distinct; current work and carried slate follow the player. |
| Undo a lamp program | Respect the existing world undo. It must not undo ownership of the slate, the read note or the introduction. A remembered completion does not justify showing a currently dark lamp as lit. |
| Use development shortcuts | F8 still uses its isolated development save. Filling code does not imply Apply. Finishing uses the real validated sandbox result. |

[PRODUCTION · These are the intended review cases. The current session already preserves drafts/items/proposals and many of these boundaries. Exact resumption of interrupted story scenes is not claimed complete: scene reopen/reoffer behavior must be checked when implementing each beat, especially `tablet-taken` and early board inspection.]

## 5. Power thread and later scene cards

### What the first two chapters establish

1. Nell is busy taking calls. This supplies a practical reason for her absence and later repeat-fault paperwork.
2. A sound fitting can have an unhelpful instruction. The player sees a local program’s result clearly.
3. The workshop screen reaches a group of fittings, but does not yet reach a city network.
4. A curious player can already find a low pressure dial in the square. It is an observation, not an emergency exposition scene.

The existing returned gate complaint remains a **Chapter 02 ending / later chapter lead**. When its full script is written, label it **Spindle Steps · gate lamp**, matching the real lane location, rather than introducing an unseen “north gate”. Keep Nell’s pencilled **“Again?”**. That is the first stronger suggestion that separate work tickets may share a cause.

Keep three facts distinct: the lamp being commanded on, the supply available to it, and the network’s cause of failure. Do not make a real `set_lit(True)` silently fail because an authored scene wants mystery. Later power constraints need explicit rules, observable readings and useful error messages of their own.

### The loading screen as a quiet part of the story

[EXISTING · The seven-wheel veil accepts `city_power` presentation snapshots with `strength`, `stability` and `restored_links`. F8 already previews Low power, Steady and Restored. No persistent city-power simulation or program API drives this hook yet.]

[CHAPTER 00 / 01 · Keep the normal steady presentation. The greeting and one lamp do not increase city-source strength. The meter is labelled City power and is not a fake loading percentage.]

[LATER · Once a real branch fault is established, use reduced conduit stability and a dimmer source. Restoring an actual network branch can relight one of the three paths; repairing the source can produce the restored train. Those changes must derive from committed world state, survive Continue and appear on normal travel. No chapter-number-only cosmetic switch should masquerade as a simulated repair.]

The gear train keeps moving even at low power so the loading signal remains readable. Early deterioration should be small and noticeable on repeated crossings, not an alarm over every door.

### Future interior A · Guildhall service room

**Recommended first new interior after the current opening/round work.** Its frontage already exists in Rootward Square. A small records counter and service room would give the investigation somewhere specific to begin without needing another outdoor district.

[FUTURE DEPENDENCIES · Saved guildhall interior and doorway; a desk/ledger or readings board; authored entrance/exit; Mira placed there for the scene. Her current cast art is available. No new power-reading API is assumed.]

[ENTRY · A later ticket asks the player to compare a reported gate fault with the guild’s records. Optional early visits can show the room, but must not skip the first workshop lessons.]

**Narrator:** Three repair slips are pinned over the same little street plan. Their dates are different. Their addresses are not.

**Mira:** I moved that pin twice. It keeps turning out to be the same street.

[CHOICE FUTURE.A · Proposed opening, not a new implemented conversation]

| You | Mira |
|---|---|
| The lamp was replaced. | It says so on all three slips. That’s what’s bothering me. |
| Could the address be wrong? | I checked. Then Rowan checked because I was annoyed. |
| What do you need me to do? | Find out what those houses share before somebody orders a fourth lamp. |

[JOIN · Read the slips and return to the square’s existing service pedestal. Initially the evidence can be authored inspections. A later lesson using live supply readings needs an explicitly designed read-only snapshot/API and tests. Exit through the same frontage; no new city traversal is required.]

**Purpose:** turn “Again?” into an investigation. New interior scope: one readable room, not the whole hall, upstairs offices and clock mechanism at once.

### Future interior B · Post office sorting room

**Optional later chapter.** The post-office frontage and Pip already exist. This is a strong place for collections, labels and eventually delivery data, after the workshop’s simple loops are comfortable.

[FUTURE DEPENDENCIES · Saved sorting-room interior, pigeonhole/parcel props, authored Pip interaction, and actual letter/delivery data if the player is to sort it. Ambient mailbox errands alone are not a programmable postal system.]

**Pip’s tape:** THREE BAGS. TWO LABELS. PLEASE ADVISE. STOP.

**Hotaru:** Don’t put the unlabelled one back on him. He’s already brought it here twice.

[STAGE · A local postal job provides a practical reason to notice that undelivered repair notices cluster on one branch of town. It is not required to finish Chapters 00 or 01. No pretend `world.mail` code is included before that API exists.]

### Future interior C · Rootwell service vestibule

**Later than the service room.** Use the small teal door already described by `beacon-door`. Start with a shallow service space, not the deep roots or the source reveal.

[FUTURE DEPENDENCIES · Saved service interior, access condition, legible branch manifold and authored readings, explicit power-network rules. All are new work; no existing root model needs to be replaced merely to write the scene.]

**Narrator:** Beyond the little door, the sound from the square becomes a dull tapping. Three pipes leave the same brass collar.

**Hotaru:** Nell always stops here. I thought it was for the shade.

[STAGE · The player can trace where a known fault leads. The eventual source problem is reached through evidence and programming, not a mysterious door opened by the Chapter 01 lantern.]

## 6. Production map and the next implementation slices

### Existing scene and quest identities

| Script beats | Existing source / ID | State or capability | Content work proposed here |
|---|---|---|---|
| 00.01–00.02 | Journey `opening`; `nell-note` | Opening cards, note interaction/read log | Opening prose, note, initial pin and final-action label |
| 00.03–00.05 | `workshop-loft.quests.json` / `say-hello` | Real Blocks/Python, Test, Send, addressed greeting | Wording and feedback; retain actual-output behavior |
| 00.06 | Journey `loft-waking` | Paired portraits; three-option replies; finished/read metadata | Six-page script and both choice sets |
| 00.07 | Loft pickup `tablet` / item `field-tablet`; `tablet-taken` | Authored saved item and four-page scene | Revised explanation; interrupted-scene reoffer audit |
| 00.08 | `downstairs` / `upstairs` | Existing saved room travel and stairs | Chapter-display handoff alignment |
| 01.01 | `workshop-arrival` | One-time arrival after greeting | Five-page scene with character-based options |
| 01.02 | `waiting-ticket`; inspection `job-board` | Read-inspection goal and story finish | Fix cause of fault, ticket-read copy and destination label |
| 01.03–01.04 | `landing-light`; `landing-lamp` | Device range, slate, Debug/Apply, lamp Boolean | Starter comments, concise help, feedback/hints |
| 01.05 | `landing-lit` | Quest plus committed-lamp condition | Reaction, choices and next-card handoff |
| 01.06 | `morning-round`; `workshop-terminal` | Existing three-lamp zone job | Preserve Chapter 02 boundary; full script later |
| Optional outdoors | `lane-arrival`, `square-arrival`, existing inspections | Open travel, ambient errands and low-dial clue | Short continuity edits and active-objective pin outside |

Authoritative files: [runtime story](../../../content/journeys/sparks-and-machines.json), [loft quests](../../../content/areas/workshop-loft.quests.json), [workshop quests](../../../content/areas/workshop-floor.quests.json), [loft area](../../../content/areas/workshop-loft.json), [workshop area](../../../content/areas/workshop-floor.json), [development checkpoints](../../../content/development/sparks-checkpoints.json).

### Deliberate differences from today

1. **The first pin points to the note.** It must not quote Hotaru’s slate hint before she has awakened.
2. **Keep the existing numbered chapter ladder.** /00 is the greeting, Chapter 01 is the first lamp, and Chapter 02 is the three-light round. Ticket numbers and chapter numbers are different labels, written out where needed.
3. **The narrative Chapter 00 handoff includes the slate.** Current chapter calculation can advance when `say-hello` completes, and F8 `hello-end` has no slate. When implementing, keep Chapter 00’s handoff pin until introduction/pickup are finished; either move that checkpoint to the narrative end or label the existing one “Greeting complete” and add a handoff checkpoint. Do not pretend this alignment is already built.
4. **The address is not the bug.** Both ticket and starter use `landing-lamp`; the wrong Boolean is the exercise. Remove the old reply claiming the routine calls a different address.
5. **Reading is not repairing.** Finish `waiting-ticket` with discovery copy, not an implied hardware repair.
6. **Actions describe what opens next.** A destination prompt is “Find the stair lantern/screen”, rather than an editor promised from across the room.
7. **Remembering a link is not remote reach.** The current `FieldAccess` / `ZoneTerminals` implementation still requires the linked screen’s physical range for zone commands. Older concept text saying a connection works from anywhere is not this script’s rule.
8. **No forced outdoor lock or Nell appearance.** Optional exploration must keep a route back and preserve the current task. Nell’s arrival, new interiors and the power simulation remain later work.

### Build one reviewable slice at a time

1. **00 · Note to first message.** Apply the opening/note/pin copy and the exact actual-output Test/Send flow. Review an unchanged starter, a wrong name, an alternate greeting, an edit after Test and a save before sending.
2. **00 · Waking and the slate.** Apply both conversation scripts; test every response and interrupted/resumed handoffs. Align narrative chapter display and development checkpoints. This completes the Chapter 00 content pass before touching Chapter 01.
3. **01 · The bench and ticket.** Apply arrival/ticket/inspection copy and early-exploration behavior. Check that reading the board requires no code and never claims the repair.
4. **01 · The lantern.** Apply the one-object starter/help/result/reaction script. Verify the existing goal through real Python; Debug must remain a proposal, Apply a fact. Review both dialogue resolutions and actual lamp visibility.
5. **Next outdoor direction, updated 2026-11-02:** after the existing Chapter 02 round, develop [A proper welcome](outdoor-quest.md), the custom-message sign at the tram stairs, as candidate Chapter 03. The guildhall service room remains a later investigation scene. No buildings need to be produced to finish the two opening chapters above. [Character profiles](characters.md) guide distinct voices for these and subsequent scenes.

### Verification record for this document

The API, target IDs, current choices, chapter definitions, range rules and checkpoint differences were checked against the local game on 2026-11-02. All nine bracketed programs were run through the existing CPython/WASI runner: **29 checks passed**, including both incomplete starters, alternate accepted answers, a wrong-type rejection, detached proposals, a single-lamp solution that leaves the other fittings untouched, and the Chapter 02 handoff. The table’s wrong-addressee branch was also verified. Scratch extraction/check runner and output are in `.cache/storyboard-v08/`; player source was never executed by host Python.

Documentation links and the active-pipeline/source handoff check passed. Runtime dialogue and area documents are not edited by this storyboard pass, so there is no new gameplay view or asset to review. The full game suite and both native resolutions passed in the preceding presentation pass; they are not reported as newly rerun for a document-only change.

When these beats are implemented, retain the reference solutions in `test/test_area.gd`, extend the existing Sparks/workshop integration checks only where behavior changes, run `scripts/test.sh` and review in Godot at 1600×1000 and 1280×720. A new quest or new power API needs its own pure rules/reference proof; the future scene cards above do not count as implemented quests.
