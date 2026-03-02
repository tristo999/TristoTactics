# SplashScreen — Studio logo reveal before the main menu.
# Fades in the logo, holds briefly, fades to black, then quick-transitions to MainMenu.
extends Control

## How long the fade-in takes (seconds).
@export var fade_in_duration: float = 0.8
## How long the logo stays fully visible.
@export var hold_duration: float = 1.0
## How long the fade-to-black takes.
@export var fade_out_duration: float = 0.6
## Brief black hold before switching to main menu.
@export var black_hold_duration: float = 0.3

@onready var logo: TextureRect = $Logo
@onready var background: ColorRect = $Background

func _ready() -> void:
	# Start fully black — logo invisible
	background.color = Color.BLACK
	logo.modulate.a = 0.0

	# Allow skipping with any input
	set_process_input(true)

	_play_sequence()

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		if event.pressed:
			_skip_to_menu()

func _skip_to_menu() -> void:
	set_process_input(false)
	# Kill any running tweens
	var tweens := get_tree().get_processed_tweens()
	for t in tweens:
		t.kill()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _play_sequence() -> void:
	# 1. Fade logo in
	var fade_in := create_tween()
	fade_in.tween_property(logo, "modulate:a", 1.0, fade_in_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	await fade_in.finished

	# 2. Hold on the logo
	await get_tree().create_timer(hold_duration).timeout

	# 3. Fade everything to black (fade logo out)
	var fade_out := create_tween()
	fade_out.tween_property(logo, "modulate:a", 0.0, fade_out_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	await fade_out.finished

	# 4. Brief black hold
	await get_tree().create_timer(black_hold_duration).timeout

	# 5. Transition to main menu
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
