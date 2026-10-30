# Quests: the main line and side jobs — 2026-10-26

**Status: greeting, ticket discovery, stair-light and workshop-round jobs playable, 2026-10-27; the wider catalog below remains proposed.** The current continuation is [The waiting ticket → The landing light → The morning round](../../../pipeline/reviews/2026-10-27-workshop-first-jobs.md). It uses the existing two rooms and lamp API, with saved job pages and original scenes between committed outcomes. The traveller walks normally; movement-key mapping is not a prerequisite. The outdoor gate lamp and later jobs below are future design. Code is real Python in the style of today's API ([docs/PROGRAMMING.md](../../PROGRAMMING.md)); **new API** marks objects that do not exist yet.

## Current workshop chapter

| Quest | Want and consequence | Goal |
|---|---|---|
| The waiting ticket | Nell has repaired the stair fitting. Her pocket-worn ticket gives the new relay address; Hotaru wants the light left on for Nell's return. | Finish reading the nearby board with F. Opening or leaving the scene alone does not count. |
| The landing light | Restore the lantern before evening. Its committed light brings Hotaru back to the unfinished opening card. | Light `landing-lamp` through the existing object/method API. |
| The morning round | The card reaches one fitting; both worktables need light as well. | Light all three lamps in `world.zone("workshop").lamps`. A loop is taught; any valid program reaching the world goal counts. |

Tests and reference solutions are in `test/test_area.gd`; the full conversation/editor/save playthrough is `test/test_workshop_quests.gd`. Each unchanged starter leaves its actual job incomplete. The final scene finds a returned north-gate complaint behind the workshop card; that complaint is a story lead, not an implemented outdoor quest.

## How a quest is built

1. **A want in the world.** Someone needs something done today. The code is the only way, or clearly the best way, to do it.
2. **One new idea per main job.** Side jobs practise it, or introduce a neighbouring idea.
3. **The starter is almost right and fails visibly.** Running it as given produces a funny, readable result in the preview. That failure is the hook.
4. **The preview teaches.** Ghosts show the consequence before Apply: a gap in a bridge, a lamp still dark, Hotaru walking into a fence.
5. **A twist that rewards understanding.** Something late in the quest only makes sense if the idea clicked.
6. **The goal checks the world, not the code text.** Any program that makes the world right counts.
7. **Each job ends on a reaction, never a moral** ([rule 7](07-dialogue.md#3-the-rules-for-writing-a-line)). The notebook can keep one plain factual line.
8. **Project rules apply:** code only sees places the player has visited, Preview stays a proposal until Apply, and every new quest gets a reference solution in the tests (`AGENTS.md`).

## The concept ladder

| # | Job | Idea | Status of what it needs |
|---|---|---|---|
| 0a | Hello, Hotaru | `print`, strings | Today's lesson rules |
| 0b | How you walk | Events, arithmetic | Today's lesson rules |
| 1 | The gate lamp | Objects, method calls | Today's API |
| 2 | Legs! | Sequences: order matters | **New API:** Hotaru working mode (stage 1) |
| 3 | Wick's round | Lists, `for` loops | Today's API |
| 4 | A measured bridge | Variables, numbers, `len` | Today's API |
| 5 | The sparkworks gate | `if` / `else`, `and` | Today's API |
| 6 | Light the Hollow | Functions with parameters | Today's API |
| 7 | The founders' card | Reading code, indexes, `range`, off-by-one | Today's API |
| 8 | *(slice 2)* Three at once | Counting with conditions, `while` | **New API:** Rootwell valves |

Side jobs: [section below](#side-jobs).

---

## Main line: Act 1, "Light the Hollow"

Jobs 0a, 0b and 1 are scripted in full in [the opening script](07-dialogue.md#5-the-opening-script-slice-1). The summaries here are for the quest data.

### Job 0a · Hello, Hotaru
- **Idea:** `print`, strings. **Where:** the loft. **Goal:** Hotaru greeted (today's `hotaru_greeted` goal).
- **Starter:** `print("Hello, Hotaru!")`, as today.
- **Payoff:** the terminal’s addressed-message bell wakes her from an ordinary nap ([script](07-dialogue.md#scene-2--a-sleepy-greeting)).

### Job 0b · How you walk
- **Idea:** events and arithmetic: each key adds a step. **Where:** the loft. **Goal:** four directions mapped and practised (today's First Steps rules).
- **Payoff:** "Four directions. You're officially allowed to walk."

### Job 1 · The gate lamp
- **Ticket:** *"Light it. — N."* **Idea:** an object you ask for by name, and a method that tells it what to do. **Where:** the lane.
- **Starter:**
  ```python
  def program(world):
      lamp = world.lamp("gate-lamp")
      lamp.set_lit(False)   # Nell's note says: light it
  ```
- **Reference solution:** change `False` to `True`.
- **Funny failure:** the starter as given → *"You asked it very clearly to stay off. It's doing a wonderful job."*
- **Payoff:** Bram's window and his fence ([script](07-dialogue.md#scene-4--the-gate-lamp-job-1)).

### Job 2 · Legs!
- **Ticket:** *"Post this. Today. — N."* (pinned to a sealed envelope)
- **Idea:** a **sequence**: instructions run in order, and order matters. **Where:** the lane, from the workshop door to the red post box.
- **The want:** Nell wants a letter posted, and Hotaru has just discovered her legs.
- **Setup:** Hotaru stands on the grid (working mode). The post box is three cells east and two south, past the corner of Bram's fence.
- **Starter:**
  ```python
  def program(world):
      hotaru = world.hotaru
      hotaru.step("south")
      hotaru.step("south")
      hotaru.step("east")
  ```
- **Reference solution:**
  ```python
  def program(world):
      hotaru = world.hotaru
      hotaru.step("east")
      hotaru.step("east")
      hotaru.step("east")
      hotaru.step("south")
      hotaru.step("south")
  ```
- **Funny failure:** the starter's ghost walks straight into the corner of Bram's fence. **Hotaru:** *"I've touched his fence."* · *"Don't tell him."*
- **Twist:** writing `hotaru.step("east")` three times feels silly, and Hotaru says so: *"You wrote the same line three times. Was the second one a different east?"* This sets up Job 3.
- **Payoff:** *The letter drops into the box with a soft clunk.* **Hotaru:** "Posted!" · *"…Who's it to?"* · Nell, later, not answering: *"Somebody who'll be glad to hear you've arrived."*
- **Needs:** **new API** `world.hotaru` with `step(direction)` and working mode ([Hotaru, stage 1](03-robot-companion.md#suggested-stages)); a post box prop.

### Job 3 · Wick's round
- **Ticket:** *"Wick's stuck. Again. — T."* (Tessa)
- **Idea:** a **list** of things and a **`for` loop** that does the same job for each one. **Where:** the green by Tessa's orchard.
- **The want:** Wick the lamplighter has stood at Lamp One since Tuesday. Rain soaked his route card, and only the first line survived.
- **Opening:**
  - **Wick (tape):** "IT IS 19.42. I AM AT LAMP ONE. I HAVE BEEN AT LAMP ONE SINCE TUESDAY. STOP."
  - **Tessa:** "I've been bringing him tea. He doesn't drink it, but it's the thought."
  - **Hotaru:** "He's very punctual. He's punctually in the wrong place."
- **Starter** (what's left of Wick's card):
  ```python
  def program(world):
      green = world.zone("green")
      first = green.lamps[0]
      first.set_lit(True)
  ```
- **Reference solution:**
  ```python
  def program(world):
      green = world.zone("green")
      for lamp in green.lamps:
          lamp.set_lit(True)
  ```
- **Funny failure:** the starter as given → **Wick:** "LAMP ONE: LIT. AGAIN. STOP." The other three ghosts stay dark.
- **Twist:** the list's order is Wick's route. Once he has a loop, he walks it in that order on his own: the player watches their loop turned into a walk.
- **Payoff:** **Wick:** "ROUND COMPLETE. FOUR LAMPS. NO COMPLAINTS. STOP." · *"CORRECTION. ONE COMPLAINT. LAMP THREE WOBBLES. STOP."* (This plants side job [S10](#s10--lamp-three-never-lights).) **Tessa:** "Oh, he's walking! Look at him go. Like a little vicar."
- **Needs:** today's zone and lamp API; Wick's walking routine as presentation (`A2` art).

### Job 4 · A measured bridge
- **Ticket:** *"Bridge needs decks. Crane's ready. Mira's coming. Sorry. — B."*
- **Idea:** a **variable** names a number so you can change it, compute it, or measure it. **Where:** the brook below the sparkworks.
- **The want:** Bram wants the mill bridge rebuilt by lunch. He and Mira disagree about how many decks it needs.
- **Opening:**
  - **Bram:** "Three decks. Three-ish. Heron'll have it done by lunch!"
  - **Mira:** "Which lunch?" · *"It's four cells across. I measured. Twice. Once in the rain."*
  - **Heron (tape):** "I. AM. READY. TO. LIFT. STOP."
- **Starter:**
  ```python
  def program(world):
      bridge = world.bridge("mill-bridge")
      decks = 3   # Bram: "three-ish"
      for cell in bridge.cells[:decks]:
          bridge.place_deck(cell)
  ```
- **Reference solutions:** `decks = 4`, or better, measure it: `decks = len(bridge.cells)`.
- **Funny failure:** the preview shows three ghost decks and a one-cell gap over the water. **Mira:** "There's your three-ish."
- **Twist:** the notebook offers `len(bridge.cells)`. **Mira**, seeing it: *"You measured it. With the code. Oh, I like you."*
- **Payoff:** **Bram:** "Four! That's what I said." · **Mira:** "You said three-ish." · **Bram:** "Four's a kind of three-ish."
- **Needs:** today's bridge API; Heron as presentation (`A3`).

### Job 5 · The sparkworks gate
- **Ticket:** *"Gate. Lamps. Night. — R."* (Rowan writes as he talks)
- **Idea:** **`if` / `else`** decides between two actions; **`and`** needs both things true. **Where:** the sparkworks walkway beside the wheel.
- **The want:** people cut across the wheel walkway in the dark and fall into the race. Rowan wants the gate open only when both walkway lamps are lit.
- **Opening:**
  - **Rowan:** *(not looking up)* "Mind the walkway. It's wet. It's always wet."
  - **Rowan:** "Two lamps. Gate opens when both are lit. Not one. Both."
  - **Rowan:** "…" · *"People swim home otherwise."*
- **Setup:** it's dusk. The west lamp is lit; **the east lamp is out** (lamp three's wobble has spread, or Rowan has taken its glass for cleaning).
- **Starter:**
  ```python
  def program(world):
      gate = world.gate("works-gate")
      west = world.lamp("works-west")
      east = world.lamp("works-east")
      gate.set_open(True)
  ```
- **Reference solution:**
  ```python
  def program(world):
      gate = world.gate("works-gate")
      west = world.lamp("works-west")
      east = world.lamp("works-east")
      if west.lit and east.lit:
          gate.set_open(True)
      else:
          gate.set_open(False)
  ```
- **Funny failure:** the starter opens the gate with one lamp dark. **Rowan:** "…" · *"That's how Albers learned to swim."*
- **Twist:** the first **correct** program does nothing visible: the gate stays shut, because the east lamp is out. Rowan approves of the shut gate. Then the player lights the east lamp (one extra line, or Job 3's habit) and runs the **same** decision again: now it opens. The program didn't change; the world did.
- **Payoff:** **Rowan:** "It's shut." · *"Good."* · (after the second run) *"Open. Good."* · **Hotaru**, whispering: *"That's the most he's said since the flood."*
- **Needs:** today's gate and lamp API; a two-stage goal (gate shut while a lamp is dark, then open when both are lit).

### Job 6 · Light the Hollow
- **Ticket:** *"All of it. Tonight. — N."*
- **Idea:** a **function** with a parameter: write the job once, use it for every district. **Where:** every district of the outskirts, plus the signal lamp at the Old Watch.
- **The want:** Nell wants the whole hill lit at once, the way it was before, "so the town remembers we're up here."
- **Opening:**
  - **Nell:** "Every lamp on the hill. Tonight. And the Old Watch."
  - **Hotaru:** "The Old Watch? Nobody's lit that since—"
  - **Nell:** "Since. Yes."
- **Starter:**
  ```python
  def light_all(lamps):
      # light every lamp in the list
      pass

  def program(world):
      for zone in world.zones:
          light_all(zone.lamps)
  ```
- **Reference solution:**
  ```python
  def light_all(lamps):
      for lamp in lamps:
          lamp.set_lit(True)

  def program(world):
      for zone in world.zones:
          light_all(zone.lamps)
      light_all([world.lamp("old-watch")])
  ```
- **Funny failure:** `pass` does nothing, so every ghost stays dark. **Hotaru:** *"It says 'pass'. Is that a kind of yes? It feels like a kind of no."*
- **Twist:** districts the player hasn't walked to don't exist yet for the code. The job sends the player exploring: walking the hill *is* part of the solution.
- **Payoff:** *Every lamp on the hill comes on, district by district, and last of all the Old Watch, far up the ridge. A moment later, from the town below, a bell answers. Once.*
  - **Nell:** "Well." · *"Now they know we're here."*
  - **Hotaru** uses the apprentice's name for the first time: *"{name}. Look at the square."* Nobody remarks on it.
  - *In the square, the Rootwell's needle drops a mark.*
  - **Hotaru:** "It went down. When we lit everything, it went down."
- **Needs:** today's zone and lamp API; districts; the Old Watch lamp (today's beacon role).

### Job 7 · The founders' card
- **Ticket:** none. Nell hands it over herself: an old punched routine card from the workshop safe.
- **Idea:** **reading someone else's code**, list indexes, `range`, and the classic **off-by-one** bug. **Where:** the hill branch stair, ten lamps in a row.
- **The want:** after last night, the hill branch's ten lamps flicker. Nell digs out the founders' own routine for that branch. It nearly works.
- **Opening:**
  - **Nell:** "This was in the safe. It's older than me, and I'm older than the safe."
  - **Hotaru:** *(reading)* "It says 'R.W.' at the bottom." · *"Who's R.W.?"*
  - **Nell:** "Read the rest first."
- **The card** (shown in the notebook as a scanned card, then as text):
  ```python
  # HILL BRANCH. TEN LAMPS. ONE BY ONE.
  # NEVER MORE THAN THREE BRANCHES AT ONCE.   - R.W.
  def program(world):
      hill = world.zone("hill-branch")
      lamps = hill.lamps
      for i in range(1, len(lamps)):
          lamps[i].set_lit(True)
  ```
- **Funny failure:** run as written, nine lamps light and the first one, by the stair, stays dark. **Hotaru:** *"Nine. It's always the one by the stair. Do you think they didn't like that one?"*
- **Reference solutions:** `range(len(lamps))`, or rewrite it as `for lamp in lamps:`.
- **Twist:** the fix is one character. Finding it means reading what `range(1, …)` actually counts. The notebook's playback (today's execution replay) shows `i` starting at 1.
- **Payoff:** the stair lamp lights. **Nell**, reading the second comment line again: *"Never more than three branches at once."* · *"Hm."* · She takes the card back and doesn't put it in the safe. She puts it in her apron pocket.
- **Leads to:** slice 2, the Rootwell, and the mystery: last night the whole hill was lit at once.
- **Needs:** today's zone and lamp API, and execution replay; a card graphic for the notebook.

### Job 8 · Three at once (slice 2, outline)
- **Idea:** counting things that match a condition, and a `while` loop that stops at a limit. **Where:** the Rootwell's valve wheels.
- **The want:** respect the founders' rule. Open branch valves one at a time until three are open, never more, watching the dial.
- **Needs:** **new API** for Rootwell valves and the dial. Designed with slice 2.

---

## Side jobs

Each side job introduces or practises a different idea, has its own small story, and unlocks after the main job that teaches what it needs. They appear as tickets on the workshop board, or as people waving you over.

| Id | Job | Giver | Idea | Unlocks after | Needs |
|---|---|---|---|---|---|
| S1 | Mrs. Oduya's sign | The baker | Strings, f-strings, `len` | Job 4 | **New API:** a letter-board sign |
| S2 | Pip's pigeonholes | Pip, the post sorter | Dictionaries, `KeyError`, adding keys | Job 4 | **New API:** post and letters |
| S3 | Tessa's rows | Tessa and Trowel | Nested loops, `range`, `continue` | Job 5 | **New API:** an orchard grid |
| S4 | Old Tom's tune | The mayor | List indexes and slicing | Job 3 | **New API:** a clock chime |
| S5 | Counting sheep | Hotaru | `while` loops, `world.memory` | Job 6 | `world.memory` exists; a wake-up hook |
| S6 | Settle it | Bram and Mira | Comparisons, `True` / `False` | Job 5 | Today's API (`house.cell`, `doodad.cell`) |
| S7 | The weather box | Rowan | `sum`, `len`, `min`, averages | Job 5 | **New API:** weather readings, a flag |
| S8 | Face the lane | Bram and Heron | Attributes, list items | Job 5 | Today's API (`house.face`) |
| S9 | The next tram | The conductor | Functions that `return` | Job 6 | **New API:** timetable, sign |
| S10 | Lamp three never lights | Wick | Boolean logic: `and` vs `or` | Job 5 | Today's lamp API, plus the clock |

### S1 · Mrs. Oduya's sign
- **Hook:** **Mrs. Oduya:** "Last week Bram wrote 'BREAD' on my board. Just 'BREAD'." · *"People asked if we were all right."*
- **Task:** put today's special on the bakery's letter board, built from the bread name and the price, and make it fit: the board holds 16 letters.
- **Code:**
  ```python
  def program(world):
      board = world.sign("bakery-board")
      bread = "rye"
      price = 3
      message = f"{bread.upper()} LOAF {price}C"
      if len(message) <= board.width:
          board.set_text(message)
      else:
          print("Too long:", len(message))
  ```
- **Twist:** tomorrow's special is "cinnamon twists", which doesn't fit. The player shortens it, or checks `len` first. **Hotaru:** *"CINNAMON TWI. It sounds like a sneeze."*
- **Payoff:** **Mrs. Oduya:** "Look at that. Words. Real ones." · She gives the apprentice a twist that didn't fit on the sign.

### S2 · Pip's pigeonholes
- **Hook:** **Pip (tape):** "GOOD MORNING. 214 LETTERS. 0 PIGEONHOLES LABELLED. HELP. STOP. PLEASE. STOP."
- **Task:** sort the letters into houses by surname, using a dictionary from surname to house.
- **Code:**
  ```python
  def program(world):
      homes = {
          "Albers": "albers-cottage",
          "Oduya": "bakery",
          "Lindqvist": "town-hall",
      }
      for letter in world.post.letters:
          letter.deliver_to(homes[letter.surname])
  ```
- **Twist:** one letter breaks the program, a `KeyError`. **Pip:** *"NO PIGEONHOLE FOR 'THE LODGER'. STOP. IS IT A PERSON. STOP."* It's addressed to *The Lodger, the old workshop*. The player adds a key (or uses `homes.get(letter.surname, "workshop")`), and the letter is for them, from home.
- **Payoff:** *A short narration page with the letter's few lines from family.* **Hotaru:** "Is it good news?" → **Earnest:** "It's from my mum." **Hotaru:** "Then it's good news." · **Wry:** "They want to know if I've eaten." **Hotaru:** "Tell them about the month of breakfasts." · **Blunt:** "It's private." **Hotaru:** "Noted." *(She turns politely toward the wall.)*

### S3 · Tessa's rows
- **Hook:** **Tessa:** "That's Aunt Margit, that's Uncle Ferenc — he leans, we don't talk about why — and those little ones are the cousins." · *"The cousins drown if you look at them. Big trees get the big can. Babies get the mist."*
- **Task:** Trowel waters the orchard grid row by row: the big can for grown trees, and skip the saplings for the misting round.
- **Code:**
  ```python
  def program(world):
      orchard = world.orchard("tessa")
      trowel = world.automaton("trowel")
      for row in orchard.rows:
          for tree in row:
              if tree.sapling:
                  continue
              trowel.water(tree)
  ```
- **Funny failure:** without the check, the cousins' ghosts sit in puddles. **Tessa:** "Oh, the cousins!"
- **Payoff:** **Trowel (tape):** "MM. STOP." · **Tessa:** "That's high praise from Trowel."

### S4 · Old Tom's tune
- **Hook:** **The mayor:** "Forty years the clock has played the same five notes. For the anniversary I'd like them backwards." · *"For dignity."*
- **Task:** set the town clock's tune from the old one: reversed for the anniversary, and only the first three notes on Sundays.
- **Code:**
  ```python
  def program(world):
      tom = world.clock("town-hall")
      old = tom.tune                 # ["C", "E", "G", "E", "C"]
      tom.set_tune(old[::-1])
      tom.set_sunday_tune(old[:3])
  ```
- **Twist:** reversed, this particular tune is the same tune. **Hotaru:** *"It's the same. Backwards and forwards. Is that allowed?"* The mayor decides it is "subtle", and the player can make it actually different by changing a note with an index (`old[2] = "A"`).
- **Payoff:** *At the hour, Old Tom plays it. Across the square, somebody claps once.*

### S5 · Counting sheep
- **When:** the night after Job 6. Back in the loft.
- **Hook:**
  - **Hotaru:** "Can I ask you something?" · *"When I switch off tonight… will I switch back on?"*
  - → **Earnest:** "Of course you will." **Hotaru:** "That's what I thought last time."
  - → **Wry:** "Not if you keep talking." **Hotaru:** "Rude. Fair, but rude."
  - → **Blunt:** "What happened last time?" **Hotaru:** "I don't know. That's the problem."
- **Task:** write her a bedtime routine: save a wake-up time she can find in the morning, then count her down to sleep on the tape.
- **Code:**
  ```python
  def program(world):
      world.memory["hotaru_wake"] = "07:00"
      count = 10
      while count > 0:
          print(count)
          count -= 1
      print("Good night, Hotaru.")
  ```
- **Funny failure:** forget `count -= 1` and the loop never ends, until the sandbox's limit stops it. **Hotaru:** *"I counted to ten thousand and the tape ran out. I'm extremely awake now."*
- **Payoff:** *Morning.* **Hotaru:** "Seven o'clock." · *"It's tomorrow. It's only tomorrow."* · She doesn't say thank you. She follows a little closer all day.
- **Needs:** `world.memory` exists; a wake-up hook that reads it the next morning.

### S6 · Settle it
- **Hook:** **Mira:** "His fence is on my line." · **Bram:** "It's on *a* line. Lines are everywhere."
- **Task:** use the coordinates of Bram's fence and Mira's boundary to print whether the fence crosses it, and by how much.
- **Code:**
  ```python
  def program(world):
      fence = world.doodad("bram-fence")
      boundary = 18
      print("Over the line:", fence.cell[1] > boundary)
      print("By:", fence.cell[1] - boundary)
  ```
- **Payoff:** `True`, by one. **Bram:** "One! One cell!" · **Mira:** "A cell's a metre. A metre's a lot of fence." · **Hotaru:** *"Somebody's touched his fence. It was him."*
- **Needs:** today's API (`doodad.cell`).

### S7 · The weather box
- **Hook:** **Rowan:** "Storm glass is broken. Harbour wants a warning." · *"…Numbers are in the box."*
- **Task:** read the hilltop station's last 24 pressure readings, print the average and the lowest, and raise the storm flag if pressure fell sharply.
- **Code:**
  ```python
  def program(world):
      readings = world.weather("hilltop").pressure
      average = sum(readings) / len(readings)
      falling = readings[-1] < readings[0] - 5
      world.flag("harbour-storm").set_raised(falling)
      print(f"Average {average:.1f}, lowest {min(readings)}")
  ```
- **Payoff:** the flag rises; that night it rains. **Rowan:** "Told you." · *(He didn't.)*

### S8 · Face the lane
- **Hook:** **Bram:** "Two cottages, backs to the lane. Ugliest thing on the hill. Heron can turn them, if somebody tells Heron which ones."
- **Task:** today's *Face the lane* quest, retold: loop over the row's houses, read where each stands, and turn the southern ones to face north.
- **Code:** as today's reference solution (`house.cell[1]`, `house.face("north")`).
- **Payoff:** **Heron (tape):** "I. HAVE. TURNED. A. HOUSE. STOP." · *"I. WOULD. LIKE. TO. DO. IT. AGAIN. STOP."*
- **Needs:** today's API.

### S9 · The next tram
- **Hook:** **The conductor:** "People stand at the halt asking me when the next tram is." · *"I'm on the tram. I'm the one who knows. I'm not at the halt."*
- **Task:** write a function that **returns** the minutes until the next tram, and show it on the halt's board.
- **Code:**
  ```python
  def minutes_until(now, times):
      for t in times:
          if t >= now:
              return t - now
      return None

  def program(world):
      board = world.sign("tram-halt")
      wait = minutes_until(world.time.minutes, world.tram.times)
      if wait is None:
          board.set_text("LAST TRAM GONE")
      else:
          board.set_text(f"NEXT TRAM {wait} MIN")
  ```
- **Twist:** after the last tram, the function returns `None`, and the board needs its own message.
- **Payoff:** **The conductor:** "Nobody's asked me anything all day." · *"It's awful. I love it."*

### S10 · Lamp three never lights
- **Hook:** **Wick (tape):** "LAMP THREE LIGHTS NEVER. STOP. THIS IS NOT ON THE TIMETABLE. STOP."
- **Task:** Wick's routine for lamp three should light it at night. Find out why it never does.
- **Wick's routine:**
  ```python
  def program(world):
      hour = world.time.hour
      lamp = world.lamp("green-3")
      if hour > 18 and hour < 6:
          lamp.set_lit(True)
  ```
- **Fix:** an hour can't be both after six in the evening **and** before six in the morning; it needs `or`.
- **Hotaru:** *"After six and before six. At the same time. Poor thing's been waiting for a time that doesn't exist."*
- **Payoff:** **Wick:** "LAMP THREE: LIT. STOP. WOBBLE: ONGOING. STOP. THAT IS A DIFFERENT PROBLEM. STOP."
- **Needs:** today's lamp API; `world.time` (**new API**).

---

## What the coding agent will need

| Exists today | New, in order of need |
|---|---|
| `print`, `world.lamp`, `world.zone`, `zone.lamps`, `lamp.set_lit`, `world.gate`, `gate.set_open`, `world.bridge`, `bridge.place_deck`, `world.house`, `house.face`, `world.doodad`, `world.memory`, `world.controls`, execution replay | `world.hotaru` with `step` (Job 2, Hotaru stage 1) · `world.time` (S9, S10) · `world.sign` (S1, S9) · `world.post` and letters (S2) · `world.orchard` and `world.automaton` (S3) · `world.clock` (S4) · `world.weather` and `world.flag` (S7) · Rootwell valves and dial (Job 8) |

Every new object follows the existing command contract: explicit type, target, range, occupancy or support rule, a plain-word error, atomic batches, and visited-places-only discovery.
