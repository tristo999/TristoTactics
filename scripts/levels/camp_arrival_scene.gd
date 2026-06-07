# CampArrivalScene - Beat 1 (ARRIVAL), a FULLY SCRIPTED cutscene. No player input.
#
# Beats:
#   1. Fade in. The hero stands in the summoning-room doorway.
#   2. Camera pans up the camp to Vael, who's finishing giving orders.
#   3. Vael notices the hero, turns, and walks down to meet them.
#   4. They talk (Vael's warm welcome).
#   5. Vael leads the hero up toward the training ground; the camera follows.
#   6. Fade out (→ tutorial battle, wired later).
#
# Actors: the hero is the WalkingPlayer (locked; its follow-camera disabled).
# Vael is a CinematicActor (placeholder, tinted). A dedicated CineCam is tweened.
extends WalkingScene
class_name CampArrivalScene

@export var fade_in_duration: float = 1.2
@export var tile_walk_time: float = 0.34   ## seconds per tile for cutscene walks
@export_file("*.tscn") var next_scene_path: String = ""

var _player: WalkingPlayer
var _vael: Node2D   # a CinematicActor (duck-typed to avoid class-load order issues)
var _cam: Camera2D
var _base: TileMapLayer
var _fx: CanvasLayer

func _ready() -> void:
	super._ready()
	_player = get_tree().get_first_node_in_group("walking_player") as WalkingPlayer
	_vael = get_node_or_null("Vael") as Node2D
	_cam = get_node_or_null("CineCam") as Camera2D
	if _player:
		_player.lock_movement()
		var pc := _player.get_node_or_null("Camera2D") as Camera2D
		if pc:
			pc.enabled = false   # the cutscene camera takes over
	# overlay layer for fades
	_fx = CanvasLayer.new()
	_fx.layer = 120
	add_child(_fx)
	call_deferred("_run_cutscene")

func _run_cutscene() -> void:
	await get_tree().process_frame
	await get_tree().process_frame   # let player/Vael snap to tiles
	_base = _get_base()
	if _cam:
		_cam.make_current()
		_cam.zoom = Vector2(1.7, 1.7)
		if _player:
			_cam.global_position = _player.global_position

	# 1. Arrive from the chamber.
	await _fade(1.0, 0.0, fade_in_duration)
	await _wait(0.4)

	# 2. Pan up to Vael, mid-orders.
	if _vael:
		await _pan_to(_vael.global_position, 1.6)
	await _wait(0.3)
	await _say([["Vael", "— and the north pickets run double tonight. Go on, the lot of you."]])

	# 3. Vael notices the hero and walks down to meet them.
	if _vael:
		_vael.face("down")
	await _wait(0.5)
	await _say([["Vael", "...Well, now. Look who the circle finally coughed up."]])
	if _player:
		_player.face("up")
	if _vael and _player:
		var meet: Vector2i = _player.current_tile + Vector2i(0, -2)
		var dur: float = maxi(absi(_vael.current_tile.y - meet.y), 1) * tile_walk_time
		var mid: Vector2 = (_world(meet) + _player.global_position) * 0.5
		_pan_to(mid, dur)          # camera eases to the meeting (parallel)
		await _vael.walk_to(meet, dur)
		_vael.face_tile(_player.current_tile)   # turn to face the hero, not his last step
	await _wait(0.3)

	# 4. The welcome.
	await _say([
		["Vael", "Easy. The crossing takes it out of everyone the first time — breathe."],
		["Vael", "Welcome to the camp, friend. You're one of us now..."],
		["Vael", "We've waited a long time for someone like you. Come — there's people you should meet."],
	])

	# 5. Vael leads up to the training ground; the hero follows.
	var up_tiles := 6
	var udur: float = up_tiles * tile_walk_time
	if _vael:
		var lead: Vector2i = _vael.current_tile + Vector2i(0, -up_tiles)
		_pan_to(_world(lead) + Vector2(0, 32), udur)   # follow up (parallel)
		_vael.walk_to(lead, udur)                       # parallel
	if _player:
		_player.cinematic_walk_north(up_tiles, udur)    # parallel
	await _wait(udur + 0.3)

	# 6. Out. (transition to the tutorial battle goes here once wired)
	await _fade(0.0, 1.0, 1.0)
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)

# --- helpers ---------------------------------------------------------------

func _get_base() -> TileMapLayer:
	var tm := get_tree().get_first_node_in_group("tilemap")
	return tm.get_node_or_null("BaseGrid") as TileMapLayer if tm else null

func _world(tile: Vector2i) -> Vector2:
	if _base == null:
		return Vector2.ZERO
	return _base.to_global(_base.map_to_local(tile))

func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

## Tween the camera center to a world point. Awaitable (await ... ), or fire-and-forget.
func _pan_to(target: Vector2, dur: float) -> void:
	if _cam == null:
		return
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_cam, "global_position", target, dur)
	await tw.finished

## Black overlay fade. from/to are alpha. Awaitable.
func _fade(from_a: float, to_a: float, dur: float) -> void:
	var rect := ColorRect.new()
	rect.color = Color(0, 0, 0, from_a)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tw := create_tween()
	tw.tween_property(rect, "color:a", to_a, dur)
	await tw.finished
	if to_a <= 0.01:
		rect.queue_free()   # faded clear -- drop it; keep opaque fades on screen

## Play a sequence of [speaker, text] rows through the DialogueBox. Awaitable.
func _say(rows: Array) -> void:
	var box: CanvasLayer = get_tree().get_first_node_in_group("dialogue_box")
	if box == null or not box.has_method("play_sequence"):
		return
	var lines: Array[DialogueLine] = []
	for row in rows:
		var dl := DialogueLine.new()
		dl.speaker = row[0]
		dl.text = row[1]
		lines.append(dl)
	await box.play_sequence(lines)
