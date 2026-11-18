class_name TabletShell
extends Modal
## The field tablet the lodger carries, taken out with Escape. It is the painted slate itself
## (`assets/ui/nells-field-slate`, the same nine-slice frame the code pages use): the glass in its
## window shows a home screen of apps, and opening one changes the whole screen, the way a tablet
## does. The terminal app is where saving and loading happen (git over the journey's own repository,
## docs/concept/save-vcs/PLAN.md). It is the same slate the code pages use, at the same size. The one
## key on the painted ledge is Home; Log out and Shut down sit in the status bar's corner. Escape
## inside an app returns home; Escape at home, or a click outside the slate, puts it away.

signal journal_requested
signal map_requested
signal load_requested(slug: String)
signal title_requested
signal quit_requested
## For lessons (TabletLesson): what the player did on the slate.
signal app_opened(name: String)
signal home_shown
signal command_ran(line: String, ok: bool)
signal graph_tapped(id: String)
signal lesson_next_pressed
signal lesson_skip_pressed

const GLASS: Color = Color("12161a")
const BAR: Color = Color("1b2026")
const LEDGE_HEIGHT: float = 92.0
const MARGIN: float = 16.0

var game: Game
var _glass: PanelContainer
var _bar: HBoxContainer
var _bar_title: Label
var _bar_clock: Label
var _bar_status: Label
var _screen: Control
var _app: Control
var _first: Control
var _player: String = ""
var _place: String = ""
var _frame_box: StyleBox
var _framed: bool = false
var _icons: Dictionary = {}
var _home_key: HomeKey
var _strip: PanelContainer
var _strip_speaker: Label
var _strip_text: RichTextLabel
var _strip_note: Label
var _strip_next: FButton
var _strip_skip: FButton
var _overlay: LessonOverlay
## The app on screen: "", "terminal", "saves", "settings".
var app_name: String = ""


func setup(owner: Game, player_name: String, place: String, _indoors: bool = false) -> void:
	game = owner
	_player = player_name
	_place = place
	_fit()
	owner.settings.changed.connect(func(key: String) -> void:
		if key == "ui_scale": _fit.call_deferred())
	var painted: Dictionary = TabletScreen.painted_frame()
	_framed = not painted.is_empty()
	card.add_theme_stylebox_override("panel", _frame_style(painted))
	body.add_theme_constant_override("separation", 0)
	# The glass: a status bar, then the screen.
	_glass = PanelContainer.new()
	var glass_box := StyleBoxFlat.new()
	glass_box.bg_color = GLASS
	glass_box.set_corner_radius_all(6 if _framed else 10)
	glass_box.set_content_margin_all(0)
	_glass.add_theme_stylebox_override("panel", glass_box)
	_glass.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_glass.clip_contents = true
	body.add_child(_glass)
	var column := UI.vbox(0)
	_glass.add_child(column)
	var bar := PanelContainer.new()
	var bar_box := StyleBoxFlat.new()
	bar_box.bg_color = BAR
	bar_box.content_margin_left = 16
	bar_box.content_margin_right = 16
	bar_box.content_margin_top = 6
	bar_box.content_margin_bottom = 6
	bar.add_theme_stylebox_override("panel", bar_box)
	column.add_child(bar)
	_bar = UI.hbox(12)
	bar.add_child(_bar)
	_bar_clock = _bar_label("")
	_bar_clock.add_theme_font_override("font", UITheme.mono_font())
	_bar.add_child(_bar_clock)
	_bar_title = _bar_label("")
	_bar_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bar.add_child(_bar_title)
	_bar_status = _bar_label("")
	_bar_status.add_theme_font_override("font", UITheme.mono_font())
	_bar.add_child(_bar_status)
	var logout := UI.icon_button(&"door", "Log out · back to the title", func() -> void: title_requested.emit())
	_bar.add_child(logout)
	var shutdown := UI.icon_button(&"cross", "Shut down · quit the game", func() -> void: quit_requested.emit())
	_bar.add_child(shutdown)
	_screen = Control.new()
	_screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_screen)
	# The lesson strip: Hotaru's line along the bottom of the glass, hidden until a lesson speaks.
	_strip = PanelContainer.new()
	var strip_box := StyleBoxFlat.new()
	strip_box.bg_color = Color("1f2a2a")
	strip_box.border_color = Pal.TEAL
	strip_box.border_width_top = 2
	strip_box.content_margin_left = 16
	strip_box.content_margin_right = 12
	strip_box.content_margin_top = 8
	strip_box.content_margin_bottom = 8
	_strip.add_theme_stylebox_override("panel", strip_box)
	_strip.visible = false
	column.add_child(_strip)
	var strip_row := UI.hbox(12)
	_strip.add_child(strip_row)
	var words := UI.vbox(2)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip_row.add_child(words)
	_strip_speaker = UI.caps("Hotaru", Pal.TEAL)
	words.add_child(_strip_speaker)
	_strip_text = RichTextLabel.new()
	_strip_text.bbcode_enabled = true
	_strip_text.fit_content = true
	_strip_text.scroll_active = false
	_strip_text.add_theme_font_size_override("normal_font_size", 16)
	_strip_text.add_theme_font_override("mono_font", UITheme.mono_font())
	_strip_text.add_theme_color_override("default_color", Color("efe6d2"))
	words.add_child(_strip_text)
	_strip_note = UI.label("", &"LabelDim", 13)
	_strip_note.visible = false
	words.add_child(_strip_note)
	var strip_buttons := UI.vbox(4)
	strip_row.add_child(strip_buttons)
	_strip_next = UI.button("Next", &"chevron", &"ButtonPrimary", func() -> void: lesson_next_pressed.emit())
	_strip_next.custom_minimum_size = Vector2(120, 36)
	strip_buttons.add_child(_strip_next)
	_strip_skip = UI.button("Skip the rest", &"", &"ButtonQuiet", func() -> void: lesson_skip_pressed.emit())
	_strip_skip.custom_minimum_size = Vector2(120, 28)
	strip_buttons.add_child(_strip_skip)
	# The ledge under the glass: the slate's one key.
	var ledge := CenterContainer.new()
	ledge.custom_minimum_size.y = LEDGE_HEIGHT
	_home_key = HomeKey.make(show_home)
	ledge.add_child(_home_key)
	body.add_child(UI.margin(ledge, 26, 18, 26, 0))
	_overlay = LessonOverlay.new()
	add_child(_overlay)
	show_home()


## The slate at the size the code pages use: the jobs journal's drawer width, the screen's height
## less the drawer margins. `screen` is the viewport at interface scale 1.
static func slate_size(screen: Vector2) -> Vector2:
	return Vector2(clampf(screen.x * 0.47, 740.0, 980.0), maxf(560.0, screen.y - MARGIN * 2.0))


## The slate keeps the same place on the screen whatever the interface scale: its size is worked
## out for the viewport as it is at scale 1, then divided by the scale the interface is drawn at.
func _fit() -> void:
	var scale: float = game.get_window().content_scale_factor if game != null and game.is_inside_tree() else 1.0
	var screen: Vector2 = game.get_viewport_rect().size
	# Width as the code slate's drawer has it; height as the drawer has it (the screen less its margins).
	card.custom_minimum_size = Vector2(slate_size(screen * scale).x / maxf(scale, 0.01), maxf(560.0, screen.y - SideDrawer.MARGIN * 2.0))


func open() -> void:
	super.open()
	refresh_status()
	if _app == null and _first != null:
		_first.grab_focus()


## The home screen: the apps.
func show_home() -> void:
	_clear_screen()
	_app = null
	_bar_title.text = ""
	var centre := CenterContainer.new()
	UI.full_rect(centre)
	_screen.add_child(centre)
	var column := UI.vbox(10)
	centre.add_child(column)
	var greeting := UI.label(_player, &"LabelHeading", 30)
	greeting.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	greeting.add_theme_color_override("font_color", Color("f1ead9"))
	column.add_child(greeting)
	var place := UI.label(_place, &"LabelDim", 15)
	place.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(place)
	column.add_child(UI.spacer(16))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 18)
	var holder := CenterContainer.new()
	holder.add_child(grid)
	column.add_child(holder)
	_first = null
	_icons.clear()
	var pending: int = SaveRepo.uncommitted_changes().size()
	for spec: Array in [
			["terminal", "Terminal", &"code", Color("1f6f6a"), open_terminal, str(pending) if pending > 0 else ""],
			["journal", "Journal", &"scroll", Color("8c6a2c"), func() -> void:
				app_opened.emit("journal")
				journal_requested.emit(), ""],
			["map", "Map", &"map", Color("3d6b3a"), func() -> void:
				app_opened.emit("map")
				map_requested.emit(), ""],
			["saves", "Saves", &"book", Color("5a4a8a"), open_saves, ""],
			["settings", "Settings", &"gear", Color("4b5563"), open_settings, ""]]:
		var icon := AppIcon.make(spec[1], spec[2], spec[3], spec[4])
		icon.badge = spec[5]
		grid.add_child(icon)
		_icons[spec[0]] = icon
		if _first == null:
			_first = icon
	app_name = ""
	home_shown.emit()
	column.add_child(UI.spacer(18))
	var hint := UI.label("Saving is git: open the Terminal and commit.  ·  reset, logout and quit are commands too.", &"LabelDim", 13)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)
	refresh_status()
	if _first != null:
		_first.grab_focus.call_deferred()


## The terminal takes the whole screen.
func open_terminal() -> void:
	_clear_screen()
	_bar_title.text = "Terminal"
	var terminal := TerminalApp.new()
	terminal.setup(game.make_shell())
	terminal.exit_requested.connect(show_home)
	terminal.ran.connect(refresh_status)
	terminal.command_ran.connect(func(line: String, ok: bool) -> void: command_ran.emit(line, ok))
	var pad := UI.margin(terminal, 12, 8, 12, 8)
	UI.full_rect(pad)
	_app = terminal
	_screen.add_child(pad)
	terminal.focus_input.call_deferred()
	app_name = "terminal"
	app_opened.emit("terminal")


## Saves, tablet-native: the repositories browser in its one-column layout.
func open_saves() -> void:
	_clear_screen()
	_bar_title.text = "Saves"
	var browser := SavesBrowser.new()
	browser.setup(game, true)
	browser.load_requested.connect(func(slug: String) -> void: load_requested.emit(slug))
	browser.deleted.connect(refresh_status)
	browser.closed.connect(show_home)
	browser.graph_tapped.connect(func(id: String) -> void: graph_tapped.emit(id))
	var pad := UI.margin(browser, 18, 14, 18, 12)
	UI.full_rect(pad)
	_app = browser
	_screen.add_child(pad)
	app_name = "saves"
	app_opened.emit("saves")


## Settings, tablet-native: the shared sheet on the glass, scrolling if it must. Done goes home.
func open_settings() -> void:
	_clear_screen()
	_bar_title.text = "Settings"
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UI.full_rect(scroll)
	var sheet := SettingsSheet.new()
	sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheet.setup(game.settings, show_home)
	var pad := UI.margin(sheet, 28, 22, 28, 22)
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(pad)
	_app = sheet
	_screen.add_child(scroll)
	app_name = "settings"
	app_opened.emit("settings")


# --- Lessons ----------------------------------------------------------------------------------

## Hotaru's line along the bottom of the glass. Backticks become code.
func show_lesson(speaker: String, text: String, with_next: bool) -> void:
	_strip.visible = true
	_strip_speaker.text = speaker.to_upper()
	var parts: PackedStringArray = text.split("`")
	var bbcode: String = ""
	for i: int in range(parts.size()):
		bbcode += ("[color=#%s][code]%s[/code][/color]" % [Pal.TEAL.to_html(false), parts[i]]) if i % 2 == 1 else parts[i].replace("[", "[lb]")
	_strip_text.text = bbcode
	_strip_next.visible = with_next
	_strip_note.visible = false
	if with_next:
		_strip_next.grab_focus.call_deferred()


## A quiet second line under Hotaru's, for a wrong turn.
func lesson_note(text: String) -> void:
	_strip_note.text = text
	_strip_note.visible = text != ""


func clear_lesson() -> void:
	_strip.visible = false
	_overlay.target = null
	_overlay.queue_redraw()
	if _app is SavesBrowser and (_app as SavesBrowser)._phantom:
		(_app as SavesBrowser).show_phantom(false)
	if _app is TerminalApp:
		(_app as TerminalApp).ghost = ""


## Rings a part of the slate: home_key, status_bar, app:<name>, terminal_input, saves:<graph|branches|command>,
## settings:<key>. Unknown or off-screen targets ring nothing.
func point(target: String) -> void:
	_overlay.target = lesson_target(target)
	_overlay.queue_redraw()


func lesson_target(target: String) -> Control:
	if target == "home_key": return _home_key
	if target == "status_bar": return _bar.get_parent() as Control
	if target.begins_with("app:"): return _icons.get(target.trim_prefix("app:"), null)
	if target == "terminal_input" and _app is TerminalApp: return (_app as TerminalApp)._input
	if target.begins_with("saves:") and _app is SavesBrowser: return (_app as SavesBrowser).lesson_target(target.trim_prefix("saves:"))
	if target.begins_with("settings:") and _app is SettingsSheet: return (_app as SettingsSheet).rows.get(target.trim_prefix("settings:"), null)
	return null


## The lesson's example tree on the Saves app, or the real one.
func set_phantom(on: bool) -> void:
	if _app is SavesBrowser and (_app as SavesBrowser)._phantom != on:
		(_app as SavesBrowser).show_phantom(on)


func set_ghost(command: String) -> void:
	if _app is TerminalApp:
		(_app as TerminalApp).ghost = command


func refresh_status() -> void:
	if _bar_status == null:
		return
	if game != null and game.session != null:
		var time: Dictionary = CityCycle.time(game.session.cycle)
		_bar_clock.text = "%02d:%02d" % [int(time.hour), int(game.session.cycle.minute) % 60]
	var vcs: Vcs = SaveRepo.repo()
	if vcs == null:
		_bar_status.text = ""
		return
	var state: Dictionary = vcs.status()
	var where: String = str(state.get("branch", "")) if str(state.get("branch", "")) != "" else "HEAD@" + str(state.get("head", "")).substr(0, 7)
	var pending: int = SaveRepo.uncommitted_changes().size()
	_bar_status.text = where + ("" if pending == 0 else "  ●%d" % pending)
	_bar_status.add_theme_color_override("font_color", Color("9fd8c8") if pending == 0 else Color("f0a08a"))


func _clear_screen() -> void:
	for child: Node in _screen.get_children():
		_screen.remove_child(child)
		child.queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if _app != null:
			show_home()
		else:
			close()


## A click beside the slate puts it away: attention goes back to the room.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		close()


func _bar_label(text: String) -> Label:
	var label := UI.label(text, &"", 13, Color("c9c2b2"))
	return label


## The painted slate as the card's panel: its window's edges become the content margins, so the
## glass sits exactly in the painted window and the keys on the ledge. Without the painting, a
## drawn enamel bezel.
func _frame_style(painted: Dictionary) -> StyleBox:
	if painted.is_empty():
		var box := StyleBoxFlat.new()
		box.bg_color = Color("23272b")
		box.border_color = Color("3a4047")
		box.set_border_width_all(2)
		box.set_corner_radius_all(22)
		box.content_margin_left = 18
		box.content_margin_right = 18
		box.content_margin_top = 18
		box.content_margin_bottom = 8
		box.shadow_color = Color(0, 0, 0, 0.5)
		box.shadow_size = 18
		return box
	var frame := StyleBoxTexture.new()
	frame.texture = painted.texture
	frame.texture_margin_left = float(painted.slice[0])
	frame.texture_margin_top = float(painted.slice[1])
	frame.texture_margin_right = float(painted.slice[2])
	frame.texture_margin_bottom = float(painted.slice[3])
	var window := Rect2(float(painted.window[0]), float(painted.window[1]), float(painted.window[2]), float(painted.window[3]))
	frame.content_margin_left = window.position.x + 3.0
	frame.content_margin_top = window.position.y + 3.0
	frame.content_margin_right = float(painted.size[0]) - window.end.x + 3.0
	frame.content_margin_bottom = 10.0
	_frame_box = frame
	return frame
