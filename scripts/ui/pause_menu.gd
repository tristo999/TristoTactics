extends "res://scripts/ui/base_menu.gd"

signal settings_requested

func _setup_menu():
	$Panel/VBox/ResumeButton.pressed.connect(_on_resume_pressed)
	$Panel/VBox/SettingsButton.pressed.connect(_on_settings_pressed)
	$Panel/VBox/QuitButton.pressed.connect(_on_quit_pressed)

func _on_settings_pressed():
	settings_requested.emit()

func _on_resume_pressed():
	request_back()

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().quit()

# Aliases for compatibility
func show_pause():
	show_menu()

func hide_pause():
	hide_menu()
