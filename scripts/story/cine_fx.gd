# CineFx - shared cinematic primitives (dialogue + screen effects) usable from ANY
# scene, battle or walking. Before this, flash/fade/wait/say were reimplemented in
# every scripted director (camp_arrival, tutorial_spar) and in the trigger engine,
# each with its own ColorRect tween that drifted apart. This is the single source.
#
# Screen effects draw onto a CanvasLayer the caller owns (so layering stays under the
# caller's control and the overlay frees with the caller's scene — important for the
# "fade to black then change scene" pattern). Dialogue and waits only need the tree.
#
#   await CineFx.say(get_tree(), [["Vael", "...this is no drill!"]])
#   await CineFx.flash(_fx, Color(1, 1, 1, 0.9), 0.06, 0.5)
#   await CineFx.fade(_fx, 1.0, 0.8)            # fade to black, leave it up
class_name CineFx
extends RefCounted

## Build a typed dialogue array from [[speaker, text], …] rows.
static func lines(rows: Array) -> Array[DialogueLine]:
	var out: Array[DialogueLine] = []
	for row in rows:
		var dl := DialogueLine.new()
		dl.speaker = row[0]
		dl.text = row[1]
		out.append(dl)
	return out

## Play a dialogue sequence via the scene's "dialogue_box". No-op if none present.
static func say(tree: SceneTree, rows: Array) -> void:
	var box = tree.get_first_node_in_group("dialogue_box")
	if box == null or not box.has_method("play_sequence"):
		return
	await box.play_sequence(lines(rows))

## Pause for `seconds`.
static func wait(tree: SceneTree, seconds: float) -> void:
	await tree.create_timer(seconds).timeout

## Full-screen color flash (alpha up then down), drawn on `layer`. Frees itself.
static func flash(layer: CanvasLayer, color: Color, up: float = 0.06, down: float = 0.5) -> void:
	if layer == null:
		return
	var r := _full_rect(layer, Color(color.r, color.g, color.b, 0.0))
	var tw := r.create_tween()
	tw.tween_property(r, "color:a", color.a, up)
	tw.tween_property(r, "color:a", 0.0, down)
	await tw.finished
	r.queue_free()

## Fade a black overlay to `to_alpha` (1 = black, 0 = clear) over `dur`, drawn on
## `layer`. Starts from the opposite alpha. When fading clear (to_alpha≈0) and
## `keep` is false, the overlay is removed; otherwise it stays (e.g. hold black
## through a scene change).
static func fade(layer: CanvasLayer, to_alpha: float, dur: float, keep: bool = true) -> void:
	if layer == null:
		return
	var from_a := 0.0 if to_alpha > 0.0 else 1.0
	var r := _full_rect(layer, Color(0, 0, 0, from_a))
	var tw := r.create_tween()
	tw.tween_property(r, "color:a", to_alpha, dur)
	await tw.finished
	if to_alpha <= 0.01 and not keep:
		r.queue_free()

static func _full_rect(layer: CanvasLayer, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(r)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return r
