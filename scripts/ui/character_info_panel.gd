# CharacterInfoPanel - Shows current turn character stats in the top-left
extends PanelContainer

@onready var char_name_label: Label = $MarginContainer/VBox/CharNameLabel
@onready var movement_label: Label = $MarginContainer/VBox/StatsContainer/MovementLabel
@onready var attacks_label: Label = $MarginContainer/VBox/StatsContainer/AttacksLabel
@onready var attack_range_label: Label = $MarginContainer/VBox/StatsContainer/AttackRangeLabel

var current_character: CharacterBase = null

func _ready():
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.character_movement_finished.connect(_on_character_updated)
	EventBus.character_attacked.connect(_on_character_attacked)
	hide()

func _on_turn_started(character: CharacterBase):
	current_character = character
	_update_display()
	show()

func _on_character_updated(character: CharacterBase):
	if character == current_character:
		_update_display()

func _on_character_attacked(attacker: Node2D, _target: Node2D, _damage: int, _is_crit: bool):
	if attacker == current_character:
		_update_display()

func _update_display():
	if not current_character:
		hide()
		return

	# Character name
	char_name_label.text = current_character.name

	# Movement
	movement_label.text = "Movement: %d / %d" % [current_character.movement_left, current_character.move_range]

	# Attacks
	var attacks = 0 if current_character.has_attacked else 1
	attacks_label.text = "Attacks Left: %d" % attacks

	# Attack Range
	if current_character.attack_range_min == current_character.attack_range_max:
		attack_range_label.text = "Attack Range: %d" % current_character.attack_range_min
	else:
		attack_range_label.text = "Attack Range: %d - %d" % [current_character.attack_range_min, current_character.attack_range_max]
