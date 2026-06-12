# TriggerEngine - the WHEN/THEN runtime for a level.
#
# Add one as a child of a level, declare REGIONS and TRIGGERS in _ready, and the
# engine wires itself to EventBus, normalizes every gameplay event into a small
# Dictionary, evaluates each trigger's condition, and runs the matching actions.
# This turns scripted beats from hand-wired signal spaghetti into declared rules:
#
#   func _ready() -> void:
#       var tr := TriggerEngine.new()
#       add_child(tr)
#       tr.region("defensible_pad", Rect2i(16, 12, 8, 5))
#       tr.add("borin_coach",
#           TriggerCond.enters("defensible_pad", TriggerCond.PLAYER),
#           [TriggerAct.say([["Borin", "Backs to the pad!"]])])
#       tr.add("raid_breaches",
#           TriggerCond.turn_reached(3),
#           [TriggerAct.flash(Color(1,1,1,0.9)), TriggerAct.spawn(RAID_ROSTER)])
#
# Conditions are built with TriggerCond.*, actions with TriggerAct.* — see those
# files for the full vocabulary. Regions are named Rect2i areas (one or many per
# name); flags are a string->Variant blackboard for cross-trigger state.
#
# EVENT SHAPE (the Dictionary passed to conditions), keyed by "type":
#   battle_started   {}
#   battle_ended     {victory:bool}
#   turn_started     {who:CharacterBase, turn:int}
#   turn_ended       {who:CharacterBase, turn:int}
#   moved            {who:Node2D, from:Vector2i, to:Vector2i}
#   attacked         {who:Node2D, target:Node2D, damage:int, crit:bool}
#   damaged          {who:Node2D, amount:int, source:Node2D}
#   healed           {who:Node2D, amount:int, source:Node2D}
#   died             {who:Node2D}
#   ability_used     {who:Node2D, target:Node2D, ability:Ability}
#   flag_changed     {flag:String, value:Variant}   (internal — lets flag changes re-eval triggers)
class_name TriggerEngine
extends Node

## Emitted whenever a trigger fires (after it begins running its actions).
signal trigger_fired(id: String)

## name -> Array[Rect2i]. A region can be several rectangles.
var _regions: Dictionary = {}
## String -> Variant blackboard shared across triggers.
var _flags: Dictionary = {}
var _triggers: Array[TriggerRule] = []

## Turn counter (1-based; incremented on each turn_started).
var _turn: int = 0

# Action execution is serialized so two dialogue beats never overlap. Events that
# match while a trigger is mid-await are queued and run in order.
var _busy: bool = false
var _queue: Array = []   # Array of [TriggerRule, event]

## Lazily-created full-screen layer for flash/fade actions.
var _fx: CanvasLayer = null

func _ready() -> void:
	EventBus.battle_started.connect(func() -> void: _dispatch({"type": "battle_started"}))
	EventBus.battle_ended.connect(func(v: bool) -> void: _dispatch({"type": "battle_ended", "victory": v}))
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.turn_ended.connect(func(c) -> void: _dispatch({"type": "turn_ended", "who": c, "turn": _turn}))
	EventBus.character_moved.connect(func(c, f, t) -> void: _dispatch({"type": "moved", "who": c, "from": f, "to": t}))
	EventBus.character_attacked.connect(func(a, t, d, cr) -> void: _dispatch({"type": "attacked", "who": a, "target": t, "damage": d, "crit": cr}))
	EventBus.character_damaged.connect(func(c, a, s) -> void: _dispatch({"type": "damaged", "who": c, "amount": a, "source": s}))
	EventBus.character_healed.connect(func(c, a, s) -> void: _dispatch({"type": "healed", "who": c, "amount": a, "source": s}))
	EventBus.character_died.connect(func(c) -> void: _dispatch({"type": "died", "who": c}))
	EventBus.ability_used.connect(func(c, t, ab) -> void: _dispatch({"type": "ability_used", "who": c, "target": t, "ability": ab}))

func _on_turn_started(c) -> void:
	_turn += 1
	_dispatch({"type": "turn_started", "who": c, "turn": _turn})

# --- Authoring API ---------------------------------------------------------

## Define (or extend) a named region. `area` may be a Rect2i or an Array[Rect2i].
## Tiles are in the BaseGrid's cell coordinates. Call multiple times to add rects.
func region(region_name: String, area) -> void:
	if not _regions.has(region_name):
		_regions[region_name] = []
	if area is Rect2i:
		_regions[region_name].append(area)
	elif area is Array:
		for r in area:
			if r is Rect2i:
				_regions[region_name].append(r)

## Declare a trigger. Returns the TriggerRule so callers can tweak (.once = false, etc.).
func add(id: String, condition: Callable, actions: Array, once: bool = true) -> TriggerRule:
	var t := TriggerRule.new(id, condition, actions, once)
	_triggers.append(t)
	return t

## Add a pre-built TriggerRule (e.g. from a shared library).
func add_trigger(t: TriggerRule) -> TriggerRule:
	_triggers.append(t)
	return t

# --- Queries used by conditions/actions ------------------------------------

## True if `tile` falls inside any rect of the named region.
func in_region(tile: Vector2i, region_name: String) -> bool:
	if not _regions.has(region_name):
		return false
	for r in _regions[region_name]:
		if (r as Rect2i).has_point(tile):
			return true
	return false

func get_flag(flag_name: String, default = null) -> Variant:
	return _flags.get(flag_name, default)

func set_flag(flag_name: String, value = true) -> void:
	if _flags.get(flag_name) == value:
		return
	_flags[flag_name] = value
	# Let flag-gated triggers re-evaluate immediately (no event needed).
	_dispatch({"type": "flag_changed", "flag": flag_name, "value": value})

func find_trigger(id: String) -> TriggerRule:
	for t in _triggers:
		if t.id == id:
			return t
	return null

func current_turn() -> int:
	return _turn

# --- Evaluation / execution ------------------------------------------------

func _dispatch(event: Dictionary) -> void:
	for t in _triggers:
		if not t.enabled or not t.condition.is_valid():
			continue
		if t.condition.call(event, self):
			_queue.append([t, event])
	if not _busy:
		_run_queue()

func _run_queue() -> void:
	_busy = true
	while not _queue.is_empty():
		var pair = _queue.pop_front()
		var t: TriggerRule = pair[0]
		if not t.enabled:
			continue
		# Disable BEFORE running so a re-entrant matching event can't double-fire it.
		if t.once:
			t.enabled = false
		t.fired_count += 1
		trigger_fired.emit(t.id)
		for action in t.actions:
			if action is Callable and action.is_valid():
				# Await the CALL directly. Storing the coroutine state and awaiting
				# it later silently never resumes (caught by the level-1 autoplay:
				# the breach hung after its flash completed). Awaiting a sync
				# action's null return just resumes immediately — exactly right.
				@warning_ignore("redundant_await")
				await action.call(self)
	_busy = false

# --- Helpers used by TriggerAct actions ------------------------------------

func base_layer() -> TileMapLayer:
	var tm = get_tree().get_first_node_in_group("tilemap")
	return tm.get_node_or_null("BaseGrid") as TileMapLayer if tm else null

func tile_to_world(tile: Vector2i) -> Vector2:
	var b := base_layer()
	return b.to_global(b.map_to_local(tile)) if b else Vector2.ZERO

func fx_layer() -> CanvasLayer:
	if _fx == null or not is_instance_valid(_fx):
		_fx = CanvasLayer.new()
		_fx.layer = 120
		add_child(_fx)
	return _fx

# These wrap CineFx so TriggerAct actions (which call eng.say/flash/fade/wait) and
# the bespoke directors all share one implementation.
func say(rows: Array) -> void:
	await CineFx.say(get_tree(), rows)

func wait(seconds: float) -> void:
	await CineFx.wait(get_tree(), seconds)

func flash(color: Color, up: float, down: float) -> void:
	await CineFx.flash(fx_layer(), color, up, down)

func fade(to_alpha: float, dur: float, keep: bool = true) -> void:
	await CineFx.fade(fx_layer(), to_alpha, dur, keep)

## Run any existing StoryEvent (DialogueEvent, FlashEvent, FogEvent, ...). This is
## how the engine reuses the 15 built event types as trigger actions.
func play_event(event: StoryEvent) -> void:
	if event == null:
		return
	await event.execute(get_tree())
