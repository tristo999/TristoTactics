# VictoryDefeatScreen - Displayed when a battle ends in victory or defeat
extends CanvasLayer

signal return_to_menu_pressed

@onready var color_rect: ColorRect = $ColorRect
@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var subtitle_label: Label = $Panel/VBox/SubtitleLabel
@onready var menu_button: Button = $Panel/VBox/MenuButton

var _is_victory: bool = false

func _ready() -> void:
	menu_button.pressed.connect(_on_menu_button_pressed)
	# Start hidden
	color_rect.modulate.a = 0.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)
	layer = 100  # On top of everything

func show_result(victory: bool) -> void:
	_is_victory = victory
	
	if victory:
		title_label.text = "VICTORY"
		title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		subtitle_label.text = "All enemies have been defeated!"
		color_rect.color = Color(0.0, 0.0, 0.0, 0.6)
		MusicManager.play_music("victory")
	else:
		title_label.text = "DEFEAT"
		title_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
		subtitle_label.text = "Your forces have fallen..."
		color_rect.color = Color(0.15, 0.0, 0.0, 0.6)
		MusicManager.play_music("defeat")
	
	# Fade in the dark overlay
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, 0.6)
	
	# Fade in and scale up the panel after overlay
	tween.tween_property(panel, "modulate:a", 1.0, 0.4)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_menu_button_pressed() -> void:
	MusicManager.stop_music()
	return_to_menu_pressed.emit()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
