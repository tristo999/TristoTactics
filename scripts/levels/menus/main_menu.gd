extends Control

const MenuStackClass = preload("res://scripts/core/menu_stack.gd")

@onready var settings_menu_scene := preload("res://scenes/ui/SettingsMenu.tscn")

var menu_stack

func _ready():
	$VBox/StartButton.connect("pressed", self._on_start_pressed)
	$VBox/SettingsButton.connect("pressed", self._on_settings_pressed)
	$VBox/QuitButton.connect("pressed", self._on_quit_pressed)
	
	# Create menu stack for sub-menus
	menu_stack = MenuStackClass.new()
	menu_stack.connect("stack_emptied", Callable(self, "_on_stack_emptied"))
	add_child(menu_stack)

func _on_stack_emptied():
	# Show main menu content when all sub-menus are closed
	$VBox.show()

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/levels/test_scene.tscn")

func _on_settings_pressed():
	$VBox.hide()
	var settings_menu = settings_menu_scene.instantiate()
	menu_stack.push_menu(settings_menu)

func _on_quit_pressed():
	get_tree().quit()
