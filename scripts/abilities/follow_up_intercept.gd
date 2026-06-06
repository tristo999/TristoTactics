# FollowUpIntercept - the dwarf's follow-up (Trigger.ALLY_ABOUT_TO_BE_HIT).
# A pre-damage redirect: when an enemy is about to strike an adjacent ally, a
# chance the dwarf jumps in and takes the hit instead. Decided by
# ComboSystem.get_interceptor() inside CharacterBase.attack_target *before* the
# swing, so the blow lands on (and is recomputed against) the dwarf. It does NOT
# use the generic resolve() path — it's a pre-event redirect, not a post-event
# reaction — but it reuses is_eligible(), rolls(), and bond_level_required.
class_name FollowUpIntercept
extends FollowUp

## "Next to": Chebyshev adjacency to the would-be victim (1 = the 8 surrounding
## tiles). Uses Chebyshev, not the game's Manhattan ranges, so diagonals count.
@export var adjacency: int = 1

func reacts_to() -> Trigger:
	return Trigger.ALLY_ABOUT_TO_BE_HIT

func is_eligible(owner, ctx: Dictionary) -> bool:
	var victim = ctx.get("victim")
	var attacker = ctx.get("attacker")
	if owner == null or victim == null or attacker == null:
		return false
	if owner == victim or not owner.is_alive:
		return false
	if not is_instance_valid(victim) or not victim.is_alive:
		return false
	if victim.team != owner.team:
		return false                       # only protect allies
	if attacker.team == owner.team:
		return false                       # the incoming hit must be hostile
	if owner.follow_up_used_this_turn:
		return false
	var cheb: int = maxi(absi(owner.current_tile.x - victim.current_tile.x), \
		absi(owner.current_tile.y - victim.current_tile.y))
	return cheb <= adjacency
