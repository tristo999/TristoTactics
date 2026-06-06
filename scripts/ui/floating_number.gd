## FloatingNumber - a tiny world-space popup ("+4", "-7") that rises and fades
## above a character. Used for reactive feedback that doesn't go through the
## full attack overlay (e.g. the healer's follow-up heal). Self-cleaning.
class_name FloatingNumber
extends RefCounted

static func spawn(anchor: Node2D, text: String, color: Color = Color.WHITE) -> void:
	if anchor == null or not is_instance_valid(anchor) or not anchor.is_inside_tree():
		return
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_font_size_override("font_size", 18)
	label.z_index = 200
	label.position = Vector2(-14, -46)  # above the sprite, roughly centered
	anchor.add_child(label)

	var tw := label.create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 30, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tw.set_parallel(false)
	tw.tween_callback(label.queue_free)
