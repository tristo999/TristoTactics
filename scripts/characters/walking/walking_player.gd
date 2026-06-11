# WalkingPlayer - Tile-snapped free-roam controller for walking scenes.
# Moves one tile at a time, respecting the same walkability rules as the
# turn-based system (base_layer must have a cell, AStar must not be solid).
# Smoothing: input buffering, first-step speed boost, and higher base speed
# combine to make tile movement feel nearly as fluid as free movement.
# The embedded Camera2D follows automatically as a child node.
extends Node2D
class_name WalkingPlayer

## Tiles per second during continuous walking.
@export var walk_speed: float = 10.0
## First step into a direction is this much faster (removes perceived input lag).
@export var first_step_boost: float = 1.5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var current_tile: Vector2i = Vector2i.ZERO

var _tilemap: Node = null
var _base_layer: TileMapLayer = null
var _astar: AStarGrid2D = null

var _is_moving: bool = false
var _in_dialogue: bool = false
## When true, _step_to callbacks are suppressed so cinematic tweens aren't interrupted.
var _cinematic_mode: bool = false
var _facing: String = "down"
var _forced_dir: Vector2i = Vector2i.ZERO
## Direction buffered while a tween is in flight; applied the instant it lands.
var _queued_dir: Vector2i = Vector2i.ZERO
## Tracks whether we are continuing a held direction or starting fresh.
var _last_step_dir: Vector2i = Vector2i.ZERO

func _ready() -> void:
	add_to_group("walking_player")
	# Deferred so Tilemap's _ready() (AStar setup) runs first
	call_deferred("_init_tilemap")

func _init_tilemap() -> void:
	_tilemap = get_tree().get_first_node_in_group("tilemap")
	if _tilemap:
		_base_layer = _tilemap.get_node_or_null("BaseGrid")
		_astar = _tilemap.get("astar_grid") as AStarGrid2D
	if _base_layer:
		var local_pos := _base_layer.to_local(global_position)
		current_tile = _base_layer.local_to_map(local_pos)
		global_position = _base_layer.to_global(_base_layer.map_to_local(current_tile))

func _process(_delta: float) -> void:
	if _in_dialogue and _forced_dir == Vector2i.ZERO:
		return

	var dir := _forced_dir
	if dir == Vector2i.ZERO:
		var dx := int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
		var dy := int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
		dir = Vector2i(dx, dy)

	if _is_moving:
		# Buffer the current input so it fires the moment the tween finishes.
		_queued_dir = dir
		return

	if dir == Vector2i.ZERO:
		_queued_dir = Vector2i.ZERO
		_last_step_dir = Vector2i.ZERO
		sprite.play("idle_" + _facing)
		return

	_try_step(dir)

## Attempt to move one tile in `dir`. Called both from _process and from the
## tween-complete callback (for buffered input).
func _try_step(dir: Vector2i) -> void:
	if dir == Vector2i.ZERO:
		sprite.play("idle_" + _facing)
		return

	_update_facing(dir)

	var target_tile := current_tile + dir

	if dir.x != 0 and dir.y != 0:
		var h_tile := current_tile + Vector2i(dir.x, 0)
		var v_tile := current_tile + Vector2i(0, dir.y)
		if not (_is_tile_walkable(target_tile) and _is_tile_walkable(h_tile) and _is_tile_walkable(v_tile)):
			sprite.play("idle_" + _facing)
			return
	else:
		if not _is_tile_walkable(target_tile):
			sprite.play("idle_" + _facing)
			return

	# Apply first-step boost when starting movement from rest or changing direction.
	var speed := walk_speed
	if dir != _last_step_dir:
		speed *= first_step_boost

	# Diagonal steps cover √2 more world distance — scale duration to match.
	var is_diagonal := dir.x != 0 and dir.y != 0
	if is_diagonal:
		speed /= sqrt(2.0)

	_last_step_dir = dir
	_step_to(target_tile, speed)

func _step_to(tile: Vector2i, speed: float) -> void:
	var from_tile := current_tile
	current_tile = tile
	_is_moving = true
	sprite.play("walk_" + _facing)

	var target_pos := _base_layer.to_global(_base_layer.map_to_local(tile))
	var duration := 1.0 / speed

	var tween := create_tween()
	tween.tween_property(self , "global_position", target_pos, duration)
	tween.tween_callback(func() -> void:
		if _cinematic_mode:
			return  # cinematic tween owns movement; don't interfere
		_is_moving = false
		# Per-step movement event: feeds walk-through doors and TriggerEngine
		# regions in walking scenes (battle units emit the same signal per move).
		EventBus.character_moved.emit(self, from_tile, tile)
		# Immediately consume buffered input — no dropped keystrokes.
		var buffered := _queued_dir
		_queued_dir = Vector2i.ZERO
		_try_step(buffered)
	)

func _is_tile_walkable(tile: Vector2i) -> bool:
	if not _base_layer:
		return false
	if _base_layer.get_cell_atlas_coords(tile) == Vector2i(-1, -1):
		return false
	if _astar and _astar.is_in_boundsv(tile) and _astar.is_point_solid(tile):
		return false
	return true

func _update_facing(dir: Vector2i) -> void:
	if dir.x > 0: _facing = "right"
	elif dir.x < 0: _facing = "left"
	elif dir.y > 0: _facing = "down"
	else: _facing = "up"

# --- NPC Interaction ---

func _unhandled_input(event: InputEvent) -> void:
	if _in_dialogue or not _base_layer:
		return

	# Space / ui_accept — interact with whatever is on the faced tile
	if event.is_action_pressed("ui_accept"):
		var faced_tile := current_tile + _facing_to_dir()
		var npc := _npc_at_tile(faced_tile)
		if npc:
			get_viewport().set_input_as_handled()
			_interact_with_npc(npc)
			return
		var interactable := _interactable_at_tile(faced_tile)
		if interactable:
			get_viewport().set_input_as_handled()
			interactable.interact()
		return

	# Left-click — interact with an adjacent NPC or interactable that was clicked
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return

	var local_pos := _base_layer.to_local(get_global_mouse_position())
	var click_tile := _base_layer.local_to_map(local_pos)

	var diff := click_tile - current_tile
	if diff == Vector2i.ZERO or abs(diff.x) > 1 or abs(diff.y) > 1:
		return

	var npc := _npc_at_tile(click_tile)
	if npc:
		get_viewport().set_input_as_handled()
		_interact_with_npc(npc)
		return

	var interactable := _interactable_at_tile(click_tile)
	if interactable:
		get_viewport().set_input_as_handled()
		interactable.interact()

func _interactable_at_tile(tile: Vector2i) -> Node:
	for n in get_tree().get_nodes_in_group("walking_interactable"):
		if n.get("current_tile") == tile:
			return n
	return null

func _npc_at_tile(tile: Vector2i) -> WalkingNPC:
	for n in get_tree().get_nodes_in_group("walking_npc"):
		if (n as WalkingNPC).current_tile == tile:
			return n as WalkingNPC
	return null

func _facing_to_dir() -> Vector2i:
	match _facing:
		"right": return Vector2i(1, 0)
		"left": return Vector2i(-1, 0)
		"down": return Vector2i(0, 1)
		"up": return Vector2i(0, -1)
	return Vector2i.ZERO

# --- Cinematic lock / unlock ---

## Face a direction without moving (for cutscenes). dir = up/down/left/right.
func face(dir: String) -> void:
	_facing = dir
	sprite.play("idle_" + _facing)

## Lock all player movement (used by CinematicTrigger during event sequences).
func lock_movement() -> void:
	_in_dialogue = true
	_forced_dir = Vector2i.ZERO
	_is_moving = false
	_queued_dir = Vector2i.ZERO
	_last_step_dir = Vector2i.ZERO
	sprite.play("idle_" + _facing)

## Release movement lock after a cinematic sequence ends.
func unlock_movement() -> void:
	_in_dialogue = false
	_forced_dir = Vector2i.ZERO

## Force continuous walking in a fixed direction during a cinematic beat.
func start_forced_walk(dir: Vector2i) -> void:
	_in_dialogue = true
	_forced_dir = dir
	_queued_dir = dir
	if dir != Vector2i.ZERO:
		_update_facing(dir)

## Stop any forced walking and return movement control to the scene.
func stop_forced_walk() -> void:
	_forced_dir = Vector2i.ZERO
	_queued_dir = Vector2i.ZERO
	_last_step_dir = Vector2i.ZERO
	_in_dialogue = false
	if not _is_moving:
		sprite.play("idle_" + _facing)

## Lock movement but keep the walk animation playing (cinematic walk-in-place).
func walk_in_place() -> void:
	_in_dialogue = true
	_forced_dir = Vector2i.ZERO
	_queued_dir = Vector2i.ZERO
	_is_moving = false
	sprite.play("walk_" + _facing)

## Stop the walk-in-place animation and show idle. Player remains locked.
func stop_walk_in_place() -> void:
	sprite.play("idle_" + _facing)

## Move the player northward by `tiles` tiles over `duration` seconds.
## Bypasses all tile-walkability checks — for cinematic forced movement only.
## Steps tile-by-tile so current_tile stays current and path tiles spawn ahead.
## Awaitable: resolves when all steps finish.
func cinematic_walk_north(tiles: int, duration: float) -> void:
	if not _base_layer:
		return
	_cinematic_mode = true
	_in_dialogue = true
	_forced_dir = Vector2i.ZERO
	_queued_dir = Vector2i.ZERO
	_facing = "up"
	sprite.play("walk_up")
	var tile_duration := duration / float(max(tiles, 1))
	for _i in range(tiles):
		_is_moving = true
		var target_tile := current_tile + Vector2i(0, -1)
		var target_pos := _base_layer.to_global(_base_layer.map_to_local(target_tile))
		var tween := create_tween()
		tween.tween_property(self, "global_position", target_pos, tile_duration)
		await tween.finished
		current_tile = target_tile
	_cinematic_mode = false
	_is_moving = false
	sprite.play("idle_up")   # settle to idle when the walk finishes

func _interact_with_npc(npc: WalkingNPC) -> void:
	# Face toward the NPC
	var diff := npc.current_tile - current_tile
	_update_facing(diff)

	lock_movement()

	var box: CanvasLayer = get_tree().get_first_node_in_group("dialogue_box")
	if box and box.has_method("play_sequence"):
		await box.play_sequence(npc.get_dialogue())

	unlock_movement()
