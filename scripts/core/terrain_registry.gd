# TerrainRegistry - Shared terrain data for the entire game
# Single source of truth for terrain types, defense bonuses, and move costs.
# Both gameplay (BFS, combat) and UI (TileInfoPanel) read from here.
extends Node

# =============================================================================
# TERRAIN DEFINITIONS
# =============================================================================

## Each terrain type maps to a dictionary with:
##   name      — display name for UI
##   defense   — defense modifier applied during combat
##   move_cost — BFS movement cost per tile (999 = impassable)
##   terrain   — terrain category label for UI
const TERRAIN_TYPES := {
	"grass": {"name": "Grass", "defense": 0, "move_cost": 1, "terrain": "Plains"},
	"dirt": {"name": "Dirt Path", "defense": 0, "move_cost": 1, "terrain": "Road"},
	"stone": {"name": "Stone Floor", "defense": 0, "move_cost": 1, "terrain": "Road"},
	"road": {"name": "Road", "defense": - 1, "move_cost": 1, "terrain": "Road"},
	"forest": {"name": "Forest", "defense": 2, "move_cost": 2, "terrain": "Forest"},
	"water": {"name": "Water", "defense": 0, "move_cost": 999, "terrain": "Impassable"},
	"wall": {"name": "Wall", "defense": 0, "move_cost": 999, "terrain": "Impassable"},
	"object": {"name": "Object", "defense": 0, "move_cost": 999, "terrain": "Impassable"},
	"bridge": {"name": "Bridge", "defense": 0, "move_cost": 1, "terrain": "Bridge"},
	"sand": {"name": "Sand", "defense": - 1, "move_cost": 2, "terrain": "Desert"},
	"mountain": {"name": "Mountain", "defense": 3, "move_cost": 3, "terrain": "Mountain"},
}

## Default terrain when nothing else matches
const DEFAULT_TERRAIN := "grass"

# =============================================================================
# LAYER-BASED LOOKUPS
# =============================================================================

## Returns the terrain data dictionary for a given tile position.
## Requires a tilemap node (the Node2D with BaseGrid, Walls, Objects, Water children).
func get_terrain_at(tile_pos: Vector2i, tilemap: Node2D) -> Dictionary:
	if not tilemap:
		return TERRAIN_TYPES[DEFAULT_TERRAIN]

	# Check walls first (impassable) — including large multi-cell tiles
	var wall_layer = tilemap.get_node_or_null("Walls")
	if wall_layer and _is_tile_covered_by_layer(wall_layer, tile_pos):
		return TERRAIN_TYPES["wall"]

	# Check objects layer (trees, benches, etc. — impassable)
	var objects_layer = tilemap.get_node_or_null("Objects")
	if objects_layer and _is_tile_covered_by_layer(objects_layer, tile_pos):
		return TERRAIN_TYPES["object"]

	# Check water layer (water, coast — impassable)
	var water_layer = tilemap.get_node_or_null("Water")
	if water_layer and water_layer.get_cell_atlas_coords(tile_pos) != Vector2i(-1, -1):
		return TERRAIN_TYPES["water"]

	# Check base layer via atlas coordinate classification
	var base_layer = tilemap.get_node_or_null("BaseGrid")
	if not base_layer:
		return TERRAIN_TYPES[DEFAULT_TERRAIN]

	var atlas_coords = base_layer.get_cell_atlas_coords(tile_pos)
	if atlas_coords == Vector2i(-1, -1):
		return {}

	return _classify_tile(atlas_coords)

## Returns just the defense bonus for a tile.
func get_defense_bonus(tile_pos: Vector2i, tilemap: Node2D) -> int:
	var data = get_terrain_at(tile_pos, tilemap)
	return data.get("defense", 0)

## Returns just the move cost for a tile.
func get_move_cost(tile_pos: Vector2i, tilemap: Node2D) -> int:
	var data = get_terrain_at(tile_pos, tilemap)
	return data.get("move_cost", 1)

# =============================================================================
# ATLAS CLASSIFICATION (Solaria Demo tileset)
# =============================================================================

## Classify a base-layer tile by its atlas coordinates.
## TODO: Replace with TileSet custom data layers for a truly data-driven approach.
func _classify_tile(atlas: Vector2i) -> Dictionary:
	var x = atlas.x
	var y = atlas.y

	# Forest/tree tiles (decorative elements that provide cover)
	if (y == 4 and x >= 11 and x <= 12) or (y == 5 and x >= 6 and x <= 9):
		return TERRAIN_TYPES["forest"]

	# Road tiles
	if y >= 3 and y <= 5 and x >= 3 and x <= 10:
		return TERRAIN_TYPES["road"]

	# Stone/brick paths
	if y >= 6 and y <= 8:
		return TERRAIN_TYPES["stone"]

	# Sand tiles
	if y >= 9 and y <= 11:
		return TERRAIN_TYPES["sand"]

	# Default: grass/plains
	return TERRAIN_TYPES[DEFAULT_TERRAIN]

# =============================================================================
# MULTI-CELL TILE HELPER
# =============================================================================

## Check if a tile position is covered by any tile in a layer (handles large
## multi-cell tiles like 3×3 trees whose origin sits at their center).
func _is_tile_covered_by_layer(layer: TileMapLayer, tile_pos: Vector2i) -> bool:
	# Direct hit
	if layer.get_cell_atlas_coords(tile_pos) != Vector2i(-1, -1):
		return true

	# Check surrounding cells for large tiles that cover this position
	for offset_x in range(-2, 3):
		for offset_y in range(-2, 3):
			var check_pos = tile_pos + Vector2i(offset_x, offset_y)
			var tile_data = layer.get_cell_tile_data(check_pos)
			if tile_data == null:
				continue

			var source_id = layer.get_cell_source_id(check_pos)
			var atlas_coords = layer.get_cell_atlas_coords(check_pos)
			var tile_set_source = layer.tile_set.get_source(source_id)

			if tile_set_source is TileSetAtlasSource:
				var atlas_source = tile_set_source as TileSetAtlasSource
				var tile_size = atlas_source.get_tile_size_in_atlas(atlas_coords)

				var half_x = tile_size.x / 2
				var half_y = tile_size.y / 2
				var min_x = check_pos.x - half_x
				var max_x = check_pos.x + (tile_size.x - 1) - half_x
				var min_y = check_pos.y - half_y
				var max_y = check_pos.y + (tile_size.y - 1) - half_y

				if tile_pos.x >= min_x and tile_pos.x <= max_x and tile_pos.y >= min_y and tile_pos.y <= max_y:
					return true

	return false
