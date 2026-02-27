# CameraControl - Battle camera with keyboard/mouse control and event-driven focusing.
extends Camera2D

@export var move_speed: float = 500.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0
@export var focus_lerp_speed: float = 5.0
@export var use_smooth_focus: bool = true

var focus_target: Node2D = null

func _ready() -> void:
	add_to_group("action_camera")

func _process(delta: float) -> void:
	handle_keyboard_input(delta)
	handle_zoom_input()
	
	# Smooth focus — continuously tracks the target node
	if focus_target and is_instance_valid(focus_target):
		if use_smooth_focus:
			position = position.lerp(focus_target.position, focus_lerp_speed * delta)
		else:
			position = focus_target.position

func handle_keyboard_input(delta: float) -> void:
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_axis("ui_left", "ui_right")
	input_vector.y = Input.get_axis("ui_up", "ui_down")
	
	if input_vector != Vector2.ZERO:
		# Cancel auto-focus when player manually moves camera
		focus_target = null
		position += input_vector.normalized() * move_speed * delta

func handle_zoom_input() -> void:
	var zoom_input := 0.0
	
	if Input.is_action_just_released("ui_zoom_out"):
		zoom_input -= zoom_speed
	if Input.is_action_just_released("ui_zoom_in"):
		zoom_input += zoom_speed
	
	if zoom_input != 0.0:
		var new_zoom = zoom + Vector2(zoom_input, zoom_input)
		new_zoom = new_zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
		zoom = new_zoom

## Start tracking a character with damped smoothing.
func move_camera(character: Node2D) -> void:
	focus_target = character

## Instant snap to position (clears tracking)
func snap_to(pos: Vector2) -> void:
	position = pos
	focus_target = null
