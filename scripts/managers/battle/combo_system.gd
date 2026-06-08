# ComboSystem (autoload) - resolves characters' tier-1 follow-ups (reactive combo
# abilities). Drop a FollowUp on a CharacterData.follow_ups and it just works; no
# per-scene wiring.
#
# REACTION STACK (everything is sequential):
#   Battle events don't resolve follow-ups inline — they PUSH a reaction onto a stack.
#   The battle flow DRAINS the stack with `await resolve_reactions()` at each
#   action-completion point (after a player attack, an enemy attack, an ability).
#   Reactions resolve one at a time (each resolve() is awaited), LIFO: a reaction
#   triggered BY another reaction (e.g. a chained shot deals damage) resolves before
#   older pending entries — depth-first, so a chain feels immediate. This is why two
#   follow-ups never play their animations on top of each other.
#
#   Triggers:
#     ALLY_ATTACKED_ENEMY  -> pushed via notify_attack() (a player attack landed)
#     ALLY_DAMAGED         -> pushed from the character_damaged signal (any damage)
#     ALLY_ABOUT_TO_BE_HIT -> NOT stacked; resolved synchronously pre-hit via
#                             get_interceptor() (the dwarf takes the blow instead)
#
# Follow-ups are capped ONCE PER ROUND per character: a character's reaction budget
# refreshes only when its OWN turn starts (rides EventBus.turn_started). This also
# bounds cascades — a unit can't react repeatedly within one drain.
extends Node

## Pending reactions: each is [trigger:int, ctx:Dictionary]. Resolved LIFO.
var _stack: Array = []
## True while draining, so a re-entrant resolve_reactions() is a no-op (the outer
## loop already owns the stack).
var _resolving: bool = false

func _ready() -> void:
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.character_damaged.connect(_on_character_damaged)

func _on_turn_started(character) -> void:
	if is_instance_valid(character) and character is CharacterBase:
		character.follow_up_used_this_turn = false

# --- Pushing reactions -----------------------------------------------------

## An allied unit landed an attack on an enemy — push the chain-strike trigger.
## Call after a successful attack; the flow then drains via resolve_reactions().
func notify_attack(attacker, target) -> void:
	_push(FollowUp.Trigger.ALLY_ATTACKED_ENEMY, {"attacker": attacker, "target": target})

## A unit took damage (any source). Pushed, not resolved inline, so the reaction
## plays in sequence when the flow drains — never concurrently with the hit.
func _on_character_damaged(victim, amount, source) -> void:
	_push(FollowUp.Trigger.ALLY_DAMAGED, {"victim": victim, "amount": amount, "source": source})

func _push(trigger: int, ctx: Dictionary) -> void:
	_stack.append([trigger, ctx])

# --- Draining (the sequential pipeline) ------------------------------------

## Resolve every pending reaction, one at a time (awaited), LIFO. Reactions pushed
## while draining (cascades) are resolved before older entries. Safe to call when
## the stack is empty (fast no-op). Awaited at each action-completion point.
func resolve_reactions() -> void:
	if _resolving:
		return
	_resolving = true
	while not _stack.is_empty():
		var item: Array = _stack.pop_back()
		await _dispatch(item[0], item[1])
	_resolving = false

# --- Synchronous pre-hit interception (not stacked) ------------------------

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

# --- Resolving one trigger across all eligible owners ----------------------

func _dispatch(trigger: int, ctx: Dictionary) -> void:
	for owner in get_tree().get_nodes_in_group(Constants.GROUP_ALL_CHARACTERS):
		if not is_instance_valid(owner) or not (owner is CharacterBase) or not owner.is_alive:
			continue
		for fu in owner.get_follow_ups():
			if fu == null or fu.reacts_to() != trigger:
				continue
			if fu.is_eligible(owner, ctx) and fu.rolls():
				await fu.resolve(owner, ctx)
