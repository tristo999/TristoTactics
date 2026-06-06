# FollowUpHeal - the Healer's follow-up (Trigger.ALLY_DAMAGED). When an ally
# (or herself) takes damage, a small chance she instantly mends a little of it,
# for free. Chance-gated and once per turn; only a nearby, still-living, not-full
# ally qualifies.
class_name FollowUpHeal
extends FollowUp

## Flat HP restored by the reactive heal.
@export var heal_amount: int = 4
## Must be within this many tiles of the hurt ally (Manhattan).
@export var heal_range_max: int = 4

func reacts_to() -> Trigger:
	return Trigger.ALLY_DAMAGED

func is_eligible(owner, ctx: Dictionary) -> bool:
	var victim = ctx.get("victim")
	if owner == null or victim == null or not is_instance_valid(victim):
		return false
	if not owner.is_alive or not victim.is_alive:
		return false
	if victim.team != owner.team:
		return false                          # only allies
	if victim.current_hp >= victim.max_hp:
		return false                          # already at full
	if owner.follow_up_used_this_turn:
		return false
	return _dist(owner.current_tile, victim.current_tile) <= heal_range_max

func resolve(owner, ctx: Dictionary) -> void:
	var victim = ctx.get("victim")
	if victim == null or not is_instance_valid(victim) or not victim.is_alive:
		return
	owner.follow_up_used_this_turn = true
	owner._update_facing(victim.global_position - owner.global_position)

	# Heal only up to what's missing so the cutscene never overstates the restore.
	var before: int = victim.current_hp
	victim.heal(heal_amount, owner)
	var restored: int = victim.current_hp - before
	if restored <= 0:
		return

	# Play the heal cutscene — same centered box as attacks, green "+N" rising.
	await AttackAnimationOverlay.play_heal_animation(owner, victim, restored)
