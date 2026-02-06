# GameManager - Manages battle flow, turn order, and game state
extends Node

enum TurnPhase { MOVE, ATTACK, DONE }

@export var tilemap_node: Node2D
@export var action_camera: Camera2D
@export var turn_label: Label

var turn_order: Array = []
var current_character: Node2D
var battle_active: bool = false
var current_phase: TurnPhase = TurnPhase.MOVE

func _ready() -> void:
	_find_node_references()
	EventBus.character_died.connect(_on_character_died)
	EventBus.character_movement_finished.connect(_on_character_movement_finished)
	call_deferred("_initialize_battle")

func _find_node_references() -> void:
	if not tilemap_node:
		tilemap_node = get_node_or_null("/root/TestScene/Node2D")
	if not action_camera:
		action_camera = get_node_or_null("../ActionCamera")
	if not turn_label:
		turn_label = get_node_or_null("../TurnLabelCanvas/TurnLabel")

func _build_turn_order() -> void:
	turn_order = get_tree().get_nodes_in_group(Constants.GROUP_ALL_CHARACTERS)
	turn_order.sort_custom(_compare_initiative)

func _initialize_battle() -> void:
	# Wait one frame for characters to add themselves to groups
	await get_tree().process_frame
	_build_turn_order()
	if turn_order.is_empty():
		push_warning("No characters found in groups!")
		return
	_setup_characters()
	_start_battle()

func _compare_initiative(a: Node2D, b: Node2D) -> bool:
	var init_a = a.initiative if "initiative" in a else 0
	var init_b = b.initiative if "initiative" in b else 0
	if init_a != init_b:
		return init_a > init_b
	# Tie-breaker: players go first
	var a_is_player = a.team == Constants.TEAM_PLAYER if "team" in a else false
	var b_is_player = b.team == Constants.TEAM_PLAYER if "team" in b else false
	if a_is_player != b_is_player:
		return a_is_player
	return a.name < b.name

func _setup_characters() -> void:
	if not tilemap_node:
		return
	var base_layer = tilemap_node.get_node_or_null("BaseGrid")
	for character in turn_order:
		character.set_base_layer(base_layer)
		character.current_tile = base_layer.local_to_map(character.global_position)
		character.global_position = base_layer.map_to_local(character.current_tile) + Constants.TILE_CENTER_OFFSET

func _start_battle() -> void:
	battle_active = true
	EventBus.battle_started.emit()
	current_character = turn_order.front()
	_focus_camera(current_character)
	_update_turn_label()
	call_deferred("_start_character_turn", current_character)

# =============================================================================
# PROCESS
# =============================================================================

func _process(_delta: float) -> void:
	if battle_active and not is_enemy_turn() and not _is_moving():
		if Input.is_action_just_pressed("ui_accept"):
			# End turn early
			_advance_turn()

func _is_moving() -> bool:
	return current_character and current_character.moving

func _start_character_turn(character: Node2D) -> void:
	current_character = character
	character.movement_left = character.move_range
	character.has_attacked = false
	current_phase = TurnPhase.MOVE
	_show_movement_range()
	character.on_turn_started()
	EventBus.turn_started.emit(character)
	
	# If it's an enemy turn, execute their AI
	if is_enemy_turn() and character is EnemyCharacter:
		_execute_enemy_turn(character as EnemyCharacter)

## Execute enemy AI turn sequence
func _execute_enemy_turn(enemy: EnemyCharacter) -> void:
	# Movement range is already shown from _start_character_turn
	# Connect to the enemy's turn completion signal
	enemy.ai_turn_completed.connect(_on_enemy_turn_completed.bind(enemy), CONNECT_ONE_SHOT)
	# Start the enemy AI execution
	enemy.execute_ai_turn()

func _on_enemy_turn_completed(enemy: EnemyCharacter) -> void:
	if enemy == current_character and battle_active:
		_advance_turn()

func _end_character_turn(character: Node2D) -> void:
	_clear_movement_range()
	character.on_turn_ended()
	EventBus.turn_ended.emit(character)

func _advance_turn() -> void:
	_end_character_turn(current_character)
	var index = (turn_order.find(current_character) + 1) % turn_order.size()
	current_character = turn_order[index]
	_update_turn_label()
	_focus_camera(current_character)
	_start_character_turn(current_character)

func request_move(character: Node2D, target_tile: Vector2i) -> bool:
	if character != current_character or is_enemy_turn() or _is_moving():
		return false
	if current_phase != TurnPhase.MOVE:
		return false
	_clear_movement_range()
	character.move_to_tile(target_tile)
	return true

func request_attack(character: Node2D, target: Node2D) -> bool:
	if character != current_character or is_enemy_turn() or _is_moving():
		return false
	if character.has_attacked:
		return false
	
	var result = character.attack_target(target)
	if result.success:
		# Brief pause after attack
		await get_tree().create_timer(0.3).timeout
		# If out of movement and attacked, end turn
		if character.movement_left <= 0 and battle_active:
			_advance_turn()
		else:
			# Still has movement, show range again
			_show_movement_range()
		return true
	return false

func _on_character_movement_finished(character: Node2D) -> void:
	if character == current_character:
		if is_enemy_turn():
			# Enemy uses phase system
			_transition_to_attack_phase()
		else:
			# Player can keep moving if they have movement left
			if character.movement_left > 0:
				_show_movement_range()
			else:
				# Out of movement, if already attacked, end turn
				if character.has_attacked:
					_advance_turn()
				else:
					# Show attack range only (no movement left)
					_show_movement_range()

func _transition_to_attack_phase() -> void:
	if current_character.has_attacked:
		# Already attacked, end turn
		_advance_turn()
		return
	current_phase = TurnPhase.ATTACK
	_clear_movement_range()
	_show_attack_range()

func _show_attack_range() -> void:
	if tilemap_node and not current_character.has_attacked:
		tilemap_node.highlight_attack_range(
			current_character.current_tile,
			current_character.attack_range_min,
			current_character.attack_range_max
		)

func _show_movement_range() -> void:
	if tilemap_node:
		tilemap_node.highlight_reachable_tiles(current_character.current_tile, current_character.movement_left, current_character)

func _clear_movement_range() -> void:
	if tilemap_node:
		tilemap_node.clear_highlights()

func is_enemy_turn() -> bool:
	return current_character.team == Constants.TEAM_ENEMY

func _update_turn_label() -> void:
	if turn_label:
		turn_label.text = "Enemy Turn" if is_enemy_turn() else "Player Turn"
	EventBus.update_turn_indicator.emit(current_character, is_enemy_turn())

func _focus_camera(target: Node2D) -> void:
	if action_camera and target:
		action_camera.move_camera(target)

func _on_character_died(character: Node2D) -> void:
	var was_current = character == current_character
	var current_index = turn_order.find(character)
	turn_order.erase(character)
	
	var players = turn_order.filter(func(c): return c.team == Constants.TEAM_PLAYER)
	var enemies = turn_order.filter(func(c): return c.team == Constants.TEAM_ENEMY)
	
	if enemies.is_empty():
		_end_battle(true)
	elif players.is_empty():
		_end_battle(false)
	elif was_current and battle_active:
		# Move to next character (use same index since we removed current)
		var next_index = current_index % turn_order.size()
		_start_character_turn(turn_order[next_index])

func _end_battle(victory: bool) -> void:
	battle_active = false
	EventBus.battle_ended.emit(victory)
