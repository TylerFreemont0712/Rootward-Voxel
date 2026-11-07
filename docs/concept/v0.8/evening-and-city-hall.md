# Chapter 04 — After the light

Implemented storyboard · 2026-11-02. Runtime text: [journey](../../../content/journeys/sparks-and-machines.json), [ticket](../../../content/areas/haverlund-lane.quests.json). This follows the three-light workshop loop and Iona’s repeating welcome sign. No new building is required for the lesson.

## What the player learns

A Boolean fact, `if`, `else`, the colon and indentation. The existing list and `for` loop are retained: two lamps need the same decision. The problem is a plausible swapped instruction, rather than a broken bulb or an unexplained new API.

The shared clock starts at 09:14. One second of exploration is one game minute, making a complete day 24 minutes. Reading, coding, conversations, menus and scene transitions pause it. After Iona and Braum acknowledge the sign, a short clockwork interlude advances the first day to 19:15. The evening stays there until the closing round is finished; this first condition lesson has no time limit.

## Staging

Nell returns from the upper lane, `[11,26]`, and walks to `[12,17]` with her existing painted skin and normal gait. An exclamation mark introduces her. F turns the whole traveller and Nell toward each other and opens the existing portrait conversation. Returning to the area after accepting the ticket places her at her destination.

Two street lamps flank the workshop frontage. Their slate approach is `[11,14]`; it leaves the doorway and Hotaru’s talk point clear. The old pavement lamp, gate lantern, both platform lamps, the square’s banner lamps, festoons and bollard lights have dusk relays. The shop pair intentionally retain the faulty/manual instruction until repaired.

## Conversation and choices

The following pages are the shipped conversation, including the responses.

### The lamps that passed the test

**Nell**: Good. You found the slate. I had a whole speech ready if you’d tried to repair the kettle with a fork.

**Nell**: I saw the new sign from the tram. Iona paid you, I hope. She once tried to settle an invoice with a very fine drawing of the money.

**Player**: Did the lamps go as well?

**Nell**: They worked on my bench. Both of them. Out here they wait all day for the dark, then decide they’ve earned the night off. Look at their closing card.

**Nell**: The clock gives you a fact: is_dark. The if line asks whether that fact is true. Then it does the indented bit beneath it. Else is what happens the rest of the time.

- **Player choice:** So the bulbs are all right?
  **Reply:** I checked them twice. Don’t let a clever fault talk you into buying a new bulb.
- **Player choice:** Could I just leave them on?
  **Reply:** You could. Then we’d be paying for daylight. Try your card in the sun as well as the dark.

**Hotaru**: I can run a daylight test while we stand here. The slate saves both instructions. No waiting until breakfast.

**Nell**: Two lamps, same rule. Finish that and we’ll call it a day. Eighteen pence. I’m paying for the checking too.

### The closing card

[Nell gives the player the closing ticket. The same field slate opens with the Job, Names and Hints notes. The “Daylight routine” checkbox is selected. Debug tests actual Python in daylight and darkness; nothing changes until Apply.]

**Faulty starter:**

[Code]

```python
# closing_round.py
# The lamps passed Nell’s bench test. Read the condition.

def program(world):
    lamps = [world.lamp("shop-door-lamp"),
             world.lamp("shop-sign-lamp")]

    for lamp in lamps:
        if world.time.is_dark:
            lamp.set_lit(False)  # the evening instruction
        else:
            lamp.set_lit(True)   # the daylight instruction
```

[/Code]

**Reference repair:**

[Code]

```python
def program(world):
    for name in ["shop-door-lamp", "shop-sign-lamp"]:
        lamp = world.lamp(name)
        if world.time.is_dark:
            lamp.set_lit(True)
        else:
            lamp.set_lit(False)
```

[/Code]

[Debug: the slate reports both test conditions and ghosts the lamps at the current time. Apply installs the two tested decisions. Daylight selects the saved day instruction; darkness selects the saved night instruction. The program does not loop in the background. Always-on and reversed routines can be applied but do not pass the ticket.]

**Hints:**

- Follow one lamp through the starter: when is_dark is True, which set_lit call runs?
- Switch the values in the two branches: True below if; False below else. Keep their indentation.

[Completion requires Nell’s accepted ticket and both lamps off by day / on in darkness. Record 18 p once, outside machine Undo. The ordinary clock resumes after completion.]


### A good closing round

**Nell**: There. Light when it’s needed. Off when it isn’t. A little decision, made properly, saves someone a walk every evening.

**Hotaru**: And the same clock, wherever we go.

**Nell**: The hall’s work desk has bigger jobs on it. Have a look tomorrow, if you like. Tonight, put the slate down before your tea goes cold.


## The power hint

The city’s supply is saved journey state, separate from room memory and Undo. The Rootwell and the loading meter share a normal pressure of 5.6. Below 8 is green; 8–9 is amber; 9 and above is red. The instrument face ends at 10; higher readings peg and flutter its needle. The loading meter can show the full 0–15 range. At 15 a latched overload trips the street supply. Lowering the number alone does not reset the breaker.

This is infrastructure for the later power-source story. Player Python cannot inspect or change pressure yet. F8 provides isolated development controls and an explicit breaker reset. The world does not generate a surprise random outage during this lesson.

## City hall, playable foundation

The existing hall on Rootward Square now has two hinged oak doors. The counter formerly blocking the entrance is removed from the adopted master. F at the steps, a click on the entry or the ordinary inward step travels into a separately saved 28×22 public lobby. The matching doorway returns to the square.

The interior has enquiries, a separate Public Works desk, waiting benches, archive shelves, tall windows and four programmable pendant lamps. Enquiries currently provides a short orientation. Public Works opens the existing job ledger. The civic screen connects the room’s devices. A street service screen on Spindle Lane and the square service screen also expose the robots in places already visited.

Workers accept a saved pace, pause/resume and an ordered selection of their authored service stops. Their real rounds use ordinary traversable paths. Fault-specific maintenance commands, new civic commissions, a staffed clerk, room-building purchases and the city-supply repair chapter remain later slices; this delivery establishes their places and interfaces.
