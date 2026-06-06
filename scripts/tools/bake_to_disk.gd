## One-shot: load a map-preview scene, bake a .map into it, strip runtime-only
## nodes, and save the populated scene back to disk — so the tiles become static
## and editable (no runtime generation). Run headless as a scene (autoloads present):
##   <godot> --headless --path . res://scenes/levels/_bake_to_disk.tscn -- <scene> <map>
extends Node

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path := args[0] if args.size() > 0 else "res://scenes/levels/text_map_test.tscn"
	var map_path := args[1] if args.size() > 1 else "res://data/maps/_draft.map"

	var ps: PackedScene = load(scene_path)
	var root = ps.instantiate()      # root IS the TextMapTilemap for the preview scene
	add_child(root)
	await get_tree().process_frame

	root.map_file = map_path
	root._bake_from_map()
	await get_tree().process_frame

	# Drop the runtime-only highlight renderer so it isn't serialized.
	if "highlight_renderer" in root and root.highlight_renderer and is_instance_valid(root.highlight_renderer):
		root.highlight_renderer.free()
		root.highlight_renderer = null

	_own(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		print("[BAKE2DISK] pack failed err=%d" % err)
		get_tree().quit()
		return
	var save_err := ResourceSaver.save(packed, scene_path)
	var spawns = root.get_node_or_null("Spawns")
	print("[BAKE2DISK] saved %s (err=%d) map=%s floor=%d wall=%d markers=%d" % [
		scene_path, save_err, map_path,
		root.get_node("BaseGrid").get_used_cells().size(),
		root.get_node("Walls").get_used_cells().size(),
		spawns.get_child_count() if spawns else 0])
	get_tree().quit()

func _own(node: Node, owner_root: Node) -> void:
	for c in node.get_children():
		if c != owner_root:
			c.owner = owner_root
		_own(c, owner_root)
