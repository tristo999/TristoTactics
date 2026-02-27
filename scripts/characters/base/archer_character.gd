# ArcherCharacter - Ranged player unit
# Keeps distance and attacks from afar. Low HP and defense, but long attack range.
extends PlayerCharacter
class_name ArcherCharacter

func _init() -> void:
	max_hp = 18
	attack_power = 8
	defense = 3
	initiative = 12
	crit_chance = 0.08
	move_speed = 90.0
	move_range = 4
	attack_range_min = 1
	attack_range_max = 4
