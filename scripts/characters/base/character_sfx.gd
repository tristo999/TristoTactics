# CharacterSFX - Per-character sound effect overrides.
# Any key left empty falls back to the default global SFX.
class_name CharacterSFX
extends Resource

@export_group("Movement")
@export_file("*.wav", "*.ogg", "*.mp3") var move: String = ""

@export_group("Combat")
@export_file("*.wav", "*.ogg", "*.mp3") var attack: String = ""
@export_file("*.wav", "*.ogg", "*.mp3") var hit: String = ""
@export_file("*.wav", "*.ogg", "*.mp3") var crit: String = ""
@export_file("*.wav", "*.ogg", "*.mp3") var miss: String = ""

@export_group("Status")
@export_file("*.wav", "*.ogg", "*.mp3") var death: String = ""
@export_file("*.wav", "*.ogg", "*.mp3") var heal: String = ""
@export_file("*.wav", "*.ogg", "*.mp3") var turn_start: String = ""

## Returns the SFX path for a given action key, or "" for no override.
func get_sfx(action: String) -> String:
	match action:
		"move": return move
		"attack": return attack
		"hit": return hit
		"crit": return crit
		"miss": return miss
		"death": return death
		"heal": return heal
		"turn_start": return turn_start
	return ""
