# CharacterData - Resource for defining character stats and properties
# Usage: Create .tres files in res://data/characters/ for each character type
class_name CharacterData
extends Resource

# =============================================================================
# BASIC INFO
# =============================================================================

@export var display_name: String = "Character"
@export var description: String = ""
@export_multiline var backstory: String = ""

# =============================================================================
# VISUALS
# =============================================================================

@export var portrait: Texture2D
@export var sprite_frames: SpriteFrames
@export var battle_sprite_scale: Vector2 = Vector2.ONE

# =============================================================================
# BASE STATS
# =============================================================================

@export_group("Stats")
@export var max_hp: int = 100
@export var max_mp: int = 50
@export var attack: int = 10
@export var defense: int = 5
@export var magic_attack: int = 10
@export var magic_defense: int = 5
@export var speed: int = 10  # Affects turn order
@export var luck: int = 5   # Affects crit chance, dodge, etc.

# =============================================================================
# MOVEMENT
# =============================================================================

@export_group("Movement")
@export var move_range: int = 5
@export var move_speed: float = 100.0  # Pixels per second for animation
@export var can_fly: bool = false
@export var can_swim: bool = false

# =============================================================================
# COMBAT
# =============================================================================

@export_group("Combat")
@export var attack_range_min: int = 1
@export var attack_range_max: int = 1
@export var crit_chance: float = 0.05  # 5% base crit

# =============================================================================
# ABILITIES
# =============================================================================

@export_group("Abilities")
@export var abilities: Array[Resource] = []  # Will be Array[AbilityData] when created

# =============================================================================
# GROWTH RATES (for leveling)
# =============================================================================

@export_group("Growth Rates", "growth_")
@export_range(0, 100) var growth_hp: int = 50
@export_range(0, 100) var growth_mp: int = 30
@export_range(0, 100) var growth_attack: int = 40
@export_range(0, 100) var growth_defense: int = 30
@export_range(0, 100) var growth_magic_attack: int = 40
@export_range(0, 100) var growth_magic_defense: int = 30
@export_range(0, 100) var growth_speed: int = 35
@export_range(0, 100) var growth_luck: int = 25

# =============================================================================
# RESISTANCES
# =============================================================================

@export_group("Resistances")
@export_range(-100, 100) var fire_resistance: int = 0
@export_range(-100, 100) var ice_resistance: int = 0
@export_range(-100, 100) var lightning_resistance: int = 0
@export_range(-100, 100) var poison_resistance: int = 0

# =============================================================================
# HELPER METHODS
# =============================================================================

## Calculate initiative for turn order (higher = goes first)
func get_initiative() -> int:
	return speed + (luck / 2)

## Get effective crit chance
func get_crit_chance() -> float:
	return crit_chance + (luck * 0.005)  # +0.5% per luck point
