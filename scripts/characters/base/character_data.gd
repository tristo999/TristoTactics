# CharacterData - Resource defining a complete character archetype.
# Assign to a CharacterBase via the Inspector. All stats, abilities, and
# visuals live here so new characters only require a .tres file — no code.
class_name CharacterData
extends Resource

@export_group("Identity")
@export var display_name: String = "Character"
@export var description: String = ""
@export var portrait: Texture2D

@export_group("Stats")
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

@export_group("Abilities")
## Abilities this character can use. Assign Ability .tres resources here.
@export var abilities: Array[Ability] = []

@export_group("Visuals")
## Idle spritesheet (480×320, 6 cols × 4 rows of 80×80 frames).
@export var idle_texture: Texture2D
## Walk spritesheet (same layout as idle).
@export var walk_texture: Texture2D

@export_group("AI")
@export var ai_pause_duration: float = 2.0

@export_group("Audio")
## Per-character sound effect overrides. Leave null to use global defaults.
@export var sfx: CharacterSFX
