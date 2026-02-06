# CharacterBase - Base class for all characters
extends Node2D
class_name CharacterBase

signal movement_finished
signal died

@export var character_data: CharacterData  ## Optional: for SFX overrides and future features

# Team is set automatically by PlayerCharacter/EnemyCharacter in _ready()
var team: String = ""

# --- Stats (edit these in the Inspector!) ---
@export_group("Stats")
@export var max_hp: int = 25
@export var attack_power: int = 10
@export var defense: int = 5
@export var initiative: int = 10
@export var crit_chance: float = 0.05

@export_group("Movement")
@export var move_speed: float = 100.0
@export var move_range: int = 5

@export_group("Attack Range")
@export var attack_range_min: int = 1
@export var attack_range_max: int = 1

# --- Runtime state (don't touch) ---
var current_hp: int
var current_tile: Vector2i
var base_layer: TileMapLayer
var movement_left: int = 0
var has_attacked: bool = false
var move_path: Array = []
var move_target: Vector2 = Vector2.ZERO
var moving: bool = false

var is_alive: bool:
	get: return current_hp > 0

var health_bar: HealthBar

func _ready() -> void:
	current_hp = max_hp
	_add_to_groups()
	_create_health_bar()

func _create_health_bar() -> void:
	health_bar = HealthBar.new()
	add_child(health_bar)  # triggers _ready() which creates the fill style
	health_bar.setup(max_hp, current_hp, team)

func _update_health_bar() -> void:
	if health_bar:
		health_bar.update_hp(current_hp, max_hp, team)

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
	EventBus.character_movement_started.emit(self)
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
	_update_health_bar()
	EventBus.character_damaged.emit(self, amount, source)
	if current_hp <= 0:
		_die()

func _die() -> void:
	died.emit()
	EventBus.character_died.emit(self)
	# Remove from all groups immediately so we're not considered in targeting
	remove_from_group(Constants.GROUP_ALL_CHARACTERS)
	remove_from_group(Constants.GROUP_PLAYER_CHARACTERS)
	remove_from_group(Constants.GROUP_ENEMY_CHARACTERS)
	# Play death animation (fade out)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func heal(amount: int, _source: Node2D = null) -> void:
	current_hp = min(current_hp + amount, max_hp)
	_update_health_bar()
	EventBus.character_healed.emit(self, amount, _source)

func attack_target(target: CharacterBase) -> Dictionary:
	if has_attacked:
		return {"success": false, "reason": "already_attacked"}
	
	var dist = _tile_distance(current_tile, target.current_tile)
	if dist < attack_range_min or dist > attack_range_max:
		return {"success": false, "reason": "out_of_range"}
	
	# Calculate damage
	var is_crit = randf() < crit_chance
	var base_damage = max(1, attack_power - target.defense)
	var final_damage = base_damage * 2 if is_crit else base_damage
	
	has_attacked = true
	target.take_damage(final_damage, self)
	EventBus.character_attacked.emit(self, target, final_damage, is_crit)
	EventBus.show_damage_popup.emit(target, final_damage, is_crit)
	
	return {"success": true, "damage": final_damage, "is_crit": is_crit}

func can_attack_target(target: CharacterBase) -> bool:
	if has_attacked or target.team == team or not target.is_alive:
		return false
	var dist = _tile_distance(current_tile, target.current_tile)
	return dist >= attack_range_min and dist <= attack_range_max

func get_targets_in_range() -> Array:
	var targets: Array = []
	var enemy_group = Constants.GROUP_PLAYER_CHARACTERS if team == Constants.TEAM_ENEMY else Constants.GROUP_ENEMY_CHARACTERS
	for enemy in get_tree().get_nodes_in_group(enemy_group):
		if can_attack_target(enemy):
			targets.append(enemy)
	return targets

## Returns the SFX path for the given action, checking character-specific
## overrides first, then falling back to the global default key.
func get_sfx(action: String) -> String:
	if character_data and character_data.sfx and character_data.sfx.has_method("get_sfx"):
		var custom: String = character_data.sfx.get_sfx(action)
		if custom != "":
			return custom
	return ""  # Empty means "use global default"

func _tile_distance(from: Vector2i, to: Vector2i) -> int:
	return abs(from.x - to.x) + abs(from.y - to.y)