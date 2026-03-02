extends PanelContainer

@onready var tile_name_label: Label = $MarginContainer/VBox/TileName
@onready var defense_label: Label = $MarginContainer/VBox/StatsContainer/DefenseLabel
@onready var move_cost_label: Label = $MarginContainer/VBox/StatsContainer/MoveCostLabel
@onready var terrain_label: Label = $MarginContainer/VBox/StatsContainer/TerrainLabel

var tilemap: Node = null

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
	return TerrainRegistry.get_terrain_at(tile_pos, tilemap)
