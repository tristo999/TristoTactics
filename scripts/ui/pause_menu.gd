extends "res://scripts/ui/base_menu.gd"

signal settings_requested

func _setup_menu():
	$Panel/VBox/ResumeButton.pressed.connect(_on_resume_pressed)
	$Panel/VBox/RestartButton.pressed.connect(_on_restart_pressed)
	$Panel/VBox/MainMenuButton.pressed.connect(_on_main_menu_pressed)
	$Panel/VBox/SettingsButton.pressed.connect(_on_settings_pressed)
	$Panel/VBox/QuitButton.pressed.connect(_on_quit_pressed)

func _on_settings_pressed():
	settings_requested.emit()

func _on_resume_pressed():
	request_back()

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().quit()

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
