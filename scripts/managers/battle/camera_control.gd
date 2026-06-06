# CameraControl - Battle camera with keyboard/mouse control and event-driven focusing.
extends Camera2D

@export var move_speed: float = 500.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 8.0
@export var focus_lerp_speed: float = 5.0
@export var use_smooth_focus: bool = true
## How many tiles wide the battle view shows (smaller = more zoomed in / bigger
## units). ~17 = a slightly looser Shining Force II-style zoom.
@export var TARGET_TILES_WIDE: float = 17.0

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

	_clamp_to_limits()

## Manually keep the view inside the map limits (Camera2D's built-in limit_*
## doesn't reliably clamp an externally-driven position). If the map is smaller
## than the view on an axis, center on it instead.
func _clamp_to_limits() -> void:
	if limit_right <= limit_left:
		return  # limits not set yet
	var half := (get_viewport_rect().size * 0.5) / zoom
	var min_x := limit_left + half.x
	var max_x := limit_right - half.x
	var min_y := limit_top + half.y
	var max_y := limit_bottom - half.y
	position.x = (limit_left + limit_right) * 0.5 if min_x > max_x else clampf(position.x, min_x, max_x)
	position.y = (limit_top + limit_bottom) * 0.5 if min_y > max_y else clampf(position.y, min_y, max_y)

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

## Bound the camera to a tilemap's used area (+ a small margin so a little
## backdrop shows past the playable edge before the camera stops). Reads the
## BaseGrid layer's used rect and sets Camera2D.limit_* in world space.
func apply_map_limits(tilemap: Node2D, margin_px: int = 0) -> void:
	if tilemap == null:
		return
	var base := tilemap.get_node_or_null("BaseGrid") as TileMapLayer
	if base == null:
		return
	var rect := base.get_used_rect()
	if rect.size == Vector2i.ZERO:
		return
	# Exact pixel edges of the used area (map_to_local gives tile centers, which
	# overshoot the true edge by half a tile).
	var ts := Vector2(base.tile_set.tile_size)
	var tl := base.to_global(Vector2(rect.position) * ts)
	var br := base.to_global(Vector2(rect.position + rect.size) * ts)
	limit_left = int(tl.x) - margin_px
	limit_top = int(tl.y) - margin_px
	limit_right = int(br.x) + margin_px
	limit_bottom = int(br.y) + margin_px

	# Zoom to a READABLE tactics view (~TARGET_TILES_WIDE tiles across), not to fit
	# the whole map -- fitting everything makes units tiny. The camera follows
	# units and scrolls; the background layer covers anything past the map edge.
	var vp := get_viewport_rect().size
	var z: float = vp.x / (TARGET_TILES_WIDE * ts.x)
	z = clampf(z, min_zoom, max_zoom)
	zoom = Vector2(z, z)
	# Start centered on the party (or the map center if no players yet).
	var players := get_tree().get_nodes_in_group(Constants.GROUP_PLAYER_CHARACTERS)
	if players.size() > 0:
		var c := Vector2.ZERO
		for p in players:
			c += (p as Node2D).global_position
		position = c / players.size()
	else:
		position = (tl + br) * 0.5
	focus_target = null
	print("[CameraControl] limits L%d T%d R%d B%d zoom %.2f" % [limit_left, limit_top, limit_right, limit_bottom, zoom.x])

## Start tracking a character with damped smoothing.
func move_camera(character: Node2D) -> void:
	focus_target = character

## Instant snap to position (clears tracking)
func snap_to(pos: Vector2) -> void:
	position = pos
	focus_target = null
