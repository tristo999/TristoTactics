# Level-1 AUTOPLAY: plays training_grounds_scene programmatically, end to end —
# drill (footwork → strikes → pit) → breach → raid → victory/defeat — by driving
# the same GameManager APIs the input handler uses, and injecting ui_accept to
# advance dialogue. Headless-safe. This is the closest thing to a playthrough a
# machine can do; it verifies FLOW, not feel.
#
# Run: <godot> --headless --path . res://scenes/dev/level1_autoplay.tscn
# Exit 0 = battle resolved (victory OR defeat — both are valid outcomes, both
# reported); exit 1 = the scene STALLED (a real flow bug).
extends Node

const SCENE := "res://scenes/levels/training_grounds_scene.tscn"
const FOOTWORK := Rect2i(9, 22, 5, 5)   # lesson-1 region (matches the director)
const TICK := 0.35
const STUCK_TICKS := 120                # ~42s sim with no state change = stalled

var _gm: Node
var _scene: Node
var _ticks := 0
var _player_turns := 0
var _last_sig := ""
var _same_sig_count := 0
var _footwork_done := false
var _resolved := false
var _last_state := -1

func _ready() -> void:
	Engine.time_scale = 3.0
	print("[AUTOPLAY] loading scene…")
	_scene = (load(SCENE) as PackedScene).instantiate()
	add_child(_scene)
	_gm = _scene.get_node_or_null("GameManager")
	EventBus.battle_ended.connect(_on_battle_ended)
	EventBus.turn_started.connect(func(c) -> void:
		if c is CharacterBase and (c as CharacterBase).team == Constants.TEAM_PLAYER:
			_player_turns += 1)
	# Listen to every trigger the scene's engine fires.
	await get_tree().process_frame
	for child in _scene.get_children():
		if child is TriggerEngine:
			(child as TriggerEngine).trigger_fired.connect(
				func(id: String) -> void: print("[AUTOPLAY] engine fired: %s (t%d)" % [id, _ticks]))
	var t := Timer.new()
	t.wait_time = TICK
	t.timeout.connect(_tick)
	add_child(t)
	t.start()

func _press_accept() -> void:
	# Synthesized InputEventAction does NOT propagate to _unhandled_input (the
	# DialogueBox's listener) — a real key event does. Send Enter, and ALSO hand
	# the event straight to the box (belt and suspenders for headless).
	var ev := InputEventKey.new()
	ev.keycode = KEY_ENTER
	ev.physical_keycode = KEY_ENTER
	ev.pressed = true
	Input.parse_input_event(ev)
	var box = get_tree().get_first_node_in_group("dialogue_box")
	if box and box.has_method("_unhandled_input"):
		box._unhandled_input(ev)
	var up := InputEventKey.new()
	up.keycode = KEY_ENTER
	up.physical_keycode = KEY_ENTER
	up.pressed = false
	Input.parse_input_event(up)

func _hero() -> CharacterBase:
	for n in get_tree().get_nodes_in_group(Constants.GROUP_PLAYER_CHARACTERS):
		if n is CharacterBase:
			return n
	return null

func _hostiles(hero: CharacterBase) -> Array:
	var out: Array = []
	for n in get_tree().get_nodes_in_group(Constants.GROUP_ALL_CHARACTERS):
		if n is CharacterBase and n != hero and (n as CharacterBase).is_alive \
				and hero.is_hostile_to(n):
			out.append(n)
	return out

func _tick() -> void:
	if _resolved:
		return
	_ticks += 1
	_press_accept()   # advance any dialogue every tick

	var hero := _hero()
	if _gm and _gm.state != _last_state:
		print("[AUTOPLAY][state] %s -> %s (t%d)" % [_last_state, _gm.state, _ticks])
		_last_state = _gm.state
	var sig := "%s|%s|%s" % [_gm.state if _gm else -1,
		hero.current_tile if hero else "x", _player_turns]
	if sig == _last_sig:
		_same_sig_count += 1
	else:
		_same_sig_count = 0
		_last_sig = sig
	# Heartbeat: periodic world dump so stalls are diagnosable from the log.
	if _ticks % 100 == 0:
		var hb_borin: CharacterBase = null
		for n in get_tree().get_nodes_in_group(Constants.GROUP_ALL_CHARACTERS):
			if n.name == "Borin": hb_borin = n
		var foes_n := _hostiles(hero).size() if hero else -1
		var box = get_tree().get_first_node_in_group("dialogue_box")
		print("[AUTOPLAY][hb t%d] ov_playing=%s dlg_visible=%s" % [_ticks,
			AttackAnimationOverlay._is_playing, box.visible if box else "?"])
		print("[AUTOPLAY][hb t%d] gm.state=%s cur=%s hero=%s hp=%s foes=%d borin=%s/%s all=%d" % [
			_ticks, _gm.state if _gm else -1,
			_gm.current_character.name if _gm and _gm.current_character else "?",
			hero.current_tile if hero else "?", hero.current_hp if hero else -1, foes_n,
			hb_borin.team if hb_borin else "?", hb_borin.current_hp if hb_borin else -1,
			get_tree().get_nodes_in_group(Constants.GROUP_ALL_CHARACTERS).size()])
	if _ticks >= 2600 and not _resolved:
		print("[AUTOPLAY] HARD STALL: %d ticks without battle_ended. gm.state=%s turns=%d" %
			[_ticks, _gm.state if _gm else -1, _player_turns])
		get_tree().quit(1)
		return
	if _same_sig_count >= STUCK_TICKS:
		print("[AUTOPLAY] STALLED. gm.state=%s hero=%s turns=%d ticks=%d" %
			[_gm.state if _gm else -1, hero.current_tile if hero else "?", _player_turns, _ticks])
		get_tree().quit(1)
		return

	if _gm == null or hero == null:
		return
	if _gm.state != 1:   # BattleState.PLAYER_IDLE
		return
	if _gm.current_character != hero:
		return

	# Phase 1 — the footwork lesson: enter the chalked course before anything else.
	if not _footwork_done:
		if FOOTWORK.has_point(hero.current_tile):
			_footwork_done = true
			print("[AUTOPLAY] footwork reached at turn %d, tile %s" % [_player_turns, hero.current_tile])
		else:
			_move_toward(hero, Vector2i(11, 24))
			return

	# Respect the drill's pacing: when the attack button is gated off, hold
	# position (end turn in place) like a human reading the prompt would.
	var bar = get_tree().get_first_node_in_group("action_bar")
	if bar and bar.attack_button.disabled:
		_end_turn(hero)
		return

	# Phase 2+ — universal soldiering: attack the nearest hostile, else close in.
	var foes := _hostiles(hero)
	if foes.is_empty():
		_end_turn(hero)
		return
	foes.sort_custom(func(a, b) -> bool:
		return Constants.tile_distance(hero.current_tile, a.current_tile) \
			< Constants.tile_distance(hero.current_tile, b.current_tile))
	var target: CharacterBase = foes[0]
	if hero.can_attack_target(target):
		print("[AUTOPLAY] attack %s (hp %d) from %s" % [target.name, target.current_hp, hero.current_tile])
		_gm.request_attack(hero, target)
		return
	if hero.movement_left > 0:
		_move_toward(hero, target.current_tile)
		return
	if not hero.has_used_action and not hero.can_attack_target(target):
		_end_turn(hero)
		return
	_end_turn(hero)

func _move_toward(hero: CharacterBase, goal: Vector2i) -> void:
	if hero.movement_left <= 0:
		_end_turn(hero)
		return
	var tm = get_tree().get_first_node_in_group("tilemap")
	if tm == null:
		return
	var reachable: Array = tm.get_reachable_tiles(hero.current_tile, hero.movement_left)
	if reachable.is_empty():
		_end_turn(hero)
		return
	var best: Vector2i = reachable[0]
	var best_d := 99999
	for cell in reachable:
		var d: int = Constants.tile_distance(cell, goal)
		if d < best_d:
			best_d = d
			best = cell
	if best == hero.current_tile:
		_end_turn(hero)
		return
	tm.cached_reachable_tiles = reachable
	if not _gm.request_move(hero, best):
		_end_turn(hero)

func _end_turn(_hero: CharacterBase) -> void:
	if _gm.has_method("end_player_turn"):
		_gm.end_player_turn()

func _on_battle_ended(victory: bool) -> void:
	_resolved = true
	var hero := _hero()
	var allies := get_tree().get_nodes_in_group(Constants.GROUP_ALLY_CHARACTERS).size()
	print("[AUTOPLAY] ===== BATTLE RESOLVED =====")
	print("[AUTOPLAY] outcome=%s player_turns=%d ticks=%d (~%.0fs sim)" %
		["VICTORY" if victory else "DEFEAT", _player_turns, _ticks, _ticks * TICK * Engine.time_scale])
	print("[AUTOPLAY] hero_hp=%s allies_alive=%d" %
		[(str(hero.current_hp) + "/" + str(hero.max_hp)) if hero else "DOWN", allies])
	await get_tree().create_timer(1.0).timeout
	get_tree().quit(0)
