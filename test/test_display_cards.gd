extends SceneTree
var checks: int=0
var failures: Array[String]=[]
func _initialize()->void: _run.call_deferred()
func _run()->void:
	var area:AreaDef=AreaStore.load_area("haverlund-lane")
	_check(area!=null,"Display definition and quest validate")
	if area==null:quit(1);return
	var source:Dictionary=AreaStore.read_source("haverlund-lane")
	for defect:String in ["unknown object","wrong zone","remote approach","invalid welcome stop"]:
		var bad_area:Dictionary=source.document.duplicate(true)
		match defect:
			"unknown object":bad_area.displays[0].object="missing"
			"wrong zone":bad_area.displays[0].zone="lookout"
			"remote approach":bad_area.displays[0].at=[1,2]
			"invalid welcome stop":bad_area.interior.welcome.braum.spawn=[-1,99]
		_check(not AreaDef.parse(bad_area,source.assets,source.quests).ok,"Malformed display staging is refused: "+defect)
	var rules:=LabWorld.new(area)
	var state:Dictionary=rules.initial_state()
	state.player=[9,6,0]
	state.zones_seen.append("tram-halt")
	state.items=["field-tablet"]
	var command:Dictionary={"op":"set_sign_messages","target":"tram-welcome","messages":["Hello","Mind the step"]}
	_check(not rules.propose(state,[command],{}).ok,"A device is not writable before its commission")
	state.inspections_read=["sign-commission"]
	var before:Dictionary=state.duplicate(true)
	var proposal:Dictionary=rules.propose(state,[command],{})
	_check(proposal.ok and state==before,"Display replacement is a detached proposal")
	_check(Quests.goal_met(area,proposal.state,area.quest("proper-welcome").goal),"Installed different pages complete the actual world goal")
	for invalid:Variant in [[],[""],["a","b","c","d"],["a".repeat(33)],[9],["x\ny"],["😀"],[String.chr(128)]]:
		var bad:Dictionary=command.duplicate(true)
		bad.messages=invalid
		var rejected:Dictionary=rules.propose(proposal.state,[command,bad],{})
		_check(not rejected.ok and rejected.state==proposal.state,"Invalid final message rejects whole batch")
	var distant:Dictionary=state.duplicate(true)
	distant.player=[11,12,0]
	_check(not rules.propose(distant,[command],{}).ok,"Physical display range is checked by core")
	var unknown:Dictionary=command.duplicate(true)
	unknown.target="other-town"
	_check(not rules.propose(state,[unknown],{}).ok,"Cannot write an unknown sign")
	_check(rules.normalize_state(proposal.state).display_cards==proposal.state.display_cards,"Saved cards normalize and retain text")
	_check(rules.revert(proposal.state,before).state.display_cards.is_empty(),"Program undo restores the previous card")
	for text:String in ["Welcome to Spindle Lane","x".repeat(32),"word word word word word word"]:
		var rows:PackedStringArray=DisplayCards.rows(text).split("\n")
		_check(rows.size()<=2 and Array(rows).all(func(row:String)->bool:return row.length()<=16),"Text layout obeys fixed character cells")
	var snapshot:Dictionary=rules.snapshot(state)
	snapshot.display_sink={"target":"tram-welcome"}
	# Even if the area normally speaks to Hotaru, the sign sink must take priority.
	var result:Dictionary=LabProgram.run('def program(world):\n    messages = ["Welcome to Spindle Lane", "Mind the step", "Tea first. Tram second."]\n    for message in messages:\n        print(message)\n',snapshot)
	_check(result.ok and result.commands.size()==1 and result.commands[0].op=="set_sign_messages","Finite loop builds one typed card, not Hotaru speech")
	_check(rules.propose(state,result.commands,{}).ok,"Real WASI loop passes the core display validator")
	var one:Dictionary=LabProgram.run(area.quest("proper-welcome").starter,snapshot)
	var attempt:Dictionary=rules.propose(state,one.commands,{})
	_check(one.ok and attempt.ok and not Quests.goal_met(area,attempt.state,area.quest("proper-welcome").goal),"Unchanged one-page starter runs but does not finish the job")
	var lines:Dictionary=LabProgram.run('def program(world):\n    print("A", end="")\n    print("B\\nC")\n',snapshot)
	_check(lines.ok and lines.commands[0].messages==["AB","C"],"Standard print separator/newline semantics survive the sink")
	var four:Dictionary=LabProgram.run('def program(world):\n    for text in ["A","B","C","D"]:\n        print(text)\n',snapshot)
	_check(four.ok and not rules.propose(state,four.commands,{}).ok,"Too many output pages are rejected without touching a working card")
	snapshot.erase("display_sink")
	var voice:Dictionary=LabProgram.run('def program(world):\n    print("Hello, Hotaru!")\n',snapshot)
	_check(voice.ok and voice.commands[0].op=="say","Normal Hotaru output remains compatible")
	for failure:String in failures:printerr("FAIL: ",failure)
	print("Display cards: %d checks, %d failures." % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
func _check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures.append(message)
