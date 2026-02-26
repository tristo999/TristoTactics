# GameManager - Manages battle flow, turn order, and game state
# Uses an explicit state machine to control battle phases.
extends Node

# =============================================================================
# STATE MACHINE
# =============================================================================

enum BattleState {
	INACTIVE, ## Battle hasn't started or has ended
	PLAYER_IDLE, ## Waiting for player input (move / attack / end turn)
	PLAYER_MOVING, ## Player character is moving along a path
	PLAYER_ATTACKING, ## Player attack animation is playing
	ENEMY_TURN, ## Enemy AI coroutine is executing
}

var state: BattleState = BattleState.INACTIVE

# =============================================================================
# EXPORTS & REFS
# =============================================================================

@export var tilemap_node: Node2D
@export var action_camera: Camera2D
@export var turn_label: Label

var turn_order: Array[CharacterBase] = []
var current_character: CharacterBase

func _ready() -> void:
	add_to_group("game_manager")
	EventBus.character_died.connect(_on_character_died)
	EventBus.character_movement_finished.connect(_on_character_movement_finished)
	# Deferred so all sibling nodes finish _ready() before we look for them
	call_deferred("_initialize_battle")

func _find_node_references() -> void:
	if not tilemap_node:
		tilemap_node = get_tree().get_first_node_in_group("tilemap")
	if not action_camera:
		action_camera = get_tree().get_first_node_in_group("action_camera")
	if not turn_label:
		turn_label = get_tree().get_first_node_in_group("turn_label")

func _build_turn_order() -> void:
	turn_order.clear()
	for node in get_tree().get_nodes_in_group(Constants.GROUP_ALL_CHARACTERS):
		if node is CharacterBase:
			turn_order.append(node as CharacterBase)
	turn_order.sort_custom(_compare_initiative)

func _initialize_battle() -> void:
	# Wait one frame so all nodes have fired _ready() and joined their groups
	await get_tree().process_frame
	_find_node_references()
	_build_turn_order()
	if turn_order.is_empty():
		push_warning("No characters found in groups!")
		return
	_setup_characters()
	_start_battle()

func _compare_initiative(a: CharacterBase, b: CharacterBase) -> bool:
	if a.initiative != b.initiative:
		return a.initiative > b.initiative
	# Tie-breaker: players go first
	var a_is_player := a.team == Constants.TEAM_PLAYER
	var b_is_player := b.team == Constants.TEAM_PLAYER
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
	EventBus.battle_started.emit()
	current_character = turn_order.front()
	_focus_camera(current_character)
	_update_turn_label()
	call_deferred("_start_character_turn", current_character)

# =============================================================================
# PROCESS — only handles player end-turn input
# =============================================================================

func _process(_delta: float) -> void:
	if state != BattleState.PLAYER_IDLE:
		return
	if Input.is_action_just_pressed("ui_accept"):
		_advance_turn()

# =============================================================================
# TURN FLOW
# =============================================================================

func _start_character_turn(character: CharacterBase) -> void:
	current_character = character
	character.movement_left = character.move_range
	character.has_attacked = false
	_show_movement_range()
	character.on_turn_started()
	EventBus.turn_started.emit(character)

	if character.team == Constants.TEAM_ENEMY and character is EnemyCharacter:
		state = BattleState.ENEMY_TURN
		_execute_enemy_turn(character as EnemyCharacter)
	else:
		state = BattleState.PLAYER_IDLE

## Execute enemy AI turn sequence
func _execute_enemy_turn(enemy: EnemyCharacter) -> void:
	enemy.ai_turn_completed.connect(_on_enemy_turn_completed.bind(enemy), CONNECT_ONE_SHOT)
	enemy.execute_ai_turn()

func _on_enemy_turn_completed(enemy: EnemyCharacter) -> void:
	if enemy == current_character and state == BattleState.ENEMY_TURN:
		_advance_turn()

func _end_character_turn(character: CharacterBase) -> void:
	_clear_highlights()
	character.on_turn_ended()
	EventBus.turn_ended.emit(character)

func _advance_turn() -> void:
	_end_character_turn(current_character)
	var index = (turn_order.find(current_character) + 1) % turn_order.size()
	current_character = turn_order[index]
	_update_turn_label()
	_focus_camera(current_character)
	_start_character_turn(current_character)

# =============================================================================
# PLAYER ACTIONS (called by BattleInputHandler)
# =============================================================================

func request_move(character: CharacterBase, target_tile: Vector2i) -> bool:
	if state != BattleState.PLAYER_IDLE or character != current_character:
		return false
	state = BattleState.PLAYER_MOVING
	character.move_to_tile(target_tile)
	return true

func request_attack(character: CharacterBase, target: CharacterBase) -> bool:
	if state != BattleState.PLAYER_IDLE or character != current_character:
		return false
	if character.has_attacked:
		return false

	state = BattleState.PLAYER_ATTACKING
	var result = await character.attack_target(target)
	if result.success:
		# Refresh highlights — player must manually end turn
		_show_movement_range()
		state = BattleState.PLAYER_IDLE
		return true
	state = BattleState.PLAYER_IDLE
	return false

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_character_movement_finished(character: CharacterBase) -> void:
	if character != current_character:
		return
	if state == BattleState.ENEMY_TURN:
		# Show attack range while enemy AI coroutine continues
		if not character.has_attacked:
			_clear_highlights()
			_show_attack_range()
		return
	# Player movement finished — return to idle
	state = BattleState.PLAYER_IDLE
	_show_movement_range()

func _on_character_died(character: CharacterBase) -> void:
	var was_current = character == current_character
	turn_order.erase(character)

	var players = turn_order.filter(func(c): return c.team == Constants.TEAM_PLAYER)
	var enemies = turn_order.filter(func(c): return c.team == Constants.TEAM_ENEMY)

	if enemies.is_empty():
		_end_battle(true)
	elif players.is_empty():
		_end_battle(false)
	elif was_current and state != BattleState.INACTIVE:
		# End the dead character's turn properly, then start the next
		_end_character_turn(character)
		var next_index = turn_order.find(character)
		if next_index < 0:
			next_index = 0
		next_index = next_index % turn_order.size()
		_start_character_turn(turn_order[next_index])

# =============================================================================
# HIGHLIGHTS & CAMERA
# =============================================================================

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

func _clear_highlights() -> void:
	if tilemap_node:
		tilemap_node.clear_highlights()

func is_enemy_turn() -> bool:
	return state == BattleState.ENEMY_TURN

func _update_turn_label() -> void:
	if turn_label:
		turn_label.text = "Enemy Turn" if is_enemy_turn() else "Player Turn"
	EventBus.update_turn_indicator.emit(current_character, is_enemy_turn())

func _focus_camera(target: Node2D) -> void:
	if action_camera and target:
		action_camera.move_camera(target)

func _end_battle(victory: bool) -> void:
	state = BattleState.INACTIVE
	EventBus.battle_ended.emit(victory)
