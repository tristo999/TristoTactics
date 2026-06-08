# Trigger - one declarative WHEN/THEN rule.
#
# A Trigger pairs a CONDITION (when does this fire?) with an ordered list of
# ACTIONS (what happens?). It is pure data: the TriggerEngine owns evaluation
# and execution. Build conditions with TriggerCond.* and actions with TriggerAct.*
#
#   var t := Trigger.new("borin_coach",
#       TriggerCond.enters("defensible_pad", TriggerCond.PLAYER),
#       [TriggerAct.say([["Borin", "Hold the pad — backs together!"]])])
#
# `condition` is a Callable(event: Dictionary, engine) -> bool.
# Each `action` is a Callable(engine) -> void and MAY be a coroutine (await is fine).
#
# NB: named TriggerRule (not Trigger) to avoid colliding with FollowUp.Trigger,
# the combo system's trigger-type enum.
class_name TriggerRule
extends RefCounted

## Stable id — used to enable/disable this trigger from other triggers, and in logs.
var id: String = ""

## Callable(event: Dictionary, engine: TriggerEngine) -> bool.
var condition: Callable = Callable()

## Ordered Callable(engine: TriggerEngine) list. Run sequentially; awaited if coroutine.
var actions: Array = []

## When true (default) the trigger disables itself the instant it fires (one-shot).
## Set false for rules that should keep reacting (e.g. "every time an ally falls").
var once: bool = true

## A disabled trigger is skipped during evaluation. Toggle via TriggerAct.enable/disable.
var enabled: bool = true

## Bookkeeping: how many times this trigger has fired.
var fired_count: int = 0

func _init(p_id: String = "", p_condition: Callable = Callable(), p_actions: Array = [], p_once: bool = true) -> void:
	id = p_id
	condition = p_condition
	actions = p_actions
	once = p_once
