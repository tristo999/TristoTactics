extends "res://scripts/ui/base_menu.gd"

signal settings_requested

func _setup_menu():
	$Panel/VBox/ResumeButton.connect("pressed", self._on_resume_pressed)
	$Panel/VBox/SettingsButton.connect("pressed", self._on_settings_pressed)
	$Panel/VBox/QuitButton.connect("pressed", self._on_quit_pressed)

func _on_settings_pressed():
	emit_signal("settings_requested")

func _on_resume_pressed():
	request_back()

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().quit()

func show_menu():
	get_tree().paused = true
	super.show_menu()

func hide_menu():
	super.hide_menu()
	get_tree().paused = false

# Aliases for compatibility
func show_pause():
	show_menu()

func hide_pause():
	hide_menu()
