## Base class for all game levels
## Handles common level setup like music
extends Node2D
class_name BaseLevel

const VictoryDefeatScreenScene = preload("res://scenes/ui/VictoryDefeatScreen.tscn")

## The music track key to play for this level (from AudioManager.music_tracks)
@export var music_key: String = ""

func _ready():
	_setup_level()
	EventBus.battle_ended.connect(_on_battle_ended)

func _setup_level():
	# Play level music if specified
	if music_key != "":
		AudioManager.play_music(music_key)

func _on_battle_ended(victory: bool) -> void:
	# Small delay so the final death animation plays
	await get_tree().create_timer(0.8).timeout
	var screen = VictoryDefeatScreenScene.instantiate()
	add_child(screen)
	screen.show_result(victory)
