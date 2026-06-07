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
var _step: int = Step.INTRO

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
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.character_moved.connect(_on_character_moved)
	EventBus.character_attacked.connect(_on_character_attacked)

	await get_tree().create_timer(0.6).timeout
	await _say([
		["Vael", "First things first. Let's see whether the circle sent us a soldier or a sack of turnips."],
		["Vael", "Move your archer — pick a spot, get a feel for the ground. Go on."],
	])
	_step = Step.MOVE
	_lock_to_move()
	_show("Select Move, then click a highlighted tile.")

# Re-lock the bar each player turn while we're still gating to Move only.
func _on_turn_started(_c: CharacterBase) -> void:
	if _step == Step.MOVE:
		await get_tree().process_frame
		_lock_to_move()

func _on_character_moved(c: Node2D, _from: Vector2i, _to: Vector2i) -> void:
	if _step != Step.MOVE or not _is_player(c):
		return
	_step = Step.ATTACK
	_hide()
	await _say([["Vael", "Good. Footwork keeps you breathing. Now — strike a partner. Attack, then choose one."]])
	_unlock_attack()
	_show("Select Attack, then click a sparring partner.")

func _on_character_attacked(attacker: Node2D, _target: Node2D, _dmg: int, _crit: bool) -> void:
	if _step != Step.ATTACK or not _is_player(attacker):
		return
	_step = Step.DONE
	_hide()
	await get_tree().create_timer(0.4).timeout
	await _say([
		["Vael", "— Hah! Did you catch that? Your squad chained off the blow. A follow-up."],
		["Vael", "Keep them close and they cover for each other. That's the whole game, recruit."],
		["Vael", "Enough drills. You'll do. Now form up — the morning's not done with you yet."],
	])
	_finish()

func _finish() -> void:
	# (Later: the raid breaks in here instead of a clean cut.)
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

func _unlock_attack() -> void:
	if _action_bar:
		_action_bar.attack_button.disabled = false

func _show(text: String) -> void:
	if _prompt:
		_prompt.set_prompt_text(text)
		_prompt.show()

func _hide() -> void:
	if _prompt:
		_prompt.hide()

func _say(rows: Array) -> void:
	var box: CanvasLayer = get_tree().get_first_node_in_group("dialogue_box")
	if box == null or not box.has_method("play_sequence"):
		return
	var lines: Array[DialogueLine] = []
	for row in rows:
		var dl := DialogueLine.new()
		dl.speaker = row[0]
		dl.text = row[1]
		lines.append(dl)
	await box.play_sequence(lines)
