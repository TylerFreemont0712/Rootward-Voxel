class_name AssetWorkflowClient
extends RefCounted
## Development authoring only. Notes travel in a JSON file, never command arguments or source.

var project_root: String=ProjectSettings.globalize_path("res://").trim_suffix("/")

func call_operation(operation: String,arguments: Array[String]=[])->Dictionary:
	var script:=project_root.path_join("pipeline/asset_workflow.py")
	if OS.has_feature("standalone") or not FileAccess.file_exists(script):
		return {"ok":false,"error":"Asset requests need the source checkout. The display remains available."}
	var output: Array=[]
	var argv:=PackedStringArray([script,"--root",project_root,operation])
	argv.append_array(arguments)
	var result:=OS.execute("python3",argv,output,true)
	var parser:=JSON.new()
	if parser.parse("\n".join(output))==OK and parser.data is Dictionary:return parser.data
	return {"ok":false,"error":"Could not run the local asset workflow (Python 3, exit %d). %s"%[result,"\n".join(output).left(1500)]}

func submit(data: Dictionary)->Dictionary:
	return call_payload("submit",[],data)

func call_payload(operation: String,arguments: Array[String],data: Dictionary)->Dictionary:
	var folder:=project_root.path_join(".cache/asset-workflow-ipc")
	if DirAccess.make_dir_recursive_absolute(folder)!=OK:return {"ok":false,"error":"Could not create the local asset request staging folder."}
	var path:=folder.path_join("%d-%d.json"%[OS.get_process_id(),Time.get_ticks_usec()])
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:return {"ok":false,"error":"Could not write the local asset request."}
	file.store_string(JSON.stringify(data))
	file.close()
	var argv: Array[String]=arguments.duplicate()
	argv.append_array(["--payload-file",path])
	var result:=call_operation(operation,argv)
	DirAccess.remove_absolute(path)
	return result
