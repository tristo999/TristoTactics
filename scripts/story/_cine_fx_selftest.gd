# CineFx self-test. Exercises the refactored cinematic primitives across the exact
# modes the consumers use (flash self-frees; fade-to-black holds; fade-to-clear frees;
# dialogue building; say with/without a box; wait). Run scenes/dev/cine_fx_selftest.tscn
# (F6 or headless) → PASS/FAIL per check.
extends Node

# Records what a fake dialogue box was asked to play.
class _FakeBox extends CanvasLayer:
	var played: Array = []
	func play_sequence(lines: Array) -> void:
		played = lines
		await (Engine.get_main_loop() as SceneTree).process_frame

var _results: Array = []

func _ready() -> void:
	await _run()
	var passed := 0
	for r in _results:
		if r[0]:
			passed += 1
		print(("  PASS " if r[0] else "  FAIL ") + r[1])
	var ok := passed == _results.size()
	print("\n[CineFxSelfTest] %d/%d checks passed — %s" % [passed, _results.size(), "ALL PASS" if ok else "FAILURES"])
	await get_tree().create_timer(0.1).timeout
	get_tree().quit(0 if ok else 1)

func _check(c: bool, label: String) -> void:
	_results.append([c, label])

func _new_layer() -> CanvasLayer:
	var l := CanvasLayer.new()
	add_child(l)
	return l

func _rects(layer: CanvasLayer) -> int:
	var n := 0
	for c in layer.get_children():
		if c is ColorRect:
			n += 1
	return n

func _settle() -> void:
	# Let queue_free() take effect.
	await get_tree().process_frame
	await get_tree().process_frame

func _run() -> void:
	# 1. flash self-frees its overlay
	var l1 := _new_layer()
	await CineFx.flash(l1, Color(1, 1, 1, 0.9), 0.02, 0.02)
	await _settle()
	_check(_rects(l1) == 0, "flash overlay self-frees")

	# 2. fade-to-black (keep) holds the overlay at full alpha (spar _fade_black, camp fade-out)
	var l2 := _new_layer()
	await CineFx.fade(l2, 1.0, 0.02, true)
	await _settle()
	var held: bool = _rects(l2) == 1
	var black: bool = held and abs((l2.get_child(0) as ColorRect).color.a - 1.0) < 0.05
	_check(held and black, "fade-to-black (keep) holds overlay at full alpha")

	# 3. fade-to-clear (keep=false) self-frees (camp fade-in)
	var l3 := _new_layer()
	await CineFx.fade(l3, 0.0, 0.02, false)
	await _settle()
	_check(_rects(l3) == 0, "fade-to-clear (keep=false) self-frees")

	# 4. lines() builds typed dialogue correctly
	var lines := CineFx.lines([["Vael", "Up, all of you!"], ["Borin", "Backs to the pad!"]])
	var lines_ok := lines.size() == 2 and lines[0].speaker == "Vael" \
		and lines[1].text == "Backs to the pad!"
	_check(lines_ok, "lines() builds typed DialogueLine array")

	# 5. say() is a safe no-op when no dialogue_box is present
	await CineFx.say(get_tree(), [["X", "into the void"]])
	_check(true, "say() with no dialogue_box returns without error")

	# 6. say() routes lines to the box in group 'dialogue_box'
	var box := _FakeBox.new()
	box.add_to_group("dialogue_box")
	add_child(box)
	await CineFx.say(get_tree(), [["Vael", "Welcome to the camp."]])
	_check(box.played.size() == 1 and box.played[0].speaker == "Vael", "say() routes to dialogue_box")

	# 7. wait() resolves
	await CineFx.wait(get_tree(), 0.05)
	_check(true, "wait() resolves")
