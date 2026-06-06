# WalkingDoor - An interactable door in a walking scene.
# Add to a Node2D positioned on the door tile.
# The player can face it and press Space/click to trigger interact().
# Connect the "interacted" signal in the parent scene to handle what happens.
extends Node2D
class_name WalkingDoor

signal interacted

var current_tile: Vector2i = Vector2i.ZERO

func _ready() -> void:
	add_to_group("walking_interactable")
	call_deferred("_snap_to_tile")

func _snap_to_tile() -> void:
	var tilemap := get_tree().get_first_node_in_group("tilemap")
	if not tilemap:
		return
	var base_layer: TileMapLayer = tilemap.get_node_or_null("BaseGrid")
	if not base_layer:
		return
	var local_pos := base_layer.to_local(global_position)
	current_tile = base_layer.local_to_map(local_pos)

func interact() -> void:
	interacted.emit()
