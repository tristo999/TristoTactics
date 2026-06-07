# CampArrivalScene - Beat 1 (ARRIVAL). The hero walks out of the summoning room
# (the solid south wall + door of camp_grounds) into the camp, and Commander Vael
# greets them warmly.
#
# Scripted sequence:
#   1. Fade in from black (arriving from the summoning chamber).
#   2. Player control unlocks; they walk out the doorway into the camp.
#   3. PROXIMITY TRIGGER: when the player gets near Vael, his greeting auto-plays
#      once (the first real "WHEN player approaches THEN dialogue" trigger).
#
# This is a walking scene (no battle). Vael is a placeholder WalkingNPC; the
# greeting is authored here, not in his interaction dialogue.
extends WalkingScene
class_name CampArrivalScene

## Seconds for the arrival fade-in.
@export var fade_in_duration: float = 1.2
## Fire Vael's greeting when the player is within this many tiles of him.
@export var greet_distance: int = 2

var _player: WalkingPlayer = null
var _vael: WalkingNPC = null
var _greeted: bool = false
var _accepting: bool = false

func _ready() -> void:
	super._ready()
	_player = get_tree().get_first_node_in_group("walking_player") as WalkingPlayer
	_vael = get_node_or_null("Vael") as WalkingNPC
	if _player:
		_player.lock_movement()
	else:
		push_warning("[CampArrival] WalkingPlayer not found.")
	call_deferred("_run_intro")

func _run_intro() -> void:
	await get_tree().process_frame

	# Fade in from black -- arriving from the summoning chamber.
	var cl := CanvasLayer.new()
	cl.layer = 120
	add_child(cl)
	var black := ColorRect.new()
	black.color = Color(0, 0, 0, 1)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(black)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var fade := create_tween()
	fade.tween_property(black, "color:a", 0.0, fade_in_duration)
	await fade.finished
	cl.queue_free()

	if _player:
		_player.unlock_movement()
	_accepting = true

func _process(_delta: float) -> void:
	if _greeted or not _accepting or _player == null or _vael == null:
		return
	var d: Vector2i = (_player.current_tile - _vael.current_tile).abs()
	if maxi(d.x, d.y) <= greet_distance:
		_greeted = true
		_greet()

func _greet() -> void:
	if _player:
		_player.lock_movement()
	var box: CanvasLayer = get_tree().get_first_node_in_group("dialogue_box")
	if box and box.has_method("play_sequence"):
		await box.play_sequence(_greeting_lines())
	if _player:
		_player.unlock_movement()

## Vael's warm welcome -- a little too warm (sets up the later reframe).
func _greeting_lines() -> Array[DialogueLine]:
	var rows := [
		"There — there you are. By the Authority, you actually came through.",
		"Easy, now. The crossing takes it out of everyone the first time. Breathe.",
		"Welcome to the camp, friend. You're one of us now...",
		"We've waited a long time for someone like you. Come — there's people you should meet.",
	]
	var lines: Array[DialogueLine] = []
	for t in rows:
		var dl := DialogueLine.new()
		dl.speaker = "Vael"
		dl.text = t
		lines.append(dl)
	return lines
