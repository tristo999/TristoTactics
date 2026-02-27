## Base class for all menu screens.
extends Control
class_name BaseMenu

signal back_requested

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_setup_menu()

func _setup_menu():
	pass

func request_back():
	back_requested.emit()

func show_menu():
	show()
	grab_focus()

func hide_menu():
	hide()
