class_name AssetShowcase
extends Modal
## Temporary title-accessible asset viewer. Its own viewport never touches a journey/session.

const SETTING: String="rootward/development/asset_showcase_on_title"
const Assets:=preload("res://art/world_assets.gd")
var stage: AssetShowcaseStage
var search: LineEdit
var models: AssetRequestList
var selection: String=""
var _assets: Dictionary={}
var _status: Label
var _count: Label
var _spin: CheckBox
var _empty: Label
var workflow:=AssetWorkflowClient.new()
var filter: OptionButton
var _requests: Array=[]
var _workflow_note: Label
var _update_button: Button
var _delete_button: Button
var _accept_button: Button
var _dialog: Modal
## Modular houses: the look on show, the seed behind "Shuffled", and whether two shuffled neighbours stand beside it.
var variant_row: HBoxContainer
var variant_mode: OptionButton
var street: CheckBox
var variant: Dictionary={}
var variant_seed: int=1
var _variant_note: Label
var _palettes: Array=[]

static func enabled()->bool:
	return OS.is_debug_build() and bool(ProjectSettings.get_setting(SETTING,false))

func setup()->void:
	_assets=JSON.parse_string(FileAccess.get_file_as_string("res://pipeline/world-catalog.json")).assets
	var header:=UI.hbox(16)
	header.add_child(UI.heading("Asset Showcase",28))
	header.add_child(UI.caps("DEVELOPMENT",Pal.BRASS))
	var space:=Control.new()
	space.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(space)
	header.add_child(UI.button("Request new",&"plus",&"",func()->void:open_request("new")))
	header.add_child(UI.button("Requests",&"book",&"",open_queue))
	header.add_child(UI.button("Back to title",&"cross",&"",close))
	body.add_child(header)
	body.add_child(UI.dim("Inspect buildings and props on an empty stage.",18))
	var row:=UI.hbox(20)
	row.size_flags_vertical=Control.SIZE_EXPAND_FILL
	body.add_child(row)
	var side:=UI.vbox(10)
	side.custom_minimum_size.x=290
	row.add_child(side)
	search=LineEdit.new()
	search.placeholder_text="Search models…"
	search.custom_minimum_size.y=38
	side.add_child(search)
	filter=OptionButton.new()
	for label: String in ["All assets","Updates requested","Finished"]:filter.add_item(label)
	filter.custom_minimum_size.y=32
	filter.item_selected.connect(func(_index: int)->void:_filter())
	side.add_child(filter)
	_count=UI.dim("",16)
	side.add_child(_count)
	models=AssetRequestList.new()
	models.custom_minimum_size=Vector2(290,180)
	models.size_flags_vertical=Control.SIZE_EXPAND_FILL
	models.add_theme_font_size_override("font_size",17)
	side.add_child(models)
	var actions:=UI.hbox(8)
	actions.add_child(UI.button("Reload",&"undo",&"",func()->void:
		refresh_workflow()
		show_asset(selection,true)))
	actions.add_child(UI.button("Clear",&"cross",&"",clear_stage))
	side.add_child(actions)
	var requests_row:=UI.hbox(8)
	_update_button=UI.button("Request update",&"brush",&"",func()->void:open_request("update"))
	_delete_button=UI.button("Delete",&"trash",&"ButtonDanger",func()->void:open_request("delete"))
	requests_row.add_child(_update_button)
	requests_row.add_child(_delete_button)
	side.add_child(requests_row)
	_accept_button=UI.button("Accept finished",&"check",&"",_accept_finished)
	side.add_child(_accept_button)
	_status=UI.dim("Choose a model to display.",17)
	_status.custom_minimum_size=Vector2(290,75)
	_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_status)
	var display:=UI.vbox(10)
	display.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(display)
	var controls:=UI.hbox(12)
	var grid:=_check("Metre grid",false)
	var guide:=_check("Scale figure",true)
	_spin=_check("Auto-rotate",false)
	for check: CheckBox in [grid,guide,_spin]:controls.add_child(check)
	display.add_child(controls)
	variant_row=UI.hbox(12)
	variant_row.visible=false
	var look:=UI.dim("Look",17)
	look.autowrap_mode=TextServer.AUTOWRAP_OFF
	variant_row.add_child(look)
	variant_mode=OptionButton.new()
	variant_mode.custom_minimum_size.y=32
	variant_mode.add_item("Authored")
	_palettes=HouseVariants.palettes().keys()
	_palettes.sort()
	for palette: String in _palettes:variant_mode.add_item(palette.replace("_"," ").capitalize())
	variant_mode.add_item("Shuffled")
	variant_mode.item_selected.connect(func(_index: int)->void:_choose_look())
	variant_row.add_child(variant_mode)
	variant_row.add_child(UI.button("Shuffle",&"sparkle",&"",shuffle_variant))
	street=_check("Street of three",false)
	street.toggled.connect(func(_on: bool)->void:show_asset(selection))
	variant_row.add_child(street)
	display.add_child(variant_row)
	var frame:=PanelContainer.new()
	frame.size_flags_vertical=Control.SIZE_EXPAND_FILL
	display.add_child(frame)
	stage=AssetShowcaseStage.new()
	stage.custom_minimum_size=Vector2(450,260)
	stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	stage.size_flags_vertical=Control.SIZE_EXPAND_FILL
	frame.add_child(stage)
	_empty=UI.dim("Choose a model to display",24)
	_empty.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_empty.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	frame.add_child(_empty)
	var views:=UI.hbox(10)
	views.add_child(UI.button("Turn left",&"turn_left",&"",func()->void:stage.turn(90)))
	views.add_child(UI.button("Turn right",&"turn_right",&"",func()->void:stage.turn(-90)))
	views.add_child(UI.button("Reset view",&"undo",&"",stage.reset_view))
	display.add_child(views)
	display.add_child(UI.dim("Drag left/right to turn · Mouse wheel to zoom",17))
	_variant_note=UI.dim("",16)
	_variant_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_variant_note.visible=false
	display.add_child(_variant_note)
	grid.toggled.connect(stage.set_grid)
	guide.toggled.connect(stage.set_guide)
	_spin.toggled.connect(func(value: bool)->void:stage.spinning=value)
	stage.manually_turned.connect(func()->void:_spin.set_pressed_no_signal(false))
	search.text_changed.connect(func(_text: String)->void:_filter())
	models.item_selected.connect(func(index: int)->void:show_asset(str(models.get_item_metadata(index))))
	_workflow_note=UI.dim("Requests: asset-requests/",16)
	_workflow_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_workflow_note)
	refresh_workflow()

func _ready()->void:
	_layout()
	get_viewport().size_changed.connect(_layout)

func _layout()->void:
	var extent:=get_viewport_rect().size
	card.custom_minimum_size=Vector2(minf(1500,extent.x-40),minf(900,extent.y-40))

func _filter()->void:
	models.clear_marks()
	models.clear()
	var ids: Array=_assets.keys()
	ids.sort()
	var query:=search.text.strip_edges().to_lower()
	for id: String in ids:
		var spec: Dictionary=_assets[id]
		if str(spec.get("runtime","")).is_empty():continue
		if filter.selected==1 and not _has_request(id,["requested","in_progress"]):continue
		if filter.selected==2 and not _has_request(id,["finished"]):continue
		var label: String=str(spec.get("label",id.replace("-"," ").capitalize()))
		if not query.is_empty() and not (label+" "+id).to_lower().contains(query):continue
		var index:=models.add_item(label)
		models.set_item_metadata(index,id)
		var mark:=_request_marker(id)
		models.set_request_mark(index,mark)
		models.set_item_tooltip(index,id+("\nDeletion requested" if mark=="delete" else "\nUpdate requested" if mark=="update" else ""))
		if id==selection:models.select(index)
	_count.text="%d %s"%[models.item_count,"model" if models.item_count==1 else "models"]
	_update_actions()

func _request_marker(id: String)->String:
	var update: bool=false
	for record: Dictionary in _requests:
		if record.status not in ["requested","in_progress"] or str(record.get("asset",{}).get("id",""))!=id:continue
		if record.kind=="delete":return "delete"
		if record.kind=="update":update=true
	return "update" if update else ""

func show_asset(id: String,reload: bool=false)->bool:
	if id.is_empty() or not _assets.has(id):return false
	var spec: Dictionary=_assets[id]
	if id!=selection:_reset_look(id)
	selection=id
	_update_actions()
	var path: String="res://"+str(spec.get("runtime",""))
	if not ResourceLoader.exists(path):
		stage.empty()
		_empty.visible=true
		_status.text="%s is not built yet.\nBuild its selected runtime model before displaying it."%id
		return false
	var houses:=HouseVariants.offers(spec)
	variant_row.visible=houses
	_variant_note.visible=houses
	var cache:=ResourceLoader.CACHE_MODE_REPLACE if reload else ResourceLoader.CACHE_MODE_REUSE
	var model:=Assets.instantiate(id,cache,variant)
	if model!=null and houses:
		_variant_note.text=HouseVariants.summary(spec,variant)
		if street.button_pressed:model=_street(id,spec,model)
	if model==null:
		stage.empty()
		_empty.visible=true
		_status.text="Could not load "+id
		return false
	var bounds:=stage.display(model)
	_empty.visible=false
	_spin.set_pressed_no_signal(false)
	_status.text="%s · %s\n%.2f × %.2f × %.2f m\nWidth × height × depth"%[id,str(spec.get("version","")),bounds.size.x,bounds.size.y,bounds.size.z]
	for record: Dictionary in _requests:
		if record.status=="finished" and id in record.get("result",{}).get("assets",[]):
			_status.text+="\nFinished · "+("awaiting review" if record.get("review_current",false) else "changed since review")
			break
	return true

## Two neighbours with shuffled looks either side of the house on show, as they would stand along a street.
func _street(id: String,spec: Dictionary,middle: Node3D)->Node3D:
	var row:=Node3D.new()
	row.name="Street"
	var width: float=stage.measure(middle).size.x+.4
	for index: int in range(3):
		var house: Node3D=middle if index==1 else Assets.instantiate(id,ResourceLoader.CACHE_MODE_REUSE,HouseVariants.pick(spec,variant_seed*7919+index))
		house.position.x=(index-1)*width
		row.add_child(house)
	_variant_note.text+="\nNeighbours: two shuffled looks"
	return row

func _reset_look(id: String)->void:
	variant=HouseVariants.authored(_assets.get(id,{}))
	if variant_mode!=null:variant_mode.select(0)

func _choose_look()->void:
	var spec: Dictionary=_assets.get(selection,{})
	var index:=variant_mode.selected
	if index==0:variant=HouseVariants.authored(spec)
	elif index<=_palettes.size():variant=HouseVariants.with_palette(spec,str(_palettes[index-1]))
	else:variant=HouseVariants.pick(spec,variant_seed)
	show_asset(selection)

## A new seed: a fresh palette, dressing and alternatives for the house on show.
func shuffle_variant()->void:
	if selection.is_empty():return
	variant_seed+=1
	variant_mode.select(variant_mode.item_count-1)
	variant=HouseVariants.pick(_assets.get(selection,{}),variant_seed)
	show_asset(selection)

func clear_stage()->void:
	selection=""
	variant={}
	if variant_row!=null:variant_row.visible=false
	if _variant_note!=null:_variant_note.visible=false
	stage.empty()
	_empty.visible=true
	_spin.set_pressed_no_signal(false)
	models.deselect_all()
	_status.text="Choose a model to display."
	_update_actions()

func refresh_workflow()->void:
	var result:=workflow.call_operation("overview")
	if not result.ok:
		_workflow_note.text=str(result.error)
		_filter()
		return
	_assets=result.data.catalog
	_requests=result.data.requests
	if not selection.is_empty() and not _assets.has(selection):clear_stage()
	var finished: int=_requests.filter(func(record: Dictionary)->bool:return record.status=="finished").size()
	_workflow_note.text="asset-requests/ · %d requests · %d finished, awaiting review"%[_requests.size(),finished]
	_filter()

func _has_request(id: String,statuses: Array)->bool:
	for record: Dictionary in _requests:
		if record.status not in statuses:continue
		if str(record.get("asset",{}).get("id",""))==id or id in record.get("result",{}).get("assets",[]):return true
	return false

func _update_actions()->void:
	var empty:=selection.is_empty()
	_update_button.disabled=empty
	_delete_button.disabled=empty
	_accept_button.disabled=empty or not _requests.any(func(record: Dictionary)->bool:
		return record.status=="finished" and record.get("review_current",false) and selection in record.get("result",{}).get("assets",[]))

func open_request(kind: String)->void:
	if is_instance_valid(_dialog) or (kind!="new" and selection.is_empty()):return
	var references: Array=[]
	var ids: Array=_assets.keys()
	ids.sort()
	for id: String in ids:references.append({"id":id,"label":str(_assets[id].get("label",id.replace("-"," ").capitalize()))})
	var dialog:=AssetRequestDialog.new()
	dialog.setup(workflow,kind,selection,references)
	dialog.saved.connect(func(record: Dictionary)->void:
		refresh_workflow()
		_workflow_note.text="%s · %s"%["Deleted" if record.status=="deleted" else "Request saved",str(record.id)] )
	_show_dialog(dialog)

func open_queue()->void:
	if is_instance_valid(_dialog):return
	var dialog:=AssetRequestQueue.new()
	dialog.setup(workflow)
	dialog.changed.connect(refresh_workflow)
	_show_dialog(dialog)

func _show_dialog(dialog: Modal)->void:
	_dialog=dialog
	add_child(dialog)
	dialog.closed.connect(func()->void:_dialog=null)
	dialog.open()

func _accept_finished()->void:
	for record: Dictionary in _requests:
		if record.status=="finished" and selection in record.get("result",{}).get("assets",[]):
			var result:=workflow.call_operation("accept",[str(record.id)])
			if not result.ok:_workflow_note.text=str(result.error);return
	refresh_workflow()

func _check(text: String,checked: bool)->CheckBox:
	var control:=CheckBox.new()
	control.text=text
	control.button_pressed=checked
	return control
