# FollowUpAbility - the signature "follow-up" combo, modeled as a reactive strike.
# When an allied unit attacks an enemy, an eligible follower chains a free
# follow-up strike on the same target. Assign one to CharacterData.follow_up.
#
# First-spike rule (the opt-in trigger + UI live in the battle layer, not here):
#   - follower must be a living ally of the attacker (and not the attacker)
#   - the target must be reachable from where the follower stands
#     (within this follow-up's range_min..range_max)
#   - free, but once per follower per turn (CharacterBase.follow_up_used_this_turn)
#   - offense-only
class_name FollowUpAbility
extends Ability

## Flavor — "reach" (ranged finisher, e.g. the Archer) or "shape" (protector who
## closes in, e.g. the dwarf). Cosmetic for now; drives presentation later.
@export var flavor: String = "reach"

## Follow-up damage = round(follower.attack_power * power_mult) - target.defense,
## min 1. Usually a touch weaker than a full attack.
@export var power_mult: float = 0.75

func _init() -> void:
	target_type = TargetType.ENEMY

## Can `follower` chain a follow-up off `attacker`'s strike on `target`?
func is_eligible(follower: CharacterBase, attacker: CharacterBase, target: CharacterBase) -> bool:
	if follower == null or attacker == null or target == null:
		return false
	if follower == attacker or not follower.is_alive or not target.is_alive:
		return false
	if follower.team != attacker.team:
		return false            # follower must be an ally of the attacker
	if target.team == follower.team:
		return false            # target must be hostile to the follower
	if follower.follow_up_used_this_turn:
		return false            # once per turn
	var dist := absi(follower.current_tile.x - target.current_tile.x) \
		+ absi(follower.current_tile.y - target.current_tile.y)
	return dist >= range_min and dist <= range_max   # positioned to reach

## Resolve the follow-up strike. Does NOT consume the follower's normal action;
## consumes the once-per-turn follow-up instead. Async (plays the hit overlay).
func perform(follower: CharacterBase, target: CharacterBase) -> Dictionary:
	var crit := randf() < follower.crit_chance
	var base := maxi(1, int(round(follower.attack_power * power_mult)) - target.defense)
	var dmg := base * 2 if crit else base
	follower.follow_up_used_this_turn = true
	follower._update_facing(target.global_position - follower.global_position)
	await AttackAnimationOverlay.play_attack_animation(follower, target, dmg, crit)
	target.take_damage(dmg, follower)
	return {"success": true, "damage": dmg, "is_crit": crit}
