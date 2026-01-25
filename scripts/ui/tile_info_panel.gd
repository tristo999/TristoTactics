extends PanelContainer

@onready var tile_name_label: Label = $MarginContainer/VBox/TileName
@onready var defense_label: Label = $MarginContainer/VBox/StatsContainer/DefenseLabel
@onready var move_cost_label: Label = $MarginContainer/VBox/StatsContainer/MoveCostLabel
@onready var terrain_label: Label = $MarginContainer/VBox/StatsContainer/TerrainLabel

var tilemap: Node = null

# Tile definitions based on Solaria Demo tileset (Source 2)
# Format: "terrain_type": { "name", "defense", "move_cost", "terrain" }
const TERRAIN_TYPES := {
	"grass": {"name": "Grass", "defense": 0, "move_cost": 1, "terrain": "Plains"},
	"dirt": {"name": "Dirt Path", "defense": 0, "move_cost": 1, "terrain": "Road"},
	"stone": {"name": "Stone Floor", "defense": 0, "move_cost": 1, "terrain": "Road"},
	"road": {"name": "Road", "defense": -1, "move_cost": 1, "terrain": "Road"},
	"forest": {"name": "Forest", "defense": 2, "move_cost": 2, "terrain": "Forest"},
	"water": {"name": "Water", "defense": 0, "move_cost": 999, "terrain": "Impassable"},
	"wall": {"name": "Wall", "defense": 0, "move_cost": 999, "terrain": "Impassable"},
	"object": {"name": "Object", "defense": 0, "move_cost": 999, "terrain": "Impassable"},
	"bridge": {"name": "Bridge", "defense": 0, "move_cost": 1, "terrain": "Bridge"},
	"sand": {"name": "Sand", "defense": - 1, "move_cost": 2, "terrain": "Desert"},
	"mountain": {"name": "Mountain", "defense": 3, "move_cost": 3, "terrain": "Mountain"},
}

func _ready():
	EventBus.tile_hovered.connect(_on_tile_hovered)
	hide()
	call_deferred("_find_tilemap")

func _find_tilemap():
	var nodes = get_tree().get_nodes_in_group("tilemap")
	if nodes.size() > 0:
		tilemap = nodes[0]

func _on_tile_hovered(tile_pos: Vector2i):
	if not tilemap:
		_find_tilemap()
	
	var tile_data = _get_tile_data(tile_pos)
	
	if tile_data.is_empty():
		hide()
		return
	
	tile_name_label.text = tile_data.get("name", "Unknown")
	
	var defense = tile_data.get("defense", 0)
	if defense >= 0:
		defense_label.text = "Defense: +%d" % defense
	else:
		defense_label.text = "Defense: %d" % defense
	
	var move_cost = tile_data.get("move_cost", 1)
	if move_cost >= 999:
		move_cost_label.text = "Move Cost: —"
	else:
		move_cost_label.text = "Move Cost: %d" % move_cost
	
	terrain_label.text = "Terrain: %s" % tile_data.get("terrain", "Normal")
	
	show()

func _get_tile_data(tile_pos: Vector2i) -> Dictionary:
	if not tilemap:
		return {}
	
	# Check walls first (impassable) - including large multi-cell tiles
	var wall_layer = tilemap.get_node_or_null("Walls")
	if wall_layer and _is_tile_covered_by_layer(wall_layer, tile_pos):
		return TERRAIN_TYPES["wall"]
	
	# Check objects layer (trees, benches, etc. - impassable)
	var objects_layer = tilemap.get_node_or_null("Objects")
	if objects_layer and _is_tile_covered_by_layer(objects_layer, tile_pos):
		return TERRAIN_TYPES["object"]
	
	# Check base layer
	var base_layer = tilemap.get_node_or_null("BaseGrid")
	if not base_layer:
		return {}
	
	var atlas_coords = base_layer.get_cell_atlas_coords(tile_pos)
	if atlas_coords == Vector2i(-1, -1):
		return {}
	
	# Determine terrain type from atlas coordinates
	# Based on Solaria Demo Tiles layout
	return _classify_tile(atlas_coords)

# Check if a tile position is covered by any tile in a layer (handles large multi-cell tiles)
func _is_tile_covered_by_layer(layer: TileMapLayer, tile_pos: Vector2i) -> bool:
	# First check if there's a tile directly at this position
	if layer.get_cell_atlas_coords(tile_pos) != Vector2i(-1, -1):
		return true
	
	# Check surrounding cells for large tiles that might cover this position
	# Large tiles have origin at center, so check in all directions
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
				
				# For large tiles, origin is at center
				var half_x = tile_size.x / 2
				var half_y = tile_size.y / 2
				var min_x = check_pos.x - half_x
				var max_x = check_pos.x + (tile_size.x - 1) - half_x
				var min_y = check_pos.y - half_y
				var max_y = check_pos.y + (tile_size.y - 1) - half_y
				
				if tile_pos.x >= min_x and tile_pos.x <= max_x and tile_pos.y >= min_y and tile_pos.y <= max_y:
					return true
	
	return false

func _classify_tile(atlas: Vector2i) -> Dictionary:
	var x = atlas.x
	var y = atlas.y
	
	# Solaria Demo Tiles classification (approximate based on common tileset layouts)
	# Row 0-2: Various ground tiles (grass, dirt variations)
	# Row 3-5: More terrain (paths, transitions)  
	# Row 6-8: Decorations, objects
	# Row 9+: Water, special tiles
	
	# Water tiles (typically in specific columns or rows)
	if y >= 6 and y <= 8 and x <= 2:
		return TERRAIN_TYPES["water"]
	
	# Forest/tree tiles (decorative elements that provide cover)
	if (y == 4 and x >= 11 and x <= 12) or (y == 5 and x >= 6 and x <= 9):
		return TERRAIN_TYPES["forest"]
	
	# Road tiles - typically paths/roads in rows 3-5
	# Adjust these coordinates based on your specific tileset
	if y >= 3 and y <= 5 and x >= 3 and x <= 10:
		return TERRAIN_TYPES["road"]
	
	# Stone/brick paths
	if y >= 6 and y <= 8:
		return TERRAIN_TYPES["stone"]
	
	# Sand tiles
	if y >= 9 and y <= 11:
		return TERRAIN_TYPES["sand"]
	
	# Default: grass/plains
	return TERRAIN_TYPES["grass"]
