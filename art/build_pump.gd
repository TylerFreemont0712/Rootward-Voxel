class_name BuildPump
extends RefCounted
## Building a place runs in one go on the main thread, so nothing is drawn while it works. Whoever wants the screen to
## keep moving meanwhile (the clockwork veil) sets `tick`; the builders call `pump()` between pieces, and it runs the
## tick at most every 25 ms. Presentation only: it never changes what is built.

static var tick: Callable = Callable()
static var _last: int = 0


static func pump() -> void:
	if not tick.is_valid():
		return
	var now: int = Time.get_ticks_msec()
	if now - _last < 25:
		return
	_last = now
	tick.call()
