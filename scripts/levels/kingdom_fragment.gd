# KingdomFragment - A single cluster of kingdom tile sprites that appears
# at the periphery of the corridor. Breathes with a slow alpha pulse.
# Represents a memory/impression of the kingdom being pulled toward the Hero.
#
# Place these as children of a KingdomFragments container node in the
# corridor scene. Each fragment is a Sprite2D with its atlas region set
# to pull from the game's actual tileset texture.
extends Sprite2D
class_name KingdomFragment

## Base alpha — the resting opacity of this fragment.
@export_range(0.0, 1.0) var base_alpha: float = 0.45
## How much the alpha pulses above/below base.
@export_range(0.0, 0.2) var pulse_range: float = 0.1
## Pulse duration in seconds (full cycle).
@export var pulse_period: float = 4.0
## Random phase offset so fragments don't pulse in sync.
var _phase_offset: float = 0.0

## Desaturated warm tint for normal state.
var _normal_color: Color = Color(0.7, 0.68, 0.65, 1.0)

func _ready() -> void:
	add_to_group("kingdom_fragment")
	_phase_offset = randf() * TAU
	modulate = Color(_normal_color.r, _normal_color.g, _normal_color.b, 0.0)
	visible = false # Hidden until activated by the corridor scene

func _process(delta: float) -> void:
	if not visible:
		return

	# Breathing alpha pulse using sine wave
	var pulse := sin((Time.get_ticks_msec() / 1000.0) * (TAU / pulse_period) + _phase_offset)
	var alpha := base_alpha + pulse * pulse_range
	modulate.a = clampf(alpha, 0.0, 1.0)

## Fade this fragment into view over `duration` seconds.
func fade_in(duration: float = 2.0) -> void:
	visible = true
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self , "modulate:a", base_alpha, duration)

## Quiet the breathing — freeze at current alpha (used during name entry).
func still() -> void:
	set_process(false)
