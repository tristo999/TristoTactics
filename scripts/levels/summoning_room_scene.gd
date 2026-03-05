# SummoningRoomScene - The player wakes up in the carved circle chamber after the
# Guardian flash. The authority has pulled them through. A door is ahead.
# Commander Vael approaches once the player reaches the door trigger.
#
# == Scene setup in editor ==
# Root: SummoningRoomScene (this script)
# Children:
#   • Tilemap          — summoning room tile layout with tilemap.gd script
#   • WalkingPlayer    — start position: center of summoning circle
#   • DialogueBox      — scenes/ui/DialogueBox.tscn  (Vael uses standard dialogue bar)
#   • CinematicTrigger [door_trigger] — at the door tile
#       events:
#         DialogueEvent → Vael lines (speaker "COMMANDER VAEL")
#         SceneChangeEvent → tutorial_scene.tscn
#
# The ScreenOverlay (bleed) is NOT carried over — summoning room starts clean.
# A fade-in from white is handled automatically below.
extends WalkingScene
class_name SummoningRoomScene

func _ready() -> void:
	super._ready()
	# Brief white-to-normal fade-in — player "wakes up" from the flash
	_fade_in_from_white()

func _fade_in_from_white() -> void:
	# Add a temporary white overlay that immediately fades out
	var overlay := ColorRect.new()
	var canvas := CanvasLayer.new()
	canvas.layer = 120
	add_child(canvas)
	canvas.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(1.0, 1.0, 1.0, 1.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 0.0, 1.2)
	await tween.finished
	canvas.queue_free()
