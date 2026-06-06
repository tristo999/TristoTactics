# CorridorCamera - Dynamic camera for the opening corridor sequence.
# Sits ahead of the player when idle (hero in lower screen), lerps closer
# when the player is moving (hero near center). Creates a forward pull
# toward the Guardian's glow without the player consciously noticing.
#
# Attach to the Camera2D child of WalkingPlayer. The camera's local offset
# is relative to the player, so negative Y = ahead (upward on screen).
extends Camera2D
class_name CorridorCamera

## How far ahead (in pixels) the camera rests when the player is idle.
## With zoom 2 on a 320px-tall viewport, ~48px puts the hero roughly
## halfway down the visible area.
@export var idle_offset: float = -48.0
## How far ahead (in pixels) when the player is actively walking.
## Smaller value = hero closer to center.
@export var moving_offset: float = -16.0
## How quickly the camera lerps toward the target offset (units per second).
@export var lerp_speed: float = 2.5

var _target_y: float = 0.0
var _player: WalkingPlayer = null
var _locked_idle: bool = false

func _ready() -> void:
	# Start at the idle offset so the first frame isn't jarring
	_target_y = idle_offset
	position.y = idle_offset

## Force the camera to drift to idle_offset regardless of player movement.
func lock_to_idle() -> void:
	_locked_idle = true

func unlock() -> void:
	_locked_idle = false

func _process(delta: float) -> void:
	if not _player:
		_player = get_parent() as WalkingPlayer
		if not _player:
			return

	# Determine target: moving → closer offset, idle → further ahead
	if _locked_idle or not _player._is_moving:
		_target_y = idle_offset
	else:
		_target_y = moving_offset

	# Smooth lerp toward target
	position.y = lerpf(position.y, _target_y, lerp_speed * delta)
