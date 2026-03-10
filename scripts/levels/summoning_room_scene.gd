extends Node2D
class_name SummoningRoomScene

## Scene to load after the player exits through the door.
@export_file("*.tscn") var next_scene_path: String = "res://scenes/levels/tutorial_scene.tscn"

var _player: WalkingPlayer = null

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("walking_player") as WalkingPlayer

	var door: Node = get_node_or_null("DoorTrigger")
	if door:
		door.interacted.connect(_on_door_triggered, CONNECT_ONE_SHOT)

func _on_door_triggered() -> void:
	if _player:
		_player.lock_movement()
	PlayerDataManager.set_checkpoint(next_scene_path)
	PlayerDataManager.save_player_data()
	var canvas := CanvasLayer.new()
	canvas.layer = 120
	add_child(canvas)
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(overlay)
	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.8)
	await tween.finished
	get_tree().change_scene_to_file(next_scene_path)
