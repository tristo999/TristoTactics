extends "res://scripts/ui/base_menu.gd"

signal settings_requested

func _setup_menu():
	$Panel/VBox/ResumeButton.pressed.connect(_on_resume_pressed)
	$Panel/VBox/SaveButton.pressed.connect(_on_save_pressed)
	$Panel/VBox/RestartButton.pressed.connect(_on_restart_pressed)
	$Panel/VBox/MainMenuButton.pressed.connect(_on_main_menu_pressed)
	$Panel/VBox/SettingsButton.pressed.connect(_on_settings_pressed)
	$Panel/VBox/QuitButton.pressed.connect(_on_quit_pressed)

func _on_save_pressed() -> void:
	var scene_path := get_tree().current_scene.scene_file_path
	PlayerDataManager.set_checkpoint(scene_path)
	PlayerDataManager.save_player_data()
	# Brief visual confirmation
	var btn := $Panel/VBox/SaveButton as Button
	btn.text = "Saved!"
	btn.disabled = true
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(btn):
		btn.text = "Save Game"
		btn.disabled = false

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
