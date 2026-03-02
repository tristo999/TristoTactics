# GameSFXManager - Bridges game events to sound effects via AudioManager.
extends Node

func _ready() -> void:
	EventBus.character_attacked.connect(_on_character_attacked)
	EventBus.character_died.connect(_on_character_died)
	EventBus.character_healed.connect(_on_character_healed)
	EventBus.character_movement_started.connect(_on_character_movement_started)
	EventBus.turn_started.connect(_on_turn_started)

## Play a character-specific SFX if available, otherwise the global default.
func _play_character_sfx(character: Node2D, action: String) -> void:
	if character.has_method("get_sfx"):
		var custom_path: String = character.get_sfx(action)
		if custom_path != "":
			AudioManager.play_sfx_from_path(custom_path)
			return
	AudioManager.play_sfx(action)

func _on_character_attacked(attacker: Node2D, target: Node2D, damage: int, is_crit: bool) -> void:
	_play_character_sfx(attacker, "attack")
	await get_tree().create_timer(0.1).timeout
	if is_crit:
		_play_character_sfx(attacker, "crit")
	elif damage <= 0:
		_play_character_sfx(attacker, "miss")
	else:
		_play_character_sfx(target, "hit")

func _on_character_died(character: Node2D) -> void:
	_play_character_sfx(character, "death")

func _on_character_healed(character: Node2D, _amount: int, _source: Node2D) -> void:
	_play_character_sfx(character, "heal")

func _on_character_movement_started(character: Node2D) -> void:
	_play_character_sfx(character, "move")

func _on_turn_started(character: Node2D) -> void:
	# Character-specific turn sound, else team-based default
	if character.has_method("get_sfx") and character.get_sfx("turn_start") != "":
		_play_character_sfx(character, "turn_start")
	else:
		var action := "enemy_turn" if character.team == Constants.TEAM_ENEMY else "turn_start"
		AudioManager.play_sfx(action)
