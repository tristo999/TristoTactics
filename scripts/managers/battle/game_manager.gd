# GameManager - Manages battle flow, turn order, and game state
extends Node

@export var tilemap_node: Node2D
@export var action_camera: Camera2D
@export var turn_label: Label
@onready var timer: Timer = $TurnTimer

var turn_order: Array = []
var current_character: Node2D
var battle_active: bool = false

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
	if is_enemy_turn():
		timer.start()

# =============================================================================
# PROCESS
# =============================================================================

func _process(_delta: float) -> void:
	if battle_active and not is_enemy_turn() and not _is_moving():
		if Input.is_action_just_pressed("ui_accept"):
			_advance_turn()

func _is_moving() -> bool:
	return current_character and current_character.moving

func _start_character_turn(character: Node2D) -> void:
	current_character = character
	character.movement_left = character.move_range
	_show_movement_range()
	character.on_turn_started()
	EventBus.turn_started.emit(character)

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
	if is_enemy_turn():
		timer.start()
	else:
		timer.stop()
	_start_character_turn(current_character)

func _on_turn_timer_timeout() -> void:
	_advance_turn()

func request_move(character: Node2D, target_tile: Vector2i) -> bool:
	if character != current_character or is_enemy_turn() or _is_moving():
		return false
	_clear_movement_range()
	character.move_to_tile(target_tile)
	return true

func _on_character_movement_finished(character: Node2D) -> void:
	if character == current_character and character.movement_left > 0:
		call_deferred("_show_movement_range")

func _show_movement_range() -> void:
	if tilemap_node and current_character.movement_left > 0:
		tilemap_node.highlight_reachable_tiles(current_character.current_tile, current_character.movement_left)

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
	turn_order.erase(character)
	var players = turn_order.filter(func(c): return c.team == Constants.TEAM_PLAYER)
	var enemies = turn_order.filter(func(c): return c.team == Constants.TEAM_ENEMY)
	if enemies.is_empty():
		_end_battle(true)
	elif players.is_empty():
		_end_battle(false)
	elif character == current_character and battle_active:
		var index = (turn_order.find(character) + 1) % turn_order.size()
		_start_character_turn(turn_order[index])

func _end_battle(victory: bool) -> void:
	battle_active = false
	timer.stop()
	EventBus.battle_ended.emit(victory)
