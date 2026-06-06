# Dev tool: parse a .map file and print its render + spawn data, so map parsing
# can be self-verified headless (and the grid shown back in chat).
# Run:  <godot> --headless --script res://scripts/tools/map_check.gd --path . -- <map_path>
extends SceneTree

const ML = preload("res://scripts/levels/tilemaps/map_loader.gd")

func _init() -> void:
	var path := "res://data/maps/sample.map"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		path = args[0]
	var parsed: Dictionary = ML.load_file(path)
	if parsed.is_empty():
		print("FAILED to load ", path)
		quit()
		return
	print("== ", path, " ==")
	print("meta:           ", parsed.meta)
	print("size:           ", parsed.size)
	print("player_spawns:  ", parsed.player_spawns)
	print("enemy_spawns:   ", parsed.enemy_spawns)
	print("named slots:    ", parsed.named)
	print("--- rendered grid ---")
	print(ML.render(parsed))
	print("--- end ---")
	quit()
