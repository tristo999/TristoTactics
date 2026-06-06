# CorridorParticles - Warm amber-gold particle motes for the opening corridor.
# Drifts upward and forward (toward the top of the screen) in early phases.
# In Phase 4 (The Connection), drift reverses toward the Hero.
# Density increases through the sequence, peaks at Title phase, then settles.
#
# Add as a child of the corridor scene. Follows the WalkingPlayer position
# so particles always emit relative to the hero's area.
extends GPUParticles2D
class_name CorridorParticles

enum PhaseStyle {
	CALL,
	ASSEMBLY,
	CONNECTION,
	BLOOM,
	SETTLED,
}

## Base number of particles when the system starts.
@export var base_amount: int = 12
## Peak number of particles during the Title phase.
@export var peak_amount: int = 50
## How quickly density changes lerp (per second).
@export var density_lerp_speed: float = 1.0

var _player: WalkingPlayer = null
var _material: ParticleProcessMaterial = null
var _target_amount: int = 12
var _target_offset: Vector2 = Vector2(0, -20)
var _target_modulate: Color = Color(0.88, 0.78, 0.48, 0.55)
var _target_direction: Vector3 = Vector3(0, -1, 0)
var _target_velocity_min: float = 6.0
var _target_velocity_max: float = 12.0
var _target_spread: float = 16.0
var _target_box: Vector3 = Vector3(14, 20, 0)
var _target_scale_min: float = 0.45
var _target_scale_max: float = 1.0
var _target_lifetime: float = 3.0

func _ready() -> void:
	call_deferred("_init_particles")

func _init_particles() -> void:
	_player = get_tree().get_first_node_in_group("walking_player") as WalkingPlayer

	# Configure the particle system
	amount = base_amount
	_target_amount = base_amount
	lifetime = _target_lifetime
	explosiveness = 0.0
	randomness = 0.3
	fixed_fps = 0
	interpolate = true
	emitting = false # Start off — Phase 2 turns them on

	# Build the process material
	_material = ParticleProcessMaterial.new()
	_material.direction = Vector3(0, -1, 0) # Upward (negative Y in Godot 2D)
	_material.spread = 16.0
	_material.initial_velocity_min = 6.0
	_material.initial_velocity_max = 12.0
	_material.gravity = Vector3(0, 0, 0) # No gravity — motes float

	# Emission shape: box around the hero area
	_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	_material.emission_box_extents = Vector3(14, 20, 0)

	# Scale
	_material.scale_min = 0.45
	_material.scale_max = 1.0

	# Fading: alpha over lifetime (fade in, hold, fade out)
	var alpha_curve := CurveTexture.new()
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0)) # Start invisible
	curve.add_point(Vector2(0.15, 1.0)) # Fade in
	curve.add_point(Vector2(0.7, 1.0)) # Hold
	curve.add_point(Vector2(1.0, 0.0)) # Fade out
	alpha_curve.curve = curve
	_material.alpha_curve = alpha_curve

	# Scale over lifetime — slight shrink at end
	var scale_curve := CurveTexture.new()
	var s_curve := Curve.new()
	s_curve.add_point(Vector2(0.0, 0.8))
	s_curve.add_point(Vector2(0.5, 1.0))
	s_curve.add_point(Vector2(1.0, 0.4))
	scale_curve.curve = s_curve
	_material.scale_curve = scale_curve

	process_material = _material
	modulate = _target_modulate

	# Create a small soft circle texture for the motes
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	var center := Vector2(3.5, 3.5)
	for x in range(8):
		for y in range(8):
			var dist := Vector2(x, y).distance_to(center)
			var alpha_val := clampf(1.0 - (dist / 4.0), 0.0, 1.0)
			# Warm amber-gold color
			img.set_pixel(x, y, Color(1.0, 0.85, 0.4, alpha_val))
	texture = ImageTexture.create_from_image(img)

func _process(delta: float) -> void:
	if not _player:
		return

	# Follow the player position and ease toward the current phase offset.
	global_position = global_position.lerp(_player.global_position + _target_offset, minf(1.0, delta * 3.0))
	modulate = modulate.lerp(_target_modulate, minf(1.0, delta * 2.5))

	# Smoothly adjust particle count toward target
	if amount != _target_amount:
		var diff := _target_amount - amount
		var step := int(ceilf(abs(diff) * density_lerp_speed * delta))
		if diff > 0:
			amount = mini(amount + step, _target_amount)
		else:
			amount = maxi(amount - step, _target_amount)

	# Ease phase-dependent material properties so the atmosphere evolves continuously.
	if _material:
		_material.direction = _material.direction.lerp(_target_direction, minf(1.0, delta * 2.4))
		_material.initial_velocity_min = lerpf(_material.initial_velocity_min, _target_velocity_min, minf(1.0, delta * 2.4))
		_material.initial_velocity_max = lerpf(_material.initial_velocity_max, _target_velocity_max, minf(1.0, delta * 2.4))
		_material.spread = lerpf(_material.spread, _target_spread, minf(1.0, delta * 2.4))
		var current_box := _material.emission_box_extents
		current_box.x = lerpf(current_box.x, _target_box.x, minf(1.0, delta * 2.4))
		current_box.y = lerpf(current_box.y, _target_box.y, minf(1.0, delta * 2.4))
		_material.emission_box_extents = current_box
		_material.scale_min = lerpf(_material.scale_min, _target_scale_min, minf(1.0, delta * 2.4))
		_material.scale_max = lerpf(_material.scale_max, _target_scale_max, minf(1.0, delta * 2.4))
		lifetime = lerpf(lifetime, _target_lifetime, minf(1.0, delta * 2.4))

## Start emitting particles (called by Phase 2).
func start() -> void:
	emitting = true

## Set target particle density (amount will lerp toward this).
func set_density(target: int) -> void:
	_target_amount = target

func set_phase_style(style: PhaseStyle) -> void:
	_apply_profile(_profile_for_style(style))

func set_phase_blend(from_style: PhaseStyle, to_style: PhaseStyle, weight: float) -> void:
	var a := _profile_for_style(from_style)
	var b := _profile_for_style(to_style)
	_apply_profile(_lerp_profile(a, b, clampf(weight, 0.0, 1.0)))

func _profile_for_style(style: PhaseStyle) -> Dictionary:
	match style:
		PhaseStyle.CALL:
			return {
				"amount": 8,
				"offset": Vector2(0, -18),
				"color": Color(0.88, 0.78, 0.48, 0.42),
				"direction": Vector3(0.0, -1.0, 0.0),
				"velocity_min": 5.0,
				"velocity_max": 10.0,
				"spread": 10.0,
				"box": Vector3(10, 16, 0),
				"scale_min": 0.28,
				"scale_max": 0.65,
				"lifetime": 3.4,
			}
		PhaseStyle.ASSEMBLY:
			return {
				"amount": 22,
				"offset": Vector2(0, -34),
				"color": Color(0.98, 0.82, 0.52, 0.70),
				"direction": Vector3(0.08, -1.0, 0.0),
				"velocity_min": 10.0,
				"velocity_max": 20.0,
				"spread": 26.0,
				"box": Vector3(22, 34, 0),
				"scale_min": 0.36,
				"scale_max": 0.95,
				"lifetime": 2.8,
			}
		PhaseStyle.CONNECTION:
			return {
				"amount": 40,
				"offset": Vector2(0, -6),
				"color": Color(1.0, 0.92, 0.68, 0.96),
				"direction": Vector3(0.0, 1.0, 0.0),
				"velocity_min": 20.0,
				"velocity_max": 34.0,
				"spread": 62.0,
				"box": Vector3(38, 46, 0),
				"scale_min": 0.60,
				"scale_max": 1.50,
				"lifetime": 1.9,
			}
		PhaseStyle.BLOOM:
			return {
				"amount": 10,
				"offset": Vector2(0, -10),
				"color": Color(1.0, 0.96, 0.82, 0.32),
				"direction": Vector3(0.0, -1.0, 0.0),
				"velocity_min": 3.0,
				"velocity_max": 7.0,
				"spread": 14.0,
				"box": Vector3(18, 20, 0),
				"scale_min": 0.30,
				"scale_max": 0.70,
				"lifetime": 2.6,
			}
		PhaseStyle.SETTLED:
			return {
				"amount": 3,
				"offset": Vector2(0, -6),
				"color": Color(0.95, 0.90, 0.82, 0.18),
				"direction": Vector3(0.0, -1.0, 0.0),
				"velocity_min": 1.5,
				"velocity_max": 4.0,
				"spread": 8.0,
				"box": Vector3(10, 14, 0),
				"scale_min": 0.24,
				"scale_max": 0.55,
				"lifetime": 3.6,
			}
	return _profile_for_style(PhaseStyle.CALL)

func _lerp_profile(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	return {
		"amount": int(round(lerpf(float(a["amount"]), float(b["amount"]), t))),
		"offset": (a["offset"] as Vector2).lerp(b["offset"] as Vector2, t),
		"color": (a["color"] as Color).lerp(b["color"] as Color, t),
		"direction": (a["direction"] as Vector3).lerp(b["direction"] as Vector3, t),
		"velocity_min": lerpf(float(a["velocity_min"]), float(b["velocity_min"]), t),
		"velocity_max": lerpf(float(a["velocity_max"]), float(b["velocity_max"]), t),
		"spread": lerpf(float(a["spread"]), float(b["spread"]), t),
		"box": (a["box"] as Vector3).lerp(b["box"] as Vector3, t),
		"scale_min": lerpf(float(a["scale_min"]), float(b["scale_min"]), t),
		"scale_max": lerpf(float(a["scale_max"]), float(b["scale_max"]), t),
		"lifetime": lerpf(float(a["lifetime"]), float(b["lifetime"]), t),
	}

func _apply_profile(profile: Dictionary) -> void:
	_target_amount = profile["amount"]
	_target_offset = profile["offset"]
	_target_modulate = profile["color"]
	_target_direction = profile["direction"]
	_target_velocity_min = profile["velocity_min"]
	_target_velocity_max = profile["velocity_max"]
	_target_spread = profile["spread"]
	_target_box = profile["box"]
	_target_scale_min = profile["scale_min"]
	_target_scale_max = profile["scale_max"]
	_target_lifetime = profile["lifetime"]

## Reverse particle direction — motes drift toward the hero instead of ahead.
## Used for Phase 4 (The Connection).
func reverse_toward_hero() -> void:
	set_phase_style(PhaseStyle.CONNECTION)

## Restore normal forward drift.
func restore_forward() -> void:
	set_phase_style(PhaseStyle.CALL)
