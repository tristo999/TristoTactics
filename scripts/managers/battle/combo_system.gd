# ComboSystem (autoload) - dispatches battle events to characters' tier-1
# follow-ups. Drop a FollowUp on a CharacterData.follow_ups and it just works;
# no per-scene wiring.
#
# Trigger wiring:
#   ALLY_ATTACKED_ENEMY  -> GameManager.request_attack: `await ComboSystem.on_attack()`
#   ALLY_DAMAGED         -> EventBus.character_damaged signal (handled here)
#   ALLY_ABOUT_TO_BE_HIT -> (future: the dwarf's intercept, a pre-damage hook)
#
# Follow-ups are capped at ONCE PER ROUND per character: a character's reaction
# budget refreshes only when its OWN turn starts (rides EventBus.turn_started).
# (Resetting every character on every turn made the cap meaningless — e.g. the
# healer could free-heal on nearly every incoming hit, an infinite-tank exploit.)
extends Node

func _ready() -> void:
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.character_damaged.connect(_on_character_damaged)

func _on_turn_started(character) -> void:
	if is_instance_valid(character) and character is CharacterBase:
		character.follow_up_used_this_turn = false

## Awaited by GameManager after a player attack lands.
func on_attack(attacker, target) -> void:
	await _dispatch(FollowUp.Trigger.ALLY_ATTACKED_ENEMY, {"attacker": attacker, "target": target})

func _on_character_damaged(victim, amount, source) -> void:
	await _dispatch(FollowUp.Trigger.ALLY_DAMAGED, {"victim": victim, "amount": amount, "source": source})

## Pre-damage redirect: find an ally who intercepts the incoming hit on `victim`
## (the dwarf's "take the hit instead"). Synchronous — called from attack_target
## before the swing. Returns the interceptor (already marked as having reacted
## this turn), or null if nobody intercepts.
func get_interceptor(attacker, victim) -> CharacterBase:
	for owner in get_tree().get_nodes_in_group(Constants.GROUP_ALL_CHARACTERS):
		if not is_instance_valid(owner) or not (owner is CharacterBase) or not owner.is_alive:
			continue
		for fu in owner.get_follow_ups():
			if not (fu is FollowUpIntercept):
				continue
			var ctx := {"attacker": attacker, "victim": victim}
			if fu.is_eligible(owner, ctx) and fu.rolls():
				owner.follow_up_used_this_turn = true
				return owner
	return null

func _dispatch(trigger: int, ctx: Dictionary) -> void:
	for owner in get_tree().get_nodes_in_group(Constants.GROUP_ALL_CHARACTERS):
		if not is_instance_valid(owner) or not (owner is CharacterBase) or not owner.is_alive:
			continue
		for fu in owner.get_follow_ups():
			if fu == null or fu.reacts_to() != trigger:
				continue
			if fu.is_eligible(owner, ctx) and fu.rolls():
				await fu.resolve(owner, ctx)
