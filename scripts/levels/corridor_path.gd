# CorridorPath - Manages the materializing path beneath the Hero.
# Each step spawns a luminous gray tile sprite at the hero's position.
# Tiles fade out after the hero moves a few steps past them.
# Also shows a faint "preview" tile one step ahead in the hero's
# facing direction.
#
# Add as a child of the corridor scene. Requires a WalkingPlayer in
# group "walking_player" and a tilemap in group "tilemap" to read
# tile size and coordinate conversion.
extends Node2D
class_name CorridorPath

## Peak alpha for the tile the hero is standing on.
@export var tile_peak_alpha: float = 0.7
## How many steps behind the hero a tile survives before fully faded.
@export var trail_length: int = 3
## Seconds for a new path tile to fade in.
@export var fade_in_duration: float = 0.15
## Seconds for a trail tile to fade to invisible.
@export var fade_duration: float = 1.5
## Alpha of the faint preview tile ahead.
@export var preview_alpha: float = 0.15
## Color tint for path tiles — cool luminous green-white to match the beacon.
@export var tile_color: Color = Color(0.82, 1.0, 0.88, 1.0)
## How many rows ahead of the player to pre-form (0 = only under feet).
@export var ahead_rows: int = 5
## Speed of the mystical alpha pulse (radians per second).
@export var pulse_speed: float = 1.8
## How much the alpha oscillates around tile_peak_alpha (half-amplitude).
@export var pulse_depth: float = 0.20

var _player: WalkingPlayer = null
var _base_layer: TileMapLayer = null
var _tile_size: Vector2 = Vector2(16, 16)
var _active: bool = false
var _preview_enabled: bool = true

## Maps tile coord → Sprite2D for active trail tiles
var _trail_tiles: Dictionary = {}
## Maps tile coord → Tween so we can kill running tweens before starting new ones
var _tile_tweens: Dictionary = {}
## The tile the hero is currently on
var _current_hero_tile: Vector2i = Vector2i.MAX
## Preview sprite (reused, repositioned each step)
var _preview_sprite: Sprite2D = null
## Y-coords of rows visited, oldest first — used to cull entire rows.
var _row_history: Array[int] = []

## Reference to tile AStar grid for blocking backtracking.
var _astar: AStarGrid2D = null
## How many tiles either side of the player the path materialises.
## 1 = 3 tiles wide, 2 = 5 tiles wide.
var _path_half_width: int = 0

## Simulated walk state — advances a fake tile north independent of the real player.
var _sim_active: bool = false
var _sim_tile: Vector2i = Vector2i.ZERO
var _sim_speed: float = 0.0
var _sim_accumulator: float = 0.0

## Pulse state — each settled tile gets a random phase offset so they shimmer independently.
var _pulse_time: float = 0.0
var _pulse_offsets: Dictionary = {}  # Vector2i → float
## Tiles whose fade-in tween is still running — excluded from the pulse loop.
var _settling_tiles: Dictionary = {}  # Vector2i → true
## Tiles that are hint tiles (dim, waiting to be promoted when the player reaches them).
var _hint_tiles: Dictionary = {}  # Vector2i → true
## When true, fire an initial step on the first _process tick after activation.
var _needs_initial_step: bool = false

## Set the number of tiles either side of the hero that materialise per step.
## Also unseals the newly-exposed columns in the AStar grid so the player
## can walk on them.
func set_path_half_width(new_half_width: int) -> void:
	var old_half_width := _path_half_width
	_path_half_width = new_half_width
	# Unseal only the columns that are newly visible (avoids re-opening sealed rows)
	if _astar and _base_layer:
		for cell in _base_layer.get_used_cells():
			if absi(cell.x) > old_half_width and absi(cell.x) <= new_half_width:
				if _astar.is_in_boundsv(cell):
					_astar.set_point_solid(cell, false)

func _ready() -> void:
	call_deferred("_setup_path")

func activate(show_preview: bool = true) -> void:
	_active = true
	_preview_enabled = show_preview
	_current_hero_tile = Vector2i.MAX
	_needs_initial_step = true

func deactivate() -> void:
	_active = false
	if _preview_sprite:
		_preview_sprite.visible = false

func set_preview_enabled(enabled: bool) -> void:
	_preview_enabled = enabled
	if _preview_sprite and not enabled:
		_preview_sprite.visible = false

## Immediately materialise tiles at the given tile position without waiting for
## the player to move. Call this right after activate() to spawn the path at
## the player's starting position.
func force_step(tile: Vector2i) -> void:
	_current_hero_tile = tile
	_on_hero_step(tile)

## Stagger-materialise rows northward from from_tile over time, without affecting
## row_history or culling. Each row fades in row_delay seconds after the previous.
## Use for the cinematic pre-build effect before the player starts walking.
func pre_build_ahead(from_tile: Vector2i, rows: int, row_delay: float = 0.14) -> void:
	# Cancel the pending initial step — we handle all rows ourselves here,
	# including row 0 (player's tile), so nothing fires instantly and kills the stagger.
	_needs_initial_step = false
	_current_hero_tile = from_tile
	for row_offset in range(0, rows + 1):
		var row_y := from_tile.y - row_offset
		var delay := row_offset * row_delay
		for dx in range(-_path_half_width, _path_half_width + 1):
			var t := create_tween()
			var target_tile := Vector2i(dx, row_y)
			t.tween_interval(delay)
			t.tween_callback(func() -> void: _materialise_tile(target_tile))
	# One extra ghost row beyond the tip — dim hint that the path will keep forming.
	var hint_y := from_tile.y - (rows + 1)
	var hint_delay := (rows + 1) * row_delay
	for dx in range(-_path_half_width, _path_half_width + 1):
		var t := create_tween()
		var target_tile := Vector2i(dx, hint_y)
		t.tween_interval(hint_delay)
		t.tween_callback(func() -> void: _materialise_hint_tile(target_tile))

func _setup_path() -> void:
	_player = get_tree().get_first_node_in_group("walking_player") as WalkingPlayer
	var tilemap := get_tree().get_first_node_in_group("tilemap")
	if tilemap:
		_base_layer = tilemap.get_node_or_null("BaseGrid") as TileMapLayer
		_astar = tilemap.get("astar_grid") as AStarGrid2D
	if _base_layer:
		var ts := _base_layer.tile_set
		if ts:
			_tile_size = Vector2(ts.tile_size)

	# Create a small white square texture for path tiles
	_preview_sprite = _create_tile_sprite()
	_preview_sprite.modulate = Color(tile_color.r, tile_color.g, tile_color.b, 0.0)
	_preview_sprite.visible = false
	add_child(_preview_sprite)

## Spawn path tiles northward at the given tile-per-second rate,
## independent of the real player tile (walk-in-place illusion).
func start_simulated_walk(speed: float) -> void:
	_sim_tile = _current_hero_tile
	_sim_speed = speed
	_sim_accumulator = 0.0
	_sim_active = true

func stop_simulated_walk() -> void:
	_sim_active = false

func _process(delta: float) -> void:
	if not _active or not _base_layer:
		return

	# Pulse settled trail tiles with an independent sine wave per tile.
	# Skip tiles still fading in so the pulse doesn't fight their tween.
	_pulse_time += delta
	for tile in _trail_tiles.keys():
		if _settling_tiles.has(tile):
			continue
		var spr: Sprite2D = _trail_tiles[tile]
		var phase: float = _pulse_offsets.get(tile, 0.0)
		spr.modulate.a = clampf(tile_peak_alpha + sin(_pulse_time * pulse_speed + phase) * pulse_depth * 0.5, 0.0, 1.0)

	# On first tick after activation, materialise tiles at the player's feet immediately.
	if _needs_initial_step and _player and _base_layer:
		_needs_initial_step = false
		force_step(_player.current_tile)

	if _sim_active:
		_sim_accumulator += delta * _sim_speed
		while _sim_accumulator >= 1.0:
			_sim_accumulator -= 1.0
			_sim_tile.y -= 1
			_on_hero_step(_sim_tile)
		_update_preview()
		return

	if not _player:
		return

	var hero_tile := _player.current_tile

	# Only act when the hero steps onto a new tile
	if hero_tile != _current_hero_tile:
		_current_hero_tile = hero_tile
		_on_hero_step(hero_tile)

	# Update preview position
	_update_preview()

func _on_hero_step(tile: Vector2i) -> void:
	# Materialise from the player's current row forward (ahead_rows rows in front).
	# Negative Y = forward in the corridor.
	for row_offset in range(0, ahead_rows + 1):
		var row_y_ahead := tile.y - row_offset
		for dx in range(-_path_half_width, _path_half_width + 1):
			_materialise_tile(Vector2i(dx, row_y_ahead), row_offset)

	# Track the row by y for culling
	var row_y := tile.y
	if row_y in _row_history:
		_row_history.erase(row_y)
	_row_history.append(row_y)
	_cull_old_rows()

func _materialise_hint_tile(tile: Vector2i) -> void:
	if not _base_layer or _base_layer.get_cell_source_id(tile) == -1:
		return
	if _trail_tiles.has(tile):
		return
	var spr := _create_tile_sprite()
	spr.modulate = Color(tile_color.r, tile_color.g, tile_color.b, 0.0)
	add_child(spr)
	spr.global_position = _base_layer.to_global(_base_layer.map_to_local(tile))
	_trail_tiles[tile] = spr
	_hint_tiles[tile] = true
	_pulse_offsets[tile] = randf() * TAU
	var fade_in := create_tween()
	_tile_tweens[tile] = fade_in
	fade_in.tween_property(spr, "modulate:a", tile_peak_alpha * 0.35, fade_in_duration)
	fade_in.tween_callback(func() -> void:
		_settling_tiles.erase(tile)
		_tile_tweens.erase(tile)
	)

func _materialise_tile(tile: Vector2i, _row_offset: int = 0) -> void:
	if not _base_layer or _base_layer.get_cell_source_id(tile) == -1:
		return

	if _trail_tiles.has(tile):
		# If this was a hint tile, promote it to full brightness now.
		if _hint_tiles.erase(tile):
			if _tile_tweens.has(tile):
				_tile_tweens[tile].kill()
				_tile_tweens.erase(tile)
			_settling_tiles[tile] = true
			var promote := create_tween()
			_tile_tweens[tile] = promote
			promote.tween_property(_trail_tiles[tile], "modulate:a", tile_peak_alpha, fade_in_duration)
			promote.tween_callback(func() -> void:
				_settling_tiles.erase(tile)
				_tile_tweens.erase(tile)
			)
		return

	var spr := _create_tile_sprite()
	spr.modulate = Color(tile_color.r, tile_color.g, tile_color.b, 0.0)
	add_child(spr)
	spr.global_position = _base_layer.to_global(_base_layer.map_to_local(tile))

	_trail_tiles[tile] = spr
	_pulse_offsets[tile] = randf() * TAU
	_settling_tiles[tile] = true

	var fade_in := create_tween()
	_tile_tweens[tile] = fade_in
	fade_in.tween_property(spr, "modulate:a", tile_peak_alpha, fade_in_duration)
	fade_in.tween_callback(func() -> void:
		_settling_tiles.erase(tile)
		_tile_tweens.erase(tile)
	)

func _cull_old_rows() -> void:
	while _row_history.size() > trail_length:
		var old_y: int = _row_history[0]
		_row_history.remove_at(0)
		# Free every tile in this row (all x values)
		var to_cull: Array[Vector2i] = []
		for cell in _trail_tiles.keys():
			if (cell as Vector2i).y == old_y:
				to_cull.append(cell)
		for cell in to_cull:
			var spr: Sprite2D = _trail_tiles[cell]
			_trail_tiles.erase(cell)
			_pulse_offsets.erase(cell)
			_settling_tiles.erase(cell)
			if _tile_tweens.has(cell):
				_tile_tweens[cell].kill()
				_tile_tweens.erase(cell)
			_fade_and_free(spr)

func _fade_and_free(spr: Sprite2D) -> void:
	var tween := create_tween()
	tween.tween_property(spr, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(spr.queue_free)

func _update_preview() -> void:
	if not _preview_enabled or not _player or not _base_layer or not _preview_sprite:
		return

	# Show preview tile one step ahead in the hero's facing direction
	var facing_dir := _player._facing_to_dir()
	if facing_dir == Vector2i.ZERO:
		_preview_sprite.visible = false
		return

	var preview_tile := _player.current_tile + facing_dir
	var source_id := _base_layer.get_cell_source_id(preview_tile)

	# Only show if the tile exists on the map and is walkable.
	if source_id != -1 and _player._is_tile_walkable(preview_tile):
		_preview_sprite.visible = true
		_preview_sprite.global_position = _base_layer.to_global(_base_layer.map_to_local(preview_tile))
		_preview_sprite.modulate.a = preview_alpha
	else:
		_preview_sprite.visible = false

func _create_tile_sprite() -> Sprite2D:
	var spr := Sprite2D.new()
	# Create a plain white square image as texture
	var img := Image.create(int(_tile_size.x), int(_tile_size.y), false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	spr.texture = ImageTexture.create_from_image(img)
	spr.z_index = 2 # Above bloom tiles (1) and fragments (-1)
	return spr

## Fade all active trail tiles to invisible and free them. Deactivates the path.
func fade_all_tiles(duration: float = 1.0) -> void:
	deactivate()
	for tile in _trail_tiles.keys():
		if _tile_tweens.has(tile):
			_tile_tweens[tile].kill()
		var spr: Sprite2D = _trail_tiles[tile]
		var tw := create_tween()
		tw.tween_property(spr, "modulate:a", 0.0, duration)
		tw.tween_callback(spr.queue_free)
	_trail_tiles.clear()
	_tile_tweens.clear()
	_settling_tiles.clear()
	_row_history.clear()
	if _preview_sprite:
		_preview_sprite.visible = false
