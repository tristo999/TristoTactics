# CharacterBase - Base class for all characters
extends Node2D
class_name CharacterBase

signal movement_finished
signal died

@export var character_data: CharacterData
@export var team: String = "player_team"
@export_group("Override Stats")
@export var override_move_speed: float = -1
@export var override_move_range: int = -1
@export var override_initiative: int = -1
@export var override_attack_range_min: int = -1
@export var override_attack_range_max: int = -1

var current_hp: int
var current_tile: Vector2i
var base_layer: TileMapLayer
var movement_left: int = 0
var move_path: Array = []
var move_target: Vector2 = Vector2.ZERO
var moving: bool = false

var move_speed: float:
	get: return override_move_speed if override_move_speed > 0 else (character_data.move_speed if character_data else 100.0)

var move_range: int:
	get: return override_move_range if override_move_range > 0 else (character_data.move_range if character_data else 5)

var initiative: int:
	get: return override_initiative if override_initiative > 0 else (character_data.get_initiative() if character_data else 10)

var attack_range_min: int:
	get: return override_attack_range_min if override_attack_range_min > 0 else (character_data.attack_range_min if character_data else 1)

var attack_range_max: int:
	get: return override_attack_range_max if override_attack_range_max > 0 else (character_data.attack_range_max if character_data else 1)

var max_hp: int:
	get: return character_data.max_hp if character_data else 100

var is_alive: bool:
	get: return current_hp > 0

func _ready() -> void:
	current_hp = max_hp
	call_deferred("_add_to_groups")

func _add_to_groups() -> void:
	add_to_group(Constants.GROUP_ALL_CHARACTERS)
	if team == Constants.TEAM_PLAYER:
		add_to_group(Constants.GROUP_PLAYER_CHARACTERS)
	elif team == Constants.TEAM_ENEMY:
		add_to_group(Constants.GROUP_ENEMY_CHARACTERS)

func set_base_layer(layer: TileMapLayer) -> void:
	base_layer = layer

func _process(delta: float) -> void:
	if not moving:
		return
	var direction = move_target - global_position
	if direction.length() <= move_speed * delta:
		global_position = move_target
		_advance_path()
	else:
		global_position += direction.normalized() * move_speed * delta

func move_to_tile(grid_pos: Vector2i) -> void:
	var tilemap = get_tree().get_first_node_in_group("tilemap")
	var path = tilemap.get_astar_path(current_tile, grid_pos) if tilemap else [current_tile, grid_pos]
	if path.size() < 2:
		return
	move_path = path.slice(1)
	movement_left -= move_path.size()
	moving = true
	_advance_path()

func _advance_path() -> void:
	if move_path.size() > 0:
		var next_tile = move_path.pop_front()
		move_target = base_layer.map_to_local(next_tile) + Constants.TILE_CENTER_OFFSET
	else:
		moving = false
		var old_tile = current_tile
		current_tile = base_layer.local_to_map(global_position)
		movement_finished.emit()
		EventBus.character_movement_finished.emit(self)
		EventBus.character_moved.emit(self, old_tile, current_tile)

# Override in subclasses for AI, etc.
func on_turn_started() -> void:
	pass

func on_turn_ended() -> void:
	pass

func take_damage(amount: int, source: Node2D = null) -> void:
	current_hp = max(0, current_hp - amount)
	EventBus.character_damaged.emit(self, amount, source)
	if current_hp <= 0:
		died.emit()
		EventBus.character_died.emit(self)

func heal(amount: int, _source: Node2D = null) -> void:
	current_hp = min(current_hp + amount, max_hp)
	EventBus.character_healed.emit(self, amount, _source)