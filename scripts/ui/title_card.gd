# TitleCard - Displays the game title centered on screen.
# Fades in, holds, then fades out. Uses either a texture image or pixel font text.
# Set title_image_path to a res:// path to show an image instead of the label.
# Sits on a high CanvasLayer so it renders above everything except flash.
#
# Usage:
#   await title.show_title("TRISTO TACTICS", 1.0, 4.0, 1.5)
extends CanvasLayer
class_name TitleCard

## Optional image to show instead of the text label.
## Leave empty to use the text label fallback.
@export_file("*.png", "*.jpg", "*.jpeg") var title_image_path: String = "res://assets/440804f6-b786-479d-8a5b-991bb4a60880.png"

var _label: Label = null
var _image_rect: TextureRect = null

func _ready() -> void:
	layer = 105 # Above game world, below dialogue/flash layers
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("title_card")

	# --- Image display (used when title_image_path is set) ---
	if title_image_path != "":
		var tex := load(title_image_path) as Texture2D
		if tex:
			_image_rect = TextureRect.new()
			_image_rect.texture = tex
			_image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			_image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_image_rect.anchor_left = 0.0
			_image_rect.anchor_right = 1.0
			_image_rect.anchor_top = 0.0
			_image_rect.anchor_bottom = 1.0
			_image_rect.offset_left = 20
			_image_rect.offset_right = 20
			_image_rect.offset_top = -80
			_image_rect.offset_bottom = 0
			_image_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_image_rect.modulate.a = 0.0
			add_child(_image_rect)
			return

	# --- Text label fallback ---
	_label = Label.new()
	_label.text = ""
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.anchor_left = 0.0
	_label.anchor_right = 1.0
	_label.anchor_top = 0.1
	_label.anchor_bottom = 0.4
	_label.offset_left = 0
	_label.offset_right = 0
	_label.offset_top = 0
	_label.offset_bottom = 0
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font := load("res://assets/test/brackeys_platformer_assets/fonts/PixelOperator8-Bold.ttf") as Font
	if font:
		_label.add_theme_font_override("font", font)
	_label.add_theme_font_size_override("font_size", 32)
	_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	_label.modulate.a = 0.0
	add_child(_label)

## Display the title with fade in, hold, and fade out.
## The `text` parameter is only used by the label fallback.
## Returns when the full animation is complete.
func show_title(text: String, fade_in: float = 1.0, hold: float = 4.0, fade_out: float = 1.5) -> void:
	var target: CanvasItem = (_image_rect as CanvasItem) if _image_rect else (_label as CanvasItem)
	if not target:
		return
	if _label:
		_label.text = text

	var tween := create_tween()
	tween.tween_property(target, "modulate:a", 1.0, fade_in)
	tween.tween_interval(hold)
	tween.tween_property(target, "modulate:a", 0.0, fade_out)
	await tween.finished
