# GoblinCharacter - Fast, aggressive melee enemy
# Small and quick with high initiative, but low HP and defense.
extends EnemyCharacter
class_name GoblinCharacter

func _init() -> void:
	max_hp = 15
	attack_power = 7
	defense = 3
	initiative = 8
	crit_chance = 0.10
	move_speed = 130.0
	move_range = 6
	attack_range_min = 1
	attack_range_max = 1
	ai_pause_duration = 0.8
