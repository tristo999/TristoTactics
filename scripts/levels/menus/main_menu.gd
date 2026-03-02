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
	
	# Fade in from black when arriving from splash screen
	modulate.a = 0.0
	var fade_in := create_tween()
	fade_in.tween_property(self , "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
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
