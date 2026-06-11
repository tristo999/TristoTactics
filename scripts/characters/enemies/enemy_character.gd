# EnemyCharacter - AI-controlled character. Drives both the enemy team and the
# AI "green" ally team (set team_override = Constants.TEAM_ALLY); the AI seeks the
# nearest HOSTILE unit, so the same logic serves either side.
extends CharacterBase
class_name EnemyCharacter

var ai_pause_duration: float = 1.0

## When set (e.g. TEAM_ALLY), this unit joins that team instead of the enemy team.
## Lets a green ally reuse this AI without a separate scene/class.
@export var team_override: String = ""

## Scripted scenes can park a unit: when false, the unit's whole turn is skipped
## (no move, no attack) — it just stands there. Reactions (follow-ups) still fire.
## The spar uses this so partners hold still while the lesson owns the turn flow.
@export var ai_enabled: bool = true

func _ready() -> void:
	team = team_override if team_override != "" else Constants.TEAM_ENEMY
	if character_data:
		ai_pause_duration = character_data.ai_pause_duration
	super._ready()

# --- AI Decision Methods (pure queries, no side effects) ---

## Returns the tile the AI wants to move to.
func get_ai_move_target() -> Vector2i:
	var target = _find_nearest_hostile()
	if not target or movement_left <= 0:
		return current_tile
	return _get_best_tile_toward(target)

## Returns the character to attack, or null if none in range.
func get_ai_attack_target() -> CharacterBase:
	var target = _find_nearest_hostile()
	if target and not has_used_action and can_attack_target(target):
		return target
	return null

## Nearest living unit this AI is hostile to (enemies seek players+allies, allies
## seek enemies). One method serves both teams via the hostility model.
func _find_nearest_hostile() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist: int = 9999
	for other in get_tree().get_nodes_in_group(Constants.GROUP_ALL_CHARACTERS):
		if other == self or not other.is_alive or not is_hostile_to(other):
			continue
		var dist = _tile_distance(current_tile, other.current_tile)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = other
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
