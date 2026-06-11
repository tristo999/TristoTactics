## Training Grounds — Beat 2 as ONE continuous scene: drill -> breach -> raid.
## Design: docs/levels/training_grounds.md · Script: docs/opening_script.md (Scene 5+6).
##
## CONTROL MODEL: the player controls ONLY THE HERO. Everyone else is scripted:
## Borin = parked enemy (the willing strike target), Elena = parked ally (her
## follow-up chains live), recruits drill in the background, Lyra arrives for the
## mend lesson. At the breach everything unparks, Borin flips to ally (set_team,
## live), three raid groups spawn at the north breaches, and the drill becomes
## the raid with no cut.
##
## The DRILL is a sequential coroutine (a linear lesson plan reads best as one);
## the BREACH/RAID orchestration runs on the TriggerEngine (regions, spawn, barks).
extends BaseLevel

const ROSTER := {
	"1": {"data": "res://data/characters/hero.tres", "name": "Hero"},
	"2": {"data": "res://data/characters/archer.tres", "name": "Elena", "team": "ally"},
	"3": {"data": "res://data/characters/dwarf.tres", "name": "Borin", "team": "enemy"},
	"5": {"data": "res://data/characters/hero.tres", "name": "Recruit Sten", "team": "ally"},
	"6": {"data": "res://data/characters/hero.tres", "name": "Recruit Wynn", "team": "ally"},
	"7": {"data": "res://data/characters/hero.tres", "name": "Recruit Bram", "team": "ally"},
}
const LYRA := {"4": {"data": "res://data/characters/healer.tres", "name": "Lyra", "team": "ally"}}
const RAIDERS := {"E": {"data": "res://data/characters/goblin.tres", "name": "Insurgent"}}

var _gm: Node
var _tm: Node
var _engine: TriggerEngine
var _action_bar: Node
var _prompt: Control
var _fx: CanvasLayer
var _hero: CharacterBase
var _elena: CharacterBase
var _borin: CharacterBase
var _drill_done := false
## Current lesson gate (move/attack/end_turn) — re-applied every player turn,
## because the action bar re-enables its buttons on turn start.
var _gate_state := [true, false, true]

func _ready() -> void:
	music_key = ""   # the drill is ambient; battle music ENTERS at the breach
	_spawn_roster()
	_gm = $GameManager
	if _gm:
		_gm.intro_event = null
		_gm.victory_event = _victory_coda()
		_gm.player_goes_first = true
	super._ready()
	call_deferred("_begin")

func _spawn_roster() -> void:
	_tm = get_tree().get_first_node_in_group("tilemap")
	if _tm == null:
		push_error("[TrainingGrounds] no tilemap.")
		return
	var units: Array = BattleSpawner.spawn(_tm, ROSTER, $PlayerTeam, $EnemyTeam, $AllyTeam)
	for u in units:
		if u is EnemyCharacter:
			(u as EnemyCharacter).ai_enabled = false   # park: the drill owns the turn flow
		if u.name == "Elena": _elena = u
		elif u.name == "Borin": _borin = u
		elif u is PlayerCharacter: _hero = u

func _begin() -> void:
	await get_tree().process_frame
	_action_bar = get_tree().get_first_node_in_group("action_bar")
	_prompt = get_tree().get_first_node_in_group("tutorial_prompt")
	_fx = CanvasLayer.new()
	_fx.layer = 120
	add_child(_fx)
	EventBus.turn_started.connect(_on_turn_started)
	_setup_engine()
	await _camera_handover()
	_run_drill()

## Re-apply the current lesson gate each player turn (the bar re-enables itself).
func _on_turn_started(c: CharacterBase) -> void:
	if _drill_done or c == null or c.team != Constants.TEAM_PLAYER:
		return
	await get_tree().process_frame
	_apply_gate()

## The one register change in the opening: ease WALK 2.0 -> BATTLE 4.0 while the
## HUD is appearing — the deliberate "it becomes a tactics game" beat.
func _camera_handover() -> void:
	var cam := get_tree().get_first_node_in_group("action_camera") as Camera2D
	if cam == null or _hero == null:
		return
	cam.global_position = _hero.global_position
	cam.zoom = Vector2(2.0, 2.0)
	await get_tree().create_timer(0.4).timeout
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(cam, "zoom", Vector2(4.0, 4.0), 1.2)
	await tw.finished

# ---------------------------------------------------------------------------
# THE DRILL — a linear lesson plan, so it reads as one sequential script.
# ---------------------------------------------------------------------------
func _run_drill() -> void:
	await get_tree().create_timer(0.4).timeout

	# LESSON 1 — MOVE (the footwork course, SW of the gate)
	await _say([
		["Vael", "First things first. Let's see whether the circle sent us a soldier or a sack of turnips."],
		["Vael", "Ground first — the chalked course, there. Walk it."],
	])
	_gate(true, false, true)
	_show("Select Move and reach the chalked footwork course (south-west). End Turn if you run out of steps.")
	await _until_region("footwork_course")
	_hide()

	# LESSON 2 — STRIKE (cross the yard to Borin at the dummy lane)
	await _say([
		["Borin", "Over here, lad! Mind the dummies — they're shy."],
		["Vael", "Now cross the yard and put steel on Borin. He insists."],
	])
	_gate(true, true, true)
	_show("Reach Borin at the dummy lane (east) and Attack him.")
	await _until_player_attack()
	_hide()
	await _say([["Borin", "HA! Good weight! Felt that in me teeth."]])

	# LESSON 3 — COVER (Borin steps behind a tarped stack; hit him again)
	var cover_tile := _find_cover_near(_borin)
	if cover_tile != Constants.INVALID_TILE and _borin:
		_borin.move_to_tile(cover_tile)
		await _borin.movement_finished
		await _say([
			["Borin", "Again — but watch: behind the stacks, half of you disappears."],
			["Vael", "Cover. Ground that shields is worth two soldiers. Strike him through it — feel the difference."],
		])
		_show("Borin is in cover (+2 DEF). Attack him again — the number drops.")
		await _until_player_attack()
		_hide()
		await _say([["Vael", "Smaller bite, yes? Remember that when it's YOU standing in the open."]])

	# LESSON 4 — TOGETHER (the pit: Elena at your shoulder, the follow-up, live)
	if _borin:
		_borin.move_to_tile(Vector2i(24, 18))   # pit floor
		await _borin.movement_finished
	if _elena:
		_elena.move_to_tile(Vector2i(21, 18))   # pit edge — inside her link range
		await _elena.movement_finished
	await _say([
		["Vael", "Last lesson, and it's the one that matters. Alone you're a blade. Beside someone, you're a squad."],
		["Vael", "Into the pit. Stand by Elena. Strike — and watch her."],
	])
	_engine.set_flag("lesson_together", true)
	_show("Enter the pit, stand NEAR Elena, and strike Borin.")
	var chained := await _strike_and_watch_for_chain()
	_hide()
	if chained:
		await _say([
			["Elena", "...clear. — w-was that... did I overdo— Borin I'm so sorry—"],
			["Borin", "That's the thing! That's the whole war, right there!"],
			["Vael", "A follow-up. Stand close, move in concert, answer each other's strikes. Learn nothing else today, learn that."],
		])
	else:
		await _say([
			["Vael", "Mark this — had you stood AT her shoulder, she'd have answered your strike with her own. A follow-up."],
			["Vael", "Stand close, move in concert. You'll lean on it before the morning's ou—"],
		])

	# LESSON 5 — MEND (Lyra arrives, fusses over Borin's bruises)
	var lyra_units: Array = BattleSpawner.spawn(_tm, LYRA, $PlayerTeam, $EnemyTeam, $AllyTeam)
	if _gm and not lyra_units.is_empty():
		_gm.register_units(lyra_units)
		var lyra := lyra_units[0] as CharacterBase
		if lyra is EnemyCharacter:
			(lyra as EnemyCharacter).ai_enabled = false
		lyra.move_to_tile(Vector2i(23, 19))
		await lyra.movement_finished
		var missing: int = _borin.max_hp - _borin.current_hp if _borin else 0
		if _borin and missing > 0:
			_borin.heal(missing, lyra)
			await AttackAnimationOverlay.play_heal_animation(lyra, _borin, missing)
		await _say([
			["Lyra", "—and by its light be mended. Honestly, you ASK them to hit you—"],
			["Borin", "It's instructional!"],
		])

	# THE BREACH — the drill ends mid-sentence.
	_drill_done = true
	_engine.set_flag("drill_done", true)   # the engine takes it from here

# ---------------------------------------------------------------------------
# THE BREACH + RAID — declared on the TriggerEngine.
# ---------------------------------------------------------------------------
func _setup_engine() -> void:
	_engine = TriggerEngine.new()
	add_child(_engine)
	# Regions (BaseGrid cell coords; see docs/levels/training_grounds.md)
	_engine.region("footwork_course", Rect2i(9, 22, 8, 6))
	_engine.region("the_pit", Rect2i(20, 16, 8, 6))
	_engine.region("lane_w", Rect2i(6, 6, 9, 10))
	_engine.region("lane_c", Rect2i(18, 6, 9, 8))
	_engine.region("lane_e", Rect2i(30, 6, 9, 9))

	# WHEN the drill wraps, THEN the raid breaks in (one continuous scene).
	_engine.add("the_breach",
		TriggerCond.flag("drill_done"),
		[TriggerAct.flash(Color(1, 1, 1, 0.9), 0.06, 0.5),
		 TriggerAct.wait(0.35),
		 TriggerAct.say([["Vael", "...Those aren't ours."]]),
		 TriggerAct.call_fn(_do_breach),
		 TriggerAct.say([
			["Vael", "Insurgents — through the north fence! All three gaps! This is no drill!"],
			["Vael", "Recruits — the muster line! Elena, your lane! Borin — WITH the champion now! MOVE!"],
		 ])])

	# Lane first-contact barks (standing flavor, once each).
	_engine.add("bark_w", TriggerCond.all_([TriggerCond.enters("lane_w", TriggerCond.is_enemy), TriggerCond.flag("raid_started")]),
		[TriggerAct.say([["Elena", "...west lane is mine. Nothing gets past."]])])
	_engine.add("bark_e", TriggerCond.all_([TriggerCond.enters("lane_e", TriggerCond.is_enemy), TriggerCond.flag("raid_started")]),
		[TriggerAct.say([["Borin", "They're in the stores! Watch the stacks — they'll use 'em!"]])])

func _do_breach() -> void:
	# Battle music ENTERS here — the audio IS the coach->commander flip.
	AudioManager.play_music("battle")
	# Borin flips to your side, live (the spar-opponent fiction ends).
	if _borin:
		_borin.set_team(Constants.TEAM_ALLY)
	# Spawn the three raid groups at the north breach markers and register them.
	var raiders: Array = BattleSpawner.spawn(_tm, RAIDERS, $PlayerTeam, $EnemyTeam, $AllyTeam)
	if _gm:
		_gm.register_units(raiders)
	# Unpark everyone: allies fight their lanes, raiders push.
	for u in get_tree().get_nodes_in_group(Constants.GROUP_ALL_CHARACTERS):
		if u is EnemyCharacter:
			(u as EnemyCharacter).ai_enabled = true
	_engine.set_flag("raid_started", true)
	_gate(true, true, true)   # full bar (ability stays as-is for now)
	_show("The camp is breached — drive them out! (You command only yourself; the squad holds its lanes.)")
	await get_tree().create_timer(2.0).timeout
	_hide()

func _victory_coda() -> DialogueEvent:
	var ev := DialogueEvent.new()
	ev.lines = CineFx.lines([
		["Lyra", "That's the last of them. Everyone still on their feet?"],
		["Borin", "On my feet and then some. Fine shooting, Elena."],
		["Elena", "...I — yes. We held."],
		["Vael", "Well fought. First morning in a new world and already earning your keep. Come — that meal I promised."],
	])
	return ev

# ---------------------------------------------------------------------------
# Await-helpers (the drill's vocabulary)
# ---------------------------------------------------------------------------
func _until_region(region_name: String) -> void:
	while true:
		var args: Array = await EventBus.character_moved
		var who = args[0]
		var to: Vector2i = args[2]
		if who is CharacterBase and (who as CharacterBase).team == Constants.TEAM_PLAYER \
				and _engine.in_region(to, region_name):
			return

func _until_player_attack() -> void:
	while true:
		var args: Array = await EventBus.character_attacked
		var who = args[0]
		if who is CharacterBase and (who as CharacterBase).team == Constants.TEAM_PLAYER:
			return

## Wait for the player's strike, then give the reaction queue a beat and report
## whether a FRIENDLY follow-up chained off it (never false-praised).
func _strike_and_watch_for_chain() -> bool:
	await _until_player_attack()
	var chained := false
	var watcher := func(attacker, _t, _d, _c) -> void:
		if attacker is CharacterBase and (attacker as CharacterBase).team == Constants.TEAM_ALLY:
			chained = true
	EventBus.character_attacked.connect(watcher)
	await get_tree().create_timer(0.9).timeout   # reaction queue drains in the gm flow
	EventBus.character_attacked.disconnect(watcher)
	return chained

func _find_cover_near(unit: CharacterBase) -> Vector2i:
	if unit == null or _tm == null:
		return Constants.INVALID_TILE
	var objects := _tm.get_node_or_null("Objects") as TileMapLayer
	if objects == null:
		return Constants.INVALID_TILE
	var best := Constants.INVALID_TILE
	var best_d := 999
	for cell in objects.get_used_cells():
		if TerrainRegistry.is_cover_overlay(objects.get_cell_atlas_coords(cell)):
			var d: int = Constants.tile_distance(cell, unit.current_tile)
			if d < best_d:
				best_d = d
				best = cell
	return best

func _gate(move: bool, attack: bool, end_turn: bool) -> void:
	_gate_state = [move, attack, end_turn]
	_apply_gate()

func _apply_gate() -> void:
	if _action_bar == null:
		return
	_action_bar.attack_button.disabled = not _gate_state[1]
	_action_bar.ability_button.disabled = true
	_action_bar.end_turn_button.disabled = not _gate_state[2]
	# (Move has no disable hook; PLAYER_IDLE defaults to move mode.)

func _show(text: String) -> void:
	if _prompt:
		_prompt.set_prompt_text(text)
		_prompt.show()

func _hide() -> void:
	if _prompt:
		_prompt.hide()

func _say(rows: Array) -> void:
	await CineFx.say(get_tree(), rows)
