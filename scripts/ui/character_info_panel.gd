# CharacterInfoPanel - Shows current turn character stats in the top-left
extends PanelContainer

@onready var char_name_label: Label = $MarginContainer/VBox/CharNameLabel
@onready var movement_label: Label = $MarginContainer/VBox/StatsContainer/MovementLabel
@onready var attacks_label: Label = $MarginContainer/VBox/StatsContainer/AttacksLabel
@onready var attack_range_label: Label = $MarginContainer/VBox/StatsContainer/AttackRangeLabel

var current_character: Node2D = null

func _ready():
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.character_movement_finished.connect(_on_character_updated)
	EventBus.character_attacked.connect(_on_character_attacked)
	hide()

func _on_turn_started(character: Node2D):
	current_character = character
	_update_display()
	show()

func _on_character_updated(character: Node2D):
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
	var move_left = current_character.movement_left if "movement_left" in current_character else 0
	var move_total = current_character.move_range if "move_range" in current_character else 0
	movement_label.text = "Movement: %d / %d" % [move_left, move_total]

	# Attacks
	var attacks = 0 if current_character.has_attacked else 1
	attacks_label.text = "Attacks Left: %d" % attacks

	# Attack Range
	var rmin = current_character.attack_range_min if "attack_range_min" in current_character else 1
	var rmax = current_character.attack_range_max if "attack_range_max" in current_character else 1
	if rmin == rmax:
		attack_range_label.text = "Attack Range: %d" % rmin
	else:
		attack_range_label.text = "Attack Range: %d - %d" % [rmin, rmax]
