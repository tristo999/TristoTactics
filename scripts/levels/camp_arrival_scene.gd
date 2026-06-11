# CampArrivalScene - Beat 1 (ARRIVAL), per docs/opening_script.md Scenes 3-4.
#
# Two phases:
#   A. SCRIPTED OPENING (no input): the hero walks out of the summoning-room wall
#      into the camp; Vael finishes orders, notices, comes down — and DELIVERS THE
#      LIE (the Authority summoned you; the kingdom is the enemy; you are ours).
#      He names the three squad stations and walks ahead to the yard gate.
#   B. PLAYER-WALKED CAMP WALK (ruled 2026-06-10): control unlocks; the player
#      visits Borin (armory racks), Elena (the range), Lyra (infirmary tent) in any
#      order — each a one-shot TriggerEngine region stop with a real conversation.
#      The yard gate hands off to the training grounds once all three are met
#      (a nudge plays if you arrive early).
#
# Hero = WalkingPlayer. Vael/Borin/Elena/Lyra = CinematicActors (tinted).
# Camera: CineCam for phase A at WALK register 2.0; the player's own camera
# (also 2.0) takes over for phase B — one register, no jump.
extends WalkingScene
class_name CampArrivalScene

@export var fade_in_duration: float = 1.2
@export_file("*.tscn") var next_scene_path: String = ""

const VAEL_GATE_TILE := Vector2i(25, 33)   # where Vael waits (yard gate, on the street)

var _player: WalkingPlayer
var _vael: Node2D
var _borin: Node2D
var _elena: Node2D
var _lyra: Node2D
var _s1: Node2D
var _s2: Node2D
var _cam: Camera2D
var _base: TileMapLayer
var _fx: CanvasLayer
var _engine: TriggerEngine
var _exiting := false

func _ready() -> void:
	super._ready()
	_player = get_tree().get_first_node_in_group("walking_player") as WalkingPlayer
	_vael = get_node_or_null("Vael") as Node2D
	_borin = get_node_or_null("Borin") as Node2D
	_elena = get_node_or_null("Elena") as Node2D
	_lyra = get_node_or_null("Lyra") as Node2D
	_s1 = get_node_or_null("Soldier1") as Node2D
	_s2 = get_node_or_null("Soldier2") as Node2D
	_cam = get_node_or_null("CineCam") as Camera2D
	if _player:
		_player.lock_movement()
		var pc := _player.get_node_or_null("Camera2D") as Camera2D
		if pc:
			pc.enabled = false
	_fx = CanvasLayer.new()
	_fx.layer = 120
	add_child(_fx)
	_setup_engine()
	call_deferred("_run_opening")

# ---------------------------------------------------------------------------
# Phase B wiring — the stations, declared.
# ---------------------------------------------------------------------------
func _setup_engine() -> void:
	_engine = TriggerEngine.new()
	add_child(_engine)
	_engine.region("borin_station", Rect2i(31, 37, 7, 6))   # armory racks, east ring
	_engine.region("elena_station", Rect2i(12, 37, 7, 6))   # the range, west ring
	_engine.region("lyra_station", Rect2i(31, 42, 7, 7))    # infirmary tent, south-east
	_engine.region("yard_gate", Rect2i(23, 29, 6, 4))       # the arena's south gate

	_engine.add("meet_borin", TriggerCond.enters("borin_station"),
		[TriggerAct.call_fn(_meet_borin), TriggerAct.set_flag("borin_met")])
	_engine.add("meet_elena", TriggerCond.enters("elena_station"),
		[TriggerAct.call_fn(_meet_elena), TriggerAct.set_flag("elena_met")])
	_engine.add("meet_lyra", TriggerCond.enters("lyra_station"),
		[TriggerAct.call_fn(_meet_lyra), TriggerAct.set_flag("lyra_met")])

	# The gate: hands off once the squad is met; nudges (once) if you rush it.
	_engine.add("gate_ready",
		TriggerCond.all_([TriggerCond.enters("yard_gate"),
			TriggerCond.flag("borin_met"), TriggerCond.flag("elena_met"), TriggerCond.flag("lyra_met")]),
		[TriggerAct.call_fn(_enter_yard)])
	_engine.add("gate_early",
		TriggerCond.all_([TriggerCond.enters("yard_gate"),
			TriggerCond.not_(TriggerCond.all_([TriggerCond.flag("borin_met"),
				TriggerCond.flag("elena_met"), TriggerCond.flag("lyra_met")]))]),
		[TriggerAct.call_fn(func() -> void: await _conversation(_vael, [
			["Vael", "The squad first. Borin, Elena, Lyra — a soldier who doesn't know his line dies of it."],
		]))])

# ---------------------------------------------------------------------------
# Phase A — the scripted opening (walk-in, the greeting, THE LIE).
# ---------------------------------------------------------------------------
func _run_opening() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_base = _get_base()
	if _cam:
		_cam.make_current()
		_cam.zoom = Vector2(2.0, 2.0)   # WALK register (opening_script camera grammar)
		if _player:
			_cam.global_position = _player.global_position + Vector2(0, -200)

	# 1. The hero walks out of the wall into the camp.
	await _fade(0.0, fade_in_duration)
	await _wait(0.3)
	if _player:
		await _player.cinematic_walk_north(7, 2.8)
	await _wait(0.3)

	# 2. Pan up to Vael, mid-orders.
	if _vael:
		_pan_to(_vael.global_position, 1.6)
	await _wait(1.6)
	if _vael:
		_vael.call("face", "down")
	if _s1: _s1.call("face", "up")
	if _s2: _s2.call("face", "up")
	await _say([["Vael", "— and the north pickets run double tonight. Go on, the lot of you."]])
	await _say([["Soldier", "Aye, Commander."]])
	if _s1: _s1.call("walk_to", Vector2i(18, 45), 1.8)
	if _s2: _s2.call("walk_to", Vector2i(33, 45), 1.8)
	await _wait(1.0)

	# 3. He notices, comes down.
	if _vael and _player:
		_vael.call("face_tile", _player.current_tile)
	await _wait(0.4)
	await _say([["Vael", "...Well, now. Look who the circle finally coughed up."]])
	if _player:
		_player.face("up")
	if _vael and _player:
		var meet: Vector2i = _player.current_tile + Vector2i(0, -2)
		var dur: float = maxi(absi(_vael.current_tile.y - meet.y), 1) * 0.32
		_pan_to((_world(meet) + _player.global_position) * 0.5, dur)
		await _vael.call("walk_to", meet, dur)
		_vael.call("face_tile", _player.current_tile)
	await _wait(0.3)

	# 4. THE LIE — the origin story the whole first act runs on.
	await _say([
		["Vael", "Easy — breathe. The crossing takes it out of everyone the first time."],
		["Vael", "You must be a little confused. That's fair. So — the short version, and the rest over a hot meal."],
		["Vael", "This is an Authority camp, and the Authority is why you're standing here. We reached across worlds for you. Took the circle's keepers the better part of a year to find you and pull you through."],
		["Vael", "Not a talker. Good. Talkers die of it out here."],
		["Vael", "There's a power east of us — the kingdom — and it has been bleeding this land for years. Burning the borderlands. Killing whoever it can't keep. We've held it about as long as holding works."],
		["Vael", "What comes next needs something it can't match. That's you. The Authority called, and you came — and that makes you ours, and us yours. Welcome to the war, friend."],
	])

	# 5. He sends you to the squad and walks ahead to the gate.
	await _say([
		["Vael", "The people you'll fight beside are about the camp — Borin at the racks, east. Elena on the range, west. Lyra at the infirmary tent. Go and meet them."],
		["Vael", "I'll be at the yard gate. Don't dawdle past the fires."],
	])
	if _vael:
		_vael.call("walk_to", VAEL_GATE_TILE, 4.0)   # fire-and-forget; he goes ahead

	# 6. Hand the camera and the legs to the player.
	if _player:
		_pan_to(_player.global_position, 1.0)
		await _wait(1.0)
		var pc := _player.get_node_or_null("Camera2D") as Camera2D
		if pc:
			pc.enabled = true
			pc.make_current()
		if _cam:
			_cam.enabled = false
		_player.unlock_movement()

# ---------------------------------------------------------------------------
# The station conversations (one-shot; engine-triggered).
# ---------------------------------------------------------------------------
func _meet_borin() -> void:
	await _conversation(_borin, [
		["Borin", "By the deep roads — so the circle works after all. I'd money on it cooking you."],
		["Borin", "Borin. The wall you'll be standing behind — wall, doorstop, furniture generally. Dwarf-made, and they don't make us anymore, so mind the antique."],
		["Borin", "You take a hit out there, that's my failing, not yours. Remember that."],
		["Borin", "You look half-drowned, lad. Eat something before Vael marches you. They never eat something."],
	])

func _meet_elena() -> void:
	await _conversation(_elena, [
		["Elena", "C-company?! I wasn't — these are the practice arrows, I signed for them, there's a ledger—"],
		["Elena", "...Oh. Oh no. You're the — the summoned one. And I just. Said the thing about the ledger."],
		["Elena", "Elena. Sharpshooter, third file. It's — yes. Hello. I'm normally better at— no. Arrows. I'm better at arrows."],
	])

func _meet_lyra() -> void:
	await _conversation(_lyra, [
		["Lyra", "—and by its light be mended. There. Try not to carry crates with a bad wrist, picket."],
		["Lyra", "And here HE is. The Authority's own light reached across worlds and chose to carry you back. Do you understand what an honor it is to be what it wanted? ...No. You will."],
		["Lyra", "Come bleeding, come broken — the blessing doesn't run out. That's the point of it."],
	])

func _enter_yard() -> void:
	if _exiting:
		return
	_exiting = true
	if _player:
		_player.lock_movement()
	if _vael and _player:
		_vael.call("face_tile", _player.current_tile)
	await _say([
		["Vael", "Good. They'll do — and so might you."],
		["Vael", "Through here. The yard. Let's see what you are."],
	])
	PlayerDataManager.set_checkpoint(next_scene_path)
	PlayerDataManager.save_player_data()
	await _fade(1.0, 0.8)
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)

## Lock, face each other, talk, release — the shared shape of every station stop.
func _conversation(actor: Node2D, rows: Array) -> void:
	if _player == null or _exiting:
		return
	_player.lock_movement()
	if actor:
		actor.call("face_tile", _player.current_tile)
		var ct = actor.get("current_tile")
		if ct is Vector2i:
			var diff: Vector2i = (ct as Vector2i) - _player.current_tile
			if absi(diff.x) > absi(diff.y):
				_player.face("right" if diff.x > 0 else "left")
			else:
				_player.face("down" if diff.y > 0 else "up")
	await _say(rows)
	if not _exiting:
		_player.unlock_movement()

# --- helpers ---------------------------------------------------------------

func _get_base() -> TileMapLayer:
	var tm := get_tree().get_first_node_in_group("tilemap")
	return tm.get_node_or_null("BaseGrid") as TileMapLayer if tm else null

func _world(tile: Vector2i) -> Vector2:
	if _base == null:
		return Vector2.ZERO
	return _base.to_global(_base.map_to_local(tile))

func _wait(s: float) -> void:
	await CineFx.wait(get_tree(), s)

func _pan_to(target: Vector2, dur: float) -> void:
	if _cam == null:
		return
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_cam, "global_position", target, dur)
	await tw.finished

func _fade(to_a: float, dur: float) -> void:
	await CineFx.fade(_fx, to_a, dur, to_a > 0.01)

func _say(rows: Array) -> void:
	await CineFx.say(get_tree(), rows)
