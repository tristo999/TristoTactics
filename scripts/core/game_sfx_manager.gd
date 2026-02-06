# GameSFXManager - Bridges game events to sound effects
# Listens to EventBus signals and triggers appropriate SFX via MusicManager.
# Characters with a CharacterSFX resource get their own unique sounds;
# otherwise the global defaults from MusicManager.sound_effects are used.
extends Node

func _ready() -> void:
	# Combat events
	EventBus.character_attacked.connect(_on_character_attacked)
	EventBus.character_damaged.connect(_on_character_damaged)
	EventBus.character_died.connect(_on_character_died)
	EventBus.character_healed.connect(_on_character_healed)
	
	# Movement events
	EventBus.character_movement_started.connect(_on_character_movement_started)
	
	# Turn flow events
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.battle_ended.connect(_on_battle_ended)

## Play a sound for a specific action on a character.
## Checks for a character-specific override first, then falls back to the
## global SFX key registered in MusicManager.
func _play_character_sfx(character: Node2D, action: String) -> void:
	# Check for per-character override
	if character.has_method("get_sfx"):
		var custom_path: String = character.get_sfx(action)
		if custom_path != "":
			_play_sfx_path(custom_path)
			return
	# Fall back to global default
	MusicManager.play_sfx(action)

## Directly play an SFX from a file path (for character overrides)
func _play_sfx_path(path: String) -> void:
	MusicManager.play_sfx_from_path(path)

# -- Combat SFX --

func _on_character_attacked(attacker: Node2D, target: Node2D, damage: int, is_crit: bool) -> void:
	# Play the attacker's swing/attack sound
	_play_character_sfx(attacker, "attack")
	
	# Slight delay then play impact sound (uses target's sounds)
	await get_tree().create_timer(0.1).timeout
	if is_crit:
		_play_character_sfx(attacker, "crit")
	elif damage <= 0:
		_play_character_sfx(attacker, "miss")
	else:
		_play_character_sfx(target, "hit")

func _on_character_damaged(_character: Node2D, _amount: int, _source: Node2D) -> void:
	# Hit sound is already handled by _on_character_attacked
	# This signal fires for non-attack damage sources too (poison, traps, etc.)
	pass

func _on_character_died(character: Node2D) -> void:
	_play_character_sfx(character, "death")

func _on_character_healed(character: Node2D, _amount: int, _source: Node2D) -> void:
	_play_character_sfx(character, "heal")

# -- Movement SFX --

func _on_character_movement_started(character: Node2D) -> void:
	_play_character_sfx(character, "move")

# -- Turn Flow SFX --

func _on_turn_started(character: Node2D) -> void:
	# Check for character-specific turn start sound first
	if character.has_method("get_sfx") and character.get_sfx("turn_start") != "":
		_play_character_sfx(character, "turn_start")
	else:
		# Use team-based default
		var action := "enemy_turn" if character.team == Constants.TEAM_ENEMY else "turn_start"
		MusicManager.play_sfx(action)

func _on_battle_ended(_victory: bool) -> void:
	# Victory/defeat music is handled by MusicManager already
	pass
	pass
