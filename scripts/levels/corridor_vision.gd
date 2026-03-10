# CorridorVision - Spawns character clusters fixed in world space beside the corridor.
# Each cluster fades in when triggered, then fades out automatically once the
# player has walked far enough past them (screen Y threshold).
#
# Sprites render at full in-game character scale — same as the walking sprites.
# No particle effects: the fade-in IS the manifestation.
#
# Usage (from opening_corridor_scene.gd):
#   var vision := CorridorVision.new()
#   add_child(vision)
#   vision.show_cluster(world_pos, CorridorVision.ClusterType.COMPANIONS)
extends Node2D
class_name CorridorVision

enum ClusterType {
	COMPANIONS,  ## 4 character figures side by side, facing up
	KINGDOM,     ## wide architectural silhouettes
	HOODED,      ## single figure
}

## Seconds for a cluster to fade in.
@export var fade_in_duration: float = 1.0
## Seconds for a cluster to fade out once the screen-Y threshold is crossed.
@export var fade_out_duration: float = 1.2
## Normalized screen Y at which clusters begin fading out (0=top, 1=bottom).
## 0.75 = 3/4 down the screen — roughly 1/4 from the bottom.
@export var fade_out_screen_y: float = 0.75

const _CHAR_IDLE_PATH := "res://assets/test/World of Solaria Demo Pack Update 04/16x16/Sprites/New/Chris Idle.png"
const _FRAME_SIZE := 80
const _FRAME_COUNT := 6
const _ROW_UP    := 0
const _ROW_DOWN  := 1
const _ROW_LEFT  := 2
const _ROW_RIGHT := 3

## Spawn a cluster at a fixed world position. Non-blocking — fades out automatically
## based on screen position as the player walks past.
func show_cluster(world_pos: Vector2, cluster_type: ClusterType) -> void:
	var container := Node2D.new()
	container.global_position = world_pos
	container.modulate.a = 0.0
	add_child(container)
	_build_cluster(container, cluster_type)
	_run_cluster_lifecycle(container)

func _run_cluster_lifecycle(container: Node2D) -> void:
	# Fade in
	var tw_in := create_tween()
	tw_in.tween_property(container, "modulate:a", 1.0, fade_in_duration)
	await tw_in.finished

	if not is_instance_valid(container):
		return

	# Wait until cluster has scrolled to 3/4 down the screen before fading out.
	var viewport := get_viewport()
	while is_instance_valid(container):
		if viewport:
			var canvas_xform := viewport.get_canvas_transform()
			var screen_y := (canvas_xform * container.global_position).y
			var screen_h := viewport.get_visible_rect().size.y
			if screen_h > 0.0 and screen_y / screen_h >= fade_out_screen_y:
				break
		await get_tree().process_frame

	if not is_instance_valid(container):
		return

	# Collect despawn burst nodes first — can't remove_child while iterating.
	var despawn_nodes: Array[CPUParticles2D] = []
	for child in container.get_children():
		if child is CPUParticles2D and (child.name as String).begins_with("despawn_burst"):
			despawn_nodes.append(child as CPUParticles2D)
	# Reparent them out of the container so they aren't faded out with it.
	for p in despawn_nodes:
		var world_pos: Vector2 = p.global_position
		container.remove_child(p)
		add_child(p)
		p.global_position = world_pos
		p.emitting = true
		get_tree().create_timer(p.lifetime + 0.2).timeout.connect(p.queue_free)

	# Fade out
	var tw_out := create_tween()
	tw_out.tween_property(container, "modulate:a", 0.0, fade_out_duration)
	await tw_out.finished

	if is_instance_valid(container):
		container.queue_free()

func _build_cluster(container: Node2D, cluster_type: ClusterType) -> void:
	match cluster_type:
		ClusterType.COMPANIONS:
			# Three figures facing inward. Center at cluster origin, 96px apart.
			# Rightmost figure edge sits 3+ tiles clear of the corridor edge.
			var fig_offsets := [Vector2(-48, 4), Vector2(0, 0), Vector2(48, 4)]
			var fig_rows    := [_ROW_RIGHT, _ROW_DOWN, _ROW_LEFT]
			var fig_tints   := [
				Color(0.70, 0.88, 0.78, 0.85),
				Color(0.65, 0.82, 0.90, 0.85),
				Color(0.78, 0.70, 0.88, 0.85),
			]
			for i in 3:
				_spawn_glow(container, fig_offsets[i], 48.0, Color(0.72, 1.0, 0.84, 0.18))
				var spr := _spawn_character(container, fig_offsets[i], fig_tints[i], fig_rows[i])
				_apply_flicker(spr, 0.75, 0.95, 1.4 + i * 0.3)
				_spawn_burst_up(container, fig_offsets[i], true)   # spawn burst — fires immediately
				_spawn_burst_out(container, fig_offsets[i], false)  # despawn burst — fired on exit

		ClusterType.KINGDOM:
			_spawn_figure(container, Vector2(-40, 8),  Vector2(20, 6),  Color(0.48, 0.58, 0.52, 0.70))
			_spawn_figure(container, Vector2(-20, 0),  Vector2(12, 18), Color(0.52, 0.62, 0.58, 0.75))
			_spawn_figure(container, Vector2(-6,  4),  Vector2(28, 8),  Color(0.50, 0.60, 0.55, 0.70))
			_spawn_figure(container, Vector2(10,  -6), Vector2(10, 22), Color(0.54, 0.64, 0.60, 0.78))
			_spawn_figure(container, Vector2(28,  2),  Vector2(16, 12), Color(0.46, 0.56, 0.50, 0.68))

		ClusterType.HOODED:
			_spawn_character(container, Vector2(0, 0), Color(0.30, 0.35, 0.32, 0.92))

func _spawn_character(parent: Node2D, offset: Vector2, tint: Color, row: int = _ROW_UP) -> AnimatedSprite2D:
	var tex := load(_CHAR_IDLE_PATH) as Texture2D
	if not tex:
		_spawn_figure(parent, offset, Vector2(16, 32), tint)
		return null

	var anim_name := "anim"
	var frames := SpriteFrames.new()
	frames.add_animation(anim_name)
	for i in _FRAME_COUNT:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * _FRAME_SIZE, row * _FRAME_SIZE, _FRAME_SIZE, _FRAME_SIZE)
		frames.add_frame(anim_name, atlas)
	frames.set_animation_loop(anim_name, true)
	frames.set_animation_speed(anim_name, 8.0)

	var anim := AnimatedSprite2D.new()
	anim.sprite_frames = frames
	anim.animation = anim_name
	anim.play()
	anim.position = offset
	anim.modulate = tint
	anim.z_index = 3
	parent.add_child(anim)
	return anim

## Soft radial glow behind a figure — circular gradient fading to transparent.
func _spawn_glow(parent: Node2D, offset: Vector2, radius: float, color: Color) -> void:
	var size := int(radius * 2)
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(radius, radius)
	for x in size:
		for y in size:
			var d := Vector2(x, y).distance_to(center) / radius
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = pow(a, 2.0)
			img.set_pixel(x, y, Color(color.r, color.g, color.b, color.a * a))
	var spr := Sprite2D.new()
	spr.texture = ImageTexture.create_from_image(img)
	spr.position = offset
	spr.z_index = 2
	parent.add_child(spr)

## Looping tween that pulses a node's alpha between lo and hi — gives a ghostly flicker.
func _apply_flicker(node: Node, lo: float, hi: float, period: float) -> void:
	if not node:
		return
	var tw := node.create_tween().set_loops()
	tw.tween_property(node, "modulate:a", lo, period * 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "modulate:a", hi, period * 0.5).set_trans(Tween.TRANS_SINE)

## One-shot upward burst when the figure forms.
func _spawn_burst_up(parent: Node2D, offset: Vector2, emit_now: bool) -> void:
	var p := CPUParticles2D.new()
	p.name = "despawn_skip"  # not a despawn node
	p.position = offset
	p.emitting = emit_now
	p.amount = 14
	p.lifetime = 1.2
	p.one_shot = true
	p.explosiveness = 0.85
	p.randomness = 0.6
	p.direction = Vector2(0, -1)
	p.spread = 50.0
	p.gravity = Vector2(0, -10)
	p.initial_velocity_min = 15.0
	p.initial_velocity_max = 35.0
	p.scale_amount_min = 0.4
	p.scale_amount_max = 1.0
	p.color = Color(0.82, 1.0, 0.88, 0.8)
	p.z_index = 4
	parent.add_child(p)

## One-shot outward burst when the figure dissolves — starts non-emitting, fired on exit.
func _spawn_burst_out(parent: Node2D, offset: Vector2, emit_now: bool) -> void:
	var p := CPUParticles2D.new()
	p.name = "despawn_burst"
	p.position = offset
	p.emitting = emit_now
	p.amount = 12
	p.lifetime = 0.9
	p.one_shot = true
	p.explosiveness = 1.0
	p.randomness = 0.8
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2(0, 0)
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 50.0
	p.scale_amount_min = 0.3
	p.scale_amount_max = 0.8
	p.color = Color(0.82, 1.0, 0.88, 0.7)
	p.z_index = 4
	parent.add_child(p)

func _spawn_figure(parent: Node2D, offset: Vector2, size: Vector2, color: Color) -> void:
	var spr := Sprite2D.new()
	var img := Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	img.fill(color)
	spr.texture = ImageTexture.create_from_image(img)
	spr.position = offset
	spr.z_index = 3
	parent.add_child(spr)
