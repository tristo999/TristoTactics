# WalkingScene - Base script for free-roaming walking scenes.
# No turn order, no battle manager. Player moves freely with WASD/arrow keys.
# Camera is embedded in WalkingPlayer and follows automatically.
#
# Adds a black backdrop on CanvasLayer -10 so areas outside the tilemap are always
# black (Forward Plus renderer ignores default_clear_color).
extends Node2D
class_name WalkingScene

## Music track to play when this scene loads (from AudioManager.music_tracks).
## Leave empty for silence.
@export var music_key: String = ""

func _ready() -> void:
	_add_black_backdrop()
	if music_key != "":
		AudioManager.play_music(music_key)

## Solid black behind everything — prevents gray/default-color showing outside tiles.
func _add_black_backdrop() -> void:
	var bg_canvas := CanvasLayer.new()
	bg_canvas.layer = -10
	add_child(bg_canvas)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_canvas.add_child(bg)
