# Learning the tablet — Hotaru's hand-held introduction

**Status: implemented 2026-11-18** (`app/tablet_lesson.gd` runs it; the steps live in the `lessons` block of
`content/journeys/sparks-and-machines.json`; the strip, ring and example tree are in `ui/tablet/` and
`ui/screens/saves_browser.gd`; `test/test_app.gd` drives every step). The script in §4 is the one that shipped, with
the example tree moved ahead of the first commit as decided during review. This is the first lesson of the v0.9
curriculum and the template for later ones.

## 1. What it teaches, and what it does not

The lesson covers exactly what the tablet can do today:

| Part | The player ends up able to |
| --- | --- |
| Taking it out, the home key | Open the slate (Esc or the HUD's menu button), return to the home screen with the round key, put it away by tapping beside it or pressing Esc at home. |
| Terminal | Read `git status`; stage with `git add .`; save with `git commit -m "…"`; see the saves with `git log --oneline`; know that `reset`, `logout` and `quit` are commands; know that `help` exists. |
| Saves | Read the graph: the green edge is *you are here*, HEAD → main is the current save line, each dot a commit; use the filled-in command line to go to another commit; understand that a branch is a save line and `git switch -c` makes one. |
| Settings | Find the interface size and code text size; know Done returns home. |
| The rule | Nothing is saved until it is committed. Leaving with uncommitted changes asks once and then loses them. |

It does **not** teach `diff`, `stash`, `restore`, `tag`, `checkout` of old commits, `config`, branches beyond
the idea of one, or anything about Journal and Map. Those are later lessons (§7), each a separate chapter in the
same framework, so this document stays short and the first session stays under four minutes.

## 2. Where it happens

**Trigger.** The moment the *tablet-taken* scene ends (the player picks the slate up off the bed in the loft; the
existing scene in `content/journeys/sparks-and-machines.json`). Hotaru is already talking; the lesson is the next
thing he says. If the player somehow has the tablet without the scene (a development checkpoint), the first time
the slate is opened Hotaru offers the lesson instead.

**The offer.** One page, two choices, no third:

> **Hotaru:** Nell's slate has a mind of its own. Want me to walk you through it, or do you know your way around one?
> - *Please show me.* → the lesson starts.
> - *I already know how to use the tablet.* → `tablet-tutorial` is marked read with `skipped`; Hotaru says one line
>   ("Then I'll stay out of your way. It's `help` in the Terminal if that changes.") and the game goes on.

Skipping is the single confirmation the design asks for: it is not a settings toggle and there is no "are you
sure". The lesson can be started again later from the Terminal with `tutorial` (§6), so skipping costs nothing.

**Completion.** `dialogue_read["tablet-tutorial"]` gains `done` (or `skipped`). It is saved like every other read
marker, so it versions with the journey and a `git checkout` of an older commit can bring it back, which is itself a
tidy demonstration later.

## 3. How a hand-held lesson works (the framework)

A lesson is a list of **steps** in content, not code. Each step says what Hotaru says, what the tablet should show,
what the player has to do before the lesson moves on, and what to do if they wander off. `app/tablet_lesson.gd`
(new) runs a lesson over the live `TabletShell`; `content/journeys/sparks-and-machines.json` gains a `lessons`
block beside `scenes`.

```json
"lessons": {
  "tablet-tutorial": {
    "title": "Nell's slate",
    "speaker": "hotaru",
    "steps": [
      {"say": "Press Escape, or the menu button in the corner. Go on.", "wait": "tablet_open"},
      {"say": "Home screen. Five things it can do, for now. The round key under the glass always brings you back here.",
       "point": "home_key", "wait": "continue"},
      {"say": "Open the Terminal.", "point": "app:terminal", "wait": "app:terminal"},
      {"say": "This is how the slate remembers things. Nothing is kept until you tell it to. Ask it what has changed:",
       "command": "git status", "wait": "ran:git status"},
      ...
    ]
  }
}
```

The fields a step may use:

| Field | Meaning |
| --- | --- |
| `say` | Hotaru's line, shown in a slim speech strip along the slate's status bar (not the full dialogue window, which would cover the tablet). One or two sentences; the voice rules in [v0.7 dialogue](../v0.7/07-dialogue.md) apply. |
| `point` | What to highlight: `home_key`, `app:<name>`, `status_bar`, `terminal_input`, `saves:graph`, `saves:branches`, `saves:command`, `settings:<key>`. The tablet draws a brass ring and dims the rest. |
| `command` | A command the player is expected to type. The terminal shows it as ghost text in the input until they type it; Tab accepts it. They can still type anything else. |
| `wait` | What advances the step: `continue` (a Next button in the strip), `tablet_open`, `app:<name>`, `home`, `ran:<prefix>` (any command starting with it was run and succeeded), `committed`, `switched`, `closed`. |
| `if_wrong` | Optional line when the player runs a different command instead (`"Not yet. Try the one I said."`). The lesson never blocks other commands; it waits. |
| `allow_skip` | Default true: the strip always has a small *skip the rest*, which marks `done`. |

Steps run strictly in order. If the player closes the tablet mid-lesson, the strip waits off-screen and the lesson
resumes from the same step when the slate is next opened; Hotaru's first line on resume is the step's `say` again.
Lessons are data, so a new app adds a new lesson (or a step) without touching the runner.

## 4. The script

Twenty-two steps in three movements: *read a tree* (on an invented example, so there is something to read),
*grow yours* (the first real commit), *the rest of the slate*. Bracketed text is staging; the lines are Hotaru's.

1. *(wait: tablet_open)* "Press Escape, or the menu button in the corner. Go on."
2. *(point: home_key)* "Home screen. Five things it can do, for now. The round key under the glass always brings you
   back here, whatever is on it."
3. *(point: app:saves, wait: app:saves)* "Open Saves first. I want to show you how the slate remembers things before
   you make it remember anything."
4. *(phantom example tree on; point: saves:graph)* "This one is an example, not yours. Every dot is a commit: a
   moment you told the slate to keep. Newest at the top."
5. *(phantom)* "The line is time. Where it forks, someone tried something without spoiling the main line. That's a
   branch. The green edge is where you are standing."
6. *(phantom; point: saves:branches)* "The branches are named up here. The filled one is the line you're on."
7. *(phantom; wait: graph_tap)* "Tap any dot."
8. *(phantom; point: saves:command)* "See the command fill itself in? That's how you'd go there: `git switch` for a
   line, `git checkout` for a single dot. Run it and the world becomes that moment. Not now."
9. *(phantom off: the player's own tree, one dot)* "Now yours. One dot: the slate made it when you arrived. Let's
   give it a second."
10. *(point: home_key, wait: home)* "Home, then the Terminal."
11. *(point: app:terminal, wait: app:terminal)* "The Terminal. That's where you tell the slate what to keep."
12. *(ghost: `git status`, wait: ran)* "Ask it what has changed since that first dot."
13. *(ghost: `git add .`)* "Red is changed and not kept. Two steps keep it. First you choose what to keep. The dot
    means here, all of it."
14. *(ghost: `git commit -m "Picked up Nell's slate"`, wait: committed)* "Then write down what you did, and commit to
    it. The words in quotes are for you, later, when you have forgotten."
15. *(ghost: `git log --oneline`)* "Every commit is a line here, newest first. That short code is its name."
16. "That's saving. If you leave without committing, the slate asks once, and then it's gone. Nell lost a week that way."
17. *(wait: home)* "Home, and look at Saves again."
18. *(wait: app:saves)* "Saves."
19. *(point: saves:graph)* "Two dots. Yours is the top one, and the green edge moved up with it. That's the whole
    trick: commit often, and the tree grows."
20. *(wait: home)* "Last thing: Settings."
21. *(wait: app:settings)* "Settings."
22. *(point: settings:ui_scale)* "If the writing is small, this one. Done takes you home. That's the slate. `help` in
    the Terminal says the rest, and I'm not going anywhere." *(marks `done`)*

A wrong command at steps 12–15 does not advance the lesson; Hotaru's `if_wrong` line appears under his own. A step
that waits for a screen already on show (home, when the slate opens on home) is met at once.

The earlier draft, kept for the record:

1. *(wait: tablet_open)* "Press Escape, or the menu button in the corner. Go on."
2. *(point: home_key, wait: continue)* "Home screen. Five things it can do, for now. The round key under the glass
   always brings you back here, whatever is on it."
3. *(point: app:terminal, wait: app:terminal)* "Open the Terminal. That's where the slate remembers things."
4. *(command: `git status`, wait: ran:git status)* "It keeps a record of your work, but only when you tell it to.
   First ask what has changed since the last record."
   *(The tree is dirty: the tablet pickup changed `rooms/workshop-loft/state.json`. The output shows it in red.)*
5. *(wait: continue)* "Red means changed and not yet kept. Two steps keep it. First you choose what to keep…"
6. *(command: `git add .`, wait: ran:git add)* "…`git add .` chooses everything. The dot means *here, all of it*."
7. *(command: `git commit -m "Picked up Nell's slate"`, wait: committed)* "Then you write down what you did and
   commit to it. The words in quotes are for you, later, when you have forgotten."
8. *(command: `git log --oneline`, wait: ran:git log)* "Every commit is a line here, newest first. That short code is
   its name. You already have two: one the slate made when you arrived, and yours."
9. *(wait: continue)* "That's saving. If you leave without committing, the slate asks once, and then it is gone. Nell
   lost a week that way. Now the other half."
10. *(point: home_key → wait: home; then point: app:saves, wait: app:saves)* "Home, then Saves."
11. *(point: saves:graph, wait: continue)* "Same commits, drawn. The green edge is where you are. `main` is your save
    line; a branch is just another line, if you ever want to try something without spoiling this one. The command at
    the bottom is already filled in for whatever you tap. You don't need it now; you're already here."
12. *(point: home_key → wait: home; point: app:settings, wait: app:settings; then point: settings:ui_scale, wait:
    continue)* "Last thing. Settings. If the writing is small, this one. Done takes you home. That's the slate.
    `help` in the Terminal says the rest, and I'm not going anywhere."
    *(The lesson marks `done`; the strip closes; the tablet stays open.)*

Lines 4–8 use the real wording because the commands are real; Hotaru never says "save" for `commit` except in line
9, where he says what the metaphor is. He does not explain staging as a concept; he shows the two steps and names
them. The lesson ends inside Settings on purpose: the player's last action is one they chose.

## 5. What the tablet needs for it

- `TabletShell`: a **lesson strip** (speaker name, one line, Next/skip) that sits over the status bar; a
  **highlight** (`point(target)`) that rings a control and dims the rest; signals already present (`ran` from the
  terminal) plus `app_opened(name)` and `home_shown`.
- `TerminalApp`: **ghost text** for `command` (grey, Tab to accept) and a `ran(line, ok)` signal carrying the line.
- `SavesBrowser`: `point` targets for the graph, the branch chips and the command line.
- `Game`: starts `tablet-tutorial` after the *tablet-taken* scene unless `dialogue_read` has it; routes the Terminal
  command `tutorial` (§6).
- Content: the `lessons` block and the offer page appended to *tablet-taken*.

Tests: a flow test runs the lesson headless by calling the same signals the player would cause (open, app, run
`git status`, `git add .`, commit, log, home, saves, settings) and checks that each step advances only on its own
condition, that a wrong command does not advance it, that closing and reopening the tablet resumes the same step,
and that both answers to the offer leave the right marker. The review capture adds the strip and a highlight.

## 6. Returning to it

`tutorial` in the Terminal lists the lessons that exist and starts one: `tutorial tablet` runs this lesson again
from step 2 (the slate is already open). The list is the `lessons` block, so later lessons appear there by
existing. A lesson already `done` is still runnable; it just does not change the marker.

## 7. What comes after (not in this lesson)

Each is a separate `lessons` entry, offered by the character it belongs to, when the thing it teaches first matters:

- **Looking back** — `git log` in full, `git checkout <id>` to look at an old commit, detached HEAD, and
  `git switch main` to come back. Offered the first time the player returns to the loft after Spindle Lane.
- **What changed** — `git diff` and `git diff --staged` on a program file, so the player sees their own Python
  change line by line. Offered by Nell with the first lamp routine.
- **Two lines** — `git switch -c`, working on a branch, switching back; branches as experiments. Offered before the
  square's layout job, where trying things is the point.
- **Putting work aside** — `git stash`, `git stash pop`; `git restore` for a mistake. Offered when a scene
  interrupts work.
- **Your slate, your colours** — `git config theme`, `prompt.format`, `color.*`. No offer; it is in `help`.
- Journal and Map lessons when they become tablet apps.

Each later lesson reuses the runner and the strip unchanged; what they add is content and, at most, a new `point`
target.
