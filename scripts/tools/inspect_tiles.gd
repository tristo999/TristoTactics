# Dev tool: prints the (source_id : atlas_coords) actually used on each tile layer
# of a scene, so the text-map loader can use real coordinates instead of guesses.
# Run:  <godot> --headless --script res://scripts/tools/inspect_tiles.gd --path .
extends SceneTree

func _init() -> void:
	var path := "res://scenes/levels/dev_sandbox_scene.tscn"
	var ps := load(path) as PackedScene
	if ps == null:
		print("Could not load ", path)
		quit()
		return
	var inst := ps.instantiate()
	for lname in ["BaseGrid", "Walls", "Water", "Objects"]:
		var layer := inst.find_child(lname, true, false) as TileMapLayer
		if layer == null:
			print(lname, ": (not found)")
			continue
		var cells := layer.get_used_cells()
		var seen := {}
		for c in cells:
			var key := "src=%d atlas=%s" % [layer.get_cell_source_id(c), str(layer.get_cell_atlas_coords(c))]
			seen[key] = int(seen.get(key, 0)) + 1
		print("--- ", lname, " (", cells.size(), " cells) ---")
		for k in seen:
			print("   ", k, "  x", seen[k])
	inst.free()
	quit()
