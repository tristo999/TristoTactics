extends Node2D

@onready var base_layer: TileMapLayer = $BaseGrid
@onready var wall_tilemap: TileMapLayer = $Walls
@onready var highlight_layer: TileMapLayer = $HighlightLayer
var astar_grid : AStarGrid2D

func _ready():
	# Initialize the AStarGrid2D
	setup_astar_grid()
	
	# Add walkable cells based on the TileMapLayer
	add_walkable_cells_from_tilemap()
	
	#delete_cells_from_top_left_to_origin()

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
		astar_grid.set_point_solid(cell, false)  # false means walkable
	
	for cell in wall_tilemap.get_used_cells():
		# Mark walls as not walkable
		astar_grid.set_point_solid(cell, true)
	

#func delete_cells_from_top_left_to_origin():
	## Get the used rect of the TileMapLayer
	#var used_rect = base_layer.get_used_rect()
	#
	## Get the top-left corner of the TileMapLayer
	#var top_left = used_rect.position  # This is a Vector2
	## Iterate from the top-left corner to (0, 0)
	#var path = astar_grid.get_id_path(Vector2i(-3,-12), Vector2i(0,0))
	#
	#for tile in path:
			## Mark the cell as solid (non-walkable)
			#astar_grid.set_point_solid(tile, true)
			## Delete the tile at this cell
			#base_layer.erase_cell(tile)  # 0 is the layer index
			#

# Use a unique name to avoid overriding Node.get_path()
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

	while queue.size() > 0:
		var current = queue.pop_front()
		var pos = current["pos"]
		var dist = current["dist"]
		if dist > max_range:
			continue
		# Only highlight if not blocked
		if not astar_grid.is_point_solid(pos):
			highlight_layer.set_cell(pos, 2, Vector2i(18, 6))
			highlight_count += 1
		# Explore neighbors
		for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
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
