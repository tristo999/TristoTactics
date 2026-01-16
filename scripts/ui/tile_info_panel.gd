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
	"forest": {"name": "Forest", "defense": 2, "move_cost": 2, "terrain": "Forest"},
	"water": {"name": "Water", "defense": 0, "move_cost": 999, "terrain": "Impassable"},
	"wall": {"name": "Wall", "defense": 0, "move_cost": 999, "terrain": "Impassable"},
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
	
	# Check walls first (impassable)
	var wall_layer = tilemap.get_node_or_null("Walls")
	if wall_layer:
		var wall_atlas = wall_layer.get_cell_atlas_coords(tile_pos)
		if wall_atlas != Vector2i(-1, -1):
			return TERRAIN_TYPES["wall"]
	
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
	
	# Stone/brick paths
	if y >= 6 and y <= 8:
		return TERRAIN_TYPES["stone"]
	
	# Sand tiles
	if y >= 9 and y <= 11:
		return TERRAIN_TYPES["sand"]
	
	# Default: grass/plains
	return TERRAIN_TYPES["grass"]
