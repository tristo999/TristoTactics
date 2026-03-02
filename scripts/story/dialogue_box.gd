# DialogueBox - Full-width bottom bar for dialogue sequences.
# Shows portrait, speaker name, and typewriter text. Click/Space/Enter to advance.
extends CanvasLayer

signal sequence_finished

const CHARS_PER_SECOND := 30.0

var _lines: Array[DialogueLine] = []
var _current_index: int = 0
var _typing: bool = false
var _full_text: String = ""
var _visible_chars: int = 0
var _char_timer: float = 0.0

var _root: PanelContainer
var _portrait_rect: TextureRect
var _speaker_label: Label
var _text_label: RichTextLabel
var _indicator: Label

func _ready() -> void:
	layer = 90
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

	# Typewriter effect
	if _typing:
		_char_timer += delta * CHARS_PER_SECOND
		while _char_timer >= 1.0 and _visible_chars < _full_text.length():
			_visible_chars += 1
			_char_timer -= 1.0
		_text_label.visible_characters = _visible_chars
		if _visible_chars >= _full_text.length():
			_typing = false
			_indicator.visible = true

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
		# First press — instant-fill the current line
		_visible_chars = _full_text.length()
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
	_full_text = line.text
	_text_label.text = line.text
	_visible_chars = 0
	_text_label.visible_characters = 0
	_typing = true
	_indicator.visible = false

	# Portrait
	if line.portrait:
		_portrait_rect.texture = line.portrait
	else:
		_portrait_rect.texture = null

func _close() -> void:
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 0.0, 0.1)
	await tween.finished
	_root.visible = false
	_lines.clear()
	sequence_finished.emit()
