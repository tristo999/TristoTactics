# NameEntryDisplay - CanvasLayer for in-scene name entry during cinematic sequences.
# Displays a prompt (glitch-styled) and a text field. Pressing Enter or clicking
# Confirm saves the name to PlayerDataManager and continues the sequence.
#
# Usage (from a StoryEvent or scene script):
#   var name = await name_entry.prompt("What is your name?")
extends CanvasLayer
class_name NameEntryDisplay

signal name_confirmed(entered_name: String)

var _bg: ColorRect
var _container: VBoxContainer
var _prompt_label: Label
var _line_edit: LineEdit
var _confirm_btn: Button

func _ready() -> void:
	layer = 116
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("name_entry_display")
	_build_ui()
	_container.visible = false
	_bg.visible = false

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0.0, 0.0, 0.0, 0.65)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg)

	_container = VBoxContainer.new()
	_container.set_anchors_preset(Control.PRESET_CENTER)
	_container.custom_minimum_size = Vector2(380, 1)
	_container.offset_left = -190
	_container.offset_right = 190
	_container.offset_top = -70
	_container.offset_bottom = 70
	_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_container.add_theme_constant_override("separation", 14)
	add_child(_container)

	_prompt_label = Label.new()
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_prompt_label.custom_minimum_size = Vector2(380, 0)
	_prompt_label.add_theme_color_override("font_color", Color(0.65, 0.9, 0.65))
	_prompt_label.add_theme_font_size_override("font_size", 16)
	_container.add_child(_prompt_label)

	_line_edit = LineEdit.new()
	_line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line_edit.max_length = 24
	_line_edit.placeholder_text = "enter your name"
	_line_edit.custom_minimum_size = Vector2(380, 0)
	_line_edit.add_theme_font_size_override("font_size", 18)
	_container.add_child(_line_edit)

	_confirm_btn = Button.new()
	_confirm_btn.text = "CONFIRM"
	_confirm_btn.custom_minimum_size = Vector2(160, 0)
	_container.add_child(_confirm_btn)
	_confirm_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER

	_confirm_btn.pressed.connect(_on_confirm)
	_line_edit.text_submitted.connect(func(_t: String) -> void: _on_confirm())

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Show the name entry UI with a given prompt. Awaitable — returns the entered name.
## Also saves to PlayerDataManager automatically.
func prompt(prompt_text: String) -> String:
	_prompt_label.text = prompt_text
	_line_edit.text = ""
	_container.visible = true
	_bg.visible = true
	_line_edit.grab_focus()

	var entered: String = await name_confirmed

	_container.visible = false
	_bg.visible = false
	return entered

# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _on_confirm() -> void:
	var n := _line_edit.text.strip_edges()
	if n.is_empty():
		n = "Hero"
	PlayerDataManager.set_player_name(n)
	name_confirmed.emit(n)
