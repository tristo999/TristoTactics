# CinematicActor - a script-driven character for cutscenes (no input). Builds its
# own directional idle/walk animations in code from an idle sheet + a walk sheet
# (80x80 frames, 6 per row; rows up=0 / down=80 / left=160 / right=240 -- the
# Chris layout). Move it with walk_to(); it faces + animates automatically and
# snaps to the tile grid.
extends Node2D
class_name CinematicActor

@export var idle_sheet: Texture2D
@export var walk_sheet: Texture2D
## Multiplied over the sprite -- handy to tint a placeholder apart from the hero.
@export var tint: Color = Color.WHITE

var current_tile: Vector2i = Vector2i.ZERO
var _sprite: AnimatedSprite2D
var _base: TileMapLayer
var _facing: String = "down"

func _ready() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _build_frames()
	_sprite.z_index = 100
	_sprite.modulate = tint
	add_child(_sprite)
	_sprite.play("idle_down")
	call_deferred("_snap")

func _build_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var rows := {"up": 0, "down": 80, "left": 160, "right": 240}
	for dir in rows:
		var yoff: int = rows[dir]
		for pair in [["idle", idle_sheet], ["walk", walk_sheet]]:
			var anim: String = "%s_%s" % [pair[0], dir]
			sf.add_animation(anim)
			sf.set_animation_loop(anim, true)
			sf.set_animation_speed(anim, 10.0)
			var tex: Texture2D = pair[1]
			if tex == null:
				continue
			for i in range(6):
				var at := AtlasTexture.new()
				at.atlas = tex
				at.region = Rect2(i * 80, yoff, 80, 80)
				sf.add_frame(anim, at)
	return sf

func _snap() -> void:
	var tm := get_tree().get_first_node_in_group("tilemap")
	if tm:
		_base = tm.get_node_or_null("BaseGrid")
	if _base:
		current_tile = _base.local_to_map(_base.to_local(global_position))
		global_position = _base.to_global(_base.map_to_local(current_tile))

func face(dir: String) -> void:
	_facing = dir
	if _sprite:
		_sprite.play("idle_" + _facing)

func face_tile(tile: Vector2i) -> void:
	var dx := tile.x - current_tile.x
	var dy := tile.y - current_tile.y
	if absi(dx) >= absi(dy):
		if dx != 0:
			_facing = "right" if dx > 0 else "left"
	else:
		_facing = "down" if dy > 0 else "up"
	face(_facing)

## Walk to a tile over `dur` seconds (animated, auto-faces). Awaitable.
func walk_to(tile: Vector2i, dur: float) -> void:
	if _base == null:
		return
	face_tile(tile)
	if _sprite:
		_sprite.play("walk_" + _facing)
	var target := _base.to_global(_base.map_to_local(tile))
	var tw := create_tween()
	tw.tween_property(self, "global_position", target, dur)
	await tw.finished
	current_tile = tile
	if _sprite:
		_sprite.play("idle_" + _facing)
