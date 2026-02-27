# GameManager - Battle flow, turn order, and state machine.
extends Node

# --- State Machine ---

enum BattleState {
	INACTIVE, ## Battle hasn't started or has ended
	PLAYER_SELECTING_MOVE, ## Movement tiles highlighted — click destination or use menu
	PLAYER_MOVING, ## Character is animating along a path
	PLAYER_SELECTING_ATTACK, ## Attack range highlighted — click target or use menu
	PLAYER_ATTACKING, ## Attack animation is playing
	PLAYER_WAITING, ## Dialog / tutorial lock — all input blocked
	ENEMY_TURN_START, ## Camera focused, brief pause before action
	ENEMY_SELECTING_MOVE, ## Movement range shown — AI "thinking"
	ENEMY_MOVING, ## Enemy character animating along a path
	ENEMY_SELECTING_ATTACK, ## Attack range shown — AI picking target
	ENEMY_ATTACKING, ## Enemy attack animation playing
}

var state: BattleState = BattleState.INACTIVE

# --- Exports & Refs ---

@export var tilemap_node: Node2D
@export var action_camera: Camera2D

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
	call_deferred("_start_character_turn", current_character)

# --- Turn Flow ---

func _start_character_turn(character: CharacterBase) -> void:
	current_character = character
	character.movement_left = character.move_range
	character.has_attacked = false
	character.on_turn_started()
	EventBus.turn_started.emit(character)

	if character.team == Constants.TEAM_ENEMY and character is EnemyCharacter:
		_execute_enemy_turn(character as EnemyCharacter)
	else:
		# Player turn: auto-enter best state (movement range + bar visible)
		_enter_best_player_state()

## Staged enemy AI turn that mirrors the player flow with visual pauses.
func _execute_enemy_turn(enemy: EnemyCharacter) -> void:
	var pause := enemy.ai_pause_duration

	# --- Stage 1: Turn start — show character highlight, brief pause ----------
	state = BattleState.ENEMY_TURN_START
	_clear_highlights()
	if tilemap_node:
		tilemap_node.highlight_renderer.set_current_character(enemy.current_tile)
	await get_tree().create_timer(pause * 0.4).timeout

	# --- Stage 2: Show movement range (like player SELECTING_MOVE) -----------
	var move_target := enemy.get_ai_move_target()
	var will_move := move_target != enemy.current_tile and enemy.movement_left > 0

	if will_move:
		state = BattleState.ENEMY_SELECTING_MOVE
		_show_movement_only()
		await get_tree().create_timer(pause * 0.75).timeout

		# --- Stage 3: Execute movement ----------------------------------------
		state = BattleState.ENEMY_MOVING
		_clear_highlights()
		if tilemap_node:
			tilemap_node.highlight_renderer.set_current_character(enemy.current_tile)
		enemy.move_to_tile(move_target)
		await enemy.movement_finished
		# Update highlight to new position
		if tilemap_node:
			tilemap_node.highlight_renderer.set_current_character(enemy.current_tile)
		await get_tree().create_timer(pause * 0.3).timeout

	# --- Stage 4: Always show attack range so the player sees the threat ------
	state = BattleState.ENEMY_SELECTING_ATTACK
	_show_attack_only()
	await get_tree().create_timer(pause * 0.75).timeout

	# --- Stage 5: Execute attack if a valid target exists ---------------------
	var attack_target := enemy.get_ai_attack_target()

	if attack_target and not enemy.has_attacked:
		state = BattleState.ENEMY_ATTACKING
		_clear_highlights()
		if tilemap_node:
			tilemap_node.highlight_renderer.set_current_character(enemy.current_tile)
		await enemy.attack_target(attack_target)
		await get_tree().create_timer(pause * 0.3).timeout

	# --- Done — advance to next turn ----------------------------------------
	_advance_turn()

func _end_character_turn(character: CharacterBase) -> void:
	_clear_highlights()
	character.on_turn_ended()
	EventBus.turn_ended.emit(character)

func _advance_turn() -> void:
	_end_character_turn(current_character)
	if turn_order.is_empty():
		return
	var index = (turn_order.find(current_character) + 1) % turn_order.size()
	current_character = turn_order[index]
	_focus_camera(current_character)
	_start_character_turn(current_character)

# --- Player State Transitions (called by BattleInputHandler / BottomActionBar) ---

## Pick the best state based on remaining actions (attack > move).
func _enter_best_player_state() -> void:
	var can_move := current_character.movement_left > 0
	var can_attack := not current_character.has_attacked and current_character.get_targets_in_range().size() > 0

	if not can_move and not can_attack:
		# Both actions spent — auto-end turn
		_auto_end_turn()
		return

	if can_attack:
		_enter_attack_state()
	elif can_move:
		_enter_move_state()

## Enter movement selection.
func _enter_move_state() -> void:
	state = BattleState.PLAYER_SELECTING_MOVE
	_show_movement_only()

## Enter attack selection.
func _enter_attack_state() -> void:
	state = BattleState.PLAYER_SELECTING_ATTACK
	_show_attack_only()

## BottomActionBar "Move" button.
func enter_move_selection() -> void:
	if state not in [BattleState.PLAYER_SELECTING_MOVE, BattleState.PLAYER_SELECTING_ATTACK]:
		return
	if current_character.movement_left <= 0:
		return
	_enter_move_state()

## BottomActionBar "Attack" button.
func enter_attack_selection() -> void:
	if state not in [BattleState.PLAYER_SELECTING_MOVE, BattleState.PLAYER_SELECTING_ATTACK]:
		return
	if current_character.has_attacked:
		return
	_enter_attack_state()

## End current character's turn.
func end_player_turn() -> void:
	if state not in [BattleState.PLAYER_SELECTING_MOVE, BattleState.PLAYER_SELECTING_ATTACK]:
		return
	_clear_highlights()
	_advance_turn()

## Auto-end when both actions are spent (no confirmation needed).
func _auto_end_turn() -> void:
	_clear_highlights()
	_advance_turn()

## Right-click / cancel — go back one level.
func cancel_action() -> void:
	match state:
		BattleState.PLAYER_SELECTING_ATTACK:
			# If player has movement, go back to move selection
			if current_character.movement_left > 0:
				_enter_move_state()
			# Otherwise stay in attack (nothing to go back to)
		BattleState.PLAYER_SELECTING_MOVE:
			# Already at the base state — do nothing
			pass

func has_actions_remaining() -> bool:
	if not current_character:
		return false
	var can_move := current_character.movement_left > 0
	var can_attack := not current_character.has_attacked
	return can_move or can_attack

# --- Player Actions (called by BattleInputHandler) ---

func request_move(character: CharacterBase, target_tile: Vector2i) -> bool:
	if state != BattleState.PLAYER_SELECTING_MOVE or character != current_character:
		return false
	state = BattleState.PLAYER_MOVING
	_clear_highlights()
	character.move_to_tile(target_tile)
	return true

func request_attack(character: CharacterBase, target: CharacterBase) -> bool:
	if state != BattleState.PLAYER_SELECTING_ATTACK or character != current_character:
		return false
	if character.has_attacked:
		return false

	state = BattleState.PLAYER_ATTACKING
	_clear_highlights()
	var result = await character.attack_target(target)
	# After attack completes, enter best next state
	_enter_best_player_state()
	return result.success

# --- Signal Handlers ---

func _on_character_movement_finished(character: CharacterBase) -> void:
	if character != current_character:
		return
	# Enemy movement is handled by the staged coroutine — no action needed here
	if is_enemy_turn():
		return
	# Player movement finished — auto-transition to best next state
	# (attack if targets in range, or move if movement left, or auto-end)
	_enter_best_player_state()

func _on_character_died(character: CharacterBase) -> void:
	var was_current = character == current_character
	var former_index = turn_order.find(character)
	turn_order.erase(character)

	var players = turn_order.filter(func(c): return c.team == Constants.TEAM_PLAYER)
	var enemies = turn_order.filter(func(c): return c.team == Constants.TEAM_ENEMY)

	if enemies.is_empty():
		_end_battle(true)
	elif players.is_empty():
		_end_battle(false)
	elif was_current and state != BattleState.INACTIVE:
		_end_character_turn(character)
		var next_index = former_index % turn_order.size()
		_start_character_turn(turn_order[next_index])

# --- Highlights & Camera ---

func _show_movement_only() -> void:
	if not tilemap_node or not current_character:
		return
	_clear_highlights()
	tilemap_node.highlight_renderer.set_current_character(current_character.current_tile)
	if current_character.movement_left > 0:
		var reachable = tilemap_node.get_reachable_tiles(current_character.current_tile, current_character.movement_left)
		tilemap_node.cached_reachable_tiles = reachable
		tilemap_node.highlight_renderer.set_movement_tiles(reachable)

func _show_attack_only() -> void:
	if not tilemap_node or not current_character:
		return
	_clear_highlights()
	tilemap_node.highlight_renderer.set_current_character(current_character.current_tile)
	tilemap_node.highlight_attack_range(
		current_character.current_tile,
		current_character.attack_range_min,
		current_character.attack_range_max
	)

func _clear_highlights() -> void:
	if tilemap_node:
		tilemap_node.clear_highlights()

func is_enemy_turn() -> bool:
	return state in [
		BattleState.ENEMY_TURN_START,
		BattleState.ENEMY_SELECTING_MOVE,
		BattleState.ENEMY_MOVING,
		BattleState.ENEMY_SELECTING_ATTACK,
		BattleState.ENEMY_ATTACKING,
	]

func _focus_camera(target: Node2D) -> void:
	if action_camera and target:
		action_camera.move_camera(target)

func _end_battle(victory: bool) -> void:
	state = BattleState.INACTIVE
	EventBus.battle_ended.emit(victory)
