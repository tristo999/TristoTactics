## TextMapTilemap - bridges the text ".map" workflow and the Godot editor.
##
## Two modes:
##   * BAKE (editor): press the "Bake from .map" inspector button to write the
##     grid into the BaseGrid/Walls layers and drop editable Marker2D spawn nodes
##     under a "Spawns" child. Save the scene (Ctrl+S) and the map is now real,
##     hand-editable tiles — paint over it, move spawns, etc.
##   * RUNTIME: if the scene was baked (a "Spawns" node exists) it reads spawn
##     positions from the markers and uses the already-placed tiles. If it was
##     NOT baked but `map_file` is set, it falls back to building at runtime.
@tool
extends "res://scripts/levels/tilemaps/tilemap.gd"

const MapLoaderScript = preload("res://scripts/levels/tilemaps/map_loader.gd")

## Path to the .map file to bake/build, e.g. "res://data/maps/tutorial.map".
@export var map_file: String = ""

## Inspector buttons (Godot 4.4+). Click to bake the .map into editable tiles.
@export_tool_button("Bake from .map") var _bake_action := _bake_from_map
@export_tool_button("Clear baked tiles") var _clear_action := _clear_baked

## Filled at runtime: { named, player_spawns, enemy_spawns, size }.
var spawn_data: Dictionary = {}

func _ready() -> void:
	if Engine.is_editor_hint():
		return  # editor: do nothing until a button is pressed
	_resolve_spawns()
	super._ready()  # setup_astar_grid() + add_walkable_cells_from_tilemap()

# --- Runtime ---------------------------------------------------------------

func _resolve_spawns() -> void:
	var base := $BaseGrid as TileMapLayer
	var walls := $Walls as TileMapLayer
	if base == null or walls == null:
		push_error("TextMapTilemap: BaseGrid/Walls layers missing.")
		return
	var spawns := get_node_or_null("Spawns")
	if spawns != null and spawns.get_child_count() > 0:
		# Baked scene: tiles are already placed, read spawns from the markers.
		spawn_data = _read_markers(base, spawns)
		print("[TextMapTilemap] baked: floor=%d wall=%d, spawns P%d/E%d named=%d" % [
			base.get_used_cells().size(), walls.get_used_cells().size(),
			spawn_data.player_spawns.size(), spawn_data.enemy_spawns.size(), spawn_data.named.size()])
	elif map_file != "":
		# Un-baked: build the tiles and spawns at runtime from the .map.
		var parsed: Dictionary = MapLoaderScript.load_file(map_file)
		if parsed.is_empty():
			push_error("TextMapTilemap: failed to load map " + map_file)
			return
		MapLoaderScript.populate(parsed, base, walls)
		spawn_data = parsed
		print("[TextMapTilemap] %s (runtime): floor=%d wall=%d, spawns P%d/E%d named=%d" % [
			map_file, base.get_used_cells().size(), walls.get_used_cells().size(),
			parsed.player_spawns.size(), parsed.enemy_spawns.size(), parsed.named.size()])

func _read_markers(base: TileMapLayer, spawns: Node) -> Dictionary:
	var data := {"named": {}, "player_spawns": [], "enemy_spawns": [],
		"size": base.get_used_rect().size}
	for m in spawns.get_children():
		if not (m is Marker2D):
			continue
		var tile: Vector2i = base.local_to_map(base.to_local(m.global_position))
		var team: String = m.get_meta("spawn_team", "named")
		match team:
			"player": data.player_spawns.append(tile)
			"enemy": data.enemy_spawns.append(tile)
			_: data.named[m.get_meta("spawn_key", "")] = tile
	return data

## Pixel position (local) for a tile, for placing units on spawns.
func tile_to_local(tile: Vector2i) -> Vector2:
	return ($BaseGrid as TileMapLayer).map_to_local(tile)

## Global position to place a unit on a tile (tile center + TILE_CENTER_OFFSET).
func tile_to_global(tile: Vector2i) -> Vector2:
	var base := $BaseGrid as TileMapLayer
	return base.to_global(base.map_to_local(tile) + Constants.TILE_CENTER_OFFSET)

# --- Editor bake -----------------------------------------------------------

func _bake_from_map() -> void:
	if map_file == "":
		push_warning("TextMapTilemap: set map_file before baking.")
		return
	var base := get_node_or_null("BaseGrid") as TileMapLayer
	var walls := get_node_or_null("Walls") as TileMapLayer
	if base == null or walls == null:
		push_error("TextMapTilemap: BaseGrid/Walls layers missing — can't bake.")
		return
	var parsed: Dictionary = MapLoaderScript.load_file(map_file)
	if parsed.is_empty():
		push_error("TextMapTilemap: failed to load " + map_file)
		return
	base.clear()
	walls.clear()
	MapLoaderScript.populate(parsed, base, walls)
	_bake_markers(base, parsed)
	print("[TextMapTilemap] BAKED %s -> floor=%d wall=%d. Save the scene (Ctrl+S) to keep it." % [
		map_file, base.get_used_cells().size(), walls.get_used_cells().size()])

func _bake_markers(base: TileMapLayer, parsed: Dictionary) -> void:
	var root := _scene_root()
	var old := get_node_or_null("Spawns")
	if old != null:
		old.free()
	var spawns := Node2D.new()
	spawns.name = "Spawns"
	add_child(spawns)
	if root != null:
		spawns.owner = root
	for key in parsed.named:
		_add_marker(spawns, base, parsed.named[key], "named", str(key), "Slot_" + str(key), root)
	for i in parsed.player_spawns.size():
		_add_marker(spawns, base, parsed.player_spawns[i], "player", str(i), "P%d" % (i + 1), root)
	for i in parsed.enemy_spawns.size():
		_add_marker(spawns, base, parsed.enemy_spawns[i], "enemy", str(i), "E%d" % (i + 1), root)

func _add_marker(spawns: Node, base: TileMapLayer, tile: Vector2i, team: String,
		key: String, marker_name: String, root: Node) -> void:
	var m := Marker2D.new()
	m.name = marker_name
	spawns.add_child(m)
	m.global_position = base.to_global(base.map_to_local(tile))
	m.set_meta("spawn_team", team)
	m.set_meta("spawn_key", key)
	if root != null:
		m.owner = root

func _clear_baked() -> void:
	var base := get_node_or_null("BaseGrid") as TileMapLayer
	var walls := get_node_or_null("Walls") as TileMapLayer
	if base:
		base.clear()
	if walls:
		walls.clear()
	var old := get_node_or_null("Spawns")
	if old != null:
		old.free()
	print("[TextMapTilemap] cleared baked tiles + spawns. Save to persist.")

func _scene_root() -> Node:
	if Engine.is_editor_hint() and get_tree() != null:
		return get_tree().edited_scene_root
	return owner
