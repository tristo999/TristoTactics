# BottomActionBar - Fixed bottom-center bar for player actions.
extends PanelContainer

const ACTIVE_COLOR := Color(1.0, 0.9, 0.3) # gold
const ABILITY_COLOR := Color(0.4, 0.8, 1.0) # cyan for ability buttons

# --- Node References ---

@onready var move_button: Button = $MarginContainer/HBox/MoveButton
@onready var attack_button: Button = $MarginContainer/HBox/AttackButton
@onready var ability_button: Button = $MarginContainer/HBox/AbilityButton
@onready var end_turn_button: Button = $MarginContainer/HBox/EndTurnButton
@onready var hbox: HBoxContainer = $MarginContainer/HBox

var game_manager: Node
var active_character: CharacterBase = null
## The ability that the ability button currently maps to (first usable, or first in list).
var _bound_ability: Ability = null

var _last_state: int = -1
var _last_mode: int = -1

# --- Lifecycle ---

func _ready() -> void:
	add_to_group("action_bar")
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.turn_ended.connect(_on_turn_ended)
	EventBus.character_movement_finished.connect(_on_character_updated)
	EventBus.character_attacked.connect(_on_character_attacked)
	EventBus.ability_used.connect(_on_ability_used)
	EventBus.battle_ended.connect(_on_battle_ended)

	move_button.pressed.connect(_on_move_pressed)
	attack_button.pressed.connect(_on_attack_pressed)
	ability_button.pressed.connect(_on_ability_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)

	# Keyboard navigation between buttons (left/right arrows)
	move_button.focus_mode = Control.FOCUS_ALL
	attack_button.focus_mode = Control.FOCUS_ALL
	ability_button.focus_mode = Control.FOCUS_ALL
	end_turn_button.focus_mode = Control.FOCUS_ALL

	move_button.focus_neighbor_right = attack_button.get_path()
	attack_button.focus_neighbor_left = move_button.get_path()
	attack_button.focus_neighbor_right = ability_button.get_path()
	ability_button.focus_neighbor_left = attack_button.get_path()
	ability_button.focus_neighbor_right = end_turn_button.get_path()
	end_turn_button.focus_neighbor_left = ability_button.get_path()

	hide()
	call_deferred("_cache_references")

func _cache_references() -> void:
	game_manager = get_tree().get_first_node_in_group("game_manager")

func _process(_delta: float) -> void:
	if not visible or not game_manager:
		return
	# Refresh highlight when state or player mode changes.
	var current_state: int = game_manager.state
	var current_mode: int = game_manager.player_mode
	if current_state != _last_state or current_mode != _last_mode:
		_last_state = current_state
		_last_mode = current_mode
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

func _on_ability_used(caster: Node2D, _target: Node2D, _ability: Ability) -> void:
	if caster == active_character and visible:
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

func _on_ability_pressed() -> void:
	if game_manager and _bound_ability:
		game_manager.enter_ability_selection(_bound_ability)

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
	var can_attack := not active_character.has_used_action and has_targets
	attack_button.disabled = not can_attack
	if active_character.has_used_action:
		attack_button.tooltip_text = "Already used action"
	elif not has_targets:
		attack_button.tooltip_text = "No targets in range"
	else:
		attack_button.tooltip_text = ""

	# Ability: enabled if character has a usable ability and hasn't used action
	_refresh_ability_button()

	# End Turn: always available
	end_turn_button.disabled = false

	_update_active_highlight()

func _update_active_highlight() -> void:
	if not game_manager:
		return
	var is_idle: bool = game_manager.state == game_manager.BattleState.PLAYER_IDLE
	var mode: int = game_manager.player_mode
	_set_button_active(move_button, is_idle and mode == game_manager.PlayerMode.MOVE)
	_set_button_active(attack_button, is_idle and mode == game_manager.PlayerMode.ATTACK)
	_set_button_active(ability_button, is_idle and mode == game_manager.PlayerMode.ABILITY)
	_set_button_active(end_turn_button, false)

func _set_button_active(button: Button, active: bool) -> void:
	if active and not button.disabled:
		button.add_theme_color_override("font_color", ACTIVE_COLOR)
	else:
		button.remove_theme_color_override("font_color")

## Update the static Ability button based on the active character's abilities.
func _refresh_ability_button() -> void:
	if not active_character:
		ability_button.disabled = true
		ability_button.text = "Ability"
		ability_button.tooltip_text = "No abilities"
		_bound_ability = null
		return

	var usable := active_character.get_usable_abilities()
	var all_abilities := active_character.abilities

	if all_abilities.is_empty():
		# Character has no abilities at all
		ability_button.disabled = true
		ability_button.text = "Ability"
		ability_button.tooltip_text = "No abilities"
		_bound_ability = null
	elif active_character.has_used_action:
		# Already used action this turn
		var ab: Ability = all_abilities[0]
		ability_button.disabled = true
		ability_button.text = _ability_label(ab)
		ability_button.tooltip_text = "Already used action"
		_bound_ability = null
	elif usable.is_empty():
		# Has abilities but all uses spent
		var ab: Ability = all_abilities[0]
		ability_button.disabled = true
		ability_button.text = _ability_label(ab)
		ability_button.tooltip_text = "No uses remaining"
		_bound_ability = null
	else:
		# Has a usable ability
		_bound_ability = usable[0]
		ability_button.disabled = false
		ability_button.text = _ability_label(_bound_ability)
		ability_button.tooltip_text = _bound_ability.description

## Format ability button label with remaining uses, e.g. "Heal (2/3)".
func _ability_label(ability: Ability) -> String:
	if ability.max_uses > 0:
		return "%s (%d/%d)" % [ability.ability_name, ability.uses_left, ability.max_uses]
	return ability.ability_name
