extends Control

@onready var settings_menu_scene := preload("res://scenes/ui/SettingsMenu.tscn")

var menu_stack: MenuStack

func _ready():
	$VBox/StartButton.pressed.connect(_on_start_pressed)
	$VBox/SettingsButton.pressed.connect(_on_settings_pressed)
	$VBox/QuitButton.pressed.connect(_on_quit_pressed)
	
	# Create menu stack for sub-menus
	menu_stack = MenuStack.new()
	menu_stack.stack_emptied.connect(_on_stack_emptied)
	add_child(menu_stack)
	
	# Start playing menu music
	AudioManager.play_music("menu")

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
