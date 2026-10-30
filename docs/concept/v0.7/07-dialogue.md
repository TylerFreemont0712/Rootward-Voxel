# Dialogue: critique, voice and the opening script — 2026-10-26

**Status: loft greeting and four workshop scenes implemented, 2026-10-27; outdoor scenes remain proposals.** Current original scene text is in `content/journeys/sparks-and-machines.json`; [the first-jobs review](../../../pipeline/reviews/2026-10-27-workshop-first-jobs.md) records the playable continuation. This document covers the [Sparks & Machines journey](05-scenario.md). Existing journeys retain their lines; examples below critique earlier writing. Quests are in [the quest design](08-quests.md).

## 1. The critique

The current lines are clear and kind. They are also nearly all doing a job other than being a person talking. Twelve problems, worst first.

### 1.1 Everyone is a tutorial kiosk

Each resident has a "How do you…?" topic where they offer a metaphor, then a definition.

> Tessa: "I keep seeds together in little trays. A list does much the same thing: several things, kept in order." / "Square brackets make a Python list."

A gardener doesn't explain square brackets. The metaphor is stapled onto her, we learn nothing about Tessa, and the explanation repeats what the notebook already says better. Mira (variables), Rowan (loops), Bram (functions) and Nell (if/else) all follow the same template. **Fix:** characters bring *problems*; the notebook brings *syntax*.

### 1.2 Nobody wants anything

Greetings are a job title plus a welcome:

> "Rowan, millwright. Good to meet a pair of hands willing to learn." · "I am Tessa. I look after the gardens and the little orchard."

With no want, trouble or opinion, there's no reason to talk to them twice. **Fix:** every first line carries a want or a small trouble.

### 1.3 Stiff, translated-sounding diction

> "I am Mira." · "You are welcome to visit." · "that is my trade" · "There is more village beyond the mill yard now."

Real people use contractions and drop words. **Fix:** contractions, fragments, interruptions. Read every line aloud.

### 1.4 Directions dressed up as dialogue

> "The old gate leads to North Common and Cedar Rise. The mill bridge opens the Eastbank neighbourhood." · "Each front door leads to its own home." · "Come in from the front doorstep."

These are map labels and interface hints in a costume. **Fix:** the map does navigation. When a character mentions a place, it comes with an opinion: *"Cedar Rise is lovely if you like hills and hate your knees."*

### 1.5 Buttons in people's mouths

> Hotaru: "Test lets you listen first. Speak lets me hear you." · "Apply connects the keys. Then Continue brings you back to me to practise." · Nell: "Your notebook remembers the room you are in."

When a character names an interface control, the world goes flat. **Fix:** the hint line and the notebook name the buttons; characters talk about the world.

### 1.6 Reassurance on a loop

> "That's all right." · "We can take this one step at a time." · "There's no hurry to finish the whole village today." · "A voice and a few steady steps are a good beginning."

Constant soothing makes the companion bland and a little patronising, and it kills momentum. **Fix:** curiosity, confidence, a bit of cheek. Let failure be funny instead of comforted.

### 1.7 The moral at the end

> "One method call changed the world." · "Four lanterns, one loop. The more things there are, the more a loop saves you." · "Your code made a decision instead of just following orders."

Each tells the player what they just learned and how to feel about it. **Fix:** end on something happening in the world: a person reacting, a sound, a consequence, a new question. The notebook can keep one plain factual line if needed.

### 1.8 A character narrating the player's body

> "Your lips move, but no words come yet." · "Hotaru's wings give a quick flutter." (spoken in Hotaru's own speech page)

Stage directions inside a speaker's page read as if the character is describing herself in the third person. **Fix:** narration goes on its own italic page, or into animation.

### 1.9 My own v0.7 sample lines make the same mistakes, just prettier

> Nell: "A routine's just a promise written down. Keep it short and it'll keep you." · Rowan: "The wheel doesn't care what you meant. Only what you wrote." · Mira: "A name is a pin in the map…"

Five people, one narrator, and it's me: tidy aphorisms about programming. They sound wise and say nothing about who these people are. Hotaru's *"Done. I'd like to do that again sometime."* is flat. These are replaced below and in [the characters document](06-characters.md).

### 1.10 One rhythm for everyone

Almost every page is two declarative sentences of 8–14 words. No questions, no one-word answers, nobody talking over anybody. **Fix:** vary length hard. Let people interrupt, answer a question with a question, or trail off.

### 1.11 No jokes

The only joke in the residents' text is "stubborn chairs". **Fix:** every character gets a comic angle that comes from who they are (below). No puns as a substitute.

### 1.12 The player is an interviewer

The apprentice's choices are a menu of questions ("Tell me about the mill."). They have no voice of their own. **Fix:** replies with attitude. Most choices offer an **earnest**, a **wry** and a **blunt** answer, and the reply changes the next line or two, not the plot.

## 2. Before and after

The same moments, rewritten in the new journey's voice:

| Before | After |
|---|---|
| Rowan: "Rowan, millwright. Good to meet a pair of hands willing to learn." | Rowan: *(not looking up from the wheel)* "Mind the walkway. It's wet. It's always wet." · *"You the lodger?"* · *"Hm. Nell said you'd be taller."* |
| Tessa: "I am Tessa. I look after the gardens and the little orchard." | Tessa: "Oh, thank goodness, a person. Can you hold this? Not the hose, the — yes, that. Margit's sulking again." · *"Margit's the pear tree. Don't look at her, she'll think it's pity."* |
| Mira: "You must be the new apprentice. I am Mira. I make maps of the Hollow…" | Mira: "Don't move. You're standing exactly on a corner." · *"Of the map. Forty metres from the gate — forty-two — ugh, now you've moved."* |
| Hotaru: "I can hear you! Now let's give those feet a little direction." | Hotaru: "Nell had a rule: nobody walks around her workshop until they've written down how they walk." · *"She said it as a joke. Once. I wrote it down. I write everything down."* |
| Done text: "Four lanterns, one loop. The more things there are, the more a loop saves you." | Wick, printing tape: "ROUND COMPLETE. FOUR LAMPS. NO COMPLAINTS. STOP." · *"CORRECTION. ONE COMPLAINT. LAMP THREE WOBBLES. STOP."* |

## 3. The rules for writing a line

1. **Characters bring problems; the notebook brings syntax.** No character says "in Python", "variable", "loop" or "function". The one exception is Hotaru reading literal words off her tape ("line 4", "it says *True*"), because she reads code.
2. **Someone wants something right now.** Every scene has a want, and the job is that want.
3. **Specific beats general.** Not "the lamp" but "Albers's lamp". Not "the tram" but "the twenty-to-eight".
4. **Contractions, fragments, interruptions.** If it sounds like a letter, rewrite it.
5. **One idea per page.** One or two sentences, ideally under 140 characters, so it sits comfortably in the dialogue box.
6. **Stage directions are narration.** Italic narration pages, or animation. Never inside a character's speech.
7. **No morals.** End on a reaction, a consequence or a new question.
8. **Failure is funny, not comforted.** A wrong program gets a joke from the world, and the notebook gives the plain explanation.
9. **No buttons in mouths.** Test, Apply, Speak and key names belong to hints and the notebook.
10. **Every voice is different.** Each character has two or three habits (below) that nobody else shares.
11. **Comedy from character.** Hotaru's literalness, Bram's overpromising, Mira's precision, Rowan's deadpan, Tessa's tangents, Nell's understatement.
12. **Earn sentiment by understatement.** Big feelings get the fewest words.

### Banned phrases and habits

- Reassurance tics: "That's all right." "No hurry." "One step at a time." "No pressure." "You've got this."
- Generic praise: "Great job!" "Well done!" "Amazing!" Characters react to *what happened*, not to the player's worth.
- Aphorisms about programming or life ("A routine is a promise…").
- Mirrored sentence pairs ("Not because it's easy. Because it's right."), rule-of-three lists in speech, and em-dash chains.
- Summaries of feelings: "You must be proud." "Isn't it wonderful?"
- Robot clichés for any machine: "beep", "boop", "does not compute", "processing", "as a robot", "I don't have feelings".
- Teacher words in mouths: "concept", "lesson", "practise", "good beginning".

## 4. Voices

### Hotaru
**Core:** earnest, old-fashioned, literal; delighted by small things; sleepy after a quiet week in the loft.
- **Habits:** counts and measures ("Four lamps. Three lit. One sulking."); answers an instruction with "Noted."; takes idioms literally ("Break a leg?" "I'd rather not. I've only just found them."); asks about the day’s ordinary work ("Has Nell been back yet?").
- **Calls the apprentice** "Lodger" until the end of [Light the Hollow](08-quests.md#job-6--light-the-hollow), when she uses their name for the first time. That moment gets no comment from anyone.
- **When code fails** she says exactly where and what she saw, never "error": *"I stopped at line 3. There's a word on the tape I don't know. 'lmap'. Is that a kind of lamp?"*
- **Never** robot clichés, never self-pity, never a speech longer than three pages.

### Nell
**Core:** bone-dry understatement; deflects feeling with chores; fond of machines as old colleagues.
- **Habits:** "Hm." as a full sentence; gives instructions as offhand remarks; says the important thing last, on her way out of the door; calls the apprentice "lodger", lowercase, forever.
- **When moved**, she says less and does something careful with her hands.
- *"Breakfast's on me, then. For a month. I'll regret that."*

### Mira
**Core:** quick, precise, always walking; corrects herself mid-sentence; loves a shortcut.
- **Habits:** measurements as opinions ("It's a nine-minute walk. Seven if you cut through Albers's hedge. Don't tell him."); interrupts her own sentences; can't stand "about".
- *"How far? Not 'a bit'. Nothing is 'a bit'. Everything is a number if you're brave."*

### Rowan
**Core:** deadpan; few words; speaks to the wheel more than to people.
- **Habits:** answers with numbers; long silences (written as a separate "…" page, at most once per scene); says one kind thing a week and then leaves.
- *"…" · "It closed." · "Good."*

### Bram
**Core:** loud, generous, overpromising, starts before he finishes the sentence.
- **Habits:** "Done by lunch!" (it never is); turns tools into verbs ("I'll hammer it into shape. The plan, I mean."); worries about his fence, which nobody has ever touched.
- *"Four! That's what I said." · "You said three-ish." · "Four is a kind of three-ish."*

### Tessa
**Core:** chatty, warm, digressive; has named every tree in the orchard after a relative.
- **Habits:** tangents that loop back; talks to the trees in front of you; gets the point at the very end.
- *"That's Uncle Ferenc. He leans. We don't talk about why."*

### The automatons
Machines other than Hotaru don't speak aloud. They **print tape**, shown in the dialogue box as a strip of ticker tape in telegram style: capitals, short, and "STOP" for full stops. Used sparingly, it's funny and of its era. Each has a personality in what it chooses to print.
- **Wick** (lamplighter): pompous and punctual. *"IT IS 19.42. I AM AT LAMP ONE. I HAVE BEEN AT LAMP ONE SINCE TUESDAY. STOP."*
- **Pip** (post sorter): polite and overwhelmed. *"GOOD MORNING. 214 LETTERS. 0 PIGEONHOLES LABELLED. HELP. STOP. PLEASE. STOP."*
- **Heron** (yard crane): grand and slow. *"I. AM. LIFTING. STOP."*
- **Trowel** (gardener): *"MM. STOP."*

### The apprentice
The player's replies come in three tones: **earnest** (sincere, curious), **wry** (dry, teasing) and **blunt** (straight to the point). They are short, never more than one sentence. The apprentice never explains code in dialogue either.

## 5. The opening script (slice 1)

Format: **Speaker:** line. *Italics* are narration pages. **→** marks the player's reply choices, each followed by the response it gets. Notebook and hint text is listed separately and keeps its plain tutorial voice.

### Scene 1 · First morning (revised 2026-10-27)

The player arrived after dark with a bag and Nell’s address. Their origins remain open. There is no special talent or old mechanical failure to explain.

Nell’s note:

> There’s bread in the tin. I’ll be back around lunchtime.
>
> The little one on the shelf is Hotaru. I’ve been out on calls all week, so she’s mostly been asleep.
>
> The terminal on the desk is linked to Hotaru. Send her a hello if you need a hand.
>
> — Nell.

Test ghost-types the actual program output. Send message delivers the tested words. Other names still print; they do not ring Hotaru’s addressed-message notification. This is an ordinary way to get a dozing companion’s attention, not a repair or magical feat.

### Scene 2 · A sleepy greeting

**Hotaru:** “Oh. Morning.”
**Hotaru:** “You’re the one in the loft, then? I’m Hotaru.”

→ “I got in last night.”
  **Hotaru:** “I heard your bag on the stairs. I thought Nell was moving things again.”
→ “Nell said you could show me around.”
  **Hotaru:** “Of course. She’s left a few things here for you. Have you found the paper drawer?”
→ “Have you been asleep all week?”
  **Hotaru:** “Most of it. Nell’s been taking the calls herself. Is it still morning?”

**Hotaru:** “Nell left you the desk. The drawers stick a little; lift them as you pull.”
**Hotaru:** “There’s a work ticket downstairs. Nell should be back for lunch.”
**Hotaru:** “She came up again after you’d gone to sleep. The board by the bed always gives her away.”
**Hotaru:** “She left something on the quilt. Twelve inches by eight, set down very square.”

→ “What is it?”
  **Hotaru:** “I couldn’t say from here. It’s mostly one flat edge.”
→ “Did she say anything?”
  **Hotaru:** “Only ‘there’. She says that when a thing is sitting right.”
→ “Is it going to bite?”
  **Hotaru:** “It hasn’t moved all night. I’d have heard.”

**Hotaru:** “Pick it up before you go down. She didn’t leave it there for the bed’s benefit.”

The slate is lying on the bed from the first moment, but it can only be lifted once Hotaru has said this; until then the stairs are open and the tablet is simply part of the room. Lifting it opens a short scene. *It is lighter than it looks, and warm from the window. A grey cord trails from one edge and ends in a brass plug no thicker than a pencil.*

**Hotaru:** “That’s the field slate. She used to carry it everywhere.”
**Hotaru:** “She’d hold it against whatever was misbehaving and ask what the matter was.”

→ “Did it ever answer?”
  **Hotaru:** “Mostly it said ‘fault’, in capitals. Nell found that helpful.”
→ “Where does the plug go?”
  **Hotaru:** “The screen downstairs. There’s a socket under the glass, with a brass collar.”
→ “So it’s hers.”
  **Hotaru:** “Was. She put it where you’d trip over it. That’s how she hands things over.”

**Hotaru:** “It’s on the wall by the long bench. The only thing along there that isn’t wood.”

The slate’s first use comes with Nell’s ticket downstairs. Hotaru, asked to show the way: *“Yes. The slate only listens at arm’s length, so we’ll have to stand beside it.”* The ticket scene ends *“The lantern is on the wall at the foot of the stairs. Hold the slate up to it and ask.”* After the lantern lights, she adds *“The screen on the wall reaches all three at once. You’ll have to stand at it, though.”*

The player can return to the same Python page or explore both rooms. The loft's three treads lead to the saved workshop. The playable continuation now uses four scenes: **A place at the bench**, **Nell's work ticket**, **The stair light**, and **The opening round**. A stool left out, a pocket-worn ticket and an unfinished card carry the context; the narrator does not explain what kindness or progress is meant to signify. The bread inspection describes the food and knife without repeating Nell's note. Reading the ticket leads to the method-call page; committing its light leads to a list/loop page. A returned gate complaint closes this chapter. The authoritative prose and replies are in `content/journeys/sparks-and-machines.json`.

### Proposed later scene · Nell returns to the workshop

*The shop doors bang open. A silver-haired woman backs in with a basket of bread, already talking before she's turned round.*

**Nell:** "If you've touched the stove, I'm not sympathetic—"

*She sees Hotaru. She stops.*

**Nell:** "Well."
**Hotaru:** "Morning, Nell. Have you been down to the harbour?"
**Nell:** "Twice. I left the other basket there. Have you two met?"
**Hotaru:** "The lodger found the paper drawer."
**Nell:** "Good. Put the kettle on, would you?"

→ **Earnest:** "Has she been up here all week?"
  **Nell:** "Mostly. I took the outside calls myself."
→ **Wry:** "I found the bread."
  **Nell:** "Good. Leave some for the afternoon."
→ **Blunt:** "Has it been a busy week?"
  **Nell:** "Busy enough. There are two calls left after lunch."

**Nell:** "Right. You're here to learn the trade, so here's the trade." *(She pins a ticket to the job board.)* "The gate lamp. The town used to send a man to light it. The town has stopped sending the man."
**Hotaru:** "Mr. Albers?"
**Nell:** "Retired. Took up bees. Says they listen better."
**Nell:** "There's a wire to it, all the way from the square. Write it a proper instruction and it'll light." · *"Probably."*

*At the door, with her back already turned:*

**Nell:** "And if it doesn't, come and tell me. Don't go poking about in the square."

*The door shuts.*

**Hotaru:** "She said 'don't go poking about in the square'." · *"That means there's something in the square worth poking."*

### Scene 4 · The gate lamp (Job 1)

**Job ticket on the board:** **JOB No. 1 · The gate lamp.** "Light it. — N."
**Notebook:** the method-call page (today's *A spark at the landing* lesson in new words: ask the world for the lamp by its name, then tell the lamp what to do).

**Hotaru's reactions** (one line each; the notebook explains the details):

| What happened | Hotaru |
|---|---|
| Ran the starter unchanged (`set_lit(False)`) | "You asked it very clearly to stay off. It's doing a wonderful job." |
| A misspelt name | "There's a word on the tape I don't know. 'lmap'. Is that a kind of lamp?" |
| Asked for a lamp that doesn't exist | "I don't know a lamp called that. I know the gate lamp. I know a lot about the gate lamp, actually." |
| `true` instead of `True` | "It says *true*, small t. The lamp only listens to the big one. Lamps are snobs." |
| A good preview | "Ooh. It's thinking about it." |

**On Apply:** *The lamp hums, catches, and glows. Down the lane, a window bangs open.*

**Bram:** *(off-screen)* "Oi! Who's lit Albers's lamp?" · *"…Oh. Morning! Nice work! Don't touch my fence!"*

*The window bangs shut.*

**Hotaru:** "That was Bram. He's always worried about his fence." · *"Nobody's ever touched his fence."*

### Scene 5 · The hook

*Walking to the gate, the view opens down the hill: roofs, the harbour, and in the square a little glass dome glowing like a jar of honey.*

**Hotaru:** "There's the Rootwell. It still glows."
*(Her eyes narrow.)*
**Hotaru:** "The needle on its dial is low, though. Lower than I remember."

→ **Earnest:** "Is that bad?"
  **Hotaru:** "It was higher when Nell took me past on Monday."
→ **Wry:** "Maybe it's tired too."
  **Hotaru:** "Dials don't get tired." · *"Nell should have a look at it."*
→ **Blunt:** "How low?"
  **Hotaru:** "Four marks. Maybe five. I'm counting from up here, so don't hold me to it."

**Hotaru:** "Nell said not to go poking about in the square." · *"She didn't say anything about looking at it very closely."*

*End of the first morning.*

## 6. Notes for whoever implements this

- Today's dialogue system already supports guided sequences, topics and response choices ([pipeline/DIALOGUE.md](../../../pipeline/DIALOGUE.md)). Narration pages and three-tone replies fit within it. Telegram tape for automatons needs a small presentation variant of the dialogue box.
- Keep every page to one or two sentences. Where this script shows *"…"* or a second quoted sentence after a ·, that's a new page.
- Replies change the next line or two and converge; they never branch the quest.
- Writers should reread [the rules](#3-the-rules-for-writing-a-line) and [the banned list](#banned-phrases-and-habits) before writing new lines, then read each scene aloud.
