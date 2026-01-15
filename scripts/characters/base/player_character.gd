extends Node2D

@export var move_speed = 3000 # Movement speed (pixels/sec)
@export var distance = 5
@export var initiative: int = 10 # Used for turn order

var current_tile: Vector2i
var base_layer: TileMapLayer
var movement_left: int = 0
var tilemap_ref = null

# Movement path and state
var move_path: Array = []
var move_target: Vector2 = Vector2()
var has_move_target: bool = false
var moving: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var sprite = $AnimatedSprite2D
	sprite.position = Vector2.ZERO
	# Instantly center on tile at start (independent of movement logic)
	if base_layer:
		current_tile = base_layer.local_to_map(global_position)
		global_position = base_layer.map_to_local(current_tile) + Vector2(3, -2)

func set_base_layer(layer: TileMapLayer):
	base_layer = layer

func update_current_tile():
	if base_layer:
		current_tile = base_layer.local_to_map(global_position)
		move_to_tile(current_tile)
		print("Character starting tile:", current_tile)
	else:
		print("BaseLayer not set for character!")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if moving and has_move_target:
		var direction = (move_target - global_position)
		var distance_to_target = direction.length()
		if distance_to_target <= move_speed * delta:
			global_position = move_target
			set_next_move_target()
		else:
			global_position += direction.normalized() * move_speed * delta

func show_movement_range(tilemap):
	if tilemap and tilemap.has_method("highlight_reachable_tiles"):
		tilemap.highlight_reachable_tiles(current_tile, movement_left)
	else:
		print("Tilemap or highlight method not found!")

func clear_movement_range(tilemap):
	if tilemap and tilemap.has_method("clear_highlights"):
		tilemap.clear_highlights()
	else:
		print("Tilemap or clear_highlights method not found!")

func start_turn(tilemap):
	tilemap_ref = tilemap
	movement_left = distance
	show_movement_range(tilemap)
	# Add any other per-turn start logic here

func end_turn(tilemap):
	clear_movement_range(tilemap)
	# Add any other per-turn end logic here

func move_to_tile(grid_pos: Vector2i):
	if not base_layer or not tilemap_ref:
		print("BaseLayer or tilemap_ref not set for character!")
		return

	# Use tilemap's get_astar_path for true tile-to-tile pathfinding
	var path = []
	if tilemap_ref.has_method("get_astar_path"):
		path = tilemap_ref.get_astar_path(current_tile, grid_pos)
	else:
		# Fallback: just go directly
		path = [current_tile, grid_pos]


	if path.size() < 2:
		print("No path found or already at destination.")
		return

	# Remove highlight when starting to move
	clear_movement_range(tilemap_ref)

	move_path = path.duplicate()
	move_path.pop_front() # Remove current tile
	moving = true
	set_next_move_target()

	# Track how much movement is left
	movement_left -= (path.size() - 1)

# Set the next tile in the path as the move target
func set_next_move_target():
	if move_path.size() > 0:
		var next_tile = move_path.pop_front()
		move_target = base_layer.map_to_local(next_tile) + Vector2(3, -2)
		has_move_target = true
		# Only update current_tile when actually arriving at the tile
	else:
		has_move_target = false
		moving = false
		current_tile = base_layer.local_to_map(global_position)
		print("Arrived at destination tile:", current_tile)
		# If movement left, show new range and allow more moves
		if movement_left > 0 and tilemap_ref:
			show_movement_range(tilemap_ref)

func set_tilemap_ref(tilemap):
	tilemap_ref = tilemap
