extends Control

func _ready():
	$VBox/StartButton.connect("pressed", self._on_start_pressed)
	$VBox/SettingsButton.connect("pressed", self._on_settings_pressed)
	$VBox/QuitButton.connect("pressed", self._on_quit_pressed)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/levels/test_scene.tscn")

func _on_settings_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/SettingsMenu.tscn")

func _on_quit_pressed():
	get_tree().quit()
