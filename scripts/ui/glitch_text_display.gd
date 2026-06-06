# GlitchTextDisplay - CanvasLayer for raw cinematic text with typewriter + glitch effect.
# Used for the Guardian's corrupted transmissions, system messages, lore reveals, etc.
# No portrait, no speaker box — just atmospheric centered text on screen.
# Reusable: all walking scenes that need cinematic text add this as a child.
#
# Usage:
#   await glitch_display.play_line("...you are awake.", "GUARDIAN", true, true)
extends CanvasLayer
class_name GlitchTextDisplay

const CHARS_PER_SECOND := 18.0
const GLITCH_CHARS := "█▓▒░▄▀■□▪◆●○▸▹"

## Emitted when a play_floating animation fully completes (typewriter + hold + fade).
signal floating_text_done

var _bg: ColorRect
var _speaker_label: Label
var _text_label: RichTextLabel
var _advance_hint: Label
var _container: VBoxContainer
## When true, wraps all typewriter output in [center]...[/center] BBCode.
var _text_center: bool = false

func _ready() -> void:
	layer = 115
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("glitch_text_display")
	_build_ui()
	_container.visible = false

func _build_ui() -> void:
	# Subtle dark veil behind the text — scene still faintly visible.
	_bg = ColorRect.new()
	_bg.color = Color(0.0, 0.0, 0.0, 0.55)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.visible = false
	add_child(_bg)

	# Centered VBox
	_container = VBoxContainer.new()
	_container.global_position = Vector2.ZERO
	_container.set_anchors_preset(Control.PRESET_CENTER)
	_container.custom_minimum_size = Vector2(640, 1)
	_container.offset_left = -320
	_container.offset_right = 320
	_container.offset_top = -60
	_container.offset_bottom = 60
	_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_container.add_theme_constant_override("separation", 8)
	add_child(_container)

	# Speaker label — small caps, colored accent
	_speaker_label = Label.new()
	_speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speaker_label.add_theme_color_override("font_color", Color(0.55, 0.85, 0.55))
	_speaker_label.add_theme_font_size_override("font_size", 13)
	_container.add_child(_speaker_label)

	# Body text — uses RichTextLabel for future color/effect tags
	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.fit_content = true
	_text_label.scroll_active = false
	_text_label.custom_minimum_size = Vector2(640, 0)
	_text_label.add_theme_color_override("default_color", Color(0.88, 0.92, 0.88))
	_text_label.add_theme_font_size_override("normal_font_size", 18)
	_text_label.add_theme_constant_override("outline_size", 3)
	_text_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	_container.add_child(_text_label)

	# Advance prompt — blinks at bottom right of box
	_advance_hint = Label.new()
	_advance_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_advance_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	_advance_hint.add_theme_font_size_override("font_size", 11)
	_advance_hint.text = "[ space / click ]"
	_container.add_child(_advance_hint)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Display one line of cinematic text.
## speaker     — shown above the text in accent color (empty = no label)
## glitched    — if true, characters flicker with glitch noise before resolving
## wait_input  — if true, waits for ui_accept or left-click before returning
func play_line(
	text: String,
	speaker: String = "",
	glitched: bool = true,
	wait_input: bool = true
) -> void:
	# Substitute {player_name} if present
	var display_text := text.replace("{player_name}", PlayerDataManager.get_player_name())

	_speaker_label.text = speaker.to_upper() if speaker != "" else ""
	_speaker_label.visible = speaker != ""
	_text_label.text = ""
	_advance_hint.visible = false
	_container.visible = true
	_bg.visible = true

	if glitched:
		await _play_glitch_typewriter(display_text)
	else:
		await _play_plain_typewriter(display_text)

	_advance_hint.visible = wait_input
	if wait_input:
		await _wait_for_advance()

	_container.visible = false
	_bg.visible = false

## Hide immediately without waiting.
func hide_now() -> void:
	_container.visible = false
	_bg.visible = false

## Non-blocking floating text for Guardian transmissions.
## Text appears at the top of the screen with no dark backdrop.
## Plays the glitch typewriter, holds briefly, fades out.
## Returns IMMEDIATELY — the animation runs as a background coroutine.
func play_floating(text: String, speaker: String = "") -> void:
	_play_float_bg(text, speaker)

## Non-blocking floating text with custom pacing. Useful for interruption beats
## where the text should fade while it is still finishing its type-on.
func play_floating_custom(
	text: String,
	speaker: String = "",
	chars_per_second: float = CHARS_PER_SECOND,
	hold_duration: float = 0.0,
	fade_duration: float = 0.9,
	fade_overlap: float = 0.0,
	glitched: bool = true
) -> void:
	_play_float_custom_bg(text, speaker, chars_per_second, hold_duration, fade_duration, fade_overlap, glitched)

func _play_float_bg(text: String, speaker: String) -> void:
	var display_text := text.replace("{player_name}", PlayerDataManager.get_player_name())
	_prepare_floating_layout(speaker)
	await _play_glitch_typewriter(display_text)
	await get_tree().create_timer(2.2).timeout
	var tw := create_tween()
	tw.tween_property(_container, "modulate:a", 0.0, 0.9)
	await tw.finished
	_finish_floating_layout()

func _play_float_custom_bg(
	text: String,
	speaker: String,
	chars_per_second: float,
	hold_duration: float,
	fade_duration: float,
	_fade_overlap: float,  # unused — pre-started tweens deadlock if they finish before await
	glitched: bool
) -> void:
	var display_text := text.replace("{player_name}", PlayerDataManager.get_player_name())
	_prepare_floating_layout(speaker)
	if glitched:
		await _play_glitch_typewriter_at_speed(display_text, chars_per_second)
	else:
		await _play_plain_typewriter_at_speed(display_text, chars_per_second)
	if hold_duration > 0.0:
		await get_tree().create_timer(hold_duration).timeout
	var tw := create_tween()
	tw.tween_property(_container, "modulate:a", 0.0, fade_duration)
	await tw.finished
	_finish_floating_layout()

func _prepare_floating_layout(speaker: String) -> void:
	_speaker_label.text = speaker.to_upper() if speaker != "" else ""
	_speaker_label.visible = speaker != ""
	_text_label.text = ""
	_advance_hint.visible = false
	_container.modulate.a = 1.0
	_bg.visible = false
	# Reposition container to a tall band across the full top of the screen
	_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_container.offset_left = 40
	_container.offset_right = -40
	_container.offset_top = 28
	_container.offset_bottom = 240
	_text_label.custom_minimum_size = Vector2(0, 0)
	_text_label.add_theme_font_size_override("normal_font_size", 28)
	_text_center = true
	_container.visible = true

func _finish_floating_layout() -> void:
	_text_center = false
	_container.visible = false
	_container.modulate.a = 1.0
	# Restore centered layout and font size for regular play_line calls
	_text_label.custom_minimum_size = Vector2(640, 0)
	_text_label.add_theme_font_size_override("normal_font_size", 18)
	_container.set_anchors_preset(Control.PRESET_CENTER)
	_container.custom_minimum_size = Vector2(640, 1)
	_container.offset_left = -320
	_container.offset_right = 320
	_container.offset_top = -60
	_container.offset_bottom = 60
	# Emit AFTER all cleanup so the next play_floating call starts clean
	floating_text_done.emit()

# ---------------------------------------------------------------------------
# Internal typewriters
# ---------------------------------------------------------------------------

func _play_plain_typewriter(text: String) -> void:
	for i in range(text.length()):
		_text_label.text = text.substr(0, i + 1)
		if text[i] != " " and text[i] != ".":
			AudioManager.play_sfx_pitched("dialogue_type", 0.08)
		var ellipsis := i >= 2 and text[i] == "." and text[i-1] == "." and text[i-2] == "."
		await get_tree().create_timer(0.38 if ellipsis else 1.0 / CHARS_PER_SECOND).timeout

func _play_plain_typewriter_at_speed(text: String, chars_per_second: float) -> void:
	for i in range(text.length()):
		var resolved := text.substr(0, i + 1)
		_text_label.text = "[center]" + resolved + "[/center]" if _text_center else resolved
		if text[i] != " " and text[i] != ".":
			AudioManager.play_sfx_pitched("dialogue_type", 0.08)
		var ellipsis := i >= 2 and text[i] == "." and text[i-1] == "." and text[i-2] == "."
		await get_tree().create_timer(0.38 if ellipsis else 1.0 / maxf(chars_per_second, 0.01)).timeout

func _play_glitch_typewriter(text: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_text_label.text = ""
	for i in range(text.length()):
		# Each character may flicker with 1-3 glitch frames before resolving
		var glitch_count := rng.randi_range(0, 4) if text[i] != " " else 0
		for _g in range(glitch_count):
			var gc := GLITCH_CHARS[rng.randi() % GLITCH_CHARS.length()]
			var partial := text.substr(0, i) + gc
			_text_label.text = "[center]" + partial + "[/center]" if _text_center else partial
			await get_tree().create_timer(0.045).timeout
		var resolved := text.substr(0, i + 1)
		_text_label.text = "[center]" + resolved + "[/center]" if _text_center else resolved
		if text[i] != " " and text[i] != ".":
			AudioManager.play_sfx_pitched("dialogue_type", 0.08)
		var ellipsis := i >= 2 and text[i] == "." and text[i-1] == "." and text[i-2] == "."
		await get_tree().create_timer(0.38 if ellipsis else 1.0 / CHARS_PER_SECOND).timeout

func _play_glitch_typewriter_at_speed(text: String, chars_per_second: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_text_label.text = ""
	for i in range(text.length()):
		var glitch_count := rng.randi_range(0, 4) if text[i] != " " else 0
		for _g in range(glitch_count):
			var gc := GLITCH_CHARS[rng.randi() % GLITCH_CHARS.length()]
			var partial := text.substr(0, i) + gc
			_text_label.text = "[center]" + partial + "[/center]" if _text_center else partial
			await get_tree().create_timer(0.045).timeout
		var resolved := text.substr(0, i + 1)
		_text_label.text = "[center]" + resolved + "[/center]" if _text_center else resolved
		if text[i] != " " and text[i] != ".":
			AudioManager.play_sfx_pitched("dialogue_type", 0.08)
		var ellipsis := i >= 2 and text[i] == "." and text[i-1] == "." and text[i-2] == "."
		await get_tree().create_timer(0.38 if ellipsis else 1.0 / maxf(chars_per_second, 0.01)).timeout

func _wait_for_advance() -> void:
	# Small debounce — prevents instantly skipping due to held key that opened the trigger
	await get_tree().create_timer(0.2).timeout
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			break
