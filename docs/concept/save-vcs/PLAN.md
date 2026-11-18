# Save/Load as Version Control — design and implementation plan

Status: phases 1–4 implemented 2026-11-18 (`app/vcs.gd`, `app/vcs_diff.gd`, `app/save_repo.gd`,
`app/git_shell.gd`, `app/history_lanes.gd`, `ui/tablet/`, `ui/screens/load_modal.gd`,
`ui/screens/history_graph.gd`; tests `test/test_vcs.gd` and the terminal section of `test/test_app.gd`;
captures `tools/reviews/save_vcs_review.gd`). Phase 5 has begun: Hotaru's hand-held tablet lesson
(`app/tablet_lesson.gd`, [v0.9](../v0.9/tablet-tutorial.md)) shipped the same day; the later lessons,
error explanations and `merge` remain. Decisions taken that day: **in-game VCS engine** (no real git binary, no
stray .json repos — it looks and feels like git but is the game's own save system),
**unforgiving by design** (no safety net git doesn't have; a dirty-quit warning when a
meaningful amount changed is the only mercy), **split, diffable save files including the
player's programs** (the player's Python sources are tracked files so `diff` shows their code),
**interactive clickable commit-graph load modal** on the main menu, and the save format is a
clean break — the legacy "lamps burning" summary metrics (scrapped campaign) go with autosave. Replaces the silent autosave system with a player-facing,
1:1-vocabulary git workflow: saving is `git commit`, loading is `git checkout`, save files are
branches, all driven through an in-world tablet terminal. The goal is real-world practice:
vocabulary, commands and process match actual git, the same way player Python is real Python.

## 1. What exists today (the autosave audit)

One JSON slot per journey, written silently and often. Everything below is the surface to gut.

### Storage (`app/save_store.gd`, 124 lines)
- `user://rootward.save.<level>.json` single slot; `user://profile.json` holds player name +
  last level; legacy Kindle Hollow fallback (`_retire_legacy`); `.dev.json` variant for dev mode;
  `VOXEL_LAB_FRESH` / `force_enabled` test plumbing.
- `SaveMigration.upgrade()` + `GameSession.SAVE_VERSION` versioning.

### Autosave triggers — all in `app/game.gd` unless noted
Debounced timer path (`_save_timer` → `save_now`, created at game.gd:174–177):
- game.gd:148 `session.progress_saved` → `_queue_save(0.4)` (quest progress; emitted from
  game_session.gd:829 on any quest change)
- game.gd:149 `session.source_changed` → `_queue_save(1.6)` (every code edit!)
- game.gd:462 (`_queue_save(2.0)`), 1257 (0.4), 1418 (0.4), 1979 (0.2)

Immediate `save_now()` calls (~25): entering play (379), quit (387), prop use (609), Nell's
note (625), terminal connect (645), pickups (660), room enter/exit (851, 904, 1066, 1110),
journal applied (1182), Hotaru intro (1193), story scenes (1272), build/layout commits (1383,
1396), dev panel (1436–1458), opening pause (1484), return to title (1609), bank transfer
(2006), evening start (2026). Plus `app/development_mode.gd:24,82`.

Window close: game.gd:1134 `NOTIFICATION_WM_CLOSE_REQUEST` → save-and-quit.

`save_now()` itself (game.gd:391–411) assembles interior/exterior/journey-room saves
(`_outer_save`, `_rooms`, `_journey_rooms`) before `SaveStore.write`. **That assembly logic
stays** — it is "build the working-tree snapshot," independent of when/why we persist it.

Consumers to keep in mind: `title_screen.gd` Continue (reads the slot via
`Game.continue_summary`), `pause_menu.gd` ("saved automatically" messaging), tests
(`test_app`, `test_development`, smoke, flow tests, `tools/reviews/*` call `game.save_now()`),
`docs/` and `pipeline/UI.md:60` mention autosave.

### Verdict
The *snapshot assembly* (`save_now`'s data building, `session.to_save()`, migration) is sound
and reused. What goes: the `_save_timer`, both `_queue_save` connections and all `_queue_save`
/ mid-gameplay `save_now()` call sites, and the "it saves by itself" promise in UI/docs.

## 2. The new model

Real git repositories, one per profile, with the save JSON as tracked files. Not a git-themed
fake: we shell out to the real `git` binary (or fall back to a bundled minimal implementation —
see Open questions) so `log`, `branch`, `checkout`, `diff`, `stash` behave exactly as at work.

- **Profile** = a directory `user://profiles/<name>/` containing a real git repo whose working
  tree is the save files (`rootward.save.<level>.json`, split per-room files later if diffs
  should read better) plus `profile.json`.
- **Save** = the player opens the tablet terminal and runs `git add -A` (or `git add <file>`)
  and `git commit -m "before the tram sign job"`. No commit, no save. Uncommitted progress is
  the "working tree" and is lost on quit — the game warns exactly like a real tool:
  "You have uncommitted changes."
- **Save files/slots** = branches. `git branch experiment && git switch experiment`.
- **Load** = `git checkout <ref>` / `git switch <branch>` from the terminal, or point-and-click
  from the load modal's commit graph (which runs the same commands and shows them, so the GUI
  teaches the CLI).
- The game itself writes the working tree (the snapshot assembly keeps running on the same
  events autosave used — but writing only to the *working tree*, never committing). So
  `git status` / `git diff` always show honestly what changed since the last save.

### Player-facing pieces
1. **Profile select** (new, before title journey choice): create/choose a profile;
   creating one runs `git init` + first commit ("journey begins") visibly.
2. **Main-menu Load modal**: commit graph (gitk-style lanes, branch labels, HEAD marker),
   click a node → shows `git switch`/`checkout` command → confirm runs it and starts the game
   from that commit.
3. **The tablet** (in-game): Esc / tablet key no longer opens `pause_menu.gd`'s plain list —
   it "opens the tablet" the character carries (the field tablet already exists in fiction and
   `ui/code/tablet_screen.gd` exists for code). Tablet home screen has app tiles: Terminal,
   Jobs, Map, Settings, Character, Quit. Existing screens become tablet apps.
4. **The terminal app**: high-fidelity terminal — monospace, truecolor ANSI, a configured
   prompt (`wren@haverlund ~/journey (main) $` with dirty-state `*` like a real PS1), colored
   `git log --oneline --graph`, `git status` red/green, history (↑), tab-completion for
   subcommands/branches, `clear`, scrollback. Non-git niceties (`ls`, `cat` of save files,
   `help`) keep it friendly.

### Vocabulary contract (1:1 with real git)
Supported verbs at launch: `init` (profile creation only), `status`, `add`, `commit -m`,
`log` (`--oneline --graph --all`), `branch`, `switch`/`checkout`, `diff`, `restore`,
`tag`, `stash` (push/pop/list), `merge` deferred (see Open questions), `revert`/`reset`
gated behind a later "advanced" unlock. Errors are real git's errors, lightly explained
underneath by the notebook-style plain-words helper (same property as the Python sandbox:
real tool, friendly annotation).

## 3. Architecture (follows the repo's core/scenes/ui/app split)

- `core/` — nothing; saves aren't world rules.
- `app/save_repo.gd` (new): owns the profile directory, wraps `git` via `OS.execute` on a
  worker thread (same pattern as the Python runner: never block the scene). API:
  `status()`, `commit(msg)`, `log()`, `checkout(ref)`, `branches()`, `raw(argv)` for the
  terminal passthrough, plus `working_tree_write(data, level)` replacing `SaveStore.write`.
  All output captured structured (exit code, stdout, stderr) for both GUI and terminal.
- `app/save_store.gd`: shrinks to working-tree file IO inside the active profile dir; keeps
  migration, `VOXEL_LAB_FRESH`, dev-mode behavior. Legacy single-slot save is imported into a
  new profile's first commit on first run, then retired (extends the existing legacy pattern).
- `app/game.gd`: `_save_timer`/`_queue_save` deleted; the ~30 trigger sites become
  `sync_working_tree()` (cheap, same assembly, no commit). Quit path checks
  `SaveRepo.dirty()` → "uncommitted changes" confirm dialog.
- `ui/tablet/` (new): `tablet_shell.gd` (the modal, device frame, app grid),
  `terminal_app.gd`, `history_graph.gd` (shared by terminal `log --graph` render and the
  main-menu Load modal), existing screens wrapped as apps.
- `ui/screens/title_screen.gd`: Continue → profile list + Load modal; summary line comes from
  HEAD commit of each profile (`git log -1 --format=...`).

## 4. Phased implementation (each phase leaves the game launchable)

What shipped differs from the sketch below in a few places, all recorded here: the engine is in-game
(`Vcs`, not a git binary); the internal log method is `history()` because GDScript's `log()` shadows
it; `SaveRepo.split/join` writes canonical JSON (sorted keys, whole floats as ints, the derived
`state.time`/`state.city_power` and sub-minute clock left out) so the tree only changes when the game
does; the tablet is the painted field slate itself (the nine-slice frame the code pages use) with a home screen of apps,
the terminal filling its glass and the slate's keys on the painted ledge; room reset, logout and quit are terminal
commands (`reset`, `logout`, `quit`); the title has no Continue and no Character entry, only New game and Load game;
the load screen is a repository browser (profiles top to bottom with commit and branch counts, the commit graph,
git-like properties of the selected commit, and a command line pre-filled with the command that loads it, which the
player runs); and `merge`,
`rebase` and remotes answer with a message saying they are not on this tablet.

**Phase 1 — Gut autosave, explicit working tree.** Remove `_save_timer`, `_queue_save`, timer
wiring; rename `save_now` → `sync_working_tree`; keep quit/close-request write (temporarily —
removed in phase 3); update pause-menu copy, `pipeline/UI.md`, tests that assert autosave
timing. Tests/reviews calling `game.save_now()` switch to the new name.

**Phase 2 — SaveRepo + profiles.** `app/save_repo.gd`, profile directories, `git init` on
create, legacy-save import, profile select screen before the title's journey list. Saving still
implicit-commit-on-quit so the game stays finishable mid-feature. New `test_save_repo.gd`
(headless git fixtures in scratch dirs; quick tier) — must pass with git absent (skip visibly
or fallback, per Open questions).

**Phase 3 — Terminal app + tablet shell.** Tablet modal replaces pause menu; terminal with
prompt/colors/history/completion; commit/status/log/branch/switch wired; remove
commit-on-quit, add the dirty-quit warning. Flow test: play, edit world, `status` shows dirty,
`commit`, quit, relaunch, `log` shows it, `checkout` an older commit restores state.

**Phase 4 — Load modal + graph.** `history_graph.gd` lane-layout over `git log` parse; main
menu Load; clicking teaches the equivalent command.

**Phase 5 — Polish & curriculum.** `diff`/`restore`/`stash`/`tag`; notebook-style error
explanations; a Field Notes chapter teaching the workflow in-story (Nell hands over the
tablet: "commit your day's work before supper"); docs (`PROJECT_HANDOFF`, `UI.md`, README
persistence row).

## 5. Decisions (settled 2026-11-18)

1. **In-game VCS engine, not real git.** `app/vcs.gd` implements the repository itself
   (content-addressed snapshots, branches, HEAD, index, log, unified diff) in typed GDScript
   over the profile directory. Vocabulary, command grammar and error wording copy git exactly;
   the implementation is ours, ships with the game, and never writes outside the profile dir.
   This is the save/load system with flair — no hidden second store.
2. **Granular, diffable working tree.** The session snapshot is split into small tracked
   files: per-room state, quest ledger, accounts/clock, layout edits, and — first-class —
   the player's Python programs as real `.py` files, so `git diff` shows their code changing
   between saves and merges become legible later. `merge` itself stays deferred until the
   split format has proven itself.
3. **Unforgiving on purpose.** Quit/crash without committing loses everything since the last
   commit; no stash-on-crash, no shadow autosave — no safety net real git doesn't give you.
   The one mercy: a "you have uncommitted changes" warning on quit when a meaningful amount
   has changed since HEAD (measured from `status`, same information git would give).
4. **Load modal is a real interactive graph.** Clickable commit-tree with lanes, branch
   labels, HEAD, messages, timestamps, author and per-commit summary (quests done, places
   found) — easy to read for someone who has never seen gitk, while showing the equivalent
   command it runs.
5. **Legacy gut rides along.** The "lamps burning" save-summary metrics (title Continue line,
   character sheet row, `_saved_lamps`) are from the scrapped lamp-campaign; they are removed
   with autosave. Live lamp *state* stays — quests still light lamps.
6. **Customizable.** Profile-level config (tracked file in the repo, so it versions too):
   terminal prompt format and palette, graph colors, author name; room to grow.
7. **Esc ladder.** Tablet replaces pause; Esc inside a tablet app goes app → home → closed,
   matching the existing modal-stack rules in `pipeline/UI.md`.
