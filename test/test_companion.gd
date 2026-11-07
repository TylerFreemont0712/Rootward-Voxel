extends SceneTree
## Speech boundaries and genuine CPython execution evidence, including failed runs.
var checks: int=0
var failures: Array[String]=[]
func _initialize() -> void:go.call_deferred()
func go() -> void:
	var room:=AreaStore.load_area("workshop-loft")
	var rules:=LabWorld.new(room)
	var state: Dictionary=rules.initial_state()
	var say: Dictionary={"op":"say","target":"hotaru","text":"Hello, Hotaru!"}
	_check(Quests.current(room,[]).id=="say-hello","Hello is the first job")
	for text: String in ["Hello, Hotaru!","HI HOTARU","Good morning, Hotaru."]:_check(CompanionLesson.is_greeting(text),"Natural greetings reach Hotaru")
	for text: String in ["Hello world","Hotaru","Hello, nothotaru"]:_check(not CompanionLesson.is_greeting(text),"A greeting needs Hotaru's actual name")
	for bad: Dictionary in [{"text":true},{"text":""},{"text":"a".repeat(161)},{"target":"engine"},{"node_path":"root"}]:
		var command: Dictionary=say.duplicate(true);command.merge(bad,true)
		_check(not rules.propose(state,[say,command],{}).ok and not state.hotaru_greeted,"Malformed speech rejects the entire proposal atomically")
	var proposal: Dictionary=rules.propose(state,[say],{})
	_check(proposal.ok and not state.hotaru_greeted and proposal.state.hotaru_greeted,"Speech preview leaves the real world untouched")
	_check(rules.normalize_state(proposal.state).hotaru_greeted,"Speech and greeting normalize through a save")
	_check(not rules.revert(proposal.state,state).state.hotaru_greeted,"Undo restores speech along with other program effects")
	_check(CompanionLesson.has_voice(rules.revert(proposal.state,state).state,["say-hello"]) and not CompanionLesson.has_voice(state,[]),"Undoing a spoken program preserves learned dialogue choices after quest completion")
	# An area that does not teach the voice command refuses it. The fixture village is such an area.
	AreaStore.use_fixtures()
	var other:=LabWorld.new(AreaStore.load_area("kindle-hollow"))
	AreaStore.use_content()
	_check(not other.propose(other.initial_state(),[say],{}).ok,"The voice command respects its area capability")
	var printed: Dictionary=LabProgram.run(CompanionLesson.STARTER,other.snapshot(other.initial_state()))
	_check(printed.ok and printed.commands.is_empty() and printed.stdout=="Hello, Hotaru!","Ordinary print remains output where the voice lesson is not taught")
	var source: String='def program(world):\n    x = 0\n    if False:\n        print("unreachable")\n    x += 2\n    print("Hello, Hotaru!")\n'
	var answer: Dictionary=LabProgram.run(source,rules.snapshot(state))
	_check(answer.ok and answer.commands.size()==1,"Recorded traces do not invent commands")
	_check(not answer.trace.any(func(event: Dictionary) -> bool:return event.line==4),"Execution replay skips branches Python did not execute")
	_check(answer.trace.any(func(event: Dictionary) -> bool:return event.get("command",-1)==0 and event.line==6 and event.get("values",{}).get("x")==2),"A real recorded command reports its source line and computed x value")
	var failed: Dictionary=LabProgram.run('def program(world):\n    x = 2\n    y = 0\n    x / y\n',rules.snapshot(state))
	_check(not failed.ok and failed.error.line==4 and not failed.trace.is_empty(),"A runtime error retains the steps that reached the broken line")
	_check(not failed.stdout.contains("__VOXEL_TRACE__"),"Internal trace framing never appears as learner output")
	var loop: Dictionary=LabProgram.run('def program(world):\n    x = 0\n    for key in range(300):\n        x += 1\n',rules.snapshot(state))
	_check(loop.ok and loop.trace.size()==96,"Long programs keep bounded execution evidence")
	for bad: Variant in [[{"line":-1}],[{"line":2,"command":LabWorld.MAX_COMMANDS}],[{"line":2,"values":{"node_path":"root"}}],[{"line":2,"values":{"x":true}}],[{"line":2,"values":{"message":"x".repeat(61)}}],"not a trace"]:
		_check(LabProgram.safe_trace(bad).is_empty(),"Untrusted playback metadata is bounded and typed")
	_check(not LabProgram.safe_trace([{"line":2,"command":LabWorld.MAX_COMMANDS-1}]).is_empty(),"Playback accepts the highest legal command index")
	if failures.is_empty():print("Hotaru voice and execution evidence: %d checks passed." % checks)
	else:
		for failure: String in failures:printerr("FAIL: ",failure)
	quit(0 if failures.is_empty() else 1)
func _check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message)
