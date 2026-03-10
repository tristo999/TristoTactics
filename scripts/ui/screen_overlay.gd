# ScreenOverlay - Manages full-screen visual effects for walking scenes:
#   • Fog:      animated procedural mist drifting across the scene.
#   • Darkness: punches a lit circle around the player, rest black.
#   • Bleed:    color-tints toward the Act-2 destruction palette.
#   • Flash:    full-screen color flash (white for warp/wakeup moments).
#
# Render order (bottom → top): Fog → Darkness → Bleed → Flash.
# Fog renders first so it's only visible inside the darkness light circle.
#
# Add as a child of any scene that needs these effects (opening corridor, etc.).
# Register via group "screen_overlay" so StoryEvents can find it with one call.
extends CanvasLayer
class_name ScreenOverlay

var _fog_rect: ColorRect
var _darkness_rect: ColorRect
var _bleed_rect: ColorRect
var _flash_rect: ColorRect
var _fog_mat: ShaderMaterial
var _darkness_mat: ShaderMaterial
var _bleed_mat: ShaderMaterial

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("screen_overlay")
	_build_rects()
	# Ensure flash rect is fully transparent at scene start
	if _flash_rect:
		_flash_rect.color = Color(1.0, 1.0, 1.0, 0.0)

func _build_rects() -> void:
	# --- Fog (renders first — sits beneath darkness mask) ---
	_fog_rect = ColorRect.new()
	_fog_rect.color = Color(0, 0, 0, 0)
	_fog_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fog_mat = ShaderMaterial.new()
	var fog_shader := load("res://shaders/fog_overlay.gdshader") as Shader
	if fog_shader:
		_fog_mat.shader = fog_shader
	else:
		push_warning("[ScreenOverlay] FAILED to load fog_overlay.gdshader")
	_fog_rect.material = _fog_mat
	add_child(_fog_rect)

	# --- Darkness ---
	_darkness_rect = ColorRect.new()
	_darkness_rect.color = Color(0, 0, 0, 0) # transparent fallback if shader fails
	_darkness_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_darkness_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_darkness_mat = ShaderMaterial.new()
	var darkness_shader := load("res://shaders/darkness_overlay.gdshader") as Shader
	if darkness_shader:
		_darkness_mat.shader = darkness_shader
	else:
		push_warning("[ScreenOverlay] FAILED to load darkness_overlay.gdshader")
	_darkness_rect.material = _darkness_mat
	add_child(_darkness_rect)

	# --- Bleed ---
	_bleed_rect = ColorRect.new()
	_bleed_rect.color = Color(0, 0, 0, 0) # transparent fallback if shader fails
	_bleed_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bleed_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bleed_mat = ShaderMaterial.new()
	var bleed_shader := load("res://shaders/bleed_overlay.gdshader") as Shader
	if bleed_shader:
		_bleed_mat.shader = bleed_shader
	else:
		push_warning("[ScreenOverlay] FAILED to load bleed_overlay.gdshader")
	_bleed_rect.material = _bleed_mat
	add_child(_bleed_rect)

	# --- Flash ---
	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.color = Color(1.0, 1.0, 1.0, 0.0)
	add_child(_flash_rect)

# ---------------------------------------------------------------------------
# Darkness API
# ---------------------------------------------------------------------------

## Set how strong the darkness vignette is (0 = off, 1 = full black except circle).
func set_darkness(value: float) -> void:
	_darkness_mat.set_shader_parameter("darkness", value)

## Smoothly tween darkness from its current value to `to` over `duration` seconds.
func tween_darkness(to: float, duration: float) -> void:
	var current_var = _darkness_mat.get_shader_parameter("darkness")
	var current: float = float(current_var) if current_var != null else 0.0
	var tween := create_tween()
	tween.tween_method(set_darkness, current, to, duration)
	await tween.finished

## Set the light circle's center in normalized screen space (default = center = vec2(0.5,0.5)).
func set_light_center(normalized_pos: Vector2) -> void:
	_darkness_mat.set_shader_parameter("light_center", normalized_pos)

## Set the radius of the lit area in normalized screen units.
func set_light_radius(r: float) -> void:
	_darkness_mat.set_shader_parameter("radius", r)

## Set the softness of the lit circle's edge.
func set_light_softness(s: float) -> void:
	_darkness_mat.set_shader_parameter("softness", s)

## Completely hide the darkness layer (called after fullly opening during Phase 5).
func hide_darkness() -> void:
	_darkness_rect.visible = false

## Returns true if the darkness rect has been permanently hidden.
func is_darkness_hidden() -> bool:
	return not _darkness_rect.visible

# ---------------------------------------------------------------------------
# Fog API
# ---------------------------------------------------------------------------

## Set fog intensity (0 = invisible, 1 = full fog).
func set_fog(value: float) -> void:
	_fog_mat.set_shader_parameter("intensity", value)

## Smoothly tween fog intensity.
func tween_fog(to: float, duration: float) -> void:
	var current_var = _fog_mat.get_shader_parameter("intensity")
	var current: float = float(current_var) if current_var != null else 0.0
	var tween := create_tween()
	tween.tween_method(set_fog, current, to, duration)
	await tween.finished

## Set the fog drift speed.
func set_fog_speed(s: float) -> void:
	_fog_mat.set_shader_parameter("speed", s)

## Set the fog noise scale (smaller = larger cloud shapes).
func set_fog_scale(s: float) -> void:
	_fog_mat.set_shader_parameter("scale", s)

# ---------------------------------------------------------------------------
# Bleed API
# ---------------------------------------------------------------------------

## Set the Bleed intensity (0 = invisible, 1 = full Act-2 tint).
func set_bleed(value: float) -> void:
	_bleed_mat.set_shader_parameter("intensity", value)

## Smoothly tween the bleed intensity.
func tween_bleed(to: float, duration: float) -> void:
	var current_var = _bleed_mat.get_shader_parameter("intensity")
	var current: float = float(current_var) if current_var != null else 0.0
	var tween := create_tween()
	tween.tween_method(set_bleed, current, to, duration)
	await tween.finished

# ---------------------------------------------------------------------------
# Flash API
# ---------------------------------------------------------------------------

## Play a full-screen flash: fade to `color`, hold, then fade back out.
func flash(
	color: Color = Color.WHITE,
	fade_in: float = 0.12,
	hold: float = 0.35,
	fade_out: float = 0.55
) -> void:
	_flash_rect.color = Color(color.r, color.g, color.b, 0.0)
	var tween := create_tween()
	tween.tween_property(_flash_rect, "color:a", 1.0, fade_in)
	tween.tween_interval(hold)
	tween.tween_property(_flash_rect, "color:a", 0.0, fade_out)
	await tween.finished

## Flash to full white and STAY there (for scene transitions — caller changes scene
## while screen is white, so the new scene fades in naturally).
func flash_hold(color: Color = Color.WHITE, fade_in: float = 0.2) -> void:
	_flash_rect.color = Color(color.r, color.g, color.b, 0.0)
	var tween := create_tween()
	tween.tween_property(_flash_rect, "color:a", 1.0, fade_in)
	await tween.finished

## Set the flash rect color (without changing alpha).
func set_flash_color(color: Color) -> void:
	_flash_rect.color = Color(color.r, color.g, color.b, _flash_rect.color.a)

## Set the flash rect alpha directly (for manual multi-step transitions).
func set_flash_alpha(alpha: float) -> void:
	_flash_rect.color.a = alpha

## Get the current flash rect alpha.
func get_flash_alpha() -> float:
	return _flash_rect.color.a
