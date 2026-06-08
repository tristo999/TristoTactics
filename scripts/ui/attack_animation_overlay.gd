# AttackAnimationOverlay - Full-screen combat cutscene overlay
# Shows attacker and defender sprites in a centered panel with lunge, damage,
# and shake animations over a dimmed background.
# Autoloaded so any system can call play_attack_animation() and await it.
extends CanvasLayer

const FADE_DURATION := 0.15
const LUNGE_DURATION := 0.12
const LUNGE_RETURN_DURATION := 0.1
const SHAKE_DURATION := 0.3
const SHAKE_INTENSITY := 6.0
const HOLD_DURATION := 0.3
const LUNGE_DISTANCE := 40.0

# Character placement inside the box (fraction of box width)
const ATTACKER_X_FRAC := 0.35
const DEFENDER_X_FRAC := 0.65
const CHARACTER_Y_FRAC := 0.55
const CHARACTER_SCALE := Vector2(3.0, 3.0)

# Box sizing (fraction of viewport)
const BOX_WIDTH_FRAC := 0.55
const BOX_HEIGHT_FRAC := 0.35

var _root: Control # Fadeable root (CanvasLayer has no modulate)
var _backdrop: ColorRect # Full-screen dim
var _box: PanelContainer # Centered combat box
var _box_content: Control # Content area inside box (for sprites + label)
var _attacker_sprite: AnimatedSprite2D
var _defender_sprite: AnimatedSprite2D
var _damage_label: Label
var _is_playing: bool = false
signal _animation_completed

func _ready() -> void:
	layer = 100
	_build_ui()
	_root.visible = false

func _build_ui() -> void:
	# Root Control that we can fade (CanvasLayer has no modulate)
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Full-screen dark backdrop
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0, 0, 0, 0.75)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_backdrop)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Centered combat box
	_box = PanelContainer.new()
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Style: dark rounded box with a subtle border
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.border_color = Color(0.6, 0.6, 0.7, 0.6)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	_box.add_theme_stylebox_override("panel", style)
	_root.add_child(_box)

	# Content area inside the box — sprites and label live here
	_box_content = Control.new()
	_box_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_box_content)

	# Damage label (positioned later per-animation)
	_damage_label = Label.new()
	_damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_damage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_damage_label.add_theme_font_size_override("font_size", 32)
	_damage_label.z_index = 10
	_damage_label.visible = false
	_box_content.add_child(_damage_label)


## Main entry point — call with await.
## Returns after the full animation has finished.
## If an animation is already playing, the request is queued and played in order.
func play_attack_animation(attacker: CharacterBase, defender: CharacterBase, damage: int, is_crit: bool) -> void:
	while _is_playing:
		await _animation_completed
	_is_playing = true

	var vp_size := get_viewport().get_visible_rect().size

	# Size and center the box using anchors so it stays centered on any screen
	var box_w := vp_size.x * BOX_WIDTH_FRAC
	var box_h := vp_size.y * BOX_HEIGHT_FRAC
	_box.custom_minimum_size = Vector2(box_w, box_h)
	_box.anchor_left = 0.5
	_box.anchor_top = 0.5
	_box.anchor_right = 0.5
	_box.anchor_bottom = 0.5
	_box.offset_left = - box_w * 0.5
	_box.offset_top = - box_h * 0.5
	_box.offset_right = box_w * 0.5
	_box.offset_bottom = box_h * 0.5
	_box_content.size = Vector2(box_w, box_h)

	# Clone sprites
	_attacker_sprite = _clone_sprite(attacker)
	_defender_sprite = _clone_sprite(defender)

	if _attacker_sprite == null or _defender_sprite == null:
		_cleanup()
		return

	# Position characters inside the box (relative to box_content)
	var attacker_pos := Vector2(box_w * ATTACKER_X_FRAC, box_h * CHARACTER_Y_FRAC)
	var defender_pos := Vector2(box_w * DEFENDER_X_FRAC, box_h * CHARACTER_Y_FRAC)

	_attacker_sprite.position = attacker_pos
	_attacker_sprite.scale = CHARACTER_SCALE
	_attacker_sprite.z_index = 5

	_defender_sprite.position = defender_pos
	_defender_sprite.scale = CHARACTER_SCALE
	_defender_sprite.z_index = 5

	# Set facing for the overlay layout: attacker faces right, defender faces left
	_set_overlay_anim(_attacker_sprite, "idle_right")
	_set_overlay_anim(_defender_sprite, "idle_left")

	_box_content.add_child(_attacker_sprite)
	_box_content.add_child(_defender_sprite)

	# Setup damage label
	_damage_label.text = str(damage) + ("!" if is_crit else "")
	_damage_label.add_theme_color_override("font_color", Color.YELLOW if is_crit else Color.WHITE)
	if is_crit:
		_damage_label.add_theme_font_size_override("font_size", 42)
	else:
		_damage_label.add_theme_font_size_override("font_size", 32)
	_damage_label.size = Vector2(120, 50)
	_damage_label.position = defender_pos + Vector2(-60, -60)
	_damage_label.visible = false

	# --- Animation sequence ---
	# 1. Fade in
	_root.modulate.a = 0.0
	_root.visible = true
	var fade_in := create_tween()
	fade_in.tween_property(_root, "modulate:a", 1.0, FADE_DURATION)
	await fade_in.finished

	# 2. Brief hold so the player sees the two characters
	await get_tree().create_timer(0.15).timeout

	# 3. Attacker lunges toward defender
	var lunge_target := attacker_pos + Vector2(LUNGE_DISTANCE, 0)
	var lunge := create_tween()
	lunge.tween_property(_attacker_sprite, "position", lunge_target, LUNGE_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	await lunge.finished

	# 4. Play damage SFX via existing system
	EventBus.character_attacked.emit(attacker, defender, damage, is_crit)

	# 5. Show damage number + defender shake
	_damage_label.visible = true
	_damage_label.modulate.a = 1.0
	await _shake_node(_defender_sprite, SHAKE_DURATION, SHAKE_INTENSITY)

	# 6. Attacker returns to original position
	var lunge_back := create_tween()
	lunge_back.tween_property(_attacker_sprite, "position", attacker_pos, LUNGE_RETURN_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await lunge_back.finished

	# 7. Hold briefly so damage number is readable
	await get_tree().create_timer(HOLD_DURATION).timeout

	# 8. Float damage number up and fade
	var label_tween := create_tween().set_parallel(true)
	label_tween.tween_property(_damage_label, "position:y", _damage_label.position.y - 30, 0.3)
	label_tween.tween_property(_damage_label, "modulate:a", 0.0, 0.3)
	await label_tween.finished

	# 9. Fade out overlay
	var fade_out := create_tween()
	fade_out.tween_property(_root, "modulate:a", 0.0, FADE_DURATION)
	await fade_out.finished

	_cleanup()


## Heal counterpart of play_attack_animation — same centered box, but the healer
## gestures toward the ally and a green "+N" rises instead of a damage hit.
## Used by the Healer's reactive follow-up. Await it.
func play_heal_animation(healer: CharacterBase, target: CharacterBase, amount: int) -> void:
	while _is_playing:
		await _animation_completed
	_is_playing = true

	var vp_size := get_viewport().get_visible_rect().size
	var box_w := vp_size.x * BOX_WIDTH_FRAC
	var box_h := vp_size.y * BOX_HEIGHT_FRAC
	_box.custom_minimum_size = Vector2(box_w, box_h)
	_box.anchor_left = 0.5
	_box.anchor_top = 0.5
	_box.anchor_right = 0.5
	_box.anchor_bottom = 0.5
	_box.offset_left = - box_w * 0.5
	_box.offset_top = - box_h * 0.5
	_box.offset_right = box_w * 0.5
	_box.offset_bottom = box_h * 0.5
	_box_content.size = Vector2(box_w, box_h)

	# Healer occupies the "attacker" slot, the mended ally the "defender" slot.
	_attacker_sprite = _clone_sprite(healer)
	_defender_sprite = _clone_sprite(target)
	if _attacker_sprite == null or _defender_sprite == null:
		_cleanup()
		return

	var healer_pos := Vector2(box_w * ATTACKER_X_FRAC, box_h * CHARACTER_Y_FRAC)
	var ally_pos := Vector2(box_w * DEFENDER_X_FRAC, box_h * CHARACTER_Y_FRAC)
	_attacker_sprite.position = healer_pos
	_attacker_sprite.scale = CHARACTER_SCALE
	_attacker_sprite.z_index = 5
	_defender_sprite.position = ally_pos
	_defender_sprite.scale = CHARACTER_SCALE
	_defender_sprite.z_index = 5
	_set_overlay_anim(_attacker_sprite, "idle_right")
	_set_overlay_anim(_defender_sprite, "idle_left")
	_box_content.add_child(_attacker_sprite)
	_box_content.add_child(_defender_sprite)

	# Green "+N" over the ally.
	_damage_label.text = "+" + str(amount)
	_damage_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	_damage_label.add_theme_font_size_override("font_size", 36)
	_damage_label.size = Vector2(120, 50)
	_damage_label.position = ally_pos + Vector2(-60, -60)
	_damage_label.visible = false

	# 1. Fade in
	_root.modulate.a = 0.0
	_root.visible = true
	var fade_in := create_tween()
	fade_in.tween_property(_root, "modulate:a", 1.0, FADE_DURATION)
	await fade_in.finished

	# 2. Brief hold
	await get_tree().create_timer(0.15).timeout

	# 3. Healer gestures toward the ally (gentle forward bob, no impact)
	var gesture := create_tween()
	gesture.tween_property(_attacker_sprite, "position", healer_pos + Vector2(LUNGE_DISTANCE * 0.5, -6), 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	gesture.tween_property(_attacker_sprite, "position", healer_pos, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)

	# 4. Green glow pulse on the ally + reveal the number
	_damage_label.visible = true
	_damage_label.modulate.a = 1.0
	var glow := create_tween()
	glow.tween_property(_defender_sprite, "modulate", Color(0.5, 1.0, 0.65), 0.16)
	glow.tween_property(_defender_sprite, "modulate", Color.WHITE, 0.32)
	# Await the LONGER tween (glow, 0.48s) — it covers the gesture (0.38s). Do NOT
	# await the gesture afterward: it finishes during the glow await, and awaiting an
	# already-finished tween's `finished` signal hangs forever (the signal won't fire
	# again) — which left the heal overlay stuck on screen and froze the battle.
	await glow.finished
	if is_instance_valid(gesture) and gesture.is_running():
		await gesture.finished

	# 5. Hold so the number is readable
	await get_tree().create_timer(HOLD_DURATION).timeout

	# 6. Float the number up and fade
	var label_tween := create_tween().set_parallel(true)
	label_tween.tween_property(_damage_label, "position:y", _damage_label.position.y - 30, 0.3)
	label_tween.tween_property(_damage_label, "modulate:a", 0.0, 0.3)
	await label_tween.finished

	# 7. Fade out overlay
	var fade_out := create_tween()
	fade_out.tween_property(_root, "modulate:a", 0.0, FADE_DURATION)
	await fade_out.finished

	_cleanup()


func _shake_node(node: Node2D, duration: float, intensity: float) -> void:
	var original_pos := node.position
	var elapsed := 0.0
	while elapsed < duration:
		var shake_offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		node.position = original_pos + shake_offset
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	node.position = original_pos


func _clone_sprite(character: CharacterBase) -> AnimatedSprite2D:
	var source: AnimatedSprite2D = null
	for child in character.get_children():
		if child is AnimatedSprite2D:
			source = child
			break
	if source == null:
		push_warning("AttackAnimationOverlay: No AnimatedSprite2D found on %s" % character.name)
		return null

	var clone := AnimatedSprite2D.new()
	clone.sprite_frames = source.sprite_frames
	clone.animation = source.animation
	clone.flip_h = source.flip_h
	clone.play()
	return clone


## Try to play a specific animation on a clone; fall back to flip_h if not available.
func _set_overlay_anim(sprite: AnimatedSprite2D, anim_name: String) -> void:
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
		sprite.flip_h = false
	else:
		# Fallback for sprites without directional animations
		if anim_name.ends_with("_left"):
			sprite.flip_h = true
		else:
			sprite.flip_h = false


func _cleanup() -> void:
	_root.visible = false
	_root.modulate.a = 1.0
	_damage_label.visible = false
	if _attacker_sprite:
		_attacker_sprite.queue_free()
		_attacker_sprite = null
	if _defender_sprite:
		_defender_sprite.queue_free()
		_defender_sprite = null
	_is_playing = false
	_animation_completed.emit()
