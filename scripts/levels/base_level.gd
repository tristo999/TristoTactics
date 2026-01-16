## Base class for all game levels
## Handles common level setup like music
extends Node2D
class_name BaseLevel

## The music track key to play for this level (from MusicManager.music_tracks)
@export var music_key: String = ""

func _ready():
	_setup_level()

func _setup_level():
	# Play level music if specified
	if music_key != "":
		MusicManager.play_music(music_key)
