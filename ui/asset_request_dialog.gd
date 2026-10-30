class_name AssetRequestDialog
extends Modal
## The same local request form serves a new asset, an update, or a dependency-aware deletion.

signal saved(record: Dictionary)

var notes: TextEdit
var asset_name: LineEdit
var reference_picker: OptionButton
var references: ItemList
var submit_button: Button
var _client: AssetWorkflowClient
var _kind: String
var _asset: String
var _plan: Dictionary={}
var _error: Label
var _options: Array=[]

func setup(client: AssetWorkflowClient,kind: String,asset: String,options: Array)->void:
	_client=client
	_kind=kind
	_asset=asset
	_options=options
	card.custom_minimum_size=Vector2(860,620)
	title_row({"new":"Request a new asset","update":"Request an update","delete":"Delete asset"}[kind],asset if kind!="new" else "Choose references for the style, shape or details you have in mind.")
	if kind=="new":
		asset_name=LineEdit.new()
		asset_name.placeholder_text="Asset name / short description"
		asset_name.max_length=180
		asset_name.custom_minimum_size.y=36
		body.add_child(asset_name)
	if kind=="delete":
		var answer:=_client.call_operation("plan-delete",[asset])
		if answer.ok:_plan=answer.data
		var detail:=TextEdit.new()
		detail.editable=false
		detail.custom_minimum_size=Vector2(0,190)
		detail.size_flags_vertical=Control.SIZE_EXPAND_FILL
		if not answer.ok:detail.text=answer.error
		elif not (_plan.blockers as Array).is_empty():
			detail.text="This asset is still used. A deletion request will give the agent these dependencies to resolve first:\n\n"
			for blocker: Dictionary in _plan.blockers:detail.text+="%s\n  %s\n"%[blocker.path,blocker.reason]
		else:
			detail.text="Delete the catalog entry and these owned source/runtime folders, including previous versions and import sidecars:\n\n"
			for folder: String in _plan.roots:detail.text+=folder+"/\n"
			detail.text+="\n%d files will be removed from this project. Shared materials and other assets are kept."%(_plan.files as Array).size()
		body.add_child(detail)
	else:
		body.add_child(UI.dim("Style references (optional; these assets stay unchanged)",18))
		var row:=UI.hbox(10)
		reference_picker=OptionButton.new()
		reference_picker.fit_to_longest_item=false
		reference_picker.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		reference_picker.custom_minimum_size=Vector2(350,36)
		reference_picker.add_item("Choose a reference…")
		for option: Dictionary in options:
			reference_picker.add_item(option.label)
			reference_picker.set_item_metadata(reference_picker.item_count-1,option.id)
		reference_picker.get_popup().max_size=Vector2i(750,420)
		row.add_child(reference_picker)
		row.add_child(UI.button("Add",&"plus",&"",_add_reference))
		row.add_child(UI.button("Remove",&"cross",&"",_remove_reference))
		body.add_child(row)
		references=ItemList.new()
		references.custom_minimum_size.y=82
		body.add_child(references)
	body.add_child(UI.dim("Notes / specific changes (optional)",18))
	notes=TextEdit.new()
	notes.placeholder_text="What should change? Mention proportions, materials, details or anything to preserve."
	notes.custom_minimum_size=Vector2(0,125)
	notes.size_flags_vertical=Control.SIZE_EXPAND_FILL
	notes.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY
	body.add_child(notes)
	_error=UI.dim("",17)
	_error.add_theme_color_override("font_color",Pal.RED)
	_error.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_error)
	var buttons:=UI.hbox(12)
	buttons.add_child(UI.button("Cancel",&"cross",&"",close))
	var label: String="Save request"
	if kind=="delete":label="Request deletion" if not _plan.get("blockers",[]).is_empty() else "Delete asset"
	submit_button=UI.button(label,&"check",&"ButtonDanger" if label=="Delete asset" else &"ButtonPrimary",_submit)
	submit_button.disabled=kind=="delete" and _plan.is_empty()
	buttons.add_child(submit_button)
	body.add_child(buttons)
	# Cancel starts focused for deletion. Nothing is removed by opening this form.
	buttons.get_child(0).grab_focus.call_deferred()

func _add_reference()->void:
	var index:=reference_picker.selected
	if index<=0 or references.item_count>=12:return
	var id:=str(reference_picker.get_item_metadata(index))
	for item: int in range(references.item_count):
		if references.get_item_metadata(item)==id:return
	var added:=references.add_item(reference_picker.get_item_text(index))
	references.set_item_metadata(added,id)

func _remove_reference()->void:
	for index: int in references.get_selected_items():references.remove_item(index)

func _submit()->void:
	submit_button.disabled=true
	var answer: Dictionary
	if _kind=="delete" and (_plan.get("blockers",[]) as Array).is_empty():
		answer=_client.call_payload("delete",["--asset",_asset,"--token",str(_plan.token)],{"notes":notes.text})
	else:
		var selected: Array[String]=[]
		if references!=null:
			for index: int in range(references.item_count):selected.append(str(references.get_item_metadata(index)))
		answer=_client.submit({"kind":_kind,"asset_id":_asset,"title":asset_name.text if asset_name!=null else "","notes":notes.text,"references":selected})
	if not answer.ok:
		_error.text=str(answer.error)
		submit_button.disabled=false
		return
	saved.emit(answer.data)
	close()
