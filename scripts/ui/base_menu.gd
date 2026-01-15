## Base class for all menu screens
## Provides consistent setup and back button signal
extends Control
class_name BaseMenu

signal back_requested

func _ready():
	# Make this control fill the screen and block all input below it
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_setup_menu()

## Override this in child classes to connect buttons and setup
func _setup_menu():
	pass

## Call this to request going back (emits signal for parent handler)
func request_back():
	emit_signal("back_requested")

## Override in child classes if custom show logic is needed
func show_menu():
	show()
	grab_focus()

## Override in child classes if custom hide logic is needed
func hide_menu():
	hide()
