## Tutorial spar — Beat 2, phase 1. A heavily SCRIPTED training match on
## arena_drill: Vael coaches the core verbs (move, attack) and points out the
## follow-up combo, then it ends and hands off to the raid (the true battle on
## arena_raid). "Very scripted": buttons are gated step-by-step and the spar
## resolves on the player's first turn, so the partners never fight back.
##
## Spar partners (5/6/7) are mechanically ENEMY units so the player can strike
## them — framed as a nonlethal drill. (In the raid they fight beside you.)
extends BaseLevel

const ROSTER := {
	"1": {"data": "res://data/characters/archer.tres", "name": "Elena"},
	"2": {"data": "res://data/characters/dwarf.tres", "name": "Borin"},
	"3": {"data": "res://data/characters/healer.tres", "name": "Lyra"},
	"5": {"data": "res://data/characters/hero.tres", "name": "Recruit", "team": "enemy"},
	"6": {"data": "res://data/characters/hero.tres", "name": "Recruit", "team": "enemy"},
	"7": {"data": "res://data/characters/hero.tres", "name": "Recruit", "team": "enemy"},
}

## Where the raid (true battle) lives — handed off to when the spar ends.
@export_file("*.tscn") var next_scene_path: String = "res://scenes/levels/tutorial_battle_scene.tscn"

enum Step { INTRO, MOVE, ATTACK, DONE }

var _action_bar: Node
var _prompt: Control
var _fx: CanvasLayer
var _step: int = Step.INTRO
var _spar_attacker: Node = null   # the unit whose strike we're judging
var _followup_fired: bool = false

func _ready() -> void:
	music_key = "battle"
	_spawn_roster()
	var gm = $GameManager
	if gm:
		gm.intro_event = null      # the spar runs its own scripted intro
		gm.victory_event = null
	super._ready()
	call_deferred("_begin")

func _spawn_roster() -> void:
	var tm = get_tree().get_first_node_in_group("tilemap")
	if tm == null:
		push_error("[TutorialSpar] no tilemap.")
		return
	BattleSpawner.spawn(tm, ROSTER, $PlayerTeam, $EnemyTeam, $AllyTeam)

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
		["Vael", "First things first. Let's see whether the circle sent us a soldier or a sack of turnips."],
		["Vael", "Move your archer — pick a spot, get a feel for the ground. Go on."],
	])
	_step = Step.MOVE
	_lock_to_move()
	_show("Select Move, then click a highlighted tile.")

# Re-lock the bar each player turn while we're still gating to Move only.
func _on_turn_started(c: CharacterBase) -> void:
	_frame_spar()
	if _step == Step.MOVE:
		await get_tree().process_frame
		_lock_to_move()
	elif _step == Step.ATTACK and _is_player(c):
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
		cam.zoom = Vector2(4.5, 4.5)
	if cam.has_method("snap_to"):
		cam.snap_to(center)
	else:
		cam.global_position = center

func _on_character_moved(c: Node2D, _from: Vector2i, _to: Vector2i) -> void:
	if _step != Step.MOVE or not _is_player(c):
		return
	_step = Step.ATTACK
	_hide()
	await _say([["Vael", "Good — footwork keeps you breathing. Now bring the rest up and put steel on a partner. Attack, then pick one."]])
	# End this unit's turn so the strike falls to the NEXT squadmate — the archer
	# can then chain a follow-up off it (she can't follow up her own blow).
	var gm := $GameManager
	if gm and gm.has_method("end_player_turn"):
		gm.end_player_turn()
	_show("Select Attack, then strike a sparring partner.")

func _on_character_attacked(attacker: Node2D, _target: Node2D, _dmg: int, _crit: bool) -> void:
	if not _is_player(attacker):
		return
	if _step == Step.ATTACK:
		# The strike the player was prompted for.
		_step = Step.DONE
		_spar_attacker = attacker
		_followup_fired = false
		_resolve_attack()
	elif _step == Step.DONE and attacker != _spar_attacker:
		# A second player strike in the same beat == a follow-up chained off the first.
		_followup_fired = true

func _resolve_attack() -> void:
	_hide()
	await get_tree().create_timer(0.7).timeout   # give any follow-up time to chain
	if _followup_fired:
		await _say([
			["Vael", "— Hah! Catch that? One of yours chained a shot off the blow. A follow-up."],
			["Vael", "Keep your squad shoulder to shoulder and they'll do that all day. That's the whole game, recru—"],
		])
	else:
		await _say([
			["Vael", "Clean enough. But mark this, recruit —"],
			["Vael", "keep your archer at your shoulder when someone else swings. She'll chain a free shot off it — a follow-up. You'll lean on it before the morning's out, recru—"],
		])
	await _raid_interrupt()

## The tonal hinge: the drill is cut short as the raid breaches. Coach → commander.
func _raid_interrupt() -> void:
	await _flash(Color(1, 1, 1, 0.9), 0.06, 0.5)   # the horn, the jolt
	await get_tree().create_timer(0.35).timeout
	await _say([
		["Vael", "...Those aren't ours."],
		["Vael", "Insurgents — they're through the gate! Up, all of you! Blades out — this is no drill!"],
		["Vael", "Recruits — you stand WITH them now, not against them. MOVE!"],
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
