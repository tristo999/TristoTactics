extends SceneTree

func _initialize() -> void:
	var parsed: Dictionary = MapLoader.load_file("res://data/maps/camp_v2.map")
	print("size=", parsed.get("size"))
	# Build into throwaway layers using the real tileset.
	var ts: TileSet = load("res://assets/tilesets/tileset.tres")
	var base := TileMapLayer.new(); base.tile_set = ts
	var walls := TileMapLayer.new(); walls.tile_set = ts
	MapLoader.populate(parsed, base, walls, null, null)
	# Which Solaria (src 2) atlas coords are actually DEFINED?
	var src := ts.get_source(2) as TileSetAtlasSource
	print("src2 tile_count=", src.get_tiles_count())
	var want := [Vector2i(5,0),Vector2i(10,6),Vector2i(10,3),Vector2i(5,3),
		Vector2i(7,0),Vector2i(1,11),Vector2i(4,11),Vector2i(7,3)]
	for c in want:
		print("  defined ", c, " = ", src.has_tile(c))
	# Sample BaseGrid cells: a yard 'g' (4,9), a bottom '.' grass (5,20), pad 'o' (10,12)
	for cell in [Vector2i(4,9), Vector2i(5,20), Vector2i(10,12), Vector2i(0,5), Vector2i(10,5)]:
		print("base ", cell, " src=", base.get_cell_source_id(cell), " atlas=", base.get_cell_atlas_coords(cell))
	for cell in [Vector2i(2,7), Vector2i(0,5), Vector2i(5,10)]:
		print("wall ", cell, " src=", walls.get_cell_source_id(cell), " atlas=", walls.get_cell_atlas_coords(cell))
	quit()
