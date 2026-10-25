extends SceneTree
## Review build mode's in-world drawing without the interface. Usage:
##   -- <absolute PNG path> <place|bad|tree|move|delete|locked> [focus_x focus_y] [zoom]
## A valid ghost, a refused one (red), a tree ghost, and the hover highlights on a house, a tree and the locked mill.

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var mode: String = args[1] if args.size() > 1 else "place"
	var source: Dictionary = AreaStore.read_source("kindle-hollow")
	var ledger := BuildLedger.new(source.document, source.assets, source.quests, AreaStore.read_build_catalog())
	var view := ClearingView.new()
	root.add_child(view)
	await process_frame
	view.setup(ledger.area)
	view.set_camera_mode(ClearingView.CameraMode.FREE)
	var focus := Vector2(float(args[2]), float(args[3])) if args.size() > 3 else Vector2(31, 8)
	view.focus_on(focus, true)
	var zoom: float = float(args[4]) if args.size() > 4 else 11.0
	view.set_zoom(zoom)
	view.camera.size = zoom
	var overlay := BuildOverlay.new()
	view.add_child(overlay)
	overlay.setup(view)
	overlay.set_active(true)
	var state: Dictionary = ledger.rules.initial_state()
	match mode:
		"place", "bad":
			var at := Vector2(34, 4) if mode == "place" else Vector2(24, 7)
			var checked: Dictionary = ledger.check_item("house-hollow", at, "E", state)
			overlay.set_cursor(at)
			overlay.show_ghost({"kind": "building", "asset": "log-cabin-large", "at": at, "facing": "E", "valid": checked.ok, "cells": AreaBuild.footprint_cells(checked.rect), "door": checked.door})
			print("check: ", checked.ok, " ", checked.reason)
		"tree":
			var at := Vector2(34.5, 8.5)
			overlay.set_cursor(at)
			overlay.show_ghost({"kind": "tree", "size": 1.25, "at": at, "valid": ledger.check_item("tree-elder", at, "S", state).ok})
		"move":
			overlay.set_cursor(Vector2(24, 6))
			overlay.highlight({"kind": "building", "id": "home"}, "move")
		"delete":
			var tree: Dictionary = ledger.area.trees[40]
			overlay.set_cursor(tree.at)
			overlay.highlight({"kind": "tree", "at": tree.at, "size": tree.size}, "delete")
		"locked":
			overlay.set_cursor(Vector2(49, 24))
			overlay.highlight({"kind": "building", "id": "mill"}, "locked")
	for _i: int in range(40):
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(args[0].get_base_dir())
	image.save_png(args[0])
	print("build overlay (", mode, ") -> ", args[0])
	quit(0)
