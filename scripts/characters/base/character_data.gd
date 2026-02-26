# CharacterData - Resource for character identity, stats, and audio overrides
# Assign to a CharacterBase via the Inspector to define a complete unit archetype.
# Stats set here override the defaults on CharacterBase.
class_name CharacterData
extends Resource

@export_group("Identity")
@export var display_name: String = "Character"
@export var description: String = ""
@export var portrait: Texture2D

@export_group("Stats")
## Set to true to apply the stat overrides below. When false, the character
## uses its script-level @export defaults (backward compatible).
@export var override_stats: bool = false
@export var max_hp: int = 25
@export var attack_power: int = 10
@export var defense: int = 5
@export var initiative: int = 10
@export var crit_chance: float = 0.05

@export_group("Movement")
@export var move_speed: float = 100.0
@export var move_range: int = 5

@export_group("Attack Range")
@export var attack_range_min: int = 1
@export var attack_range_max: int = 1

@export_group("AI")
@export var ai_pause_duration: float = 2.0

## Per-character sound effect overrides. Leave null to use global defaults.
@export_group("Audio")
@export var sfx: CharacterSFX
