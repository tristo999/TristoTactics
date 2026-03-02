# HealAbility - Restores HP to an allied target.
class_name HealAbility
extends Ability

@export var heal_amount: int = 10

func _init() -> void:
	ability_name = "Heal"
	description = "Restore HP to an ally."
	target_type = TargetType.ALLY
	range_min = 1
	range_max = 3

## Heal the target ally.
func execute(caster, target) -> Dictionary:
	if not can_use():
		return {"success": false, "reason": "no_uses_left"}

	var target_char: CharacterBase = target as CharacterBase
	if not target_char or not target_char.is_alive:
		return {"success": false, "reason": "invalid_target"}

	consume_use()

	var actual_heal := min(heal_amount, target_char.max_hp - target_char.current_hp)
	target_char.heal(actual_heal, caster)

	return {"success": true, "healed": actual_heal, "target": target_char.name}
