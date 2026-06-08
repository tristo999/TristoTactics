# Trigger engine self-test. Run the scene scenes/dev/trigger_selftest.tscn (F6)
# in the editor — it drives the engine with fake EventBus events and prints a
# PASS/FAIL line per check, then an overall result. Headless can't see new
# class_names, so run this in the editor.
extends Node

# Minimal stand-in for a unit. Synthetic EventBus emissions are also heard by real
# autoloads (GameSFXManager reads .team/.get_sfx on turn_started; ComboSystem checks
# `is CharacterBase`), so the stub provides just enough to keep their handlers quiet.
class _FakeUnit extends Node2D:
	var team: String = "player_team"
	func get_sfx(_action: String) -> String: return ""

var _results: Array = []

func _ready() -> void:
	await _run()
	var passed := 0
	for r in _results:
		if r[0]:
			passed += 1
		print(("  PASS " if r[0] else "  FAIL ") + r[1])
	var ok := passed == _results.size()
	print("\n[TriggerSelfTest] %d/%d checks passed — %s" % [passed, _results.size(), "ALL PASS" if ok else "FAILURES"])
	# Auto-quit when run standalone (headless/F6) so it doesn't hang the main loop.
	if get_tree().current_scene == self or DisplayServer.get_name() == "headless":
		await get_tree().create_timer(0.1).timeout
		get_tree().quit(0 if ok else 1)

func _check(cond: bool, label: String) -> void:
	_results.append([cond, label])

func _run() -> void:
	var eng := TriggerEngine.new()
	add_child(eng)
	await get_tree().process_frame   # let _ready wire EventBus

	eng.region("pad", Rect2i(5, 5, 3, 3))   # tiles (5,5)..(7,7)

	# 1. enters region (one-shot)
	eng.add("enter_pad",
		TriggerCond.enters("pad"),
		[TriggerAct.set_flag("entered")])
	# 2. turn_reached(2)
	eng.add("turn2",
		TriggerCond.turn_reached(2),
		[TriggerAct.set_flag("turn2")])
	# 3. once vs repeat — count fires
	var counts := {"once": 0, "repeat": 0}
	eng.add("count_once",
		TriggerCond.on("battle_started"),
		[TriggerAct.call_fn(func() -> void: counts["once"] += 1)], true)
	eng.add("count_repeat",
		TriggerCond.on("battle_started"),
		[TriggerAct.call_fn(func() -> void: counts["repeat"] += 1)], false)
	# 4. flag gating + enable/disable: armed only after "armed" is set
	eng.add("gated",
		TriggerCond.all_([TriggerCond.on("turn_ended"), TriggerCond.flag("armed")]),
		[TriggerAct.set_flag("gated_fired")])
	# 5. cross-trigger enable: a disabled trigger flipped on by another
	var late := eng.add("late",
		TriggerCond.on("healed"),
		[TriggerAct.set_flag("late_fired")])
	late.enabled = false
	eng.add("arm_late",
		TriggerCond.on("died"),
		[TriggerAct.enable("late")])

	var stub := _FakeUnit.new()
	add_child(stub)

	# --- drive events ---
	EventBus.character_moved.emit(stub, Vector2i(0, 0), Vector2i(6, 6))   # into pad
	await get_tree().process_frame
	_check(eng.get_flag("entered") == true, "unit entering region fires trigger")

	# move outside the region should NOT re-fire (and it's one-shot anyway)
	eng.set_flag("entered", false)
	EventBus.character_moved.emit(stub, Vector2i(6, 6), Vector2i(0, 0))   # out of pad
	await get_tree().process_frame
	_check(eng.get_flag("entered") == false, "one-shot trigger does not re-fire / no false enter")

	EventBus.turn_started.emit(stub)   # turn 1
	await get_tree().process_frame
	_check(eng.get_flag("turn2") == null, "turn_reached(2) silent on turn 1")
	EventBus.turn_started.emit(stub)   # turn 2
	await get_tree().process_frame
	_check(eng.get_flag("turn2") == true, "turn_reached(2) fires on turn 2")

	EventBus.battle_started.emit()
	EventBus.battle_started.emit()
	await get_tree().process_frame
	_check(counts["once"] == 1, "once=true fires exactly once across two events")
	_check(counts["repeat"] == 2, "once=false fires every time")

	EventBus.turn_ended.emit(null)   # gate not armed yet
	await get_tree().process_frame
	_check(eng.get_flag("gated_fired") == null, "flag-gated trigger stays silent while flag unset")
	eng.set_flag("armed", true)
	EventBus.turn_ended.emit(null)
	await get_tree().process_frame
	_check(eng.get_flag("gated_fired") == true, "flag-gated trigger fires once flag is set")

	EventBus.character_healed.emit(stub, 5, null)   # 'late' still disabled
	await get_tree().process_frame
	_check(eng.get_flag("late_fired") == null, "disabled trigger does not fire")
	EventBus.character_died.emit(stub)              # arms 'late'
	await get_tree().process_frame
	EventBus.character_healed.emit(stub, 5, null)   # now enabled
	await get_tree().process_frame
	_check(eng.get_flag("late_fired") == true, "trigger enabled by another trigger then fires")
