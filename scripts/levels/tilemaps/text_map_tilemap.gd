## TextMapTilemap - builds the tilemap at runtime from a text ".map" file
## (see docs/text_map_system.md), then lets the base tilemap initialize
## pathfinding over the placed cells. Mirrors tutorial_tilemap.gd's pattern.
extends "res://scripts/levels/tilemaps/tilemap.gd"

const MapLoaderScript = preload("res://scripts/levels/tilemaps/map_loader.gd")

## Path to the .map file to build, e.g. "res://data/maps/sample.map".
@export var map_file: String = ""

## Filled after build: { meta, grid, size, player_spawns, enemy_spawns, named }.
var spawn_data: Dictionary = {}

func _ready() -> void:
	if map_file != "":
		_build_from_file()
	super._ready()  # setup_astar_grid() + add_walkable_cells_from_tilemap()

func _build_from_file() -> void:
	# Use the child nodes directly — @onready refs aren't guaranteed before super._ready().
	var base := $BaseGrid as TileMapLayer
	var walls := $Walls as TileMapLayer
	if base == null or walls == null:
		push_error("TextMapTilemap: BaseGrid/Walls layers missing.")
		return
	spawn_data = MapLoaderScript.load_file(map_file)
	if spawn_data.is_empty():
		push_error("TextMapTilemap: failed to load map " + map_file)
		return
	MapLoaderScript.populate(spawn_data, base, walls)
	print("[TextMapTilemap] %s: %s, floor=%d wall=%d, spawns P%d/E%d named=%d" % [
		map_file, str(spawn_data.size), base.get_used_cells().size(), walls.get_used_cells().size(),
		spawn_data.player_spawns.size(), spawn_data.enemy_spawns.size(), spawn_data.named.size()])

## Pixel position (local) for a tile, for placing units on spawns.
func tile_to_local(tile: Vector2i) -> Vector2:
	return ($BaseGrid as TileMapLayer).map_to_local(tile)
