class_name LoadModal
extends Modal
## The title's load screen: a SavesBrowser in its landscape layout. On the field tablet the same
## browser is the Saves app (docs/concept/save-vcs/PLAN.md).

signal load_requested(slug: String)
signal deleted

var browser: SavesBrowser


func setup(owner: Game) -> void:
	card.custom_minimum_size = Vector2(1260, 700)
	title_row("Load a save", "Every profile is a repository; every commit is a save. Pick a commit, or type the command yourself.")
	browser = SavesBrowser.new()
	browser.setup(owner, false)
	browser.load_requested.connect(func(slug: String) -> void: load_requested.emit(slug))
	browser.deleted.connect(func() -> void: deleted.emit())
	browser.closed.connect(close)
	body.add_child(browser)


## The command line and output, for tests and scripted lessons.
var _command: LineEdit:
	get: return browser._command
var _output: RichTextLabel:
	get: return browser._output
var _graph: HistoryGraph:
	get: return browser._graph
func run_command() -> void:
	browser.run_command()
