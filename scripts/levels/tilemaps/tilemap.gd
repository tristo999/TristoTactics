# Tilemap - Handles tile rendering, pathfinding, and tile interaction
extends Node2D

const INVALID_TILE = Vector2i(-9999, -9999)

@onready var base_layer: TileMapLayer = $BaseGrid
@onready var wall_tilemap: TileMapLayer = $Walls
@onready var highlight_layer: TileMapLayer = $HighlightLayer

var astar_grid: AStarGrid2D
var last_hovered_tile: Vector2i = INVALID_TILE
var prev_highlight_atlas_coords: Dictionary = {}
var game_manager: Node = null
var cached_occupied_tiles: Dictionary = {}

func _ready() -> void:
	add_to_group("tilemap")
	setup_astar_grid()
	add_walkable_cells_from_tilemap()
	call_deferred("_cache_game_manager")
	EventBus.character_moved.connect(func(_c, _f, _t): _refresh_occupied_tiles())
	EventBus.turn_started.connect(func(_c): _refresh_occupied_tiles())

func _cache_game_manager() -> void:
	var scene = get_tree().get_current_scene()
	if scene:
		game_manager = scene.find_child("GameManager", true, false)

func _refresh_occupied_tiles() -> void:
	cached_occupied_tiles.clear()
	if not game_manager:
		return
	for c in game_manager.turn_order:
		if "current_tile" in c:
			cached_occupied_tiles[c.current_tile] = c

# =============================================================================
# MOUSE HOVER HANDLING
# =============================================================================

func _process(_delta: float) -> void:
	_handle_mouse_hover()

func _handle_mouse_hover() -> void:
	var mouse_pos = highlight_layer.get_global_mouse_position()
	var local_mouse = highlight_layer.to_local(mouse_pos)
	var tile = highlight_layer.local_to_map(local_mouse)
	
	if tile == last_hovered_tile:
		return
	
	_restore_tile_highlight(last_hovered_tile)
	_apply_mouse_over_highlight(tile)
	
	last_hovered_tile = tile
	EventBus.tile_hovered.emit(tile)

func _restore_tile_highlight(tile: Vector2i) -> void:
	if not prev_highlight_atlas_coords.has(tile):
		return
	var prev_atlas = prev_highlight_atlas_coords[tile]
	var current_atlas = highlight_layer.get_cell_atlas_coords(tile)
	if prev_atlas == null:
		highlight_layer.erase_cell(tile)
	elif current_atlas == Constants.HIGHLIGHT_MOUSE_OVER or current_atlas == Vector2i(-1, -1):
		highlight_layer.set_cell(tile, Constants.TILE_SOURCE_ID, prev_atlas)
	prev_highlight_atlas_coords.erase(tile)

func _apply_mouse_over_highlight(tile: Vector2i) -> void:
	var current_atlas = highlight_layer.get_cell_atlas_coords(tile)
	if current_atlas == Constants.HIGHLIGHT_MOUSE_OVER:
		return
	if typeof(current_atlas) == TYPE_VECTOR2I and current_atlas != Vector2i(-1, -1):
		prev_highlight_atlas_coords[tile] = current_atlas
	else:
		prev_highlight_atlas_coords[tile] = null
	highlight_layer.set_cell(tile, Constants.TILE_SOURCE_ID, Constants.HIGHLIGHT_MOUSE_OVER)

# =============================================================================
# A* PATHFINDING
# =============================================================================

func setup_astar_grid() -> void:
	astar_grid = AStarGrid2D.new()
	astar_grid.region = base_layer.get_used_rect()
	astar_grid.cell_size = base_layer.tile_set.tile_size
	astar_grid.jumping_enabled = false
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()

func add_walkable_cells_from_tilemap() -> void:
	for cell in base_layer.get_used_cells():
		if astar_grid.is_in_boundsv(cell):
			astar_grid.set_point_solid(cell, false)
	
	for cell in wall_tilemap.get_used_cells():
		if astar_grid.is_in_boundsv(cell):
			astar_grid.set_point_solid(cell, true)

func get_astar_path(start: Vector2i, end: Vector2i) -> Array:
	if astar_grid == null:
		push_error("AStar grid not initialized!")
		return []
	
	if not astar_grid.is_in_boundsv(start) or not astar_grid.is_in_boundsv(end):
		push_error("Start or end point not in grid!")
		return []
	
	var temporarily_blocked: Array[Vector2i] = []
	
	for tile in cached_occupied_tiles.keys():
		if tile != start and astar_grid.is_in_boundsv(tile):
			if not astar_grid.is_point_solid(tile):
				astar_grid.set_point_solid(tile, true)
				temporarily_blocked.append(tile)
	
	var path = astar_grid.get_id_path(start, end)
	
	for tile in temporarily_blocked:
		astar_grid.set_point_solid(tile, false)
	
	return path

# =============================================================================
# TILE HIGHLIGHTING
# =============================================================================

func highlight_reachable_tiles(start: Vector2i, max_range: int) -> void:
	clear_highlights()
	if max_range <= 0:
		return
	_refresh_occupied_tiles()
	var reachable = _calculate_reachable_tiles(start, max_range)
	for tile in reachable:
		highlight_layer.set_cell(tile, Constants.TILE_SOURCE_ID, Constants.HIGHLIGHT_REACHABLE)

func _calculate_reachable_tiles(start: Vector2i, max_range: int) -> Array:
	var visited := {start: true}
	var reachable: Array = []
	var queue: Array = [[start, 0]]
	while queue.size() > 0:
		var current = queue.pop_front()
		var pos: Vector2i = current[0]
		var dist: int = current[1]
		if dist > max_range:
			continue
		if pos != start and not astar_grid.is_point_solid(pos) and not cached_occupied_tiles.has(pos):
			reachable.append(pos)
		for dir in Constants.CARDINAL_DIRECTIONS:
			var neighbor = pos + dir
			if visited.has(neighbor) or not astar_grid.is_in_boundsv(neighbor):
				continue
			if astar_grid.is_point_solid(neighbor) or cached_occupied_tiles.has(neighbor):
				continue
			visited[neighbor] = true
			queue.push_back([neighbor, dist + 1])
	return reachable

func clear_highlights() -> void:
	for cell in highlight_layer.get_used_cells():
		highlight_layer.erase_cell(cell)
	prev_highlight_atlas_coords.clear()
	last_hovered_tile = INVALID_TILE

# =============================================================================
# INPUT HANDLING
# =============================================================================

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not game_manager:
		return
	var tile = _get_tile_at_mouse()
	var atlas = highlight_layer.get_cell_atlas_coords(tile)
	var prev_atlas = prev_highlight_atlas_coords.get(tile, null)
	var is_reachable = (atlas == Constants.HIGHLIGHT_REACHABLE or 
		(atlas == Constants.HIGHLIGHT_MOUSE_OVER and prev_atlas == Constants.HIGHLIGHT_REACHABLE))
	if is_reachable:
		game_manager.request_move(game_manager.current_character, tile)

func _get_tile_at_mouse() -> Vector2i:
	return highlight_layer.local_to_map(highlight_layer.to_local(highlight_layer.get_global_mouse_position()))
