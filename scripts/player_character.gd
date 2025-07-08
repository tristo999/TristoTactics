extends Node2D

@export var speed = 100;
@export var distance = 5;

var current_tile: Vector2i
var base_layer: TileMapLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Wait for GameManager to assign base_layer
	pass

func set_base_layer(layer: TileMapLayer):
	base_layer = layer

func update_current_tile():
	if base_layer:
		current_tile = base_layer.local_to_map(global_position)
		print("Character starting tile:", current_tile)
	else:
		print("BaseLayer not set for character!")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func show_movement_range(tilemap):
	if tilemap and tilemap.has_method("highlight_reachable_tiles"):
		tilemap.highlight_reachable_tiles(current_tile, speed)
	else:
		print("Tilemap or highlight method not found!")

func clear_movement_range(tilemap):
	if tilemap and tilemap.has_method("clear_highlights"):
		tilemap.clear_highlights()
	else:
		print("Tilemap or clear_highlights method not found!")

func start_turn(tilemap):
	show_movement_range(tilemap)
	# Add any other per-turn start logic here

func end_turn(tilemap):
	clear_movement_range(tilemap)
	# Add any other per-turn end logic here
