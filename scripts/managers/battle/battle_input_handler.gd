# BattleInputHandler - State-aware input router for player turns.
extends Node

var game_manager: Node
var tilemap_node: Node2D

## Double-tap confirmation for ending turn with actions remaining.
var _end_turn_pending: bool = false
var _end_turn_timer: float = 0.0
const END_TURN_CONFIRM_WINDOW := 1.5 ## seconds to press Space again


func _ready() -> void:
	call_deferred("_cache_references")

func _cache_references() -> void:
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		var scene = get_tree().get_current_scene()
		if scene:
			game_manager = scene.find_child("GameManager", true, false)
	tilemap_node = get_tree().get_first_node_in_group("tilemap")

func _process(delta: float) -> void:
	# Tick down the end-turn confirmation window
	if _end_turn_pending:
		_end_turn_timer -= delta
		if _end_turn_timer <= 0.0:
			_end_turn_pending = false

# --- Input Routing ---

func _unhandled_input(event: InputEvent) -> void:
	if not game_manager or not tilemap_node:
		return

	# --- Right-click / Escape: cancel current sub-action ---
	if _is_cancel(event):
		_end_turn_pending = false
		game_manager.cancel_action()
		get_viewport().set_input_as_handled()
		return

	# --- Space: end turn ---
	if event.is_action_pressed("ui_accept"):
		_handle_end_turn_request()
		get_viewport().set_input_as_handled()
		return

	# --- Left click ---
	if not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return

	var tile := _get_tile_at_mouse()

	match game_manager.state:
		game_manager.BattleState.PLAYER_SELECTING_MOVE:
			_handle_selecting_move(tile)
		game_manager.BattleState.PLAYER_SELECTING_ATTACK:
			_handle_selecting_attack(tile)
		game_manager.BattleState.PLAYER_SELECTING_ABILITY:
			_handle_selecting_ability(tile)

# --- State Handlers ---

func _handle_selecting_move(tile: Vector2i) -> void:
	var character = game_manager.current_character
	if not character:
		return

	if tile in tilemap_node.cached_reachable_tiles:
		_end_turn_pending = false
		game_manager.request_move(character, tile)

## Click a valid enemy target → attack.
func _handle_selecting_attack(tile: Vector2i) -> void:
	var character = game_manager.current_character
	if not character:
		return

	var target = tilemap_node.get_character_at_tile(tile)
	if target and character.can_attack_target(target):
		_end_turn_pending = false
		game_manager.request_attack(character, target)

## Click a valid ability target → use ability.
func _handle_selecting_ability(tile: Vector2i) -> void:
	var character = game_manager.current_character
	var ability: Ability = game_manager.selected_ability
	if not character or not ability:
		return

	var target = tilemap_node.get_character_at_tile(tile)
	if not target or not target is CharacterBase:
		return

	# Verify this target is valid for the ability
	var valid_targets = character.get_ability_targets(ability)
	if target in valid_targets:
		_end_turn_pending = false
		game_manager.request_ability(character, ability, target)

# --- End Turn (double-tap Space) ---

func _handle_end_turn_request() -> void:
	if game_manager.state not in [
		game_manager.BattleState.PLAYER_SELECTING_MOVE,
		game_manager.BattleState.PLAYER_SELECTING_ATTACK,
		game_manager.BattleState.PLAYER_SELECTING_ABILITY,
	]:
		return

	if game_manager.has_actions_remaining():
		if _end_turn_pending:
			# Second press within window — confirm end turn
			_end_turn_pending = false
			game_manager.end_player_turn()
		else:
			# First press — start confirmation window
			_end_turn_pending = true
			_end_turn_timer = END_TURN_CONFIRM_WINDOW
			# TODO: Show "Press Space again to end turn" hint in UI
	else:
		# No actions remaining — end immediately
		game_manager.end_player_turn()

# --- Helpers ---

func _is_cancel(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_RIGHT
	if event.is_action_pressed("ui_cancel"):
		return true
	return false

func _get_tile_at_mouse() -> Vector2i:
	var base_layer: TileMapLayer = tilemap_node.base_layer
	var mouse_pos := base_layer.get_global_mouse_position()
	var local_mouse := base_layer.to_local(mouse_pos)
	return base_layer.local_to_map(local_mouse)
