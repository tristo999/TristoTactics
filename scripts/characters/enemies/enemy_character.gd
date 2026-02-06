# EnemyCharacter - AI-controlled enemy character
extends CharacterBase
class_name EnemyCharacter

signal ai_turn_completed

@export_group("AI Behavior")
@export var ai_pause_duration: float = 2.0

func _ready() -> void:
	team = Constants.TEAM_ENEMY
	super._ready()

func on_turn_started() -> void:
	pass

func execute_ai_turn() -> void:
	await get_tree().create_timer(ai_pause_duration).timeout
	
	var target = _find_nearest_player()
	
	# Move phase
	if target and movement_left > 0:
		var target_tile = _get_best_tile_toward(target)
		if target_tile != current_tile:
			var tilemap = get_tree().get_first_node_in_group("tilemap")
			if tilemap:
				tilemap.clear_highlights()
			move_to_tile(target_tile)
			await movement_finished
	
	# Attack phase
	if target and not has_attacked:
		var tilemap = get_tree().get_first_node_in_group("tilemap")
		if tilemap:
			tilemap.clear_highlights()
			tilemap.highlight_attack_range(current_tile, attack_range_min, attack_range_max)
		
		await get_tree().create_timer(ai_pause_duration * 0.5).timeout
		
		if can_attack_target(target):
			if tilemap:
				tilemap.clear_highlights()
			attack_target(target)
			await get_tree().create_timer(ai_pause_duration * 0.5).timeout
	
	await get_tree().create_timer(ai_pause_duration * 0.5).timeout
	ai_turn_completed.emit()

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
	
	# Check if already in attack range
	var current_dist = _tile_distance(current_tile, target.current_tile)
	if current_dist >= attack_range_min and current_dist <= attack_range_max:
		return current_tile
	
	var tilemap = get_tree().get_first_node_in_group("tilemap")
	var path = tilemap.get_astar_path(current_tile, target.current_tile) if tilemap else []
	if path.size() < 2:
		return current_tile
	
	# Find the best tile that puts us in attack range
	for i in range(min(movement_left, path.size() - 1), 0, -1):
		var tile = path[i]
		var dist = _tile_distance(tile, target.current_tile)
		if dist >= attack_range_min and dist <= attack_range_max:
			return tile
	
	# Can't reach attack range, move as close as possible without landing on target
	var max_index = min(movement_left, path.size() - 1)
	if path[max_index] == target.current_tile and max_index > 0:
		max_index -= 1
	return path[max_index]

# Note: _tile_distance() is inherited from CharacterBase

func _tile_distance(from: Vector2i, to: Vector2i) -> int:
	return abs(from.x - to.x) + abs(from.y - to.y)
