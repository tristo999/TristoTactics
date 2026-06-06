# FollowUp - base for tier-1 combo "follow-ups": automatic, reactive,
# character-specific micro-reactions that fire when a battle event matches their
# trigger. Subclass per behaviour (attack / heal / intercept / ...).
#
# The ComboSystem autoload dispatches each battle event to every living owner
# whose follow-up reacts to it, rolls `trigger_chance`, checks is_eligible(),
# and awaits resolve(). Adding a new follow-up = write a subclass + drop it on a
# CharacterData.follow_ups — no battle-flow edits (unless it needs a brand-new
# trigger moment, which means one new hook + a new Trigger enum value).
#
# `bond_level_required` reserves room for relationship-gated unlocks; it is NOT
# enforced yet (bonds aren't built).
class_name FollowUp
extends Resource

## Battle moments a follow-up can react to. Extend as new triggers are designed.
enum Trigger {
	ALLY_ATTACKED_ENEMY,    ## an allied unit landed an attack on an enemy
	ALLY_DAMAGED,           ## an allied unit took damage
	ALLY_ABOUT_TO_BE_HIT,   ## an allied unit is about to be hit (can redirect)
}

@export var display_name: String = "Follow-up"
@export var description: String = ""
## 1.0 = always fires when eligible; < 1.0 = rolls each time it could.
@export var trigger_chance: float = 1.0
## Future: relationship level needed to have unlocked this. 0 = always available.
@export var bond_level_required: int = 0

## Which battle event this reacts to. Override in subclasses.
func reacts_to() -> Trigger:
	return Trigger.ALLY_ATTACKED_ENEMY

## Can `owner` react to this event? `ctx` carries event data; its keys depend on
## the trigger (see ComboSystem). Override in subclasses.
func is_eligible(_owner, _ctx: Dictionary) -> bool:
	return false

## Perform the reaction (async-capable). Override in subclasses.
func resolve(_owner, _ctx: Dictionary) -> void:
	pass

## Roll the chance gate.
func rolls() -> bool:
	return trigger_chance >= 1.0 or randf() < trigger_chance

func _dist(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
