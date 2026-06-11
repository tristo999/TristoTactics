# One-off: verify arena_drill tile placement + which atlas coords are DEFINED.
# Run: <godot> --headless --path . -s scripts/tools/dump_arena.gd
extends SceneTree

func _initialize() -> void:
	var parsed: Dictionary = MapLoader.load_file("res://data/maps/arena_drill.map")
	print("size=", parsed.get("size"), " named_spawns=", parsed.get("spawns", {}))
	var ts: TileSet = load("res://assets/tilesets/tileset.tres")
	var base := TileMapLayer.new(); base.tile_set = ts
	var walls := TileMapLayer.new(); walls.tile_set = ts
	var objects := TileMapLayer.new(); objects.tile_set = ts
	MapLoader.populate(parsed, base, walls, objects, null)

	var src := ts.get_source(2) as TileSetAtlasSource
	print("--- coords DEFINED in Solaria src2? ---")
	var want := {
		"grass(5,0)": Vector2i(5, 0), "dirt(5,3)": Vector2i(5, 3),
		"pad(10,6)": Vector2i(10, 6), "brick(10,3)": Vector2i(10, 3),
		"tree1(7,3)": Vector2i(7, 3), "tree3(7,0)": Vector2i(7, 0),
		"fence_tl(0,12)": Vector2i(0, 12), "fence_t(1,12)": Vector2i(1, 12),
		"fence_tr(2,12)": Vector2i(2, 12), "fence_l(0,13)": Vector2i(0, 13),
		"fence_r(2,13)": Vector2i(2, 13), "fence_bl(0,14)": Vector2i(0, 14),
		"fence_b(1,14)": Vector2i(1, 14), "fence_br(2,14)": Vector2i(2, 14),
	}
	for k in want:
		print("  %s defined=%s" % [k, src.has_tile(want[k])])

	print("--- placed cells (base | walls | objects) ---")
	for probe in [["yard g", Vector2i(10, 10)], ["pad o", Vector2i(19, 14)],
			["fence #", Vector2i(4, 6)], ["road ,", Vector2i(19, 25)],
			["forest .", Vector2i(2, 0)], ["tree T", Vector2i(24, 0)]]:
		var c: Vector2i = probe[1]
		print("  %s %s: base=%s walls=%s obj=%s" % [probe[0], c,
			base.get_cell_atlas_coords(c), walls.get_cell_atlas_coords(c),
			objects.get_cell_atlas_coords(c)])
	quit()
