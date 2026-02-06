# CharacterSFX - Resource for per-character sound effect overrides
# Assign to a CharacterData to give that character unique sounds.
# Any key left empty falls back to the default global SFX.
#
# Usage: Create .tres files in res://data/sfx/ for each character archetype,
#        e.g. "horse_sfx.tres" with move = "res://assets/audio/sfx/horse_clomp.wav"
class_name CharacterSFX
extends Resource

# =============================================================================
# MOVEMENT
# =============================================================================

@export_group("Movement")
## Sound played when this character starts moving (e.g. footsteps, hooves, slithering)
@export_file("*.wav", "*.ogg", "*.mp3") var move: String = ""

# =============================================================================
# COMBAT
# =============================================================================

@export_group("Combat")
## Sound played when this character attacks (swing, cast, bite, etc.)
@export_file("*.wav", "*.ogg", "*.mp3") var attack: String = ""
## Sound played when this character lands a hit
@export_file("*.wav", "*.ogg", "*.mp3") var hit: String = ""
## Sound played when this character lands a critical hit
@export_file("*.wav", "*.ogg", "*.mp3") var crit: String = ""
## Sound played when this character misses
@export_file("*.wav", "*.ogg", "*.mp3") var miss: String = ""

# =============================================================================
# STATUS
# =============================================================================

@export_group("Status")
## Sound played when this character dies
@export_file("*.wav", "*.ogg", "*.mp3") var death: String = ""
## Sound played when this character is healed
@export_file("*.wav", "*.ogg", "*.mp3") var heal: String = ""
## Sound played when this character's turn starts
@export_file("*.wav", "*.ogg", "*.mp3") var turn_start: String = ""

# =============================================================================
# HELPER
# =============================================================================

## Returns the character-specific SFX path for a given action key,
## or an empty string if no override is set (caller should use default).
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
