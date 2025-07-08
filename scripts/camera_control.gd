extends Camera2D

@export var move_speed := 500.0    # Camera movement speed (pixels/second)
@export var zoom_speed := 0.1     # Zoom speed
@export var min_zoom := 0.5       # Minimum zoom level
@export var max_zoom := 3.0       # Maximum zoom level
@export var edge_threshold := 1.0 # Threshold from screen edge to start moving

func _process(delta: float) -> void:
	handle_keyboard_input(delta)
	handle_zoom_input()

func handle_keyboard_input(delta: float) -> void:
	var input_vector := Vector2.ZERO
	
	# WASD or Arrow Key movement
	input_vector.x = Input.get_axis("ui_left", "ui_right")
	input_vector.y = Input.get_axis("ui_up", "ui_down")
	
	if input_vector != Vector2.ZERO:
		position += input_vector.normalized() * move_speed * delta


func handle_zoom_input() -> void:
	# Mouse wheel zoom 
	var zoom_input := 0.0
	if Input.is_action_just_released("ui_zoom_out"):
		zoom_input -= zoom_speed
	if Input.is_action_just_released("ui_zoom_in"):
		zoom_input += zoom_speed
	
	if zoom_input != 0.0:
		var new_zoom = zoom + Vector2(zoom_input, zoom_input)
		new_zoom = new_zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
		zoom = new_zoom

func move_camera(character: Node2D) -> void:
	print("camera moved!")
	print(character.position)
	position = character.position
