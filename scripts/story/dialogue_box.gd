# DialogueBox - Full-width bottom bar for dialogue sequences.
# Shows portrait, speaker name, and typewriter text. Click/Space/Enter to advance.
# Supports per-line glitch mode: characters flicker through noise before resolving.
extends CanvasLayer

signal sequence_finished

const CHARS_PER_SECOND := 30.0
const GLITCH_CHARS := "█▓▒░▄▀■□▪◆●○▸▹"
const GLITCH_CHAR_DELAY := 0.04

var _lines: Array[DialogueLine] = []
var _current_index: int = 0
var _typing: bool = false
var _glitch_typing: bool = false # true when running the async glitch coroutine
var _glitch_generation: int = 0 # incremented each line to cancel stale coroutines
var _full_text: String = ""
var _visible_chars: int = 0
var _char_timer: float = 0.0
var _rng := RandomNumberGenerator.new()
var _current_chars_per_second: float = CHARS_PER_SECOND
var _current_sfx_key: String = "dialogue_type"

var _root: PanelContainer
var _portrait_rect: TextureRect
var _speaker_label: Label
var _text_label: RichTextLabel
var _indicator: Label

func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("dialogue_box")
	_build_ui()
	_root.visible = false

func _build_ui() -> void:
	# Root panel — anchored to bottom, full width
	_root = PanelContainer.new()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_root.anchor_left = 0.0
	_root.anchor_right = 1.0
	_root.anchor_top = 1.0
	_root.anchor_bottom = 1.0
	_root.offset_top = -140
	_root.offset_bottom = 0
	_root.offset_left = 0
	_root.offset_right = 0

	# Panel style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.1, 0.92)
	style.border_color = Color(0.5, 0.5, 0.6, 0.5)
	style.border_width_top = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	_root.add_theme_stylebox_override("panel", style)

	# HBox: portrait | text column
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	_root.add_child(hbox)

	# Portrait container — fixed size box with border
	var portrait_panel := PanelContainer.new()
	portrait_panel.custom_minimum_size = Vector2(80, 80)
	var portrait_style := StyleBoxFlat.new()
	portrait_style.bg_color = Color(0.12, 0.12, 0.18, 1.0)
	portrait_style.border_color = Color(0.4, 0.4, 0.5, 0.6)
	portrait_style.set_border_width_all(1)
	portrait_style.set_corner_radius_all(4)
	portrait_panel.add_theme_stylebox_override("panel", portrait_style)
	hbox.add_child(portrait_panel)

	_portrait_rect = TextureRect.new()
	_portrait_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait_rect.custom_minimum_size = Vector2(80, 80)
	portrait_panel.add_child(_portrait_rect)

	# VBox: speaker name + body text
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(vbox)

	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 16)
	_speaker_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	vbox.add_child(_speaker_label)

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.fit_content = true
	_text_label.scroll_active = false
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_label.add_theme_font_size_override("normal_font_size", 14)
	vbox.add_child(_text_label)

	# Advance indicator (bottom-right)
	_indicator = Label.new()
	_indicator.text = "▼"
	_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_indicator.add_theme_font_size_override("font_size", 12)
	_indicator.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	vbox.add_child(_indicator)

func _process(delta: float) -> void:
	if not _root.visible:
		return

	# Normal (non-glitch) typewriter — glitch typing is handled by its own coroutine
	if _typing and not _glitch_typing:
		var prev_chars := _visible_chars
		_char_timer += delta * _current_chars_per_second
		while _char_timer >= 1.0 and _visible_chars < _full_text.length():
			_visible_chars += 1
			_char_timer -= 1.0
		if _visible_chars > prev_chars:
			var last_char := _full_text[_visible_chars - 1]
			if last_char != " " and last_char != ".":
				AudioManager.play_sfx_pitched(_current_sfx_key, 0.08)
		_text_label.visible_characters = _visible_chars
		if _visible_chars >= _full_text.length():
			_typing = false
			_on_typing_finished()

func _unhandled_input(event: InputEvent) -> void:
	if not _root.visible:
		return

	var advance := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance = true
	elif event.is_action_pressed("ui_accept"):
		advance = true

	if not advance:
		return

	get_viewport().set_input_as_handled()

	if _typing:
		# First press — instant-fill the current line (works for both normal and glitch)
		_glitch_typing = false # signal the glitch coroutine to stop
		_visible_chars = _full_text.length()
		_text_label.text = _full_text
		_text_label.visible_characters = _visible_chars
		_typing = false
		_indicator.visible = true
	else:
		# Advance to next line
		_current_index += 1
		if _current_index < _lines.size():
			_show_line(_lines[_current_index])
		else:
			_close()

## Start a dialogue sequence. Awaitable — resolves when the player finishes all lines.
func play_sequence(lines: Array[DialogueLine]) -> void:
	if lines.is_empty():
		sequence_finished.emit()
		return

	_lines = lines
	_current_index = 0
	_show_line(_lines[0])
	_root.visible = true
	_root.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 1.0, 0.15)

	# Wait for the sequence to finish
	await sequence_finished

func _show_line(line: DialogueLine) -> void:
	_speaker_label.text = line.speaker
	_speaker_label.visible = line.speaker != ""
	_current_chars_per_second = line.chars_per_second if line.chars_per_second > 0.0 else CHARS_PER_SECOND
	_current_sfx_key = line.type_sfx_key if line.type_sfx_key != "" else "dialogue_type"
	# Substitute {player_name} with the actual player name at display time
	var display_text := line.text.replace("{player_name}", PlayerDataManager.get_player_name())
	_full_text = display_text
	_text_label.text = display_text
	_visible_chars = 0
	_text_label.visible_characters = 0
	_typing = true
	_glitch_typing = false
	_glitch_generation += 1 # invalidate any old glitch coroutine
	_indicator.visible = false

	# Portrait
	if line.portrait:
		_portrait_rect.texture = line.portrait
	else:
		_portrait_rect.texture = null

	# Start glitch typewriter coroutine if flagged
	if line.glitched:
		_play_glitch_typewriter(display_text, _glitch_generation)

## Async glitch typewriter — each character flickers through random noise glyphs
## before resolving to the real character. Runs alongside _process; skippable.
## The `gen` parameter ensures stale coroutines from previous lines exit cleanly.
func _play_glitch_typewriter(text: String, gen: int) -> void:
	_glitch_typing = true
	_rng.randomize()
	_text_label.visible_characters = -1 # show all (we control text content directly)
	_text_label.text = ""
	for i in range(text.length()):
		if gen != _glitch_generation or not _glitch_typing:
			return # player skipped or new line started
		var glitch_count := _rng.randi_range(0, 3) if text[i] != " " else 0
		for _g in range(glitch_count):
			if gen != _glitch_generation or not _glitch_typing:
				return
			var gc := GLITCH_CHARS[_rng.randi() % GLITCH_CHARS.length()]
			_text_label.text = text.substr(0, i) + gc
			await get_tree().create_timer(GLITCH_CHAR_DELAY).timeout
		# Check again after inner loop — skip may have happened during last timer
		if gen != _glitch_generation or not _glitch_typing:
			return
		_text_label.text = text.substr(0, i + 1)
		if text[i] != " " and text[i] != ".":
			AudioManager.play_sfx_pitched(_current_sfx_key, 0.08)
		# Pause after an ellipsis resolves
		var ellipsis_pause := i >= 2 and text[i] == "." and text[i - 1] == "." and text[i - 2] == "."
		await get_tree().create_timer(0.38 if ellipsis_pause else 1.0 / _current_chars_per_second).timeout
	# Finished naturally
	if gen == _glitch_generation and _glitch_typing:
		_glitch_typing = false
		_typing = false
		_on_typing_finished()


func _on_typing_finished() -> void:
	var line := _lines[_current_index]
	if line.auto_advance_delay >= 0.0:
		_indicator.visible = false
		_do_auto_advance(line.auto_advance_delay)
	else:
		_indicator.visible = true


func _do_auto_advance(delay: float) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	_current_index += 1
	if _current_index < _lines.size():
		_show_line(_lines[_current_index])
	else:
		_close()

func _close() -> void:
	_glitch_generation += 1 # kill any lingering glitch coroutine
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 0.0, 0.1)
	await tween.finished
	_root.visible = false
	_lines.clear()
	# Small debounce — prevents the closing click from leaking into the next event
	await get_tree().create_timer(0.15).timeout
	sequence_finished.emit()
