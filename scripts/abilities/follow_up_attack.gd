# FollowUpAttack - the Archer's signature follow-up (Trigger.ALLY_ATTACKED_ENEMY).
# When a nearby ally attacks an enemy that's also within her shot window, she
# auto-chains a smaller shot at the same target. Two windows must both hold:
#   - partner link: owner within link_range_max of the attacking ally
#   - shot window:  target within owner's shot_range_min..shot_range_max
# Auto-fire, once per turn, offence-only.
class_name FollowUpAttack
extends FollowUp

## Follow-up damage = round(owner.attack_power * power_mult) - target.defense, min 1.
@export var power_mult: float = 0.6
## Shot window (owner -> target).
@export var shot_range_min: int = 1
@export var shot_range_max: int = 4
## Partner-link window (owner -> the attacking ally): they must be in concert.
@export var link_range_max: int = 2

func reacts_to() -> Trigger:
	return Trigger.ALLY_ATTACKED_ENEMY

func is_eligible(owner, ctx: Dictionary) -> bool:
	var attacker = ctx.get("attacker")
	var target = ctx.get("target")
	if owner == null or attacker == null or target == null:
		return false
	if owner == attacker or not owner.is_alive or not target.is_alive:
		return false
	if owner.team != attacker.team or target.team == owner.team:
		return false
	if owner.follow_up_used_this_turn:
		return false
	if _dist(owner.current_tile, attacker.current_tile) > link_range_max:
		return false                                       # not in concert
	var reach := _dist(owner.current_tile, target.current_tile)
	return reach >= shot_range_min and reach <= shot_range_max

func resolve(owner, ctx: Dictionary) -> void:
	var target = ctx.get("target")
	if target == null or not is_instance_valid(target) or not target.is_alive:
		return
	var crit: bool = randf() < owner.crit_chance
	var base: int = maxi(1, int(round(owner.attack_power * power_mult)) - int(target.defense))
	var dmg: int = base * 2 if crit else base
	owner.follow_up_used_this_turn = true
	owner._update_facing(target.global_position - owner.global_position)
	await AttackAnimationOverlay.play_attack_animation(owner, target, dmg, crit)
	target.take_damage(dmg, owner)
