# CameraControl - Battle camera with keyboard/mouse control and event-driven focusing
extends Camera2D

# =============================================================================
# EXPORTS
# =============================================================================

@export var move_speed: float = 500.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0
@export var edge_threshold: float = 1.0

# Camera smoothing for focus transitions
@export var focus_lerp_speed: float = 5.0
@export var use_smooth_focus: bool = true

# =============================================================================
# STATE
# =============================================================================

var focus_target: Node2D = null
var is_focusing: bool = false

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	pass

# =============================================================================
# PROCESS
# =============================================================================

func _process(delta: float) -> void:
	handle_keyboard_input(delta)
	handle_zoom_input()
	
	# Smooth focus transition
	if is_focusing and focus_target and use_smooth_focus:
		position = position.lerp(focus_target.position, focus_lerp_speed * delta)
		if position.distance_to(focus_target.position) < 1.0:
			position = focus_target.position
			is_focusing = false

func handle_keyboard_input(delta: float) -> void:
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_axis("ui_left", "ui_right")
	input_vector.y = Input.get_axis("ui_up", "ui_down")
	
	if input_vector != Vector2.ZERO:
		# Cancel auto-focus when player manually moves camera
		is_focusing = false
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

# =============================================================================
# PUBLIC METHODS
# =============================================================================

## Move camera to focus on a character (called by GameManager)
func move_camera(character: Node2D) -> void:
	print("Camera focusing on: ", character.name)
	
	if use_smooth_focus:
		focus_target = character
		is_focusing = true
	else:
		position = character.position

## Instant snap to position
func snap_to(pos: Vector2) -> void:
	position = pos
	is_focusing = false
	focus_target = null
