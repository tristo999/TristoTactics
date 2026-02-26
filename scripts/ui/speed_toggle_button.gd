# SpeedToggleButton - Toggles between 1x and 2x game speed
# Uses Engine.time_scale so ALL timers, tweens, movement, and animations speed up.
extends Button

const SPEED_NORMAL := 1.0
const SPEED_FAST := 2.0

var is_fast: bool = false

func _ready() -> void:
	toggle_mode = true
	text = "1x"
	tooltip_text = "Toggle game speed"
	pressed.connect(_on_toggled)
	# Ensure we start at normal speed
	Engine.time_scale = SPEED_NORMAL

func _exit_tree() -> void:
	Engine.time_scale = SPEED_NORMAL

func _on_toggled() -> void:
	is_fast = button_pressed
	if is_fast:
		Engine.time_scale = SPEED_FAST
		text = "2x"
	else:
		Engine.time_scale = SPEED_NORMAL
		text = "1x"
