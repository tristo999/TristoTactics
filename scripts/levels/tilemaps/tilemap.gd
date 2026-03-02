# Tilemap - Tile rendering, pathfinding, and tile interaction.
extends Node2D

const HighlightRendererScript = preload("res://scripts/levels/tilemaps/highlight_renderer.gd")

@onready var base_layer: TileMapLayer = $BaseGrid
@onready var wall_tilemap: TileMapLayer = $Walls
@onready var objects_layer: TileMapLayer = get_node_or_null("Objects")
@onready var water_layer: TileMapLayer = get_node_or_null("Water")

var highlight_renderer: Node2D
var astar_grid: AStarGrid2D
var last_hovered_tile: Vector2i = Constants.INVALID_TILE
var game_manager: Node = null
var cached_occupied_tiles: Dictionary = {}
var cached_reachable_tiles: Array = []

func _ready() -> void:
	add_to_group("tilemap")
	setup_astar_grid()
	add_walkable_cells_from_tilemap()
	_create_highlight_renderer()
	# Deferred so GameManager (a sibling node) has finished _ready() first
	call_deferred("_cache_game_manager")
	EventBus.character_moved.connect(func(_c, _f, _t): _refresh_occupied_tiles())
	EventBus.turn_started.connect(func(_c): _refresh_occupied_tiles())

func _create_highlight_renderer() -> void:
	highlight_renderer = HighlightRendererScript.new()
	highlight_renderer.z_index = 1
	add_child(highlight_renderer)
	highlight_renderer.setup(base_layer)

func _cache_game_manager() -> void:
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		var scene = get_tree().get_current_scene()
		if scene:
			game_manager = scene.find_child("GameManager", true, false)

func _refresh_occupied_tiles() -> void:
	cached_occupied_tiles.clear()
	if not game_manager:
		return
	for c in game_manager.turn_order:
		cached_occupied_tiles[c.current_tile] = c

# --- Mouse Hover ---

func _process(_delta: float) -> void:
	_handle_mouse_hover()

func _handle_mouse_hover() -> void:
	var mouse_pos = base_layer.get_global_mouse_position()
	var local_mouse = base_layer.to_local(mouse_pos)
	var tile = base_layer.local_to_map(local_mouse)

	if tile == last_hovered_tile:
		return

	last_hovered_tile = tile

	if _is_tile_walkable(tile):
		highlight_renderer.set_hover(tile)
	else:
		highlight_renderer.clear_hover()

	EventBus.tile_hovered.emit(tile)

func _is_tile_walkable(tile: Vector2i) -> bool:
	# Check if tile is in the base layer (valid ground)
	var base_atlas = base_layer.get_cell_atlas_coords(tile)
	if base_atlas == Vector2i(-1, -1):
		return false
	# Check if tile is blocked by pathfinding grid (handles large tiles like 3x3 trees)
	if astar_grid.is_in_boundsv(tile) and astar_grid.is_point_solid(tile):
		return false
	return true

# --- A* Pathfinding ---

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
	
	# Mark wall tiles as solid, including large tiles (e.g., 3x3 trees)
	_mark_layer_cells_solid(wall_tilemap)
	
	# Objects layer (trees, benches, etc.) are also impassable
	if objects_layer:
		_mark_layer_cells_solid(objects_layer)
	
	# Water layer (water, coast, etc.) is impassable
	if water_layer:
		_mark_layer_cells_solid(water_layer)

# Marks all cells covered by tiles in a layer as solid (handles large multi-cell tiles)
func _mark_layer_cells_solid(layer: TileMapLayer) -> void:
	for cell in layer.get_used_cells():
		var tile_data = layer.get_cell_tile_data(cell)
		if tile_data == null:
			continue
		
		# Get the tile size from the texture region
		var source_id = layer.get_cell_source_id(cell)
		var atlas_coords = layer.get_cell_atlas_coords(cell)
		var tile_set_source = layer.tile_set.get_source(source_id)
		
		if tile_set_source is TileSetAtlasSource:
			var atlas_source = tile_set_source as TileSetAtlasSource
			var tile_size_in_atlas = atlas_source.get_tile_size_in_atlas(atlas_coords)
			
			# For large tiles, the origin is at the center
			# Calculate offset from center to cover all cells
			var offset_x = tile_size_in_atlas.x / 2
			var offset_y = tile_size_in_atlas.y / 2
			
			for x in range(tile_size_in_atlas.x):
				for y in range(tile_size_in_atlas.y):
					var covered_cell = cell + Vector2i(x - offset_x, y - offset_y)
					if astar_grid.is_in_boundsv(covered_cell):
						astar_grid.set_point_solid(covered_cell, true)
		else:
			# Fallback for non-atlas sources - just mark the origin cell
			if astar_grid.is_in_boundsv(cell):
				astar_grid.set_point_solid(cell, true)

func get_astar_path(start: Vector2i, end: Vector2i) -> Array:
	if astar_grid == null:
		push_error("AStar grid not initialized!")
		return []
	
	if not astar_grid.is_in_boundsv(start) or not astar_grid.is_in_boundsv(end):
		push_error("Start or end point not in grid!")
		return []
	
	# Temporarily unblock the start position if it's the character's own tile
	var start_was_solid = astar_grid.is_point_solid(start)
	if start_was_solid:
		astar_grid.set_point_solid(start, false)
	
	var temporarily_blocked: Array[Vector2i] = []
	
	for tile in cached_occupied_tiles.keys():
		if tile != start and tile != end and astar_grid.is_in_boundsv(tile):
			if not astar_grid.is_point_solid(tile):
				astar_grid.set_point_solid(tile, true)
				temporarily_blocked.append(tile)
	
	var path = astar_grid.get_id_path(start, end)
	
	for tile in temporarily_blocked:
		astar_grid.set_point_solid(tile, false)
	
	# Restore start position solid state
	if start_was_solid:
		astar_grid.set_point_solid(start, true)
	
	return path

# --- Tile Highlighting ---

func highlight_reachable_tiles(start: Vector2i, max_range: int, character: CharacterBase = null) -> void:
	clear_highlights()
	_refresh_occupied_tiles()

	# Calculate and cache reachable tiles
	if max_range > 0:
		cached_reachable_tiles = _calculate_reachable_tiles(start, max_range)
	else:
		cached_reachable_tiles = []

	# Current character indicator (green hollow square)
	highlight_renderer.set_current_character(start)

	# Movement range (dark filled squares)
	highlight_renderer.set_movement_tiles(cached_reachable_tiles)

	# Attack range (red hollow squares overlaid on movement)
	if character and not character.has_used_action:
		var atk_tiles = _calculate_attack_range_tiles(start, character.attack_range_min, character.attack_range_max)
		highlight_renderer.set_attack_tiles(atk_tiles)

func _calculate_reachable_tiles(start: Vector2i, max_range: int) -> Array:
	var visited := {start: 0} # tile -> cost to reach
	var reachable: Array = []
	var queue: Array = [[start, 0]]
	while queue.size() > 0:
		var current = queue.pop_front()
		var pos: Vector2i = current[0]
		var cost_so_far: int = current[1]
		if pos != start and not astar_grid.is_point_solid(pos) and not cached_occupied_tiles.has(pos):
			reachable.append(pos)
		for dir in Constants.CARDINAL_DIRECTIONS:
			var neighbor = pos + dir
			if not astar_grid.is_in_boundsv(neighbor):
				continue
			if astar_grid.is_point_solid(neighbor) or cached_occupied_tiles.has(neighbor):
				continue
			var step_cost: int = TerrainRegistry.get_move_cost(neighbor, self )
			var new_cost: int = cost_so_far + step_cost
			if new_cost > max_range:
				continue
			if not visited.has(neighbor) or new_cost < visited[neighbor]:
				visited[neighbor] = new_cost
				queue.push_back([neighbor, new_cost])
	return reachable

func clear_highlights() -> void:
	highlight_renderer.clear_range_highlights()
	last_hovered_tile = Constants.INVALID_TILE
	cached_reachable_tiles = []

func highlight_attack_range(start: Vector2i, min_range: int, max_range: int) -> void:
	clear_highlights()
	highlight_renderer.set_current_character(start)
	var tiles = _calculate_attack_range_tiles(start, min_range, max_range)
	highlight_renderer.set_attack_tiles(tiles)

func _calculate_attack_range_tiles(start: Vector2i, min_range: int, max_range: int) -> Array:
	var tiles: Array = []
	for x in range(-max_range, max_range + 1):
		for y in range(-max_range, max_range + 1):
			var dist = abs(x) + abs(y)
			if dist >= min_range and dist <= max_range:
				var tile = start + Vector2i(x, y)
				if astar_grid.is_in_boundsv(tile):
					tiles.append(tile)
	return tiles

## Returns all tiles reachable from `start` within `max_range` steps,
## respecting solid terrain and occupied tiles.
func get_reachable_tiles(start: Vector2i, max_range: int) -> Array:
	_refresh_occupied_tiles()
	return _calculate_reachable_tiles(start, max_range)

func get_character_at_tile(tile: Vector2i) -> Node2D:
	_refresh_occupied_tiles()
	return cached_occupied_tiles.get(tile, null)
