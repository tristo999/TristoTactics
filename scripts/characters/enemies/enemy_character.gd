# EnemyCharacter - AI-controlled enemy character
extends CharacterBase
class_name EnemyCharacter

@export_group("AI Behavior")
@export var ai_delay: float = 0.5

func on_turn_started() -> void:
	if ai_delay > 0:
		await get_tree().create_timer(ai_delay).timeout
	_execute_ai_turn()

func _execute_ai_turn() -> void:
	var target = _find_nearest_player()
	if target:
		var target_tile = _get_best_tile_toward(target)
		if target_tile != current_tile:
			move_to_tile(target_tile)

func _find_nearest_player() -> Node2D:
	var players = get_tree().get_nodes_in_group(Constants.GROUP_PLAYER_CHARACTERS)
	var nearest: Node2D = null
	var nearest_dist: float = INF
	for player in players:
		if not player.is_alive:
			continue
		var dist = current_tile.distance_to(player.current_tile)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = player
	return nearest

func _get_best_tile_toward(target: Node2D) -> Vector2i:
	if movement_left <= 0:
		return current_tile
	var tilemap = get_tree().get_first_node_in_group("tilemap")
	var path = tilemap.get_astar_path(current_tile, target.current_tile) if tilemap else []
	if path.size() < 2:
		return current_tile
	return path[min(movement_left, path.size() - 1)]
