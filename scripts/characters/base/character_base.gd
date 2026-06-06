# CharacterBase - Base class for all characters.
extends Node2D
class_name CharacterBase

signal movement_finished

## The data resource that defines this character's stats, abilities, and visuals.
## Assign a .tres CharacterData in the Inspector — that's all you need.
@export var character_data: CharacterData

# Team is set automatically by PlayerCharacter/EnemyCharacter in _ready()
var team: String = ""

# --- Stats (populated from CharacterData in _ready) ---
var max_hp: int = 25
var attack_power: int = 10
var defense: int = 5
var initiative: int = 10
var crit_chance: float = 0.05
var move_speed: float = 100.0
var move_range: int = 5
var attack_range_min: int = 1
var attack_range_max: int = 1
var abilities: Array[Ability] = []

# --- Runtime state (don't touch) ---
var current_hp: int
var current_tile: Vector2i
var base_layer: TileMapLayer
var movement_left: int = 0
var has_used_action: bool = false
var follow_up_used_this_turn: bool = false ## Reset each turn; gates the once-per-turn combo follow-up
var move_path: Array = []
var move_target: Vector2 = Vector2.ZERO
var moving: bool = false
var facing: String = "down" ## Current facing direction (up/down/left/right)
var _sprite: AnimatedSprite2D

var is_alive: bool:
	get: return current_hp > 0

var health_bar: HealthBar

func _ready() -> void:
	_sprite = get_node_or_null("AnimatedSprite2D")
	_apply_character_data()
	current_hp = max_hp
	_add_to_groups()
	_create_health_bar()
	_play_anim("idle")
	_reset_ability_uses()

## Reset all ability use counts (called at battle start or per battle).
func _reset_ability_uses() -> void:
	for ability in abilities:
		ability.reset_uses()

## Apply all configuration from CharacterData resource.
func _apply_character_data() -> void:
	if not character_data:
		return
	max_hp = character_data.max_hp
	attack_power = character_data.attack_power
	defense = character_data.defense
	initiative = character_data.initiative
	crit_chance = character_data.crit_chance
	move_speed = character_data.move_speed
	move_range = character_data.move_range
	attack_range_min = character_data.attack_range_min
	attack_range_max = character_data.attack_range_max
	# Duplicate abilities so each instance has its own use counters
	abilities.clear()
	for ability in character_data.abilities:
		abilities.append(ability.duplicate())
	# Build sprite frames from idle/walk textures if provided
	if character_data.idle_texture and character_data.walk_texture and _sprite:
		_sprite.sprite_frames = SpriteFrameBuilder.build(
			character_data.idle_texture, character_data.walk_texture
		)
		# Replacing sprite_frames keeps the old animation name but stops playback.
		# Force-play so the idle animation actually runs with the new frames.
		_sprite.play(&"idle_" + facing)

func _create_health_bar() -> void:
	health_bar = HealthBar.new()
	add_child(health_bar) # triggers _ready() which creates the fill style
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
	# Deduct terrain-weighted cost, not just tile count
	var path_cost := 0
	for tile in move_path:
		path_cost += TerrainRegistry.get_move_cost(tile, tilemap)
	movement_left -= path_cost
	moving = true
	EventBus.character_movement_started.emit(self )
	_advance_path()

func _advance_path() -> void:
	if move_path.size() > 0:
		var next_tile = move_path.pop_front()
		move_target = base_layer.map_to_local(next_tile) + Constants.TILE_CENTER_OFFSET
		_update_facing(move_target - global_position)
		_play_anim("walk")
	else:
		moving = false
		_play_anim("idle")
		var old_tile = current_tile
		current_tile = base_layer.local_to_map(global_position)
		movement_finished.emit()
		EventBus.character_movement_finished.emit(self )
		EventBus.character_moved.emit(self , old_tile, current_tile)

# --- Animation Helpers ---

## Update facing direction from a movement vector.
func _update_facing(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		facing = "right" if dir.x > 0 else "left"
	else:
		facing = "down" if dir.y > 0 else "up"

## Play a directional animation (e.g. "walk" -> "walk_down").
## Falls back to the base name or "default" if directional variant doesn't exist.
func _play_anim(base_name: String) -> void:
	if not _sprite:
		return
	var anim_name := base_name + "_" + facing
	if _sprite.sprite_frames and _sprite.sprite_frames.has_animation(anim_name):
		if _sprite.animation != anim_name:
			_sprite.play(anim_name)
	elif _sprite.sprite_frames and _sprite.sprite_frames.has_animation(base_name):
		if _sprite.animation != base_name:
			_sprite.play(base_name)
	elif _sprite.sprite_frames and _sprite.sprite_frames.has_animation("default"):
		if _sprite.animation != "default":
			_sprite.play("default")

# Override in subclasses for AI, etc.
func on_turn_started() -> void:
	pass

func on_turn_ended() -> void:
	pass

func take_damage(amount: int, source: Node2D = null) -> void:
	current_hp = max(0, current_hp - amount)
	_update_health_bar()
	EventBus.character_damaged.emit(self , amount, source)
	if current_hp <= 0:
		_die()

func _die() -> void:
	EventBus.character_died.emit(self )
	# Remove from all groups immediately so we're not considered in targeting
	remove_from_group(Constants.GROUP_ALL_CHARACTERS)
	remove_from_group(Constants.GROUP_PLAYER_CHARACTERS)
	remove_from_group(Constants.GROUP_ENEMY_CHARACTERS)
	# Play death animation (fade out)
	var tween = create_tween()
	tween.tween_property(self , "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func heal(amount: int, source: Node2D = null) -> void:
	current_hp = min(current_hp + amount, max_hp)
	_update_health_bar()
	EventBus.character_healed.emit(self , amount, source)

func attack_target(target: CharacterBase) -> Dictionary:
	if has_used_action:
		return {"success": false, "reason": "already_used_action"}
	
	var dist = _tile_distance(current_tile, target.current_tile)
	if dist < attack_range_min or dist > attack_range_max:
		return {"success": false, "reason": "out_of_range"}
	
	# Calculate damage (includes terrain defense bonus for the defender)
	var terrain_def: int = 0
	var tilemap = get_tree().get_first_node_in_group("tilemap")
	if tilemap:
		terrain_def = TerrainRegistry.get_defense_bonus(target.current_tile, tilemap)
	var is_crit = randf() < crit_chance
	var effective_defense: int = target.defense + terrain_def
	var base_damage = max(1, attack_power - effective_defense)
	var final_damage = base_damage * 2 if is_crit else base_damage
	
	has_used_action = true
	
	# Both characters face each other before attacking
	_update_facing(target.global_position - global_position)
	_play_anim("idle")
	target._update_facing(global_position - target.global_position)
	target._play_anim("idle")
	
	# Play attack animation overlay (blocking cutscene)
	await AttackAnimationOverlay.play_attack_animation(self , target, final_damage, is_crit)
	
	# Apply damage after the animation completes
	target.take_damage(final_damage, self )
	
	return {"success": true, "damage": final_damage, "is_crit": is_crit}

func can_attack_target(target: CharacterBase) -> bool:
	if has_used_action or target.team == team or not target.is_alive:
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

func get_sfx(action: String) -> String:
	if character_data and character_data.sfx:
		var custom: String = character_data.sfx.get_sfx(action)
		if custom != "":
			return custom
	return "" # Empty means "use global default"

# --- Ability Helpers ---

## Returns abilities that can still be used this turn.
func get_usable_abilities() -> Array[Ability]:
	var usable: Array[Ability] = []
	if has_used_action:
		return usable
	for ability in abilities:
		if ability.can_use():
			usable.append(ability)
	return usable

## Whether this character has any usable abilities right now.
func has_abilities() -> bool:
	return get_usable_abilities().size() > 0

## Get valid targets for a specific ability.
func get_ability_targets(ability: Ability) -> Array:
	var targets: Array = []
	var all_chars = get_tree().get_nodes_in_group(Constants.GROUP_ALL_CHARACTERS)
	for character in all_chars:
		if not character is CharacterBase or not character.is_alive:
			continue
		var dist = _tile_distance(current_tile, character.current_tile)
		if dist < ability.range_min or dist > ability.range_max:
			continue
		match ability.target_type:
			Ability.TargetType.ALLY:
				if character.team == team and character != self:
					targets.append(character)
			Ability.TargetType.ENEMY:
				if character.team != team:
					targets.append(character)
			Ability.TargetType.SELF:
				if character == self:
					targets.append(character)
	return targets

func _tile_distance(from: Vector2i, to: Vector2i) -> int:
	return abs(from.x - to.x) + abs(from.y - to.y)
