# SummoningRoomScene - Beat 1. The hero arrives in the summoning chamber.
# The circle is already dead. The room is cold and empty. One door north.
#
# == Sequence ==
# 1. Fade in from white (arriving from the corridor's white-out flash).
# 2. A beat of stillness — no dialogue, just the empty room.
# 3. Player control unlocks.
# 4. Player walks to the door → black fade → scene change to camp.
#
# == Scene setup in editor ==
# Root: SummoningRoomScene (this script)
# Children:
#   • Tilemap          — room tilemap with BaseGrid layer
#   • WalkingPlayer    — scenes/characters/WalkingPlayer.tscn
#   • DoorTrigger      — Node2D with walking_door.gd, positioned on north door tile
#   • SummoningCircle  — Node2D with summoning_circle.gd (placeholder Sprite2D)
extends WalkingScene
class_name SummoningRoomScene

## Scene to load after the player exits through the door.
@export_file("*.tscn") var next_scene_path: String = "res://scenes/levels/tutorial_scene.tscn"
## How long the white fade-in takes on scene start.
@export var fade_in_duration: float = 1.2
## Seconds of stillness before player control unlocks.
@export var still_hold_duration: float = 1.8

var _player: WalkingPlayer = null
var _sequence_running: bool = false

func _ready() -> void:
	super._ready()

	_player = get_tree().get_first_node_in_group("walking_player") as WalkingPlayer
	if _player:
		_player.lock_movement()
	else:
		push_warning("[SummoningRoom] WalkingPlayer not found.")

	var door := get_node_or_null("DoorTrigger") as WalkingDoor
	if door:
		door.interacted.connect(_on_door_triggered, CONNECT_ONE_SHOT)
	else:
		push_warning("[SummoningRoom] DoorTrigger node not found.")

	call_deferred("_run_sequence")

func _exit_tree() -> void:
	_sequence_running = false

# ---------------------------------------------------------------------------
# Opening sequence — fade in, stillness, unlock.
# ---------------------------------------------------------------------------
func _run_sequence() -> void:
	await get_tree().process_frame
	_sequence_running = true

	# White overlay fades out — arriving from the corridor flash.
	var cl := CanvasLayer.new()
	cl.layer = 120
	add_child(cl)
	var white := ColorRect.new()
	white.color = Color(1, 1, 1, 1)
	white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(white)
	white.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var fade := create_tween()
	fade.tween_property(white, "color:a", 0.0, fade_in_duration)
	await fade.finished
	if not _sequence_running: return
	cl.queue_free()

	# Stillness — the room is empty and silent.
	await get_tree().create_timer(still_hold_duration).timeout
	if not _sequence_running: return

	# Hand control to the player.
	if _player:
		_player.unlock_movement()

# ---------------------------------------------------------------------------
# Door interaction — save checkpoint, fade to black, change scene.
# ---------------------------------------------------------------------------
func _on_door_triggered() -> void:
	if _player:
		_player.lock_movement()

	PlayerDataManager.set_checkpoint(next_scene_path)
	PlayerDataManager.save_player_data()

	var cl := CanvasLayer.new()
	cl.layer = 120
	add_child(cl)
	var black := ColorRect.new()
	black.color = Color(0, 0, 0, 0)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(black)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var fade := create_tween()
	fade.tween_property(black, "color:a", 1.0, 0.8)
	await fade.finished
	get_tree().change_scene_to_file(next_scene_path)
