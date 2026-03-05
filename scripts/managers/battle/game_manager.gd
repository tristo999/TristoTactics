# GameManager - Battle flow, turn order, and state machine.
extends Node

# --- State Machine ---

enum BattleState {
	INACTIVE, ## Battle hasn't started or has ended
	PLAYER_IDLE, ## Player's turn — menu active, awaiting input
	PLAYER_MOVING, ## Character is animating along a path
	PLAYER_ACTING, ## Attack / ability animation is playing
	PLAYER_WAITING, ## Dialog / tutorial lock — all input blocked
	ENEMY_TURN_START, ## Camera focused, brief pause before action
	ENEMY_SELECTING_MOVE, ## Movement range shown — AI "thinking"
	ENEMY_MOVING, ## Enemy character animating along a path
	ENEMY_SELECTING_ATTACK, ## Attack range shown — AI picking target
	ENEMY_ATTACKING, ## Enemy attack animation playing
}

## Which action the player is currently targeting during PLAYER_IDLE.
enum PlayerMode {MOVE, ATTACK, ABILITY}

var state: BattleState = BattleState.INACTIVE
var player_mode: PlayerMode = PlayerMode.MOVE

# --- Exports & Refs ---

@export var tilemap_node: Node2D
@export var action_camera: Camera2D

## Optional intro event played before the first turn (dialogue, cutscene, etc.).
@export var intro_event: StoryEvent

## Optional victory event played after all enemies are defeated, before the victory screen.
@export var victory_event: StoryEvent

## Optional defeat event played after all players are defeated, before the defeat screen.
@export var defeat_event: StoryEvent

var turn_order: Array[CharacterBase] = []
var current_character: CharacterBase
var selected_ability: Ability = null ## Currently selected ability for targeting

func _ready() -> void:
	add_to_group("game_manager")
	EventBus.character_died.connect(_on_character_died)
	EventBus.character_movement_finished.connect(_on_character_movement_finished)
	EventBus.story_event_triggered.connect(_on_story_event_triggered)
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

	# Play intro event before the first turn (if any)
	if intro_event:
		await play_event(intro_event)

	current_character = turn_order.front()
	_focus_camera(current_character)
	call_deferred("_start_character_turn", current_character)

# --- Turn Flow ---

func _start_character_turn(character: CharacterBase) -> void:
	current_character = character
	character.movement_left = character.move_range
	character.has_used_action = false
	character.on_turn_started()
	EventBus.turn_started.emit(character)

	if character.team == Constants.TEAM_ENEMY and character is EnemyCharacter:
		_execute_enemy_turn(character as EnemyCharacter)
	else:
		# Player turn — enter idle with movement highlights
		_return_to_idle()

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

	if attack_target and not enemy.has_used_action:
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

## Return to PLAYER_IDLE after any action completes.
## Auto-ends the turn when nothing remains.
func _return_to_idle() -> void:
	var can_move := current_character.movement_left > 0
	var can_act := not current_character.has_used_action
	if not can_move and not can_act:
		_auto_end_turn()
		return
	state = BattleState.PLAYER_IDLE
	player_mode = PlayerMode.MOVE
	selected_ability = null
	_update_highlights()

## BottomActionBar "Move" button.
func enter_move_selection() -> void:
	if state != BattleState.PLAYER_IDLE:
		return
	player_mode = PlayerMode.MOVE
	selected_ability = null
	_update_highlights()

## BottomActionBar "Attack" button.
func enter_attack_selection() -> void:
	if state != BattleState.PLAYER_IDLE:
		return
	if current_character.has_used_action:
		return
	player_mode = PlayerMode.ATTACK
	selected_ability = null
	_update_highlights()

## BottomActionBar ability button — switch to ability targeting.
func enter_ability_selection(ability: Ability) -> void:
	if state != BattleState.PLAYER_IDLE:
		return
	if current_character.has_used_action:
		return
	player_mode = PlayerMode.ABILITY
	selected_ability = ability
	_update_highlights()

## End current character's turn (always works from PLAYER_IDLE).
func end_player_turn() -> void:
	if state != BattleState.PLAYER_IDLE:
		return
	selected_ability = null
	_clear_highlights()
	_advance_turn()

## Auto-end when both actions are spent (no confirmation needed).
func _auto_end_turn() -> void:
	_clear_highlights()
	_advance_turn()

## Right-click / cancel — return to move mode.
func cancel_action() -> void:
	if state != BattleState.PLAYER_IDLE:
		return
	player_mode = PlayerMode.MOVE
	selected_ability = null
	_update_highlights()

func has_actions_remaining() -> bool:
	if not current_character:
		return false
	var can_move := current_character.movement_left > 0
	var can_act := not current_character.has_used_action
	return can_move or can_act

# --- Player Actions (called by BattleInputHandler) ---

func request_move(character: CharacterBase, target_tile: Vector2i) -> bool:
	if state != BattleState.PLAYER_IDLE or character != current_character:
		return false
	state = BattleState.PLAYER_MOVING
	_clear_highlights()
	character.move_to_tile(target_tile)
	return true

func request_attack(character: CharacterBase, target: CharacterBase) -> bool:
	if state != BattleState.PLAYER_IDLE or character != current_character:
		return false
	if character.has_used_action:
		return false

	state = BattleState.PLAYER_ACTING
	_clear_highlights()
	var result = await character.attack_target(target)
	_return_to_idle()
	return result.success

func request_ability(character: CharacterBase, ability: Ability, target: CharacterBase) -> bool:
	if state != BattleState.PLAYER_IDLE or character != current_character:
		return false
	if character.has_used_action or not ability.can_use():
		return false

	state = BattleState.PLAYER_ACTING
	_clear_highlights()

	# Face the target
	character._update_facing(target.global_position - character.global_position)
	character._play_anim("idle")

	var result = ability.execute(character, target)
	character.has_used_action = true
	selected_ability = null

	EventBus.ability_used.emit(character, target, ability)

	# Brief pause so the player sees the effect
	await get_tree().create_timer(0.5).timeout

	_return_to_idle()
	return result.get("success", false)

# --- Signal Handlers ---

func _on_character_movement_finished(character: CharacterBase) -> void:
	if character != current_character:
		return
	# Enemy movement is handled by the staged coroutine — no action needed here
	if is_enemy_turn():
		return
	# Player movement finished — return to idle
	_return_to_idle()

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

## Refresh tile highlights based on current player_mode.
func _update_highlights() -> void:
	match player_mode:
		PlayerMode.MOVE:
			_show_movement_only()
		PlayerMode.ATTACK:
			_show_attack_only()
		PlayerMode.ABILITY:
			if selected_ability:
				_show_ability_range(selected_ability)

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

func _show_ability_range(ability: Ability) -> void:
	if not tilemap_node or not current_character:
		return
	_clear_highlights()
	tilemap_node.highlight_renderer.set_current_character(current_character.current_tile)
	var tiles = ability.get_target_tiles(current_character.current_tile, tilemap_node)
	tilemap_node.highlight_renderer.set_ability_tiles(tiles)

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

# --- Story Events ---

## Pause gameplay and run a story event. Awaitable — returns when the event finishes.
func play_event(event: StoryEvent) -> void:
	var previous_state := state
	state = BattleState.PLAYER_WAITING
	await event.execute(get_tree())
	event.completed.emit()
	if state == BattleState.PLAYER_WAITING:
		state = previous_state

func _on_story_event_triggered(event: StoryEvent) -> void:
	await play_event(event)

func _end_battle(victory: bool) -> void:
	state = BattleState.INACTIVE
	# Play post-battle story event if one exists
	var post_event: StoryEvent = victory_event if victory else defeat_event
	if post_event:
		await play_event(post_event)
	EventBus.battle_ended.emit(victory)
