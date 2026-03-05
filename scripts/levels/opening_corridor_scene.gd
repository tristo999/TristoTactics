# OpeningCorridorScene - The first playable scene in TristoTactics.
# The player wakes in a dark corridor and walks upward toward a light they can't
# explain. The Guardian contacts them mid-walk (via CinematicTriggers placed on
# specific tiles). After the white flash they are ripped away to the summoning room.
#
# == Scene setup in editor ==
# Root node: OpeningCorridorScene (this script)
# Children (add in editor):
#   • Tilemap          — corridor TileMapLayer tree with tilemap.gd script
#   • WalkingPlayer    — scenes/characters/WalkingPlayer.tscn
#   • DialogueBox      — scenes/ui/DialogueBox.tscn
#   • CinematicTrigger × N — positioned on corridor tiles
#
# CinematicTrigger events are authored in _setup_triggers() below because custom
# Resource subclasses (StoryEvent) cannot be embedded as sub_resources in .tscn files.
#
# The ScreenOverlay, GlitchTextDisplay, and NameEntryDisplay are added automatically
# by this script — do NOT add them manually in the editor.
extends WalkingScene
class_name OpeningCorridorScene

## Starting darkness radius — small bubble around the player.
@export_range(0.0, 1.0) var start_light_radius: float = 0.07
## Starting darkness softness.
@export_range(0.0, 0.5) var start_light_softness: float = 0.08
## Seconds the screen stays fully black before the light fades in.
@export var fade_in_delay: float = 3.0
## How long the light bubble takes to appear.
@export var fade_in_duration: float = 3.5
## Fog intensity inside the light circle.
@export_range(0.0, 1.0) var fog_intensity: float = 0.22

func _ready() -> void:
	super._ready() # plays music if music_key is set, adds black backdrop

	# Stop any music from the previous scene (e.g. main menu)
	AudioManager.stop_music()

	# Procedurally add the three effect/UI layers —
	# keeps the scene tree clean and avoids manual layer ordering mistakes.
	var overlay := ScreenOverlay.new()
	add_child(overlay)
	overlay.set_darkness(1.0)
	overlay.set_light_radius(0.0) # Start fully black — no light at all
	overlay.set_light_softness(0.0) # Zero softness so there's no gradient leak
	overlay.set_fog(fog_intensity)

	var glitch := GlitchTextDisplay.new()
	add_child(glitch)

	var name_entry := NameEntryDisplay.new()
	add_child(name_entry)

	# Lock player for the entire fade-in — completely frozen during the black hold.
	var player := get_tree().get_first_node_in_group("walking_player") as WalkingPlayer
	if player:
		player.walk_speed = 2.5
		player.first_step_boost = 1.0
		player.sprite.speed_scale = 0.25
		player.lock_movement()
	else:
		push_warning("[OpeningCorridorScene] WalkingPlayer not found to set speed")

	# Slow fade-in: total black hold → light + softness tween together → unlock.
	var fade_tween := create_tween()
	fade_tween.tween_interval(fade_in_delay)
	fade_tween.tween_callback(func() -> void:
		# After the black hold, tween radius and softness together in a second tween
		var light_tween := create_tween()
		light_tween.set_parallel(true)
		light_tween.tween_method(overlay.set_light_radius, 0.0, start_light_radius, fade_in_duration)
		light_tween.tween_method(overlay.set_light_softness, 0.0, start_light_softness, fade_in_duration)
		if player:
			light_tween.set_parallel(false)
			light_tween.tween_callback(player.unlock_movement)
			# After movement unlocks, tell the player to start walking
			light_tween.tween_callback(func() -> void:
				var intro := DialogueEvent.new()
				var l := DialogueLine.new()
				l.text = "...walk forward."
				l.glitched = true
				intro.lines.append(l)
				player.lock_movement()
				await intro.execute(get_tree())
				player.unlock_movement()
			)
	)

	# Build trigger event arrays in code — custom Resource subclasses cannot be
	# embedded as sub_resource in .tscn files, so we author them here instead.
	call_deferred("_setup_triggers")

# ---------------------------------------------------------------------------
# Trigger authoring — add all opening corridor story beats here.
# Each CinematicTrigger node is placed in the editor for positioning;
# its events array is filled in below so the scene file stays clean.
# ---------------------------------------------------------------------------
func _setup_triggers() -> void:
	_setup_guardian_contact1()
	_setup_guardian_contact2()
	_setup_name_and_flash()

func _setup_guardian_contact1() -> void:
	var trigger := get_node_or_null("GuardianContact1") as CinematicTrigger
	if not trigger:
		push_warning("[OpeningCorridorScene] GuardianContact1 node not found")
		return

	var e1 := DialogueEvent.new()
	var l1 := DialogueLine.new()
	l1.text = "...static... ...can you hear me...?"
	l1.glitched = true
	e1.lines.append(l1)

	trigger.events.clear()
	trigger.events.append(e1)

func _setup_guardian_contact2() -> void:
	var trigger := get_node_or_null("GuardianContact2") as CinematicTrigger
	if not trigger:
		push_warning("[OpeningCorridorScene] GuardianContact2 node not found")
		return

	var e1 := DialogueEvent.new()
	var l1 := DialogueLine.new()
	l1.text = "You are... between places. Do not stop moving."
	l1.glitched = true
	e1.lines.append(l1)
	var l2 := DialogueLine.new()
	l2.text = "I found you in the break. I don't have much time."
	l2.glitched = true
	e1.lines.append(l2)

	trigger.events.clear()
	trigger.events.append(e1)

func _setup_name_and_flash() -> void:
	var trigger := get_node_or_null("NameAndFlash") as CinematicTrigger
	if not trigger:
		push_warning("[OpeningCorridorScene] NameAndFlash node not found")
		return

	# Ask the name
	var ask := DialogueEvent.new()
	var l_ask := DialogueLine.new()
	l_ask.text = "Before you go — what is your name?"
	l_ask.glitched = true
	ask.lines.append(l_ask)

	# Name entry
	var name_evt := NameEntryEvent.new()
	name_evt.prompt_text = "What is your name?"

	# Guardian echoes the name back
	var echo := DialogueEvent.new()
	var l_echo := DialogueLine.new()
	l_echo.text = "{player_name}. I will remember you."
	l_echo.glitched = true
	echo.lines.append(l_echo)

	# Brief pause, then white flash and scene change
	var wait := WaitEvent.new()
	wait.duration = 0.5

	var flash := FlashEvent.new()
	flash.hold_and_cut = true
	flash.fade_in = 0.3

	var change := SceneChangeEvent.new()
	change.scene_path = "res://scenes/levels/test_scene.tscn"

	trigger.events.clear()
	trigger.events.append(ask)
	trigger.events.append(name_evt)
	trigger.events.append(echo)
	trigger.events.append(wait)
	trigger.events.append(flash)

	# Hold the white screen for 3 seconds before switching scenes
	var flash_hold_wait := WaitEvent.new()
	flash_hold_wait.duration = 3.0
	trigger.events.append(flash_hold_wait)

	trigger.events.append(change)
