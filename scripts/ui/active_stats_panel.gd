# ActiveStatsPanel - Top-right panel showing the active character's stats.
# Swaps to show hovered unit stats on hover, returns to active when mouse leaves.
extends PanelContainer

# --- Node References ---

@onready var char_name_label: Label = $MarginContainer/VBox/CharNameLabel
@onready var hp_label: Label = $MarginContainer/VBox/StatsContainer/HPLabel
@onready var atk_label: Label = $MarginContainer/VBox/StatsContainer/ATKLabel
@onready var def_label: Label = $MarginContainer/VBox/StatsContainer/DEFLabel
@onready var move_label: Label = $MarginContainer/VBox/StatsContainer/MoveLabel
@onready var range_label: Label = $MarginContainer/VBox/StatsContainer/RangeLabel

var tilemap_node: Node2D
var active_character: CharacterBase = null
var hovered_character: CharacterBase = null

# --- Lifecycle ---

func _ready() -> void:
	# Show for every turn (player and enemy), hide only when the battle ends.
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.battle_ended.connect(_on_battle_ended)
	EventBus.tile_hovered.connect(_on_tile_hovered)
	EventBus.character_movement_finished.connect(_on_character_updated)
	EventBus.character_attacked.connect(_on_character_attacked)

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()
	call_deferred("_cache_references")

func _cache_references() -> void:
	tilemap_node = get_tree().get_first_node_in_group("tilemap")

# --- Signal Handlers ---

func _on_turn_started(character: CharacterBase) -> void:
	active_character = character
	hovered_character = null
	_display_character(character)
	show()

func _on_battle_ended(_victory: bool) -> void:
	active_character = null
	hovered_character = null
	hide()

func _on_tile_hovered(tile_pos: Vector2i) -> void:
	if not active_character or not visible or not tilemap_node:
		return

	var character = tilemap_node.get_character_at_tile(tile_pos)
	if character and character is CharacterBase:
		hovered_character = character as CharacterBase
		_display_character(hovered_character)
	else:
		# Mouse left a unit — snap back to active character
		if hovered_character != null:
			hovered_character = null
			_display_character(active_character)

func _on_character_updated(character: Node2D) -> void:
	if character == active_character and hovered_character == null:
		_display_character(active_character)
	elif character == hovered_character:
		_display_character(hovered_character)

func _on_character_attacked(attacker: Node2D, _target: Node2D, _damage: int, _is_crit: bool) -> void:
	if attacker == active_character and hovered_character == null:
		_display_character(active_character)

# --- Display ---

func _display_character(character: CharacterBase) -> void:
	if not character:
		return

	var display_name := character.name
	if character.character_data and character.character_data.display_name != "":
		display_name = character.character_data.display_name

	# Indicate if viewing a different unit vs the active character
	if character == active_character:
		char_name_label.text = display_name
		char_name_label.add_theme_color_override("font_color", Color.WHITE)
	elif character.team == Constants.TEAM_ENEMY:
		char_name_label.text = display_name + " [Enemy]"
		char_name_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	else:
		char_name_label.text = display_name + " [Ally]"
		char_name_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))

	hp_label.text = "HP: %d / %d" % [character.current_hp, character.max_hp]
	atk_label.text = "ATK: %d" % character.attack_power
	def_label.text = "DEF: %d" % character.defense
	move_label.text = "MOV: %d / %d" % [character.movement_left, character.move_range]

	if character.attack_range_min == character.attack_range_max:
		range_label.text = "RNG: %d" % character.attack_range_min
	else:
		range_label.text = "RNG: %d-%d" % [character.attack_range_min, character.attack_range_max]
