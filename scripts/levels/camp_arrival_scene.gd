# CampArrivalScene - Beat 1 (ARRIVAL), a FULLY SCRIPTED cutscene. No player input.
#
# Beats:
#   1. Fade in; the hero walks out of the summoning-room doorway into the camp.
#   2. Camera pans up to Vael, who's giving orders to a pair of soldiers.
#   3. The soldiers acknowledge and disperse to their posts.
#   4. Vael notices the hero, walks down to meet them, and gives a warm welcome.
#   5. Vael leads the hero all the way up to the training ground (the arena).
#   6. Fade out (→ tutorial battle, when wired via next_scene_path).
#
# Hero = WalkingPlayer (locked, follow-cam disabled). Vael + soldiers are
# CinematicActors (placeholders, tinted). A dedicated CineCam is tweened.
extends WalkingScene
class_name CampArrivalScene

@export var fade_in_duration: float = 1.2
@export var tile_walk_time: float = 0.32   ## seconds per tile (meeting walk)
@export var lead_walk_duration: float = 4.2 ## total seconds for the walk to the arena
@export_file("*.tscn") var next_scene_path: String = ""

var _player: WalkingPlayer
var _vael: Node2D
var _s1: Node2D
var _s2: Node2D
var _cam: Camera2D
var _base: TileMapLayer
var _fx: CanvasLayer

func _ready() -> void:
	super._ready()
	_player = get_tree().get_first_node_in_group("walking_player") as WalkingPlayer
	_vael = get_node_or_null("Vael") as Node2D
	_s1 = get_node_or_null("Soldier1") as Node2D
	_s2 = get_node_or_null("Soldier2") as Node2D
	_cam = get_node_or_null("CineCam") as Camera2D
	if _player:
		_player.lock_movement()
		var pc := _player.get_node_or_null("Camera2D") as Camera2D
		if pc:
			pc.enabled = false
	_fx = CanvasLayer.new()
	_fx.layer = 120
	add_child(_fx)
	call_deferred("_run_cutscene")

func _run_cutscene() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_base = _get_base()
	if _cam:
		_cam.make_current()
		_cam.zoom = Vector2(1.7, 1.7)
		if _player:
			# Frame the camp with the south WALL along the bottom edge; the hero is
			# off-map below it and walks up through the doorway onto the screen.
			_cam.global_position = _player.global_position + Vector2(0, -210)

	# 1. The hero walks out of the building (up through the doorway) into the camp.
	await _fade(1.0, 0.0, fade_in_duration)
	await _wait(0.3)
	if _player:
		await _player.cinematic_walk_north(7, 2.8)
	await _wait(0.3)

	# 2. Pan up to Vael, mid-orders to his soldiers.
	if _vael:
		_pan_to(_vael.global_position, 1.6)
	await _wait(1.6)
	if _vael:
		_vael.face("down")
	if _s1:
		_s1.call("face", "up")
	if _s2:
		_s2.call("face", "up")
	await _say([["Vael", "— and the north pickets run double tonight. Go on, the lot of you."]])
	await _say([["Soldier", "Aye, Commander."]])

	# 3. Soldiers disperse to their posts.
	if _s1:
		_s1.call("walk_to", Vector2i(18, 45), 1.8)
	if _s2:
		_s2.call("walk_to", Vector2i(33, 45), 1.8)
	await _wait(1.0)

	# 4. Vael notices the hero, comes down, and welcomes them.
	if _vael and _player:
		_vael.call("face_tile", _player.current_tile)
	await _wait(0.4)
	await _say([["Vael", "...Well, now. Look who the circle finally coughed up."]])
	if _player:
		_player.face("up")
	if _vael and _player:
		var meet: Vector2i = _player.current_tile + Vector2i(0, -2)
		var dur: float = maxi(absi(_vael.current_tile.y - meet.y), 1) * tile_walk_time
		_pan_to((_world(meet) + _player.global_position) * 0.5, dur)
		await _vael.call("walk_to", meet, dur)
		_vael.call("face_tile", _player.current_tile)
	await _wait(0.3)
	await _say([
		["Vael", "Easy. The crossing takes it out of everyone the first time — breathe."],
		["Vael", "Welcome to the camp, friend. You're one of us now..."],
		["Vael", "We've waited a long time for someone like you. Come — I'll show you the yard."],
	])

	# 5. Vael leads the hero up to the training ground (the arena's south gate).
	var lead_dur: float = lead_walk_duration
	if _vael:
		var dest := Vector2i(25, 31)   # the arena south gate
		var tiles: int = maxi(_player.current_tile.y - 33, 1) if _player else 14
		_pan_to(_world(Vector2i(26, 31)), lead_dur)          # follow up to the arena
		_vael.call("walk_to", dest, lead_dur)                 # parallel
		if _player:
			_player.cinematic_walk_north(tiles, lead_dur)     # hero follows
		await _wait(lead_dur + 0.3)

	# 6. Out. (→ tutorial battle, when next_scene_path is set)
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

func _pan_to(target: Vector2, dur: float) -> void:
	if _cam == null:
		return
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_cam, "global_position", target, dur)
	await tw.finished

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
		rect.queue_free()

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
