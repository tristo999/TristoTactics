# SpriteFrameBuilder - Builds SpriteFrames at runtime from idle/walk spritesheets.
# All character sheets use the same layout:
#   480×320 px, 6 columns × 4 rows of 80×80 frames
#   Row 0 = up, Row 1 = down, Row 2 = left, Row 3 = right
class_name SpriteFrameBuilder

const FRAME_SIZE := Vector2i(80, 80)
const COLS := 6
const ROW_DIRS := ["up", "down", "left", "right"]
const ANIM_SPEED := 10.0

## Build a complete SpriteFrames resource from idle and walk spritesheets.
static func build(idle_texture: Texture2D, walk_texture: Texture2D) -> SpriteFrames:
	var sf := SpriteFrames.new()
	# Remove the default animation Godot adds
	if sf.has_animation(&"default"):
		sf.remove_animation(&"default")

	for row in ROW_DIRS.size():
		var dir: String = ROW_DIRS[row]
		_add_animation(sf, "idle_%s" % dir, idle_texture, row)
		_add_animation(sf, "walk_%s" % dir, walk_texture, row)

	return sf

## Add a single animation (6 frames from one row of a spritesheet).
static func _add_animation(sf: SpriteFrames, anim_name: String, texture: Texture2D, row: int) -> void:
	sf.add_animation(StringName(anim_name))
	sf.set_animation_speed(StringName(anim_name), ANIM_SPEED)
	sf.set_animation_loop(StringName(anim_name), true)

	for col in COLS:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(col * FRAME_SIZE.x, row * FRAME_SIZE.y, FRAME_SIZE.x, FRAME_SIZE.y)
		sf.add_frame(StringName(anim_name), atlas)
