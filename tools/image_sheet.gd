extends SceneTree
## Lays pictures side by side at one height on a dark sheet, for concept-versus-model reviews.
##   -- <output PNG> <height> <picture> [picture ...]


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 3:
		printerr("usage: -- <output PNG> <height> <picture> [picture ...]")
		quit(2)
		return
	var height: int = int(args[1])
	var pictures: Array[Image] = []
	var width: int = 0
	for path: String in args.slice(2):
		var image := Image.load_from_file(path)
		image.convert(Image.FORMAT_RGBA8)
		image.resize(roundi(float(image.get_width()) * height / image.get_height()), height, Image.INTERPOLATE_LANCZOS)
		pictures.append(image)
		width += image.get_width() + 16
	var sheet := Image.create(width + 16, height + 32, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("263337"))
	var x: int = 16
	for image: Image in pictures:
		sheet.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(x, 16))
		x += image.get_width() + 16
	sheet.save_png(args[0])
	print("Saved ", args[0])
	quit()
