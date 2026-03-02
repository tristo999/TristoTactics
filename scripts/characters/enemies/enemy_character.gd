# EnemyCharacter - AI-controlled enemy character.
extends CharacterBase
class_name EnemyCharacter

@export_group("AI Behavior")
@export var ai_pause_duration: float = 1.0

func _ready() -> void:
	team = Constants.TEAM_ENEMY
	# Apply ai_pause_duration from CharacterData if present
	if character_data and character_data.override_stats:
		ai_pause_duration = character_data.ai_pause_duration
	super._ready()

# --- AI Decision Methods (pure queries, no side effects) ---

## Returns the tile the AI wants to move to.
func get_ai_move_target() -> Vector2i:
	var target = _find_nearest_player()
	if not target or movement_left <= 0:
		return current_tile
	return _get_best_tile_toward(target)

## Returns the character to attack, or null if none in range.
func get_ai_attack_target() -> CharacterBase:
	var target = _find_nearest_player()
	if target and not has_attacked and can_attack_target(target):
		return target
	return null

func _find_nearest_player() -> Node2D:
	var players = get_tree().get_nodes_in_group(Constants.GROUP_PLAYER_CHARACTERS)
	var nearest: Node2D = null
	var nearest_dist: int = 9999
	for player in players:
		if not player.is_alive:
			continue
		var dist = _tile_distance(current_tile, player.current_tile)
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
	if not tilemap:
		return current_tile
	
	var path = tilemap.get_astar_path(current_tile, target.current_tile)
	
	# Direct path found — use it
	if path.size() >= 2:
		# Walk the path accumulating terrain costs to find the farthest reachable index
		var max_reachable_index := 0
		var cost_so_far := 0
		for i in range(1, path.size()):
			var step_cost: int = TerrainRegistry.get_move_cost(path[i], tilemap)
			if cost_so_far + step_cost > movement_left:
				break
			cost_so_far += step_cost
			max_reachable_index = i
		
		if max_reachable_index == 0:
			return current_tile
		
		# Find the best reachable tile that puts us in attack range
		for i in range(max_reachable_index, 0, -1):
			var tile = path[i]
			var dist = _tile_distance(tile, target.current_tile)
			if dist >= attack_range_min and dist <= attack_range_max:
				return tile
		
		# Can't reach attack range, move as close as possible without landing on target
		if path[max_reachable_index] == target.current_tile and max_reachable_index > 0:
			max_reachable_index -= 1
		return path[max_reachable_index]
	
	# No direct path (blocked by other characters) — pick the reachable tile
	# closest to the target so we still make progress.
	return _get_closest_reachable_tile_toward(tilemap, target)

## Fallback when A* path is blocked: pick the closest reachable tile.
func _get_closest_reachable_tile_toward(tilemap: Node2D, target: Node2D) -> Vector2i:
	var reachable = tilemap.get_reachable_tiles(current_tile, movement_left)
	if reachable.is_empty():
		return current_tile
	
	var best_tile: Vector2i = current_tile
	var best_dist: int = _tile_distance(current_tile, target.current_tile)
	
	for tile in reachable:
		# Make sure we can actually path to this tile (no blocked intermediate tiles)
		var path = tilemap.get_astar_path(current_tile, tile)
		if path.size() < 2:
			continue
		var dist = _tile_distance(tile, target.current_tile)
		if dist < best_dist:
			best_dist = dist
			best_tile = tile
	
	return best_tile
