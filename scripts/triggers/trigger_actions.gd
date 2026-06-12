# TriggerAct - the THEN vocabulary. Static factories that return action Callables
# of the form func(engine: TriggerEngine) -> void. Actions run in order and may
# be coroutines (the engine awaits each one), so a dialogue beat blocks the next
# action until the player dismisses it.
#
#   [TriggerAct.flash(Color(1,1,1,0.9)),
#    TriggerAct.say([["Vael", "...this is no drill!"]]),
#    TriggerAct.flip_team(TriggerCond.team("enemy_team"), Constants.TEAM_ALLY),
#    TriggerAct.set_flag("raid_started")]
class_name TriggerAct
extends RefCounted

## Play a dialogue sequence. rows = [[speaker, text], ...].
static func say(rows: Array) -> Callable:
	return func(eng) -> void: await eng.say(rows)

## Run any existing StoryEvent subclass as an action (reuses the 15 built types).
static func play_event(event: StoryEvent) -> Callable:
	return func(eng) -> void: await eng.play_event(event)

## Emit a StoryEvent on the bus (for listeners wired to story_event_triggered).
static func emit_story(event: StoryEvent) -> Callable:
	return func(_eng) -> void: EventBus.story_event_triggered.emit(event)

## Pause for `seconds` before the next action.
static func wait(seconds: float) -> Callable:
	return func(eng) -> void: await eng.wait(seconds)

## Full-screen color flash (up then down). Default = a white jolt.
static func flash(color: Color = Color(1, 1, 1, 0.9), up: float = 0.06, down: float = 0.5) -> Callable:
	return func(eng) -> void: await eng.flash(color, up, down)

## Fade the screen to black (keep = leave the overlay up, e.g. before a scene change).
static func fade_out(dur: float = 0.8, keep: bool = true) -> Callable:
	return func(eng) -> void: await eng.fade(1.0, dur, keep)

## Fade up from black and remove the overlay.
static func fade_in(dur: float = 0.8) -> Callable:
	return func(eng) -> void: await eng.fade(0.0, dur, false)

## Change scene (use after fade_out for a clean cut).
static func change_scene(path: String) -> Callable:
	return func(eng) -> void: eng.get_tree().change_scene_to_file(path)

## Set a blackboard flag (gates other triggers via TriggerCond.flag).
static func set_flag(name: String, value = true) -> Callable:
	return func(eng) -> void: eng.set_flag(name, value)

## Flip every CURRENTLY-ALIVE unit matching `who` onto `new_team` (the mid-battle
## defection — e.g. spar partners joining you when the raid hits). AI enemies flipped
## to ALLY stay AI-controlled but friendly; win/lose ignores allies.
static func flip_team(who: Callable, new_team: String) -> Callable:
	return func(eng) -> void:
		for n in eng.get_tree().get_nodes_in_group(Constants.GROUP_ALL_CHARACTERS):
			if who.call(n) and n.has_method("set_team"):
				n.set_team(new_team)

## Spawn a roster onto the active tilemap via BattleSpawner. Parent nodes are found
## on the current scene by name (PlayerTeam/EnemyTeam/AllyTeam by default — the
## tutorial-scene convention). Returns nothing; spawned units enter normal flow.
static func spawn(roster: Dictionary, player_parent: String = "PlayerTeam",
		enemy_parent: String = "EnemyTeam", ally_parent: String = "AllyTeam") -> Callable:
	return func(eng) -> void:
		var tm = eng.get_tree().get_first_node_in_group("tilemap")
		var root = eng.get_tree().current_scene
		if tm == null or root == null:
			push_error("[TriggerAct.spawn] missing tilemap or scene root.")
			return
		var pp = root.get_node_or_null(player_parent)
		var ep = root.get_node_or_null(enemy_parent)
		var ap = root.get_node_or_null(ally_parent)
		if pp == null or ep == null:
			push_error("[TriggerAct.spawn] could not find team parent nodes '%s'/'%s'." % [player_parent, enemy_parent])
			return
		BattleSpawner.spawn(tm, roster, pp, ep, ap)

## Run an arbitrary Callable — escape hatch for one-off scene logic that doesn't
## warrant a dedicated action. The callable may take 0 args or 1 (the engine).
static func call_fn(fn: Callable) -> Callable:
	return func(eng) -> void:
		# Await the call directly: calling an async callable without await is a
		# runtime error (4.6), and a stored coroutine state never resumes.
		# Awaiting a sync callable's return just resumes immediately.
		if fn.get_argument_count() >= 1:
			@warning_ignore("redundant_await")
			await fn.call(eng)
		else:
			@warning_ignore("redundant_await")
			await fn.call()

## Enable another trigger by id (arm a rule that was declared disabled).
static func enable(trigger_id: String) -> Callable:
	return func(eng) -> void:
		var t = eng.find_trigger(trigger_id)
		if t:
			t.enabled = true

## Disable another trigger by id (disarm a rule).
static func disable(trigger_id: String) -> Callable:
	return func(eng) -> void:
		var t = eng.find_trigger(trigger_id)
		if t:
			t.enabled = false
