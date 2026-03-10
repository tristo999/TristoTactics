# WalkingNPC - A stationary NPC in a walking scene.
# Place anywhere on the map; the position is snapped to the nearest tile at runtime.
# The player can click this NPC when standing adjacent to trigger its dialogue.
extends Node2D
class_name WalkingNPC

@export var npc_name: String = "Villager"
## One entry per line of spoken text. All lines are spoken by npc_name.
@export_multiline var dialogue_lines: Array[String] = ["Hello there, traveller!"]

## Tile this NPC occupies — set automatically at runtime from world position.
var current_tile: Vector2i = Vector2i.ZERO

func _ready() -> void:
	add_to_group("walking_npc")
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
	global_position = base_layer.to_global(base_layer.map_to_local(current_tile))

	# Block this tile in the shared AStar grid so the player can't walk through.
	var astar := tilemap.get("astar_grid") as AStarGrid2D
	if astar and astar.is_in_boundsv(current_tile):
		astar.set_point_solid(current_tile, true)

## Build typed DialogueLine objects from the exported string array.
func get_dialogue() -> Array[DialogueLine]:
	var result: Array[DialogueLine] = []
	for text in dialogue_lines:
		var dl := DialogueLine.new()
		dl.speaker = npc_name
		dl.text = text
		result.append(dl)
	return result
