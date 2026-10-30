extends SceneTree
## Speech boundaries and genuine CPython execution evidence, including failed runs.
var checks: int=0
var failures: Array[String]=[]
func _initialize() -> void:go.call_deferred()
func go() -> void:
	var selected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://pipeline/art-catalog.json")).companions.hotaru
	var origin: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://"+str(selected.provenance)))
	_check(FileAccess.get_sha256(selected.source)==origin.sha256 and FileAccess.get_sha256(selected.portrait_runtime)==origin.sha256,"The selected black-haired portrait preserves its generated source")
	_check(FileAccess.get_sha256("res://"+str(selected.prompt))==origin.prompt_sha256,"The exact selected fairy prompt is preserved")
	var texture:=Image.load_from_file(ProjectSettings.globalize_path(selected.runtime))
	_check(texture.detect_alpha() and texture.get_height()==256,"The compact fairy avatar has bounded size and transparency")
	var fairy: Dictionary=HotaruDialogue.person("Wren")
	_check(VillageDialogue.validate(fairy).is_empty(),"Hotaru’s authored pages obey the shared dialogue contract")
	var talk:=VillageDialogue.new(fairy)
	var pages: int=0
	while not talk.closed and pages<20:
		_check(talk.current().choices.is_empty() and not talk.choose("company"),"The voiceless introduction cannot offer or record a player reply")
		talk.advance()
		pages+=1
	_check(talk.closed and pages==3 and fairy.on_finish=="notebook","The guided greeting ends at its automatic notebook handoff")
	_check(talk.history.all(func(entry: Dictionary) -> bool:return entry.speaker=="Hotaru"),"Guided history never invents a spoken response")
	var movement:=VillageDialogue.new(HotaruDialogue.person("Wren",true,true,"movement"))
	_check(movement.is_guided() and movement.topic=="movement" and movement.history.size()==1,"Movement starts directly with Hotaru’s explanation, without a fabricated player choice")
	while not movement.closed:
		_check(movement.current().choices.is_empty(),"The first-steps introduction stays on the tutorial path")
		movement.advance()
	var spoken:=VillageDialogue.new(HotaruDialogue.person("Wren",true,true))
	_check(not spoken.is_guided() and spoken.advance() and spoken.choose("company"),"Optional replies become available after the player has a voice")
	var hollow:=VillageDialogue.new(HotaruDialogue.person("Wren",false))
	_check(not hollow.is_guided() and hollow.advance() and hollow.choose("hollow"),"The original level keeps optional conversation navigation")
	for invalid: Variant in [[],"hello",["menu"],["unknown"],["hello","hello"],[false],["greeting","hello","movement","company","hello","hello","hello","hello","hello","hello"]]:
		var malformed: Dictionary=fairy.duplicate(true)
		malformed.sequence=invalid
		_check(not VillageDialogue.validate(malformed).is_empty(),"Guided sequences must name a small set of distinct authored pages/topics")
	var action: Dictionary=fairy.duplicate(true)
	action.on_finish="execute_code"
	_check(not VillageDialogue.validate(action).is_empty(),"Dialogue completion can request only the declared notebook action")
	var room:=AreaStore.load_area("morning-bedroom")
	var rules:=LabWorld.new(room)
	var state: Dictionary=rules.initial_state()
	var say: Dictionary={"op":"say","target":"hotaru","text":"Hello, Hotaru!"}
	_check(Quests.current(room,[]).id=="say-hello","Hello precedes the movement quest")
	for text: String in ["Hello, Hotaru!","HI HOTARU","Good morning, Hotaru."]:_check(CompanionLesson.is_greeting(text),"Natural greetings reach the fairy")
	for text: String in ["Hello world","Hotaru","Hello, nothotaru"]:_check(not CompanionLesson.is_greeting(text),"A greeting needs Hotaru's actual name")
	for bad: Dictionary in [{"text":true},{"text":""},{"text":"a".repeat(161)},{"target":"engine"},{"node_path":"root"}]:
		var command: Dictionary=say.duplicate(true);command.merge(bad,true)
		_check(not rules.propose(state,[say,command],{}).ok and not state.hotaru_greeted,"Malformed speech rejects the entire proposal atomically")
	var proposal: Dictionary=rules.propose(state,[say],{})
	_check(proposal.ok and not state.hotaru_greeted and proposal.state.hotaru_greeted,"Speech preview leaves the real world untouched")
	_check(rules.normalize_state(proposal.state).hotaru_greeted,"Speech and greeting normalize through a save")
	_check(not rules.revert(proposal.state,state).state.hotaru_greeted,"Undo restores speech along with other program effects")
	_check(CompanionLesson.has_voice(rules.revert(proposal.state,state).state,["say-hello"]) and not CompanionLesson.has_voice(state,[]),"Undoing a spoken program preserves learned dialogue choices after quest completion")
	var legacy:=LabWorld.new(AreaStore.load_area("kindle-hollow"))
	_check(not legacy.propose(legacy.initial_state(),[say],{}).ok,"The voice command respects its area capability")
	var printed: Dictionary=LabProgram.run(CompanionLesson.STARTER,legacy.snapshot(legacy.initial_state()))
	_check(printed.ok and printed.commands.is_empty() and printed.stdout=="Hello, Hotaru!","Ordinary print remains output in existing levels")
	var source: String='def program(world):\n    x = 0\n    if False:\n        print("unreachable")\n    x += 2\n    world.controls.bind_move("W", x, 0)\n'
	var answer: Dictionary=LabProgram.run(source,rules.snapshot(state))
	_check(answer.ok and answer.commands.size()==1,"Recorded traces do not invent commands")
	_check(not answer.trace.any(func(event: Dictionary) -> bool:return event.line==4),"Execution replay skips branches Python did not execute")
	_check(answer.trace.any(func(event: Dictionary) -> bool:return event.get("command",-1)==0 and event.line==6 and event.get("values",{}).get("x")==2),"A real recorded command reports its source line and computed x value")
	_check(not rules.propose(state,answer.commands,answer.memory).ok,"Executed excessive movement is still rejected by pure rules")
	var failed: Dictionary=LabProgram.run('def program(world):\n    x = 2\n    y = 0\n    x / y\n',rules.snapshot(state))
	_check(not failed.ok and failed.error.line==4 and not failed.trace.is_empty(),"A runtime error retains the steps that reached the broken line")
	_check(not failed.stdout.contains("__VOXEL_TRACE__"),"Internal trace framing never appears as learner output")
	var loop: Dictionary=LabProgram.run('def program(world):\n    x = 0\n    for key in range(300):\n        x += 1\n',rules.snapshot(state))
	_check(loop.ok and loop.trace.size()==96,"Long programs keep bounded execution evidence")
	for bad: Variant in [[{"line":-1}],[{"line":2,"command":64}],[{"line":2,"values":{"node_path":"root"}}],[{"line":2,"values":{"x":true}}],[{"line":2,"values":{"message":"x".repeat(61)}}],"not a trace"]:
		_check(LabProgram.safe_trace(bad).is_empty(),"Untrusted playback metadata is bounded and typed")
	var section: Dictionary=MovementBindings.block_source(["W","W","S","D"],["north","","",""],[1,0,0,0],0)
	_check(section.ok and section.source.count("bind_move")==1,"A section compiles independently of other unfinished blocks")
	var executed: Dictionary=LabProgram.run(section.source,rules.snapshot(state))
	_check(executed.ok and executed.commands.size()==1 and executed.commands[0].key=="W","A section runs exactly one key event in real WASI")
	if failures.is_empty():print("Hotaru voice and execution evidence: %d checks passed." % checks)
	else:
		for failure: String in failures:printerr("FAIL: ",failure)
	quit(0 if failures.is_empty() else 1)
func _check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message)
