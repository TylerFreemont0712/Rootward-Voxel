class_name AssetRequestQueue
extends Modal
## Readable local work queue; finishing is done by the authoring CLI, acceptance by the reviewer.

signal changed

var requests: ItemList
var details: RichTextLabel
var status_filter: OptionButton
var accept_button: Button
var _client: AssetWorkflowClient
var _records: Array=[]
var _selected: Dictionary={}
var _error: Label

func setup(client: AssetWorkflowClient)->void:
	_client=client
	card.custom_minimum_size=Vector2(1150,640)
	var header:=UI.hbox(12)
	header.add_child(UI.heading("Asset requests",28))
	header.add_child(UI.button("Refresh",&"undo",&"",refresh))
	header.add_child(UI.button("Open folder",&"book",&"",func()->void:OS.shell_open(_client.project_root.path_join("asset-requests")) ))
	header.add_child(UI.button("Close",&"cross",&"",close))
	body.add_child(header)
	status_filter=OptionButton.new()
	for label: String in ["All requests","Open requests","Finished","Accepted","Deleted"]:status_filter.add_item(label)
	status_filter.item_selected.connect(func(_index: int)->void:_filter())
	body.add_child(status_filter)
	var row:=UI.hbox(14)
	row.size_flags_vertical=Control.SIZE_EXPAND_FILL
	body.add_child(row)
	requests=ItemList.new()
	requests.custom_minimum_size=Vector2(330,300)
	requests.size_flags_vertical=Control.SIZE_EXPAND_FILL
	requests.item_selected.connect(_select)
	row.add_child(requests)
	details=RichTextLabel.new()
	details.selection_enabled=true
	details.add_theme_color_override("default_color",Pal.PARCHMENT)
	details.add_theme_font_size_override("normal_font_size",19)
	details.meta_clicked.connect(func(meta: Variant)->void:
		var path:=_client.project_root.path_join(str(meta)).simplify_path()
		if path.begins_with(_client.project_root+"/") and FileAccess.file_exists(path):OS.shell_open(path))
	details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	details.text="Choose a request to read its notes and source paths."
	row.add_child(details)
	var buttons:=UI.hbox(12)
	buttons.add_child(UI.button("Open brief",&"book",&"",func()->void:
		if not _selected.is_empty():OS.shell_open(_client.project_root.path_join(str(_selected.brief)))))
	accept_button=UI.button("Accept finished",&"check",&"ButtonPrimary",_accept)
	accept_button.disabled=true
	buttons.add_child(accept_button)
	body.add_child(buttons)
	_error=UI.dim("",17)
	_error.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_error)
	refresh()

func refresh()->void:
	var result:=_client.call_operation("overview")
	if not result.ok:_error.text=str(result.error);return
	_records=result.data.requests
	_filter()
	changed.emit()

func _filter()->void:
	requests.clear()
	_selected={}
	accept_button.disabled=true
	for record: Dictionary in _records:
		var status:=str(record.status)
		if status_filter.selected==1 and status not in ["requested","in_progress"]:continue
		if status_filter.selected>=2 and status!=["","","finished","accepted","deleted"][status_filter.selected]:continue
		var index:=requests.add_item("%s · %s"%[status.replace("_"," "),record.title])
		requests.set_item_metadata(index,record)
		requests.set_item_tooltip(index,"%s\n%s"%[record.id,record.title])

func _select(index: int)->void:
	_selected=requests.get_item_metadata(index)
	details.clear()
	_heading(str(_selected.title))
	details.add_text(str(_selected.status).replace("_"," ").capitalize()+"\n\n")
	if _selected.status=="finished" and not _selected.get("review_current",false):details.add_text("Changed since review — rebuild and review before acceptance.\n\n")
	_heading("Requested changes")
	details.add_text(str(_selected.notes) if not str(_selected.notes).is_empty() else "No additional notes.")
	details.add_text("\n\n")
	var contexts: Array=(_selected.references as Array).duplicate()
	if not (_selected.asset as Dictionary).is_empty():contexts.push_front(_selected.asset)
	for context: Dictionary in contexts:
		_heading(str(context.label))
		for key: String in ["source","runtime","manifest","catalog"]:
			if not str(context.get(key,"")).is_empty():
				details.add_text(key.capitalize()+": ")
				_link(str(context[key]))
				details.add_text("\n")
		for path: String in context.get("usage_files",[]):
			details.add_text("Used in: ")
			_link(path)
			details.add_text("\n")
		details.add_text("\n")
	if _selected.has("result"):
		_heading("Delivered result")
		details.add_text(str(_selected.result.summary)+"\n")
		_link(str(_selected.result.review))
		details.add_text("\n\n")
	_heading("Agent brief")
	_link(str(_selected.brief))
	details.add_text("\n"+str(_selected.id))
	details.scroll_to_line(0)
	accept_button.disabled=_selected.status!="finished" or not _selected.get("review_current",false)

func _heading(text: String)->void:
	details.push_bold()
	details.add_text(text+"\n")
	details.pop()

func _link(path: String)->void:
	details.push_meta(path)
	details.add_text(path)
	details.pop()

func _accept()->void:
	if _selected.is_empty():return
	var result:=_client.call_operation("accept",[str(_selected.id)])
	if not result.ok:_error.text=str(result.error);return
	refresh()
