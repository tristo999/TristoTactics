extends "res://scripts/ui/base_menu.gd"

func _setup_menu():
	$Panel/VBox/BackButton.connect("pressed", Callable(self, "_on_back_pressed"))

func _on_back_pressed():
	request_back()

# Aliases for compatibility
func show_settings():
	show_menu()

func hide_settings():
	hide_menu()
