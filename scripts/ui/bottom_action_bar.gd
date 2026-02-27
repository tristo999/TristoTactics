# BottomActionBar - Fixed bottom-center bar for player actions.
extends PanelContainer

const ACTIVE_COLOR := Color(1.0, 0.9, 0.3) # gold

# --- Node References ---

@onready var move_button: Button = $MarginContainer/HBox/MoveButton
@onready var attack_button: Button = $MarginContainer/HBox/AttackButton
@onready var end_turn_button: Button = $MarginContainer/HBox/EndTurnButton

var game_manager: Node
var active_character: CharacterBase = null

var _last_state: int = -1

# --- Lifecycle ---

func _ready() -> void:
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.turn_ended.connect(_on_turn_ended)
	EventBus.character_movement_finished.connect(_on_character_updated)
	EventBus.character_attacked.connect(_on_character_attacked)
	EventBus.battle_ended.connect(_on_battle_ended)

	move_button.pressed.connect(_on_move_pressed)
	attack_button.pressed.connect(_on_attack_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)

	# Keyboard navigation between buttons (left/right arrows)
	move_button.focus_mode = Control.FOCUS_ALL
	attack_button.focus_mode = Control.FOCUS_ALL
	end_turn_button.focus_mode = Control.FOCUS_ALL

	move_button.focus_neighbor_right = attack_button.get_path()
	attack_button.focus_neighbor_left = move_button.get_path()
	attack_button.focus_neighbor_right = end_turn_button.get_path()
	end_turn_button.focus_neighbor_left = attack_button.get_path()

	hide()
	call_deferred("_cache_references")

func _cache_references() -> void:
	game_manager = get_tree().get_first_node_in_group("game_manager")

func _process(_delta: float) -> void:
	if not visible or not game_manager:
		return
	# Lightweight state check — only refresh highlight when state changes.
	var current_state: int = game_manager.state
	if current_state != _last_state:
		_last_state = current_state
		_update_active_highlight()

# --- Signal Handlers ---

func _on_turn_started(character: CharacterBase) -> void:
	if character.team == Constants.TEAM_PLAYER:
		active_character = character
		_refresh()
		show()
	else:
		active_character = null
		hide()

func _on_turn_ended(_character: CharacterBase) -> void:
	active_character = null
	hide()

func _on_battle_ended(_victory: bool) -> void:
	active_character = null
	hide()

func _on_character_updated(character: Node2D) -> void:
	if character == active_character and visible:
		_refresh()

func _on_character_attacked(attacker: Node2D, _target: Node2D, _damage: int, _is_crit: bool) -> void:
	if attacker == active_character and visible:
		_refresh()

# --- Button Handlers ---

func _on_move_pressed() -> void:
	if game_manager:
		game_manager.enter_move_selection()

func _on_attack_pressed() -> void:
	if game_manager:
		game_manager.enter_attack_selection()

func _on_end_turn_pressed() -> void:
	if game_manager:
		game_manager.end_player_turn()

# --- Display Updates ---

func _refresh() -> void:
	if not active_character:
		return

	# Move: enabled if character has movement left
	var can_move := active_character.movement_left > 0
	move_button.disabled = not can_move
	move_button.tooltip_text = "" if can_move else "No movement remaining"

	# Attack: enabled if hasn't attacked AND targets exist in range
	var has_targets := active_character.get_targets_in_range().size() > 0
	var can_attack := not active_character.has_attacked and has_targets
	attack_button.disabled = not can_attack
	if active_character.has_attacked:
		attack_button.tooltip_text = "Already attacked"
	elif not has_targets:
		attack_button.tooltip_text = "No targets in range"
	else:
		attack_button.tooltip_text = ""

	# End Turn: always available
	end_turn_button.disabled = false

	_update_active_highlight()

func _update_active_highlight() -> void:
	if not game_manager:
		return
	var gm_state: int = game_manager.state
	_set_button_active(move_button, gm_state == game_manager.BattleState.PLAYER_SELECTING_MOVE)
	_set_button_active(attack_button, gm_state == game_manager.BattleState.PLAYER_SELECTING_ATTACK)
	# End Turn is never "active" in a selection sense
	_set_button_active(end_turn_button, false)

func _set_button_active(button: Button, active: bool) -> void:
	if active and not button.disabled:
		button.add_theme_color_override("font_color", ACTIVE_COLOR)
	else:
		button.remove_theme_color_override("font_color")
