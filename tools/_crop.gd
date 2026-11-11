extends SceneTree
## -- <out> <x> <y> <w> <h> <pictures...>: crops each picture and lays them side by side.
func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var r := Rect2i(int(a[1]), int(a[2]), int(a[3]), int(a[4]))
	var pics: Array = a.slice(5)
	var sheet := Image.create(r.size.x * pics.size(), r.size.y, false, Image.FORMAT_RGBA8)
	for i: int in range(pics.size()):
		var img := Image.load_from_file(pics[i]); img.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(img, r, Vector2i(r.size.x * i, 0))
	sheet.save_png(a[0]); quit()
