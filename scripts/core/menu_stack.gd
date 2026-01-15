## Manages a stack of menus with universal back button support
## Attach this to any scene that needs menu management (main menu, game levels, etc.)
extends Node
class_name MenuStack

## Emitted when the menu stack becomes empty (all menus closed)
signal stack_emptied
## Emitted when a menu is pushed onto the stack
signal menu_pushed(menu: Control)
## Emitted when a menu is popped from the stack
signal menu_popped(menu: Control)

var _menu_stack: Array[Control] = []
var _menu_layers: Dictionary = {} # menu -> CanvasLayer
var _escape_down := false

## If true, this MenuStack handles escape key input
@export var handle_escape_input := true

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if not handle_escape_input:
		return
	# Only handle escape if we have menus to close
	if _menu_stack.is_empty():
		return
	if event.is_action_pressed("ui_cancel") and not _escape_down:
		_escape_down = true
		go_back()
		get_viewport().set_input_as_handled()
	elif event.is_action_released("ui_cancel"):
		_escape_down = false

## Push a menu onto the stack (shows it, hides the previous one)
func push_menu(menu: Control, use_canvas_layer: bool = true):
	# Hide current top menu if any
	if not _menu_stack.is_empty():
		_menu_stack.back().hide()
	
	# Add to scene tree if needed
	if use_canvas_layer:
		var layer = CanvasLayer.new()
		layer.add_child(menu)
		add_child(layer)
		_menu_layers[menu] = layer
	else:
		add_child(menu)
	
	# Connect back signal if menu has it
	if menu.has_signal("back_requested"):
		if not menu.is_connected("back_requested", Callable(self, "go_back")):
			menu.connect("back_requested", Callable(self, "go_back"))
	
	_menu_stack.push_back(menu)
	
	# Show the menu
	if menu.has_method("show_menu"):
		menu.show_menu()
	else:
		menu.show()
		menu.grab_focus()
	
	emit_signal("menu_pushed", menu)

## Pop the top menu from the stack (hides it, shows the previous one)
func pop_menu() -> Control:
	if _menu_stack.is_empty():
		return null
	
	var menu = _menu_stack.pop_back()
	
	# Hide the menu
	if menu.has_method("hide_menu"):
		menu.hide_menu()
	else:
		menu.hide()
	
	# Remove from scene tree
	if _menu_layers.has(menu):
		var layer = _menu_layers[menu]
		_menu_layers.erase(menu)
		layer.queue_free()
	else:
		menu.queue_free()
	
	emit_signal("menu_popped", menu)
	
	# Show previous menu if any
	if not _menu_stack.is_empty():
		var prev_menu = _menu_stack.back()
		if prev_menu.has_method("show_menu"):
			prev_menu.show_menu()
		else:
			prev_menu.show()
			prev_menu.grab_focus()
	else:
		emit_signal("stack_emptied")
	
	return menu

## Go back one level (pop the top menu)
func go_back():
	if not _menu_stack.is_empty():
		pop_menu()

## Clear all menus from the stack
func clear_all():
	while not _menu_stack.is_empty():
		pop_menu()

## Check if any menus are currently shown
func has_menus() -> bool:
	return not _menu_stack.is_empty()

## Get the current top menu (or null if empty)
func get_current_menu() -> Control:
	if _menu_stack.is_empty():
		return null
	return _menu_stack.back()

## Get the number of menus in the stack
func get_stack_size() -> int:
	return _menu_stack.size()
