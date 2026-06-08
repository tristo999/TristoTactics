# TriggerCond - the WHEN vocabulary. Static factories that return condition
# Callables of the form func(event: Dictionary, engine: TriggerEngine) -> bool.
#
# Compose them with all_()/any_()/not_() and gate on flags. Unit-filter args take
# a Callable(node) -> bool — pass a preset by reference (TriggerCond.is_player) or
# use team()/named(). Omitting the filter (or passing an empty Callable) matches
# any unit.
#
#   TriggerCond.enters("pad", TriggerCond.is_player)
#   TriggerCond.all_([TriggerCond.died(TriggerCond.is_ally), TriggerCond.flag("raid_started")])
#   TriggerCond.turn_reached(3)
class_name TriggerCond
extends RefCounted

# --- Unit filters (pass by reference, e.g. TriggerCond.is_player) -----------

static func is_player(n) -> bool:
	return n is CharacterBase and (n as CharacterBase).team == Constants.TEAM_PLAYER

static func is_enemy(n) -> bool:
	return n is CharacterBase and (n as CharacterBase).team == Constants.TEAM_ENEMY

static func is_ally(n) -> bool:
	return n is CharacterBase and (n as CharacterBase).team == Constants.TEAM_ALLY

static func any_unit(n) -> bool:
	return n != null

## Filter by exact team string.
static func team(t: String) -> Callable:
	return func(n) -> bool: return n is CharacterBase and (n as CharacterBase).team == t

## Filter by character display name (CharacterData.character_name / node name).
static func named(unit_name: String) -> Callable:
	return func(n) -> bool:
		if n == null:
			return false
		if n.get("character_name") == unit_name:
			return true
		return n.name == unit_name

## Apply a (possibly empty) unit filter; an invalid/empty filter matches anything.
static func _accept(who: Callable, n) -> bool:
	return not who.is_valid() or who.call(n)

# --- Event conditions ------------------------------------------------------

## Bare event-type match, e.g. on("battle_started").
static func on(event_type: String) -> Callable:
	return func(e: Dictionary, _eng) -> bool: return e.get("type") == event_type

## A unit matching `who` enters the named region (its destination tile is inside).
static func enters(region_name: String, who: Callable = Callable()) -> Callable:
	return func(e: Dictionary, eng) -> bool:
		return e.get("type") == "moved" and _accept(who, e.get("who")) \
			and eng.in_region(e.get("to"), region_name)

## A unit matching `who` leaves the named region (was inside, now isn't).
static func leaves(region_name: String, who: Callable = Callable()) -> Callable:
	return func(e: Dictionary, eng) -> bool:
		return e.get("type") == "moved" and _accept(who, e.get("who")) \
			and eng.in_region(e.get("from"), region_name) \
			and not eng.in_region(e.get("to"), region_name)

## A unit matching `who` begins its turn.
static func turn_start(who: Callable = Callable()) -> Callable:
	return func(e: Dictionary, _eng) -> bool:
		return e.get("type") == "turn_started" and _accept(who, e.get("who"))

## The Nth turn (any unit) has started. Fires when the counter reaches `n`.
static func turn_reached(n: int) -> Callable:
	return func(e: Dictionary, _eng) -> bool:
		return e.get("type") == "turn_started" and e.get("turn", 0) == n

## A unit matching `who` died.
static func died(who: Callable = Callable()) -> Callable:
	return func(e: Dictionary, _eng) -> bool:
		return e.get("type") == "died" and _accept(who, e.get("who"))

## A unit matching `who` dealt an attack.
static func attacked(who: Callable = Callable()) -> Callable:
	return func(e: Dictionary, _eng) -> bool:
		return e.get("type") == "attacked" and _accept(who, e.get("who"))

## A unit matching `who` dropped to/below `pct` (0..1) of max HP (checked on damage).
static func hp_below(who: Callable, pct: float) -> Callable:
	return func(e: Dictionary, _eng) -> bool:
		if e.get("type") != "damaged":
			return false
		var c = e.get("who")
		if c == null or not _accept(who, c):
			return false
		var mx := float(c.get("max_hp"))
		if mx <= 0.0:
			return false
		return float(c.get("current_hp")) / mx <= pct

## Battle ended. victory: 1 = win only, 0 = loss only, -1 = either.
static func battle_end(victory: int = -1) -> Callable:
	return func(e: Dictionary, _eng) -> bool:
		if e.get("type") != "battle_ended":
			return false
		if victory == -1:
			return true
		return e.get("victory") == (victory == 1)

# --- Pure predicates (ignore the event; read engine state) -----------------

## True while a flag holds `value` (default true). Combine inside all_().
static func flag(name: String, value = true) -> Callable:
	return func(_e: Dictionary, eng) -> bool: return eng.get_flag(name) == value

# --- Combinators -----------------------------------------------------------

static func all_(conds: Array) -> Callable:
	return func(e: Dictionary, eng) -> bool:
		for c in conds:
			if not (c is Callable and c.call(e, eng)):
				return false
		return true

static func any_(conds: Array) -> Callable:
	return func(e: Dictionary, eng) -> bool:
		for c in conds:
			if c is Callable and c.call(e, eng):
				return true
		return false

static func not_(cond: Callable) -> Callable:
	return func(e: Dictionary, eng) -> bool: return not cond.call(e, eng)
