extends Node2D

const MenuStackClass = preload("res://scripts/core/menu_stack.gd")

@onready var pause_menu_scene := preload("res://scenes/ui/PauseMenu.tscn")
@onready var settings_menu_scene := preload("res://scenes/ui/SettingsMenu.tscn")

var menu_stack
var escape_down := false

func _ready():
	# Create the menu stack manager
	menu_stack = MenuStackClass.new()
	menu_stack.connect("stack_emptied", Callable(self, "_on_stack_emptied"))
	add_child(menu_stack)
	
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if event.is_action_pressed("ui_cancel") and not escape_down:
		escape_down = true
		if not menu_stack.has_menus():
			# No menus open - open the pause menu
			_open_pause_menu()
			get_viewport().set_input_as_handled()
		# If menus are open, MenuStack handles the back action
	elif event.is_action_released("ui_cancel"):
		escape_down = false

func _open_pause_menu():
	var pause_menu = pause_menu_scene.instantiate()
	pause_menu.connect("settings_requested", Callable(self, "_open_settings_menu"))
	menu_stack.push_menu(pause_menu)

func _open_settings_menu():
	var settings_menu = settings_menu_scene.instantiate()
	menu_stack.push_menu(settings_menu)

func _on_stack_emptied():
	# Resume game when all menus are closed
	get_tree().paused = false
