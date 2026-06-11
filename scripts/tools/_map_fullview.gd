# One-off dev harness: render an entire .map via TextMapTilemap with a fitted
# camera — no game UI, no units. Usage:
#   <godot> --rendering-driver opengl3 --path . res://scenes/dev/map_fullview.tscn -- <map.map> <out.png>
extends Node2D

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var map_path := "res://data/maps/arena_drill.map"
	var outp := "docs/maps/map_fullview.png"
	if args.size() > 0: map_path = args[0]
	if args.size() > 1: outp = args[1]

	var parsed: Dictionary = MapLoader.load_file(map_path)
	print("[FULLVIEW] parsed keys=", parsed.keys())
	print("[FULLVIEW] spawn-ish entries: ", {
		"named": parsed.get("named", "<none>"),
		"player_spawns": parsed.get("player_spawns", "<none>"),
		"enemy_spawns": parsed.get("enemy_spawns", "<none>"),
	})

	var tm := load("res://scenes/levels/TextMapTilemap.tscn")
	var tilemap: Node2D
	if tm:
		tilemap = tm.instantiate()
	else:
		# Fall back: build layers directly.
		tilemap = Node2D.new()
		var ts: TileSet = load("res://assets/tilesets/tileset.tres")
		var base := TileMapLayer.new(); base.name = "BaseGrid"; base.tile_set = ts
		var walls := TileMapLayer.new(); walls.name = "Walls"; walls.tile_set = ts
		var objects := TileMapLayer.new(); objects.name = "Objects"; objects.tile_set = ts
		var decor := TileMapLayer.new(); decor.name = "Decor"; decor.tile_set = ts
		tilemap.add_child(base); tilemap.add_child(decor)
		tilemap.add_child(objects); tilemap.add_child(walls)
		MapLoader.populate(parsed, base, walls, objects, decor)
	if "map_file" in tilemap:
		tilemap.set("map_file", map_path)
	add_child(tilemap)

	var size: Vector2i = parsed.get("size", Vector2i(40, 30))
	var cam := Camera2D.new()
	add_child(cam)
	cam.make_current()
	cam.position = Vector2(size.x * 16 / 2.0, size.y * 16 / 2.0)
	var vp := get_viewport().get_visible_rect().size
	var z: float = min(vp.x / (size.x * 16.0), vp.y / (size.y * 16.0))
	cam.zoom = Vector2(z, z)

	await get_tree().create_timer(1.5).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(outp)
	print("[FULLVIEW] saved ", outp, " ", img.get_size())
	get_tree().quit()
