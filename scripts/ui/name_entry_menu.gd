extends Control

const NEXT_SCENE := "res://scenes/levels/test_scene.tscn"
const MAIN_MENU_SCENE := "res://scenes/ui/MainMenu.tscn"

func _ready() -> void:
	modulate.a = 0.0
	$CenterContainer/Content/NameInput.grab_focus()
	$CenterContainer/Content/ConfirmButton.pressed.connect(_on_confirm_pressed)
	$CenterContainer/Content/BackButton.pressed.connect(_on_back_pressed)
	$CenterContainer/Content/NameInput.text_submitted.connect(_on_name_submitted)
	_fade_in()

func _fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func _fade_out_to(scene: String) -> void:
	$CenterContainer/Content/ConfirmButton.disabled = true
	$CenterContainer/Content/BackButton.disabled = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func(): get_tree().change_scene_to_file(scene))

func _on_confirm_pressed() -> void:
	_submit_name()

func _on_name_submitted(_text: String) -> void:
	_submit_name()

func _submit_name() -> void:
	var entered: String = $CenterContainer/Content/NameInput.text.strip_edges()
	if entered.is_empty():
		entered = "HERO"
	PlayerDataManager.reset_player_data()
	PlayerDataManager.set_player_name(entered)
	PlayerDataManager.save_player_data()
	_fade_out_to(NEXT_SCENE)

func _on_back_pressed() -> void:
	_fade_out_to(MAIN_MENU_SCENE)
