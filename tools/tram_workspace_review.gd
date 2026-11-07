extends "res://test/test_welcome_flow.gd"
## The real shared-slate quest flow, plus a normal-scale view across the complete tram stop.
func _shot(name:String)->void:
	await super._shot(name)
	if name=="05-working-sign" and output!="":
		var before:Vector2i=game.session.player_cell()
		_place(Vector2i(13,6))
		await super._shot("05c-tram-stop-wide")
		_place(before)
