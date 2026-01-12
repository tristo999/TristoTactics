extends Node2D

@onready var base_layer: TileMapLayer = $BaseGrid
@onready var wall_tilemap: TileMapLayer = $Walls
@onready var highlight_layer: TileMapLayer = $HighlightLayer
var astar_grid: AStarGrid2D
var last_hovered_tile: Vector2i = Vector2i(-9999, -9999)
# Stores previous atlas coords for each tile when mouse hovers
var prev_highlight_atlas_coords := {}

func _process(delta):
	# Mouse-over tile highlight
	var mouse_pos = highlight_layer.get_global_mouse_position()
	var local_mouse = highlight_layer.to_local(mouse_pos)
	var tile = highlight_layer.local_to_map(local_mouse)
	if tile != last_hovered_tile:
		# Restore previous highlight for the last hovered tile
		if prev_highlight_atlas_coords.has(last_hovered_tile):
			var prev_atlas = prev_highlight_atlas_coords[last_hovered_tile]
			# Only restore if the highlight is still valid (i.e., matches current game state)
			var current_atlas = highlight_layer.get_cell_atlas_coords(last_hovered_tile)
			# If the highlight was cleared (e.g., by turn switch), don't restore
			if prev_atlas == null:
				highlight_layer.erase_cell(last_hovered_tile)
			elif current_atlas == Vector2i(8, 4) or current_atlas == null:
				# Only restore if the cell is currently mouse-over or empty
				highlight_layer.set_cell(last_hovered_tile, 2, prev_atlas)
			# Otherwise, do not restore (the highlight was changed by game logic)
			prev_highlight_atlas_coords.erase(last_hovered_tile)
		# Store the current highlight for the new tile
		var current_atlas = highlight_layer.get_cell_atlas_coords(tile)
		if current_atlas == Vector2i(8, 4):
			# Already mouse-over highlight, do nothing
			pass
		else:
			# Store previous highlight (or null if none)
			prev_highlight_atlas_coords[tile] = current_atlas if current_atlas != null else null
			# Set mouse-over highlight to (8, 4)
			highlight_layer.set_cell(tile, 2, Vector2i(8, 4))
		last_hovered_tile = tile


func _ready():
	# Initialize the AStarGrid2D
	setup_astar_grid()
	# Add walkable cells based on the TileMapLayer
	add_walkable_cells_from_tilemap()

func setup_astar_grid():
	astar_grid = AStarGrid2D.new()
	# Set the size of the grid to match the TileMapLayer
	astar_grid.region = base_layer.get_used_rect()
	# Set the cell size to match the tile size
	astar_grid.cell_size = base_layer.tile_set.tile_size
	astar_grid.jumping_enabled = false
	# Update the grid
	astar_grid.update()

func add_walkable_cells_from_tilemap():
	# Get the used cells from the TileMapLayer
	var used_cells = base_layer.get_used_cells()
	for cell in used_cells:
		# Mark the cell as walkable in the AStarGrid2D
		astar_grid.set_point_solid(cell, false) # false means walkable
	for cell in wall_tilemap.get_used_cells():
		# Mark walls as not walkable
		astar_grid.set_point_solid(cell, true)

func get_astar_path(start: Vector2i, end: Vector2i) -> Array:
	# Returns a list of points from start to end using the AStarGrid2D
	if astar_grid == null:
		push_error("AStar grid not initialized!")
		return []
	if not astar_grid.is_in_boundsv(start) or not astar_grid.is_in_boundsv(end):
		push_error("Start or end point not in grid!")
		return []
	return astar_grid.get_id_path(start, end)

# Highlights all tiles reachable from a start position within a given range (speed)
func highlight_reachable_tiles(start: Vector2i, max_range: int):
	print("[Highlight] Clearing previous highlights...")
	var used_cells = highlight_layer.get_used_cells()
	for cell in used_cells:
		highlight_layer.erase_cell(cell)
	print("[Highlight] Highlighting reachable tiles from:", start, "with range:", max_range)
	# BFS for range-limited, obstacle-aware highlighting
	var visited = {}
	var queue = []
	queue.push_back({"pos": start, "dist": 0})
	visited[start] = true
	var highlight_count = 0
	# Gather all character positions (player and enemy)
	var occupied_tiles := {}
	var scene = get_tree().get_current_scene()
	if scene:
		var gm = scene.find_child("GameManager", true, false)
		if gm:
			for c in gm.player_team_characters:
				occupied_tiles[c.current_tile] = true
			for c in gm.enemy_team_characters:
				occupied_tiles[c.current_tile] = true

	while queue.size() > 0:
		var current = queue.pop_front()
		var pos = current["pos"]
		var dist = current["dist"]
		if dist > max_range:
			continue
		# Only highlight if not blocked, not the starting tile, and not occupied
		if not astar_grid.is_point_solid(pos) and pos != start and not occupied_tiles.has(pos):
			highlight_layer.set_cell(pos, 2, Vector2i(27, 3))
			highlight_count += 1
		# Explore neighbors
		for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var neighbor = pos + dir
			if not astar_grid.is_in_boundsv(neighbor):
				continue
			if visited.has(neighbor):
				continue
			if astar_grid.is_point_solid(neighbor):
				continue
			visited[neighbor] = true
			queue.push_back({"pos": neighbor, "dist": dist + 1})
	print("[Highlight] Total highlighted:", highlight_count)

# Optionally, a function to clear highlights
func clear_highlights():
	print("[Highlight] Clearing all highlights...")
	var used_cells = highlight_layer.get_used_cells()
	for cell in used_cells:
		highlight_layer.erase_cell(cell)
var game_manager: Node = null

func _unhandled_input(event):
	if game_manager == null:
		# Try to find the game manager node in the current scene
		var scene = get_tree().get_current_scene()
		if scene:
			game_manager = scene.find_child("GameManager", true, false)
		if game_manager == null:
			return
	# Only allow input if it's the player's turn
	if not game_manager.enemy_team_characters.has(game_manager.current_character):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = highlight_layer.get_global_mouse_position()
			var local_mouse = highlight_layer.to_local(mouse_pos)
			var tile = highlight_layer.local_to_map(local_mouse)
			var atlas = highlight_layer.get_cell_atlas_coords(tile)
			# Allow movement if the tile is reachable (27, 3) or mouse-over (8, 4) but was previously reachable
			var prev_atlas = prev_highlight_atlas_coords.get(tile, null)
			if atlas == Vector2i(27, 3) or (atlas == Vector2i(8, 4) and prev_atlas == Vector2i(27, 3)):
				game_manager.current_character.move_to_tile(tile)
				# End the turn after moving (deferred, so move is visible)
				game_manager.call_deferred("_on_turn_timer_timeout")
