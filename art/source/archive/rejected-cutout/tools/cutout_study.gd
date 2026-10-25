# INACTIVE EXPERIMENT: visually rejected; preserve the original painted runtime character. See pipeline/CHARACTERS.md.
extends Node2D
## The actual shared rig, shown in all views/states with a skin and hand-slot example.

const Rig := preload("res://art/rigs/chibi_v1/rig.tscn")


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("dce3d8"))
	_label("Layered character rig — idle / walking", Vector2(32, 10), 25)
	var directions: Array[String] = ["se", "sw", "ne", "nw"]
	for row: int in range(2):
		for column: int in range(4):
			var rig: CutoutRig = Rig.instantiate()
			rig.position = Vector2(32 + column * 384, 50 + row * 440)
			add_child(rig)
			rig.set_motion(directions[column], row == 1)
			if row == 1 and column == 3:
				rig.set_skin("dusk_outfit")
				rig.equip_demo_staff(true)
			_label(("IDLE " if row == 0 else "WALK ") + directions[column].to_upper() + (" / skin + hand item" if row == 1 and column == 3 else ""), rig.position + Vector2(40, 365), 18)
	_label("One bone hierarchy and motion library • layered attachments • continuous interpolation", Vector2(32, 950), 18)


func _label(value: String, at: Vector2, font_size: int) -> void:
	var label := Label.new()
	label.text = value
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("263d36"))
	add_child(label)
