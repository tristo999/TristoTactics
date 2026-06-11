## Tutorial spar — Beat 2, phase 1. A heavily SCRIPTED training drill on
## arena_drill, per docs/opening_script.md (Scene 5).
##
## CONTROL MODEL (settled 2026-06-10): the player controls ONLY THE HERO — the
## student. Everyone else is scripted: Borin is the strike target (enemy team so
## he's targetable, AI parked so he just stands there and takes it — he insists),
## Elena is a parked ally at your shoulder whose follow-up chains LIVE off your
## strike (the signature verb, demonstrated by the engine, never false-praised),
## and the recruits drill in the background. Lessons: MOVE → STRIKE → TOGETHER,
## then the raid interrupts and hands off to the true battle.
extends BaseLevel

const ROSTER := {
	"1": {"data": "res://data/characters/hero.tres", "name": "Hero"},
	"2": {"data": "res://data/characters/archer.tres", "name": "Elena", "team": "ally"},
	"3": {"data": "res://data/characters/dwarf.tres", "name": "Borin", "team": "enemy"},
	"5": {"data": "res://data/characters/hero.tres", "name": "Recruit Sten", "team": "ally"},
	"6": {"data": "res://data/characters/hero.tres", "name": "Recruit Wynn", "team": "ally"},
	"7": {"data": "res://data/characters/hero.tres", "name": "Recruit Bram", "team": "ally"},
}

## Where the raid (true battle) lives — handed off to when the spar ends.
@export_file("*.tscn") var next_scene_path: String = "res://scenes/levels/tutorial_battle_scene.tscn"

enum Step { INTRO, MOVE, ATTACK, DONE }

var _action_bar: Node
var _prompt: Control
var _fx: CanvasLayer
var _step: int = Step.INTRO
var _followup_fired: bool = false

func _ready() -> void:
	music_key = "battle"   # TODO(opening_script): camp theme here; battle music at the breach
	_spawn_roster()
	var gm = $GameManager
	if gm:
		gm.intro_event = null      # the spar runs its own scripted intro
		gm.victory_event = null
		gm.player_goes_first = true
	super._ready()
	call_deferred("_begin")

func _spawn_roster() -> void:
	var tm = get_tree().get_first_node_in_group("tilemap")
	if tm == null:
		push_error("[TutorialSpar] no tilemap.")
		return
	var units: Array = BattleSpawner.spawn(tm, ROSTER, $PlayerTeam, $EnemyTeam, $AllyTeam)
	# Park every AI unit: the drill owns the turn flow — partners hold still.
	# (Reactions still fire, which is exactly how Elena's chain demo works.)
	for u in units:
		if u is EnemyCharacter:
			(u as EnemyCharacter).ai_enabled = false

func _begin() -> void:
	await get_tree().process_frame
	_action_bar = get_tree().get_first_node_in_group("action_bar")
	_prompt = get_tree().get_first_node_in_group("tutorial_prompt")
	_fx = CanvasLayer.new()
	_fx.layer = 120
	add_child(_fx)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.character_moved.connect(_on_character_moved)
	EventBus.character_attacked.connect(_on_character_attacked)

	await get_tree().create_timer(0.6).timeout
	_frame_spar()
	await _say([
		["Vael", "Borin. Elena. With me — bring the blunts."],
		["Vael", "First things first. Let's see whether the circle sent us a soldier or a sack of turnips."],
		["Vael", "Ground first — pick your footing. Go on."],
	])
	_step = Step.MOVE
	_lock_to_move()
	_show("Select Move, then click a highlighted tile.")

# Re-lock the bar each player turn while we're still gating.
func _on_turn_started(c: CharacterBase) -> void:
	_frame_spar()
	if not _is_player(c):
		return
	if _step == Step.MOVE:
		await get_tree().process_frame
		_lock_to_move()
	elif _step == Step.ATTACK:
		await get_tree().process_frame
		_lock_for_attack()

## Hold a stable framing on the spar pad (the drill is choreographed, not free
## combat — we don't want the battle camera drifting/following).
func _frame_spar() -> void:
	var cam := get_tree().get_first_node_in_group("action_camera") as Node2D
	var tm := get_tree().get_first_node_in_group("tilemap")
	if cam == null or tm == null:
		return
	var base := tm.get_node_or_null("BaseGrid") as TileMapLayer
	if base == null:
		return
	var center := base.to_global(base.map_to_local(Vector2i(19, 15)))   # pad / squad
	if "zoom" in cam:
		cam.zoom = Vector2(4.0, 4.0)   # BATTLE register (opening_script camera grammar)
	if cam.has_method("snap_to"):
		cam.snap_to(center)
	else:
		cam.global_position = center

func _on_character_moved(c: Node2D, _from: Vector2i, _to: Vector2i) -> void:
	if _step != Step.MOVE or not _is_player(c):
		return
	_step = Step.ATTACK
	_hide()
	await _say([
		["Borin", "Then come introduce yourself!"],
		["Vael", "Now put steel on Borin — he insists. Strike — and keep Elena at your shoulder."],
	])
	_show("Select Attack, then strike Borin.")

func _on_character_attacked(attacker: Node2D, _target: Node2D, _dmg: int, _crit: bool) -> void:
	if _is_player(attacker) and _step == Step.ATTACK:
		# The strike the player was prompted for.
		_step = Step.DONE
		_followup_fired = false
		_resolve_attack()
	elif _step == Step.DONE and attacker is CharacterBase \
			and (attacker as CharacterBase).team == Constants.TEAM_ALLY:
		# A friendly unit's attack chained in the same beat == Elena's follow-up fired.
		_followup_fired = true

func _resolve_attack() -> void:
	_hide()
	await get_tree().create_timer(0.7).timeout   # give the follow-up time to chain
	if _followup_fired:
		await _say([
			["Elena", "...clear. — w-was that... did I overdo— Borin I'm so sorry—"],
			["Borin", "HA! That's the thing! That's the whole war, right there!"],
			["Vael", "A follow-up. Stand close, move in concert, answer each other's strikes."],
			["Vael", "Learn nothing else today, learn th—"],
		])
	else:
		await _say([
			["Borin", "Good weight! Felt that in me teeth."],
			["Vael", "Mark this, though — keep Elena at your shoulder when you swing. She'll answer your strike with her own. A follow-up. You'll lean on it before the morning's ou—"],
		])
	await _raid_interrupt()

## The tonal hinge: the drill is cut short as the raid breaches. Coach → commander.
func _raid_interrupt() -> void:
	await _flash(Color(1, 1, 1, 0.9), 0.06, 0.5)   # the horn, the jolt
	await get_tree().create_timer(0.35).timeout
	await _say([
		["Vael", "...Those aren't ours."],
		["Vael", "Insurgents — through the north fence! Up, ALL of you — blades out, this is no drill!"],
		["Vael", "Recruits — fall in behind the champion. Elena, Lyra, Borin — you know your work. MOVE!"],
	])
	await _fade_black(0.8)
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)

# --- helpers ---------------------------------------------------------------

func _is_player(c) -> bool:
	return c != null and c is CharacterBase and (c as CharacterBase).team == Constants.TEAM_PLAYER

func _lock_to_move() -> void:
	if _action_bar == null:
		return
	_action_bar.attack_button.disabled = true
	_action_bar.ability_button.disabled = true
	_action_bar.end_turn_button.disabled = true

func _lock_for_attack() -> void:
	# Attack (and Move, to step into range) available; the rest stays locked.
	if _action_bar == null:
		return
	_action_bar.attack_button.disabled = false
	_action_bar.ability_button.disabled = true
	_action_bar.end_turn_button.disabled = true

func _show(text: String) -> void:
	if _prompt:
		_prompt.set_prompt_text(text)
		_prompt.show()

func _hide() -> void:
	if _prompt:
		_prompt.hide()

func _flash(color: Color, up: float, down: float) -> void:
	await CineFx.flash(_fx, color, up, down)

func _fade_black(dur: float) -> void:
	await CineFx.fade(_fx, 1.0, dur, true)

func _say(rows: Array) -> void:
	await CineFx.say(get_tree(), rows)
